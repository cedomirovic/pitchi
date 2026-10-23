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
    let html_url: URL
    let assets: [Fajl]

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

    /// Ako izdanje nema zip, otvara se stranica izdanja.
    var adresaPreuzimanja: URL {
        fajlPreuzimanja?.browser_download_url ?? html_url
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
            return "GitHub ne nalazi objavljeno izdanje Pitchi-ja."
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
    static let repozitorij = "cedomirovic/pitchi"

    static var adresaNajnovijeg: URL {
        // Samo za razvoj i testiranje: lokalni mock umesto GitHub-a.
        if let tekst = ProcessInfo.processInfo.environment["PITCHI_AZURIRANJE_API"],
           let adresa = URL(string: tekst) {
            return adresa
        }
        return URL(string: "https://api.github.com/repos/\(repozitorij)/releases/latest")!
    }

    static var stranicaIzdanja: URL {
        URL(string: "https://github.com/\(repozitorij)/releases")!
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
        zahtev.setValue("Pitchi/\(trenutnaVerzija)", forHTTPHeaderField: "User-Agent")

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
    private static let zadnjaProveraKljuc = "pitchi.azuriranja.zadnjaProvera"
    private static let zadnjaVerzijaKljuc = "pitchi.azuriranja.zadnjaVerzija"
    private static let obavestenaVerzijaKljuc = "pitchi.azuriranja.obavestenaVerzija"
    private static let preskocenaVerzijaKljuc = "pitchi.azuriranja.preskocenaVerzija"

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
    private static let identifikator = "pitchi.azuriranje"

    /// Prvo pita za dozvolu, pa prikaže obaveštenje. Ako je korisnik
    /// isključio obaveštenja, traka u aplikaciji i dalje radi.
    static func prikazi(verzija: String, adresa: URL) {
        let centar = UNUserNotificationCenter.current()
        centar.getNotificationSettings { podesavanja in
            switch podesavanja.authorizationStatus {
            case .notDetermined:
                centar.requestAuthorization(options: [.alert, .sound]) { dozvoljeno, _ in
                    guard dozvoljeno else { return }
                    posalji(centar, verzija: verzija, adresa: adresa)
                }
            case .authorized, .provisional, .ephemeral:
                posalji(centar, verzija: verzija, adresa: adresa)
            default:
                break
            }
        }
    }

    private static func posalji(_ centar: UNUserNotificationCenter, verzija: String, adresa: URL) {
        let sadrzaj = UNMutableNotificationContent()
        sadrzaj.title = "Dostupno je ažuriranje Pitchi-ja"
        sadrzaj.body = "Verzija \(verzija) je spremna. Klikni da otvoriš preuzimanje."
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
           let adresa = URL(string: tekst) {
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
