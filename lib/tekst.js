// Rad sa tekstom: čišćenje prepisa, klipbord i lepljenje u aktivnu aplikaciju.
import { spawnSync } from "node:child_process";

/**
 * Sređuje sirov prepis: spaja redove u jedan pasus, skuplja višestruke
 * razmake i sklanja prazne redove. Whisper često vraća tekst po segmentima.
 */
export function ocistiTekst(tekst) {
  return String(tekst ?? "")
    .replace(/\r\n?/g, "\n")
    .split("\n")
    .map((red) => red.trim())
    .filter((red) => red.length > 0)
    .join(" ")
    .replace(/[ \t]{2,}/g, " ")
    .trim();
}

/** Stavlja tekst u klipbord preko pbcopy (macOS). */
export function uKlipbord(tekst) {
  const rezultat = spawnSync("pbcopy", { input: tekst, encoding: "utf8" });
  if (rezultat.status !== 0) {
    throw new Error("Ne mogu da upišem u klipbord (pbcopy nije uspeo).");
  }
}

/**
 * Lepljenje teksta u aplikaciju koja je bila aktivna.
 * Zahteva dozvolu „Accessibility“ za Terminal (Sistemska podešavanja →
 * Privatnost i bezbednost → Pristupačnost); bez nje macOS ignoriše keystroke.
 */
export function ubaciUTekst(tekst) {
  uKlipbord(tekst);
  const skripta = [
    'tell application "System Events"',
    '  keystroke "v" using command down',
    "end tell",
  ].join("\n");
  const rezultat = spawnSync("osascript", ["-e", skripta], { encoding: "utf8" });
  if (rezultat.status !== 0) {
    throw new Error(
      "Lepljenje nije uspelo. Proveri dozvolu „Accessibility“ za Terminal.",
    );
  }
}
