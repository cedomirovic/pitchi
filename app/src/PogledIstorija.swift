// Istorija svih prepisa, sa pretragom i brisanjem.
import SwiftUI

struct PogledIstorija: View {
    @EnvironmentObject var app: AppStanje
    @State private var pretraga = ""
    @State private var potvrdiBrisanje = false

    private var filtrirano: [Zapis] {
        let upit = pretraga.trimmingCharacters(in: .whitespaces)
        guard !upit.isEmpty else { return app.istorija }
        return app.istorija.filter { $0.tekst.localizedCaseInsensitiveContains(upit) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZaglavljeStrane(
                    naslov: "Istorija",
                    detalj: "\(app.istorija.count) prepisa, čuvaju se samo na ovom Macu."
                ) {
                    HStack(spacing: 8) {
                        poljePretrage

                        if !app.istorija.isEmpty {
                            Button {
                                potvrdiBrisanje = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.bordered)
                            .help("Obriši celu istoriju")
                        }
                    }
                }

                if app.istorija.isEmpty {
                    prazno
                } else {
                    tabela
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .alert("Obrisati celu istoriju?", isPresented: $potvrdiBrisanje) {
            Button("Obriši", role: .destructive) { app.obrisiIstoriju() }
            Button("Otkaži", role: .cancel) {}
        } message: {
            Text("Ova radnja se ne može poništiti.")
        }
    }

    private var poljePretrage: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            TextField("Pretraži prepise…", text: $pretraga)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .frame(width: 175)
            if !pretraga.isEmpty {
                Button {
                    pretraga = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Izgled.kartica)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Izgled.ivica, lineWidth: 1)
        )
    }

    private var tabela: some View {
        VStack(spacing: 0) {
            zaglavljeTabele

            Rectangle()
                .fill(Izgled.ivica)
                .frame(height: 1)

            if filtrirano.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text("Nema rezultata za „\(pretraga)”")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            } else {
                ForEach(Array(filtrirano.enumerated()), id: \.element.id) { indeks, zapis in
                    red(zapis)

                    if indeks < filtrirano.count - 1 {
                        Rectangle()
                            .fill(Izgled.ivica)
                            .frame(height: 1)
                            .padding(.leading, 52)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .fill(Izgled.kartica)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .stroke(Izgled.ivica, lineWidth: 1)
        )
    }

    private var zaglavljeTabele: some View {
        HStack(spacing: 12) {
            Text("Naslov / Snipet")
                .padding(.leading, 38)
            Spacer(minLength: 8)
            Text("Datum i vreme")
                .frame(width: 128, alignment: .leading)
            Text("Trajanje")
                .frame(width: 64, alignment: .leading)
            Color.clear.frame(width: 22)
        }
        .font(.system(size: 10.5, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    private func red(_ zapis: Zapis) -> some View {
        let delovi = razdeljak(zapis.tekst)

        return HStack(alignment: .center, spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(delovi.naslov)
                    .font(.system(size: 12.5, weight: .semibold))
                    .lineLimit(1)
                Text(delovi.snipet)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)

            VStack(alignment: .leading, spacing: 1) {
                Text(datumPrvi(zapis.datum))
                    .font(.system(size: 11))
                Text(datumDrugi(zapis.datum))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 128, alignment: .leading)

            Text(Statistika.vremeKratko(zapis.trajanje))
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.primary.opacity(0.06)))
                .frame(width: 64, alignment: .leading)

            Menu {
                Button("Kopiraj") { app.kopiraj(zapis.tekst) }
                Button("Zalepi u aktivnu aplikaciju") {
                    app.kopiraj(zapis.tekst)
                    app.zalepiPoslednji()
                }
                Divider()
                Button("Obriši", role: .destructive) { app.obrisi(zapis) }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 22)
            .help("Više radnji")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Kopiraj") { app.kopiraj(zapis.tekst) }
            Button("Obriši", role: .destructive) { app.obrisi(zapis) }
        }
    }

    private var prazno: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Izgled.akcenat.opacity(0.7))
            Text("Još nema prepisa")
                .font(.system(size: 16, weight: .semibold))
            Text(app.izabranaPrecica.jePrekidac
                ? "Pritisni \(app.nazivPrecice), izgovori prvu rečenicu i pritisni ponovo — ovde će se pojaviti."
                : "Drži \(app.nazivPrecice) i izgovori prvu rečenicu — ovde će se pojaviti.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 70)
    }

    // MARK: - Delovi zapisa

    /// Prvi deo teksta je naslov, ostatak je snipet. Naslov seče na reči.
    private func razdeljak(_ tekst: String) -> (naslov: String, snipet: String) {
        let ocisceno = tekst
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard ocisceno.count > 40 else { return (ocisceno, ocisceno) }

        let granica = ocisceno.index(ocisceno.startIndex, offsetBy: 40)
        let rez = ocisceno[..<granica].lastIndex(of: " ") ?? granica
        let naslov = ocisceno[..<rez]
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:!?"))
        let snipet = ocisceno[rez...]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (naslov.isEmpty ? ocisceno : naslov, snipet.isEmpty ? ocisceno : snipet)
    }

    private func datumPrvi(_ datum: Date) -> String {
        let kalendar = Calendar.current
        let vreme = datum.formatted(date: .omitted, time: .shortened)
        if kalendar.isDateInToday(datum) { return "Danas, \(vreme)" }
        if kalendar.isDateInYesterday(datum) { return "Juče, \(vreme)" }
        return PogledIstorija.danMesecGodina.string(from: datum)
    }

    /// Za starije zapise prvi red već nosi datum, pa drugi red pokazuje dan.
    private func datumDrugi(_ datum: Date) -> String {
        let kalendar = Calendar.current
        if kalendar.isDateInToday(datum) || kalendar.isDateInYesterday(datum) {
            return PogledIstorija.danMesecGodina.string(from: datum)
        }
        return Statistika.nazivDana(datum)
    }

    private static let danMesecGodina: DateFormatter = {
        let formater = DateFormatter()
        formater.locale = Statistika.srpskiLokal
        formater.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        return formater
    }()
}
