// Globalna precica: drzi se Fn i govori. Radi i kada Pitchi nije u fokusu,
// ali trazi dozvolu "Nadzor unosa" (Input Monitoring).
import ApplicationServices
import Foundation

final class Tastatura {
    var naPritisak: (() -> Void)?
    var naOtpust: (() -> Void)?

    private var dodir: CFMachPort?
    private var izvor: CFRunLoopSource?
    private var fnPritisnut = false

    static var dozvola: Bool { CGPreflightListenEventAccess() }

    @discardableResult
    func pokreni() -> Bool {
        if dodir != nil { return true }
        let maska = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        guard let dodir = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: maska,
            callback: { _, tip, dogadjaj, podaci in
                guard let podaci else { return Unmanaged.passUnretained(dogadjaj) }
                let tastatura = Unmanaged<Tastatura>.fromOpaque(podaci).takeUnretainedValue()
                tastatura.obradi(tip: tip, dogadjaj: dogadjaj)
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
        fnPritisnut = false
    }

    private func obradi(tip: CGEventType, dogadjaj: CGEvent) {
        if tip == .tapDisabledByTimeout || tip == .tapDisabledByUserInput {
            if let dodir { CGEvent.tapEnable(tap: dodir, enable: true) }
            return
        }
        guard tip == .flagsChanged else { return }

        // 63 = Fn
        let kod = dogadjaj.getIntegerValueField(.keyboardEventKeycode)
        guard kod == 63 else { return }

        let sada = dogadjaj.flags.contains(.maskSecondaryFn)
        if sada && !fnPritisnut {
            fnPritisnut = true
            DispatchQueue.main.async { [weak self] in self?.naPritisak?() }
        } else if !sada && fnPritisnut {
            fnPritisnut = false
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
