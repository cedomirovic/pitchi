// Kratko uputstvo i odgovori na najčešće probleme.
import SwiftUI

struct PogledPomoc: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Kartica(naslov: "Kako se koristi", ikona: "questionmark.circle") {
                    korak(1, "Drži Fn", "Dok god držiš Fn, Pitchi snima. Pusti kada završiš rečenicu.")
                    korak(2, "Sačekaj trenutak", "Prvi prepis učitava model (2–3 s). Sledeći su brži dok je model u memoriji.")
                    korak(3, "Tekst se sam zalepi", "Pitchi pošalje Cmd+V aplikaciji u kojoj si pisao. Ako ne može, tekst čeka u klipbordu.")
                    korak(4, "Bez Fn? Klikni dugme", "Na ekranu „Početak” veliko dugme radi isto — klik za početak, klik za kraj.")
                }

                Kartica(naslov: "Ako nešto ne radi", ikona: "wrench.and.screwdriver") {
                    problem(
                        "Fn ne reaguje",
                        "Dozvoli „Nadzor unosa” u Podešavanjima → Privatnost. Posle promene dozvole zatvori i otvori Pitchi."
                    )
                    Divider()
                    problem(
                        "Fn otvara emoji birač",
                        "U Podešavanjima → Tastatura podesi „Pritisni 🌐 key za” na „Ne radi ništa”. Tada Fn služi samo za diktiranje."
                    )
                    Divider()
                    problem(
                        "Tekst se ne lepi sam",
                        "Dozvoli „Pristupačnost”. Pitchi tada može da pošalje Cmd+V. Bez toga tekst i dalje završi u klipbordu."
                    )
                    Divider()
                    problem(
                        "Prepis je lošiji nego što znaš da bude",
                        "Pričaj bliže mikrofonu i malo razgovetnije. Dodaj imena u Rečnik (Podešavanja) — Whisper ih tada bolje pogađa."
                    )
                    Divider()
                    problem(
                        "Mac se guši",
                        "Model od 1 GB se drži u memoriji samo dok diktiraš. Ako ne diktiraš, u Podešavanjima klikni „Oslobodi memoriju”."
                    )
                }

                Kartica(naslov: "Privatnost", ikona: "hand.raised") {
                    Text("Snimak se obrađuje lokalno, whisper.cpp modelom na ovom Macu. Nigde se ne šalje. Jedina mrežna radnja je preuzimanje modela. Ako uključiš DeepSeek doterivanje, tada se šalje samo gotov tekst — nikada zvuk.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Kartica(naslov: "Tehnički podaci", ikona: "cpu") {
                    red("Motor", "whisper.cpp (statički ugrađen)")
                    red("Model", "large-v3 q5_0, 1 GB")
                    red("Jezik", "srpski, latinica")
                    red("Memorija", "~1,4 GB samo tokom diktiranja")
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

    private func red(_ naziv: String, _ vrednost: String) -> some View {
        HStack {
            Text(naziv).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(vrednost).font(.caption.weight(.medium))
        }
    }
}
