// Pomoć: kratko uputstvo, česta pitanja i osnovni podaci o aplikaciji.
import SwiftUI

struct PogledPomoc: View {
    @EnvironmentObject var app: AppStanje
    @State private var svePitanja = false
    @State private var otvorena = Set<String>()

    private var pitanja: [(pitanje: String, odgovor: String)] {
        [
            (
                "Kako da promenim prečicu za diktiranje?",
                "Podešavanja → Prečica za diktiranje. Fn + Space radi kao prekidač: prvi pritisak počinje snimak, drugi ga završava. Ostale prečice se drže dok govoriš."
            ),
            (
                "Na kojim jezicima Diktator radi?",
                "Na srpskom i engleskom, sa automatskim prepoznavanjem. Srpski se ispisuje latinicom, a hrvatski i bosanski izlaz je isti kao srpski."
            ),
            (
                "Da li moja snimanja ostaju sačuvana?",
                "Ne. Zvuk se obrađuje u memoriji i briše posle prepisa. Tekst se čuva u istoriji na ovom Macu i može da se isključi, a u statistiku ulaze samo brojevi — nikad tekst."
            ),
            (
                "Kako da poboljšam tačnost prepoznavanja?",
                "Pričaj bliže mikrofonu i malo razgovetnije. Dodaj imena, firme i stručne pojmove u Rečnik — whisper ih tada bolje pogađa. U rečnik idu imena i pojmovi, ne obične reči, i staje 600 znakova, pa najvažnije stavi na početak."
            ),
            (
                "Šta ako se tekst ne zalepi sam?",
                "Dozvoli „Pristupačnost“ u Podešavanjima → Dozvole. Diktator tada šalje Cmd+V u aplikaciju u kojoj pišeš. Bez te dozvole tekst i dalje završi u klipbordu, pa ga zalepi ručno."
            ),
            (
                "Šta ako prečica ne reaguje?",
                "Dozvoli „Nadzor unosa“ u Podešavanjima → Dozvole, pa zatvori i ponovo otvori Diktator. Ako Fn otvara emoji birač, u macOS Tastaturi podesi da Fn ne radi ništa ili izaberi drugu prečicu."
            ),
            (
                "Koliko RAM-a troši model?",
                "Zavisi od modela: Tiny i Base su najlakši, Turbo troši oko 500 MB manje od Large v3. Uključi brzi režim i model se pušta čim macOS javi pritisak na RAM, pri spavanju ekrana i u Low Power Mode."
            ),
            (
                "Kako da ažuriram Diktator?",
                "Aplikacija jednom dnevno proveri GitHub i prikaže obaveštenje sa stavkama novog izdanja. Preuzmeš zip i zameniš staru kopiju u Applications. Proveru možeš isključiti u Podešavanjima → Ažuriranja."
            ),
        ]
    }

    private var prikazanaPitanja: [(pitanje: String, odgovor: String)] {
        svePitanja ? pitanja : Array(pitanja.prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                zaglavlje
                koraci
                pitanjaDeo
                baner
                ostalo
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Zaglavlje

    private var zaglavlje: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Spacer()
                Text("Verzija \(app.trenutnaVerzija)")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
            }

            Text("Dobro došli u Diktator!")
                .font(.system(size: 27, weight: .bold))
            Text("Diktator vam omogućava da brzo i prirodno pretvorite govor u tekst, gde god da se nalazite na macOS-u.")
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Prva tri koraka

    private var koraci: some View {
        VStack(alignment: .leading, spacing: 7) {
            NaslovGrupe("Kako da počnete")

            HStack(alignment: .top, spacing: 12) {
                korakKartica(
                    broj: 1,
                    ikona: "keyboard",
                    naslov: app.izabranaPrecica.jePrekidac ? "Pritisnite prečicu" : "Držite prečicu",
                    opis: app.izabranaPrecica.jePrekidac
                        ? "Podrazumevana prečica je \(app.nazivPrecice). Pritisni za početak, ponovo za kraj. Može se promeniti u podešavanjima."
                        : "Podrazumevana prečica je \(app.nazivPrecice). Drži je dok govoriš i pusti kada završiš. Može se promeniti u podešavanjima."
                )

                korakKartica(
                    broj: 2,
                    ikona: "mic",
                    naslov: "Govorite",
                    opis: "Jasno i prirodno govorite. Diktator automatski prepoznaje srpski ili engleski i pretvara govor u tekst."
                )

                korakKartica(
                    broj: 3,
                    ikona: "text.alignleft",
                    naslov: "Tekst se pojavljuje",
                    opis: "Prepoznati tekst se automatski unosi na mesto kursora u aktivnoj aplikaciji. Ako to ne uspe, čeka u klipbordu."
                )
            }
        }
    }

    private func korakKartica(broj: Int, ikona: String, naslov: String, opis: String) -> some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
                Text("\(broj)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Izgled.akcenat)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Izgled.akcenat.opacity(0.10)))

                Spacer()

                Image(systemName: ikona)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.primary.opacity(0.55))
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }

            VStack(spacing: 5) {
                Text(naslov)
                    .font(.system(size: 13.5, weight: .semibold))
                Text(opis)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .fill(Izgled.kartica)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .stroke(Izgled.ivica, lineWidth: 1)
        )
    }

    // MARK: - Česta pitanja

    private var pitanjaDeo: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                NaslovGrupe("Često postavljena pitanja")
                Spacer()
                Button(svePitanja ? "Prikaži manje" : "Prikaži sve") {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        svePitanja.toggle()
                    }
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Izgled.akcenat)
            }

            VStack(spacing: 5) {
                ForEach(prikazanaPitanja, id: \.pitanje) { stavka in
                    pitanjeRed(stavka.pitanje, stavka.odgovor)
                }
            }
        }
    }

    private func pitanjeRed(_ pitanje: String, _ odgovor: String) -> some View {
        let otvoreno = otvorena.contains(pitanje)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if otvoreno {
                        otvorena.remove(pitanje)
                    } else {
                        otvorena.insert(pitanje)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(pitanje)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(otvoreno ? 180 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if otvoreno {
                Text(odgovor)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 11)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: - Baner

    private var baner: some View {
        HStack(spacing: 13) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Izgled.akcenat))

            VStack(alignment: .leading, spacing: 2) {
                Text("I dalje imate pitanja?")
                    .font(.system(size: 12.5, weight: .semibold))
                Text("Uputstvo i prijava problema su na GitHub-u.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            Link(destination: URL(string: "https://github.com/cedomirovic/pitchi")!) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Otvori GitHub")
                        .font(.system(size: 11.5, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Izgled.akcenat)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .fill(Izgled.akcenat.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .stroke(Izgled.akcenat.opacity(0.14), lineWidth: 1)
        )
    }

    // MARK: - Privatnost, doterivanje i tehnički podaci

    private var ostalo: some View {
        VStack(alignment: .leading, spacing: 7) {
            NaslovGrupe("Više o aplikaciji")

            VStack(spacing: 0) {
                grupa(
                    "Privatnost i bezbednost",
                    ikona: "hand.raised",
                    prva: true
                ) {
                    tekst("Snimak se obrađuje lokalno, whisper.cpp modelom na ovom Macu. Nigde se ne šalje. Mreža se koristi za preuzimanje modela i za proveru novih izdanja na GitHub-u.")
                    tekst("Ako uključiš doterivanje, samo gotov tekst ide izabranom servisu — nikada zvuk. Ollama radi lokalno i tada tekst ne napušta Mac.")
                    tekst("API ključevi su u macOS Keychain-u, dostupni samo dok je Mac otključan i samo na ovom uređaju. Adrese za doterivanje moraju da koriste https://; http:// je dozvoljen samo za localhost.")
                }

                grupa("Doterivanje teksta", ikona: "wand.and.stars") {
                    tekst("U Podešavanjima → Doterivanje uključi opciju, izaberi servis, unesi ključ i klikni „Test veze“. Ako obavezan ključ nedostaje, prepis ostaje sirov.")
                    red("DeepSeek", "Ključ sa platform.deepseek.com, model deepseek-chat.")
                    red("OpenAI / ChatGPT", "Ključ sa platform.openai.com. ChatGPT Plus nije dovoljan za API.")
                    red("Anthropic Claude", "Ključ sa console.anthropic.com. Claude Code je druga alatka, nije API.")
                    red("Google Gemini", "Ključ sa aistudio.google.com, model gemini-3.5-flash-lite.")
                    red("Ollama", "Pokreni „ollama pull llama3.2“. Nema ključa i tekst ostaje na Macu.")
                    red("Drugi OpenAI-kompatibilni", "Adresa koja se završava sa /chat/completions i tačan naziv modela.")
                }

                grupa("Tehnički podaci", ikona: "cpu") {
                    red("Motor", "whisper.cpp (statički ugrađen)")
                    red("Model", "Tiny, Base, Small, Turbo ili Large v3 — po izboru")
                    red("Jezik", "srpski i engleski, automatski; srpski latinica")
                    red("Memorija", "~0,2–1,9 GB dok je model učitan; vreme oslobađanja biraš u Podešavanjima")
                    red("Najduži snimak", "5 minuta")
                    red("Sistemski zahtev", "macOS 13+, Apple Silicon")
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                    .fill(Izgled.kartica)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                    .stroke(Izgled.ivica, lineWidth: 1)
            )
        }
    }

    private func grupa<Sadrzaj: View>(
        _ naslov: String,
        ikona: String,
        prva: Bool = false,
        @ViewBuilder sadrzaj: () -> Sadrzaj
    ) -> some View {
        let otvorenaGrupa = otvorena.contains(naslov)

        return VStack(spacing: 0) {
            if !prva {
                Rectangle()
                    .fill(Izgled.ivica)
                    .frame(height: 1)
                    .padding(.leading, 46)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if otvorenaGrupa {
                        otvorena.remove(naslov)
                    } else {
                        otvorena.insert(naslov)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: ikona)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                    Text(naslov)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(otvorenaGrupa ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if otvorenaGrupa {
                VStack(alignment: .leading, spacing: 8) {
                    sadrzaj()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.leading, 34)
                .padding(.bottom, 12)
            }
        }
    }

    private func tekst(_ vrednost: String) -> some View {
        Text(vrednost)
            .font(.system(size: 11.5))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func red(_ naziv: String, _ vrednost: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(naziv)
                .font(.system(size: 11.5, weight: .medium))
                .frame(width: 150, alignment: .leading)
            Text(vrednost)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
