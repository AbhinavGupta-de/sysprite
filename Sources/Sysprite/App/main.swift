import AppKit

let args = CommandLine.arguments.dropFirst()
if args.first == "stats" {
    CLI.runStats(Array(args.dropFirst()))
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
