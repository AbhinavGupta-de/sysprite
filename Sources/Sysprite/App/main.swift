import AppKit

let args = CommandLine.arguments.dropFirst()
switch args.first {
case "stats":
    CLI.runStats(Array(args.dropFirst())); exit(0)
case "enable-login":
    exit(CLI.setLoginItem(true))
case "disable-login":
    exit(CLI.setLoginItem(false))
case "login-status":
    exit(CLI.printLoginStatus())
default:
    break
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
