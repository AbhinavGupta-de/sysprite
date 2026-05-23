import AppKit

struct Theme: Identifiable, Hashable {
    let id: String
    let displayName: String
    let frames: [NSImage]

    static func loadAll() -> [Theme] {
        let fm = FileManager.default
        // App bundle: Contents/Resources/Themes
        let candidates: [URL] = [
            Bundle.main.resourceURL?.appendingPathComponent("Themes"),
            URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("Resources/Themes")
        ].compactMap { $0 }

        guard let root = candidates.first(where: { fm.fileExists(atPath: $0.path) }) else {
            return [Theme.procedural()]
        }
        let dirs: [URL] = ((try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? [])
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var themes: [Theme] = dirs.compactMap { dir -> Theme? in
            let pngs: [URL] = ((try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? [])
                .filter { $0.pathExtension.lowercased() == "png" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            guard !pngs.isEmpty else { return nil }
            let frames = pngs.compactMap { NSImage(contentsOf: $0) }
            frames.forEach { $0.isTemplate = true }
            return Theme(id: dir.lastPathComponent, displayName: dir.lastPathComponent.capitalized, frames: frames)
        }

        if themes.isEmpty { themes = [Theme.procedural()] }
        return themes
    }

    /// Fallback theme: programmatically draws a tiny running cat silhouette across 5 frames.
    /// Used only when no PNG sprite sheets are bundled — see Resources/Themes/README.md.
    static func procedural() -> Theme {
        let size = NSSize(width: 22, height: 16)
        let frames: [NSImage] = (0..<5).map { i in
            let img = NSImage(size: size)
            img.lockFocus()
            NSColor.black.setFill()
            let phase = CGFloat(i) / 5.0
            let body = NSBezierPath(roundedRect: NSRect(x: 4, y: 4, width: 14, height: 7), xRadius: 3, yRadius: 3)
            body.fill()
            // head
            NSBezierPath(ovalIn: NSRect(x: 14, y: 7, width: 6, height: 6)).fill()
            // ears
            let earL = NSBezierPath(); earL.move(to: NSPoint(x: 15, y: 12)); earL.line(to: NSPoint(x: 16, y: 15)); earL.line(to: NSPoint(x: 17, y: 12)); earL.close(); earL.fill()
            let earR = NSBezierPath(); earR.move(to: NSPoint(x: 17, y: 12)); earR.line(to: NSPoint(x: 18, y: 14)); earR.line(to: NSPoint(x: 19, y: 12)); earR.close(); earR.fill()
            // tail wags
            let tailY = 8 + sin(phase * .pi * 2) * 2
            let tail = NSBezierPath(); tail.move(to: NSPoint(x: 4, y: 8)); tail.curve(to: NSPoint(x: 1, y: tailY + 3), controlPoint1: NSPoint(x: 2, y: 8), controlPoint2: NSPoint(x: 1, y: tailY)); tail.lineWidth = 1.5; tail.stroke()
            // legs alternate
            let legPhase: CGFloat = (i % 2 == 0) ? 1 : -1
            NSBezierPath(rect: NSRect(x: 6, y: 1, width: 2, height: 3 + legPhase)).fill()
            NSBezierPath(rect: NSRect(x: 14, y: 1, width: 2, height: 3 - legPhase)).fill()
            img.unlockFocus()
            img.isTemplate = true
            return img
        }
        return Theme(id: "cat", displayName: "Cat", frames: frames)
    }
}
