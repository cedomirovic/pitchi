// Pretvaranje snimka u tekst preko whisper.cpp (lokalno, bez mreže).
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { GRESKA, IZLAZ, KOREN, folderModela, nadjiAlat, osigurajFolder } from "./pomoc.js";
import { ocistiTekst } from "./tekst.js";

const NAZIVI_WHISPERA = ["whisper-cli", "whisper-cpp", "whisper"];

/** Vraća putanju do whisper.cpp programa ili baca grešku sa uputstvom. */
export function nadjiWhisper() {
  for (const ime of NAZIVI_WHISPERA) {
    const putanja = nadjiAlat(ime);
    if (putanja) return putanja;
  }

  // Ponekad brew stavi program u svoj prefix, a nije u PATH-u.
  const brew = nadjiAlat("brew", ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]);
  if (brew) {
    const prefiks = spawnSync(brew, ["--prefix", "whisper-cpp"], { encoding: "utf8" });
    if (prefiks.status === 0) {
      const kandidat = path.join(
        prefiks.stdout.trim(),
        "bin",
        "whisper-cli",
      );
      if (fs.existsSync(kandidat)) return kandidat;
    }
  }

  throw new Error(
    `${GRESKA} whisper.cpp nije pronađen.\n` +
      "  Instaliraj ga sa: brew install whisper-cpp\n" +
      "  (bez npm paketa — samo jedan izvršni fajl)",
  );
}

/** Folderi u kojima tražimo modele, redom kojim se pretražuju. */
export function folderiModela() {
  return [
    path.join(KOREN, "modeli"),
    folderModela(),
    path.join(os.homedir(), ".cache", "whisper.cpp"),
  ];
}

/** Svi pronađeni .bin modeli iz svih foldera (bez duplikata). */
export function listaModela(folderi = folderiModela()) {
  const nadjeni = [];
  for (const folder of folderi) {
    let sadrzaj = [];
    try {
      sadrzaj = fs.readdirSync(folder);
    } catch {
      continue;
    }
    for (const ime of sadrzaj) {
      if (!ime.endsWith(".bin")) continue;
      const puna = path.join(folder, ime);
      // Preskačemo nedovršene preuzete fajlove.
      if (ime.endsWith(".part.bin")) continue;
      if (!nadjeni.some((m) => m.putanja === puna)) nadjeni.push({ ime, putanja: puna });
    }
  }
  return nadjeni;
}

/**
 * Nalazi model po imenu ili putanji.
 * `izbor` može biti: puna putanja, "large-v3-turbo" ili "ggml-large-v3-turbo.bin".
 */
export function nadjiModel(izbor, { folderi = folderiModela() } = {}) {
  const zelja = izbor || process.env.DIKTATOR_MODEL || null;
  const svi = listaModela(folderi);

  if (!zelja) {
    const turbo = svi.find((m) => /turbo/i.test(m.ime));
    return turbo || svi[0] || null;
  }

  const kaoPutanja = path.resolve(zelja);
  if (fs.existsSync(kaoPutanja) && kaoPutanja.endsWith(".bin")) {
    return { ime: path.basename(kaoPutanja), putanja: kaoPutanja };
  }

  const ime = zelja.endsWith(".bin") ? zelja : `ggml-${zelja}.bin`;
  return (
    svi.find((m) => m.ime === ime) ||
    svi.find((m) => m.ime === zelja) ||
    svi.find((m) => m.ime.includes(zelja)) ||
    null
  );
}

/**
 * Prepisuje snimak u tekst.
 * Vraća { tekst, izlaz, naredba, uradjeno }.
 */
export function prepisi({
  ulaz,
  jezik = "sr",
  model = null,
  izlaz = null,
  probni = false,
  whisper = null,
}) {
  const puniUlaz = path.resolve(ulaz);
  if (!fs.existsSync(puniUlaz)) {
    throw new Error(`${GRESKA} Snimak ne postoji: ${puniUlaz}`);
  }

  const program = whisper || nadjiWhisper();
  const izabraniModel = nadjiModel(model);
  if (!izabraniModel) {
    throw new Error(
      `${GRESKA} Model za Whisper nije pronađen.\n` +
        "  Stavi ggml model u: " +
        folderModela() +
        "\n  ili ga navedi sa: --model /putanja/do/ggml-large-v3-turbo.bin",
    );
  }

  const osnova = izlaz
    ? path.resolve(izlaz.replace(/\.txt$/i, ""))
    : path.join(IZLAZ, path.basename(puniUlaz, path.extname(puniUlaz)));
  const izlazniTekst = `${osnova}.txt`;

  const argumenti = [
    "-m",
    izabraniModel.putanja,
    "-f",
    puniUlaz,
    "-l",
    jezik,
    "-otxt",
    "-nt",
    "-of",
    osnova,
  ];
  const naredba = [program, ...argumenti];

  if (probni) {
    return { tekst: "", izlaz: izlazniTekst, naredba, uradjeno: false };
  }

  osigurajFolder(path.dirname(izlazniTekst));
  const rezultat = spawnSync(program, argumenti, { encoding: "utf8" });
  if (rezultat.status !== 0) {
    throw new Error(
      `${GRESKA} Whisper nije uspeo.\n${rezultat.stderr || rezultat.stdout || ""}`.trim(),
    );
  }
  if (!fs.existsSync(izlazniTekst)) {
    throw new Error(`${GRESKA} Whisper nije napravio izlazni fajl: ${izlazniTekst}`);
  }

  try {
    fs.chmodSync(izlazniTekst, 0o600);
  } catch {
    // Dozvole su dodatna zaštita; tekst i dalje postoji.
  }

  const tekst = ocistiTekst(fs.readFileSync(izlazniTekst, "utf8"));
  return { tekst, izlaz: izlazniTekst, naredba, uradjeno: true };
}
