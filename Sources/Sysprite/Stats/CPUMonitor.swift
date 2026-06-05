import Foundation
import Darwin

/// Samples system-wide CPU usage via host_processor_info; computes delta between ticks.
final class CPUMonitor {
    private var prevTicks: [UInt32] = []
    private let queue = DispatchQueue(label: "sysprite.cpu")
    private var timer: DispatchSourceTimer?

    var onUpdate: ((Double) -> Void)?

    func start(interval: TimeInterval = 1.0) {
        // Prime baseline tick snapshot so the second call produces a real delta immediately.
        queue.async { [weak self] in self?.sample(); self?.sample() }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + interval, repeating: interval)
        t.setEventHandler { [weak self] in self?.sample() }
        t.resume()
        timer = t
    }

    func stop() { timer?.cancel(); timer = nil }

    private func sample() {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let kr = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &info, &infoCount)
        guard kr == KERN_SUCCESS, let info else { return }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride))
        }

        let ticks = UnsafeBufferPointer(start: info, count: Int(infoCount)).map { UInt32(bitPattern: Int32($0)) }
        defer { prevTicks = ticks }
        guard prevTicks.count == ticks.count else { return }

        var totalUsed: UInt64 = 0
        var totalAll: UInt64 = 0
        let perCPU = Int(CPU_STATE_MAX)
        for c in 0..<Int(cpuCount) {
            let base = c * perCPU
            let user = UInt64(ticks[base + Int(CPU_STATE_USER)] &- prevTicks[base + Int(CPU_STATE_USER)])
            let sys  = UInt64(ticks[base + Int(CPU_STATE_SYSTEM)] &- prevTicks[base + Int(CPU_STATE_SYSTEM)])
            let nice = UInt64(ticks[base + Int(CPU_STATE_NICE)] &- prevTicks[base + Int(CPU_STATE_NICE)])
            let idle = UInt64(ticks[base + Int(CPU_STATE_IDLE)] &- prevTicks[base + Int(CPU_STATE_IDLE)])
            totalUsed += user + sys + nice
            totalAll  += user + sys + nice + idle
        }
        guard totalAll > 0 else { return }
        let pct = Double(totalUsed) / Double(totalAll) * 100.0
        DispatchQueue.main.async { [onUpdate] in onUpdate?(pct) }
    }
}
