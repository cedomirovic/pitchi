// Whisper za srpski ume da vrati cirilicu. Korisnik pise latinicom, pa sve
// prevodimo pre nego sto tekst ode u klipbord.
import Foundation

enum Tekst {
    private static let mapa: [Character: String] = [
        "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "ђ": "đ",
        "е": "e", "ж": "ž", "з": "z", "и": "i", "ј": "j", "к": "k",
        "л": "l", "љ": "lj", "м": "m", "н": "n", "њ": "nj", "о": "o",
        "п": "p", "р": "r", "с": "s", "т": "t", "ћ": "ć", "у": "u",
        "ф": "f", "х": "h", "ц": "c", "ч": "č", "џ": "dž", "ш": "š",
        "А": "A", "Б": "B", "В": "V", "Г": "G", "Д": "D", "Ђ": "Đ",
        "Е": "E", "Ж": "Ž", "З": "Z", "И": "I", "Ј": "J", "К": "K",
        "Л": "L", "Љ": "Lj", "М": "M", "Н": "N", "Њ": "Nj", "О": "O",
        "П": "P", "Р": "R", "С": "S", "Т": "T", "Ћ": "Ć", "У": "U",
        "Ф": "F", "Х": "H", "Ц": "C", "Ч": "Č", "Џ": "Dž", "Ш": "Š",
    ]

    static func imaCirilicu(_ tekst: String) -> Bool {
        tekst.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) }
    }

    static func naLatnicu(_ tekst: String) -> String {
        guard imaCirilicu(tekst) else { return tekst }
        var izlaz = ""
        izlaz.reserveCapacity(tekst.count)
        for znak in tekst {
            if let latinicno = mapa[znak] {
                izlaz += latinicno
            } else {
                izlaz.append(znak)
            }
        }
        return izlaz
    }

    /// Skida visak razmaka i lepi interpunkciju za prethodnu rec.
    /// Tacka se ne odvaja od reci kada je deo imena ili broja ("whisper.cpp",
    /// "Node.js", "v1.2") — razmak se dodaje samo ispred velikog slova.
    static func ocisti(_ tekst: String) -> String {
        var t = tekst.replacingOccurrences(of: "\u{00A0}", with: " ")
        t = t.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        t = t.replacingOccurrences(of: "\\s+([,.;:!?])", with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: "(\\p{Ll}|\\d)\\.(\\p{Lu})", with: "$1. $2", options: .regularExpression)
        t = t.replacingOccurrences(of: "([,;:!?])(?=\\S)", with: "$1 ", options: .regularExpression)
        t = t.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whisper ume da ponovi istu recenicu na kraju; skidamo duplikat.
    static func bezPonavljanja(_ tekst: String) -> String {
        let recenice = tekst
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard recenice.count >= 2, recenice.count % 2 == 0 else { return tekst }

        let pola = recenice.count / 2
        let prva = recenice[0..<pola].joined(separator: ". ")
        let druga = recenice[pola...].joined(separator: ". ")
        if prva.caseInsensitiveCompare(druga) == .orderedSame {
            return prva + "."
        }
        return tekst
    }

    /// Uklanja zagrade i navodnike koje model ponekad doda oko celog teksta.
    static func bezUkrasa(_ tekst: String) -> String {
        var t = tekst.trimmingCharacters(in: .whitespacesAndNewlines)
        let parovi: [(Character, Character)] = [("\"", "\""), ("„", "“"), ("'", "'")]
        for (pocetak, kraj) in parovi where t.count >= 2 {
            if t.first == pocetak && t.last == kraj {
                t = String(t.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return t
    }

    static func sredi(_ tekst: String) -> String {
        var t = naLatnicu(tekst)
        t = bezPonavljanja(t)
        t = bezUkrasa(t)
        return ocisti(t)
    }
}
