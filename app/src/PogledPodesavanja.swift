// Podesavanja: jezik, lepljenje, servis za doterivanje, recnik, model i dozvole.
import Foundation
import SwiftUI

struct PogledPodesavanja: View {
    @EnvironmentObject var app: AppStanje
    @State private var kljucVidljiv = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                diktiranje
                sistem
                doterivanje
                recnikKartica
                modelKartica
                dozvoleKartica
                azuriranjaKartica
                oAplikaciji
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onChange(of: app.podesavanja) { _ in
            app.sacuvajPodesavanja()
        }
        .onDisappear {
            app.sacuvajRecnik()
        }
    }

    private var diktiranje: some View {
        Kartica(naslov: "Diktiranje", ikona: "mic") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Jezik").font(.callout.weight(.medium))
                    Text("Automatski prepoznaje srpski i engleski; srpski ispisuje latinicom.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $app.podesavanja.jezik) {
                    Text("Srpski").tag("sr")
                    Text("Engleski").tag("en")
                    Text("Automatski").tag("auto")
                }
                .labelsHidden()
                .frame(width: 150)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Prečica za diktiranje").font(.callout.weight(.medium))
                    Text("Drži izabrani taster dok govoriš, pusti ga da završiš.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $app.podesavanja.precica) {
                    ForEach(Precica.allCases) { precica in
                        Text(precica.etiketa).tag(precica.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 190)
            }

            if app.izabranaPrecica == .fn {
                Text("Ako Fn otvara emoji birač, izaberi drugu prečicu ili u macOS Tastaturi podesi da Fn ne radi ništa.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Toggle(isOn: $app.podesavanja.automatskoLepljenje) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Automatsko lepljenje").font(.callout.weight(.medium))
                    Text("Posle prepisa pošalje Cmd+V u aplikaciju u kojoj si bio.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            Divider()

            Toggle(isOn: $app.podesavanja.zvuk) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Zvučni signal").font(.callout.weight(.medium))
                    Text("Kratak zvuk kada snimanje počne i završi se.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            Divider()

            Toggle(isOn: $app.podesavanja.cuvajIstoriju) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Čuvaj istoriju").font(.callout.weight(.medium))
                    Text("Zadnjih 200 prepisa, samo na ovom Macu.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
    }

    private var sistem: some View {
        Kartica(naslov: "Sistem", ikona: "gearshape.2") {
            Toggle(
                isOn: Binding(
                    get: { app.prijavaUkljucena || app.prijavaZahtevaOdobrenje },
                    set: { app.postaviPrijavu($0) }
                )
            ) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pokreni pri prijavi računara").font(.callout.weight(.medium))
                    Text("Diktator se pokrene odmah posle prijave, pa je \(app.nazivPrecice) spreman za diktiranje.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            if app.prijavaZahtevaOdobrenje {
                Divider()
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("macOS traži odobrenje")
                            .font(.callout.weight(.medium))
                        Text("Odobri Diktator u System Settings → General → Login Items.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Otvori Login Items") { app.otvoriPrijavuPodesavanja() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                    Spacer()
                }
            }

            Divider()

            HStack(spacing: 10) {
                Image(systemName: "dock.rectangle")
                    .foregroundStyle(Izgled.akcenat)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ikona u Docku").font(.callout.weight(.medium))
                    Text("Diktator je vidljiv u Docku i Cmd+Tab-u, pored ikone u menu baru.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    private var doterivanje: some View {
        Kartica(naslov: "Doterivanje teksta (opciono)", ikona: "wand.and.stars") {
            Toggle(isOn: $app.podesavanja.doterivanje) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Popravi interpunkciju i imena").font(.callout.weight(.medium))
                    Text("Šalje samo gotov tekst izabranom servisu. Isključeno znači da ništa ne napušta Mac.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            if app.podesavanja.doterivanje {
                Divider()

                HStack {
                    Text("Servis").font(.callout.weight(.medium))
                    Spacer()
                    Picker("", selection: izborProvajdera) {
                        ForEach(ProvajderiDoterivanja.svi) { provajder in
                            Text(provajder.naziv).tag(provajder.id)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 290)
                }

                Text(provajder.opis)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if provajder.prikazujeKljuc {
                    HStack(spacing: 8) {
                        if kljucVidljiv {
                            TextField(kljucPlaceholder, text: $app.kljucDoterivanja)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField(kljucPlaceholder, text: $app.kljucDoterivanja)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button {
                            kljucVidljiv.toggle()
                        } label: {
                            Image(systemName: kljucVidljiv ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.bordered)
                        .help(kljucVidljiv ? "Sakrij ključ" : "Prikaži ključ")
                        .accessibilityLabel(kljucVidljiv ? "Sakrij ključ" : "Prikaži ključ")

                        Button("Sačuvaj") { app.sacuvajKljuc() }
                            .buttonStyle(.borderedProminent)
                            .tint(Izgled.akcenat)
                            .accessibilityLabel("Sačuvaj ključ")
                    }

                    Text(provajder.traziKljuc
                        ? "Ključ se čuva u Keychain-u. Ako polje ostane prazno, doterivanje se preskače."
                        : "Ključ nije obavezan; čuva se u Keychain-u ako ga uneseš.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(provajder.uputstvo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let link = provajder.link {
                        Link(provajder.linkNaslov ?? "Otvori", destination: link)
                            .font(.caption.weight(.medium))
                    }
                }

                HStack(spacing: 8) {
                    Text("Model").font(.caption.weight(.medium))
                        .frame(width: 58, alignment: .leading)
                    TextField(provajder.model, text: modelDoterivanja)
                        .textFieldStyle(.roundedBorder)
                }

                if provajder.prikazujeAdresu {
                    HStack(spacing: 8) {
                        Text("Adresa").font(.caption.weight(.medium))
                            .frame(width: 58, alignment: .leading)
                        TextField(provajder.adresa, text: adresaDoterivanja)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Text("Podrazumevani model je dovoljan; menjaš ga samo ako servis promeni naziv.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

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
                }
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
            get: { app.adresaDoterivanja },
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

    private var recnikKartica: some View {
        Kartica(naslov: "Rečnik", ikona: "character.book.closed") {
            Text("Imena i pojmovi koje Whisper pogrešno piše. Jedan po redu — model ih koristi kao nagoveštaj.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $app.recnik)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 130)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))

            HStack {
                Text("\(app.recnik.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count) pojmova")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Sačuvaj rečnik") { app.sacuvajRecnik() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }

    private var modelKartica: some View {
        Kartica(naslov: "Model", ikona: "brain") {
            Text("Lakši modeli se brže učitavaju i troše manje RAM-a; veći modeli su tačniji.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Text("Model").font(.callout.weight(.medium))
                Spacer()
                Picker("", selection: izborModela) {
                    ForEach(Modeli.svi) { model in
                        Text("\(model.naziv) · \(model.velicinaTekst)\(model.preporucen ? " — preporučeno" : "")")
                            .tag(model.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 300)
                .disabled(app.preuzimaModel || app.stanje.jeZauzet)
            }

            Text(app.izabraniModel.opis)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Oslobodi memoriju posle").font(.callout.weight(.medium))
                    Text("Model se učitava pri diktiranju, a oslobađa posle izabranog mirovanja.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: izborOslobadjanja) {
                    ForEach(OslobadjanjeModela.allCases) { opcija in
                        Text(opcija.naziv).tag(opcija.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 220)
            }

            Text(app.oslobadjanjeModela.opis)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Režim prepisa").font(.callout.weight(.medium))
                    Text("Štedljivi režim troši manje RAM-a, ali na težem snimku može biti nešto manje tačan.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: izborRezima) {
                    ForEach(RezimPrepisa.allCases) { rezim in
                        Text(rezim.naziv).tag(rezim.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 220)
                .disabled(app.stanje.jeZauzet)
            }

            Text(app.rezimPrepisa.opis)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if app.izabraniModel.preuzet {
                    Label("Preuzet", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                } else {
                    Label("Nije preuzet", systemImage: "arrow.down.circle")
                        .font(.caption.weight(.medium))
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

            if app.preuzimaModel {
                ProgressView(value: app.napredakModela)
                    .tint(Izgled.akcenat)
                HStack {
                    Text("Preuzimam \(Modeli.nadji(app.modelPreuzimanja ?? "")?.naziv ?? "model")…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(app.napredakModela * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Button("Otkaži") { app.otkaziPreuzimanje() }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                }
            }

            if let putanja = app.modelPutanja {
                Text(putanja.path)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
                    .lineLimit(2)
            }

        }
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

    private var dozvoleKartica: some View {
        Kartica(naslov: "Dozvole", ikona: "lock.shield") {
            RedDozvole(
                naziv: "Mikrofon",
                opis: "Snimanje govora.",
                ikona: "mic",
                dozvoljeno: app.dozvole.mikrofon
            ) { app.zatrazMikrofon() }

            Divider()
            RedDozvole(
                naziv: "Nadzor unosa",
                opis: "Prečica \(app.nazivPrecice) radi i van Diktatora.",
                ikona: "keyboard",
                dozvoljeno: app.dozvole.nadzorUnosa
            ) { app.zatrazNadzorUnosa() }

            Divider()
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
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                }
            }
            .padding(.top, 4)
        }
    }

    private var azuriranjaKartica: some View {
        Kartica(naslov: "Ažuriranja", ikona: "arrow.down.circle") {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Verzija \(app.trenutnaVerzija)")
                        .font(.callout.weight(.medium))
                    Text(statusAzuriranja)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

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
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Label("Dostupna je verzija \(izdanje.verzija)", systemImage: "sparkles")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Izgled.akcenat)

                    if let napomena = izdanje.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !napomena.isEmpty,
                       napomena != izdanje.verzija,
                       napomena != "v\(izdanje.verzija)" {
                        Text(napomena)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
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
            }

            Divider()

            Toggle(isOn: $app.podesavanja.proveravajAzuriranja) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Proveravaj automatski").font(.callout.weight(.medium))
                    Text("Jednom dnevno pita GitHub da li postoji novije izdanje. Ne šalje se nikakav tekst ni podaci o računaru.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
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

    private var oAplikaciji: some View {
        Kartica(naslov: "O aplikaciji", ikona: "info.circle") {
            HStack {
                Text("Diktator")
                    .font(.callout.weight(.medium))
                Text(verzija)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("whisper.cpp \(whisper_version().map { String(cString: $0) } ?? "")")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
            Text("Snimak i tekst ne napuštaju Mac. Nema naloga, nema telemetrije. Mreža se koristi samo za preuzimanje modela, proveru novih izdanja na GitHub-u — i izabrani servis za doterivanje, ako ga sam uključiš.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 4) {
                Text("Inspirisano aplikacijom")
                Link("Pichi", destination: URL(string: "https://github.com/ndjerma/pichi-release")!)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var verzija: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}
