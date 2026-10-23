# Pitchi · lokalno diktiranje

Pitchi pretvara govor u tekst — na tvom Macu, bez slanja snimka na internet.
Snimiš mikrofon, Whisper prepiše, tekst ode u klipbord (ili se sam zalepi u
aplikaciju u kojoj pišeš).

Projekat je u ranoj fazi: radi komandna linija; sledeći korak je globalna
prečica i rad iz meni bara.

## Šta je potrebno

| Alat | Zašto | Instalacija |
| --- | --- | --- |
| Node 22.5+ | pokreće Pitchi (bez npm paketa) | već instaliran (v26) |
| ffmpeg | snimanje mikrofona | `brew install ffmpeg` (već je tu) |
| whisper.cpp | prepis govora u tekst | `brew install whisper-cpp` |
| model | „mozak“ za srpski | vidi „Modeli“ ispod |

### Modeli

Modeli se ne drže u git-u. Preporučeni folder:

```bash
mkdir -p "$HOME/Library/Application Support/Pitchi/modeli"
```

Brži i manji (≈574 MB), dobar za diktanje:

```bash
curl -L -o "$HOME/Library/Application Support/Pitchi/modeli/ggml-large-v3-turbo-q5_0.bin" \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin"
```

Tačniji i veći (≈1,6 GB):

```bash
curl -L -o "$HOME/Library/Application Support/Pitchi/modeli/ggml-large-v3-turbo.bin" \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
```

Pitchi sam nađe model u `modeli/` (u projektu), u
`~/Library/Application Support/Pitchi/modeli/` i u `~/.cache/whisper.cpp/`.
Može i eksplicitno: `--model /putanja/do/ggml-....bin` ili promenljiva
`PITCHI_MODEL`.

## Korišćenje

```bash
node pitchi.js stanje                 # šta je instalirano i koji modeli postoje
node pitchi.js diktat --sekundi 15    # snimi 15 s, prepiši, stavi u klipbord
node pitchi.js diktat --ubaci         # isto, ali odmah zalepi u aktivnu aplikaciju
node pitchi.js snimi snimci/test.wav --sekundi 5
node pitchi.js prepis snimci/test.wav --izlaz izlaz/test.txt --u-klipbord
node pitchi.js --help                 # sve opcije
```

Probni rad (ništa se ne menja):

```bash
node pitchi.js diktat --dry-run --sekundi 10
```

### Dozvole (macOS)

- **Mikrofon** — pri prvom snimanju macOS pita da Terminal sme da koristi
  mikrofon. Ako se odbije: Sistemska podešavanja → Privatnost i bezbednost →
  Mikrofon.
- **Pristupačnost** (samo za `--ubaci`) — Terminal mora imati dozvolu
  „Accessibility“, inače se `Cmd+V` ignoriše.

## Struktura

```
pitchi.js        ulaz — parsira opcije i zove lib/
lib/pomoc.js     pronalaženje alata, čuvanje putanja, ispis
lib/snimak.js    snimanje mikrofona preko ffmpeg-a (AVFoundation)
lib/prepis.js    whisper.cpp: pronalaženje programa i modela, prepis
lib/tekst.js     čišćenje teksta, klipbord, lepljenje u aplikaciju
test/            testovi (node:test)
snimci/, izlaz/  tvoji snimci i prepisi (nisu u git-u)
```

## Plan

- [x] skelet, CLI (`stanje`, `snimi`, `prepis`, `diktat`)
- [ ] instalacija whisper.cpp + model, prvi pravi prepis srpskog
- [ ] globalna prečica (snimanje „na dugme“, bez terminala)
- [ ] meni bar ikonica i status snimanja
- [ ] podešavanja (jezik, model, unos vs. klipbord)

## Provera

```bash
npm test
node --check pitchi.js lib/*.js
node pitchi.js stanje
```
