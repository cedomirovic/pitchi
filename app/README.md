# Pitchi

Diktiranje na srpskom i engleskom, lokalno, na macOS-u. Držiš `Fn`, izgovoriš
rečenicu, pustiš — tekst se prepiše i zalepi tamo gde pišeš. Jezik se prepoznaje
automatski, pa možeš da menjaš srpski i engleski bez podešavanja.

Sve ostaje na Macu: snimak se obrađuje whisper.cpp modelom u samoj aplikaciji,
bez servera i bez naloga. Jedini mrežni izlaz je preuzimanje modela (1 GB) i
opciono DeepSeek doterivanje teksta, koje sam uključuješ.

## Šta dobijaš

- **Prozor sa jasnim stanjem** — vidiš kada snima, kada priprema model i kada
  prepisuje; istorija i podešavanja su na jednom mestu.
- **Fn kao prečica** — radi i kada je druga aplikacija u fokusu.
- **Automatsko lepljenje** — posle prepisa pošalje `Cmd+V` u aplikaciju u kojoj
  si bio. Ako dozvola nije data, tekst čeka u klipbordu.
- **Srpski i engleski** — jezik se prepoznaje automatski; srpski izlaz se
  prevodi ćirilica → latinica.
- **Rečnik** — imena i pojmovi koje model pogrešno piše (Nemanja Čedomirović,
  Tamara Pandža, nazivi projekata…).
- **Istorija** — zadnjih 200 prepisa, pretraga i kopiranje.
- **Štednja memorije** — model se učitava pri diktiranju i oslobađa posle
  5 minuta mirovanja. Na 8 GB Macu ostaje oko 1,4 GB samo dok radi.
- **Opciono doterivanje** — DeepSeek popravi interpunkciju i imena; isključeno
  po defaultu, ključ se čuva u Keychain-u.

## Zahtevi

- macOS 13 (Ventura) ili noviji
- Apple Silicon (arm64)
- ~1,5 GB slobodnog prostora (aplikacija + model)
- 8 GB RAM radi; 16 GB je udobnije

## Instalacija

Potrebni su Command Line Tools (`xcode-select --install`), `cmake`
(`brew install cmake`) i `git` — samo za prvo građenje whisper.cpp-a.

```bash
bash app/instaliraj.sh            # prvi put
bash app/instaliraj.sh --prepisi  # nova verzija (stara ide u .bak)
```

Skripta napravi `Pitchi.app`, potpiše ga lokalnim sertifikatom (ako postoji) i
smesti u `/Applications`.

## Prvo pokretanje

1. Otvori Pitchi (ikona u menu baru, prozor se pojavi sam).
2. Daj tri dozvole, redom iz prozora:
   - **Mikrofon** — da čuje govor.
   - **Nadzor unosa** — da prepozna `Fn` i van Pitchi-ja. Posle ove dozvole
     zatvori i ponovo otvori aplikaciju.
   - **Pristupačnost** — da pošalje `Cmd+V` posle prepisa.
3. Ako model nije tu, klikni **Preuzmi model (1 GB)**.

Prvi prepis posle novog builda ume da bude sporiji (kompajliraju se Metal
šejderi); svaki sledeći je brži.

## Korišćenje

- Drži `Fn` dok govoriš, pusti kada završiš.
- Ili klikni veliko dugme na ekranu „Početak”.
- Ako `Fn` otvara emoji birač: Podešavanja → Tastatura → „Pritisni 🌐 key za”
  → **Ne radi ništa**.

## Ako nešto ne radi

**Fn ne reaguje.** Nema dozvole „Nadzor unosa”. Otvori Podešavanja → Privatnost
→ Nadzor unosa, dodaj Pitchi i restartuj ga.

**Tekst se ne lepi sam.** Nema dozvole „Pristupačnost”. Tekst i dalje završi u
klipbordu — zalepi ga sa `Cmd+V`.

**Prepis je slabiji.** Pričaj bliže mikrofonu, dodaj imena u Rečnik. Prvi model
(`large-v3 q5_0`) je najbolji kompromis za 8 GB; veći modeli traže više RAM-a.

**Mac se guši.** Model se sam oslobađa posle 5 minuta. Možeš i ručno:
Podešavanja → Model → Oslobodi memoriju.

## Privatnost

- Snimak se ne čuva i ne šalje nigde.
- Istorija je lokalni JSON u `~/Library/Application Support/Pitchi/`.
- DeepSeek je opcion i šalje **samo tekst**, nikada zvuk.

## Razvoj

```
app/
  src/            Swift izvori (AppKit + SwiftUI)
  Info.plist      bundle, dozvole, LSUIElement
  build.sh        građenje + potpisivanje
  pripremi-whisper.sh   jednokratno građenje statičkog whisper.cpp-a
  instaliraj.sh   build + /Applications
  vendor/         whisper.cpp biblioteke (ne ide u git)
```

Whisper je **statički** ugrađen (Metal + BLAS), pa aplikacija ne zavisi od
Homebrew-a na ciljnom Macu. Model se preuzima sa Hugging Face-a u
`~/Library/Application Support/Pitchi/models/`.

```bash
bash app/build.sh
open app/build/Pitchi.app
```

## Zahvalnost

- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) (MIT) — ggml/whisper
- OpenAI Whisper model `large-v3` (MIT), kvantizovan na q5_0
- Ikona: napravljena za Pitchi
