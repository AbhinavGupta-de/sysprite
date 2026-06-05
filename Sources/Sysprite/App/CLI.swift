import Foundation
import ServiceManagement

/// `sysprite stats` CLI. Reads the snapshot JSON written by the running GUI and prints either
/// the full JSON or a single field — designed for sketchybar plugins, fish/zsh prompts, etc.
enum CLI {
    static func runStats(_ args: [String]) {
        guard let data = try? Data(contentsOf: Snapshot.fileURL),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            FileHandle.standardError.write(Data("sysprite: no snapshot yet (is the app running?)\n".utf8))
            exit(1)
        }

        let flag = args.first ?? "--text"
        switch flag {
        case "--json":
            if let pretty = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
               let s = String(data: pretty, encoding: .utf8) {
                print(s)
            }
        case "--text":
            let cpu = dict["cpu"] as? Double ?? 0
            let mem = dict["memory"] as? Double ?? 0
            let pressure = dict["pressure"] as? Double ?? 0
            print(String(format: "CPU %.0f%%  MEM %.0f%%  PRESSURE %.0f%%", cpu, mem, pressure))
        case "--pressure":  printDouble(dict["pressure"])
        case "--cpu":       printDouble(dict["cpu"])
        case "--memory":    printDouble(dict["memory"])
        case "--disk":      printDouble(dict["disk"])
        case "--net-down":  printBytesPerSec(dict["net_down_bps"])
        case "--net-up":    printBytesPerSec(dict["net_up_bps"])
        case "--battery":   printDouble(dict["battery_percent"])
        case "--help", "-h":
            print("""
            Usage: sysprite stats [flag]

              --json         Print full snapshot as JSON
              --text         One-line human summary (default)
              --pressure     Combined pressure %
              --cpu          CPU %
              --memory       Memory %
              --disk         Disk %
              --net-down     Download bytes/sec
              --net-up       Upload bytes/sec
              --battery      Battery %
              --help, -h     This help
            """)
        default:
            FileHandle.standardError.write(Data("sysprite: unknown flag \(flag)\n".utf8))
            exit(2)
        }
    }

    private static func printDouble(_ any: Any?) {
        if let d = any as? Double { print(String(format: "%.0f", d)) } else { print("0") }
    }
    private static func printBytesPerSec(_ any: Any?) {
        let v = (any as? NSNumber)?.uint64Value ?? 0
        print(v)
    }

    /// Registers (or unregisters) Sysprite as a Login Item via SMAppService so the user can
    /// see and toggle it from System Settings → General → Login Items.
    static func setLoginItem(_ enabled: Bool) -> Int32 {
        guard #available(macOS 13.0, *) else {
            FileHandle.standardError.write(Data("sysprite: login items require macOS 13+\n".utf8))
            return 1
        }
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
                print("Sysprite is set to launch at login.")
            } else {
                if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
                print("Sysprite will no longer launch at login.")
            }
            return 0
        } catch {
            FileHandle.standardError.write(Data("sysprite: \(error.localizedDescription)\n".utf8))
            return 1
        }
    }

    static func printLoginStatus() -> Int32 {
        guard #available(macOS 13.0, *) else { print("unsupported"); return 1 }
        switch SMAppService.mainApp.status {
        case .enabled:           print("enabled")
        case .notRegistered:     print("disabled")
        case .notFound:          print("not-found")
        case .requiresApproval:  print("requires-approval")
        @unknown default:        print("unknown")
        }
        return 0
    }
}
