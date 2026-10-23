// Testovi za Pitchi — node:test, bez spoljnih paketa.
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import { parsirajArgumente } from "../pitchi.js";
import { ocistiTekst } from "../lib/tekst.js";
import { putanjaUDaljem } from "../lib/pomoc.js";
import { nadjiModel, listaModela } from "../lib/prepis.js";

test("parsirajArgumente: podrazumevane vrednosti", () => {
  const { komanda, opcije } = parsirajArgumente(["diktat"]);
  assert.equal(komanda, "diktat");
  assert.equal(opcije.sekundi, 10);
  assert.equal(opcije.jezik, "sr");
  assert.equal(opcije.uKlipbord, false);
  assert.equal(opcije.dryRun, false);
});

test("parsirajArgumente: opcije sa vrednošću", () => {
  const { opcije } = parsirajArgumente([
    "prepis",
    "snimci/a.wav",
    "--jezik",
    "en",
    "--sekundi",
    "25",
    "--u-klipbord",
  ]);
  assert.equal(opcije.jezik, "en");
  assert.equal(opcije.sekundi, 25);
  assert.equal(opcije.uKlipbord, true);
});

test("parsirajArgumente: nepoznata opcija", () => {
  assert.throws(() => parsirajArgumente(["diktat", "--nepostoji"]), /Nepoznata opcija/);
});

test("parsirajArgumente: opcija bez vrednosti", () => {
  assert.throws(() => parsirajArgumente(["prepis", "--izlaz"]), /traži vrednost/);
});

test("parsirajArgumente: sekundi mora biti broj", () => {
  assert.throws(() => parsirajArgumente(["diktat", "--sekundi", "nula"]), /broj veći od nule/);
});

test("ocistiTekst: spaja redove i sklanja viškove", () => {
  const ulaz = "  Zdravo,\n\n ovo   je   proba. \r\nDruga linija.  ";
  assert.equal(ocistiTekst(ulaz), "Zdravo, ovo je proba. Druga linija.");
});

test("ocistiTekst: prazan ulaz", () => {
  assert.equal(ocistiTekst(""), "");
  assert.equal(ocistiTekst(null), "");
});

test("putanjaUDaljem: pušta putanju unutar foldera", () => {
  const osnovni = path.join(os.tmpdir(), "pitchi-test");
  assert.equal(putanjaUDaljem(osnovni, "a/b.txt"), path.join(osnovni, "a/b.txt"));
});

test("putanjaUDaljem: odbija izlazak iz foldera", () => {
  const osnovni = path.join(os.tmpdir(), "pitchi-test");
  assert.throws(() => putanjaUDaljem(osnovni, "../../nešto.txt"), /izlazi iz foldera/);
});

test("nadjiModel: bira turbo model i po imenu", () => {
  const folder = fs.mkdtempSync(path.join(os.tmpdir(), "pitchi-modeli-"));
  fs.writeFileSync(path.join(folder, "ggml-small.bin"), "");
  fs.writeFileSync(path.join(folder, "ggml-large-v3-turbo.bin"), "");

  const svi = listaModela([folder]);
  assert.equal(svi.length, 2);

  assert.equal(nadjiModel(null, { folderi: [folder] }).ime, "ggml-large-v3-turbo.bin");
  assert.equal(
    nadjiModel("small", { folderi: [folder] }).ime,
    "ggml-small.bin",
  );
});

test("nadjiModel: vraća null kada nema modela", () => {
  const folder = fs.mkdtempSync(path.join(os.tmpdir(), "pitchi-prazno-"));
  assert.equal(nadjiModel("large", { folderi: [folder] }), null);
});
