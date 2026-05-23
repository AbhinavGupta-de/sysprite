import AppKit

/// A menu-item-sized row: [label] [value] [60-sample sparkline].
final class StatRowView: NSView {
    private let label = NSTextField(labelWithString: "")
    private let value = NSTextField(labelWithString: "")
    private let spark = SparklineView()

    private let capacity = 60
    private var history: [Double] = []

    init(title: String) {
        super.init(frame: NSRect(x: 0, y: 0, width: 260, height: 36))
        label.stringValue = title
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor

        value.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        value.textColor = .labelColor
        value.alignment = .right

        [label, value, spark].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.widthAnchor.constraint(equalToConstant: 70),

            value.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 4),
            value.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            value.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            spark.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            spark.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            spark.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
            spark.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func update(percent: Double, detail: String) {
        history.append(max(0, min(100, percent)))
        if history.count > capacity { history.removeFirst(history.count - capacity) }
        value.stringValue = detail
        spark.samples = history
    }
}

/// Bar-chart sparkline of 0–100 samples.
final class SparklineView: NSView {
    var samples: [Double] = [] { didSet { needsDisplay = true } }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let ctx = NSGraphicsContext.current?.cgContext
        let bg = NSColor.tertiaryLabelColor.withAlphaComponent(0.18).cgColor
        ctx?.setFillColor(bg)
        let bgPath = CGPath(roundedRect: bounds, cornerWidth: 3, cornerHeight: 3, transform: nil)
        ctx?.addPath(bgPath); ctx?.fillPath()

        guard !samples.isEmpty else { return }

        let count = 60
        let barW = bounds.width / CGFloat(count)
        let fill = NSColor.controlAccentColor.cgColor
        ctx?.setFillColor(fill)

        let startIdx = max(0, samples.count - count)
        for (i, idx) in (startIdx..<samples.count).enumerated() {
            let v = CGFloat(samples[idx] / 100.0)
            let h = max(1, bounds.height * v)
            let x = CGFloat(i) * barW
            let y = bounds.height - h
            let r = CGRect(x: x + 0.5, y: y, width: max(1, barW - 1), height: h)
            ctx?.fill(r)
        }
    }
}
