// Crta ikonicu Diktatora (gradijent + mikrofon) i pravi .icns.
// Pokretanje: swift napravi-ikonu.swift
import AppKit

let velicina = 1024.0
let slika = NSImage(size: NSSize(width: velicina, height: velicina))
slika.lockFocus()

let ceo = NSRect(x: 0, y: 0, width: velicina, height: velicina)
NSColor.clear.setFill()
ceo.fill()

// Zaobljena podloga sa marginom, kao macOS ikone.
let okvir = ceo.insetBy(dx: 62, dy: 62)
let podloga = NSBezierPath(roundedRect: okvir, xRadius: 210, yRadius: 210)

let gornja = NSColor(calibratedRed: 0.46, green: 0.36, blue: 0.98, alpha: 1)
let donja = NSColor(calibratedRed: 0.27, green: 0.20, blue: 0.78, alpha: 1)
NSGradient(starting: gornja, ending: donja)?.draw(in: podloga, angle: -70)

// Blagi sjaj u gornjem delu.
let sjaj = NSBezierPath(ovalIn: NSRect(x: 120, y: 540, width: 800, height: 430))
NSColor.white.withAlphaComponent(0.10).setFill()
sjaj.fill()

// Mikrofon: telo, luk, drzac i osnova.
NSColor.white.setFill()
NSColor.white.setStroke()

let telo = NSBezierPath(roundedRect: NSRect(x: 422, y: 470, width: 180, height: 300), xRadius: 90, yRadius: 90)
telo.fill()

let luk = NSBezierPath()
luk.appendArc(withCenter: NSPoint(x: 512, y: 520), radius: 168, startAngle: 200, endAngle: 340)
luk.lineWidth = 40
luk.lineCapStyle = .round
luk.stroke()

let drzac = NSBezierPath()
drzac.move(to: NSPoint(x: 512, y: 352))
drzac.line(to: NSPoint(x: 512, y: 292))
drzac.lineWidth = 40
drzac.lineCapStyle = .round
drzac.stroke()

let osnova = NSBezierPath()
osnova.move(to: NSPoint(x: 412, y: 292))
osnova.line(to: NSPoint(x: 612, y: 292))
osnova.lineWidth = 40
osnova.lineCapStyle = .round
osnova.stroke()

// Dva mala talasa levo i desno, da se vidi da je dikiranje.
for (strana, visina) in [(-1.0, 220.0), (1.0, 220.0), (-1.0, 320.0), (1.0, 320.0)] {
    let x = 512.0 + strana * 300.0
    let talas = NSBezierPath()
    talas.move(to: NSPoint(x: x, y: 512 - visina / 2))
    talas.line(to: NSPoint(x: x, y: 512 + visina / 2))
    talas.lineWidth = 26
    talas.lineCapStyle = .round
    NSColor.white.withAlphaComponent(visina > 250 ? 0.55 : 0.85).setStroke()
    talas.stroke()
}

slika.unlockFocus()

guard let tiff = slika.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("ne mogu da napravim ikonicu")
}

let izlaz = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Resursi")
try? FileManager.default.createDirectory(at: izlaz, withIntermediateDirectories: true)
let pngURL = izlaz.appendingPathComponent("AppIcon-1024.png")
try png.write(to: pngURL)
print(pngURL.path)
