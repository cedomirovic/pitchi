// Opciono doterivanje teksta preko izabranog servisa. Isključeno je po
// defaultu i šalje se samo gotov tekst (bez snimka) — i to samo ako korisnik
// uključi doterivanje.
import Foundation

enum GreskaDoterivanja: LocalizedError {
    case nemaKljuca(String)
    case neispravnaAdresa
    case odgovor(String)
    case prazan(String)

    var errorDescription: String? {
        switch self {
        case .nemaKljuca(let naziv):
            return "\(naziv) API ključ nije unet."
        case .neispravnaAdresa:
            return "Adresa servisa za doterivanje nije ispravna."
        case .odgovor(let poruka):
            return poruka
        case .prazan(let naziv):
            return "\(naziv) je vratio prazan tekst."
        }
    }
}

struct Doterivac {
    static func doteraj(
        _ tekst: String,
        provajder: ProvajderDoterivanja,
        kljuc: String,
        model: String,
        adresa: String,
        jezik: String = "sr"
    ) async throws -> String {
        let ociscenKljuc = kljuc.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !provajder.traziKljuc || !ociscenKljuc.isEmpty else {
            throw GreskaDoterivanja.nemaKljuca(provajder.naziv)
        }

        let izabraniModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !izabraniModel.isEmpty else {
            throw GreskaDoterivanja.odgovor("\(provajder.naziv): model nije unet.")
        }
        guard let url = URL(string: adresa),
              let sema = url.scheme,
              sema == "http" || sema == "https" else {
            throw GreskaDoterivanja.neispravnaAdresa
        }

        let uputstvo = uputstvo(jezik: jezik)
        var zahtev = URLRequest(url: url)
        zahtev.httpMethod = "POST"
        zahtev.timeoutInterval = 60
        zahtev.setValue("application/json", forHTTPHeaderField: "Content-Type")

        switch provajder.vrsta {
        case .openAIKompatibilan:
            if !ociscenKljuc.isEmpty {
                zahtev.setValue("Bearer \(ociscenKljuc)", forHTTPHeaderField: "Authorization")
            }
            let telo: [String: Any] = [
                "model": izabraniModel,
                "temperature": 0,
                "messages": [
                    ["role": "system", "content": uputstvo],
                    ["role": "user", "content": tekst],
                ],
            ]
            zahtev.httpBody = try JSONSerialization.data(withJSONObject: telo)

        case .anthropic:
            zahtev.setValue(ociscenKljuc, forHTTPHeaderField: "x-api-key")
            zahtev.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            let telo: [String: Any] = [
                "model": izabraniModel,
                "max_tokens": 2048,
                "temperature": 0,
                "system": uputstvo,
                "messages": [
                    ["role": "user", "content": tekst],
                ],
            ]
            zahtev.httpBody = try JSONSerialization.data(withJSONObject: telo)

        case .ollama:
            let telo: [String: Any] = [
                "model": izabraniModel,
                "stream": false,
                "messages": [
                    ["role": "system", "content": uputstvo],
                    ["role": "user", "content": tekst],
                ],
                "options": ["temperature": 0],
            ]
            zahtev.httpBody = try JSONSerialization.data(withJSONObject: telo)
        }

        let (podaci, odgovor) = try await URLSession.shared.data(for: zahtev)
        guard let http = odgovor as? HTTPURLResponse else {
            throw GreskaDoterivanja.odgovor("\(provajder.naziv) nije vratio HTTP odgovor.")
        }
        guard http.statusCode == 200 else {
            throw GreskaDoterivanja.odgovor(porukaZaStatus(http.statusCode, naziv: provajder.naziv))
        }

        let ocisceno: String?
        do {
            ocisceno = try ocitaj(podaci, vrsta: provajder.vrsta)
        } catch {
            throw GreskaDoterivanja.odgovor("\(provajder.naziv) je vratio neočekivan odgovor.")
        }

        guard let tekst = ocisceno?.trimmingCharacters(in: .whitespacesAndNewlines),
              !tekst.isEmpty else {
            throw GreskaDoterivanja.prazan(provajder.naziv)
        }
        return tekst
    }

    private static func ocitaj(_ podaci: Data, vrsta: VrstaDoterivaca) throws -> String? {
        switch vrsta {
        case .openAIKompatibilan:
            struct Odgovor: Decodable {
                struct Izbor: Decodable {
                    struct Poruka: Decodable { let content: String }
                    let message: Poruka
                }
                let choices: [Izbor]
            }
            let dekodirano = try JSONDecoder().decode(Odgovor.self, from: podaci)
            return dekodirano.choices.first?.message.content

        case .anthropic:
            struct Odgovor: Decodable {
                struct Blok: Decodable {
                    let type: String
                    let text: String?
                }
                let content: [Blok]
            }
            let dekodirano = try JSONDecoder().decode(Odgovor.self, from: podaci)
            return dekodirano.content
                .filter { $0.type == "text" }
                .compactMap(\.text)
                .joined(separator: " ")

        case .ollama:
            struct Odgovor: Decodable {
                struct Poruka: Decodable { let content: String }
                let message: Poruka
            }
            let dekodirano = try JSONDecoder().decode(Odgovor.self, from: podaci)
            return dekodirano.message.content
        }
    }

    private static func porukaZaStatus(_ kod: Int, naziv: String) -> String {
        switch kod {
        case 401, 403:
            return "\(naziv) je odbio ključ (HTTP \(kod))."
        case 404:
            return "\(naziv) ne nalazi adresu ili model (HTTP 404)."
        case 429:
            return "\(naziv) traži pauzu — previše zahteva (HTTP 429)."
        default:
            return "\(naziv) je vratio HTTP \(kod)."
        }
    }

    private static func uputstvo(jezik: String) -> String {
        if jezik == "en" {
            return """
            You are an English proofreader. Fix only punctuation, capitalization, \
            and obvious speech-recognition errors. Do not change the meaning, add \
            sentences, or translate. Return only the corrected text, without \
            explanations or quotation marks. Preserve these names and terms: \
            Nemanja Čedomirović, Tamara Pandža, Diktator, Beograd.
            """
        }
        return """
        Ti si lektor za srpski jezik. Ispravi samo interpunkciju, velika slova i \
        očigledne greške u prepoznavanju govora. Ne menjaj smisao, ne dodaj nove \
        rečenice i ne prevodi. Vrati isključivo ispravljen tekst, bez objašnjenja \
        i bez navodnika. Imena i pojmovi koje treba poštovati: Nemanja Čedomirović, \
        Tamara Pandža, Diktator, Beograd.
        """
    }
}
