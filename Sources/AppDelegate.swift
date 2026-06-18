import Cocoa
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var onboardingWindow: NSWindow?
    let updater = UpdateChecker()
    let settings = AppSettings()
    private var bundleWatcher: DispatchSourceFileSystemObject?

    func applicationDidFinishLaunching(_ notification: Notification) {
        startBundleWatcher()
        popover = NSPopover()
        popover.contentSize = NSSize(width: 860, height: 600)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(updater)
                .environmentObject(settings)
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let bundleURL = Bundle.main.resourceURL?.appendingPathComponent("menubar_template@2x.png")
            if let url = bundleURL, let img = NSImage(contentsOf: url) {
                img.isTemplate = true
                img.size = NSSize(width: 18, height: 18)
                button.image = img
            } else {
                let sf = NSImage(systemSymbolName: "clock.badge.xmark", accessibilityDescription: "TimeCleaner")
                sf?.isTemplate = true
                button.image = sf
            }
            button.action = #selector(togglePopover)
            button.target = self
        }

        updater.checkForUpdates()
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showOnboardingIfNeeded() {
        let hosting = NSHostingController(rootView: OnboardingView {
            self.onboardingWindow?.close()
            self.onboardingWindow = nil
        })
        let win = NSWindow(contentViewController: hosting)
        win.styleMask = [.titled, .closable, .fullSizeContentView]
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isMovableByWindowBackground = true
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = win
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showOnboardingIfNeeded()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func startBundleWatcher() {
        let bundlePath = Bundle.main.bundlePath
        let fd = open(bundlePath, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .delete,
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.uninstallAndQuit()
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        bundleWatcher = source
    }

    private func uninstallAndQuit() {
        let plist = NSHomeDirectory() + "/Library/LaunchAgents/com.timecleaner.app.plist"
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["unload", plist]
        try? task.run()
        task.waitUntilExit()
        try? FileManager.default.removeItem(atPath: plist)
        NSApp.terminate(nil)
    }
}
