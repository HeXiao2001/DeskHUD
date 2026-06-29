import AppKit
import DeskHUDCore

@MainActor
enum HUDDisplayResolver {
    static func screens(for config: HUDConfig) -> [NSScreen] {
        switch config.displays {
        case .all:
            return NSScreen.screens
        case .primary, .main:
            return primaryScreen()
        case .mouse:
            return mouseScreen()
        case .fixed:
            return fixedScreen(config: config) ?? primaryScreen()
        }
    }

    static func primaryScreen() -> [NSScreen] {
        // Screen with menu bar is typically the primary
        if let menuBarScreen = NSScreen.screens.first(where: { $0.frame.minY == 0 && $0.frame.minX == 0 }) {
            return [menuBarScreen]
        }
        return NSScreen.screens.first.map { [$0] } ?? []
    }

    static func mouseScreen() -> [NSScreen] {
        let mouse = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) {
            return [screen]
        }
        return primaryScreen()
    }

    static func fixedScreen(config: HUDConfig) -> [NSScreen]? {
        guard let id = config.fixedDisplayID else { return nil }
        let targetID = CGDirectDisplayID(id)
        for screen in NSScreen.screens {
            if let screenID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32,
               screenID == targetID {
                return [screen]
            }
        }
        return nil
    }

    /// Human-readable display names for Settings UI
    static func displayName(for screen: NSScreen) -> String {
        let name = screen.localizedName
        let size = screen.frame.size
        return "\(name) — \(Int(size.width))×\(Int(size.height))"
    }
}
