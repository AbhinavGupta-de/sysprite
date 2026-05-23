import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    init(themes: [Theme], onThemeChange: @escaping (String) -> Void, onAppearanceChange: @escaping () -> Void) {
        let root = PreferencesView(themes: themes,
                                   onThemeChange: onThemeChange,
                                   onAppearanceChange: onAppearanceChange)
        let host = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: host)
        window.title = "Sysprite Preferences"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 420, height: 340))
        super.init(window: window)
    }
    required init?(coder: NSCoder) { fatalError() }
}

struct PreferencesView: View {
    let themes: [Theme]
    let onThemeChange: (String) -> Void
    let onAppearanceChange: () -> Void

    @State private var themeID: String = Settings.shared.themeID
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @State private var highCPUAlerts: Bool = Settings.shared.highCPUAlerts
    @State private var threshold: Double = Settings.shared.highCPUThreshold
    @State private var showLabel: Bool = Settings.shared.showPressureLabel
    @State private var tint: Bool = Settings.shared.tintOnHighPressure

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $themeID) {
                    ForEach(themes) { Text($0.displayName).tag($0.id) }
                }
                .onChange(of: themeID) { new in onThemeChange(new) }

                Toggle("Show pressure % in menu bar", isOn: $showLabel)
                    .onChange(of: showLabel) { new in
                        Settings.shared.showPressureLabel = new
                        onAppearanceChange()
                    }

                Toggle("Tint icon when pressure is high", isOn: $tint)
                    .onChange(of: tint) { new in
                        Settings.shared.tintOnHighPressure = new
                        onAppearanceChange()
                    }
            }

            Section("System") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { new in
                        Settings.shared.launchAtLogin = new
                        LaunchAtLogin.set(new)
                    }
            }

            Section("Notifications") {
                Toggle("High CPU notifications", isOn: $highCPUAlerts)
                    .onChange(of: highCPUAlerts) { new in Settings.shared.highCPUAlerts = new }

                HStack {
                    Text("Threshold")
                    Slider(value: $threshold, in: 50...100, step: 5)
                        .onChange(of: threshold) { new in Settings.shared.highCPUThreshold = new }
                    Text("\(Int(threshold))%").monospacedDigit().frame(width: 40, alignment: .trailing)
                }
            }

            Section {
                Text("Drop PNG frame sequences into `Resources/Themes/<name>/` and rebuild to add more themes. See README.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
