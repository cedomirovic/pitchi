// Opciono doterivanje teksta preko DeepSeek-a. Isključeno je po defaultu i
// šalje se samo gotov tekst (bez snimka) — i to samo ako korisnik uključi.
import Foundation

enum GreskaDoterivanja: LocalizedError {
    case nemaKljuca
    case odgovor
    case prazan

    var errorDescription: String? {
        switch self {
        case .nemaKljuca: return "DeepSeek ključ nije unet."
        case .odgovor: return "DeepSeek nije odgovorio kako treba."
        case .prazan: return "DeepSeek je vratio prazan tekst."
        }
    }
}

struct Doterivac {
    static func doteraj(_ tekst: String, kljuc: String, jezik: String = "sr") async throws -> String {
        guard !kljuc.isEmpty else { throw GreskaDoterivanja.nemaKljuca }
        guard let url = URL(string: "https://api.deepseek.com/chat/completions") else {
            throw GreskaDoterivanja.odgovor
        }

        var zahtev = URLRequest(url: url)
        zahtev.httpMethod = "POST"
        zahtev.timeoutInterval = 20
        zahtev.setValue("application/json", forHTTPHeaderField: "Content-Type")
        zahtev.setValue("Bearer \(kljuc)", forHTTPHeaderField: "Authorization")

        let uputstvo: String
        if jezik == "en" {
            uputstvo = """
            You are an English proofreader. Fix only punctuation, capitalization, \
            and obvious speech-recognition errors. Do not change the meaning, add \
            sentences, or translate. Return only the corrected text, without \
            explanations or quotation marks. Preserve these names and terms: \
            Nemanja Čedomirović, Tamara Pandža, Pitchi, Diktator, Beograd.
            """
        } else {
            uputstvo = """
            Ti si lektor za srpski jezik. Ispravi samo interpunkciju, velika slova i \
            očigledne greške u prepoznavanju govora. Ne menjaj smisao, ne dodaj nove \
            rečenice i ne prevodi. Vrati isključivo ispravljen tekst, bez objašnjenja \
            i bez navodnika. Imena i pojmovi koje treba poštovati: Nemanja Čedomirović, \
            Tamara Pandža, Pitchi, Diktator, Beograd.
            """
        }

        let telo: [String: Any] = [
            "model": "deepseek-chat",
            "temperature": 0,
            "messages": [
                ["role": "system", "content": uputstvo],
                ["role": "user", "content": tekst],
            ],
        ]
        zahtev.httpBody = try JSONSerialization.data(withJSONObject: telo)

        let (podaci, odgovor) = try await URLSession.shared.data(for: zahtev)
        guard let http = odgovor as? HTTPURLResponse, http.statusCode == 200 else {
            throw GreskaDoterivanja.odgovor
        }

        struct Odgovor: Decodable {
            struct Izbor: Decodable {
                struct Poruka: Decodable { let content: String }
                let message: Poruka
            }
            let choices: [Izbor]
        }

        let dekodirano = try JSONDecoder().decode(Odgovor.self, from: podaci)
        guard let tekst = dekodirano.choices.first?.message.content
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !tekst.isEmpty else {
            throw GreskaDoterivanja.prazan
        }
        return tekst
    }
}
