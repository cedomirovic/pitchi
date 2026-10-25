// Snimanje sa mikrofona preko ffmpeg-a (AVFoundation), bez dodatnih paketa.
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { GRESKA, nadjiAlat, osigurajFolder } from "./pomoc.js";

const POZNATE_FFMPEG = [
  "/opt/homebrew/bin/ffmpeg",
  "/usr/local/bin/ffmpeg",
  "/usr/bin/ffmpeg",
];

/** Vraća putanju do ffmpeg-a ili baca grešku sa uputstvom. */
export function nadjiFfmpeg() {
  const putanja = nadjiAlat("ffmpeg", POZNATE_FFMPEG);
  if (!putanja) {
    throw new Error(
      `${GRESKA} ffmpeg nije pronađen. Instaliraj ga sa: brew install ffmpeg`,
    );
  }
  return putanja;
}

/**
 * Snima zadati broj sekundi u WAV (mono, 16 kHz — dovoljno za Whisper).
 * Postojeći fajl se ne prepisuje bez opcije `prepisi`.
 */
export function snimi({ izlaz, sekundi = 10, uredjaj = "0", prepisi = false, probni = false }) {
  const ffmpeg = nadjiFfmpeg();
  const trajanje = Math.max(1, Math.round(Number(sekundi)));
  const punaIzlaz = path.resolve(izlaz);

  if (fs.existsSync(punaIzlaz) && !prepisi) {
    throw new Error(
      `${GRESKA} Fajl već postoji: ${punaIzlaz}\n` +
        "  Dodaj --prepisi ako želiš da ga zameniš (stari se čuva kao .bak).",
    );
  }

  const argumenti = [
    "-hide_banner",
    "-loglevel",
    "error",
    "-f",
    "avfoundation",
    "-i",
    `:${uredjaj}`,
    "-ac",
    "1",
    "-ar",
    "16000",
    "-c:a",
    "pcm_s16le",
    "-t",
    String(trajanje),
    "-y",
    punaIzlaz,
  ];

  if (probni) {
    return { naredba: [ffmpeg, ...argumenti], izlaz: punaIzlaz, uradjeno: false };
  }

  osigurajFolder(path.dirname(punaIzlaz));
  if (fs.existsSync(punaIzlaz)) {
    const rezerva = `${punaIzlaz}.bak`;
    fs.copyFileSync(punaIzlaz, rezerva);
    try {
      fs.chmodSync(rezerva, 0o600);
    } catch {
      // Dozvole su dodatna zaštita; snimak i dalje postoji.
    }
  }

  const rezultat = spawnSync(ffmpeg, argumenti, { encoding: "utf8" });
  if (fs.existsSync(punaIzlaz)) {
    try {
      fs.chmodSync(punaIzlaz, 0o600);
    } catch {
      // Dozvole su dodatna zaštita; snimak i dalje postoji.
    }
  }
  if (rezultat.status !== 0) {
    throw new Error(
      `${GRESKA} Snimanje nije uspelo.\n${rezultat.stderr || ""}`.trim() +
        "\n  Proveri mikrofon i dozvolu za Terminal (Mikrofon u Privatnosti).",
    );
  }

  return { naredba: [ffmpeg, ...argumenti], izlaz: punaIzlaz, uradjeno: true };
}
