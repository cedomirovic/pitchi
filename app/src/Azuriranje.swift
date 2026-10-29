// Provera novih izdanja na GitHub-u i obaveštenje korisniku.
// Mreža se koristi samo za čitanje javnog spiska izdanja — ne šalje se
// nikakav tekst, snimak ni podatak o računaru.
import AppKit
import Foundation
import UserNotifications

// MARK: - Izdanje sa GitHub-a

struct Izdanje: Decodable, Equatable {
    struct Fajl: Decodable, Equatable {
        let name: String
        let browser_download_url: URL
    }

    let tag_name: String
    let name: String?
    /// Opis izdanja sa GitHub-a (markdown) — „šta je novo“.
    let body: String?
    let html_url: URL
    let assets: [Fajl]

    /// Kratke stavke iz opisa izdanja, spremne za prikaz.
    var novine: [String] {
        Napomene.stavke(body)
    }

    /// Verzija bez početnog „v“ (npr. `v0.4.0` → `0.4.0`).
    var verzija: String {
        var ocisceno = tag_name.trimmingCharacters(in: .whitespacesAndNewlines)
        if ocisceno.lowercased().hasPrefix("v") {
            ocisceno.removeFirst()
        }
        return ocisceno
    }

    /// Prvi zip fajl u izdanju je paket aplikacije za macOS.
    var fajlPreuzimanja: Fajl? {
        assets.first { $0.name.lowercased().hasSuffix(".zip") } ?? assets.first
    }

    /// Za bezbednost otvaramo samo HTTPS adrese sa GitHub-a. Ako API vrati
    /// nešto drugo, koristimo zvaničnu stranicu izdanja.
    var bezbednaAdresaPreuzimanja: URL {
        if let fajl = fajlPreuzimanja,
           Azuriranja.jeBezbednaAdresa(fajl.browser_download_url) {
            return fajl.browser_download_url
        }
        return bezbednaStranicaIzdanja
    }

    var bezbednaStranicaIzdanja: URL {
        Azuriranja.jeBezbednaAdresa(html_url) ? html_url : Azuriranja.stranicaIzdanja
    }
}

// MARK: - Napomene izdanja

/// Pretvara GitHub markdown iz opisa izdanja u kratke, čitljive stavke.
/// Iste stavke idu u sistemsko obaveštenje, traku u prozoru i Podešavanja.
enum Napomene {
    static func stavke(_ tekst: String?, najvise: Int = 6) -> [String] {
        guard let tekst, !tekst.isEmpty else { return [] }

        var obicne: [String] = []
        var nabrojane: [String] = []
        var uKodu = false

        for sirova in tekst.components(separatedBy: .newlines) {
            let linija = sirova.trimmingCharacters(in: .whitespaces)
            if linija.hasPrefix("```") {
                uKodu.toggle()
                continue
            }
            if uKodu || linija.isEmpty { continue }
            // Naslovi, tabele, slike i horizontalne linije nisu stavke.
            if linija.hasPrefix("#") || linija.hasPrefix("|")
                || linija.hasPrefix("---") || linija.hasPrefix("![") { continue }

            var ociscena = linija
            var jeStavka = false
            for oznaka in ["- ", "* ", "+ "] where ociscena.hasPrefix(oznaka) {
                ociscena.removeFirst(oznaka.count)
                jeStavka = true
            }
            ociscena = bezMarkdowna(ociscena)
            guard !ociscena.isEmpty else { continue }
            ociscena = velikoPrvoSlovo(ociscena)

            // Ako izdanje ima spisak, on je najkorisniji za „šta je novo“;
            // uvodne rečenice i podnaslove tada preskačemo.
            if jeStavka {
                nabrojane.append(ociscena)
            } else {
                obicne.append(ociscena)
            }
        }

        let izvor = nabrojane.isEmpty ? obicne : nabrojane
        return Array(izvor.prefix(najvise))
    }

    /// Skida markdown oznake: linkove, podebljanja, kod i HTML.
    static func bezMarkdowna(_ tekst: String) -> String {
        var t = tekst
        t = t.replacingOccurrences(
            of: "\\[([^\\]]+)\\]\\([^)]*\\)",
            with: "$1",
            options: .regularExpression
        )
        t = t.replacingOccurrences(of: "[`*_]", with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Stavka spiska je rečenica, pa počinje velikim slovom.
    static func velikoPrvoSlovo(_ tekst: String) -> String {
        guard let prvo = tekst.first else { return tekst }
        return prvo.uppercased() + tekst.dropFirst()
    }

    /// Skraćuje stavku za obaveštenje, na celoj reči kada može.
    static func skraceno(_ tekst: String, do granica: Int = 100) -> String {
        guard tekst.count > granica else { return tekst }
        let isecak = String(tekst.prefix(granica))
        if let razmak = isecak.lastIndex(of: " ") {
            return String(isecak[..<razmak]) + "…"
        }
        return isecak + "…"
    }
}

// MARK: - Poređenje verzija

enum Verzija {
    /// Deli verziju na brojeve: `0.10.2` → `[0, 10, 2]`.
    static func delovi(_ tekst: String) -> [Int] {
        var ocisceno = tekst.trimmingCharacters(in: .whitespacesAndNewlines)
        if ocisceno.lowercased().hasPrefix("v") {
            ocisceno.removeFirst()
        }
        return ocisceno.split(separator: ".").map { deo in
            Int(deo.prefix { $0.isNumber }) ?? 0
        }
    }

    /// Brojevno poređenje, pa `0.10.0` ispravno ide posle `0.9.0`.
    static func uporedi(_ prva: String, _ druga: String) -> ComparisonResult {
        let a = delovi(prva)
        let b = delovi(druga)
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x < y { return .orderedAscending }
            if x > y { return .orderedDescending }
        }
        return .orderedSame
    }

    static func jeNovija(_ kandidat: String, od osnova: String) -> Bool {
        uporedi(kandidat, osnova) == .orderedDescending
    }
}

// MARK: - GitHub

enum GreskaAzuriranja: LocalizedError {
    case status(Int)
    case neispravanOdgovor
    case nemaIzdanja

    var errorDescription: String? {
        switch self {
        case .status(403):
            return "GitHub je ograničio broj provera. Pokušaj kasnije."
        case .status(404):
            return "GitHub ne nalazi objavljeno izdanje Diktatora."
        case .status(let kod):
            return "GitHub je vratio HTTP \(kod)."
        case .neispravanOdgovor:
            return "GitHub je vratio neočekivan odgovor."
        case .nemaIzdanja:
            return "Još nema objavljenog izdanja."
        }
    }
}

enum Azuriranja {
    // Javni repozitorijum u kome su objavljena izdanja. Adresa je zadržana
    // jer se tu već nalaze release-i i stare veze.
    static let repozitorij = "cedomirovic/pitchi"

    static var adresaNajnovijeg: URL {
        // Samo za razvoj i testiranje: lokalni mock umesto GitHub-a.
        if let tekst = ProcessInfo.processInfo.environment["DIKTATOR_AZURIRANJE_API"],
           let adresa = URL(string: tekst) {
            return adresa
        }
        return URL(string: "https://api.github.com/repos/\(repozitorij)/releases/latest")!
    }

    static var stranicaIzdanja: URL {
        URL(string: "https://github.com/\(repozitorij)/releases")!
    }

    /// Dozvoljavamo samo HTTPS adrese koje pripadaju GitHub-u. Time se
    /// sprečava da neočekivan odgovor otvori `file://` ili neki drugi
    /// protokol u browseru.
    static func jeBezbednaAdresa(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased() else { return false }
        return host == "github.com"
            || host == "www.github.com"
            || host == "objects.githubusercontent.com"
    }

    static var trenutnaVerzija: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    /// `adresa` postoji da bi se provera mogla testirati na lokalnom serveru.
    static func proveri(
        adresa: URL = adresaNajnovijeg,
        completion: @escaping (Result<Izdanje, Error>) -> Void
    ) {
        var zahtev = URLRequest(url: adresa)
        zahtev.httpMethod = "GET"
        zahtev.timeoutInterval = 15
        zahtev.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        zahtev.setValue("Diktator/\(trenutnaVerzija)", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: zahtev) { podaci, odgovor, greska in
            if let greska {
                completion(.failure(greska))
                return
            }
            guard let http = odgovor as? HTTPURLResponse else {
                completion(.failure(GreskaAzuriranja.neispravanOdgovor))
                return
            }
            guard http.statusCode == 200 else {
                completion(.failure(GreskaAzuriranja.status(http.statusCode)))
                return
            }
            guard let podaci else {
                completion(.failure(GreskaAzuriranja.neispravanOdgovor))
                return
            }
            do {
                let izdanje = try JSONDecoder().decode(Izdanje.self, from: podaci)
                guard !izdanje.verzija.isEmpty else {
                    completion(.failure(GreskaAzuriranja.nemaIzdanja))
                    return
                }
                completion(.success(izdanje))
            } catch {
                completion(.failure(GreskaAzuriranja.neispravanOdgovor))
            }
        }.resume()
    }
}

// MARK: - Pamćenje provera

/// Da se GitHub ne pita pri svakom pokretanju i da se ista verzija ne
/// obaveštava više puta.
enum SkladisteAzuriranja {
    private static let zadnjaProveraKljuc = "diktator.azuriranja.zadnjaProvera"
    private static let zadnjaVerzijaKljuc = "diktator.azuriranja.zadnjaVerzija"
    private static let napomenaKljuc = "diktator.azuriranja.napomena"
    private static let obavestenaVerzijaKljuc = "diktator.azuriranja.obavestenaVerzija"
    private static let preskocenaVerzijaKljuc = "diktator.azuriranja.preskocenaVerzija"

    private static var defaults: UserDefaults { .standard }

    static var zadnjaProvera: Date? {
        get { defaults.object(forKey: zadnjaProveraKljuc) as? Date }
        set { defaults.set(newValue, forKey: zadnjaProveraKljuc) }
    }

    static var zadnjaVerzija: String? {
        get { defaults.string(forKey: zadnjaVerzijaKljuc) }
        set { defaults.set(newValue, forKey: zadnjaVerzijaKljuc) }
    }

    static var obavestenaVerzija: String? {
        get { defaults.string(forKey: obavestenaVerzijaKljuc) }
        set { defaults.set(newValue, forKey: obavestenaVerzijaKljuc) }
    }

    /// Opis zadnjeg viđenog izdanja, da „šta je novo“ ostane i posle pokretanja.
    static var zadnjaNapomena: String? {
        get { defaults.string(forKey: napomenaKljuc) }
        set { defaults.set(newValue, forKey: napomenaKljuc) }
    }

    static var preskocenaVerzija: String? {
        get { defaults.string(forKey: preskocenaVerzijaKljuc) }
        set { defaults.set(newValue, forKey: preskocenaVerzijaKljuc) }
    }

    /// Automatska provera ide najviše jednom dnevno.
    static func trebaProveriti(sada: Date = Date()) -> Bool {
        guard let zadnja = zadnjaProvera else { return true }
        return sada.timeIntervalSince(zadnja) >= 24 * 3600
    }
}

// MARK: - Sistemsko obaveštenje

enum ObavestenjaAzuriranja {
    private static let identifikator = "diktator.azuriranje"

    /// Prvo pita za dozvolu, pa prikaže obaveštenje. Ako je korisnik
    /// isključio obaveštenja, traka u aplikaciji i dalje radi.
    static func prikazi(verzija: String, adresa: URL, novine: [String] = []) {
        let centar = UNUserNotificationCenter.current()
        centar.getNotificationSettings { podesavanja in
            switch podesavanja.authorizationStatus {
            case .notDetermined:
                centar.requestAuthorization(options: [.alert, .sound]) { dozvoljeno, _ in
                    guard dozvoljeno else { return }
                    posalji(centar, verzija: verzija, adresa: adresa, novine: novine)
                }
            case .authorized, .provisional, .ephemeral:
                posalji(centar, verzija: verzija, adresa: adresa, novine: novine)
            default:
                break
            }
        }
    }

    private static func posalji(
        _ centar: UNUserNotificationCenter,
        verzija: String,
        adresa: URL,
        novine: [String]
    ) {
        let sadrzaj = UNMutableNotificationContent()
        sadrzaj.title = "Dostupno je ažuriranje Diktatora \(verzija)"

        // Ako svež opis izdanja nije stigao, koristi zadnji zapamćeni, da
        // obaveštenje ne ostane bez spiska novina.
        let izvor = novine.isEmpty ? Napomene.stavke(SkladisteAzuriranja.zadnjaNapomena) : novine
        let stavke = izvor.prefix(3).map { "• " + Napomene.skraceno($0) }
        if stavke.isEmpty {
            sadrzaj.body = "Klikni da otvoriš preuzimanje."
        } else {
            sadrzaj.body = "Šta je novo:\n" + stavke.joined(separator: "\n")
        }
        sadrzaj.sound = .default
        sadrzaj.userInfo = ["adresa": adresa.absoluteString]

        let zahtev = UNNotificationRequest(
            identifier: "\(identifikator).\(verzija)",
            content: sadrzaj,
            trigger: nil
        )
        centar.add(zahtev)
    }
}

/// Klik na obaveštenje otvara stranicu za preuzimanje; dok je aplikacija
/// u prvom planu, obaveštenje se ipak prikazuje kao traka.
final class DelegateObavestenja: NSObject, UNUserNotificationCenterDelegate {
    static let zajednicki = DelegateObavestenja()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let tekst = response.notification.request.content.userInfo["adresa"] as? String,
           let adresa = URL(string: tekst),
           Azuriranja.jeBezbednaAdresa(adresa) {
            DispatchQueue.main.async {
                NSWorkspace.shared.open(adresa)
            }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
