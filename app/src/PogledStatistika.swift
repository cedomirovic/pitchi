// Tab „Statistika" — pregled kao u Wispr Flow-u: reči, diktati, vreme,
// ušteda, serija dana i aktivnost po danima. Sve je izračunato iz lokalnih
// podataka; nigde se ne šalje.
import SwiftUI

struct PogledStatistika: View {
    @EnvironmentObject var app: AppStanje
    @State private var potvrdiBrisanje = false

    private var statistika: Statistika { app.statistika }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                zaglavlje

                if statistika.ukupnoDiktata == 0 {
                    prazno
                } else {
                    glavniBrojevi
                    sporedniBrojevi
                    grafikonKartica
                    podelaKartice
                    podnozje
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .alert("Obrisati statistiku?", isPresented: $potvrdiBrisanje) {
            Button("Obriši", role: .destructive) { app.obrisiStatistiku() }
            Button("Otkaži", role: .cancel) {}
        } message: {
            Text("Brojevi o diktiranju se brišu. Istorija i rečnik ostaju.")
        }
    }

    // MARK: - Zaglavlje

    private var zaglavlje: some View {
        HStack(alignment: .firstTextBaseline) {
            NaslovSekcije(
                "Statistika",
                detalj: "Koliko si izdiktirao i koliko si vremena uštedeo — sve na ovom Macu."
            )

            Spacer()

            if statistika.ukupnoDiktata > 0 {
                Button {
                    potvrdiBrisanje = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .help("Obriši statistiku")
            }
        }
    }

    // MARK: - Glavni brojevi

    private var glavniBrojevi: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
            spacing: 12
        ) {
            velikaKartica(
                vrednost: Statistika.broj(statistika.ukupnoReci),
                jedinica: "reči",
                naslov: "Ukupno izdiktirano",
                ikona: "text.alignleft",
                detalj: "\(Statistika.broj(statistika.ukupnoDiktata)) diktata"
            )

            velikaKartica(
                vrednost: Statistika.vreme(statistika.ustedjenoVreme),
                jedinica: "",
                naslov: "Ušteđeno vreme",
                ikona: "clock.badge.checkmark",
                detalj: "u odnosu na kucanje od \(Int(Statistika.brzinaKucanja)) reči u minuti"
            )

            velikaKartica(
                vrednost: Statistika.vreme(statistika.ukupnoTrajanje),
                jedinica: "",
                naslov: "Vreme diktiranja",
                ikona: "mic.fill",
                detalj: "prosečno \(Statistika.vreme(statistika.prosecnoTrajanje)) po diktatu"
            )

            velikaKartica(
                vrednost: "\(Int(statistika.reciPoMinuti.rounded()))",
                jedinica: "reči/min",
                naslov: "Brzina govora",
                ikona: "speedometer",
                detalj: "\(Int(Statistika.brzinaKucanja)) reči/min je prosek kucanja"
            )
        }
    }

    private func velikaKartica(
        vrednost: String,
        jedinica: String,
        naslov: String,
        ikona: String,
        detalj: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: ikona)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Izgled.akcenat)
                Text(naslov)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(vrednost)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                if !jedinica.isEmpty {
                    Text(jedinica)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            Text(detalj)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    // MARK: - Sporedni brojevi

    private var sporedniBrojevi: some View {
        HStack(spacing: 12) {
            malaKartica(
                vrednost: Statistika.broj(statistika.danasReci),
                naslov: "Danas reči",
                ikona: "sun.max"
            )
            malaKartica(
                vrednost: "\(statistika.danasDiktata)",
                naslov: "Danas diktata",
                ikona: "mic"
            )
            malaKartica(
                vrednost: "\(statistika.serijaDana)",
                naslov: statistika.serijaDana == 1 ? "dan zaredom" : "dana zaredom",
                ikona: "flame"
            )
            malaKartica(
                vrednost: "\(statistika.neuspeli)",
                naslov: "neuspelih pokušaja",
                ikona: "exclamationmark.triangle"
            )
        }
    }

    private func malaKartica(vrednost: String, naslov: String, ikona: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: ikona)
                .font(.system(size: 12))
                .foregroundStyle(Izgled.akcenat)
            Text(vrednost)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text(naslov)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Grafikon

    private var grafikonKartica: some View {
        let dani = statistika.dnevnaAktivnost(dana: 14)
        let najveci = max(1, dani.map(\.reci).max() ?? 1)

        return Kartica(naslov: "Poslednjih 14 dana", ikona: "chart.bar.fill") {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(dani) { dan in
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(dan.reci > 0 ? Izgled.akcenat.opacity(0.85) : Color.primary.opacity(0.07))
                            .frame(height: visina(dan.reci, najveci: najveci))

                        Text(dan.datum.formatted(.dateTime.day()))
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(dan.reci > 0 ? Color.secondary : Color.secondary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .help("\(dan.datum.formatted(date: .abbreviated, time: .omitted)): \(Statistika.broj(dan.reci)) reči, \(dan.diktati) diktata")
                }
            }
            .frame(height: 130)
        }
    }

    private func visina(_ reci: Int, najveci: Int) -> CGFloat {
        guard reci > 0 else { return 3 }
        let odnos = CGFloat(reci) / CGFloat(najveci)
        return max(6, odnos * 100)
    }

    // MARK: - Podela

    private var podelaKartice: some View {
        HStack(alignment: .top, spacing: 12) {
            podelaKartica(naslov: "Po jeziku", ikona: "globe", stavke: statistika.poJeziku)
            podelaKartica(naslov: "Po modelu", ikona: "cpu", stavke: statistika.poModelu)
        }
    }

    private func podelaKartica(
        naslov: String,
        ikona: String,
        stavke: [(naziv: String, reci: Int)]
    ) -> some View {
        let ukupno = max(1, stavke.reduce(0) { $0 + $1.reci })

        return Kartica(naslov: naslov, ikona: ikona) {
            VStack(spacing: 10) {
                ForEach(stavke.prefix(4), id: \.naziv) { stavka in
                    VStack(spacing: 4) {
                        HStack {
                            Text(stavka.naziv)
                                .font(.caption.weight(.medium))
                            Spacer()
                            Text("\(Statistika.broj(stavka.reci)) reči")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        GeometryReader { geometrija in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.primary.opacity(0.08))
                                Capsule()
                                    .fill(Izgled.akcenat.opacity(0.75))
                                    .frame(width: max(4, geometrija.size.width * CGFloat(stavka.reci) / CGFloat(ukupno)))
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Prazno stanje i podnožje

    private var prazno: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Izgled.akcenat.opacity(0.7))
            Text("Još nema statistike")
                .font(.title3.weight(.semibold))
            Text("Prvi diktat popunjava brojeve: reči, trajanje, ušteđeno vreme i seriju dana.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var podnozje: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.secondary)
            Text("Statistika se računa iz brojeva o diktatima i čuva u tvom folderu Diktator. Sam tekst se ne upisuje u statistiku.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }
}
