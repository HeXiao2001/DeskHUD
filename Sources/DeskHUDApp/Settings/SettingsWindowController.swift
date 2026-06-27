import AppKit
import DeskHUDCore
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    private var currentConfig: HUDConfig
    var onConfigChanged: ((HUDConfig) -> Void)?

    init(config: HUDConfig) {
        self.currentConfig = config

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 370),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DeskHUD Settings"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        window.contentView = makeHostingView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeHostingView() -> NSHostingView<SettingsView> {
        let view = SettingsView(config: currentConfig) { [weak self] newConfig in
            self?.currentConfig = newConfig
            self?.onConfigChanged?(newConfig)
        }
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame.size = NSSize(width: 450, height: 370)
        return hostingView
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Called when the config changes externally (e.g. file reload).
    /// Replaces the view tree so SwiftUI picks up the fresh config.
    func updateConfig(_ newConfig: HUDConfig) {
        currentConfig = newConfig
        window?.contentView = makeHostingView()
    }
}
