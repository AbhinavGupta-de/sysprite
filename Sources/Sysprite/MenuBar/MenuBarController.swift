import AppKit

final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private var animator: SpriteAnimator

    private let cpuMonitor = CPUMonitor()
    private let memMonitor = MemoryMonitor()
    private let diskMonitor = DiskMonitor()
    private let netMonitor = NetworkMonitor()
    private let batteryMonitor = BatteryMonitor()

    private var themes: [Theme] = []
    private var prefsController: PreferencesWindowController?

    private var cpuRow: StatRowView!
    private var memRow: StatRowView!
    private var diskRow: StatRowView!
    private var netRow: StatRowView!
    private var batteryRow: StatRowView!
    private var batteryItem: NSMenuItem!
    private var themeMenu: NSMenu!

    private var latestCPU: Double = 0
    private var latestMem: Double = 0
    private var latestDisk: Double = 0
    private var latestNet: Double = 0

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        themes = Theme.loadAll()
        let initial = themes.first(where: { $0.id == Settings.shared.themeID }) ?? themes[0]
        animator = SpriteAnimator(theme: initial)
        super.init()
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        wireMonitors()
        buildMenu()
        animator.onFrame = { [weak self] img in self?.statusItem.button?.image = img }
        Snapshot.shared.start()
    }

    func shutdown() {
        animator.stop()
        cpuMonitor.stop(); memMonitor.stop(); diskMonitor.stop()
        netMonitor.stop(); batteryMonitor.stop()
    }

    /// Combined pressure drives animation speed and the label color.
    /// CPU and memory dominate; disk only kicks in when nearly full; sustained network adds too.
    private func currentPressure() -> Double {
        var p = max(latestCPU, latestMem)
        if latestDisk >= 90 { p = max(p, 75) }
        if latestNet >= 50 { p = max(p, latestNet * 0.7) }
        return p
    }

    private func applyPressure() {
        let p = currentPressure()
        animator.setPressure(p)
        updateButtonAppearance(pressure: p)
        Snapshot.shared.pressure = p
    }

    private func updateButtonAppearance(pressure p: Double) {
        guard let button = statusItem.button else { return }
        if Settings.shared.showPressureLabel {
            button.title = " \(Int(p))%"
        } else {
            button.title = ""
        }
        if Settings.shared.tintOnHighPressure {
            let color: NSColor
            switch p {
            case ..<70: color = .labelColor
            case ..<90: color = .systemOrange
            default:    color = .systemRed
            }
            button.contentTintColor = color
        } else {
            button.contentTintColor = nil
        }
    }

    private func wireMonitors() {
        cpuMonitor.onUpdate = { [weak self] pct in
            guard let self else { return }
            self.latestCPU = pct
            self.cpuRow?.update(percent: pct, detail: String(format: "%.0f%%", pct))
            Snapshot.shared.cpu = pct
            self.applyPressure()
            if Settings.shared.highCPUAlerts, pct >= Settings.shared.highCPUThreshold {
                NotificationService.shared.alertHighCPU(percent: pct, threshold: Settings.shared.highCPUThreshold)
            }
        }
        memMonitor.onUpdate = { [weak self] s in
            guard let self else { return }
            self.latestMem = s.percent
            self.memRow?.update(percent: s.percent,
                                detail: String(format: "%.0f%%  %@/%@", s.percent, Self.fmt(s.usedBytes), Self.fmt(s.totalBytes)))
            Snapshot.shared.memory = s.percent
            Snapshot.shared.memoryUsedBytes = s.usedBytes
            Snapshot.shared.memoryTotalBytes = s.totalBytes
            self.applyPressure()
        }
        diskMonitor.onUpdate = { [weak self] s in
            guard let self else { return }
            self.latestDisk = s.percent
            self.diskRow?.update(percent: s.percent,
                                 detail: String(format: "%.0f%%  %@ free", s.percent, Self.fmt(s.totalBytes - s.usedBytes)))
            Snapshot.shared.disk = s.percent
            Snapshot.shared.diskFreeBytes = s.totalBytes - s.usedBytes
            self.applyPressure()
        }
        netMonitor.onUpdate = { [weak self] s in
            guard let self else { return }
            self.latestNet = s.percent
            let detail = String(format: "↓ %@/s  ↑ %@/s",
                                Self.fmt(s.downBytesPerSec), Self.fmt(s.upBytesPerSec))
            self.netRow?.update(percent: s.percent, detail: detail)
            Snapshot.shared.netDownBps = s.downBytesPerSec
            Snapshot.shared.netUpBps = s.upBytesPerSec
            self.applyPressure()
        }
        batteryMonitor.onUpdate = { [weak self] s in
            guard let self else { return }
            self.batteryItem.isHidden = !s.isPresent
            guard s.isPresent else { return }
            let suffix: String
            if s.isCharging { suffix = "charging" }
            else if let tte = s.timeToEmptyMinutes { suffix = "\(tte / 60)h \(tte % 60)m left" }
            else { suffix = "on battery" }
            self.batteryRow?.update(percent: s.percent,
                                    detail: String(format: "%.0f%%  %@", s.percent, suffix))
            Snapshot.shared.batteryPercent = s.percent
            Snapshot.shared.batteryCharging = s.isCharging
            Snapshot.shared.batteryPresent = true
        }
        cpuMonitor.start()
        memMonitor.start()
        diskMonitor.start()
        netMonitor.start()
        batteryMonitor.start()
    }

    private func buildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        cpuRow = StatRowView(title: "CPU")
        memRow = StatRowView(title: "Memory")
        diskRow = StatRowView(title: "Disk")
        netRow = StatRowView(title: "Network")
        batteryRow = StatRowView(title: "Battery")

        for row in [cpuRow, memRow, diskRow, netRow] {
            let item = NSMenuItem(); item.view = row; menu.addItem(item)
        }
        batteryItem = NSMenuItem(); batteryItem.view = batteryRow; batteryItem.isHidden = true
        menu.addItem(batteryItem)

        menu.addItem(.separator())

        let activity = NSMenuItem(title: "Open Activity Monitor", action: #selector(openActivityMonitor), keyEquivalent: "")
        activity.target = self
        menu.addItem(activity)

        let themeRoot = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeMenu = NSMenu(title: "Theme")
        for t in themes {
            let item = NSMenuItem(title: t.displayName, action: #selector(selectTheme(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = t.id
            item.state = (t.id == Settings.shared.themeID) ? .on : .off
            themeMenu.addItem(item)
        }
        themeRoot.submenu = themeMenu
        menu.addItem(themeRoot)

        let prefs = NSMenuItem(title: "Preferences…", action: #selector(openPrefs), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "About Sysprite", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }

    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let theme = themes.first(where: { $0.id == id }) else { return }
        Settings.shared.themeID = id
        animator.setTheme(theme)
        themeMenu.items.forEach { $0.state = ($0.representedObject as? String == id) ? .on : .off }
    }

    @objc private func openPrefs() {
        if prefsController == nil {
            prefsController = PreferencesWindowController(
                themes: themes,
                onThemeChange: { [weak self] newThemeID in
                    guard let self, let t = self.themes.first(where: { $0.id == newThemeID }) else { return }
                    Settings.shared.themeID = newThemeID
                    self.animator.setTheme(t)
                    self.themeMenu.items.forEach { $0.state = ($0.representedObject as? String == newThemeID) ? .on : .off }
                },
                onAppearanceChange: { [weak self] in self?.applyPressure() }
            )
        }
        prefsController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Sysprite",
            .applicationVersion: "0.1.0",
            .credits: NSAttributedString(string: "Open-source menu-bar system pet.\nhttps://github.com/AbhinavGupta-de/sysprite")
        ])
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() { NSApp.terminate(nil) }

    private static func fmt(_ bytes: UInt64) -> String {
        let bcf = ByteCountFormatter(); bcf.countStyle = .memory
        return bcf.string(fromByteCount: Int64(bytes))
    }
}
