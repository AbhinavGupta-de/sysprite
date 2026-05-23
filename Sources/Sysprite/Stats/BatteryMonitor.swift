import Foundation
import IOKit.ps

struct BatterySample {
    let percent: Double
    let isCharging: Bool
    let isPresent: Bool
    let timeToEmptyMinutes: Int?
}

final class BatteryMonitor {
    private let queue = DispatchQueue(label: "sysprite.battery")
    private var timer: DispatchSourceTimer?
    var onUpdate: ((BatterySample) -> Void)?

    func start(interval: TimeInterval = 10.0) {
        queue.async { [weak self] in self?.sample() }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + interval, repeating: interval)
        t.setEventHandler { [weak self] in self?.sample() }
        t.resume()
        timer = t
    }

    func stop() { timer?.cancel(); timer = nil }

    private func sample() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }
        for src in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, src)?.takeUnretainedValue() as? [String: Any] else { continue }
            guard let type = info[kIOPSTypeKey] as? String, type == kIOPSInternalBatteryType else { continue }
            let cur = info[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max = info[kIOPSMaxCapacityKey] as? Int ?? 100
            let charging = (info[kIOPSIsChargingKey] as? Bool) ?? false
            let tte = info[kIOPSTimeToEmptyKey] as? Int
            let sample = BatterySample(
                percent: max == 0 ? 0 : Double(cur) / Double(max) * 100,
                isCharging: charging,
                isPresent: true,
                timeToEmptyMinutes: (tte ?? -1) > 0 ? tte : nil
            )
            DispatchQueue.main.async { [onUpdate] in onUpdate?(sample) }
            return
        }
        // No internal battery (e.g. desktop Mac)
        DispatchQueue.main.async { [onUpdate] in
            onUpdate?(BatterySample(percent: 0, isCharging: false, isPresent: false, timeToEmptyMinutes: nil))
        }
    }
}
