import Foundation

struct DiskSample {
    let usedBytes: UInt64
    let totalBytes: UInt64
    var percent: Double { totalBytes == 0 ? 0 : Double(usedBytes) / Double(totalBytes) * 100 }
}

/// Disk capacity is mostly static, so we re-query the volume at `refreshInterval` but emit the
/// cached value every `tickInterval` so its sparkline stays in sync with the other rows.
final class DiskMonitor {
    private let queue = DispatchQueue(label: "sysprite.disk")
    private var timer: DispatchSourceTimer?
    private var cached: DiskSample?
    private var lastFetch: Date = .distantPast
    private let refreshInterval: TimeInterval = 15.0

    var onUpdate: ((DiskSample) -> Void)?

    func start(tickInterval: TimeInterval = 1.0) {
        queue.async { [weak self] in self?.tick() }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + tickInterval, repeating: tickInterval)
        t.setEventHandler { [weak self] in self?.tick() }
        t.resume()
        timer = t
    }

    func stop() { timer?.cancel(); timer = nil }

    private func tick() {
        if cached == nil || Date().timeIntervalSince(lastFetch) >= refreshInterval {
            refresh()
        }
        guard let sample = cached else { return }
        DispatchQueue.main.async { [onUpdate] in onUpdate?(sample) }
    }

    private func refresh() {
        let url = URL(fileURLWithPath: "/")
        guard let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]),
              let total = values.volumeTotalCapacity,
              let avail = values.volumeAvailableCapacityForImportantUsage else { return }
        let totalU = UInt64(total)
        let availU = UInt64(avail)
        let used = totalU > availU ? totalU - availU : 0
        cached = DiskSample(usedBytes: used, totalBytes: totalU)
        lastFetch = Date()
    }
}
