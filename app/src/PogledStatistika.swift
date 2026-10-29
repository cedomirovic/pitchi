// Tab „Statistika" — brojevi, dnevna aktivnost, brzina i podele.
// Sve se računa iz lokalnih podataka; nigde se ne šalje.
import SwiftUI

struct PogledStatistika: View {
    @EnvironmentObject var app: AppStanje
    @State private var potvrdiBrisanje = false
    @State private var period = 7

    private var statistika: Statistika { app.statistika }
    private var tekuci: StatistickiPeriod { statistika.period(dana: period) }
    private var prethodni: StatistickiPeriod { statistika.period(dana: period, pomak: 1) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZaglavljeStrane(
                    naslov: "Statistika",
                    detalj: "Pregledaj svoj napredak i način korišćenja aplikacije."
                ) {
                    izborPerioda
                }

                if statistika.ukupnoDiktata == 0 {
                    prazno
                } else {
                    glavneKartice
                    HStack(alignment: .top, spacing: 12) {
                        dnevnaKartica
                        brzinaKartica
                            .frame(width: 300)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        podelaKartica
                        najaktivnijiKartica
                            .frame(width: 158)
                        najduzaKartica
                            .frame(width: 158)
                    }
                    poModeluKartica
                    podnozje
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .alert("Obrisati statistiku?", isPresented: $potvrdiBrisanje) {
            Button("Obriši", role: .destructive) { app.obrisiStatistiku() }
            Button("Otkaži", role: .cancel) {}
        } message: {
            Text("Brojevi o diktiranju se brišu. Istorija i rečnik ostaju.")
        }
    }

    // MARK: - Izbor perioda

    private var izborPerioda: some View {
        Menu {
            ForEach([7, 14, 30], id: \.self) { dana in
                Button {
                    period = dana
                } label: {
                    if period == dana {
                        Label("Poslednjih \(dana) dana", systemImage: "checkmark")
                    } else {
                        Text("Poslednjih \(dana) dana")
                    }
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                Text("Poslednjih \(period) dana")
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 11)
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
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    /// „prethodnu nedelju“ u zavisnosti od izabranog perioda.
    private var opisPoređenja: String {
        switch period {
        case 7: return "u odnosu na prethodnu nedelju"
        case 14: return "u odnosu na prethodne dve nedelje"
        default: return "u odnosu na prethodnih 30 dana"
        }
    }

    // MARK: - Glavne kartice

    private var glavneKartice: some View {
        HStack(spacing: 12) {
            BrojKartica(
                naslov: "Diktirane reči",
                vrednost: Statistika.broj(tekuci.reci),
                ikona: "doc.text",
                promena: Statistika.promena(sada: Double(tekuci.reci), pre: Double(prethodni.reci)),
                opisPromene: opisPoređenja
            )

            BrojKartica(
                naslov: "Ukupno vreme",
                vrednost: Statistika.vreme(tekuci.trajanje),
                ikona: "clock",
                promena: Statistika.promena(sada: tekuci.trajanje, pre: prethodni.trajanje),
                opisPromene: opisPoređenja
            )

            BrojKartica(
                naslov: "Reči u minuti",
                vrednost: tekuci.reciPoMinuti > 0 ? "\(Int(tekuci.reciPoMinuti.rounded()))" : "—",
                ikona: "speedometer",
                promena: Statistika.promena(sada: tekuci.reciPoMinuti, pre: prethodni.reciPoMinuti),
                opisPromene: opisPoređenja
            )
        }
    }

    // MARK: - Dnevna aktivnost

    private var dnevnaKartica: some View {
        let dani = statistika.dnevnaAktivnost(dana: period)

        return Kartica {
            VStack(alignment: .leading, spacing: 1) {
                Text("Dnevno korišćenje")
                    .font(.system(size: 14, weight: .semibold))
                Text("Broj diktiranih reči po danima")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }

            stubovi(dani)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }

    private func stubovi(_ dani: [StatisticniDan]) -> some View {
        let najveci = zaokruzenMaks(dani.map(\.reci).max() ?? 0)
        let visina = 104.0

        return HStack(alignment: .bottom, spacing: dani.count > 14 ? 3 : 8) {
            ForEach(dani) { dan in
                VStack(spacing: 5) {
                    Text(dan.reci > 0 ? Statistika.broj(dan.reci) : "")
                        .font(.system(size: dani.count > 14 ? 8 : 9.5, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            dan.reci == 0
                                ? AnyShapeStyle(Color.primary.opacity(0.07))
                                : AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Izgled.akcenat, Izgled.akcenat.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .frame(height: max(3, visina * CGFloat(dan.reci) / CGFloat(max(1, najveci))))

                    Text(oznaka(dan))
                        .font(.system(size: dani.count > 14 ? 8 : 9.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .help("\(Statistika.broj(dan.reci)) reči · \(dan.diktati) diktata")
            }
        }
        .frame(height: visina + 34, alignment: .bottom)
    }

    private func oznaka(_ dan: StatisticniDan) -> String {
        if period <= 7 { return Statistika.oznakaDana(dan.datum) }
        if period == 14 { return dan.datum.formatted(.dateTime.day()) }
        let danBroj = Calendar.current.component(.day, from: dan.datum)
        return danBroj % 5 == 0 ? "\(danBroj)." : ""
    }

    private func zaokruzenMaks(_ vrednost: Int) -> Int {
        guard vrednost > 0 else { return 100 }
        let korak = pow(10, floor(log10(Double(vrednost)))) / 2
        return max(1, Int((Double(vrednost) / korak).rounded(.up) * korak))
    }

    // MARK: - Brzina diktiranja

    private var brzinaKartica: some View {
        let dani = statistika.dnevnaAktivnost(dana: period)

        return Kartica {
            VStack(alignment: .leading, spacing: 1) {
                Text("Prosečna brzina diktiranja")
                    .font(.system(size: 14, weight: .semibold))
                Text("Reči u minuti")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }

            linijaBrzine(dani)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private func linijaBrzine(_ dani: [StatisticniDan]) -> some View {
        // Dani bez diktata nemaju brzinu, pa se ne crtaju kao nula — linija
        // povezuje samo dane kada je bilo govora.
        let aktivni = dani.indices.filter { dani[$0].trajanje > 0 }
        let vrednosti = aktivni.map { dani[$0].brzina }
        let vrh = max(60.0, (vrednosti.max() ?? 0) * 1.25)

        return GeometryReader { geometrija in
            let sirina = geometrija.size.width
            let visina = geometrija.size.height
            let korak = dani.count > 1 ? sirina / CGFloat(dani.count - 1) : 0
            let tacke = zip(aktivni, vrednosti).map { indeks, vrednost in
                CGPoint(
                    x: korak * CGFloat(indeks),
                    y: visina - visina * CGFloat(min(vrednost, vrh) / vrh)
                )
            }

            ZStack(alignment: .topLeading) {
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { deo in
                    Rectangle()
                        .fill(Izgled.ivica)
                        .frame(height: 1)
                        .offset(y: visina * deo)
                }

                if tacke.count > 1 {
                    Path { putanja in
                        putanja.move(to: CGPoint(x: tacke[0].x, y: visina))
                        for tacka in tacke { putanja.addLine(to: tacka) }
                        putanja.addLine(to: CGPoint(x: tacke[tacke.count - 1].x, y: visina))
                        putanja.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Izgled.akcenat.opacity(0.20), Izgled.akcenat.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { putanja in
                        putanja.move(to: tacke[0])
                        for tacka in tacke.dropFirst() { putanja.addLine(to: tacka) }
                    }
                    .stroke(Izgled.akcenat, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }

                ForEach(Array(tacke.dropLast().enumerated()), id: \.offset) { _, tacka in
                    Circle()
                        .fill(Izgled.kartica)
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(Izgled.akcenat, lineWidth: 2))
                        .position(tacka)
                }

                if let poslednja = tacke.last, let vrednost = vrednosti.last {
                    Text("\(Int(vrednost.rounded()))")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(Izgled.akcenat)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Izgled.kartica)
                                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                        )
                        .position(x: min(max(poslednja.x - 18, 20), sirina - 20),
                                  y: max(poslednja.y - 18, 12))

                    Circle()
                        .fill(Izgled.akcenat)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Izgled.kartica, lineWidth: 2))
                        .position(poslednja)
                }
            }
        }
        .frame(height: 140)
        .overlay(alignment: .bottom) {
            HStack(spacing: 0) {
                ForEach(dani) { dan in
                    Text(oznaka(dan))
                        .font(.system(size: period > 7 ? 8 : 9.5))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .offset(y: 16)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Podela po jeziku

    private var podelaKartica: some View {
        let ukupno = max(1, statistika.poJeziku(dana: period).reduce(0) { $0 + $1.reci })
        let stavke = podelaSaOstalim(statistika.poJeziku(dana: period))

        return Kartica {
            VStack(alignment: .leading, spacing: 1) {
                Text("Po jeziku")
                    .font(.system(size: 14, weight: .semibold))
                Text("Koji jezik najviše koristiš")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .center, spacing: 18) {
                prsten(ukupno: ukupno, stavke: stavke)
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(stavke.enumerated()), id: \.offset) { indeks, stavka in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Izgled.bojaGrafikona(indeks))
                                .frame(width: 7, height: 7)
                            Text(stavka.naziv)
                                .font(.system(size: 11))
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(Int((Double(stavka.reci) / Double(ukupno) * 100).rounded()))%")
                                .font(.system(size: 11, weight: .medium))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private func podelaSaOstalim(
        _ stavke: [(naziv: String, reci: Int)]
    ) -> [(naziv: String, reci: Int)] {
        guard stavke.count > 4 else { return stavke }
        let prve = Array(stavke.prefix(3))
        let ostalo = stavke.dropFirst(3).reduce(0) { $0 + $1.reci }
        return prve + [(naziv: "ostalo", reci: ostalo)]
    }

    private func prsten(ukupno: Int, stavke: [(naziv: String, reci: Int)]) -> some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: 15)

            ForEach(Array(stavke.enumerated()), id: \.offset) { indeks, stavka in
                let udeo = CGFloat(stavka.reci) / CGFloat(max(1, ukupno))
                let pocetak = stavke.prefix(indeks).reduce(0.0) {
                    $0 + CGFloat($1.reci) / CGFloat(max(1, ukupno))
                }

                Circle()
                    .trim(from: pocetak, to: pocetak + udeo)
                    .stroke(
                        Izgled.bojaGrafikona(indeks),
                        style: StrokeStyle(lineWidth: 15, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 0) {
                Text(Statistika.broj(ukupno))
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                Text("reči")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 92, height: 92)
    }

    // MARK: - Najaktivniji dan i najduža sesija

    private var najaktivnijiKartica: some View {
        let dan = statistika.najaktivnijiDan(dana: period)

        return Kartica {
            Image(systemName: "calendar")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Izgled.akcenat)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Izgled.akcenat.opacity(0.10)))

            Text("Najaktivniji dan")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.secondary)

            Text(dan.map { Statistika.nazivDana($0.datum) } ?? "—")
                .font(.system(size: 19, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(dan.map { "\(Statistika.broj($0.reci)) reči" } ?? "nema diktata")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var najduzaKartica: some View {
        let zapis = statistika.najduziDiktat(dana: period)

        return Kartica {
            Image(systemName: "waveform")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Izgled.akcenat)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Izgled.akcenat.opacity(0.10)))

            Text("Najduža sesija")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.secondary)

            Text(zapis.map { Statistika.vreme($0.trajanje) } ?? "—")
                .font(.system(size: 19, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(zapis.map { Statistika.dugDatum($0.datum) } ?? "nema diktata")
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Po modelu

    private var poModeluKartica: some View {
        let stavke = statistika.poModelu(dana: period)
        let ukupno = max(1, stavke.reduce(0) { $0 + $1.reci })

        return Kartica(naslov: "Po modelu", ikona: "cpu") {
            VStack(spacing: 9) {
                ForEach(Array(stavke.prefix(4).enumerated()), id: \.offset) { indeks, stavka in
                    VStack(spacing: 4) {
                        HStack {
                            Text(stavka.naziv)
                                .font(.system(size: 11.5, weight: .medium))
                                .lineLimit(1)
                            Spacer()
                            Text("\(Statistika.broj(stavka.reci)) reči")
                                .font(.system(size: 10.5))
                                .foregroundStyle(.secondary)
                        }
                        GeometryReader { geometrija in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.primary.opacity(0.07))
                                Capsule()
                                    .fill(Izgled.bojaGrafikona(indeks))
                                    .frame(
                                        width: max(4, geometrija.size.width * CGFloat(stavka.reci) / CGFloat(ukupno))
                                    )
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
    }

    // MARK: - Prazno stanje i podnožje

    private var prazno: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Izgled.akcenat.opacity(0.7))
            Text("Još nema statistike")
                .font(.system(size: 16, weight: .semibold))
            Text("Prvi diktat popunjava brojeve: reči, trajanje, ušteđeno vreme i seriju dana.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 70)
    }

    private var podnozje: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text("Statistika se računa iz brojeva o diktatima i čuva u tvom folderu Diktator. Sam tekst se ne upisuje u statistiku.")
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 10)

            Button("Obriši statistiku") {
                potvrdiBrisanje = true
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .padding(.top, 2)
    }
}
