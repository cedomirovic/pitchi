// Centralno stanje aplikacije i ceo tok: snimi -> prepiši -> sredi -> zalepi.
import AVFoundation
import AppKit
import Combine
import Foundation

final class AppStanje: NSObject, ObservableObject {
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
    @Published var modelPreuzimanja: String?
    @Published var napredakModela: Double = 0
    @Published var prijavaUkljucena = false
    @Published var prijavaZahtevaOdobrenje = false
    @Published var poslednjiTekst = ""
    @Published var greska: String?
    @Published var info: String?
    @Published var izabranTab = 0
    @Published var kljucDoterivanja = ""
    @Published var testiraDoterivanje = false
    @Published var azuriranje: Izdanje?
    @Published var proveravaAzuriranja = false
    @Published var sakrijTrakuAzuriranja = false
    @Published var zadnjaProveraAzuriranja: Date?
    @Published var statistika: Statistika

    let snimac = Snimac()
    let prepisivac = Prepisivac()
    let preuzimac = Preuzimac()
    let tastatura = Tastatura()

    private var tajmerOslobadjanja: Timer?
    private var tajmerSekundi: Timer?
    private var tajmerAzuriranja: Timer?
    private var pocetakSnimanja = Date()
    private var aplikacijaPreSnimanja: NSRunningApplication?
    private var zadnjaSpoljnaAplikacija: NSRunningApplication?
    private var pretplate = Set<AnyCancellable>()
    private var brojInfo = 0

    override init() {
        let ucitanaPodesavanja = SkladistePodesavanja.ucitaj()
        podesavanja = ucitanaPodesavanja
        istorija = IstorijaSkladiste.ucitaj()
        recnik = Recnik.ucitaj()
        statistika = StatistikaSkladiste.ucitaj()
        kljucDoterivanja = Kljuc.citaj(za: ucitanaPodesavanja.provajderDoterivanja) ?? ""
        super.init()

        Prepisivac.utisajLog()
        osveziModel()
        osveziDozvole()
        osveziPrijavu()
        zadnjaProveraAzuriranja = SkladisteAzuriranja.zadnjaProvera
        vratiPoznatoAzuriranje()
        pokreniProveruAzuriranja()

        snimac.naNivo = { [weak self] vrednost in
            self?.nivo = vrednost
        }

        preuzimac.naNapredak = { [weak self] procenat in
            self?.napredakModela = procenat
        }
        preuzimac.naKraj = { [weak self] rezultat in
            guard let self else { return }
            let naziv = Modeli.nadji(self.modelPreuzimanja ?? "")?.naziv ?? "Model"
            self.preuzimaModel = false
            self.modelPreuzimanja = nil
            switch rezultat {
            case .success:
                self.osveziModel()
                self.postaviInfo("\(naziv) je preuzet. Možeš da diktiraš.")
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
        tajmerAzuriranja?.invalidate()
        tajmerOslobadjanja?.invalidate()
        tajmerSekundi?.invalidate()
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

    // MARK: - Prijava pri pokretanju

    func osveziPrijavu() {
        prijavaUkljucena = Prijava.ukljucena
        prijavaZahtevaOdobrenje = Prijava.zahtevaOdobrenje
    }

    func postaviPrijavu(_ zeljeno: Bool) {
        do {
            try Prijava.postavi(zeljeno)
        } catch {
            greska = "Pokretanje pri prijavi nije promenjeno: \(error.localizedDescription)"
        }

        osveziPrijavu()
        if prijavaZahtevaOdobrenje {
            postaviInfo("Odobri Diktator u System Settings → General → Login Items.")
        } else if prijavaUkljucena {
            postaviInfo("Diktator će se pokretati pri prijavi računara.")
        } else {
            postaviInfo("Pokretanje pri prijavi je isključeno.")
        }
    }

    func otvoriPrijavuPodesavanja() {
        Prijava.otvoriPodesavanja()
    }

    // MARK: - Precica

    var izabranaPrecica: Precica {
        Precica.iz(podesavanja.precica)
    }

    var nazivPrecice: String { izabranaPrecica.naziv }
    var simbolPrecice: String { izabranaPrecica.simbol }

    func pokreniTastaturu() {
        tastatura.precica = izabranaPrecica
        tastatura.naPritisak = { [weak self] in self?.pocniSnimanje() }
        tastatura.naOtpust = { [weak self] in self?.zavrsiSnimanje() }
        tastatura.naPrekidac = { [weak self] in self?.prebaciSnimanje() }
        precicaRadi = tastatura.pokreni()
    }

    // MARK: - Model

    var izabraniModel: PonudaModela {
        Modeli.nadji(podesavanja.model) ?? Modeli.podrazumevani
    }

    var oslobadjanjeModela: OslobadjanjeModela {
        OslobadjanjeModela.iz(podesavanja.oslobadjanjeModela)
    }

    var rezimPrepisa: RezimPrepisa {
        RezimPrepisa.iz(podesavanja.rezimPrepisa)
    }

    func osveziModel() {
        modelPutanja = izabraniModel.preuzet ? izabraniModel.putanja : nil
        if let modelPutanja {
            Putanje.zastitiFajl(modelPutanja)
        }
    }

    var modelSpreman: Bool { modelPutanja != nil }

    var opisModela: String {
        "\(izabraniModel.naziv) · \(izabraniModel.velicinaTekst)"
    }

    func izaberiModel(_ id: String) {
        guard id != podesavanja.model, let model = Modeli.nadji(id) else { return }
        guard !stanje.jeZauzet, !preuzimaModel else {
            postaviInfo("Sačekaj da završi trenutni prepis ili preuzimanje.")
            return
        }

        tajmerOslobadjanja?.invalidate()
        tajmerOslobadjanja = nil
        prepisivac.oslobodi()
        modelUcitan = false
        podesavanja.model = id
        SkladistePodesavanja.sacuvaj(podesavanja)
        osveziModel()

        if model.preuzet {
            postaviInfo("Izabran je model \(model.naziv).")
        } else {
            postaviInfo("Model \(model.naziv) još nije preuzet.")
        }
    }

    func preuzmiModel() {
        guard !preuzimaModel else { return }
        let model = izabraniModel
        guard !model.preuzet else {
            osveziModel()
            return
        }
        preuzimaModel = true
        modelPreuzimanja = model.id
        napredakModela = 0
        preuzimac.pocni(od: model.url, u: model.putanja, velicina: model.velicina)
    }

    func otkaziPreuzimanje() {
        preuzimac.otkazi()
        preuzimaModel = false
        modelPreuzimanja = nil
    }

    func oslobodiMemoriju() {
        tajmerOslobadjanja?.invalidate()
        tajmerOslobadjanja = nil
        prepisivac.oslobodi()
        modelUcitan = false
        postaviInfo("Model je oslobođen iz memorije.")
    }

    func postaviOslobadjanjeModela(_ id: String) {
        let opcija = OslobadjanjeModela.iz(id)
        guard opcija.rawValue != podesavanja.oslobadjanjeModela else { return }
        podesavanja.oslobadjanjeModela = opcija.rawValue
        SkladistePodesavanja.sacuvaj(podesavanja)
        if modelUcitan {
            zakaziOslobadjanje()
        }
    }

    func postaviRezimPrepisa(_ id: String) {
        let rezim = RezimPrepisa.iz(id)
        guard rezim.rawValue != podesavanja.rezimPrepisa else { return }
        podesavanja.rezimPrepisa = rezim.rawValue
        SkladistePodesavanja.sacuvaj(podesavanja)
    }

    // MARK: - Doterivanje

    var provajderDoterivanja: ProvajderDoterivanja {
        ProvajderiDoterivanja.nadji(podesavanja.provajderDoterivanja)
            ?? ProvajderiDoterivanja.podrazumevani
    }

    var modelDoterivanja: String {
        let upisan = podesavanja.modeliDoterivanja[provajderDoterivanja.id]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return upisan.isEmpty ? provajderDoterivanja.model : upisan
    }

    var adresaDoterivanja: String {
        let provajder = provajderDoterivanja
        guard provajder.id == ProvajderiDoterivanja.customId else {
            return provajder.adresa
        }
        let upisana = podesavanja.adresaCustomDoterivanja
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return upisana.isEmpty ? provajder.adresa : upisana
    }

    func postaviModelDoterivanja(_ vrednost: String) {
        let ocisceno = vrednost.trimmingCharacters(in: .whitespacesAndNewlines)
        let provajder = provajderDoterivanja.id
        if ocisceno.isEmpty {
            podesavanja.modeliDoterivanja.removeValue(forKey: provajder)
        } else {
            podesavanja.modeliDoterivanja[provajder] = ocisceno
        }
    }

    func izaberiProvajdera(_ id: String) {
        guard id != podesavanja.provajderDoterivanja,
              let provajder = ProvajderiDoterivanja.nadji(id) else { return }

        sacuvajKljuc(prikaziPoruku: false)
        podesavanja.provajderDoterivanja = provajder.id
        SkladistePodesavanja.sacuvaj(podesavanja)
        kljucDoterivanja = Kljuc.citaj(za: provajder.id) ?? ""
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
        guard modelSpreman else {
            greska = GreskaPrepisaa.modelNijePreuzet.localizedDescription
            izabranTab = 3
            return
        }

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
            zakaziOslobadjanje()
            postaviInfo(izabranaPrecica.jePrekidac
                ? "Snimak je prekratak — pritisni \(nazivPrecice), pa govori."
                : "Snimak je prekratak — drži \(nazivPrecice) dok govoriš.")
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
        zakaziOslobadjanje()
        postaviInfo("Snimak je otkazan.")
    }

    private func pokreniTajmerSekundi() {
        tajmerSekundi?.invalidate()
        tajmerSekundi = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, self.stanje.jeSnimanje else { return }
            let proteklo = Int(Date().timeIntervalSince(self.pocetakSnimanja))
            self.sekunde = proteklo
            // Ne dozvoljavamo neograničen snimak: dugo držanje bi napunilo
            // RAM i whisper bi trošio sve više memorije pri prepisu.
            if proteklo >= Snimac.najduzeSekundi {
                self.zavrsiSnimanje()
                self.postaviInfo("Snimak je ograničen na \(Snimac.najduzeSekundi / 60) minuta.")
            }
        }
    }

    private func zaustaviTajmerSekundi() {
        tajmerSekundi?.invalidate()
        tajmerSekundi = nil
    }

    // MARK: - Prepis

    private func obradi(_ uzorci: [Float], trajanje: Double) {
        guard let putanja = modelPutanja else {
            stanje = .mirno
            zakaziOslobadjanje()
            greska = GreskaPrepisaa.modelNijePreuzet.localizedDescription
            izabranTab = 3
            return
        }
        modelPutanja = putanja

        stanje = .priprema
        tajmerOslobadjanja?.invalidate()
        let jezik = podesavanja.jezik
        let prompt = Recnik.kaoPrompt(recnik)
        let rezim = RezimPrepisa.iz(podesavanja.rezimPrepisa)
        let doteruj = podesavanja.doterivanje
        let provajder = provajderDoterivanja
        let kljuc = kljucDoterivanja.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = modelDoterivanja
        let adresa = adresaDoterivanja

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
                    recnik: prompt,
                    rezim: rezim
                )
                let jezikTeksta = self.prepisivac.jezikZadnjegPrepisa()
                let sredjeno = Tekst.sredi(sirovo)

                // Whisper je završio posao — model može da se oslobodi po
                // izabranom vremenu, čak i dok doterivanje još čeka mrežu.
                DispatchQueue.main.async { self.zakaziOslobadjanje() }

                guard !sredjeno.isEmpty else {
                    DispatchQueue.main.async {
                        self.stanje = .mirno
                        self.postaviInfo("Nisam čuo govor. Probaj bliže mikrofonu.")
                    }
                    return
                }

                if doteruj, !provajder.traziKljuc || !kljuc.isEmpty {
                    Task { [weak self] in
                        guard let self else { return }
                        do {
                            let doteran = try await Doterivac.doteraj(
                                sredjeno,
                                provajder: provajder,
                                kljuc: kljuc,
                                model: model,
                                adresa: adresa,
                                jezik: jezikTeksta
                            )
                            DispatchQueue.main.async {
                                self.dovrsi(
                                    doteran,
                                    trajanje: trajanje,
                                    jezik: jezikTeksta,
                                    napomena: nil
                                )
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.dovrsi(
                                    sredjeno,
                                    trajanje: trajanje,
                                    jezik: jezikTeksta,
                                    napomena: "Doterivanje nije uspelo (\(provajder.naziv)) — ostavljen je sirov prepis."
                                )
                            }
                        }
                    }
                } else {
                    let napomena = doteruj
                        ? "Doterivanje je preskočeno — \(provajder.naziv) ključ nije unet."
                        : nil
                    DispatchQueue.main.async {
                        self.dovrsi(
                            sredjeno,
                            trajanje: trajanje,
                            jezik: jezikTeksta,
                            napomena: napomena
                        )
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.stanje = .mirno
                    // I posle greške model treba da se oslobodi po izabranom
                    // vremenu, umesto da zauvek ostane u RAM-u.
                    self.zakaziOslobadjanje()
                    self.greska = error.localizedDescription
                    self.statistika.dodajNeuspeh(jezik: jezik, model: self.izabraniModel.naziv)
                    StatistikaSkladiste.sacuvaj(self.statistika)
                }
            }
        }
    }

    private func dovrsi(_ tekst: String, trajanje: Double, jezik: String, napomena: String?) {
        poslednjiTekst = tekst
        stanje = .mirno
        if podesavanja.cuvajIstoriju {
            istorija.insert(Zapis(tekst: tekst, trajanje: trajanje, jezik: jezik), at: 0)
            if istorija.count > 200 { istorija = Array(istorija.prefix(200)) }
            IstorijaSkladiste.sacuvaj(istorija)
        }

        statistika.dodaj(
            tekst: tekst,
            trajanje: trajanje,
            jezik: jezik,
            model: izabraniModel.naziv
        )
        StatistikaSkladiste.sacuvaj(statistika)

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

    func obrisiStatistiku() {
        statistika.obrisiSve()
        StatistikaSkladiste.obrisi()
        postaviInfo("Statistika je obrisana.")
    }

    func sacuvajPodesavanja() {
        let novaPrecica = izabranaPrecica
        if novaPrecica != tastatura.precica && stanje.jeSnimanje {
            zavrsiSnimanje()
        }
        SkladistePodesavanja.sacuvaj(podesavanja)
        // Promena prečice ne zahteva ponovno pravljenje event tapa.
        tastatura.precica = novaPrecica
    }

    func sacuvajRecnik() {
        Recnik.sacuvaj(recnik)
    }

    func sacuvajKljuc() {
        sacuvajKljuc(prikaziPoruku: true)
    }

    @discardableResult
    private func sacuvajKljuc(prikaziPoruku: Bool) -> Bool {
        let provajder = provajderDoterivanja
        let kljuc = kljucDoterivanja.trimmingCharacters(in: .whitespacesAndNewlines)
        kljucDoterivanja = kljuc
        let sacuvan = Kljuc.upisi(kljuc, za: provajder.id)
        if !kljuc.isEmpty && !sacuvan {
            greska = "\(provajder.naziv) ključ nije mogao da se sačuva u Keychain-u."
            return false
        }
        guard prikaziPoruku else { return true }
        postaviInfo(kljuc.isEmpty
            ? "\(provajder.naziv) ključ je obrisan."
            : "\(provajder.naziv) ključ je sačuvan u Keychain-u.")
        return true
    }

    func testirajDoterivanje() {
        guard !testiraDoterivanje else { return }

        let provajder = provajderDoterivanja
        let kljuc = kljucDoterivanja.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = modelDoterivanja
        let adresa = adresaDoterivanja

        guard !provajder.traziKljuc || !kljuc.isEmpty else {
            greska = "\(provajder.naziv) API ključ nije unet."
            return
        }

        greska = nil
        testiraDoterivanje = true
        Task { [weak self] in
            do {
                let odgovor = try await Doterivac.doteraj(
                    "Ovo je kratak test. Popravi interpunkciju.",
                    provajder: provajder,
                    kljuc: kljuc,
                    model: model,
                    adresa: adresa,
                    jezik: "sr"
                )
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.testiraDoterivanje = false
                    let kratko = odgovor.count > 80 ? "\(odgovor.prefix(80))…" : odgovor
                    self.postaviInfo("Test je uspeo (\(provajder.naziv)): \(kratko)")
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.testiraDoterivanje = false
                    self.greska = "Test nije uspeo (\(provajder.naziv)): \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Ažuriranja

    var trenutnaVerzija: String { Azuriranja.trenutnaVerzija }

    var azuriranjeDostupno: Bool { azuriranje != nil }

    var dostupnaVerzija: String? { azuriranje?.verzija }

    /// Posle pokretanja odmah pokaži poznato novije izdanje, dok dnevna
    /// provera ne stigne sa svežim podacima (link, zip, napomena).
    private func vratiPoznatoAzuriranje() {
        guard let verzija = SkladisteAzuriranja.zadnjaVerzija,
              Verzija.jeNovija(verzija, od: trenutnaVerzija),
              SkladisteAzuriranja.preskocenaVerzija != verzija else { return }

        let stranica = URL(string: "https://github.com/\(Azuriranja.repozitorij)/releases/tag/v\(verzija)")
            ?? Azuriranja.stranicaIzdanja
        azuriranje = Izdanje(
            tag_name: "v\(verzija)",
            name: nil,
            html_url: stranica,
            assets: []
        )
    }

    /// Prva provera ide par sekundi posle pokretanja, pa na svakih šest sati
    /// proveravamo da li je prošlo dvadeset četiri. Tako se propuštena
    /// provera (spavanje, prekid mreže) nadoknadi bez stalnog saobraćaja.
    private func pokreniProveruAzuriranja() {
        tajmerAzuriranja?.invalidate()
        tajmerAzuriranja = Timer.scheduledTimer(withTimeInterval: 6 * 3600, repeats: true) { [weak self] _ in
            self?.proveriAzuriranjaAkoTreba()
        }
        guard podesavanja.proveravajAzuriranja, SkladisteAzuriranja.trebaProveriti() else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.proveriAzuriranjaAkoTreba()
        }
    }

    private func proveriAzuriranjaAkoTreba() {
        guard podesavanja.proveravajAzuriranja,
              !proveravaAzuriranja,
              SkladisteAzuriranja.trebaProveriti() else { return }
        proveriAzuriranja(rucno: false)
    }

    func proveriAzuriranja(rucno: Bool = false) {
        guard !proveravaAzuriranja else { return }
        proveravaAzuriranja = true
        if rucno {
            greska = nil
            // Ručna provera je nova odluka — i preskočena verzija se ponovo nudi.
            SkladisteAzuriranja.preskocenaVerzija = nil
        }

        Azuriranja.proveri { [weak self] rezultat in
            DispatchQueue.main.async {
                guard let self else { return }
                self.proveravaAzuriranja = false
                switch rezultat {
                case .success(let izdanje):
                    self.obradiIzdanje(izdanje, rucno: rucno)
                case .failure(let error):
                    if rucno {
                        self.greska = "Provera ažuriranja nije uspela: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func obradiIzdanje(_ izdanje: Izdanje, rucno: Bool) {
        let sada = Date()
        SkladisteAzuriranja.zadnjaProvera = sada
        SkladisteAzuriranja.zadnjaVerzija = izdanje.verzija
        zadnjaProveraAzuriranja = sada

        let novija = Verzija.jeNovija(izdanje.verzija, od: trenutnaVerzija)
        let preskocena = SkladisteAzuriranja.preskocenaVerzija == izdanje.verzija

        if novija, !preskocena {
            azuriranje = izdanje
            sakrijTrakuAzuriranja = false
            if !rucno, SkladisteAzuriranja.obavestenaVerzija != izdanje.verzija {
                SkladisteAzuriranja.obavestenaVerzija = izdanje.verzija
                ObavestenjaAzuriranja.prikazi(
                    verzija: izdanje.verzija,
                    adresa: izdanje.bezbednaAdresaPreuzimanja
                )
            }
            if rucno {
                postaviInfo("Dostupna je verzija \(izdanje.verzija).")
            }
        } else {
            azuriranje = nil
            if rucno {
                postaviInfo("Diktator je ažuran (verzija \(trenutnaVerzija)).")
            }
        }
    }

    func otvoriAzuriranje() {
        guard let izdanje = azuriranje else { return }
        NSWorkspace.shared.open(izdanje.bezbednaAdresaPreuzimanja)
        sakrijTrakuAzuriranja = true
    }

    func otvoriStranicuIzdanja() {
        NSWorkspace.shared.open(azuriranje?.bezbednaStranicaIzdanja ?? Azuriranja.stranicaIzdanja)
    }

    func kasnijeAzuriranje() {
        sakrijTrakuAzuriranja = true
    }

    func preskociAzuriranje() {
        guard let izdanje = azuriranje else { return }
        SkladisteAzuriranja.preskocenaVerzija = izdanje.verzija
        azuriranje = nil
        sakrijTrakuAzuriranja = false
        postaviInfo("Neću više podsećati na verziju \(izdanje.verzija).")
    }

    // MARK: - Pomoćno

    private func zakaziOslobadjanje() {
        tajmerOslobadjanja?.invalidate()
        tajmerOslobadjanja = nil
        guard let sekunde = oslobadjanjeModela.sekunde else { return }
        tajmerOslobadjanja = Timer.scheduledTimer(withTimeInterval: sekunde, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.tajmerOslobadjanja = nil
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
