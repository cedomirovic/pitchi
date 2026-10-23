// Zajednicke putanje i mesta gde Pitchi cuva svoje fajlove.
import Foundation

enum Putanje {
    static var podrska: URL {
        let baza = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = baza.appendingPathComponent("Pitchi", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
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
