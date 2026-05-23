import Foundation

final class Settings {
    static let shared = Settings()
    private let defaults = UserDefaults.standard

    enum Keys {
        static let themeID = "themeID"
        static let launchAtLogin = "launchAtLogin"
        static let highCPUAlerts = "highCPUAlerts"
        static let highCPUThreshold = "highCPUThreshold"
        static let showStatsInMenu = "showStatsInMenu"
        static let showPressureLabel = "showPressureLabel"
        static let tintOnHighPressure = "tintOnHighPressure"
    }

    var themeID: String {
        get { defaults.string(forKey: Keys.themeID) ?? "cat" }
        set { defaults.set(newValue, forKey: Keys.themeID) }
    }
    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }
    var highCPUAlerts: Bool {
        get { defaults.object(forKey: Keys.highCPUAlerts) == nil ? false : defaults.bool(forKey: Keys.highCPUAlerts) }
        set { defaults.set(newValue, forKey: Keys.highCPUAlerts) }
    }
    var highCPUThreshold: Double {
        get { let v = defaults.double(forKey: Keys.highCPUThreshold); return v == 0 ? 85 : v }
        set { defaults.set(newValue, forKey: Keys.highCPUThreshold) }
    }
    var showStatsInMenu: Bool {
        get { defaults.object(forKey: Keys.showStatsInMenu) == nil ? true : defaults.bool(forKey: Keys.showStatsInMenu) }
        set { defaults.set(newValue, forKey: Keys.showStatsInMenu) }
    }
    var showPressureLabel: Bool {
        get { defaults.object(forKey: Keys.showPressureLabel) == nil ? true : defaults.bool(forKey: Keys.showPressureLabel) }
        set { defaults.set(newValue, forKey: Keys.showPressureLabel) }
    }
    var tintOnHighPressure: Bool {
        get { defaults.object(forKey: Keys.tintOnHighPressure) == nil ? true : defaults.bool(forKey: Keys.tintOnHighPressure) }
        set { defaults.set(newValue, forKey: Keys.tintOnHighPressure) }
    }
}
