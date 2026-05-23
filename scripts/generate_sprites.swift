#!/usr/bin/env swift
// Procedurally render sprite frames for each bundled theme.
// Output: Resources/Themes/<name>/frame_NN.png
// All art is original — MIT-licensed alongside the rest of the repo.

import AppKit

let size = NSSize(width: 44, height: 22) // 2x menu-bar height
let frameCount = 5

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "png", code: 0)
    }
    try png.write(to: url)
}

func render(theme: String, draw: (Int, NSSize) -> Void) throws {
    let outDir = URL(fileURLWithPath: "Resources/Themes/\(theme)")
    try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
    for i in 0..<frameCount {
        let img = NSImage(size: size)
        img.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()
        NSColor.black.setFill()
        NSColor.black.setStroke()
        draw(i, size)
        img.unlockFocus()
        let url = outDir.appendingPathComponent(String(format: "frame_%02d.png", i))
        try writePNG(img, to: url)
        print("wrote \(url.path)")
    }
}

// MARK: cat — running silhouette, alternating legs, swishing tail

try render(theme: "cat") { frame, s in
    let phase = CGFloat(frame) / CGFloat(frameCount)
    let bob = sin(phase * .pi * 2) * 0.8
    let cy: CGFloat = 9 + bob

    // body
    let body = NSBezierPath(roundedRect: NSRect(x: 8, y: cy, width: 22, height: 8), xRadius: 4, yRadius: 4)
    body.fill()
    // head
    NSBezierPath(ovalIn: NSRect(x: 26, y: cy + 3, width: 10, height: 9)).fill()
    // ears (triangles)
    let earL = NSBezierPath()
    earL.move(to: NSPoint(x: 27, y: cy + 11)); earL.line(to: NSPoint(x: 29, y: cy + 15)); earL.line(to: NSPoint(x: 31, y: cy + 11)); earL.close(); earL.fill()
    let earR = NSBezierPath()
    earR.move(to: NSPoint(x: 31, y: cy + 11)); earR.line(to: NSPoint(x: 33, y: cy + 14)); earR.line(to: NSPoint(x: 35, y: cy + 11)); earR.close(); earR.fill()
    // tail (curved, wags)
    let tailY = cy + 6 + sin(phase * .pi * 2 + .pi) * 4
    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: 8, y: cy + 5))
    tail.curve(to: NSPoint(x: 1, y: tailY),
               controlPoint1: NSPoint(x: 4, y: cy + 5),
               controlPoint2: NSPoint(x: 1, y: tailY - 2))
    tail.lineWidth = 2
    tail.lineCapStyle = .round
    tail.stroke()

    // legs — two pairs alternating
    let alt: CGFloat = frame.isMultiple(of: 2) ? 1 : -1
    // front legs
    NSBezierPath(rect: NSRect(x: 11, y: cy - 5 + alt, width: 3, height: 6 - alt)).fill()
    NSBezierPath(rect: NSRect(x: 24, y: cy - 5 - alt, width: 3, height: 6 + alt)).fill()
    // back legs (opposite)
    NSBezierPath(rect: NSRect(x: 15, y: cy - 5 - alt, width: 3, height: 6 + alt)).fill()
    NSBezierPath(rect: NSRect(x: 20, y: cy - 5 + alt, width: 3, height: 6 - alt)).fill()

    // tiny eye highlight (knocked out)
    NSColor.clear.setFill()
    NSGraphicsContext.current?.compositingOperation = .destinationOut
    NSBezierPath(ovalIn: NSRect(x: 32, y: cy + 7, width: 1.5, height: 1.5)).fill()
    NSGraphicsContext.current?.compositingOperation = .sourceOver
    NSColor.black.setFill()
}

// MARK: parrot — flapping wings, perched body

try render(theme: "parrot") { frame, s in
    let phase = CGFloat(frame) / CGFloat(frameCount)
    let flap = sin(phase * .pi * 2)

    // body
    NSBezierPath(ovalIn: NSRect(x: 12, y: 4, width: 18, height: 14)).fill()
    // head
    NSBezierPath(ovalIn: NSRect(x: 24, y: 12, width: 10, height: 9)).fill()
    // beak
    let beak = NSBezierPath()
    beak.move(to: NSPoint(x: 33, y: 17)); beak.line(to: NSPoint(x: 38, y: 15)); beak.line(to: NSPoint(x: 33, y: 14)); beak.close(); beak.fill()
    // wing — flaps via shear
    let wing = NSBezierPath()
    let wingTipY: CGFloat = 14 + flap * 7
    wing.move(to: NSPoint(x: 14, y: 12))
    wing.curve(to: NSPoint(x: 24, y: wingTipY),
               controlPoint1: NSPoint(x: 16, y: 16),
               controlPoint2: NSPoint(x: 20, y: wingTipY))
    wing.line(to: NSPoint(x: 22, y: 8))
    wing.close()
    wing.fill()
    // tail
    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: 12, y: 10)); tail.line(to: NSPoint(x: 3, y: 8)); tail.line(to: NSPoint(x: 12, y: 6)); tail.close(); tail.fill()
    // feet
    NSBezierPath(rect: NSRect(x: 17, y: 1, width: 1.5, height: 4)).fill()
    NSBezierPath(rect: NSRect(x: 23, y: 1, width: 1.5, height: 4)).fill()
}

// MARK: horse — galloping silhouette

try render(theme: "horse") { frame, s in
    let phase = CGFloat(frame) / CGFloat(frameCount)
    let bob = sin(phase * .pi * 2) * 1.2
    let cy: CGFloat = 8 + bob

    // body — elongated rounded rect
    NSBezierPath(roundedRect: NSRect(x: 6, y: cy, width: 26, height: 7), xRadius: 3, yRadius: 3).fill()
    // neck
    let neck = NSBezierPath()
    neck.move(to: NSPoint(x: 28, y: cy + 6))
    neck.line(to: NSPoint(x: 34, y: cy + 13))
    neck.line(to: NSPoint(x: 38, y: cy + 12))
    neck.line(to: NSPoint(x: 32, y: cy + 5))
    neck.close()
    neck.fill()
    // head
    NSBezierPath(ovalIn: NSRect(x: 34, y: cy + 11, width: 9, height: 6)).fill()
    // ear
    let ear = NSBezierPath()
    ear.move(to: NSPoint(x: 35, y: cy + 16)); ear.line(to: NSPoint(x: 36, y: cy + 19)); ear.line(to: NSPoint(x: 37, y: cy + 16)); ear.close(); ear.fill()
    // mane
    for i in 0..<4 {
        let x = 31 + CGFloat(i) * 1.2
        NSBezierPath(ovalIn: NSRect(x: x, y: cy + 11, width: 2, height: 3)).fill()
    }
    // tail
    let tail = NSBezierPath()
    tail.move(to: NSPoint(x: 6, y: cy + 5))
    tail.curve(to: NSPoint(x: 0, y: cy + sin(phase * .pi * 2 + 1) * 3),
               controlPoint1: NSPoint(x: 3, y: cy + 4),
               controlPoint2: NSPoint(x: 0, y: cy + 2))
    tail.lineWidth = 2.5
    tail.lineCapStyle = .round
    tail.stroke()
    // legs — galloping 4-beat
    let beats: [(CGFloat, CGFloat)] = [
        (-3,  3), ( 3, -3), (-3, -3), ( 3,  3), ( 0,  0)
    ]
    let b = beats[frame % beats.count]
    NSBezierPath(rect: NSRect(x: 9,  y: cy - 6 + b.0, width: 2.5, height: 7 - b.0)).fill()
    NSBezierPath(rect: NSRect(x: 13, y: cy - 6 + b.1, width: 2.5, height: 7 - b.1)).fill()
    NSBezierPath(rect: NSRect(x: 24, y: cy - 6 - b.1, width: 2.5, height: 7 + b.1)).fill()
    NSBezierPath(rect: NSRect(x: 28, y: cy - 6 - b.0, width: 2.5, height: 7 + b.0)).fill()
}

// MARK: dog — trotting silhouette with long body and floppy ears

try render(theme: "dog") { frame, s in
    let phase = CGFloat(frame) / CGFloat(frameCount)
    let bob = sin(phase * .pi * 2) * 0.8
    let cy: CGFloat = 8 + bob

    NSBezierPath(roundedRect: NSRect(x: 6, y: cy, width: 24, height: 8), xRadius: 4, yRadius: 4).fill()
    // head + snout
    NSBezierPath(ovalIn: NSRect(x: 26, y: cy + 4, width: 10, height: 8)).fill()
    NSBezierPath(roundedRect: NSRect(x: 33, y: cy + 4, width: 7, height: 4), xRadius: 1, yRadius: 1).fill()
    // floppy ear
    let ear = NSBezierPath()
    ear.move(to: NSPoint(x: 27, y: cy + 11))
    ear.curve(to: NSPoint(x: 25, y: cy + 4),
              controlPoint1: NSPoint(x: 23, y: cy + 10),
              controlPoint2: NSPoint(x: 23, y: cy + 5))
    ear.line(to: NSPoint(x: 28, y: cy + 4))
    ear.close(); ear.fill()
    // tail (perky, wags)
    let tail = NSBezierPath()
    let tailTip = cy + 12 + sin(phase * .pi * 2) * 2
    tail.move(to: NSPoint(x: 6, y: cy + 6))
    tail.curve(to: NSPoint(x: 0, y: tailTip),
               controlPoint1: NSPoint(x: 3, y: cy + 9),
               controlPoint2: NSPoint(x: 0, y: tailTip - 3))
    tail.lineWidth = 2.5; tail.lineCapStyle = .round; tail.stroke()
    // legs - trotting
    let alt: CGFloat = frame.isMultiple(of: 2) ? 2 : -2
    NSBezierPath(rect: NSRect(x: 9,  y: cy - 5 + alt, width: 2.5, height: 6 - alt)).fill()
    NSBezierPath(rect: NSRect(x: 14, y: cy - 5 - alt, width: 2.5, height: 6 + alt)).fill()
    NSBezierPath(rect: NSRect(x: 22, y: cy - 5 - alt, width: 2.5, height: 6 + alt)).fill()
    NSBezierPath(rect: NSRect(x: 27, y: cy - 5 + alt, width: 2.5, height: 6 - alt)).fill()
}

// MARK: rabbit — hopping silhouette with long ears

try render(theme: "rabbit") { frame, s in
    let phase = CGFloat(frame) / CGFloat(frameCount)
    // hop height — peaks at mid-cycle
    let hop = max(0, sin(phase * .pi)) * 5
    let cy: CGFloat = 4 + hop
    let tuck = phase < 0.5 ? 0.0 : 1.0   // legs tuck mid-hop

    // body
    NSBezierPath(ovalIn: NSRect(x: 10, y: cy, width: 18, height: 11)).fill()
    // head
    NSBezierPath(ovalIn: NSRect(x: 24, y: cy + 6, width: 9, height: 9)).fill()
    // long ears
    NSBezierPath(roundedRect: NSRect(x: 25, y: cy + 13, width: 2, height: 7), xRadius: 1, yRadius: 1).fill()
    NSBezierPath(roundedRect: NSRect(x: 29, y: cy + 13, width: 2, height: 7), xRadius: 1, yRadius: 1).fill()
    // fluffy tail
    NSBezierPath(ovalIn: NSRect(x: 7, y: cy + 4, width: 4, height: 4)).fill()
    // legs
    if tuck < 0.5 {
        // extended (push-off)
        NSBezierPath(roundedRect: NSRect(x: 11, y: cy - 4, width: 4, height: 6), xRadius: 1.5, yRadius: 1.5).fill()
        NSBezierPath(roundedRect: NSRect(x: 22, y: cy - 4, width: 4, height: 6), xRadius: 1.5, yRadius: 1.5).fill()
    } else {
        // tucked (airborne)
        NSBezierPath(roundedRect: NSRect(x: 12, y: cy, width: 6, height: 3), xRadius: 1.5, yRadius: 1.5).fill()
        NSBezierPath(roundedRect: NSRect(x: 20, y: cy, width: 6, height: 3), xRadius: 1.5, yRadius: 1.5).fill()
    }
}

// MARK: snake — sinusoidal body, no legs

try render(theme: "snake") { frame, s in
    let phase = CGFloat(frame) / CGFloat(frameCount)
    let segments = 18
    let segW: CGFloat = 2.4
    for i in 0..<segments {
        let t = CGFloat(i) / CGFloat(segments)
        let x = 2 + t * 36
        let amp: CGFloat = 4.5
        let y = 10 + sin(t * .pi * 3 + phase * .pi * 2) * amp
        let r = max(2.5, 4 - abs(t - 0.0) * 2) // taper toward tail
        NSBezierPath(ovalIn: NSRect(x: x - r/2, y: y - r/2, width: r, height: r)).fill()
        _ = segW
    }
    // head (slightly larger circle at front)
    let headT: CGFloat = 1.0
    let hx = 2 + headT * 36
    let hy = 10 + sin(headT * .pi * 3 + phase * .pi * 2) * 4.5
    NSBezierPath(ovalIn: NSRect(x: hx - 3, y: hy - 3, width: 6, height: 6)).fill()
    // tongue flick on odd frames
    if frame % 2 == 1 {
        let tongue = NSBezierPath()
        tongue.move(to: NSPoint(x: hx + 3, y: hy))
        tongue.line(to: NSPoint(x: hx + 7, y: hy + 1))
        tongue.line(to: NSPoint(x: hx + 7, y: hy - 1))
        tongue.lineWidth = 1; tongue.stroke()
    }
}

print("done")
