# Pitchi · lokalni alat za diktiranje

Treći projekat pored `moja-zemlja-crm` (port 3000) i `alat` (port 3001).
Ova dva se **ne diraju odavde** — svaki ima svoj `AGENTS.md` i svoj git.

Pitchi snima govor sa mikrofona, prepisuje ga lokalno (whisper.cpp) i predaje
tekst klipbordu ili aktivnoj aplikaciji. Sve ostaje na mašini — nema oblaka i
nema npm paketa. Glavni deo je sada **macOS aplikacija** (`app/`, Swift +
SwiftUI), a stari Node CLI (`pitchi.js`) ostaje kao rezerva.

## Pokretanje

```bash
bash app/build.sh                 # napravi app/build/Pitchi.app
bash app/instaliraj.sh            # build + kopija u /Applications
bash app/instaliraj.sh --prepisi  # zameni postojeću (stara u .bak)

# stari CLI
node pitchi.js stanje
node pitchi.js diktat
npm test
```

## Struktura

```
app/src/          Swift izvori (PitchiApp, AppStanje, Snimac, Prepisivac…)
app/Info.plist    bundle, dozvole, LSUIElement
app/build.sh      građenje + potpisivanje (swiftc, bez Xcode-a)
app/pripremi-whisper.sh  statički whisper.cpp (Metal + BLAS)
app/instaliraj.sh build + /Applications
app/vendor/       whisper.cpp biblioteke — ne ide u git
pitchi.js        stariji CLI ulaz — parsira opcije i zove lib/
lib/             stariji CLI (snimak, prepis, tekst)
test/            testovi; pokretanje: node --test test/
snimci/, izlaz/  korisnikovi fajlovi — u .gitignore
```

## Pravila koja se lako prekrše

1. **Bez npm paketa.** Samo ugrađeni moduli Node-a; za aplikaciju samo Swift,
   AppKit/SwiftUI i statički whisper.cpp — bez SPM/CocoaPods zavisnosti.
2. **Node 22.5+** za CLI, ES moduli (`import`), ne CommonJS.
3. **Sve putanje kroz `path.join()` / `path.resolve()`** u Node delu; u Swiftu
   kroz `URL`/`appendingPathComponent`, nikad spajanje stringova sa `/`.
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
   nema telemetrije. DeepSeek je opcion i šalje samo tekst.
8. **Dozvole:** mikrofon, „Accessibility“ i „Input Monitoring“ traži korisnik;
   kod koji ih zahteva mora to jasno da kaže u poruci o grešci.

## Provera posle izmena

```bash
node --check pitchi.js lib/*.js
node pitchi.js --help
npm test
bash app/build.sh
app/build/Pitchi.app/Contents/MacOS/Pitchi --test-whisper
```

## Stanje projekta

*(Ovaj deo se prepisuje na kraju svake sesije.)*

- **23.10.2026.** — projekat pokrenut i postavljen skelet: `package.json`
  (bez zavisnosti), `.gitignore`, `pitchi.js` (CLI: `stanje`, `snimi`,
  `prepis`, `diktat`), `lib/` (pomoc, snimak, prepis, tekst), `test/`
  (11 provera), `README.md`, `AGENTS.md`.
  Utvrđeno: Apple-ov Speech framework na ovoj mašini **ne podržava srpski**
  (63 jezika, nema `sr`), pa je izbor pao na whisper.cpp.
- **23.10.2026. (nastavak)** — napravljena prava macOS aplikacija u `app/`:
  AppKit + SwiftUI, menu bar, HUD tokom snimanja, istorija, rečnik, dozvole,
  preuzimanje modela, opciono DeepSeek doterivanje. Whisper.cpp 1.9.5 je
  **statički** ugrađen (Metal + BLAS), model `large-v3 q5_0` (1 GB).
  Ključne odluke:
  - model se učitava lenjo i oslobađa posle 5 min; radno stanje se oslobađa
    odmah posle prepisa (`whisper_state`), pa mirna aplikacija drži ~15 MB,
    a sa modelom ~1,4 GB (pik ~1,9 GB tokom prepisa);
  - srpski izlaz se transliteriše ćirilica → latinica (`Tekst.naLatnicu`);
  - `Fn` hold preko CGEventTap-a; lepljenje preko `Cmd+V` (Accessibility);
  - statičke biblioteke se grade sa `CMAKE_OSX_DEPLOYMENT_TARGET=13.0`.
  Provereno: TTS snimak (`/tmp/sr.wav`) daje „Pitchi, Test, Nemanja
  Čedomirović, Tamara Pandža. Danas je lepo vreme u Beogradu.” za ~2,8 s
  (posle prvog Metal kompajliranja).
  Instalirano u `/Applications/Pitchi.app`, potpis `Pichi Local Dev`.
- Sledeći korak: korisnik da dozvole (mikrofon, nadzor unosa, pristupačnost),
  probni diktat uživo i doterivanje po potrebi; zatim eventualno prelazak
  `diktator` repoa na ovu aplikaciju.
