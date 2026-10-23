// Preuzimanje modela sa Hugging Face-a, sa napretkom u UI-ju.
import Foundation

final class Preuzimac: NSObject, URLSessionDownloadDelegate {
    var naNapredak: ((Double) -> Void)?
    var naKraj: ((Result<URL, Error>) -> Void)?

    private var sesija: URLSession!
    private var odrediste: URL?
    private var ocekivanaVelicina: Int64 = 0

    override init() {
        super.init()
        sesija = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func pocni(od url: URL, u odrediste: URL, velicina: Int64) {
        self.odrediste = odrediste
        self.ocekivanaVelicina = velicina
        naNapredak?(0)
        let zadatak = sesija.downloadTask(with: url)
        zadatak.resume()
    }

    func otkazi() {
        sesija.getAllTasks { zadaci in
            zadaci.forEach { $0.cancel() }
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let ukupno = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : ocekivanaVelicina
        guard ukupno > 0 else { return }
        let procenat = min(1, Double(totalBytesWritten) / Double(ukupno))
        DispatchQueue.main.async { [weak self] in self?.naNapredak?(procenat) }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let odrediste else { return }
        do {
            try FileManager.default.createDirectory(
                at: odrediste.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: odrediste.path) {
                try FileManager.default.removeItem(at: odrediste)
            }
            try FileManager.default.moveItem(at: location, to: odrediste)

            let velicina = Putanje.velicina(odrediste)
            if ocekivanaVelicina > 0 && velicina != ocekivanaVelicina {
                try? FileManager.default.removeItem(at: odrediste)
                throw GreskaPreuzimanja.neispravanFajl
            }
            DispatchQueue.main.async { [weak self] in
                self?.naNapredak?(1)
                self?.naKraj?(.success(odrediste))
            }
        } catch {
            DispatchQueue.main.async { [weak self] in self?.naKraj?(.failure(error)) }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled {
            return
        }
        DispatchQueue.main.async { [weak self] in self?.naKraj?(.failure(error)) }
    }
}

enum GreskaPreuzimanja: LocalizedError {
    case neispravanFajl

    var errorDescription: String? {
        switch self {
        case .neispravanFajl: return "Preuzeti model nije kompletan. Pokušaj ponovo."
        }
    }
}
