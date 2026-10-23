// Pocetni ekran: veliko dugme, stanje, dozvole, model i poslednji tekst.
import SwiftUI

struct PogledPregled: View {
    @EnvironmentObject var app: AppStanje

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                glavnaKartica

                if !app.dozvole.sve {
                    dozvoleKartica
                }

                modelKartica

                if !app.poslednjiTekst.isEmpty {
                    poslednjiTekstKartica
                }

                if !app.istorija.isEmpty {
                    skorasnjeKartica
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var glavnaKartica: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 20) {
                dugmeZaSnimanje

                VStack(alignment: .leading, spacing: 6) {
                    Text(app.stanje.naslov)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text(app.stanje.detalj)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if app.stanje.jeSnimanje {
                        HStack(spacing: 8) {
                            NivoTrake(nivo: app.nivo, aktivno: true)
                            Text(sekunde)
                                .font(.system(.caption, design: .monospaced).weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer(minLength: 0)
            }

            Divider()

            HStack(spacing: 10) {
                Image(systemName: "keyboard")
                    .foregroundStyle(.secondary)
                Text("Drži")
                Taster("Fn")
                Text("i govori, pusti kada završiš. Ili klikni dugme iznad.")
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(app.stanje.jeSnimanje ? Color.red.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var dugmeZaSnimanje: some View {
        Button {
            app.prebaciSnimanje()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        app.stanje.jeSnimanje
                            ? Color.red
                            : Izgled.akcenat
                    )
                    .frame(width: 84, height: 84)
                    .shadow(
                        color: (app.stanje.jeSnimanje ? Color.red : Izgled.akcenat).opacity(0.35),
                        radius: app.stanje.jeSnimanje ? 18 : 10,
                        y: 4
                    )

                if app.stanje.jeZauzet {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                } else {
                    Image(systemName: app.stanje.jeSnimanje ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(app.stanje.jeZauzet)
        .help(app.stanje.jeSnimanje ? "Zaustavi snimanje" : "Počni snimanje")
    }

    private var dozvoleKartica: some View {
        Kartica(naslov: "Još malo pa sve radi", ikona: "lock.shield") {
            Text("Pitchi traži tri dozvole. Bez njih ne može da čuje mikrofon, prepozna Fn ili zalepi tekst.")
                .font(.callout)
                .foregroundStyle(.secondary)

            RedDozvole(
                naziv: "Mikrofon",
                opis: "Da snimi tvoj glas. Snimak ostaje na Macu.",
                ikona: "mic",
                dozvoljeno: app.dozvole.mikrofon
            ) { app.zatrazMikrofon() }

            Divider()

            RedDozvole(
                naziv: "Nadzor unosa",
                opis: "Da prepozna kada držiš Fn, i dok je druga aplikacija u fokusu.",
                ikona: "keyboard",
                dozvoljeno: app.dozvole.nadzorUnosa
            ) { app.zatrazNadzorUnosa() }

            Divider()

            RedDozvole(
                naziv: "Pristupačnost",
                opis: "Da automatski zalepi tekst u aplikaciju u kojoj pišeš.",
                ikona: "cursorarrow.click",
                dozvoljeno: app.dozvole.pristupacnost
            ) { app.zatrazPristupacnost() }

            if app.dozvole.nadzorUnosa && !app.precicaRadi {
                Text("Dozvola postoji, ali prečica još nije aktivna. Zatvori i ponovo otvori Pitchi.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var modelKartica: some View {
        Kartica(naslov: "Model za srpski", ikona: "brain") {
            if app.modelSpreman {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Model je spreman").font(.callout.weight(.medium))
                        Text(app.opisModela).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if app.modelUcitan {
                        Button("Oslobodi memoriju") { app.oslobodiMemoriju() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
                Text("Model se učitava samo kada diktiraš i sam se oslobađa posle 5 minuta mirovanja — da ne guši Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if app.preuzimaModel {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preuzimam model (1 GB)…").font(.callout.weight(.medium))
                    ProgressView(value: app.napredakModela)
                        .tint(Izgled.akcenat)
                    HStack {
                        Text("\(Int(app.napredakModela * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Otkaži") { app.otkaziPreuzimanje() }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                    }
                }
            } else {
                Text("Za dobar srpski potreban je whisper `large-v3` model od 1 GB. Skida se jednokratno, direktno sa Hugging Face-a.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button {
                    app.preuzmiModel()
                } label: {
                    Label("Preuzmi model (1 GB)", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(Izgled.akcenat)
            }
        }
    }

    private var poslednjiTekstKartica: some View {
        Kartica(naslov: "Poslednji prepis", ikona: "text.quote") {
            Text(app.poslednjiTekst)
                .font(.body)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button {
                    app.kopiraj(app.poslednjiTekst)
                } label: {
                    Label("Kopiraj", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    app.zalepiPoslednji()
                } label: {
                    Label("Zalepi u aktivnu aplikaciju", systemImage: "arrow.down.to.line")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()
            }
        }
    }

    private var skorasnjeKartica: some View {
        Kartica(naslov: "Skorašnje", ikona: "clock") {
            ForEach(app.istorija.prefix(3)) { zapis in
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(zapis.tekst)
                            .font(.callout)
                            .lineLimit(2)
                        Text(vreme(zapis.datum))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    DugmeKopiraj(tekst: zapis.tekst) { app.kopiraj(zapis.tekst) }
                }
                if zapis.id != app.istorija.prefix(3).last?.id {
                    Divider()
                }
            }

            Button {
                app.izabranTab = 1
            } label: {
                Label("Sva istorija", systemImage: "arrow.right")
                    .font(.caption.weight(.medium))
            }
            .buttonStyle(.borderless)
        }
    }

    private var sekunde: String {
        String(format: "%d:%02d", app.sekunde / 60, app.sekunde % 60)
    }

    private func vreme(_ datum: Date) -> String {
        datum.formatted(date: .abbreviated, time: .shortened)
    }
}

struct Taster: View {
    let tekst: String

    init(_ tekst: String) {
        self.tekst = tekst
    }

    var body: some View {
        Text(tekst)
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.primary.opacity(0.15), lineWidth: 1))
    }
}
