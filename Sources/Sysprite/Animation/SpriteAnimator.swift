import AppKit

final class SpriteAnimator {
    private var theme: Theme
    private var frameIndex = 0
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "runcat.animator")
    private(set) var currentInterval: TimeInterval = 0.2

    var onFrame: ((NSImage) -> Void)?

    init(theme: Theme) {
        self.theme = theme
        start()
    }

    func setTheme(_ theme: Theme) {
        queue.async { [weak self] in
            self?.theme = theme
            self?.frameIndex = 0
        }
    }

    /// Maps system pressure (0–100) to per-frame interval. Higher pressure → faster animation.
    /// Exponential curve so idle vs busy is visually obvious.
    func setPressure(_ pressure: Double) {
        let clamped = max(0, min(100, pressure)) / 100.0
        // 0 → 500ms/frame (lazy stroll); 1 → 20ms/frame (full sprint)
        let interval = 0.5 * pow(0.04, clamped)
        queue.async { [weak self] in
            guard let self else { return }
            guard abs(interval - self.currentInterval) > 0.002 else { return }
            self.currentInterval = interval
            self.restartTimer()
        }
    }

    private func start() {
        queue.async { [weak self] in self?.restartTimer() }
    }

    private func restartTimer() {
        timer?.cancel()
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + currentInterval, repeating: currentInterval)
        t.setEventHandler { [weak self] in self?.tick() }
        t.resume()
        timer = t
    }

    private func tick() {
        guard !theme.frames.isEmpty else { return }
        let img = theme.frames[frameIndex % theme.frames.count]
        frameIndex += 1
        DispatchQueue.main.async { [onFrame] in onFrame?(img) }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }
}
