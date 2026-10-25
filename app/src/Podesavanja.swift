// Cuvanje podesavanja i API kljuca (kljuc ide u Keychain, ne u UserDefaults).
import Foundation
import Security

final class SkladistePodesavanja {
    // Kljuc je zadrzao staro ime da postojeća podesavanja ostanu vidljiva
    // posle preimenovanja aplikacije.
    private static let kljuc = "pitchi.podesavanja.v1"

    static func ucitaj() -> Podesavanja {
        guard let podaci = UserDefaults.standard.data(forKey: kljuc),
              let p = try? JSONDecoder().decode(Podesavanja.self, from: podaci) else {
            return Podesavanja()
        }
        return p
    }

    static func sacuvaj(_ p: Podesavanja) {
        guard let podaci = try? JSONEncoder().encode(p) else { return }
        UserDefaults.standard.set(podaci, forKey: kljuc)
    }
}

enum Kljuc {
    // Servis je zadrzao stari bundle ID da API kljucevi u Keychain-u ostanu
    // dostupni bez ponovnog unosa.
    private static let servis = "com.cedomirovic.pitchi"

    /// Svaki servis ima svoj nalog u Keychain-u, pa se ključevi ne mešaju.
    /// Stari DeepSeek ključ je već pod nalogom „deepseek“ i zato ostaje važeći.
    /// Vraća `false` ako Keychain nije prihvatio zapis.
    @discardableResult
    static func upisi(_ vrednost: String, za provajder: String) -> Bool {
        obrisi(za: provajder)
        guard !vrednost.isEmpty, let podaci = vrednost.data(using: .utf8) else { return true }
        let upit: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servis,
            kSecAttrAccount as String: provajder,
            kSecValueData as String: podaci,
            // Ključ je dostupan samo dok je Mac otključan i samo na ovom uređaju.
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false,
        ]
        return SecItemAdd(upit as CFDictionary, nil) == errSecSuccess
    }

    static func citaj(za provajder: String) -> String? {
        let upit: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servis,
            kSecAttrAccount as String: provajder,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var rezultat: AnyObject?
        guard SecItemCopyMatching(upit as CFDictionary, &rezultat) == errSecSuccess,
              let podaci = rezultat as? Data else { return nil }
        return String(data: podaci, encoding: .utf8)
    }

    static func obrisi(za provajder: String) {
        let upit: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servis,
            kSecAttrAccount as String: provajder,
        ]
        SecItemDelete(upit as CFDictionary)
    }
}

final class IstorijaSkladiste {
    static func ucitaj() -> [Zapis] {
        guard let podaci = try? Data(contentsOf: Putanje.istorija),
              let zapisi = try? JSONDecoder().decode([Zapis].self, from: podaci) else {
            return []
        }
        Putanje.zastitiFajl(Putanje.istorija)
        return zapisi
    }

    static func sacuvaj(_ zapisi: [Zapis]) {
        let ograniceno = Array(zapisi.prefix(200))
        guard let podaci = try? JSONEncoder().encode(ograniceno) else { return }
        try? podaci.write(to: Putanje.istorija, options: .atomic)
        Putanje.zastitiFajl(Putanje.istorija)
    }
}

enum Recnik {
    static func ucitaj() -> String {
        if let tekst = try? String(contentsOf: Putanje.recnik, encoding: .utf8) {
            Putanje.zastitiFajl(Putanje.recnik)
            return tekst
        }
        // Prvi put: preuzmi recnik starog Pichija ako postoji.
        if let stari = try? String(contentsOf: Putanje.stariRecnik, encoding: .utf8),
           !stari.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? stari.write(to: Putanje.recnik, atomically: true, encoding: .utf8)
            Putanje.zastitiFajl(Putanje.recnik)
            return stari
        }
        return ""
    }

    static func sacuvaj(_ tekst: String) {
        try? tekst.write(to: Putanje.recnik, atomically: true, encoding: .utf8)
        Putanje.zastitiFajl(Putanje.recnik)
    }

    /// Recnik ide whisper-u kao pocetni tekst (prompt), zato ga kratimo.
    static func kaoPrompt(_ tekst: String) -> String {
        let redovi = tekst
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let spojeno = redovi.joined(separator: ", ")
        if spojeno.count <= 600 { return spojeno }
        return String(spojeno.prefix(600))
    }
}
