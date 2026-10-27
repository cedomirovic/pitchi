// Katalog whisper.cpp modela koje korisnik moze da preuzme i izabere.
import Foundation

struct PonudaModela: Identifiable, Equatable {
    let id: String
    let naziv: String
    let opis: String
    let velicina: Int64
    let preporucen: Bool
    let url: URL

    /// Ljudski citljiva velicina (binarne jedinice, kao u aplikaciji).
    var velicinaTekst: String {
        if velicina >= 1_073_741_824 {
            return String(format: "%.1f GB", Double(velicina) / 1_073_741_824)
        }
        return String(format: "%.0f MB", Double(velicina) / 1_048_576)
    }

    var putanja: URL {
        Putanje.modeli.appendingPathComponent(id)
    }

    /// Model je preuzet samo ako je fajl tu i ako je cela ocekivana velicina.
    var preuzet: Bool {
        FileManager.default.fileExists(atPath: putanja.path) &&
            Putanje.velicina(putanja) == velicina
    }
}

enum Modeli {
    /// Redosled u izboru: od najlaksih ka najkvalitetnijim.
    static let svi: [PonudaModela] = [
        PonudaModela(
            id: "ggml-tiny.bin",
            naziv: "Tiny",
            opis: "Najmanji i najbrži. Dobar za brze probe, ali češće pogreši imena i ređe reči.",
            velicina: 77_691_713,
            preporucen: false,
            url: adresa("ggml-tiny.bin")
        ),
        PonudaModela(
            id: "ggml-base.bin",
            naziv: "Base",
            opis: "Mali i brz. Osnovni kvalitet, primetno slabiji od Small i Turbo modela.",
            velicina: 147_951_465,
            preporucen: false,
            url: adresa("ggml-base.bin")
        ),
        PonudaModela(
            id: "ggml-small.bin",
            naziv: "Small",
            opis: "Lakši model za Macove sa malo RAM-a. Solidan, ali nešto sporiji od Turbo modela.",
            velicina: 487_601_967,
            preporucen: false,
            url: adresa("ggml-small.bin")
        ),
        PonudaModela(
            id: "ggml-large-v3-turbo-q5_0.bin",
            naziv: "Large v3 Turbo",
            opis: "Preporučeno za 8 GB. Brz, troši manje memorije i kvalitetom je blizu Large v3.",
            velicina: 574_041_195,
            preporucen: true,
            url: adresa("ggml-large-v3-turbo-q5_0.bin")
        ),
        PonudaModela(
            id: "ggml-large-v3-q5_0.bin",
            naziv: "Large v3",
            opis: "Najbolji kvalitet, posebno za imena i stručne reči. Traži više RAM-a i sporije se učitava.",
            velicina: 1_081_140_203,
            preporucen: false,
            url: adresa("ggml-large-v3-q5_0.bin")
        ),
    ]

    /// Model koji se nudi novim korisnicima.
    static let podrazumevani = svi.first { $0.preporucen } ?? svi[0]

    /// Model za brzi režim: Turbo je oko dva puta brži i ~500 MB lakši.
    static let brzi = nadji("ggml-large-v3-turbo-q5_0.bin") ?? podrazumevani

    static func nadji(_ id: String) -> PonudaModela? {
        svi.first { $0.id == id }
    }

    /// Najbolji model koji vec postoji na disku (za migraciju i razvojnu proveru).
    static func nadjiPostojeci() -> PonudaModela? {
        let redosled = [
            "ggml-large-v3-q5_0.bin",
            "ggml-large-v3-turbo-q5_0.bin",
            "ggml-small.bin",
            "ggml-base.bin",
            "ggml-tiny.bin",
        ]
        for id in redosled {
            if let model = nadji(id), model.preuzet {
                return model
            }
        }
        return nil
    }

    private static func adresa(_ ime: String) -> URL {
        URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(ime)")!
    }
}
