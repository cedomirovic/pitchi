// Centralno stanje aplikacije i ceo tok: snimi -> prepiši -> sredi -> zalepi.
import AVFoundation
import AppKit
import Combine
import Foundation

final class AppStanje: NSObject, ObservableObject {
    static let modelURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-q5_0.bin")!
    static let modelVelicina: Int64 = 1_081_140_203

    @Published var stanje: StanjeAplikacije = .mirno
    @Published var nivo: Float = 0
    @Published var sekunde: Int = 0
    @Published var podesavanja: Podesavanja
    @Published var istorija: [Zapis]
    @Published var recnik: String
    @Published var dozvole = Dozvole()
    @Published var precicaRadi = false
    @Published var modelPutanja: URL?
    @Published var modelUcitan = false
    @Published var preuzimaModel = false
    @Published var napredakModela: Double = 0
    @Published var poslednjiTekst = ""
    @Published var greska: String?
    @Published var info: String?
    @Published var izabranTab = 0
    @Published var deepSeekKljuc = ""

    let snimac = Snimac()
    let prepisivac = Prepisivac()
    let preuzimac = Preuzimac()
    let tastatura = Tastatura()

    private var tajmerOslobadjanja: Timer?
    private var tajmerSekundi: Timer?
    private var pocetakSnimanja = Date()
    private var aplikacijaPreSnimanja: NSRunningApplication?
    private var zadnjaSpoljnaAplikacija: NSRunningApplication?
    private var pretplate = Set<AnyCancellable>()
    private var brojInfo = 0

    override init() {
        podesavanja = SkladistePodesavanja.ucitaj()
        istorija = IstorijaSkladiste.ucitaj()
        recnik = Recnik.ucitaj()
        deepSeekKljuc = Kljuc.citaj() ?? ""
        super.init()

        Prepisivac.utisajLog()
        osveziModel()
        osveziDozvole()

        snimac.naNivo = { [weak self] vrednost in
            self?.nivo = vrednost
        }

        preuzimac.naNapredak = { [weak self] procenat in
            self?.napredakModela = procenat
        }
        preuzimac.naKraj = { [weak self] rezultat in
            guard let self else { return }
            self.preuzimaModel = false
            switch rezultat {
            case .success:
                self.osveziModel()
                self.postaviInfo("Model je preuzet. Možeš da diktiraš.")
            case .failure(let error):
                self.greska = "Preuzimanje nije uspelo: \(error.localizedDescription)"
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(promenjenaAplikacija(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        pokreniTastaturu()
    }

    deinit {
        tastatura.zaustavi()
    }

    // MARK: - Dozvole

    func osveziDozvole() {
        dozvole = Dozvole(
            mikrofon: AVCaptureDevice.authorizationStatus(for: .audio) == .authorized,
            pristupacnost: Lepak.dozvola,
            nadzorUnosa: Tastatura.dozvola
        )
        if dozvole.nadzorUnosa {
            pokreniTastaturu()
        }
    }

    func zatrazMikrofon() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            osveziDozvole()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
                DispatchQueue.main.async { self?.osveziDozvole() }
            }
        default:
            otvoriPodesavanja("Privacy_Microphone")
        }
    }

    func zatrazPristupacnost() {
        Lepak.zatrazDozvolu()
        otvoriPodesavanja("Privacy_Accessibility")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in self?.osveziDozvole() }
    }

    func zatrazNadzorUnosa() {
        _ = CGRequestListenEventAccess()
        otvoriPodesavanja("Privacy_ListenEvent")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.osveziDozvole()
            self?.pokreniTastaturu()
        }
    }

    func otvoriPodesavanja(_ odeljak: String) {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(odeljak)")!
        NSWorkspace.shared.open(url)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.osveziDozvole() }
    }

    // MARK: - Precica

    func pokreniTastaturu() {
        tastatura.naPritisak = { [weak self] in self?.pocniSnimanje() }
        tastatura.naOtpust = { [weak self] in self?.zavrsiSnimanje() }
        precicaRadi = tastatura.pokreni()
    }

    // MARK: - Model

    func osveziModel() {
        modelPutanja = Putanje.nadjiPostojeciModel()
    }

    var modelSpreman: Bool { modelPutanja != nil }

    var opisModela: String {
        guard let modelPutanja else { return "nije preuzet" }
        let velicina = Putanje.velicina(modelPutanja)
        let naziv = Putanje.poznatiModeli[velicina] ?? "nepoznat"
        let gb = Double(velicina) / 1_073_741_824
        return String(format: "%@ · %.1f GB", naziv, gb)
    }

    func preuzmiModel() {
        guard !preuzimaModel else { return }
        preuzimaModel = true
        napredakModela = 0
        preuzimac.pocni(od: Self.modelURL, u: Putanje.model, velicina: Self.modelVelicina)
    }

    func otkaziPreuzimanje() {
        preuzimac.otkazi()
        preuzimaModel = false
    }

    func oslobodiMemoriju() {
        prepisivac.oslobodi()
        modelUcitan = false
        postaviInfo("Model je oslobođen iz memorije.")
    }

    // MARK: - Snimanje

    func prebaciSnimanje() {
        if stanje.jeSnimanje {
            zavrsiSnimanje()
        } else if !stanje.jeZauzet {
            pocniSnimanje()
        }
    }

    func pocniSnimanje() {
        guard !stanje.jeSnimanje, !stanje.jeZauzet else { return }

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] dozvoljeno in
                DispatchQueue.main.async {
                    self?.osveziDozvole()
                    if dozvoljeno { self?.pocniSnimanje() }
                }
            }
            return
        default:
            greska = "Dozvoli pristup mikrofonu u Podešavanjima → Privatnost → Mikrofon."
            return
        }

        let prednja = NSWorkspace.shared.frontmostApplication
        if prednja?.bundleIdentifier != Bundle.main.bundleIdentifier {
            aplikacijaPreSnimanja = prednja ?? zadnjaSpoljnaAplikacija
        } else {
            aplikacijaPreSnimanja = zadnjaSpoljnaAplikacija
        }

        do {
            try snimac.pocni()
        } catch {
            greska = error.localizedDescription
            return
        }

        greska = nil
        info = nil
        nivo = 0
        sekunde = 0
        pocetakSnimanja = Date()
        tajmerOslobadjanja?.invalidate()
        stanje = .snima
        pustiZvuk("Tink")
        pokreniTajmerSekundi()
    }

    func zavrsiSnimanje() {
        guard stanje.jeSnimanje else { return }
        zaustaviTajmerSekundi()
        let uzorci = snimac.zaustavi()
        nivo = 0
        pustiZvuk("Pop")

        let ocisceno = Snimac.skratiTisinu(uzorci)
        let trajanje = Double(ocisceno.count) / 16_000.0
        guard trajanje >= 0.35 else {
            stanje = .mirno
            postaviInfo("Snimak je prekratak — drži Fn dok govoriš.")
            return
        }

        obradi(ocisceno, trajanje: trajanje)
    }

    func otkaziSnimanje() {
        guard stanje.jeSnimanje else { return }
        zaustaviTajmerSekundi()
        snimac.otkazi()
        nivo = 0
        stanje = .mirno
        postaviInfo("Snimak je otkazan.")
    }

    private func pokreniTajmerSekundi() {
        tajmerSekundi?.invalidate()
        tajmerSekundi = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, self.stanje.jeSnimanje else { return }
            self.sekunde = Int(Date().timeIntervalSince(self.pocetakSnimanja))
        }
    }

    private func zaustaviTajmerSekundi() {
        tajmerSekundi?.invalidate()
        tajmerSekundi = nil
    }

    // MARK: - Prepis

    private func obradi(_ uzorci: [Float], trajanje: Double) {
        guard let putanja = modelPutanja ?? Putanje.nadjiPostojeciModel() else {
            stanje = .mirno
            greska = GreskaPrepisaa.modelNijePreuzet.localizedDescription
            izabranTab = 2
            return
        }
        modelPutanja = putanja

        stanje = .priprema
        tajmerOslobadjanja?.invalidate()
        let jezik = podesavanja.jezik
        let prompt = Recnik.kaoPrompt(recnik)
        let doteruj = podesavanja.doterivanje
        let kljuc = deepSeekKljuc

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                if !self.prepisivac.ucitano {
                    try self.prepisivac.ucitaj(putanja: putanja.path)
                }
                DispatchQueue.main.async {
                    self.modelUcitan = true
                    self.stanje = .prepisuje
                }

                let sirovo = try self.prepisivac.prepisi(
                    uzorci: uzorci,
                    jezik: jezik,
                    recnik: prompt
                )
                let sredjeno = Tekst.sredi(sirovo)

                guard !sredjeno.isEmpty else {
                    DispatchQueue.main.async {
                        self.stanje = .mirno
                        self.postaviInfo("Nisam čuo govor. Probaj bliže mikrofonu.")
                    }
                    return
                }

                if doteruj, !kljuc.isEmpty {
                    Task { [weak self] in
                        guard let self else { return }
                        do {
                            let doteran = try await Doterivac.doteraj(sredjeno, kljuc: kljuc)
                            DispatchQueue.main.async {
                                self.dovrsi(doteran, trajanje: trajanje, napomena: nil)
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.dovrsi(
                                    sredjeno,
                                    trajanje: trajanje,
                                    napomena: "Doterivanje nije uspelo — ostavljen je sirov prepis."
                                )
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.dovrsi(sredjeno, trajanje: trajanje, napomena: nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.stanje = .mirno
                    self.greska = error.localizedDescription
                }
            }
        }
    }

    private func dovrsi(_ tekst: String, trajanje: Double, napomena: String?) {
        poslednjiTekst = tekst
        stanje = .mirno
        if podesavanja.cuvajIstoriju {
            istorija.insert(Zapis(tekst: tekst, trajanje: trajanje, jezik: podesavanja.jezik), at: 0)
            if istorija.count > 200 { istorija = Array(istorija.prefix(200)) }
            IstorijaSkladiste.sacuvaj(istorija)
        }
        zakaziOslobadjanje()

        if let napomena {
            postaviInfo(napomena)
        }
        isporuci(tekst)
    }

    // MARK: - Lepljenje

    private func isporuci(_ tekst: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(tekst, forType: .string)

        guard podesavanja.automatskoLepljenje else {
            postaviInfo("Tekst je u klipbordu. Zalepi ga sa Cmd+V.")
            return
        }
        guard Lepak.dozvola else {
            postaviInfo("Tekst je u klipbordu. Za automatsko lepljenje dozvoli Pristupačnost.")
            return
        }

        let nas = Bundle.main.bundleIdentifier
        var cilj: NSRunningApplication?
        if let prednja = NSWorkspace.shared.frontmostApplication, prednja.bundleIdentifier != nas {
            cilj = prednja
        } else if let pre = aplikacijaPreSnimanja, pre.bundleIdentifier != nas, !pre.isTerminated {
            cilj = pre
        }

        guard let cilj else {
            postaviInfo("Tekst je u klipbordu. Zalepi ga sa Cmd+V.")
            return
        }

        cilj.activate(options: [.activateIgnoringOtherApps])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            Lepak.zalepi()
        }
    }

    func kopiraj(_ tekst: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(tekst, forType: .string)
        postaviInfo("Kopirano u klipbord.")
    }

    func zalepiPoslednji() {
        guard !poslednjiTekst.isEmpty else { return }
        isporuci(poslednjiTekst)
    }

    // MARK: - Istorija i recnik

    func obrisi(_ zapis: Zapis) {
        istorija.removeAll { $0.id == zapis.id }
        IstorijaSkladiste.sacuvaj(istorija)
    }

    func obrisiIstoriju() {
        istorija.removeAll()
        IstorijaSkladiste.sacuvaj(istorija)
        postaviInfo("Istorija je obrisana.")
    }

    func sacuvajPodesavanja() {
        SkladistePodesavanja.sacuvaj(podesavanja)
    }

    func sacuvajRecnik() {
        Recnik.sacuvaj(recnik)
    }

    func sacuvajKljuc() {
        Kljuc.upisi(deepSeekKljuc)
        postaviInfo(deepSeekKljuc.isEmpty ? "Ključ je obrisan." : "Ključ je sačuvan u Keychain-u.")
    }

    // MARK: - Pomoćno

    private func zakaziOslobadjanje() {
        tajmerOslobadjanja?.invalidate()
        tajmerOslobadjanja = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.prepisivac.oslobodi()
            self.modelUcitan = false
        }
    }

    private func pustiZvuk(_ ime: String) {
        guard podesavanja.zvuk else { return }
        NSSound(named: NSSound.Name(ime))?.play()
    }

    func postaviInfo(_ poruka: String) {
        brojInfo += 1
        let mojBroj = brojInfo
        info = poruka
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self, self.brojInfo == mojBroj else { return }
            self.info = nil
        }
    }

    func resetujGresku() {
        greska = nil
        if case .greska = stanje { stanje = .mirno }
    }

    @objc private func promenjenaAplikacija(_ obavestenje: Notification) {
        guard let aplikacija = obavestenje.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        if aplikacija.bundleIdentifier != Bundle.main.bundleIdentifier {
            zadnjaSpoljnaAplikacija = aplikacija
        }
    }
}
