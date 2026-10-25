// Globalna precica: drzi se izabrani taster i govori. Radi i kada Diktator
// nije u fokusu, ali trazi dozvolu "Nadzor unosa" (Input Monitoring).
import ApplicationServices
import Foundation

final class Tastatura {
    var naPritisak: (() -> Void)?
    var naOtpust: (() -> Void)?
    /// Za prečice-prekidače (Fn + Space): svaki pritisak menja stanje.
    var naPrekidac: (() -> Void)?

    /// Taster se moze promeniti u Podesavanjima; tap ostaje isti.
    var precica: Precica = .fn {
        didSet {
            guard precica != oldValue else { return }
            progutajSpace = false
            // Ako je stari taster još pritisnut, završi snimak da ne ostane
            // zaglavljen kada se prečica promeni usred snimanja.
            if pritisnut {
                pritisnut = false
                DispatchQueue.main.async { [weak self] in self?.naOtpust?() }
            }
        }
    }

    private var dodir: CFMachPort?
    private var izvor: CFRunLoopSource?
    private var pritisnut = false
    /// Space iz Fn + Space je već potrošen; njegov keyUp se takođe proguta.
    private var progutajSpace = false

    static var dozvola: Bool { CGPreflightListenEventAccess() }

    @discardableResult
    func pokreni() -> Bool {
        if dodir != nil { return true }
        let maska = CGEventMask(
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue)
        )
        guard let dodir = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: maska,
            callback: { _, tip, dogadjaj, podaci in
                guard let podaci else { return Unmanaged.passUnretained(dogadjaj) }
                let tastatura = Unmanaged<Tastatura>.fromOpaque(podaci).takeUnretainedValue()
                if tastatura.obradi(tip: tip, dogadjaj: dogadjaj) {
                    return nil
                }
                return Unmanaged.passUnretained(dogadjaj)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        self.dodir = dodir
        let izvor = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, dodir, 0)
        self.izvor = izvor
        CFRunLoopAddSource(CFRunLoopGetMain(), izvor, .commonModes)
        CGEvent.tapEnable(tap: dodir, enable: true)
        return true
    }

    func zaustavi() {
        if let dodir { CGEvent.tapEnable(tap: dodir, enable: false) }
        if let izvor { CFRunLoopRemoveSource(CFRunLoopGetMain(), izvor, .commonModes) }
        dodir = nil
        izvor = nil
        pritisnut = false
        progutajSpace = false
    }

    /// Vraća `true` kada događaj treba progutati (Fn + Space ne sme da
    /// upiše razmak u aktivnu aplikaciju).
    @discardableResult
    private func obradi(tip: CGEventType, dogadjaj: CGEvent) -> Bool {
        if tip == .tapDisabledByTimeout || tip == .tapDisabledByUserInput {
            if let dodir { CGEvent.tapEnable(tap: dodir, enable: true) }
            return false
        }

        let kod = dogadjaj.getIntegerValueField(.keyboardEventKeycode)
        guard kod == precica.kod else { return false }

        if precica.jePrekidac {
            return obradiPrekidac(tip: tip, dogadjaj: dogadjaj)
        }

        if precica.jeModifikator {
            guard tip == .flagsChanged else { return false }
            let sada: Bool
            if precica == .fn {
                sada = dogadjaj.flags.contains(.maskSecondaryFn)
            } else {
                sada = CGEventSource.keyState(
                    .combinedSessionState,
                    key: CGKeyCode(precica.kod)
                )
            }
            postaviPritisnut(sada)
        } else {
            guard tip == .keyDown || tip == .keyUp else { return false }
            // Dok se taster drži, macOS šalje ponovljene keyDown događaje.
            if tip == .keyDown && dogadjaj.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
                return false
            }
            postaviPritisnut(tip == .keyDown)
        }
        return false
    }

    /// Fn + Space: svaki čist pritisak menja stanje snimanja. Space se
    /// proglašava potrošenim da se ne bi upisao u aplikaciju u kojoj kucamo.
    private func obradiPrekidac(tip: CGEventType, dogadjaj: CGEvent) -> Bool {
        if tip == .keyDown {
            let zabranjeni: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate]
            guard dogadjaj.flags.contains(.maskSecondaryFn),
                  dogadjaj.flags.isDisjoint(with: zabranjeni) else {
                return false
            }
            if dogadjaj.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
                return progutajSpace
            }
            progutajSpace = true
            DispatchQueue.main.async { [weak self] in self?.naPrekidac?() }
            return true
        }

        if tip == .keyUp && progutajSpace {
            progutajSpace = false
            return true
        }
        return false
    }

    private func postaviPritisnut(_ sada: Bool) {
        if sada && !pritisnut {
            pritisnut = true
            DispatchQueue.main.async { [weak self] in self?.naPritisak?() }
        } else if !sada && pritisnut {
            pritisnut = false
            DispatchQueue.main.async { [weak self] in self?.naOtpust?() }
        }
    }
}

enum Lepak {
    /// Salje Cmd+V aktivnoj aplikaciji. Trazi dozvolu "Pristupacnost".
    static func zalepi() {
        let izvor = CGEventSource(stateID: .combinedSessionState)
        guard let dole = CGEvent(keyboardEventSource: izvor, virtualKey: 0x09, keyDown: true),
              let gore = CGEvent(keyboardEventSource: izvor, virtualKey: 0x09, keyDown: false) else {
            return
        }
        dole.flags = .maskCommand
        gore.flags = .maskCommand
        dole.post(tap: .cghidEventTap)
        gore.post(tap: .cghidEventTap)
    }

    static var dozvola: Bool { AXIsProcessTrusted() }

    static func zatrazDozvolu() {
        let opcije = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(opcije as CFDictionary)
    }
}
