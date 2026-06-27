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
        let screenFrame = screen.frame
        let visible = screen.visibleFrame
        let size = NSSize(width: config.window.width, height: config.window.height)
        let margin = config.window.margin
        let bottomDockBandHeight = max(0, visible.minY - screenFrame.minY)
        let leftDockBandWidth = max(0, visible.minX - screenFrame.minX)
        let rightDockBandWidth = max(0, screenFrame.maxX - visible.maxX)

        let x: CGFloat
        let y: CGFloat

        if bottomDockBandHeight > 24 {
            x = xForBottomDockSlot(slot, screenFrame: screenFrame, size: size, margin: margin)
            y = screenFrame.minY + max(6, (bottomDockBandHeight - size.height) / 2)
        } else if leftDockBandWidth > 24 || rightDockBandWidth > 24 {
            x = xForSideDockSlot(slot, visible: visible, size: size, margin: margin)
            y = visible.minY + margin
        } else {
            x = xForSideDockSlot(slot, visible: visible, size: size, margin: margin)
            y = visible.minY + margin
        }

        return NSRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height)
    }

    private func xForBottomDockSlot(
        _ slot: HUDSlot,
        screenFrame: NSRect,
        size: NSSize,
        margin: CGFloat
    ) -> CGFloat {
        switch slot.anchor {
        case .dockLeft:
            return screenFrame.minX + margin
        case .dockRight:
            return screenFrame.maxX - margin - size.width
        }
    }

    private func xForSideDockSlot(
        _ slot: HUDSlot,
        visible: NSRect,
        size: NSSize,
        margin: CGFloat
    ) -> CGFloat {
        switch slot.anchor {
        case .dockLeft:
            return visible.minX + margin
        case .dockRight:
            return visible.maxX - margin - size.width
        }
    }
}
