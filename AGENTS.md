# Diktator · lokalni alat za diktiranje

Treći projekat pored `moja-zemlja-crm` (port 3000) i `alat` (port 3001).
Ova dva se **ne diraju odavde** — svaki ima svoj `AGENTS.md` i svoj git.

Diktator snima govor sa mikrofona, prepisuje ga lokalno (whisper.cpp) i predaje
tekst klipbordu ili aktivnoj aplikaciji. Sve ostaje na mašini — nema oblaka i
nema npm paketa. Glavni deo je sada **macOS aplikacija** (`app/`, Swift +
SwiftUI), a stari Node CLI (`diktator.js`) ostaje kao rezerva.

## Pokretanje

```bash
bash app/build.sh                 # napravi app/build/Diktator.app
bash app/instaliraj.sh            # build + kopija u /Applications
bash app/instaliraj.sh --prepisi  # zameni postojeću (stara u .bak)

# stari CLI
node diktator.js stanje
node diktator.js diktat
npm test
```

## Struktura

```
app/src/          Swift izvori (DiktatorApp, AppStanje, Snimac, Prepisivac…)
app/Info.plist    bundle, dozvole, Dock i menu bar
app/build.sh      građenje + potpisivanje (swiftc, bez Xcode-a)
app/pripremi-whisper.sh  statički whisper.cpp (Metal + BLAS)
app/instaliraj.sh build + /Applications
app/vendor/       whisper.cpp biblioteke — ne ide u git
diktator.js        stariji CLI ulaz — parsira opcije i zove lib/
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
node --check diktator.js lib/*.js
node diktator.js --help
npm test
bash app/build.sh
app/build/Diktator.app/Contents/MacOS/Diktator --test-whisper
app/build/Diktator.app/Contents/MacOS/Diktator --dozvole
```

## Stanje projekta

*(Ovaj deo se prepisuje na kraju svake sesije. Istorijske beleške koriste
današnje ime aplikacije.)*

- **23.10.2026.** — projekat pokrenut i postavljen skelet: `package.json`
  (bez zavisnosti), `.gitignore`, `diktator.js` (CLI: `stanje`, `snimi`,
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
  Provereno: TTS snimak (`/tmp/sr.wav`) daje „Diktator, Test, Nemanja
  Čedomirović, Tamara Pandža. Danas je lepo vreme u Beogradu.” za ~2,8 s
  (posle prvog Metal kompajliranja).
  Instalirano u `/Applications/Diktator.app`, potpis `Pichi Local Dev`.
- **23.10.2026. (čišćenje)** — stara `Pichi.app` (`com.johnny.pichi`) potpuno
  uklonjena jer se i ona javljala na `Fn`. Model od 1 GB je pre toga premešten
  iz `~/Library/Application Support/Pichi/models/ggml-small-q5_1.bin` u
  `~/Library/Application Support/Diktator/models/ggml-large-v3-q5_0.bin`
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
  isti tekst, engleski „Diktator, Test, My name is Nemanja Čedomirović…”; auto
  detekcija dodaje ~1,5 s (prepis ~4,5 s umesto ~3 s).
- **23.10.2026. (objava)** — projekat je javno objavljen:
  <https://github.com/cedomirovic/pitchi> (MIT licenca). Dodati su `LICENSE`,
  uputstvo za instalaciju iz izvornog koda i dve slike u `docs/`. Provereno je
  da **svež klon** radi: `app/build.sh` sam preuzme i kompajlira whisper.cpp
  (5–10 min), pa napravi aplikaciju; `--test-whisper` na engleskom daje isti
  tekst. Napravljen je i release `v0.1.0` sa `Diktator-0.1.0-macOS-arm64.zip`
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
  `Diktator-0.2.0-macOS-arm64.zip` (2,9 MB, SHA-256
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
  `v0.3.0` sa `Diktator-0.3.0-macOS-arm64.zip` (3,0 MB, SHA-256
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
    zameni `Diktator.app` u `/Applications`.
  Provereno: test poređenja verzija i dekodiranja GitHub odgovora protiv
  lokalnog mock servera; živa aplikacija je sa mock izdanjem `0.4.0`/`0.5.0`
  upisala `zadnjaVerzija` i `obavestenaVerzija`, a pravi GitHub je vratio
  `0.3.0` i aplikacija je ispravno zaključila da je `0.4.0` ažurna. Tabovi su
  nacrtani kroz `--slika` sa lažnim izdanjem (`DIKTATOR_SLIKA_AZURIRANJE=1`);
  `--test-whisper` i dalje daje isti srpski tekst. Verzija je podignuta na
  `0.4.0` (build 4) i instalirana u `/Applications`. Objavljen je release
  `v0.4.0` sa `Diktator-0.4.0-macOS-arm64.zip` (3,0 MB, SHA-256
  `244d39a0cb2bb7a3c85e421414271a2b678a0b9a41843147f986109e88a91bf1`).
- **23.10.2026. (ime)** — aplikacija je preimenovana u **Diktator**.
  Odluke:
  - `Diktator.app`, izvršni fajl `Diktator`, `CFBundleDisplayName` i
    `CFBundleName` su novi; svi vidljivi tekstovi (meni, prozor, HUD,
    obaveštenja, pomoć, README) takođe. Fajlovi su `DiktatorApp.swift`,
    `Diktator-Bridging-Header.h`, `diktator.js` i `diktator.test.mjs`.
  - `CFBundleIdentifier` je ostao `com.cedomirovic.pitchi`, a UserDefaults
    ključ i Keychain servis takođe, da dozvole, podešavanja, API ključevi i
    login item nastave da rade bez ponovnog davanja. Zato u tim internim
    identifikatorima i dalje stoji staro ime — to je svesna kompatibilnost.
  - `~/Library/Application Support/Pitchi` se pri prvom pokretanju premešta u
    `~/Library/Application Support/Diktator` (model, istorija, rečnik); ako
    premestanje ne uspe, koristi se stari folder. Isto radi i stari CLI.
  - `instaliraj.sh` instalira `Diktator.app`, a stariju kopiju istog bundle
    ID-a pronalazi po identifikatoru i čuva je kao `.bak`.
  - Razvojne promenljive su `DIKTATOR_AZURIRANJE_API` i
    `DIKTATOR_SLIKA_AZURIRANJE`; lažno izdanje za `--slika` je `0.6.0`.
  - Javni repo za izdanja je zadržao adresu `cedomirovic/pitchi` jer se tu već
    nalaze release-i; `cedomirovic/diktator` je drugi, privatni projekat i nije
    diran.
  Provereno: `node --check diktator.js lib/*.js`, `node diktator.js --help`,
  `npm test` (11/11), `bash app/build.sh`, `--test-whisper` sa novim TTS
  snimkom daje „Diktator, Test, Nemanja Čedomirović, Tamara Pandža. Danas je
  lepo vreme u Beogradu.”, `--dozvole` čita stvarne dozvole, a `--slika` crta
  tabove sa imenom Diktator. Verzija je podignuta na `0.5.0` (build 5);
  instalirano u `/Applications/Diktator.app`, login item ponovo uključen preko
  `--prijava`. Objavljen je release `v0.5.0` sa
  `Diktator-0.5.0-macOS-arm64.zip` (3,0 MB, SHA-256
  `d067de37fd14e826e4ec0e78ba33635116ae70fab4ab010ed291e3fa969305f8`);
  starija izdanja zadržavaju istorijske nazive fajlova.
- **23.10.2026. (prečica)** — dodato je biranje prečice za diktiranje.
  Odluke:
  - `Precica` u `Modeli.swift` nudi `Fn`, desni `Option`, `Command`, `Control`
    i `Shift`, kao i `F13`–`F19`; desni modifikatori su izabrani da levi
    ostane slobodan za normalno kucanje.
  - `Podesavanja.precica` čuva izbor i podrazumevano je `fn`; stara
    podešavanja bez tog polja se dekodiraju kao `Fn`, a nepoznata vrednost se
    vraća na `Fn`.
  - `Tastatura` sada sluša `flagsChanged`, `keyDown` i `keyUp`; ponovljeni
    `keyDown` se ignoriše, `Fn` koristi `.maskSecondaryFn`, a desni
    modifikatori `CGEventSource.keyState`. Event tap ostaje živ pa promena
    prečice važi odmah; ako se prečica promeni usred snimanja, snimak se
    završava da ne ostane zaglavljen.
  - U Podešavanjima → Diktiranje je izbor „Prečica za diktiranje“, a svi
    vidljivi tekstovi (Početak, HUD, pomoć, dozvole, istorija i tooltip u menu
    baru) prate izabranu prečicu.
  Provereno: `node --check diktator.js lib/*.js`, `node diktator.js --help`,
  `npm test` (11/11), `bash app/build.sh`; `--slika` crta novi izbor, a
  `docs/pocetak.png` i `docs/podesavanja.png` su ponovo nacrtani. Kroz UI je
  prečica promenjena `Fn` → `F13` → `Fn`, a podešavanja su sadržala
  `"precica": "f13"` odnosno `"fn"`. Sintetički `F13` (držan 5 s) prikazuje
  „Snimam…“ i „Pusti F13 kada završiš“, a kratak `F13` kroz System Events daje
  „Snimak je prekratak — drži F13 dok govoriš.“ `--test-whisper` i dalje daje
  isti srpski tekst, a `--dozvole` čita stvarne dozvole. Desni modifikatori
  nisu probani fizički (na mašini nema takvog tastera u testu), ali su izbor,
  keycode i logika preko `CGEventSource.keyState` provereni kodom.
  Verzija je podignuta na `0.6.0` (build 6), `package.json` na `0.6.0`, a
  lažno izdanje za `--slika` je `0.7.0`. Instalirano je u
  `/Applications/Diktator.app`; objavljen je release `v0.6.0` sa
  `Diktator-0.6.0-macOS-arm64.zip` (3,0 MB, SHA-256
  `de8569f72317790e6c248f2d1718dd1e7b2e83eb54bcae4b41327759946488b4`).
- **23.10.2026. (zahvalnica)** — dodata je zahvalnica da je Diktator inspirisan
  aplikacijom **Pichi** (<https://github.com/ndjerma/pichi-release>). U README-u
  je prva stavka u „Zahvalnost“, a u Podešavanjima → **O aplikaciji** stoji
  link „Inspirisano aplikacijom Pichi“. Verzija je podignuta na `0.6.1`
  (build 7), `package.json` na `0.6.1`; `--slika` i `docs/pocetak.png` /
  `docs/podesavanja.png` su ponovo nacrtani. Provereno: `node --check`,
  `npm test` (11/11), `--dozvole`, `--test-whisper` daje isti srpski tekst;
  instalirano u `/Applications/Diktator.app`. Objavljen je release `v0.6.1`
  sa `Diktator-0.6.1-macOS-arm64.zip` (3,0 MB, SHA-256
  `0b62ea24e8a1d80217c560031ed08c6638ac428c0f367a7ca9ba4bfce1d37ba6`).
- **25.10.2026. (memorija, režim prepisa, bezbednost)** — aplikacija je
  optimizovana da troši manje RAM-a, a bezbednosne provere su zaokružene.
  Odluke:
  - model se sada oslobađa po izabranom vremenu i kada snimak bude prekratak,
    otkazan, tih ili kada whisper baci grešku; ranije je u tim putevima timer
    ostajao nezakazan pa je model mogao zauvek da ostane u RAM-u;
  - timer se zakazuje odmah posle prepisa, pre opcionog doterivanja, pa model
    može da se oslobodi dok LLM još čeka mrežu;
  - snimak je ograničen na 5 minuta (`Snimac.najduzeSekundi`), da ne raste
    neograničeno; audio tap više ne pravi privremeni niz za svaki deo;
  - dodat je `RezimPrepisa`: `kvalitet` (beam search 5, staro ponašanje) i
    `stedljivo` (greedy `best_of = 1`); nova instalacija podrazumevano dobija
    `stedljivo`, a stara podešavanja bez polja se dekodiraju kao `kvalitet`;
    korisniku je kroz UI izabran `stedljivo` (može da vrati `kvalitet`);
  - izmereno na `/tmp/sr.wav` sa Large v3: beam 5 ~2,37 GB, greedy ~1,93 GB
    (ušteda ~440 MB), isti tekst; u pregledu stoji savet da Turbo troši ~500 MB
    manje od Large v3;
  - bezbednosne izmene: Keychain stavke sa
    `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, LLM adrese samo `https://`
    (osim `localhost`/`127.0.0.1`), GitHub samo za ažuriranja, fajlovi
    `0700`/`0600`, provera statusa/preusmeravanja/veličine preuzimanja,
    `SECURITY.md`.
  Provereno: `node --check diktator.js lib/*.js`, `npm test` (11/11),
  `bash app/build.sh` (10 postojećih upozorenja), `--test-whisper` u oba režima
  daje isti srpski tekst, `--dozvole` čita stvarne dozvole, a kroz UI su
  provereni izbor režima (upis `"rezimPrepisa": "stedljivo"`) i vraćanje
  provajdera na DeepSeek. Verzija je `0.7.0` (build 9), `package.json` `0.7.0`;
  lažno izdanje za `--slika` je `0.8.0`. Instalirano u
  `/Applications/Diktator.app`; objavljen je release `v0.7.0` sa
  `Diktator-0.7.0-macOS-arm64.zip` (3,1 MB, SHA-256
  `5aedd193a5e25e7a50d874c918083b98c037d98df1b6bd82367af027e3d938fd`).
- **25.10.2026. (Fn + Space)** — dodata je prečica `Fn + Space` koja radi kao
  prekidač: prvi pritisak počinje snimak, drugi ga završava i šalje tekst.
  Odluke:
  - `Precica.fnSpace` (`"fn-space"`, keycode 49) je nova stavka u izboru;
    `jePrekidac` menja uputstva u celom UI-ju (Početak, HUD, Pomoć, Istorija,
    Podešavanja, tooltip u menu baru), a stare prečice i dalje rade kao
    „drži i govori“;
  - `Tastatura` na `keyDown` sa Fn flagom zove `naPrekidac` →
    `AppStanje.prebaciSnimanje()`; ponovljeni `keyDown` se ignoriše, a Space
    `keyDown`/`keyUp` se proguta (`progutajSpace`) da se razmak ne upiše u
    aktivnu aplikaciju; kombinacije sa Cmd/Ctrl/Option se ne hvataju;
  - promena prečice usred snimanja završava snimak (`sacuvajPodesavanja`);
  - kroz UI je korisniku izabran `Fn + Space` (upis `"precica": "fn-space"`),
    a stara podešavanja bez tog polja ostaju `Fn` (drži);
  - `--slika` je ponovo nacrtao `docs/pocetak.png` i `docs/podesavanja.png`
    sa prekidačem i lažnim izdanjem `0.8.0` („Imaš 0.7.1“).
  Provereno: `node --check diktator.js lib/*.js`, `node diktator.js --help`,
  `npm test` (11/11), `bash app/build.sh` (10 postojećih upozorenja),
  `--test-whisper` u oba režima daje isti srpski tekst, `--dozvole` čita
  stvarne dozvole; sintetički `Fn + Space` je pokrenuo snimak („Snimam…“,
  „Govori sada — pritisni Fn + Space ponovo da završiš.“), drugi pritisak ga
  zaustavio i vratio u „Spreman“; u TextEdit-u je posle oba pritiska ostalo
  samo „X“ (Space nije upisan), a zatim je tekst zalepljen. Verzija je
  `0.7.1` (build 10), `package.json` `0.7.1`; lažno izdanje za `--slika` je
  `0.8.0`. Instalirano u `/Applications/Diktator.app`; objavljen je release
  `v0.7.1` sa `Diktator-0.7.1-macOS-arm64.zip` (3,1 MB, SHA-256
  `e3756280177cfd474f097a3fcb2d4f0d98d974c99db0bdc0493bbad19550a582`).
- **25.10.2026. (Gemini, čist paket)** — doterivanje sada podržava i **Google
  Gemini**, a pripremljen je čist paket za slanje drugima. Odluke:
  - `ProvajderiDoterivanja.gemini` (`id: "gemini"`) koristi Gemini REST
    `POST /v1beta/models/{model}:generateContent`, ključ ide u zaglavlje
    `x-goog-api-key`, a telo u camelCase formatu (`systemInstruction`,
    `contents`, `generationConfig`); odgovor se čita iz
    `candidates[].content.parts[].text`, a delovi sa `thought: true` se
    preskaču;
  - podrazumevani model je `gemini-3.5-flash-lite` (Gemini 2.5 je ograničen na
    postojeće korisnike), a model se može promeniti u polju **Model**;
    `models/` prefiks se skida pre sastavljanja URL-a, a naziv sme da sadrži
    samo slova, brojeve, tačku, crtu i donju crtu;
  - Gemini je dodat u README, Pomoć i tehnički pregled; stari DeepSeek ključ i
    podešavanja ostaju netaknuti;
  - verzija je `0.8.0` (build 11), `package.json` `0.8.0`, a lažno izdanje za
    `--slika` je `0.9.0` („Imaš 0.8.0“); `docs/pocetak.png` i
    `docs/podesavanja.png` su ponovo nacrtani;
  - Dock je očišćen: uklonjen je zaostali unos iz `recent-apps`, a provera je
    potvrdila samo jedan `AXDockItem` za `/Applications/Diktator.app`.
  Provereno: `node --check diktator.js lib/*.js`, `node diktator.js --help`,
  `npm test` (11/11), `bash app/build.sh`, `--test-whisper` u oba režima daje
  isti srpski tekst, `--dozvole` čita stvarne dozvole; Gemini je testiran
  protiv lokalnog mock servera (uspešan odgovor sa `thought` delom, HTTP 401 i
  `models/` prefiks). Aplikacija je instalirana u `/Applications/Diktator.app`
  (0.8.0, build 11), a podešavanja su zadržala Large v3, `Fn + Space`,
  `stedljivo` i isključeno doterivanje. Objavljen je release `v0.8.0` sa
  `Diktator-0.8.0-macOS-arm64.zip` (3.209.707 bajtova, SHA-256
  `85da08f212f7c4bcfd4fa268130109b618aff9da594d0fa32d4c0f51ef1a0c28`);
  paket je očišćen od `__MACOSX` metapodataka i proveren posle raspakivanja
  (`codesign --verify`, verzija 0.8.0/11).
- **27.10.2026. (statistika)** — dodat je tab **Statistika**, po uzoru na
  Wispr Flow. Odluke:
  - `Statistika.swift` je zaseban modul: `StatistickiZapis` (datum, reči,
    trajanje, jezik, model, uspeh) i `Statistika` kao vrednosni tip, pa svaka
    promena kroz `@Published` automatski osveži SwiftUI;
  - tekst diktata se **ne** upisuje — samo brojevi; fajl je
    `~/Library/Application Support/Diktator/statistika.json` sa dozvolama 0600;
  - mere: ukupno reči, diktati, vreme diktiranja, brzina govora, ušteđeno vreme
    prema kucanju od 40 reči/min, današnji brojevi, serija dana zaredom,
    neuspeli pokušaji, aktivnost za 14 dana i podela po jeziku i modelu;
  - neuspeo prepis se broji kao pokušaj, ali ne ulazi u reči ni u vreme;
  - pamtimo najviše 5.000 zapisa, da fajl ne raste unedogled;
  - grafikon je nacrtan običnim SwiftUI oblicima, bez Swift Charts, da se ne
    dodaju novi framework-i u `build.sh`;
  - tab je umetnut na indeks 2, pa su Podešavanja sada 3, a Pomoć 4; svi skokovi
    na podešavanja su pomereni.
  Provereno: `node --check`, `node diktator.js --help`, `npm test` (11/11),
  `bash app/build.sh`, `--dozvole`; `--slika` je nacrtao svih pet tabova, a
  demo prikaz statistike je pregledan (1.460 reči, 26 min ušteđeno, grafikon).
  Verzija je `0.9.0` (build 12), `package.json` `0.9.0`; lažno izdanje za
  `--slika` je `1.0.0`. Aplikacija je instalirana u `/Applications/Diktator.app`.
  Release se objavljuje posle korisnikove provere uživo.
- Sledeći korak: probni diktat uživo i provera da statistika raste i da se
  `statistika.json` upisuje sa dozvolama 0600; zatim objava release-a `v0.9.0`.
  Posle toga: probni diktat sa stvarnim Gemini API ključem (ili drugim izabranim
  servisom), fizički probati `Fn + Space` i desni modifikator na tastaturi koja
  ga ima, zatim po potrebi brisanje modela koje korisnik ne želi i eventualni
  prelazak `diktator` repoa na ovu aplikaciju.
