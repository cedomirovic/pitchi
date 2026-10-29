// Ulaz u aplikaciju: menu bar ikona, glavni prozor i mali HUD tokom snimanja.
import AppKit
import AVFoundation
import Combine
import SwiftUI
import UserNotifications

@main
struct DiktatorMain {
    // NSApplication.delegate je slaba referenca — bez ovoga bi delegat nestao
    // pre nego što stigne da napravi prozor i menu bar.
    private static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared

        if CommandLine.arguments.contains("--slika") {
            Task { @MainActor in
                nacrtajSlike()
                exit(0)
            }
            app.setActivationPolicy(.accessory)
            app.run()
            return
        }

        if CommandLine.arguments.contains("--test-whisper") {
            app.setActivationPolicy(.prohibited)
            testWhisper()
            exit(0)
        }

        // Razvojna pomoć: ispiši stvarne macOS dozvole bez otvaranja prozora.
        if CommandLine.arguments.contains("--dozvole") {
            app.setActivationPolicy(.prohibited)
            print("mikrofon: \(Snimac.dozvola == .authorized ? "dozvoljen" : "nije dozvoljen")")
            print("pristupacnost: \(Lepak.dozvola ? "dozvoljena" : "nije dozvoljena")")
            print("nadzor unosa: \(Tastatura.dozvola ? "dozvoljen" : "nije dozvoljen")")
            exit(0)
        }

        // Razvojna pomoć: uključi pokretanje pri prijavi bez otvaranja prozora.
        if CommandLine.arguments.contains("--prijava") {
            app.setActivationPolicy(.prohibited)
            do {
                try Prijava.postavi(true)
                if Prijava.zahtevaOdobrenje {
                    print("prijava: čeka odobrenje u System Settings → General → Login Items")
                } else {
                    print("prijava: \(Prijava.ukljucena ? "uključena" : "isključena")")
                }
            } catch {
                print("GRESKA: \(error.localizedDescription)")
            }
            exit(0)
        }

        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

    /// Pomoćna opcija za razvoj: nacrta sve tabove u PNG bez snimanja ekrana.
    @MainActor
    private static func nacrtajSlike() {
        let stanje = AppStanje()
        stanje.demoStanje = true

        // Demo podešavanja: Fn + Space, Turbo i brzi režim, sve uključeno —
        // tako slike prikazuju preporučeno stanje, a ne stanje ove mašine.
        var demo = Podesavanja()
        demo.precica = Precica.fnSpace.rawValue
        demo.model = Modeli.brzi.id
        demo.brziRezim = true
        demo.oslobadjanjeModela = OslobadjanjeModela.trideset.rawValue
        demo.unapredUcitajModel = true
        stanje.podesavanja = demo
        stanje.osveziModel()
        stanje.prijavaUkljucena = true
        stanje.recnik = "Nemanja Čedomirović, Tamara Pandža, Diktator, whisper.cpp, SwiftUI, GitHub, Beograd"
        stanje.zadnjaProveraAzuriranja = Date().addingTimeInterval(-7200)

        stanje.poslednjiTekst = "Danas je lepo vreme u Beogradu. Sastanak je u pet sati, u kancelariji."
        stanje.istorija = [
            Zapis(tekst: "Pošalji Nemanji ponudu do petka, pa da vidimo.", datum: Date().addingTimeInterval(-3600), trajanje: 4.2),
            Zapis(tekst: "Podseti me da zovem Tamaru u vezi ugovora.", datum: Date().addingTimeInterval(-7200), trajanje: 3.1),
        ]
        stanje.dozvole = Dozvole(mikrofon: true, pristupacnost: true, nadzorUnosa: true)
        stanje.precicaRadi = true
        stanje.statistika = Statistika.primer()

        // Razvojna provera: nacrtaj traku i karticu ažuriranja bez mreže.
        if ProcessInfo.processInfo.environment["DIKTATOR_SLIKA_AZURIRANJE"] != nil {
            stanje.azuriranje = Izdanje(
                tag_name: "v1.0.0",
                name: "Diktator 1.0.0",
                body: """
                ## Rečnik

                - Rečnik se sada seče između pojmova, bez pola reči.
                - Brojač znakova i upozorenje kada spisak pređe 600 znakova.
                - Tačka više ne razdvaja „whisper.cpp“ i slične pojmove.
                """,
                html_url: URL(string: "https://github.com/cedomirovic/pitchi/releases/tag/v1.0.0")!,
                assets: [
                    Izdanje.Fajl(
                        name: "Diktator-1.0.0-macOS-arm64.zip",
                        browser_download_url: URL(string: "https://github.com/cedomirovic/pitchi/releases/download/v1.0.0/Diktator-1.0.0-macOS-arm64.zip")!
                    )
                ]
            )
            stanje.zadnjaProveraAzuriranja = Date()
        }

        let prozor = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        prozor.contentView = NSHostingView(rootView: ContentView().environmentObject(stanje))
        prozor.setFrameOrigin(NSPoint(x: 60, y: 60))
        prozor.orderFrontRegardless()

        for tab in 0...4 {
            stanje.izabranTab = tab
            RunLoop.main.run(until: Date().addingTimeInterval(0.8))
            guard let pogled = prozor.contentView else { continue }
            pogled.layoutSubtreeIfNeeded()
            guard let rep = pogled.bitmapImageRepForCachingDisplay(in: pogled.bounds) else { continue }
            pogled.cacheDisplay(in: pogled.bounds, to: rep)
            guard let png = rep.representation(using: .png, properties: [:]) else { continue }
            let putanja = "/tmp/diktator-tab\(tab).png"
            try? png.write(to: URL(fileURLWithPath: putanja))
            print(putanja)
        }
        prozor.orderOut(nil)
    }

    /// Pomoćna opcija za razvoj: prepiše /tmp/sr.wav kroz isti kod koji koristi aplikacija.
    private static func testWhisper() {
        if !CommandLine.arguments.contains("--log") {
            Prepisivac.utisajLog()
        }
        let argumenti = CommandLine.arguments
        let model: PonudaModela
        if let indeksModela = argumenti.firstIndex(of: "--model"),
           indeksModela + 1 < argumenti.count,
           let izabran = Modeli.nadji(argumenti[indeksModela + 1]),
           izabran.preuzet {
            model = izabran
        } else if let postoji = Modeli.nadjiPostojeci() {
            model = postoji
        } else {
            print("GRESKA: nema modela")
            return
        }
        let indeks = argumenti.firstIndex(of: "--test-whisper") ?? 0
        let sledeci = indeks + 1 < argumenti.count ? argumenti[indeks + 1] : nil
        let putanja = (sledeci?.hasPrefix("--") == false ? sledeci : nil) ?? "/tmp/sr.wav"
        let fajlURL = URL(fileURLWithPath: putanja)
        do {
            let fajl = try AVAudioFile(
                forReading: fajlURL,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )
            let format = fajl.processingFormat
            guard let bafer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(fajl.length)
            ) else {
                print("GRESKA: bafer")
                return
            }
            try fajl.read(into: bafer)
            guard let kanal = bafer.floatChannelData?[0] else {
                print("GRESKA: nema float podataka")
                return
            }
            let uzorci = Array(UnsafeBufferPointer(start: kanal, count: Int(bafer.frameLength)))

            let prepisivac = Prepisivac()
            let pocetak = Date()
            try prepisivac.ucitaj(putanja: model.putanja.path)
            let ucitan = Date()
            let rezim: RezimPrepisa = CommandLine.arguments.contains("--stedljivo")
                ? .stedljivo : .kvalitet
            let sirovo = try prepisivac.prepisi(
                uzorci: uzorci,
                jezik: "auto",
                recnik: Recnik.kaoPrompt(Recnik.ucitaj()),
                rezim: rezim
            )
            let kraj = Date()
            print("MODEL:", model.putanja.path)
            print("REZIM:      \(rezim.naziv)")
            print("JEZIK:      \(prepisivac.jezikZadnjegPrepisa())")
            print("UCITAVANJE: \(String(format: "%.2f", ucitan.timeIntervalSince(pocetak))) s")
            print("PREPIS:     \(String(format: "%.2f", kraj.timeIntervalSince(ucitan))) s")
            print("SIROVO:     \(sirovo)")
            print("SREDJENO:   \(Tekst.sredi(sirovo))")

            if CommandLine.arguments.contains("--zadrzi") {
                print("PID:        \(ProcessInfo.processInfo.processIdentifier)")
                Thread.sleep(forTimeInterval: 20)
            }

            prepisivac.oslobodiSada()
        } catch {
            print("GRESKA: \(error.localizedDescription)")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let stanje = AppStanje()
    private var statusItem: NSStatusItem?
    private var window: NSWindow?
    private var hud: NSPanel?
    private var stavkaSnimi: NSMenuItem?
    private var stavkaAzuriranja: NSMenuItem?
    private var pretplate = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = DelegateObavestenja.zajednicki
        postaviGlavniMeni()
        postaviStatusItem()
        postaviHud()
        pratiStanje()
        prikaziProzor()
        // Brzi režim može unapred da učita model; ako je isključen, ovo ne radi ništa.
        stanje.pripremiModel()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stanje.prepisivac.oslobodiSada()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            prikaziProzor()
        }
        return true
    }

    // MARK: - Menu bar

    private func postaviGlavniMeni() {
        let glavni = NSMenu()

        let aplikacijaStavka = NSMenuItem()
        glavni.addItem(aplikacijaStavka)
        let aplikacijaMeni = NSMenu()
        aplikacijaMeni.addItem(
            withTitle: "O aplikaciji Diktator",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        aplikacijaMeni.addItem(.separator())
        aplikacijaMeni.addItem(
            withTitle: "Sakrij Diktator",
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )
        aplikacijaMeni.addItem(.separator())
        aplikacijaMeni.addItem(
            withTitle: "Izađi iz Diktatora",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        aplikacijaStavka.submenu = aplikacijaMeni

        let izmenaStavka = NSMenuItem()
        glavni.addItem(izmenaStavka)
        let izmena = NSMenu(title: "Izmena")
        izmena.addItem(withTitle: "Poništi", action: Selector(("undo:")), keyEquivalent: "z")
        izmena.addItem(withTitle: "Ponovi", action: Selector(("redo:")), keyEquivalent: "Z")
        izmena.addItem(.separator())
        izmena.addItem(withTitle: "Iseci", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        izmena.addItem(withTitle: "Kopiraj", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        izmena.addItem(withTitle: "Zalepi", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        izmena.addItem(withTitle: "Obriši", action: Selector(("delete:")), keyEquivalent: "")
        izmena.addItem(withTitle: "Označi sve", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        izmenaStavka.submenu = izmena

        NSApp.mainMenu = glavni
    }

    private func postaviStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let dugme = item.button {
            dugme.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Diktator")
            dugme.image?.isTemplate = true
            dugme.toolTip = stanje.izabranaPrecica.kratkoUputstvo
        }

        let meni = NSMenu()

        let pokazi = NSMenuItem(title: "Prikaži Diktator", action: #selector(prikaziProzor), keyEquivalent: "o")
        pokazi.target = self
        meni.addItem(pokazi)

        let snimi = NSMenuItem(title: "Snimi sada", action: #selector(prebaciSnimanje), keyEquivalent: "")
        snimi.target = self
        meni.addItem(snimi)
        stavkaSnimi = snimi

        let kopiraj = NSMenuItem(
            title: "Poslednji tekst u klipbord",
            action: #selector(kopirajPoslednji),
            keyEquivalent: ""
        )
        kopiraj.target = self
        meni.addItem(kopiraj)

        meni.addItem(.separator())

        let azuriranja = NSMenuItem(
            title: "Proveri ažuriranja…",
            action: #selector(proveriAzuriranja),
            keyEquivalent: ""
        )
        azuriranja.target = self
        meni.addItem(azuriranja)
        stavkaAzuriranja = azuriranja

        let podesavanja = NSMenuItem(title: "Podešavanja…", action: #selector(otvoriPodesavanja), keyEquivalent: ",")
        podesavanja.target = self
        meni.addItem(podesavanja)

        let dozvole = NSMenuItem(title: "Dozvole…", action: #selector(otvoriDozvole), keyEquivalent: "")
        dozvole.target = self
        meni.addItem(dozvole)

        meni.addItem(.separator())

        let izadji = NSMenuItem(title: "Izađi", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        meni.addItem(izadji)

        item.menu = meni
        statusItem = item
    }

    private func pratiStanje() {
        stanje.$stanje
            .receive(on: RunLoop.main)
            .sink { [weak self] novo in
                self?.osveziIkonu(novo)
                self?.osveziHud(novo)
            }
            .store(in: &pretplate)

        stanje.$sekunde
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.osveziIkonu(self?.stanje.stanje ?? .mirno) }
            .store(in: &pretplate)

        stanje.$azuriranje
            .receive(on: RunLoop.main)
            .sink { [weak self] izdanje in
                self?.stavkaAzuriranja?.title = izdanje.map { "Ažuriranje \($0.verzija)…" }
                    ?? "Proveri ažuriranja…"
            }
            .store(in: &pretplate)

        stanje.$podesavanja
            .receive(on: RunLoop.main)
            .sink { [weak self] podesavanja in
                let precica = Precica.iz(podesavanja.precica)
                self?.statusItem?.button?.toolTip = precica.kratkoUputstvo
            }
            .store(in: &pretplate)
    }

    private func osveziIkonu(_ stanje: StanjeAplikacije) {
        let ime: String
        switch stanje {
        case .mirno: ime = "mic.fill"
        case .snima: ime = "waveform"
        case .priprema, .prepisuje: ime = "hourglass"
        case .greska: ime = "exclamationmark.triangle.fill"
        }
        statusItem?.button?.image = NSImage(systemSymbolName: ime, accessibilityDescription: "Diktator")
        statusItem?.button?.image?.isTemplate = true

        let naslov: String
        if stanje.jeSnimanje {
            let sek = self.stanje.sekunde
            naslov = String(format: "Zaustavi snimanje (%d:%02d)", sek / 60, sek % 60)
        } else {
            naslov = "Snimi sada"
        }
        stavkaSnimi?.title = naslov
    }

    // MARK: - Prozor

    @objc func prikaziProzor() {
        if window == nil {
            let pogled = ContentView().environmentObject(stanje)
            let prozor = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 820, height: 740),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            prozor.title = "Diktator"
            prozor.titlebarAppearsTransparent = true
            prozor.titleVisibility = .hidden
            prozor.contentView = NSHostingView(rootView: pogled)
            prozor.contentMinSize = NSSize(width: 760, height: 640)
            prozor.isReleasedWhenClosed = false
            prozor.tabbingMode = .disallowed
            prozor.center()
            window = prozor
        }
        window?.makeKeyAndOrderFront(nil)
        window?.deminiaturize(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - HUD

    private func postaviHud() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 102),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.ignoresMouseEvents = true
        panel.contentView = NSHostingView(rootView: HudPogled().environmentObject(stanje))
        panel.alphaValue = 0
        hud = panel
        pozicionirajHud()
    }

    private func pozicionirajHud() {
        guard let hud, let ekran = NSScreen.main else { return }
        let okvir = ekran.visibleFrame
        hud.setFrameOrigin(NSPoint(x: okvir.midX - 170, y: okvir.minY + 80))
    }

    private func osveziHud(_ stanje: StanjeAplikacije) {
        guard let hud else { return }
        pozicionirajHud()

        let treba = stanje.jeSnimanje || stanje.jeZauzet
        if treba {
            if !hud.isVisible {
                hud.alphaValue = 0
                hud.orderFrontRegardless()
            }
            NSAnimationContext.runAnimationGroup { kontekst in
                kontekst.duration = 0.15
                hud.animator().alphaValue = 1
            }
        } else {
            NSAnimationContext.runAnimationGroup { kontekst in
                kontekst.duration = 0.2
                hud.animator().alphaValue = 0
            } completionHandler: {
                if !self.stanje.stanje.jeSnimanje && !self.stanje.stanje.jeZauzet {
                    hud.orderOut(nil)
                }
            }
        }
    }

    // MARK: - Akcije iz menija

    @objc private func prebaciSnimanje() {
        stanje.prebaciSnimanje()
    }

    @objc private func kopirajPoslednji() {
        guard !stanje.poslednjiTekst.isEmpty else {
            stanje.postaviInfo("Još nema prepisa.")
            return
        }
        stanje.kopiraj(stanje.poslednjiTekst)
    }

    @objc private func otvoriPodesavanja() {
        stanje.izabranTab = 3
        prikaziProzor()
    }

    @objc private func proveriAzuriranja() {
        stanje.izabranTab = 3
        prikaziProzor()
        if stanje.azuriranje == nil {
            stanje.proveriAzuriranja(rucno: true)
        }
    }

    @objc private func otvoriDozvole() {
        stanje.izabranTab = 3
        prikaziProzor()
    }
}
