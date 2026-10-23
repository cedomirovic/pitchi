#!/usr/bin/env node
// Pitchi — ulazna tačka. Samo parsira opcije i poziva lib/ module.
import fs from "node:fs";
import path from "node:path";
import {
  GRESKA,
  IZLAZ,
  OK,
  SNIMCI,
  ispisi,
  ispisiTabelu,
  osigurajFolder,
  upozori,
} from "./lib/pomoc.js";
import { nadjiWhisper, listaModela, folderiModela, prepisi } from "./lib/prepis.js";
import { snimi, nadjiFfmpeg } from "./lib/snimak.js";
import { uKlipbord, ubaciUTekst } from "./lib/tekst.js";

const POMOC = `
Pitchi — lokalno diktiranje: snimi govor → tekst → klipbord.

KORIŠĆENJE
  node pitchi.js <komanda> [opcije]

KOMANDE
  stanje                    proveri šta je instalirano (ffmpeg, whisper, modeli)
  snimi <fajl.wav>          snimi mikrofon u WAV
  prepis <fajl.wav>         pretvori snimak u tekst
  diktat                    snimi, prepiši i stavi tekst u klipbord

OPCIJE
  --sekundi <n>             trajanje snimanja u sekundama (podrazumevano 10)
  --uredjaj <n>             indeks audio uređaja za ffmpeg (podrazumevano 0)
  --jezik <kod>             jezik govora (podrazumevano sr)
  --model <ime|putanja>     Whisper model (npr. large-v3-turbo ili puna putanja)
  --izlaz <putanja>         gde da ode tekst/snimak
  --u-klipbord              stavi prepis u klipbord
  --ubaci                   zalepi prepis u aktivnu aplikaciju (Accessibility)
  --prepisi                 dozvoli zamenu postojećeg fajla (stari ide u .bak)
  --dry-run                 pokaži šta bi se uradilo, bez izmena
  -h, --pomoc               ova pomoć

PRIMERI
  node pitchi.js stanje
  node pitchi.js diktat --sekundi 15 --u-klipbord
  node pitchi.js snimi snimci/test.wav --sekundi 5
  node pitchi.js prepis snimci/test.wav --izlaz izlaz/test.txt --u-klipbord
`;

/** Opcije koje uzimaju vrednost iz sledećeg argumenta. */
const OPCIJE_SA_VREDNOSTI = new Set([
  "--jezik",
  "--model",
  "--izlaz",
  "--sekundi",
  "--uredjaj",
]);

/**
 * Pretvara listu argumenata u { komanda, opcije, pozicioni }.
 * Baca grešku za nepoznatu opciju ili opciju bez vrednosti.
 */
export function parsirajArgumente(argv) {
  const opcije = {
    jezik: "sr",
    model: null,
    izlaz: null,
    sekundi: 10,
    uredjaj: "0",
    uKlipbord: false,
    ubaci: false,
    prepisi: false,
    dryRun: false,
    pomoc: false,
  };
  const pozicioni = [];

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];

    if (arg === "-h" || arg === "--help" || arg === "--pomoc") {
      opcije.pomoc = true;
      continue;
    }
    if (arg === "--u-klipbord") {
      opcije.uKlipbord = true;
      continue;
    }
    if (arg === "--ubaci") {
      opcije.ubaci = true;
      continue;
    }
    if (arg === "--prepisi") {
      opcije.prepisi = true;
      continue;
    }
    if (arg === "--dry-run") {
      opcije.dryRun = true;
      continue;
    }

    if (OPCIJE_SA_VREDNOSTI.has(arg)) {
      const vrednost = argv[i + 1];
      if (vrednost === undefined || vrednost.startsWith("--")) {
        throw new Error(`${GRESKA} Opcija ${arg} traži vrednost.`);
      }
      i++;
      const kljuc = arg
        .slice(2)
        .replace(/-([a-z])/g, (_, slovo) => slovo.toUpperCase());
      opcije[kljuc] = vrednost;
      continue;
    }

    if (arg.startsWith("-")) {
      throw new Error(`${GRESKA} Nepoznata opcija: ${arg}`);
    }
    pozicioni.push(arg);
  }

  const broj = Number(opcije.sekundi);
  if (!Number.isFinite(broj) || broj < 1) {
    throw new Error(`${GRESKA} --sekundi mora biti broj veći od nule.`);
  }
  opcije.sekundi = Math.round(broj);

  return { komanda: pozicioni[0] || null, opcije, pozicioni: pozicioni.slice(1) };
}

function komandaStanje() {
  const redovi = [];

  redovi.push(["Node", process.version]);

  let ffmpeg = null;
  try {
    ffmpeg = nadjiFfmpeg();
  } catch {
    ffmpeg = null;
  }
  redovi.push(["ffmpeg", ffmpeg ? `${OK} ${ffmpeg}` : "✗ nije instaliran (brew install ffmpeg)"]);

  let whisper = null;
  try {
    whisper = nadjiWhisper();
  } catch {
    whisper = null;
  }
  redovi.push([
    "whisper",
    whisper ? `${OK} ${whisper}` : "✗ nije instaliran (brew install whisper-cpp)",
  ]);

  const modeli = listaModela();
  if (modeli.length === 0) {
    redovi.push(["modeli", "✗ nema modela — vidi README (odeljak „Modeli“)"]);
  } else {
    for (const model of modeli) {
      const mb = (fs.statSync(model.putanja).size / 1024 / 1024).toFixed(0);
      redovi.push(["model", `${OK} ${model.ime} (${mb} MB)`]);
    }
  }

  redovi.push(["modeli u", folderiModela().join("\n             ")]);
  redovi.push(["snimci", SNIMCI]);
  redovi.push(["izlaz", IZLAZ]);

  ispisiTabelu(redovi);

  if (!whisper || modeli.length === 0) {
    ispisi("");
    ispisi("Za rad su potrebna dva koraka: brew install whisper-cpp i model u folderu modela.");
  }
}

function komandaSnimi(opcije, pozicioni) {
  const izlaz = opcije.izlaz || pozicioni[0] || path.join(SNIMCI, `snimak-${vreme()}.wav`);
  const rezultat = snimi({
    izlaz,
    sekundi: opcije.sekundi,
    uredjaj: opcije.uredjaj,
    prepisi: opcije.prepisi,
    probni: opcije.dryRun,
  });

  if (opcije.dryRun) {
    ispisi("Probni rad — ništa nije snimljeno.");
    ispisi(`Naredba: ${rezultat.naredba.join(" ")}`);
    ispisi(`Snimak bi bio: ${rezultat.izlaz}`);
    return;
  }

  ispisi(`${OK} Snimak: ${rezultat.izlaz} (${opcije.sekundi} s)`);
}

function komandaPrepis(opcije, pozicioni) {
  const ulaz = pozicioni[0];
  if (!ulaz) {
    throw new Error(`${GRESKA} Nedostaje snimak. Primer: node pitchi.js prepis snimci/test.wav`);
  }

  const rezultat = prepisi({
    ulaz,
    jezik: opcije.jezik,
    model: opcije.model,
    izlaz: opcije.izlaz,
    probni: opcije.dryRun,
  });

  if (opcije.dryRun) {
    ispisi("Probni rad — ništa nije prepisano.");
    ispisi(`Naredba: ${rezultat.naredba.join(" ")}`);
    ispisi(`Tekst bi bio u: ${rezultat.izlaz}`);
    return;
  }

  ispisi(rezultat.tekst || "(prazan prepis)");
  ispisi("");
  ispisi(`${OK} Tekst sačuvan: ${rezultat.izlaz}`);

  predajTekst(rezultat.tekst, opcije);
}

function predajTekst(tekst, opcije) {
  if (!tekst) return;
  if (opcije.ubaci) {
    ubaciUTekst(tekst);
    ispisi(`${OK} Tekst zalepen u aktivnu aplikaciju.`);
    return;
  }
  if (opcije.uKlipbord) {
    uKlipbord(tekst);
    ispisi(`${OK} Tekst je u klipbordu (Cmd+V).`);
  }
}

function komandaDiktat(opcije) {
  const snimak = path.join(SNIMCI, `diktat-${vreme()}.wav`);
  osigurajFolder(SNIMCI);

  if (!opcije.dryRun) {
    ispisi(`Snimam ${opcije.sekundi} s… govori sada.`);
  }

  snimi({
    izlaz: snimak,
    sekundi: opcije.sekundi,
    uredjaj: opcije.uredjaj,
    probni: opcije.dryRun,
  });

  if (opcije.dryRun) {
    ispisi("Probni rad — ništa nije snimljeno ni prepisano.");
    ispisi(`Snimak bi bio: ${snimak}`);
    return;
  }

  const rezultat = prepisi({
    ulaz: snimak,
    jezik: opcije.jezik,
    model: opcije.model,
    izlaz: opcije.izlaz,
  });

  ispisi(rezultat.tekst || "(prazan prepis)");

  // Podrazumevano diktat ide u klipbord, osim ako je traženo lepljenje.
  predajTekst(rezultat.tekst, { ...opcije, uKlipbord: opcije.uKlipbord || !opcije.ubaci });
}

/** Vremenski pečat za imena fajlova (bez dvotačaka). */
function vreme() {
  return new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
}

function main() {
  let parsirano;
  try {
    parsirano = parsirajArgumente(process.argv.slice(2));
  } catch (greska) {
    upozori(greska.message);
    ispisi("");
    ispisi(POMOC);
    process.exitCode = 1;
    return;
  }

  const { komanda, opcije, pozicioni } = parsirano;

  if (opcije.pomoc || !komanda) {
    ispisi(POMOC);
    return;
  }

  try {
    switch (komanda) {
      case "stanje":
        komandaStanje();
        break;
      case "snimi":
        komandaSnimi(opcije, pozicioni);
        break;
      case "prepis":
        komandaPrepis(opcije, pozicioni);
        break;
      case "diktat":
        komandaDiktat(opcije);
        break;
      default:
        throw new Error(`${GRESKA} Nepoznata komanda: ${komanda}`);
    }
  } catch (greska) {
    upozori(greska.message);
    process.exitCode = 1;
  }
}

// Pokreni samo kada je fajl pozvan direktno (testovi ga importuju).
if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(import.meta.filename)) {
  main();
}
