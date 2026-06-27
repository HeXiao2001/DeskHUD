import AppKit
import DeskHUDCore
import SwiftUI

@MainActor
final class HUDWindowManager {
    private var windows: [NSWindow] = []

    func show(document: HUDDocument, config: HUDConfig) {
        closeAll()

        let screens = config.displays == .main ? [NSScreen.main].compactMap { $0 } : NSScreen.screens
        for screen in screens {
            for slot in document.slots {
                guard slot.anchor == .dockLeft || slot.anchor == .dockRight else { continue }
                let frame = frameForSlot(slot, on: screen, config: config)
                let view = HUDPanelView(slot: slot, config: config)
                let hostingView = NSHostingView(rootView: view)
                hostingView.frame = NSRect(origin: .zero, size: frame.size)

                let window = NSWindow(
                    contentRect: frame,
                    styleMask: [.borderless],
                    backing: .buffered,
                    defer: false,
                    screen: screen
                )
                window.contentView = hostingView
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = false
                window.ignoresMouseEvents = true
                window.level = .floating
                window.collectionBehavior = collectionBehavior(for: config)
                window.isReleasedWhenClosed = false
                window.orderFrontRegardless()
                windows.append(window)
            }
        }
    }

    func closeAll() {
        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
    }

    private func collectionBehavior(for config: HUDConfig) -> NSWindow.CollectionBehavior {
        if config.fullscreenMode == .desktopOnly {
            return [.stationary, .ignoresCycle]
        }
        return [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    private func frameForSlot(_ slot: HUDSlot, on screen: NSScreen, config: HUDConfig) -> NSRect {
        let visible = screen.visibleFrame
        let size = NSSize(width: config.window.width, height: config.window.height)
        let x: CGFloat
        switch slot.anchor {
        case .dockLeft:
            x = visible.minX + config.window.margin
        case .dockRight:
            x = visible.maxX - config.window.margin - size.width
        }
        let y = visible.minY + config.window.margin
        return NSRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height)
    }
}
