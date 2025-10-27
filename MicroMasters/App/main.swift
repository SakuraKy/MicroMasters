import AppKit

private let appDelegate = AppDelegate()

_ = {
    let app = NSApplication.shared
    app.delegate = appDelegate
    return ()
}()

NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
