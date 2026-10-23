// Zajedničke sitnice: pronalaženje alata, čuvanje putanja, ispis.
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

// Koren projekta (folder u kome je diktator.js).
export const KOREN = path.resolve(import.meta.dirname, "..");

// Folder za snimke i izlaze (u .gitignore je).
export const SNIMCI = path.join(KOREN, "snimci");
export const IZLAZ = path.join(KOREN, "izlaz");

export const GRESKA = "✗";
export const OK = "✓";

/**
 * Pronalazi izvršni fajl alata u PATH-u ili na poznatim mestima.
 * Vraća punu putanju ili null. Ne baca grešku — proveru radi pozivalac.
 */
export function nadjiAlat(ime, dodatnePutanje = []) {
  const nadjeno = spawnSync("which", [ime], { encoding: "utf8" });
  if (nadjeno.status === 0) {
    const putanja = nadjeno.stdout.trim();
    if (putanja) return putanja;
  }
  for (const putanja of dodatnePutanje) {
    if (postojiIzvršni(putanja)) return putanja;
  }
  return null;
}

function postojiIzvršni(putanja) {
  try {
    fs.accessSync(putanja, fs.constants.X_OK);
    return true;
  } catch {
    return false;
  }
}

/**
 * Spaja putanju sa osnovnim folderom i proverava da se ne izlazi iz njega.
 * Baca grešku ako ciljna putanja beži napolje (npr. "../../nešto").
 */
export function putanjaUDaljem(osnovni, cilj) {
  const osnova = path.resolve(osnovni);
  const puna = path.resolve(osnova, cilj);
  const prefiks = osnova.endsWith(path.sep) ? osnova : osnova + path.sep;
  if (puna !== osnova && !puna.startsWith(prefiks)) {
    throw new Error(`Putanja "${cilj}" izlazi iz foldera "${osnovni}".`);
  }
  return puna;
}

/** Pravi folder ako ne postoji i vraća njegovu putanju. */
export function osigurajFolder(putanja) {
  fs.mkdirSync(putanja, { recursive: true });
  return putanja;
}

/** Putanja do foldera sa modelima u korisničkom profilu. */
export function folderModela() {
  const baza = path.join(os.homedir(), "Library", "Application Support");
  const nova = path.join(baza, "Diktator", "modeli");
  const stara = path.join(baza, "Pitchi", "modeli");

  // Jednokratna migracija zajedno sa aplikacijom: stari folder sadrži i
  // modele i istoriju. Ako premestanje ne uspe, koristimo stari folder.
  if (!fs.existsSync(nova) && fs.existsSync(stara)) {
    try {
      fs.renameSync(path.dirname(stara), path.join(baza, "Diktator"));
    } catch {
      return stara;
    }
  }
  return nova;
}

/** Ispis u konzolu sa prefiksom alata. */
export function ispisi(tekst = "") {
  console.log(tekst);
}

export function upozori(tekst) {
  console.warn(tekst);
}

/** Ispis tabele „stavka — vrednost“ bez spoljnih paketa. */
export function ispisiTabelu(redovi) {
  const sirina = Math.max(...redovi.map(([naziv]) => naziv.length));
  for (const [naziv, vrednost] of redovi) {
    console.log(`${naziv.padEnd(sirina)}  ${vrednost}`);
  }
}
