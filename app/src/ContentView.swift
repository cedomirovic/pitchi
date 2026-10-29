// Glavni prozor: leva navigacija i desna strana sa sadržajem.
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppStanje

    private struct Stavka: Identifiable {
        let id: Int
        let naslov: String
        let ikona: String
    }

    private let stavke: [Stavka] = [
        Stavka(id: 0, naslov: "Pregled", ikona: "house"),
        Stavka(id: 1, naslov: "Istorija", ikona: "clock"),
        Stavka(id: 2, naslov: "Statistika", ikona: "chart.bar"),
        Stavka(id: 3, naslov: "Podešavanja", ikona: "gearshape"),
        Stavka(id: 4, naslov: "Pomoć", ikona: "questionmark.circle"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            stranicnaTraka

            VStack(spacing: 0) {
                if let greska = app.greska {
                    GreskaKartica(poruka: greska) { app.resetujGresku() }
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                }

                ZStack {
                    switch app.izabranTab {
                    case 0: PogledPregled()
                    case 1: PogledIstorija()
                    case 2: PogledStatistika()
                    case 3: PogledPodesavanja()
                    default: PogledPomoc()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Traka stoji na dnu da ne pomera naslov strane i ne kvari
                // raspored; detalji su i u Podešavanjima → Ažuriranja.
                if let izdanje = app.azuriranje, !app.sakrijTrakuAzuriranja {
                    AzuriranjeTraka(
                        verzija: izdanje.verzija,
                        trenutna: app.trenutnaVerzija,
                        stavke: izdanje.novine,
                        preuzmi: { app.otvoriAzuriranje() },
                        pogledaj: { app.izabranTab = 3 },
                        kasnije: { app.kasnijeAzuriranje() }
                    )
                }

                if let info = app.info {
                    InfoTraka(tekst: info)
                }
            }
            .background(Izgled.pozadina)
        }
        .frame(minWidth: 900, minHeight: 640)
        .onAppear {
            app.osveziDozvole()
            app.osveziModel()
            app.pokreniTastaturu()
        }
    }

    // MARK: - Leva navigacija

    private var stranicnaTraka: some View {
        VStack(alignment: .leading, spacing: 0) {
            zaglavlje

            VStack(spacing: 2) {
                ForEach(stavke) { stavka in
                    dugmeStrane(stavka)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)

            Spacer(minLength: 16)

            podnozje
        }
        .frame(width: 208)
        .background {
            ZStack {
                Rectangle().fill(.regularMaterial)
                Izgled.akcenat.opacity(0.035)
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Izgled.ivica)
                .frame(width: 1)
        }
    }

    private var zaglavlje: some View {
        HStack(spacing: 10) {
            if let ikona = NSApp.applicationIconImage {
                Image(nsImage: ikona)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Diktator")
                    .font(.system(size: 14, weight: .semibold))
                Text("Glas u tekst.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 22)
        .padding(.bottom, 18)
    }

    private func dugmeStrane(_ stavka: Stavka) -> some View {
        let izabrana = app.izabranTab == stavka.id

        return Button {
            app.izabranTab = stavka.id
        } label: {
            HStack(spacing: 10) {
                Image(systemName: stavka.ikona)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 18)

                Text(stavka.naslov)
                    .font(.system(size: 13, weight: izabrana ? .semibold : .regular))

                Spacer(minLength: 0)
            }
            .foregroundStyle(izabrana ? Color.white : Color.primary.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if izabrana {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Izgled.akcenat)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(stavka.naslov)
        .accessibilityAddTraits(izabrana ? [.isSelected] : [])
    }

    private var podnozje: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !app.dozvole.sve {
                Button {
                    app.izabranTab = 3
                } label: {
                    Label("Nedostaju dozvole", systemImage: "lock.shield")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Izgled.narandzasta)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 5) {
                Image(systemName: "lock")
                    .font(.system(size: 9))
                Text("Sve ostaje na ovom Macu")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.secondary)

            Text("Diktator \(app.trenutnaVerzija)")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
    }
}
