import AppKit
import ApplicationServices
import DeskHUDCore
import SwiftUI

@MainActor
final class HUDWindowManager {
    private struct ManagedWindow {
        let window: NSWindow
        let hostingView: NSHostingView<HUDPanelView>
        let slot: HUDSlot
        let screen: NSScreen
    }

    private var managedWindows: [ManagedWindow] = []
    private var mouseMonitor: Any?
    private var dockFollowTimer: Timer?
    private var isMouseNearBottomDock = false
    private var lastMouseLocation: NSPoint = .zero

    func show(document: HUDDocument, config: HUDConfig) {
        closeAll()

        let screens = config.displays == .main ? [NSScreen.main].compactMap { $0 } : NSScreen.screens
        for screen in screens {
            for slot in document.slots {
                guard slot.anchor == .dockLeft || slot.anchor == .dockRight else { continue }
                let frame = frameForSlot(slot, on: screen, config: config, mouseLocation: nil)
                let view = HUDPanelView(slot: slot, config: config, width: frame.width, height: frame.height)
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
                managedWindows.append(ManagedWindow(window: window, hostingView: hostingView, slot: slot, screen: screen))
            }
        }

        installMouseMonitor(config: config)
    }

    func closeAll() {
        stopDockFollowTimer()
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
            self.mouseMonitor = nil
        }

        for managedWindow in managedWindows {
            managedWindow.window.orderOut(nil)
            managedWindow.window.close()
        }
        managedWindows.removeAll()
    }

    private func collectionBehavior(for config: HUDConfig) -> NSWindow.CollectionBehavior {
        if config.fullscreenMode == .desktopOnly {
            return [.stationary, .ignoresCycle]
        }
        return [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    private func installMouseMonitor(config: HUDConfig) {
        if mouseMonitor != nil { return }
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            Task { @MainActor in
                self?.handleMouseMoved(config: config)
            }
        }
    }

    private func handleMouseMoved(config: HUDConfig) {
        lastMouseLocation = NSEvent.mouseLocation
        let shouldFollow = isInBottomDockTrackingArea(lastMouseLocation)
        if shouldFollow == isMouseNearBottomDock { return }

        isMouseNearBottomDock = shouldFollow
        if shouldFollow {
            startDockFollowTimer(config: config)
        } else {
            stopDockFollowTimer()
            updateFrames(config: config, mouseLocation: nil)
        }
    }

    private func startDockFollowTimer(config: HUDConfig) {
        guard dockFollowTimer == nil else { return }
        dockFollowTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 24.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.lastMouseLocation = NSEvent.mouseLocation
                if self.isInBottomDockTrackingArea(self.lastMouseLocation) {
                    self.updateFrames(config: config, mouseLocation: self.lastMouseLocation)
                } else {
                    self.isMouseNearBottomDock = false
                    self.stopDockFollowTimer()
                    self.updateFrames(config: config, mouseLocation: nil)
                }
            }
        }
    }

    private func stopDockFollowTimer() {
        dockFollowTimer?.invalidate()
        dockFollowTimer = nil
    }

    private func updateFrames(config: HUDConfig, mouseLocation: NSPoint?) {
        for managedWindow in managedWindows {
            let frame = frameForSlot(managedWindow.slot, on: managedWindow.screen, config: config, mouseLocation: mouseLocation)
            guard !managedWindow.window.frame.equalTo(frame) else { continue }
            managedWindow.hostingView.rootView = HUDPanelView(
                slot: managedWindow.slot,
                config: config,
                width: frame.width,
                height: frame.height
            )
            managedWindow.hostingView.frame = NSRect(origin: .zero, size: frame.size)
            managedWindow.window.setFrame(frame, display: true, animate: false)
        }
    }

    private func isInBottomDockTrackingArea(_ point: NSPoint) -> Bool {
        for screen in NSScreen.screens {
            let screenFrame = screen.frame
            let visible = screen.visibleFrame
            let bottomDockBandHeight = max(0, visible.minY - screenFrame.minY)
            guard bottomDockBandHeight > 24 else { continue }
            let trackingHeight = max(bottomDockBandHeight + 100, 180)
            let trackingRect = NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: screenFrame.width,
                height: trackingHeight
            )
            if trackingRect.contains(point) { return true }
        }
        return false
    }

    private func frameForSlot(
        _ slot: HUDSlot,
        on screen: NSScreen,
        config: HUDConfig,
        mouseLocation: NSPoint?
    ) -> NSRect {
        let screenFrame = screen.frame
        let visible = screen.visibleFrame
        let margin = config.window.margin
        let preferredSize = NSSize(width: config.window.width, height: config.window.height)
        let bottomDockBandHeight = max(0, visible.minY - screenFrame.minY)
        let leftDockBandWidth = max(0, visible.minX - screenFrame.minX)
        let rightDockBandWidth = max(0, screenFrame.maxX - visible.maxX)

        if bottomDockBandHeight > 24 {
            return frameForBottomDockSlot(
                slot,
                screenFrame: screenFrame,
                dockBandHeight: bottomDockBandHeight,
                preferredSize: preferredSize,
                margin: margin,
                mouseLocation: mouseLocation
            )
        } else if leftDockBandWidth > 24 || rightDockBandWidth > 24 {
            return frameForSideDockSlot(slot, visible: visible, preferredSize: preferredSize, margin: margin)
        } else {
            return frameForSideDockSlot(slot, visible: visible, preferredSize: preferredSize, margin: margin)
        }
    }

    private func frameForBottomDockSlot(
        _ slot: HUDSlot,
        screenFrame: NSRect,
        dockBandHeight: CGFloat,
        preferredSize: NSSize,
        margin: CGFloat,
        mouseLocation: NSPoint?
    ) -> NSRect {
        let dockExclusion = estimatedDockExclusionRect(
            in: screenFrame,
            dockBandHeight: dockBandHeight,
            mouseLocation: mouseLocation
        )
        let gap: CGFloat = 12
        let minWidth: CGFloat = 150
        let height = min(preferredSize.height, max(54, dockBandHeight - 10))
        let y = screenFrame.minY + max(5, (dockBandHeight - height) / 2)

        switch slot.anchor {
        case .dockLeft:
            let leftAvailable = max(0, dockExclusion.minX - screenFrame.minX - margin - gap)
            let width = min(preferredSize.width, max(minWidth, leftAvailable))
            let x = screenFrame.minX + margin
            return NSRect(x: x.rounded(), y: y.rounded(), width: width.rounded(), height: height.rounded())
        case .dockRight:
            let rightAvailable = max(0, screenFrame.maxX - dockExclusion.maxX - margin - gap)
            let width = min(preferredSize.width, max(minWidth, rightAvailable))
            let x = screenFrame.maxX - margin - width
            return NSRect(x: x.rounded(), y: y.rounded(), width: width.rounded(), height: height.rounded())
        }
    }

    private func estimatedDockExclusionRect(
        in screenFrame: NSRect,
        dockBandHeight: CGFloat,
        mouseLocation: NSPoint?
    ) -> NSRect {
        if let accessibilityRect = accessibilityDockRect(in: screenFrame) {
            return accessibilityRect.insetBy(dx: -10, dy: 0)
        }

        let baseWidth = min(screenFrame.width * 0.64, max(620, screenFrame.width * 0.48))
        var minX = screenFrame.midX - baseWidth / 2
        var maxX = screenFrame.midX + baseWidth / 2

        if let mouseLocation, screenFrame.contains(mouseLocation) {
            let magnifiedRadius = max(210, dockBandHeight * 2.4)
            minX = min(minX, mouseLocation.x - magnifiedRadius)
            maxX = max(maxX, mouseLocation.x + magnifiedRadius)
        }

        minX = max(screenFrame.minX, minX)
        maxX = min(screenFrame.maxX, maxX)
        return NSRect(x: minX, y: screenFrame.minY, width: max(0, maxX - minX), height: dockBandHeight)
    }

    private func accessibilityDockRect(in screenFrame: NSRect) -> NSRect? {
        guard AXIsProcessTrusted() else { return nil }
        guard let dockApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.dock" }) else {
            return nil
        }

        let dockElement = AXUIElementCreateApplication(dockApp.processIdentifier)
        guard let children = accessibilityChildren(of: dockElement) else { return nil }

        for child in children {
            guard accessibilityString(kAXRoleAttribute, of: child) == kAXListRole else { continue }
            guard accessibilityString(kAXOrientationAttribute, of: child) == kAXHorizontalOrientationValue else { continue }
            guard let topLeftRect = accessibilityRect(of: child) else { continue }
            let appKitRect = convertTopLeftRectToAppKit(topLeftRect, in: screenFrame)
            guard appKitRect.intersects(screenFrame) else { continue }
            return appKitRect.intersection(screenFrame)
        }

        return nil
    }

    private func accessibilityChildren(of element: AXUIElement) -> [AXUIElement]? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value)
        guard result == .success else { return nil }
        return value as? [AXUIElement]
    }

    private func accessibilityString(_ attribute: String, of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return value as? String
    }

    private func accessibilityRect(of element: AXUIElement) -> NSRect? {
        guard let position = accessibilityPoint(kAXPositionAttribute, of: element),
              let size = accessibilitySize(kAXSizeAttribute, of: element) else {
            return nil
        }
        return NSRect(origin: position, size: size)
    }

    private func accessibilityPoint(_ attribute: String, of element: AXUIElement) -> NSPoint? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgPoint else { return nil }
        var point = CGPoint.zero
        AXValueGetValue(axValue, .cgPoint, &point)
        return point
    }

    private func accessibilitySize(_ attribute: String, of element: AXUIElement) -> NSSize? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgSize else { return nil }
        var size = CGSize.zero
        AXValueGetValue(axValue, .cgSize, &size)
        return size
    }

    private func convertTopLeftRectToAppKit(_ rect: NSRect, in screenFrame: NSRect) -> NSRect {
        NSRect(
            x: rect.minX,
            y: screenFrame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    private func frameForSideDockSlot(
        _ slot: HUDSlot,
        visible: NSRect,
        preferredSize: NSSize,
        margin: CGFloat
    ) -> NSRect {
        let x: CGFloat
        switch slot.anchor {
        case .dockLeft:
            x = visible.minX + margin
        case .dockRight:
            x = visible.maxX - margin - preferredSize.width
        }
        let y = visible.minY + margin
        return NSRect(x: x.rounded(), y: y.rounded(), width: preferredSize.width, height: preferredSize.height)
    }
}
