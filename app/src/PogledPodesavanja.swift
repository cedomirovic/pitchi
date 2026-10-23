// Podesavanja: jezik, lepljenje, DeepSeek, recnik, model i dozvole.
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
                    Text("Pitchi se pokrene odmah posle prijave, pa je Fn spreman za diktiranje.")
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
                        Text("Odobri Pitchi u System Settings → General → Login Items.")
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
                    Text("Pitchi je vidljiv u Docku i Cmd+Tab-u, pored ikone u menu baru.")
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
                    Text("Šalje samo gotov tekst na DeepSeek. Isključeno znači da ništa ne napušta Mac.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            if app.podesavanja.doterivanje {
                Divider()

                HStack(spacing: 8) {
                    if kljucVidljiv {
                        TextField("DeepSeek API ključ", text: $app.deepSeekKljuc)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("DeepSeek API ključ", text: $app.deepSeekKljuc)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button {
                        kljucVidljiv.toggle()
                    } label: {
                        Image(systemName: kljucVidljiv ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.bordered)
                    .help(kljucVidljiv ? "Sakrij ključ" : "Prikaži ključ")

                    Button("Sačuvaj") { app.sacuvajKljuc() }
                        .buttonStyle(.borderedProminent)
                        .tint(Izgled.akcenat)
                }

                Text("Ključ se čuva u Keychain-u. Ako polje ostane prazno, doterivanje se preskače.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
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

            Text("Model se ne drži stalno u memoriji. Učita se pri diktiranju i oslobodi posle 5 minuta — zato na 8 GB Mac ostaje upotrebljiv.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var izborModela: Binding<String> {
        Binding(
            get: { app.podesavanja.model },
            set: { app.izaberiModel($0) }
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
                opis: "Prečica Fn radi i van Pitchi-ja.",
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

    private var oAplikaciji: some View {
        Kartica(naslov: "O aplikaciji", ikona: "info.circle") {
            HStack {
                Text("Pitchi")
                    .font(.callout.weight(.medium))
                Text("0.1.0")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("whisper.cpp \(whisper_version().map { String(cString: $0) } ?? "")")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
            Text("Snimak i tekst ne napuštaju Mac. Nema naloga, nema telemetrije. Jedini izlaz u mrežu je preuzimanje modela — i DeepSeek, ako ga sam uključiš.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
