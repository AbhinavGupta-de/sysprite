import Foundation
import Darwin

struct MemorySample {
    let usedBytes: UInt64
    let totalBytes: UInt64
    var percent: Double { totalBytes == 0 ? 0 : Double(usedBytes) / Double(totalBytes) * 100 }
}

final class MemoryMonitor {
    private let queue = DispatchQueue(label: "sysprite.mem")
    private var timer: DispatchSourceTimer?
    var onUpdate: ((MemorySample) -> Void)?

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
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return }
        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let wired  = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let used = active + wired + compressed
        let total = ProcessInfo.processInfo.physicalMemory
        let sample = MemorySample(usedBytes: used, totalBytes: total)
        DispatchQueue.main.async { [onUpdate] in onUpdate?(sample) }
    }
}
