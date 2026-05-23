import Foundation
import Darwin

struct NetworkSample {
    let downBytesPerSec: UInt64
    let upBytesPerSec: UInt64
    /// Pseudo-percent for sparkline display, normalized against `referenceBytesPerSec`.
    let percent: Double
}

/// Sums non-loopback interface byte counters from `getifaddrs` and reports per-second deltas.
final class NetworkMonitor {
    private let queue = DispatchQueue(label: "sysprite.net")
    private var timer: DispatchSourceTimer?
    private var lastIn: UInt64 = 0
    private var lastOut: UInt64 = 0
    private var lastAt: Date = .distantPast

    /// Bytes/sec value treated as "100%" for sparkline scaling (default 5 MB/s).
    var referenceBytesPerSec: Double = 5_000_000

    var onUpdate: ((NetworkSample) -> Void)?

    func start(interval: TimeInterval = 1.0) {
        queue.async { [weak self] in self?.sample() }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + interval, repeating: interval)
        t.setEventHandler { [weak self] in self?.sample() }
        t.resume()
        timer = t
    }

    func stop() { timer?.cancel(); timer = nil }

    private func sample() {
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let head = ifap else { return }
        defer { freeifaddrs(ifap) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var ptr: UnsafeMutablePointer<ifaddrs>? = head
        while let cur = ptr {
            defer { ptr = cur.pointee.ifa_next }
            let name = String(cString: cur.pointee.ifa_name)
            if name.hasPrefix("lo") { continue }
            guard let addr = cur.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) else { continue }
            guard let dataPtr = cur.pointee.ifa_data else { continue }
            let data = dataPtr.assumingMemoryBound(to: if_data.self).pointee
            totalIn += UInt64(data.ifi_ibytes)
            totalOut += UInt64(data.ifi_obytes)
        }

        let now = Date()
        defer { lastIn = totalIn; lastOut = totalOut; lastAt = now }
        guard lastAt != .distantPast else { return }
        let dt = now.timeIntervalSince(lastAt)
        guard dt > 0 else { return }
        let downBPS = totalIn >= lastIn ? UInt64(Double(totalIn - lastIn) / dt) : 0
        let upBPS = totalOut >= lastOut ? UInt64(Double(totalOut - lastOut) / dt) : 0
        let total = Double(downBPS + upBPS)
        let pct = min(100, total / referenceBytesPerSec * 100)
        let sample = NetworkSample(downBytesPerSec: downBPS, upBytesPerSec: upBPS, percent: pct)
        DispatchQueue.main.async { [onUpdate] in onUpdate?(sample) }
    }
}
