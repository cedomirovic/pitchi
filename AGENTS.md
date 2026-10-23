# Pitchi · lokalni alat za diktiranje

Treći projekat pored `moja-zemlja-crm` (port 3000) i `alat` (port 3001).
Ova dva se **ne diraju odavde** — svaki ima svoj `AGENTS.md` i svoj git.

Pitchi snima govor sa mikrofona, prepisuje ga lokalno (whisper.cpp) i predaje
tekst klipbordu ili aktivnoj aplikaciji. Sve ostaje na mašini — nema oblaka i
nema npm paketa.

## Pokretanje

```bash
node pitchi.js stanje          # provera okruženja
node pitchi.js diktat          # snimi → prepiši → klipbord
node pitchi.js --help
npm test                       # node:test, ugrađeno
```

## Struktura

```
pitchi.js        ulaz (entry point) — parsira opcije i zove lib/
lib/pomoc.js     zajedničke stvari (alati, putanje, ispis)
lib/snimak.js    snimanje preko ffmpeg-a (AVFoundation)
lib/prepis.js    whisper.cpp — program, modeli, prepis
lib/tekst.js     čišćenje teksta, pbcopy, lepljenje
test/            testovi; pokretanje: node --test test/
snimci/, izlaz/  korisnikovi fajlovi — u .gitignore
```

## Pravila koja se lako prekrše

1. **Bez npm paketa.** Samo ugrađeni moduli Node-a (`node:fs`, `node:path`,
   `node:child_process`…). Ako zatreba paket, prvo predloži rešenje kroz
   ugrađene module ili sistemske alate (`ffmpeg`, `whisper-cli`, `pbcopy`).
2. **Node 22.5+**, ES moduli (`import`), ne CommonJS.
3. **Sve putanje kroz `path.join()` / `path.resolve()`** — nikad spajanje
   stringova sa `/`.
4. **Bezbedan rad sa fajlovima:**
   - probni rad (`--dry-run`) pre svake izmene,
   - postojeći fajl se ne prepisuje bez `--prepisi` (stari ide u `.bak`),
   - ne izlazi iz zadatog foldera (`putanjaUDaljem`),
   - snimci i prepisi nikad ne idu u git.
5. **Tekstovi i komentari na srpskom** (latinica); imena funkcija i
   promenljivih takođe na srpskom, bez dijakritika (`proveriFajl`).
6. **Git:** posle svakog završenog koraka `git add` + `git commit`, poruka na
   srpskom.
7. **Privatnost:** snimak i tekst ostaju lokalno. Nikakvo slanje na server,
   nema telemetrije.
8. **Dozvole:** mikrofon i „Accessibility“ traži korisnik; kod koji ih
   zahteva mora to jasno da kaže u poruci o grešci.

## Provera posle izmena

```bash
node --check pitchi.js lib/*.js
node pitchi.js --help
npm test
```

## Stanje projekta

*(Ovaj deo se prepisuje na kraju svake sesije.)*

- **23.10.2026.** — projekat pokrenut i postavljen skelet: `package.json`
  (bez zavisnosti), `.gitignore`, `pitchi.js` (CLI: `stanje`, `snimi`,
  `prepis`, `diktat`), `lib/` (pomoc, snimak, prepis, tekst), `test/`
  (11 provera), `README.md`, `AGENTS.md`.
  Utvrđeno: Apple-ov Speech framework na ovoj mašini **ne podržava srpski**
  (63 jezika, nema `sr`), pa je izbor pao na whisper.cpp.
  ffmpeg postoji (`/usr/local/bin/ffmpeg`); whisper.cpp i model još nisu
  instalirani.
- Sledeći korak: `brew install whisper-cpp` + model
  `ggml-large-v3-turbo-q5_0` (~574 MB), pa probni snimak srpskog.
