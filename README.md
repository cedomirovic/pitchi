# Pitchi — diktiranje na srpskom i engleskom (macOS)

Pitchi je macOS aplikacija za dikiranje: držiš `Fn`, izgovoriš rečenicu, pusti
— tekst se prepiše **lokalno** (whisper.cpp) i zalepi u aplikaciju u kojoj
pišeš. Jezik se prepoznaje automatski, pa srpski i engleski mogu da se smenjuju
bez podešavanja. Snimak ne napušta Mac.

Aplikacija ima prozor sa stanjem, istorijom, rečnikom i podešavanjima, ikonu u
Docku i u menu baru. Model se učitava samo tokom diktiranja i oslobađa posle
5 minuta, pa i 8 GB Mac ostaje upotrebljiv. Koji model se koristi biraš sam, a
lakši modeli se preuzimaju direktno iz aplikacije.

| Početak | Podešavanja |
|---|---|
| ![Početak](docs/pocetak.png) | ![Podešavanja](docs/podesavanja.png) |

## Šta radi

- **Fn kao prečica** — drži i govori, pusti kada završiš; radi i van Pitchi-ja.
- **Automatsko lepljenje** — pošalje `Cmd+V` u aplikaciju u kojoj si bio; ako
  dozvola nije data, tekst čeka u klipbordu.
- **Srpski i engleski** — jezik se prepoznaje automatski; srpski izlaz ide u
  latinicu.
- **Rečnik** — imena i pojmovi koje model pogrešno piše.
- **Istorija** — zadnjih 200 prepisa, pretraga i kopiranje.
- **Izbor modela** — Tiny, Base, Small, Large v3 Turbo i Large v3; lakši modeli
  se preuzimaju iz same aplikacije, bez terminala.
- **Pokretanje pri prijavi** — opciono u Podešavanjima, preko macOS Login Items.
- **Dock i menu bar** — ikonica je vidljiva na oba mesta; klik na Dock ponovo
  otvara prozor.
- **Opciono DeepSeek doterivanje** — popravi interpunkciju i imena; isključeno
  po defaultu, šalje se samo tekst, nikada zvuk.

## Instalacija

### Gotova aplikacija

1. Preuzmi `Pitchi-0.2.0-macOS-arm64.zip` sa
   [Releases](https://github.com/cedomirovic/pitchi/releases/latest).
2. Otpakuj i prevuci `Pitchi.app` u `/Applications`.
3. Prvi put: desni klik na aplikaciju → **Open** → **Open** ponovo. Aplikacija
   nije notarizovana, pa je macOS inače blokira. Alternativa:
   `xattr -dr com.apple.quarantine /Applications/Pitchi.app`.

Potreban je Apple Silicon i macOS 13 ili noviji.

### Iz izvornog koda

Potrebni su Command Line Tools (`xcode-select --install`), `cmake`
(`brew install cmake`) i `git` — samo za prvo građenje whisper.cpp-a.

```bash
git clone https://github.com/cedomirovic/pitchi.git
cd pitchi
bash app/instaliraj.sh            # prvi put
bash app/instaliraj.sh --prepisi  # nova verzija (stara ide u .bak)
```

Prvo građenje traje **5–10 minuta** jer se whisper.cpp i Metal biblioteke
kompajliraju jednokratno. Skripta napravi `Pitchi.app`, potpiše ga lokalno
(ad-hoc ako nema razvojnog sertifikata) i smesti u `/Applications`.

### Prvo pokretanje

1. Otvori Pitchi — prozor se pojavi sam, a ikona je u Docku i u menu baru.
2. Daj tri dozvole iz prozora:
   - **Mikrofon** — da čuje govor.
   - **Nadzor unosa** — da prepozna `Fn` i van Pitchi-ja. Posle ove dozvole
     zatvori i ponovo otvori aplikaciju.
   - **Pristupačnost** — da pošalje `Cmd+V` posle prepisa.
3. U Podešavanjima → **Model** izaberi model. Preporučeni Large v3 Turbo ima
   547 MB; ako želiš najmanji, izaberi Tiny (74 MB).

Ako `Fn` otvara emoji birač: Podešavanja → Tastatura → „Pritisni 🌐 key za” →
**Ne radi ništa**.

## Model i memorija

Preporučeni model je **Large v3 Turbo q5_0** (547 MB): brz je, troši manje
memorije i kvalitetom je blizu Large v3. U Podešavanjima → **Model** možeš
izabrati i drugi model; svi se preuzimaju jednokratno sa Hugging Face-a.

| Model | Veličina | Kada ga izabrati |
|---|---|---|
| Tiny | 74 MB | najbrži, za probe; češće greši imena |
| Base | 141 MB | mali i brz, osnovni kvalitet |
| Small | 465 MB | kada je malo RAM-a, solidan kvalitet |
| Large v3 Turbo | 547 MB | **preporučeno za 8 GB** |
| Large v3 | 1,0 GB | najbolji kvalitet, traži više RAM-a |

Modeli se čuvaju u:

```
~/Library/Application Support/Pitchi/models/
```

Dok je model učitan, aplikacija drži ~0,2–1,4 GB, zavisno od izbora; posle
5 minuta mirovanja se oslobađa. Prvi prepis posle novog builda je sporiji jer
se kompajliraju Metal šejderi; sledeći su nekoliko sekundi za kraću rečenicu
(uključujući detekciju jezika).

## Privatnost

- Snimak se ne čuva i ne šalje nigde.
- Istorija i rečnik su lokalni fajlovi u `~/Library/Application Support/Pitchi/`.
- DeepSeek je opcion i šalje samo gotov tekst, nikada zvuk.

## Razvoj

```
app/
  src/                 Swift izvori (AppKit + SwiftUI)
  Info.plist           bundle, dozvole, Dock i menu bar
  build.sh             građenje + potpisivanje
  pripremi-whisper.sh  jednokratno građenje statičkog whisper.cpp-a
  instaliraj.sh        build + /Applications
  vendor/              whisper.cpp biblioteke (ne ide u git)
pitchi.js, lib/, test/ stariji CLI (Node, bez paketa)
```

```bash
bash app/build.sh
open app/build/Pitchi.app
```

Whisper je **statički** ugrađen (Metal + BLAS), pa aplikacija ne zavisi od
Homebrew-a na ciljnom Macu. Skrivene razvojne opcije: `--slika` (nacrta tabove
u PNG), `--test-whisper` (prepiše `/tmp/sr.wav` kroz isti kod).

## Stariji CLI

`pitchi.js` je prva verzija (Node 22.5+, ffmpeg + whisper-cli) i još radi:

```bash
node pitchi.js stanje
node pitchi.js diktat
npm test
```

## Zahvalnost

- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) (MIT)
- OpenAI Whisper modeli Tiny, Base, Small, Large v3 Turbo i Large v3 (MIT)
