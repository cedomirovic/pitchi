// Podešavanja: unos, ponašanje, model, doterivanje, rečnik, dozvole i ažuriranja.
import Foundation
import SwiftUI

struct PogledPodesavanja: View {
    @EnvironmentObject var app: AppStanje
    @State private var kljucVidljiv = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ZaglavljeStrane(
                    naslov: "Podešavanja",
                    detalj: "Prilagodi Diktator svojim potrebama."
                )

                diktiranje
                sistem
                modelKartica
                doterivanje
                recnikKartica
                dozvoleKartica
                azuriranjaKartica
                oAplikaciji
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .onChange(of: app.podesavanja) { _ in
            app.sacuvajPodesavanja()
        }
        .onDisappear {
            app.sacuvajRecnik()
        }
    }

    // MARK: - Unos i prepoznavanje govora

    private var diktiranje: some View {
        SekcijaPodesavanja(naslov: "Unos i prepoznavanje govora") {
            RedPodesavanja(
                ikona: "globe",
                naslov: "Jezik prepoznavanja",
                opis: "Automatski prepoznaje srpski i engleski; srpski ispisuje latinicom.",
                prvi: true
            ) {
                Picker("", selection: $app.podesavanja.jezik) {
                    Text("Srpski").tag("sr")
                    Text("Engleski").tag("en")
                    Text("Automatski").tag("auto")
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 180)
            }

            RedPodesavanja(
                ikona: "keyboard",
                naslov: "Prečica za diktiranje",
                opis: app.izabranaPrecica.uputstvo
            ) {
                Picker("", selection: $app.podesavanja.precica) {
                    ForEach(Precica.allCases) { precica in
                        Text(precica.etiketa).tag(precica.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 190)
            }

            if app.izabranaPrecica == .fn || app.izabranaPrecica == .fnSpace {
                napomena("Ako Fn otvara emoji birač, u macOS Tastaturi podesi da Fn ne radi ništa ili izaberi drugu prečicu.")
            }
        }
    }

    // MARK: - Ponašanje aplikacije

    private var sistem: some View {
        SekcijaPodesavanja(naslov: "Ponašanje aplikacije") {
            RedPodesavanja(
                ikona: "doc.on.clipboard",
                naslov: "Automatsko lepljenje",
                opis: "Posle prepisa pošalje Cmd+V u aplikaciju u kojoj si bio.",
                prvi: true
            ) {
                Prekidac(ukljuceno: $app.podesavanja.automatskoLepljenje)
            }

            RedPodesavanja(
                ikona: "speaker.wave.2",
                naslov: "Zvučni signal",
                opis: "Kratak zvuk kada snimanje počne i završi se."
            ) {
                Prekidac(ukljuceno: $app.podesavanja.zvuk)
            }

            RedPodesavanja(
                ikona: "clock.arrow.circlepath",
                naslov: "Čuvaj istoriju",
                opis: "Zadnjih 200 prepisa, samo na ovom Macu."
            ) {
                Prekidac(ukljuceno: $app.podesavanja.cuvajIstoriju)
            }

            RedPodesavanja(
                ikona: "power",
                naslov: "Pokreni pri prijavi računara",
                opis: "Diktator se pokrene odmah posle prijave, pa je \(app.nazivPrecice) spreman za diktiranje."
            ) {
                Prekidac(ukljuceno: Binding(
                    get: { app.prijavaUkljucena || app.prijavaZahtevaOdobrenje },
                    set: { app.postaviPrijavu($0) }
                ))
            }

            if app.prijavaZahtevaOdobrenje {
                Divider().padding(.leading, 52)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Izgled.narandzasta)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("macOS traži odobrenje")
                            .font(.system(size: 12, weight: .medium))
                        Text("Odobri Diktator u System Settings → General → Login Items.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Button("Otvori Login Items") { app.otvoriPrijavuPodesavanja() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                    Spacer()
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
            }

            RedPodesavanja(
                ikona: "dock.rectangle",
                naslov: "Ikona u Docku",
                opis: "Diktator je vidljiv u Docku i Cmd+Tab-u, pored ikone u menu baru."
            ) {
                Text("Uključeno")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Model i memorija

    private var modelKartica: some View {
        SekcijaPodesavanja(naslov: "Model i memorija") {
            RedPodesavanja(
                ikona: "cpu",
                naslov: "Model",
                opis: "Lakši modeli se brže učitavaju i troše manje RAM-a; veći su tačniji.",
                prvi: true
            ) {
                Picker("", selection: izborModela) {
                    ForEach(Modeli.svi) { model in
                        Text("\(model.naziv) · \(model.velicinaTekst)\(model.preporucen ? " — preporučeno" : "")")
                            .tag(model.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 330)
                .disabled(app.preuzimaModel || app.stanje.jeZauzet || app.stanje.jeSnimanje)
            }

            napomena(app.izabraniModel.opis)

            RedPodesavanja(
                ikona: "bolt.fill",
                naslov: "Brzi režim",
                opis: "Turbo model, 30 min u RAM-u i učitavanje odmah po pokretanju."
            ) {
                if app.brziRezimAktivan {
                    HStack(spacing: 8) {
                        Label("Uključen", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Izgled.zelena)
                        Button("Isključi") { app.iskljuciBrziRezim() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                } else {
                    Button(oznakaBrzogRezima) { app.ukljuciBrziRezim() }
                        .buttonStyle(.borderedProminent)
                        .tint(Izgled.akcenat)
                        .controlSize(.small)
                        .disabled(app.preuzimaModel || app.stanje.jeZauzet || app.stanje.jeSnimanje)
                }
            }

            RedPodesavanja(
                ikona: "arrow.down.to.line",
                naslov: "Učitaj model odmah po pokretanju",
                opis: "Prvi diktat kreće bez čekanja; model zauzima RAM dok je aplikacija otvorena."
            ) {
                Prekidac(ukljuceno: Binding(
                    get: { app.podesavanja.unapredUcitajModel },
                    set: { app.postaviUnapredUcitavanje($0) }
                ))
                .disabled(
                    app.preuzimaModel
                        || app.stanje.jeZauzet
                        || !app.modelSpreman
                        || app.oslobadjanjeModela == .odmah
                )
            }

            RedPodesavanja(
                ikona: "memorychip",
                naslov: "Oslobodi memoriju posle",
                opis: "Model se učitava pri diktiranju ili unapred, a oslobađa posle izabranog mirovanja."
            ) {
                Picker("", selection: izborOslobadjanja) {
                    ForEach(OslobadjanjeModela.allCases) { opcija in
                        Text(opcija.naziv).tag(opcija.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 190)
            }

            RedPodesavanja(
                ikona: "slider.horizontal.3",
                naslov: "Režim prepisa",
                opis: "Štedljivi režim troši manje RAM-a, ali na teškom snimku može biti nešto manje tačan."
            ) {
                Picker("", selection: izborRezima) {
                    ForEach(RezimPrepisa.allCases) { rezim in
                        Text(rezim.naziv).tag(rezim.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 190)
                .disabled(app.stanje.jeZauzet)
            }

            napomena(app.rezimPrepisa.opis)

            Divider().padding(.leading, 52)

            HStack(spacing: 10) {
                if app.izabraniModel.preuzet {
                    Label("Model je preuzet", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Izgled.zelena)
                } else {
                    Label("Model nije preuzet", systemImage: "arrow.down.circle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !app.izabraniModel.preuzet && !app.preuzimaModel {
                    Button("Preuzmi \(app.izabraniModel.velicinaTekst)") { app.preuzmiModel() }
                        .buttonStyle(.borderedProminent)
                        .tint(Izgled.akcenat)
                        .controlSize(.small)
                }

                if app.modelUcitan {
                    Button("Oslobodi memoriju") { app.oslobodiMemoriju() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)

            if app.preuzimaModel {
                VStack(spacing: 6) {
                    ProgressView(value: app.napredakModela)
                        .tint(Izgled.akcenat)
                    HStack {
                        Text("Preuzimam \(Modeli.nadji(app.modelPreuzimanja ?? "")?.naziv ?? "model")…")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(app.napredakModela * 100))%")
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundStyle(.secondary)
                        Button("Otkaži") { app.otkaziPreuzimanje() }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
            }

            if let putanja = app.modelPutanja {
                Text(putanja.path)
                    .font(.system(size: 10).monospaced())
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .padding(.horizontal, 15)
                    .padding(.bottom, 10)
            }
        }
    }

    private var oznakaBrzogRezima: String {
        let turbo = Modeli.brzi
        if turbo.preuzet {
            return "Uključi brzi režim"
        }
        return "Preuzmi Turbo i uključi (\(turbo.velicinaTekst))"
    }

    private var izborModela: Binding<String> {
        Binding(
            get: { app.podesavanja.model },
            set: { app.izaberiModel($0) }
        )
    }

    private var izborOslobadjanja: Binding<String> {
        Binding(
            get: { app.podesavanja.oslobadjanjeModela },
            set: { app.postaviOslobadjanjeModela($0) }
        )
    }

    private var izborRezima: Binding<String> {
        Binding(
            get: { app.podesavanja.rezimPrepisa },
            set: { app.postaviRezimPrepisa($0) }
        )
    }

    // MARK: - Doterivanje teksta

    private var doterivanje: some View {
        SekcijaPodesavanja(naslov: "Doterivanje teksta") {
            RedPodesavanja(
                ikona: "wand.and.stars",
                naslov: "Popravi interpunkciju i imena",
                opis: "Šalje samo gotov tekst izabranom servisu. Isključeno znači da ništa ne napušta Mac.",
                prvi: true
            ) {
                Prekidac(ukljuceno: $app.podesavanja.doterivanje)
            }

            if app.podesavanja.doterivanje {
                RedPodesavanja(
                    ikona: "server.rack",
                    naslov: "Servis",
                    opis: provajder.opis
                ) {
                    Picker("", selection: izborProvajdera) {
                        ForEach(ProvajderiDoterivanja.svi) { provajder in
                            Text(provajder.naziv).tag(provajder.id)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 220)
                }

                if provajder.prikazujeKljuc {
                    RedPodesavanja(
                        ikona: "key",
                        naslov: "API ključ",
                        opis: provajder.traziKljuc
                            ? "Čuva se u Keychain-u. Ako polje ostane prazno, doterivanje se preskače."
                            : "Nije obavezan; čuva se u Keychain-u ako ga uneseš."
                    ) {
                        HStack(spacing: 6) {
                            Group {
                                if kljucVidljiv {
                                    TextField(kljucPlaceholder, text: $app.kljucDoterivanja)
                                } else {
                                    SecureField(kljucPlaceholder, text: $app.kljucDoterivanja)
                                }
                            }
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)

                            Button {
                                kljucVidljiv.toggle()
                            } label: {
                                Image(systemName: kljucVidljiv ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.bordered)
                            .help(kljucVidljiv ? "Sakrij ključ" : "Prikaži ključ")
                            .accessibilityLabel(kljucVidljiv ? "Sakrij ključ" : "Prikaži ključ")

                            Button("Sačuvaj") { app.sacuvajKljuc() }
                                .buttonStyle(.bordered)
                                .accessibilityLabel("Sačuvaj ključ")
                        }
                    }
                }

                RedPodesavanja(
                    ikona: "chip",
                    naslov: "Model",
                    opis: "Podrazumevani model je dovoljan; menjaš ga samo ako servis promeni naziv."
                ) {
                    TextField(provajder.model, text: modelDoterivanja)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }

                if provajder.prikazujeAdresu {
                    RedPodesavanja(
                        ikona: "link",
                        naslov: "Adresa",
                        opis: "Mora da koristi https://; http:// je dozvoljen samo za localhost."
                    ) {
                        TextField(provajder.adresa, text: adresaDoterivanja)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                    }
                }

                if let link = provajder.link {
                    HStack(spacing: 6) {
                        Text(provajder.uputstvo)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Link(provajder.linkNaslov ?? "Otvori", destination: link)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 9)
                }

                Divider().padding(.leading, 52)

                HStack {
                    Button {
                        app.testirajDoterivanje()
                    } label: {
                        if app.testiraDoterivanje {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text("Testiram…")
                            }
                        } else {
                            Label("Test veze", systemImage: "bolt.horizontal")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(app.testiraDoterivanje || !kljucSpreman)
                    .accessibilityLabel("Test veze")

                    Spacer()

                    Text("Šalje se samo probna rečenica.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
            }
        }
        .onChange(of: app.podesavanja.provajderDoterivanja) { _ in
            kljucVidljiv = false
        }
    }

    private var provajder: ProvajderDoterivanja {
        app.provajderDoterivanja
    }

    private var izborProvajdera: Binding<String> {
        Binding(
            get: { app.podesavanja.provajderDoterivanja },
            set: { app.izaberiProvajdera($0) }
        )
    }

    private var modelDoterivanja: Binding<String> {
        Binding(
            get: { app.modelDoterivanja },
            set: { app.postaviModelDoterivanja($0) }
        )
    }

    private var adresaDoterivanja: Binding<String> {
        Binding(
            get: { app.podesavanja.adresaCustomDoterivanja },
            set: { app.podesavanja.adresaCustomDoterivanja = $0 }
        )
    }

    private var kljucPlaceholder: String {
        provajder.traziKljuc ? "\(provajder.naziv) API ključ" : "API ključ (opciono)"
    }

    private var kljucSpreman: Bool {
        !provajder.traziKljuc ||
            !app.kljucDoterivanja.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Rečnik

    private var recnikKartica: some View {
        SekcijaPodesavanja(naslov: "Rečnik") {
            VStack(alignment: .leading, spacing: 9) {
                Text("Imena, prezimena, firme i stručni pojmovi koje whisper pogrešno piše. Obične reči ne pomažu jer ih model već zna. Jedan pojam po redu, najvažniji prvi.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                TextEditor(text: $app.recnik)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(minHeight: 120, maxHeight: 190)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.035))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Izgled.ivica, lineWidth: 1)
                    )

                if punRecnik {
                    Text("Rečnik je duži nego što staje u prompt — model dobija prvih \(Recnik.granica) znakova. Skrati spisak ili stavi najvažnije pojmove na početak.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Izgled.narandzasta)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Text("\(Recnik.pojmovi(app.recnik).count) pojmova · \(duzinaRecnika) / \(Recnik.granica) znakova")
                        .font(.system(size: 10.5))
                        .foregroundStyle(punRecnik ? Izgled.narandzasta : Color.secondary)
                    Spacer()
                    Button("Sačuvaj rečnik") { app.sacuvajRecnik() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding(15)
        }
    }

    private var duzinaRecnika: Int {
        Recnik.duzinaPrompta(app.recnik)
    }

    private var punRecnik: Bool {
        duzinaRecnika >= Recnik.granica
            || Recnik.kaoPrompt(app.recnik).count < Recnik.pojmovi(app.recnik).joined(separator: ", ").count
    }

    // MARK: - Dozvole

    private var dozvoleKartica: some View {
        SekcijaPodesavanja(naslov: "Dozvole") {
            VStack(alignment: .leading, spacing: 0) {
                RedDozvole(
                    naziv: "Mikrofon",
                    opis: "Snimanje govora.",
                    ikona: "mic",
                    dozvoljeno: app.dozvole.mikrofon
                ) { app.zatrazMikrofon() }

                Divider().padding(.leading, 38)

                RedDozvole(
                    naziv: "Nadzor unosa",
                    opis: "Prečica \(app.nazivPrecice) radi i van Diktatora.",
                    ikona: "keyboard",
                    dozvoljeno: app.dozvole.nadzorUnosa
                ) { app.zatrazNadzorUnosa() }

                Divider().padding(.leading, 38)

                RedDozvole(
                    naziv: "Pristupačnost",
                    opis: "Automatsko Cmd+V posle prepisa.",
                    ikona: "cursorarrow.click",
                    dozvoljeno: app.dozvole.pristupacnost
                ) { app.zatrazPristupacnost() }

                HStack {
                    Button("Proveri ponovo") {
                        app.osveziDozvole()
                        app.pokreniTastaturu()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()

                    if app.dozvole.sve && app.precicaRadi {
                        Label("Sve radi", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Izgled.zelena)
                    }
                }
                .padding(.top, 8)
            }
            .padding(15)
        }
    }

    // MARK: - Ažuriranja

    private var azuriranjaKartica: some View {
        SekcijaPodesavanja(naslov: "Ažuriranja") {
            RedPodesavanja(
                ikona: "arrow.triangle.2.circlepath",
                naslov: "Verzija \(app.trenutnaVerzija)",
                opis: statusAzuriranja,
                prvi: true
            ) {
                Button {
                    app.proveriAzuriranja(rucno: true)
                } label: {
                    if app.proveravaAzuriranja {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("Proveravam…")
                        }
                    } else {
                        Label("Proveri ažuriranja", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(app.proveravaAzuriranja)
            }

            if let izdanje = app.azuriranje {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Dostupna je verzija \(izdanje.verzija)", systemImage: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Izgled.akcenat)

                    if !izdanje.novine.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Šta je novo")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(.secondary)
                            ForEach(Array(izdanje.novine.enumerated()), id: \.offset) { _, stavka in
                                Text("• \(stavka)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.primary.opacity(0.035))
                        )
                    }

                    HStack(spacing: 8) {
                        Button("Preuzmi \(izdanje.verzija)") { app.otvoriAzuriranje() }
                            .buttonStyle(.borderedProminent)
                            .tint(Izgled.akcenat)
                            .controlSize(.small)

                        Button("Stranica izdanja") { app.otvoriStranicuIzdanja() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                        Spacer()

                        Button("Preskoči ovu verziju") { app.preskociAzuriranje() }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(15)
                .background(Izgled.akcenat.opacity(0.05))
            }

            RedPodesavanja(
                ikona: "clock.badge.checkmark",
                naslov: "Proveravaj automatski",
                opis: "Jednom dnevno pita GitHub da li postoji novije izdanje. Ne šalje se nikakav tekst ni podaci o računaru."
            ) {
                Prekidac(ukljuceno: $app.podesavanja.proveravajAzuriranja)
            }
            .onChange(of: app.podesavanja.proveravajAzuriranja) { ukljuceno in
                if ukljuceno { app.proveriAzuriranja(rucno: true) }
            }
        }
    }

    private var statusAzuriranja: String {
        if app.proveravaAzuriranja { return "Proveravam GitHub…" }
        if app.azuriranje != nil { return "Dostupno je novije izdanje." }
        if let datum = app.zadnjaProveraAzuriranja {
            return "Poslednja provera: \(Self.formatDatuma.string(from: datum))."
        }
        return "Još nije provereno."
    }

    private static let formatDatuma: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - O aplikaciji

    private var oAplikaciji: some View {
        SekcijaPodesavanja(naslov: "O aplikaciji") {
            RedPodesavanja(
                ikona: "info.circle",
                naslov: "Diktator \(verzija)",
                opis: "whisper.cpp \(whisper_version().map { String(cString: $0) } ?? "")",
                prvi: true
            ) {
                Link("GitHub", destination: URL(string: "https://github.com/cedomirovic/pitchi")!)
                    .font(.system(size: 11.5, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Snimak i tekst ne napuštaju Mac. Nema naloga, nema telemetrije. Mreža se koristi samo za preuzimanje modela, proveru novih izdanja na GitHub-u — i izabrani servis za doterivanje, ako ga sam uključiš.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Text("Inspirisano aplikacijom")
                    Link("Pichi", destination: URL(string: "https://github.com/ndjerma/pichi-release")!)
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
        }
    }

    private var verzija: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    // MARK: - Pomoćni delovi

    /// Siva napomena unutar grupe, ispod redova.
    private func napomena(_ tekst: String, boja: Color = .secondary) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Izgled.ivica)
                .frame(height: 1)
                .padding(.leading, 52)

            Text(tekst)
                .font(.system(size: 11))
                .foregroundStyle(boja)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
        }
    }
}
