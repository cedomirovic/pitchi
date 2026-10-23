// Snimanje sa mikrofona i pretvaranje u 16 kHz mono, kako whisper ocekuje.
import AVFoundation
import Foundation

enum GreskaSnimka: LocalizedError {
    case nemaMikrofona
    case nemaDozvole
    case pretvaranje

    var errorDescription: String? {
        switch self {
        case .nemaMikrofona: return "Nema dostupnog mikrofona."
        case .nemaDozvole: return "Diktator nema dozvolu za mikrofon. Otvori Podešavanja → Privatnost → Mikrofon."
        case .pretvaranje: return "Snimak nije mogao da se pripremi za prepis."
        }
    }
}

final class Snimac {
    private let motor = AVAudioEngine()
    private let ciljniFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16_000,
        channels: 1,
        interleaved: false
    )!
    private var pretvarac: AVAudioConverter?
    private let brava = NSLock()
    private var uzorci: [Float] = []
    private var aktivan = false
    private var zadnjiNivo = CFAbsoluteTimeGetCurrent()
    private var ukupnoUzoraka = 0

    var naNivo: ((Float) -> Void)?

    static var dozvola: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    var snima: Bool { aktivan }

    func pocni() throws {
        guard !aktivan else { return }
        guard Self.dozvola == .authorized else { throw GreskaSnimka.nemaDozvole }

        let ulaz = motor.inputNode
        let format = ulaz.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw GreskaSnimka.nemaMikrofona
        }
        guard let pretvarac = AVAudioConverter(from: format, to: ciljniFormat) else {
            throw GreskaSnimka.pretvaranje
        }
        pretvarac.sampleRateConverterQuality = AVAudioQuality.high.rawValue
        pretvarac.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_Normal

        brava.lock()
        uzorci.removeAll(keepingCapacity: true)
        ukupnoUzoraka = 0
        self.pretvarac = pretvarac
        brava.unlock()

        ulaz.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] bafer, _ in
            self?.obradi(bafer)
        }

        motor.prepare()
        do {
            try motor.start()
        } catch {
            ulaz.removeTap(onBus: 0)
            self.pretvarac = nil
            throw error
        }
        aktivan = true
    }

    private func obradi(_ bafer: AVAudioPCMBuffer) {
        guard let pretvarac else { return }
        let odnos = ciljniFormat.sampleRate / bafer.format.sampleRate
        let kapacitet = AVAudioFrameCount(Double(bafer.frameLength) * odnos) + 128
        guard let izlaz = AVAudioPCMBuffer(pcmFormat: ciljniFormat, frameCapacity: kapacitet) else {
            return
        }

        var greska: NSError?
        var iskoriscen = false
        let status = pretvarac.convert(to: izlaz, error: &greska) { _, stanje in
            if iskoriscen {
                stanje.pointee = .noDataNow
                return nil
            }
            iskoriscen = true
            stanje.pointee = .haveData
            return bafer
        }
        guard status != .error, let podaci = izlaz.floatChannelData?[0] else { return }

        let broj = Int(izlaz.frameLength)
        guard broj > 0 else { return }
        let deo = Array(UnsafeBufferPointer(start: podaci, count: broj))

        brava.lock()
        uzorci.append(contentsOf: deo)
        ukupnoUzoraka += broj
        brava.unlock()

        // Nivo za UI (RMS u dB, preslikano na 0…1).
        var suma: Float = 0
        for v in deo { suma += v * v }
        let rms = sqrt(suma / Float(broj))
        let db = 20 * log10(max(rms, 0.000_001))
        let nivo = min(1, max(0, (db + 55) / 55))

        let sada = CFAbsoluteTimeGetCurrent()
        if sada - zadnjiNivo > 0.05 {
            zadnjiNivo = sada
            DispatchQueue.main.async { [weak self] in
                self?.naNivo?(nivo)
            }
        }
    }

    func zaustavi() -> [Float] {
        guard aktivan else { return [] }
        aktivan = false
        motor.stop()
        motor.inputNode.removeTap(onBus: 0)

        brava.lock()
        let rezultat = uzorci
        uzorci.removeAll(keepingCapacity: false)
        pretvarac = nil
        brava.unlock()

        DispatchQueue.main.async { [weak self] in
            self?.naNivo?(0)
        }
        return rezultat
    }

    func otkazi() {
        _ = zaustavi()
    }

    static func trajanje(_ brojUzoraka: Int) -> Double {
        Double(brojUzoraka) / 16_000.0
    }

    /// Skida tisinu sa pocetka i kraja, da whisper ne bi izmisljao tekst.
    static func skratiTisinu(_ ulaz: [Float], prag: Float = 0.012) -> [Float] {
        guard !ulaz.isEmpty else { return [] }

        var prvi: Int?
        for (i, v) in ulaz.enumerated() where abs(v) > prag {
            prvi = i
            break
        }
        guard let pocetak = prvi else { return [] }

        var kraj = pocetak
        for i in stride(from: ulaz.count - 1, through: pocetak, by: -1) where abs(ulaz[i]) > prag {
            kraj = i
            break
        }

        let pauza = Int(0.18 * 16_000)
        let od = max(0, pocetak - pauza)
        let doKraja = min(ulaz.count, kraj + pauza)
        guard doKraja > od else { return [] }
        return Array(ulaz[od..<doKraja])
    }
}
