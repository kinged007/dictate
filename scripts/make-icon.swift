// Generates the 1024x1024 app icon source PNG for Dictate.
// Usage: swift scripts/make-icon.swift
// Output: Resources/AppIcon-Source.png
import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let canvas = NSRect(x: 0, y: 0, width: 1024, height: 1024)

// Background: rounded rect with a vertical indigo -> blue gradient.
let bgPath = NSBezierPath(roundedRect: canvas.insetBy(dx: 40, dy: 40), xRadius: 220, yRadius: 220)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.36, green: 0.36, blue: 0.92, alpha: 1.0), // #5B5CEB
    NSColor(calibratedRed: 0.23, green: 0.55, blue: 0.95, alpha: 1.0)  // #3B8CF2
])!
gradient.draw(in: bgPath, angle: -90)

// White microphone.
NSColor.white.setFill()
NSColor.white.setStroke()

// 1. Pill body.
let body = NSBezierPath(roundedRect: NSRect(x: 372, y: 170, width: 280, height: 390), xRadius: 140, yRadius: 140)
body.fill()

// 2. Grill arc (lower half-circle under the pill).
let arc = NSBezierPath()
arc.appendArc(withCenter: NSPoint(x: 512, y: 560), radius: 135, startAngle: 180, endAngle: 360, clockwise: false)
arc.lineWidth = 46
arc.lineCapStyle = .round
arc.stroke()

// 3. Stem.
let stem = NSBezierPath(roundedRect: NSRect(x: 492, y: 560, width: 40, height: 110), xRadius: 20, yRadius: 20)
stem.fill()

// 4. Base.
let base = NSBezierPath(roundedRect: NSRect(x: 402, y: 660, width: 220, height: 52), xRadius: 26, yRadius: 26)
base.fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Could not render icon")
}

let outURL = URL(fileURLWithPath: "Resources/AppIcon-Source.png")
try! png.write(to: outURL)
print("Wrote \(outURL.path)")
