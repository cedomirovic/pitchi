// Glavni prozor: zaglavlje, tabovi i traka sa porukama.
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppStanje

    var body: some View {
        VStack(spacing: 0) {
            zaglavlje

            Picker("", selection: $app.izabranTab) {
                Text("Početak").tag(0)
                Text("Istorija").tag(1)
                Text("Podešavanja").tag(2)
                Text("Pomoć").tag(3)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 12)

            if let greska = app.greska {
                GreskaKartica(poruka: greska) { app.resetujGresku() }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
            }

            ZStack {
                switch app.izabranTab {
                case 0: PogledPregled()
                case 1: PogledIstorija()
                case 2: PogledPodesavanja()
                default: PogledPomoc()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let info = app.info {
                InfoTraka(tekst: info)
            }
        }
        .frame(minWidth: 760, minHeight: 640)
        .background(Izgled.pozadina)
        .onAppear {
            app.osveziDozvole()
            app.osveziModel()
            app.pokreniTastaturu()
        }
    }

    private var zaglavlje: some View {
        HStack(spacing: 12) {
            if let ikona = NSApp.applicationIconImage {
                Image(nsImage: ikona)
                    .resizable()
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Pitchi")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Diktiranje na srpskom — sve ostaje na ovom Macu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !app.dozvole.sve {
                Button {
                    app.izabranTab = 2
                } label: {
                    Label("Dozvole", systemImage: "lock.shield")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            StatusnaTacka(stanje: app.stanje)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}
