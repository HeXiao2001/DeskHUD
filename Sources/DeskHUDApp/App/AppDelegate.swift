import AppKit
import ApplicationServices
import DeskHUDCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let windowManager = HUDWindowManager()
    private let loader = HUDFileLoader()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        requestAccessibilityTrustIfNeeded()
        installMenuBarItem()
        renderInitialHUD()
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowManager.closeAll()
    }

    private func renderInitialHUD() {
        let configURL = resourceURL(named: "config", extension: "json")
        let hudURL = resourceURL(named: "hud", extension: "json")

        let config = configURL.flatMap { try? loader.loadConfig(from: $0).get() } ?? HUDConfig()
        let document = hudURL.flatMap { try? loader.loadHUD(from: $0).get() } ?? .empty
        windowManager.show(document: document, config: config)
    }

    private func resourceURL(named name: String, extension fileExtension: String) -> URL? {
        if let bundled = Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Examples") {
            return bundled
        }
        let fallback = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Examples")
            .appendingPathComponent("\(name).\(fileExtension)")
        return FileManager.default.fileExists(atPath: fallback.path) ? fallback : nil
    }

    private func installMenuBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "DeskHUD"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Reload", action: #selector(reloadHUD), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    private func requestAccessibilityTrustIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    @objc private func reloadHUD() {
        renderInitialHUD()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
