// Zajednicke putanje i mesta gde Diktator cuva svoje fajlove.
import Foundation

enum Putanje {
    static var podrska: URL {
        let baza = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = baza.appendingPathComponent("Diktator", isDirectory: true)

        // Jednokratna migracija: stari folder sadrži model, istoriju i rečnik.
        // Ako premestanje ne uspe, nastavljamo da koristimo stari folder da
        // korisnik ne izgubi podatke.
        let fm = FileManager.default
        if !fm.fileExists(atPath: dir.path) {
            let stara = baza.appendingPathComponent("Pitchi", isDirectory: true)
            if fm.fileExists(atPath: stara.path) {
                do {
                    try fm.moveItem(at: stara, to: dir)
                } catch {
                    return stara
                }
            }
        }

        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var modeli: URL {
        let dir = podrska.appendingPathComponent("models", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var istorija: URL {
        podrska.appendingPathComponent("istorija.json")
    }

    static var recnik: URL {
        podrska.appendingPathComponent("recnik.txt")
    }

    static var stariRecnik: URL {
        let baza = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baza.appendingPathComponent("Pichi/vocabulary.txt")
    }

    static func velicina(_ url: URL) -> Int64 {
        guard let atributi = try? FileManager.default.attributesOfItem(atPath: url.path),
              let broj = atributi[.size] as? NSNumber else { return 0 }
        return broj.int64Value
    }
}
