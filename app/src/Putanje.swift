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

    static var model: URL {
        modeli.appendingPathComponent("ggml-large-v3-q5_0.bin")
    }

    static var istorija: URL {
        podrska.appendingPathComponent("istorija.json")
    }

    static var recnik: URL {
        podrska.appendingPathComponent("recnik.txt")
    }

    /// Stari Pichi je cuvao model ovde; ako postoji, koristimo ga da ne bi
    /// ponovo skidali 1 GB.
    static var stariModeli: URL {
        let baza = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baza.appendingPathComponent("Pichi/models", isDirectory: true)
    }

    static var stariRecnik: URL {
        let baza = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baza.appendingPathComponent("Pichi/vocabulary.txt")
    }

    /// Velicine poznatih modela, da znamo sta smo nasli na disku.
    static let poznatiModeli: [Int64: String] = [
        1_081_140_203: "large-v3 q5_0",
        574_041_195: "large-v3-turbo q5_0",
        3_095_033_483: "large-v3 f16",
        181_000_000: "small",
    ]

    static func velicina(_ url: URL) -> Int64 {
        guard let atributi = try? FileManager.default.attributesOfItem(atPath: url.path),
              let broj = atributi[.size] as? NSNumber else { return 0 }
        return broj.int64Value
    }

    /// Trazi najbolji model koji vec postoji na Macu.
    static func nadjiPostojeciModel() -> URL? {
        var kandidati: [URL] = []

        if FileManager.default.fileExists(atPath: model.path) {
            kandidati.append(model)
        }

        let folderi = [modeli, stariModeli]
        for folder in folderi {
            guard let fajlovi = try? FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            for fajl in fajlovi where fajl.pathExtension.lowercased() == "bin" {
                if !kandidati.contains(where: { $0.path == fajl.path }) {
                    kandidati.append(fajl)
                }
            }
        }

        // Prvo large-v3 q5_0, pa turbo, pa ostalo.
        let redosled: [Int64] = [1_081_140_203, 574_041_195]
        for zeljena in redosled {
            if let nadjen = kandidati.first(where: { velicina($0) == zeljena }) {
                return nadjen
            }
        }
        return kandidati.first
    }
}
