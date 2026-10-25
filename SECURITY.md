# Bezbednost

Diktator je lokalna macOS aplikacija za diktiranje. Snimak i tekst ostaju na
računaru; mreža se koristi samo za preuzimanje modela, proveru izdanja na
GitHub-u i — ako korisnik uključi doterivanje — slanje gotovog teksta izabranom
servisu.

## Podržane verzije

Bezbednosne ispravke dobija najnovije objavljeno izdanje. Starije verzije mogu
raditi, ali se ne održavaju.

## Prijava ranjivosti

**Ne otvaraj javni GitHub issue za bezbednosni problem.** Koristi GitHub
Security Advisory:

<https://github.com/cedomirovic/pitchi/security/advisories/new>

U prijavi navedi:

- verziju Diktatora i macOS,
- korake za reprodukciju,
- šta je posledica (npr. curenje ključa, čitanje tuđeg fajla, zaobilaženje
  HTTPS-a),
- po mogućstvu predlog ispravke.

Nikada ne šalji stvarne API ključeve, snimke ni prepise. Ako je potreban
primer, koristi izmišljeni ključ i kratak tekst.

## Šta je u obimu

- macOS aplikacija u `app/` (Swift, whisper.cpp, mreža, Keychain, fajlovi),
- Node CLI u `diktator.js` i `lib/`,
- skripte za građenje i instalaciju (`app/*.sh`),
- način na koji se čuvaju podešavanja, istorija, rečnik i API ključevi.

## Bezbednosni model

- Snimak se drži u memoriji i ne upisuje se na disk.
- Istorija i rečnik su lokalni fajlovi sa dozvolama 0600; folder je 0700.
- API ključevi su u macOS Keychain-u, po servisu, dostupni samo dok je Mac
  otključan i samo na tom uređaju.
- Doterivanje je isključeno po defaultu. Kada je uključeno, šalje se samo
  gotov tekst, nikada zvuk.
- Adrese za doterivanje moraju da koriste HTTPS; HTTP je dozvoljen samo za
  `localhost` (Ollama i lokalni modeli).
- Modeli se preuzimaju preko HTTPS-a, a veličina fajla se proverava.
- Ažuriranja se proveravaju preko HTTPS-a; aplikacija otvara samo HTTPS adrese
  sa GitHub-a.
- Nema telemetrije, naloga ni automatskog slanja podataka.

## Zahvalnost

Ako prijaviš ranjivost, navešću tvoje ime u beleškama izdanja ako to želiš.
Nema novčane nagrade.
