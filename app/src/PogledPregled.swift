// Početni ekran: veliko dugme, stanje, model i poslednji tekst.
import SwiftUI

struct PogledPregled: View {
    @EnvironmentObject var app: AppStanje

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ZaglavljeStrane(
                    naslov: "Pregled",
                    detalj: "Sve je spremno za diktiranje — govori, a tekst se sam upiše."
                ) {
                    StatusnaTacka(stanje: app.stanje)
                }

                glavnaKartica
                brojevi

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
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Glavna kartica

    private var glavnaKartica: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 18) {
                dugmeZaSnimanje

                VStack(alignment: .leading, spacing: 5) {
                    Text(app.stanje.naslov)
                        .font(.system(size: 21, weight: .bold))
                    Text(app.stanje.detalj(precica: app.nazivPrecice, prekidac: app.izabranaPrecica.jePrekidac))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if app.stanje.jeSnimanje {
                        HStack(spacing: 8) {
                            NivoTrake(nivo: app.nivo, aktivno: true)
                            Text(sekunde)
                                .font(.system(size: 11, design: .monospaced).weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(Izgled.ivica)
                .frame(height: 1)

            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                if app.izabranaPrecica.jePrekidac {
                    Text("Pritisni")
                    Taster(app.simbolPrecice)
                    Text("da počneš, ponovo da završiš. Ili klikni dugme iznad.")
                } else {
                    Text("Drži")
                    Taster(app.simbolPrecice)
                    Text("i govori, pusti kada završiš. Ili klikni dugme iznad.")
                }
                Spacer()
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .fill(Izgled.kartica)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .stroke(app.stanje.jeSnimanje ? Izgled.crvena.opacity(0.45) : Izgled.ivica, lineWidth: 1)
        )
    }

    private var dugmeZaSnimanje: some View {
        Button {
            app.prebaciSnimanje()
        } label: {
            ZStack {
                Circle()
                    .fill(app.stanje.jeSnimanje ? Izgled.crvena : Izgled.akcenat)
                    .frame(width: 76, height: 76)
                    .shadow(
                        color: (app.stanje.jeSnimanje ? Izgled.crvena : Izgled.akcenat).opacity(0.30),
                        radius: app.stanje.jeSnimanje ? 16 : 9,
                        y: 4
                    )

                if app.stanje.jeZauzet {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                } else {
                    Image(systemName: app.stanje.jeSnimanje ? "stop.fill" : "mic.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(app.stanje.jeZauzet)
        .help(app.stanje.jeSnimanje ? "Zaustavi snimanje" : "Počni snimanje")
    }

    // MARK: - Dnevni brojevi

    private var brojevi: some View {
        HStack(spacing: 12) {
            BrojKartica(
                naslov: "Danas reči",
                vrednost: Statistika.broj(app.statistika.danasReci),
                ikona: "doc.text",
                opisPromene: "\(app.statistika.danasDiktata) diktata danas"
            )

            BrojKartica(
                naslov: "Dana zaredom",
                vrednost: "\(app.statistika.serijaDana)",
                ikona: "flame",
                opisPromene: app.statistika.serijaDana == 1 ? "jedan dan u nizu" : "dana u nizu"
            )

            BrojKartica(
                naslov: "Ušteđeno vreme",
                vrednost: Statistika.vreme(app.statistika.ustedjenoVreme),
                ikona: "clock.badge.checkmark",
                opisPromene: "prema kucanju od 40 reči/min"
            )
        }
    }

    // MARK: - Dozvole

    private var dozvoleKartica: some View {
        Kartica(naslov: "Još malo pa sve radi", ikona: "lock.shield", detalj: "Tri dozvole i diktiranje radi u svakoj aplikaciji.") {
            RedDozvole(
                naziv: "Mikrofon",
                opis: "Da snimi tvoj glas. Snimak ostaje na Macu.",
                ikona: "mic",
                dozvoljeno: app.dozvole.mikrofon
            ) { app.zatrazMikrofon() }

            Divider()

            RedDozvole(
                naziv: "Nadzor unosa",
                opis: app.izabranaPrecica.jePrekidac
                    ? "Da prepozna kada pritisneš \(app.nazivPrecice), i dok je druga aplikacija u fokusu."
                    : "Da prepozna kada držiš \(app.nazivPrecice), i dok je druga aplikacija u fokusu.",
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
                Text("Dozvola postoji, ali prečica još nije aktivna. Zatvori i ponovo otvori Diktator.")
                    .font(.system(size: 11))
                    .foregroundStyle(Izgled.narandzasta)
            }
        }
    }

    // MARK: - Model

    private var modelKartica: some View {
        Kartica(naslov: "Model za diktiranje", ikona: "cpu") {
            if app.modelSpreman {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Izgled.zelena)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(app.izabraniModel.naziv) je spreman")
                            .font(.system(size: 12.5, weight: .medium))
                        Text(app.opisModela)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if app.modelUcitan {
                        Button("Oslobodi memoriju") { app.oslobodiMemoriju() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                    izborModelaMeni
                }
                Text("Model se učitava samo kada diktiraš. \(app.oslobadjanjeModela.opis)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if app.izabraniModel.id == "ggml-large-v3-q5_0.bin" {
                    Text("Za oko 500 MB manje memorije izaberi Large v3 Turbo — kvalitet je blizu.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if app.preuzimaModel {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preuzimam \(Modeli.nadji(app.modelPreuzimanja ?? "")?.naziv ?? "model")…")
                        .font(.system(size: 12.5, weight: .medium))
                    ProgressView(value: app.napredakModela)
                        .tint(Izgled.akcenat)
                    HStack {
                        Text("\(Int(app.napredakModela * 100))%")
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Otkaži") { app.otkaziPreuzimanje() }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                    }
                }
            } else {
                Text("Izabran je model \(app.izabraniModel.naziv) (\(app.izabraniModel.velicinaTekst)). Preuzima se jednokratno, direktno sa Hugging Face-a.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                HStack {
                    Button {
                        app.preuzmiModel()
                    } label: {
                        Label("Preuzmi \(app.izabraniModel.velicinaTekst)", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Izgled.akcenat)

                    izborModelaMeni
                }
            }
        }
    }

    private var izborModelaMeni: some View {
        Menu {
            ForEach(Modeli.svi) { model in
                Button {
                    app.izaberiModel(model.id)
                } label: {
                    if model.id == app.podesavanja.model {
                        Label("\(model.naziv) · \(model.velicinaTekst)", systemImage: "checkmark")
                    } else {
                        Text("\(model.naziv) · \(model.velicinaTekst)")
                    }
                }
            }
        } label: {
            Label("Promeni model", systemImage: "slider.horizontal.3")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: - Poslednji tekst i skorašnje

    private var poslednjiTekstKartica: some View {
        Kartica(naslov: "Poslednji prepis", ikona: "text.quote") {
            Text(app.poslednjiTekst)
                .font(.system(size: 13))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
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
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zapis.tekst)
                            .font(.system(size: 12))
                            .lineLimit(2)
                        Text(vreme(zapis.datum))
                            .font(.system(size: 10.5))
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
                    .font(.system(size: 11, weight: .medium))
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
            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .fixedSize()
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.primary.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
    }
}
