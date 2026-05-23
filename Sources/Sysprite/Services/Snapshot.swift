import Foundation

/// Thread-safe shared cache of the most recent stats sample, persisted to disk so the CLI mode
/// (`sysprite stats`) and sketchybar plugins can read live values from another process.
final class Snapshot {
    static let shared = Snapshot()

    var cpu: Double = 0
    var memory: Double = 0
    var memoryUsedBytes: UInt64 = 0
    var memoryTotalBytes: UInt64 = 0
    var disk: Double = 0
    var diskFreeBytes: UInt64 = 0
    var netDownBps: UInt64 = 0
    var netUpBps: UInt64 = 0
    var batteryPresent: Bool = false
    var batteryPercent: Double = 0
    var batteryCharging: Bool = false
    var pressure: Double = 0

    private let queue = DispatchQueue(label: "sysprite.snapshot")
    private var timer: DispatchSourceTimer?

    static var fileURL: URL {
        let dir = (try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Sysprite", isDirectory: true)) ?? URL(fileURLWithPath: NSTemporaryDirectory())
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("snapshot.json")
    }

    func start() {
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + 1.0, repeating: 1.0)
        t.setEventHandler { [weak self] in self?.persist() }
        t.resume()
        timer = t
    }

    func persist() {
        let dict: [String: Any] = [
            "cpu": cpu,
            "memory": memory,
            "memory_used_bytes": memoryUsedBytes,
            "memory_total_bytes": memoryTotalBytes,
            "disk": disk,
            "disk_free_bytes": diskFreeBytes,
            "net_down_bps": netDownBps,
            "net_up_bps": netUpBps,
            "battery_present": batteryPresent,
            "battery_percent": batteryPercent,
            "battery_charging": batteryCharging,
            "pressure": pressure,
            "timestamp": Date().timeIntervalSince1970
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }
}
