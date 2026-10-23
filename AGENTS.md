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
app/Info.plist    bundle, dozvole, Dock i menu bar
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
- **23.10.2026. (čišćenje)** — stara `Pichi.app` (`com.johnny.pichi`) potpuno
  uklonjena jer se i ona javljala na `Fn`. Model od 1 GB je pre toga premešten
  iz `~/Library/Application Support/Pichi/models/ggml-small-q5_1.bin` u
  `~/Library/Application Support/Pitchi/models/ggml-large-v3-q5_0.bin`
  (1.081.140.203 bajta). Obrisani su i stari Application Support (1,7 GB),
  `com.johnny.pichi.plist` i sam bundle; novi rečnik je već bio identičan.
  `--test-whisper` sada čita novu putanju i daje isti srpski tekst za ~3,2 s.
  Na mašini je ostala samo nova aplikacija, ušteda ~730 MB.
- **23.10.2026. (jezici)** — diktat sada automatski prepoznaje **srpski i
  engleski**; podrazumevano je `auto` umesto `sr`. Bitna zamka: u whisper.cpp
  1.9.5 polje `detect_language` služi **samo za detekciju** i vraća se pre
  dekodiranja (prazan tekst). Zato se detekcija pokreće vrednošću `"auto"` u
  `params.language`, a `detect_language` ostaje `false`. Prepoznati jezik se
  pamti uz zapis; `hr`/`bs` se prikazuju kao `sr` jer je izlaz isti. DeepSeek
  dobija uputstvo na prepoznatom jeziku. Provereno TTS snimcima: srpski daje
  isti tekst, engleski „Pitchi, Test, My name is Nemanja Čedomirović…”; auto
  detekcija dodaje ~1,5 s (prepis ~4,5 s umesto ~3 s).
- **23.10.2026. (objava)** — projekat je javno objavljen:
  <https://github.com/cedomirovic/pitchi> (MIT licenca). Dodati su `LICENSE`,
  uputstvo za instalaciju iz izvornog koda i dve slike u `docs/`. Provereno je
  da **svež klon** radi: `app/build.sh` sam preuzme i kompajlira whisper.cpp
  (5–10 min), pa napravi aplikaciju; `--test-whisper` na engleskom daje isti
  tekst. Napravljen je i release `v0.1.0` sa `Pitchi-0.1.0-macOS-arm64.zip`
  (2,9 MB, ad-hoc potpis, bez modela). Aplikacija nije notarizovana — u
  uputstvu piše desni klik → Open ili `xattr -dr com.apple.quarantine`.
- **23.10.2026. (modeli, prijava, Dock)** — dodato je biranje modela sa
  preuzimanjem u aplikaciji, opciono pokretanje pri prijavi i ikonica u Docku.
  Odluke:
  - katalog `PonudaModela.swift`: Tiny (77.691.713 B), Base (147.951.465 B),
    Small (487.601.967 B), Large v3 Turbo (574.041.195 B) i Large v3
    (1.081.140.203 B); model je „preuzet” samo ako veličina tačno odgovara;
  - novi korisnici dobijaju Turbo kao preporučeni model, a stara podešavanja
    bez polja `model` automatski biraju najbolji model koji već postoji na
    disku (kod korisnika je to Large v3);
  - `Prijava.swift` koristi `SMAppService.mainApp` (macOS 13+), bez
    LaunchAgenta; u Podešavanjima postoji i dugme za Login Items ako macOS
    traži odobrenje;
  - `LSUIElement` je uklonjen, aplikacija je `.regular` pa se vidi u Docku i
    Cmd+Tab-u; `applicationShouldHandleReopen` ponovo otvara prozor klikom na
    Dock, a `applicationWillTerminate` sinhrono oslobađa whisper model
    (`oslobodiSada`) da Metal ne bi pucao pri izlasku.
  Provereno na živoj aplikaciji: picker nudi svih pet modela, Tiny je preuzet
  kroz UI (74 MB, tačna veličina), prepis Tiny modelom radi (~0,4 s) ali je
  kvalitet slabiji; posle probe je Tiny obrisan i vraćen je Large v3. Login
  item je uključen i isključen kroz UI (`sfltool dumpbtm` potvrdio), a
  aplikacija je posle zatvaranja prozora ponovo otvorena preko Docka. Verzija
  je podignuta na `0.2.0` i objavljen je release `v0.2.0` sa
  `Pitchi-0.2.0-macOS-arm64.zip` (2,9 MB, SHA-256
  `6f47d7f8d8453dfdb69da092aec9482566cff583f7271c1f7a085d573c7b02b3`).
- **23.10.2026. (izbor LLM servisa)** — doterivanje više nije vezano samo za
  DeepSeek. Odluke:
  - `ProvajderiDoterivanja.swift` je katalog: DeepSeek, OpenAI / ChatGPT,
    Anthropic Claude, Ollama (lokalno) i „Drugi OpenAI-kompatibilni“;
    podrazumevani modeli su `deepseek-chat`, `gpt-4o-mini`,
    `claude-haiku-5-5`, `llama3.2` i `local-model`;
  - `Doterivac` zna tri formata: OpenAI chat, Anthropic Messages i Ollama chat;
    ima timeout od 60 s i jasnije poruke za 401/403, 404 i 429;
  - ključevi se čuvaju u Keychain-u **po servisu**; stari DeepSeek nalog
    `deepseek` ostaje važeći, a novi servisi dobijaju svoje naloge;
  - `Podesavanja` čuva `provajderDoterivanja`, `modeliDoterivanja` (model po
    servisu) i `adresaCustomDoterivanja`; stara podešavanja se dekodiraju bez
    greške i dalje koriste DeepSeek;
  - u Podešavanjima su izbor servisa, dinamičko polje za ključ, model, adresa
    za custom servis i dugme „Test veze“; verzija u „O aplikaciji“ se sada čita
    iz `Info.plist` (ranije je bila hardkodovana na `0.1.0`);
  - README i Pomoć objašnjavaju povezivanje svih servisa; posebno piše da
    **Claude Code nije API** i da se za Claude koristi Anthropic API ključ.
  Provereno: samostalni test protiv lokalnog mock servera za OpenAI,
  Anthropic i Ollama odgovore, HTTP 401, prazan tekst i nedostajući ključ;
  kroz UI su prošli „Test veze“ (uspeh i greška) i prebacivanje servisa sa
  čuvanjem/ucitavanjem ključa po servisu. Živi pozivi nisu probani jer nema
  API ključeva. Verzija je podignuta na `0.3.0` i objavljen je release
  `v0.3.0` sa `Pitchi-0.3.0-macOS-arm64.zip` (3,0 MB, SHA-256
  `bbb3aea0cefa7d298750a104efefed2305218d5da90f6c47cdc1f66f47530e92`).
- **23.10.2026. (ažuriranja)** — dodata je provera novih izdanja i obaveštenje.
  Odluke:
  - `Azuriranje.swift` čita `releases/latest` sa GitHub-a; poređenje verzija je
    brojevno (`0.10.0` ide posle `0.9.0`, `v` prefiks se ignoriše);
  - provera ide 4 s posle pokretanja i najviše jednom dnevno; timer na 6 h
    nadoknađuje propuštenu proveru posle spavanja ili prekida mreže;
  - `UNUserNotificationCenter` prikaže sistemsko obaveštenje (prvi put traži
    dozvolu), a klik otvara zip asset; ako obaveštenja nisu dozvoljena, radi
    traka u prozoru i naslov u menu baru;
  - u Podešavanjima → **Ažuriranja** su trenutna verzija, „Proveri ažuriranja“,
    dugmad „Preuzmi“ i „Stranica izdanja“, „Preskoči ovu verziju“ i prekidač
    `proveravajAzuriranja` (podrazumevano uključen; stara podešavanja se
    dekodiraju sa `true`);
  - poznata novija verzija se pamti u `UserDefaults` i vraća odmah pri sledećem
    pokretanju, dok dnevna provera ne stigne sa svežim linkom; ista verzija se
    obaveštava samo jednom, a preskočena se nudi ponovo tek posle ručne provere
    ili nove verzije;
  - aplikacija se ne menja sama — „Preuzmi“ otvara zip u browseru, pa korisnik
    zameni `Pitchi.app` u `/Applications`.
  Provereno: test poređenja verzija i dekodiranja GitHub odgovora protiv
  lokalnog mock servera; živa aplikacija je sa mock izdanjem `0.4.0`/`0.5.0`
  upisala `zadnjaVerzija` i `obavestenaVerzija`, a pravi GitHub je vratio
  `0.3.0` i aplikacija je ispravno zaključila da je `0.4.0` ažurna. Tabovi su
  nacrtani kroz `--slika` sa lažnim izdanjem (`PITCHI_SLIKA_AZURIRANJE=1`);
  `--test-whisper` i dalje daje isti srpski tekst. Verzija je podignuta na
  `0.4.0` (build 4) i instalirana u `/Applications`.
- Sledeći korak: probni diktat uživo sa Large v3 i stvarnim API ključem za
  izabrani servis, zatim po potrebi brisanje modela koje korisnik ne želi i
  eventualni prelazak `diktator` repoa na ovu aplikaciju.
