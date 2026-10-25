// Kratko uputstvo i odgovori na najčešće probleme.
import SwiftUI

struct PogledPomoc: View {
    @EnvironmentObject var app: AppStanje

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Kartica(naslov: "Kako se koristi", ikona: "questionmark.circle") {
                    korak(
                        1,
                        app.izabranaPrecica.jePrekidac ? "Pritisni \(app.nazivPrecice)" : "Drži \(app.nazivPrecice)",
                        app.izabranaPrecica.jePrekidac
                            ? "Pritisni \(app.nazivPrecice) da počneš, ponovo da završiš. Diktator snima između ta dva pritiska."
                            : "Dok god držiš \(app.nazivPrecice), Diktator snima. Pusti kada završiš rečenicu."
                    )
                    korak(2, "Sačekaj trenutak", "Prvi prepis učitava model (2–3 s). Sledeći su brži dok je model u memoriji.")
                    korak(3, "Tekst se sam zalepi", "Diktator pošalje Cmd+V aplikaciji u kojoj si pisao. Ako ne može, tekst čeka u klipbordu.")
                    korak(4, "Bez \(app.nazivPrecice)? Klikni dugme", "Na ekranu „Početak” veliko dugme radi isto — klik za početak, klik za kraj.")
                }

                Kartica(naslov: "Ako nešto ne radi", ikona: "wrench.and.screwdriver") {
                    problem(
                        "\(app.nazivPrecice) ne reaguje",
                        "Dozvoli „Nadzor unosa” u Podešavanjima → Privatnost. Posle promene dozvole zatvori i otvori Diktator."
                    )
                    Divider()
                    problem(
                        "Prečica otvara emoji birač",
                        "Ako je izabran Fn ili Fn + Space, u Podešavanjima → Tastatura podesi „Pritisni 🌐 key za” na „Ne radi ništa”. Ili u Diktatoru izaberi drugu prečicu."
                    )
                    Divider()
                    problem(
                        "Tekst se ne lepi sam",
                        "Dozvoli „Pristupačnost”. Diktator tada može da pošalje Cmd+V. Bez toga tekst i dalje završi u klipbordu."
                    )
                    Divider()
                    problem(
                        "Prepis je lošiji nego što znaš da bude",
                        "Pričaj bliže mikrofonu i malo razgovetnije. Dodaj imena u Rečnik (Podešavanja) — Whisper ih tada bolje pogađa."
                    )
                    Divider()
                    problem(
                        "Mac se guši",
                        "Model se učitava pri diktiranju i oslobađa po izabranom vremenu (Podešavanja → Model → Oslobodi memoriju posle). Za manje RAM-a izaberi lakši model ili „Odmah posle prepisa“."
                    )
                }

                Kartica(naslov: "Doterivanje teksta", ikona: "wand.and.stars") {
                    Text("U Podešavanjima → Doterivanje uključi opciju, izaberi servis, unesi ključ i klikni „Test veze“. Ako obavezan ključ nedostaje, prepis ostaje sirov.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                    servis("DeepSeek", "API ključ sa platform.deepseek.com → API keys. Model: deepseek-chat.")
                    Divider()
                    servis("OpenAI / ChatGPT", "API ključ sa platform.openai.com → API keys. ChatGPT Plus pretplata nije dovoljna za API.")
                    Divider()
                    servis("Anthropic Claude", "API ključ sa console.anthropic.com → API keys. Claude Code je druga alatka, nije API.")
                    Divider()
                    servis("Ollama (lokalno)", "Instaliraj Ollama i pokreni `ollama pull llama3.2`. Nema ključa i tekst ostaje na Macu.")
                    Divider()
                    servis("Drugi OpenAI-kompatibilni", "OpenRouter, Groq, LM Studio, vLLM… Unesi adresu koja se završava sa /chat/completions i tačan naziv modela. Adresa mora da koristi https://; http:// je dozvoljen samo za localhost.")
                }

                Kartica(naslov: "Ažuriranja", ikona: "arrow.down.circle") {
                    Text("Diktator jednom dnevno proveri da li na GitHub-u postoji novije izdanje. Kada postoji, prikaže sistemsko obaveštenje i traku u prozoru sa dugmetom „Preuzmi“. Aplikacija se ne menja sama — preuzmeš novi paket i zameniš staru kopiju.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                    Text("Proveru možeš isključiti u Podešavanjima → Ažuriranja, a ručno je pokrenuti dugmetom „Proveri ažuriranja“ ili iz menija u menu baru.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Kartica(naslov: "Privatnost i bezbednost", ikona: "hand.raised") {
                    Text("Snimak se obrađuje lokalno, whisper.cpp modelom na ovom Macu. Nigde se ne šalje. Mreža se koristi za preuzimanje modela i za proveru novih izdanja na GitHub-u. Ako uključiš doterivanje, samo gotov tekst ide izabranom servisu — nikada zvuk. Ollama radi lokalno i tada tekst ne napušta Mac.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("API ključevi su u macOS Keychain-u, dostupni samo dok je Mac otključan i samo na ovom uređaju. Adrese za doterivanje moraju da koriste https://; http:// je dozvoljen samo za localhost. Istorija i rečnik su lokalni fajlovi dostupni samo korisniku.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Kartica(naslov: "Tehnički podaci", ikona: "cpu") {
                    red("Motor", "whisper.cpp (statički ugrađen)")
                    red("Model", "Tiny, Base, Small, Turbo ili Large v3 — po izboru")
                    red("Jezik", "srpski i engleski, automatski; srpski latinica")
                    red("Doterivanje", "DeepSeek, OpenAI, Claude, Ollama ili drugi")
                    red("Memorija", "~0,2–1,4 GB dok je model učitan; vreme oslobađanja biraš u Podešavanjima")
                    red("Režim prepisa", "Najbolji kvalitet (beam 5) ili manje memorije (greedy)")
                    red("Najduži snimak", "5 minuta")
                    red("Sistemski zahtev", "macOS 13+, Apple Silicon")
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func korak(_ broj: Int, _ naslov: String, _ opis: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(broj)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Izgled.akcenat))

            VStack(alignment: .leading, spacing: 2) {
                Text(naslov).font(.callout.weight(.semibold))
                Text(opis)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func problem(_ naslov: String, _ opis: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(naslov).font(.callout.weight(.medium))
            Text(opis)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func servis(_ naziv: String, _ opis: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(naziv).font(.callout.weight(.medium))
            Text(opis)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func red(_ naziv: String, _ vrednost: String) -> some View {
        HStack {
            Text(naziv).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(vrednost).font(.caption.weight(.medium))
        }
    }
}
