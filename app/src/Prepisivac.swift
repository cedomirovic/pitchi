// Prepisivanje zvuka preko whisper.cpp. Model se učitava tek kada zatreba i
// oslobađa posle mirovanja, da ne drži ~2 GB memorije bez potrebe.
import Foundation

enum GreskaPrepisaa: LocalizedError {
    case modelNijePreuzet
    case modelNeMoeDaSeUcita
    case dekodiranje

    var errorDescription: String? {
        switch self {
        case .modelNijePreuzet:
            return "Model za srpski još nije preuzet. Otvori Podešavanja i preuzmi ga (1 GB)."
        case .modelNeMoeDaSeUcita:
            return "Model nije mogao da se učita. Proveri da li je fajl kompletan."
        case .dekodiranje:
            return "Whisper nije uspeo da prepiše snimak."
        }
    }
}

final class Prepisivac {
    private var kontekst: OpaquePointer?
    private let red = DispatchQueue(label: "com.cedomirovic.pitchi.whisper")
    private let bravaStanja = NSLock()
    private var uMemoriji = false

    private(set) var ucitanaPutanja: String?

    var ucitano: Bool {
        bravaStanja.lock()
        defer { bravaStanja.unlock() }
        return uMemoriji
    }

    static func utisajLog() {
        whisper_log_set({ _, _, _ in }, nil)
    }

    func ucitaj(putanja: String) throws {
        try red.sync {
            if kontekst != nil, ucitanaPutanja == putanja { return }
            oslobodiBezReda()

            var parametri = whisper_context_default_params()
            parametri.use_gpu = true
            parametri.flash_attn = true

            guard let novi = whisper_init_from_file_with_params(putanja, parametri) else {
                throw GreskaPrepisaa.modelNeMoeDaSeUcita
            }
            kontekst = novi
            ucitanaPutanja = putanja
            postaviUcitan(true)
        }
    }

    /// Oslobađa model bez blokiranja UI-ja; ako se trenutno prepisuje, sačekaće
    /// da se posao završi pa tek onda osloboditi memoriju.
    func oslobodi() {
        red.async { [weak self] in
            self?.oslobodiBezReda()
        }
    }

    private func oslobodiBezReda() {
        if let kontekst {
            whisper_free(kontekst)
        }
        kontekst = nil
        ucitanaPutanja = nil
        postaviUcitan(false)
    }

    private func postaviUcitan(_ vrednost: Bool) {
        bravaStanja.lock()
        uMemoriji = vrednost
        bravaStanja.unlock()
    }

    func prepisi(uzorci: [Float], jezik: String, recnik: String) throws -> String {
        try red.sync {
            guard let kontekst else { throw GreskaPrepisaa.modelNijePreuzet }
            guard !uzorci.isEmpty else { return "" }
            guard let stanje = whisper_init_state(kontekst) else {
                throw GreskaPrepisaa.dekodiranje
            }
            defer { whisper_free_state(stanje) }

            var p = whisper_full_default_params(WHISPER_SAMPLING_BEAM_SEARCH)
            p.n_threads = 4
            p.translate = false
            p.no_context = true
            p.no_timestamps = true
            p.single_segment = false
            p.print_special = false
            p.print_progress = false
            p.print_realtime = false
            p.print_timestamps = false
            p.suppress_blank = true
            p.suppress_nst = true
            p.temperature = 0.0
            p.temperature_inc = 0.2
            p.beam_search.beam_size = 5
            p.greedy.best_of = 5
            p.detect_language = (jezik == "auto")

            let prompt = recnik.trimmingCharacters(in: .whitespacesAndNewlines)

            let rezultat: Int32 = jezik.withCString { jez in
                prompt.withCString { rec in
                    p.language = jez
                    p.initial_prompt = prompt.isEmpty ? nil : rec
                    return uzorci.withUnsafeBufferPointer { bafer in
                        whisper_full_with_state(
                            kontekst,
                            stanje,
                            p,
                            bafer.baseAddress,
                            Int32(bafer.count)
                        )
                    }
                }
            }

            guard rezultat == 0 else { throw GreskaPrepisaa.dekodiranje }

            var delovi: [String] = []
            let broj = whisper_full_n_segments_from_state(stanje)
            if broj > 0 {
                for i in 0..<broj {
                    if let tekst = whisper_full_get_segment_text_from_state(stanje, i) {
                        delovi.append(String(cString: tekst))
                    }
                }
            }
            return delovi.joined(separator: " ")
        }
    }
}
