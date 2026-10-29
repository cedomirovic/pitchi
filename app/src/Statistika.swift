// Statistika diktiranja — pregled kao u Wispr Flow-u: koliko je reči izgovoreno,
// koliko je diktata bilo, koliko je vremena ušteđeno u odnosu na kucanje,
// serija dana zaredom i aktivnost po danima. Sve se računa i čuva lokalno.
import Foundation

/// Jedan diktat koji ulazi u statistiku. Tekst se ne čuva — samo brojevi.
struct StatistickiZapis: Codable, Identifiable, Equatable {
    var id = UUID()
    var datum = Date()
    var reci = 0
    var trajanje: Double = 0
    var jezik = "auto"
    var model = ""
    /// Neuspeo prepis se broji kao pokušaj, ali ne ulazi u reči ni vreme.
    var uspeh = true
}

/// Jedan dan u grafikonu aktivnosti.
struct StatisticniDan: Identifiable, Equatable {
    let datum: Date
    let reci: Int
    let diktati: Int
    let trajanje: Double

    var id: Date { datum }

    /// Prosečna brzina govora tog dana, u rečima u minuti.
    var brzina: Double {
        trajanje <= 0 ? 0 : Double(reci) / trajanje * 60
    }
}

/// Zbir za izabrani period — za kartice i poređenje sa prethodnim periodom.
struct StatistickiPeriod: Equatable {
    var reci = 0
    var diktati = 0
    var trajanje: Double = 0

    var reciPoMinuti: Double {
        trajanje <= 0 ? 0 : Double(reci) / trajanje * 60
    }
}

/// Sve statistike zajedno. Vrednosni tip, pa promena automatski osveži UI.
struct Statistika: Codable, Equatable {
    var zapisi: [StatistickiZapis] = []

    /// Kucanje prosečno ide oko 40 reči u minuti; prema tome merimo uštedu.
    static let brzinaKucanja = 40.0

    /// Koliko zapisa pamtimo; stariji se odbacuju da fajl ne raste unedogled.
    static let najviseZapisa = 5000

    // MARK: - Sabiranje

    private var uspesni: [StatistickiZapis] {
        zapisi.filter { $0.uspeh && $0.reci > 0 }
    }

    var ukupnoDiktata: Int { uspesni.count }

    var ukupnoReci: Int { uspesni.reduce(0) { $0 + $1.reci } }

    /// Ukupno trajanje govora u sekundama.
    var ukupnoTrajanje: Double { uspesni.reduce(0) { $0 + $1.trajanje } }

    var neuspeli: Int { zapisi.filter { !$0.uspeh }.count }

    /// Prosečno trajanje jednog diktata u sekundama.
    var prosecnoTrajanje: Double {
        ukupnoDiktata == 0 ? 0 : ukupnoTrajanje / Double(ukupnoDiktata)
    }

    /// Koliko reči u minuti govorimo (brzina diktiranja).
    var reciPoMinuti: Double {
        ukupnoTrajanje <= 0 ? 0 : Double(ukupnoReci) / ukupnoTrajanje * 60
    }

    /// Vreme koje bi trebalo da se isto toliko reči otkuca.
    var vremeKucanja: Double { Double(ukupnoReci) / Statistika.brzinaKucanja * 60 }

    /// Ušteda: kucanje minus diktiranje. Nikad negativna.
    var ustedjenoVreme: Double { max(0, vremeKucanja - ukupnoTrajanje) }

    // MARK: - Danas i serija

    private var kalendar: Calendar { Calendar.current }

    var danasReci: Int {
        let danas = kalendar.startOfDay(for: Date())
        return uspesni
            .filter { kalendar.isDate($0.datum, inSameDayAs: danas) }
            .reduce(0) { $0 + $1.reci }
    }

    var danasDiktata: Int {
        let danas = kalendar.startOfDay(for: Date())
        return uspesni.filter { kalendar.isDate($0.datum, inSameDayAs: danas) }.count
    }

    /// Koliko dana zaredom je bilo bar jedan diktat (danas ili do juče).
    var serijaDana: Int {
        let dani = Set(uspesni.map { kalendar.startOfDay(for: $0.datum) })
        guard !dani.isEmpty else { return 0 }

        var dan = kalendar.startOfDay(for: Date())
        if !dani.contains(dan) {
            guard let juce = kalendar.date(byAdding: .day, value: -1, to: dan),
                  dani.contains(juce) else { return 0 }
            dan = juce
        }

        var broj = 0
        while dani.contains(dan) {
            broj += 1
            guard let prethodni = kalendar.date(byAdding: .day, value: -1, to: dan) else { break }
            dan = prethodni
        }
        return broj
    }

    /// Poslednjih `dana` dana, od najstarijeg ka današnjem.
    func dnevnaAktivnost(dana: Int = 14) -> [StatisticniDan] {
        let danas = kalendar.startOfDay(for: Date())
        return stride(from: dana - 1, through: 0, by: -1).compactMap { pomeraj -> StatisticniDan? in
            guard let dan = kalendar.date(byAdding: .day, value: -pomeraj, to: danas) else { return nil }
            let zaDan = uspesni.filter { kalendar.isDate($0.datum, inSameDayAs: dan) }
            return StatisticniDan(
                datum: dan,
                reci: zaDan.reduce(0) { $0 + $1.reci },
                diktati: zaDan.count,
                trajanje: zaDan.reduce(0) { $0 + $1.trajanje }
            )
        }
    }

    // MARK: - Periodi i poređenje

    /// Zbir za `dana` dana unazad. `pomak` 0 je tekući period, 1 prethodni.
    func period(dana: Int, pomak: Int = 0) -> StatistickiPeriod {
        let danas = kalendar.startOfDay(for: Date())
        guard let kraj = kalendar.date(byAdding: .day, value: 1 - pomak * dana, to: danas),
              let pocetak = kalendar.date(byAdding: .day, value: -dana, to: kraj) else {
            return StatistickiPeriod()
        }
        let uPeriodu = uspesni.filter { $0.datum >= pocetak && $0.datum < kraj }
        return StatistickiPeriod(
            reci: uPeriodu.reduce(0) { $0 + $1.reci },
            diktati: uPeriodu.count,
            trajanje: uPeriodu.reduce(0) { $0 + $1.trajanje }
        )
    }

    /// Promena u procentima; `nil` kada u prethodnom periodu nije bilo ničega.
    static func promena(sada: Double, pre: Double) -> Double? {
        guard pre > 0, sada > 0 else { return nil }
        return (sada - pre) / pre * 100
    }

    /// Dan sa najviše reči u poslednjih `dana` dana.
    func najaktivnijiDan(dana: Int) -> StatisticniDan? {
        dnevnaAktivnost(dana: dana)
            .filter { $0.reci > 0 }
            .max { $0.reci < $1.reci }
    }

    /// Najduži pojedinačni diktat u poslednjih `dana` dana.
    func najduziDiktat(dana: Int) -> StatistickiZapis? {
        let danas = kalendar.startOfDay(for: Date())
        guard let pocetak = kalendar.date(byAdding: .day, value: -dana, to: danas) else { return nil }
        return uspesni
            .filter { $0.datum >= pocetak && $0.trajanje > 0 }
            .max { $0.trajanje < $1.trajanje }
    }

    // MARK: - Podela po jeziku i modelu

    /// Naziv jezika za prikaz; hrvatski i bosanski izlaz je isti kao srpski.
    static func nazivJezika(_ kod: String) -> String {
        switch kod {
        case "sr", "hr", "bs": return "srpski"
        case "en": return "engleski"
        default: return "automatski"
        }
    }

    var poJeziku: [(naziv: String, reci: Int)] {
        poJeziku(dana: nil)
    }

    /// Podela po jeziku za poslednjih `dana` dana; `nil` znači sve vreme.
    func poJeziku(dana: Int?) -> [(naziv: String, reci: Int)] {
        Statistika.podela(uPeriodu(dana: dana)) { Statistika.nazivJezika($0.jezik) }
    }

    var poModelu: [(naziv: String, reci: Int)] {
        poModelu(dana: nil)
    }

    /// Podela po modelu za poslednjih `dana` dana; `nil` znači sve vreme.
    func poModelu(dana: Int?) -> [(naziv: String, reci: Int)] {
        Statistika.podela(uPeriodu(dana: dana)) { zapis in
            let ocisceno = zapis.model.trimmingCharacters(in: .whitespaces)
            return ocisceno.isEmpty ? "nepoznat model" : ocisceno
        }
    }

    /// Uspešni zapisi u poslednjih `dana` dana (uključujući danas).
    private func uPeriodu(dana: Int?) -> [StatistickiZapis] {
        guard let dana else { return uspesni }
        let danas = kalendar.startOfDay(for: Date())
        guard let pocetak = kalendar.date(byAdding: .day, value: -dana, to: danas) else {
            return uspesni
        }
        return uspesni.filter { $0.datum >= pocetak }
    }

    private static func podela(
        _ zapisi: [StatistickiZapis],
        kljuc: (StatistickiZapis) -> String
    ) -> [(naziv: String, reci: Int)] {
        var zbir: [String: Int] = [:]
        for zapis in zapisi {
            zbir[kljuc(zapis), default: 0] += zapis.reci
        }
        return zbir
            .map { (naziv: $0.key, reci: $0.value) }
            .sorted { $0.reci > $1.reci }
    }

    // MARK: - Upis

    mutating func dodaj(tekst: String, trajanje: Double, jezik: String, model: String) {
        let reci = Statistika.brojReci(tekst)
        var zapis = StatistickiZapis(
            datum: Date(),
            reci: reci,
            trajanje: max(0, trajanje),
            jezik: jezik,
            model: model
        )
        zapis.uspeh = reci > 0
        upisi(zapis)
    }

    mutating func dodajNeuspeh(jezik: String, model: String) {
        upisi(StatistickiZapis(datum: Date(), reci: 0, trajanje: 0, jezik: jezik, model: model, uspeh: false))
    }

    private mutating func upisi(_ zapis: StatistickiZapis) {
        zapisi.append(zapis)
        if zapisi.count > Statistika.najviseZapisa {
            zapisi = Array(zapisi.suffix(Statistika.najviseZapisa))
        }
    }

    mutating func obrisiSve() {
        zapisi.removeAll()
    }

    /// Reči se broje po razmacima; interpunkcija ostaje uz reč.
    static func brojReci(_ tekst: String) -> Int {
        tekst.split(whereSeparator: { $0.isWhitespace }).count
    }

    // MARK: - Prikaz

    static func broj(_ vrednost: Int) -> String {
        let formater = NumberFormatter()
        formater.numberStyle = .decimal
        formater.groupingSeparator = "."
        formater.maximumFractionDigits = 0
        return formater.string(from: NSNumber(value: vrednost)) ?? "\(vrednost)"
    }

    static func vreme(_ sekunde: Double) -> String {
        let ukupno = Int(sekunde.rounded())
        if ukupno < 60 { return "\(ukupno) s" }
        let minuti = ukupno / 60
        if minuti < 60 { return "\(minuti) min" }
        let sati = minuti / 60
        let ostatak = minuti % 60
        return ostatak == 0 ? "\(sati) h" : "\(sati) h \(ostatak) min"
    }

    /// Trajanje kao na satu: 01:32.
    static func vremeKratko(_ sekunde: Double) -> String {
        let ukupno = max(0, Int(sekunde.rounded()))
        return String(format: "%02d:%02d", ukupno / 60, ukupno % 60)
    }

    static let srpskiLokal = Locale(identifier: "sr_Latn_RS")

    private static let kratakDan: DateFormatter = {
        let formater = DateFormatter()
        formater.locale = Statistika.srpskiLokal
        formater.setLocalizedDateFormatFromTemplate("EEE")
        return formater
    }()

    private static let punDan: DateFormatter = {
        let formater = DateFormatter()
        formater.locale = Statistika.srpskiLokal
        formater.setLocalizedDateFormatFromTemplate("EEEE")
        return formater
    }()

    private static let dugacakDatum: DateFormatter = {
        let formater = DateFormatter()
        formater.locale = Statistika.srpskiLokal
        formater.dateStyle = .long
        formater.timeStyle = .short
        return formater
    }()

    /// „Pon“, „Uto“… za osu grafikona.
    static func oznakaDana(_ datum: Date) -> String {
        kratakDan.string(from: datum).capitalized
    }

    /// „Sreda“ za karticu najaktivnijeg dana.
    static func nazivDana(_ datum: Date) -> String {
        punDan.string(from: datum).capitalized
    }

    /// „12. mart 2025. u 14:32“.
    static func dugDatum(_ datum: Date) -> String {
        dugacakDatum.string(from: datum)
    }

    /// Primer podataka za crtanje slika i brzu proveru izgleda.
    static func primer() -> Statistika {
        var statistika = Statistika()
        let kalendar = Calendar.current
        let uzorci: [(Int, Int, Double, String, String)] = [
            (0, 148, 62, "sr", "Large v3 Turbo"),
            (0, 96, 41, "en", "Large v3 Turbo"),
            (1, 212, 88, "sr", "Large v3 Turbo"),
            (2, 34, 15, "sr", "Large v3"),
            (3, 176, 71, "sr", "Large v3 Turbo"),
            (4, 128, 54, "en", "Large v3"),
            (5, 0, 0, "sr", "Large v3"),
            (6, 92, 38, "sr", "Large v3 Turbo"),
            (8, 240, 96, "sr", "Large v3 Turbo"),
            (9, 64, 27, "en", "Large v3 Turbo"),
            (11, 118, 49, "sr", "Small"),
            (12, 152, 63, "sr", "Large v3 Turbo"),
        ]
        for (dana, reci, trajanje, jezik, model) in uzorci where reci > 0 {
            guard let datum = kalendar.date(byAdding: .day, value: -dana, to: Date()) else { continue }
            statistika.zapisi.append(
                StatistickiZapis(
                    datum: datum,
                    reci: reci,
                    trajanje: trajanje,
                    jezik: jezik,
                    model: model,
                    uspeh: true
                )
            )
        }
        return statistika
    }
}

/// Čuvanje statistike u Application Support, sa dozvolama samo za korisnika.
enum StatistikaSkladiste {
    static func ucitaj() -> Statistika {
        guard let podaci = try? Data(contentsOf: Putanje.statistika),
              let statistika = try? JSONDecoder().decode(Statistika.self, from: podaci) else {
            return Statistika()
        }
        Putanje.zastitiFajl(Putanje.statistika)
        return statistika
    }

    static func sacuvaj(_ statistika: Statistika) {
        guard let podaci = try? JSONEncoder().encode(statistika) else { return }
        try? podaci.write(to: Putanje.statistika, options: .atomic)
        Putanje.zastitiFajl(Putanje.statistika)
    }

    static func obrisi() {
        try? FileManager.default.removeItem(at: Putanje.statistika)
    }
}
