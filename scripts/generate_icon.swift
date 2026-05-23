#!/usr/bin/env swift
// Render Resources/AppIcon.icns: a sprinting cat over a rounded gradient tile.
// Generates the standard iconset sizes then runs `iconutil --convert icns`.

import AppKit

let sizes = [16, 32, 64, 128, 256, 512, 1024]
let outDir = URL(fileURLWithPath: "Resources/AppIcon.iconset")
try? FileManager.default.removeItem(at: outDir)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func render(size: Int) -> NSImage {
    let s = CGFloat(size)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }

    // Rounded tile background — purple → indigo gradient
    let cornerRadius = s * 0.225
    let tile = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                      cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(tile); ctx.clip()
    let colors = [
        NSColor(calibratedRed: 0.42, green: 0.36, blue: 0.95, alpha: 1).cgColor,
        NSColor(calibratedRed: 0.20, green: 0.18, blue: 0.55, alpha: 1).cgColor
    ] as CFArray
    let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: 0, y: s),
                           end: CGPoint(x: s, y: 0),
                           options: [])

    // Sparkline behind the cat
    NSColor.white.withAlphaComponent(0.18).setStroke()
    let spark = NSBezierPath()
    spark.lineWidth = s * 0.012
    let baseY = s * 0.28
    let step = s / 24
    var x: CGFloat = 0
    spark.move(to: NSPoint(x: x, y: baseY))
    let bars: [CGFloat] = [0.10, 0.18, 0.12, 0.22, 0.30, 0.18, 0.45, 0.35, 0.55, 0.40, 0.60,
                           0.50, 0.70, 0.55, 0.78, 0.62, 0.85, 0.70, 0.92, 0.78, 0.95, 0.82, 0.88, 0.72]
    for h in bars {
        x += step
        spark.line(to: NSPoint(x: x, y: baseY + h * s * 0.25))
    }
    spark.stroke()

    // Cat silhouette — white, centered
    NSColor.white.setFill()
    let centerX = s / 2, centerY = s * 0.54
    let scale = s / 44
    func P(_ px: CGFloat, _ py: CGFloat) -> NSPoint {
        NSPoint(x: centerX + (px - 22) * scale, y: centerY + (py - 11) * scale)
    }

    // body
    let body = NSBezierPath(roundedRect: NSRect(x: P(8, 8).x, y: P(8, 8).y,
                                                width: 22 * scale, height: 8 * scale),
                            xRadius: 4 * scale, yRadius: 4 * scale)
    body.fill()
    // head
    NSBezierPath(ovalIn: NSRect(x: P(26, 11).x, y: P(26, 11).y, width: 10 * scale, height: 9 * scale)).fill()
    // ears
    let earL = NSBezierPath()
    earL.move(to: P(27, 19)); earL.line(to: P(29, 23)); earL.line(to: P(31, 19)); earL.close(); earL.fill()
    let earR = NSBezierPath()
    earR.move(to: P(31, 19)); earR.line(to: P(33, 22)); earR.line(to: P(35, 19)); earR.close(); earR.fill()
    // tail (curled up)
    let tail = NSBezierPath()
    tail.move(to: P(8, 13))
    tail.curve(to: P(2, 22),
               controlPoint1: P(4, 14),
               controlPoint2: P(0, 18))
    tail.lineWidth = 2.5 * scale; tail.lineCapStyle = .round; tail.stroke()
    // legs — mid-stride
    NSBezierPath(rect: NSRect(x: P(11, 3).x, y: P(11, 3).y, width: 3 * scale, height: 6 * scale)).fill()
    NSBezierPath(rect: NSRect(x: P(15, 3).x, y: P(15, 3).y, width: 3 * scale, height: 6 * scale)).fill()
    NSBezierPath(rect: NSRect(x: P(20, 3).x, y: P(20, 3).y, width: 3 * scale, height: 6 * scale)).fill()
    NSBezierPath(rect: NSRect(x: P(24, 3).x, y: P(24, 3).y, width: 3 * scale, height: 6 * scale)).fill()
    // eye knockout
    NSGraphicsContext.current?.compositingOperation = .destinationOut
    NSBezierPath(ovalIn: NSRect(x: P(32, 16).x, y: P(32, 16).y, width: 1.6 * scale, height: 1.6 * scale)).fill()
    NSGraphicsContext.current?.compositingOperation = .sourceOver

    img.unlockFocus()
    return img
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "png", code: 0)
    }
    try png.write(to: url)
}

for px in sizes {
    let img = render(size: px)
    try writePNG(img, to: outDir.appendingPathComponent("icon_\(px)x\(px).png"))
    if px <= 512 {
        let img2x = render(size: px * 2)
        try writePNG(img2x, to: outDir.appendingPathComponent("icon_\(px)x\(px)@2x.png"))
    }
}

// Convert to .icns
let task = Process()
task.launchPath = "/usr/bin/iconutil"
task.arguments = ["--convert", "icns", "--output", "Resources/AppIcon.icns", outDir.path]
try task.run()
task.waitUntilExit()
print("iconutil exit: \(task.terminationStatus)")
