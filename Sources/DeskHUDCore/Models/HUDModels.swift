import Foundation

public struct HUDConfig: Codable, Equatable, Sendable {
    public var version: Int
    public var effectProfile: EffectProfile
    public var fullscreenMode: FullscreenMode
    public var displays: DisplayMode
    public var backgroundStyle: BackgroundStyle
    public var window: HUDWindowConfig
    public var calendarEvents: Bool
    public var watchDirectory: String?
    public var debugLogging: Bool

    public init(
        version: Int = 1,
        effectProfile: EffectProfile = .low,
        fullscreenMode: FullscreenMode = .overlay,
        displays: DisplayMode = .all,
        backgroundStyle: BackgroundStyle = .clear,
        calendarEvents: Bool = false,
        watchDirectory: String? = nil,
        window: HUDWindowConfig = HUDWindowConfig(),
        debugLogging: Bool = true
    ) {
        self.version = version
        self.effectProfile = effectProfile
        self.fullscreenMode = fullscreenMode
        self.displays = displays
        self.backgroundStyle = backgroundStyle
        self.calendarEvents = calendarEvents
        self.watchDirectory = watchDirectory
        self.window = window
        self.debugLogging = debugLogging
    }
}

public enum FullscreenMode: String, Codable, CaseIterable, Sendable {
    case overlay
    case desktopOnly
}

public enum BackgroundStyle: String, Codable, CaseIterable, Sendable {
    case glass  // System Liquid Glass — matches Dock appearance
    case clear  // No background, only text and glyphs
    case dark   // Dark semi-transparent overlay (classic HUD)
}

public enum DisplayMode: String, Codable, CaseIterable, Sendable {
    case all
    case main
}

public struct HUDWindowConfig: Codable, Equatable, Sendable {
    public var width: Double
    public var height: Double
    public var margin: Double
    public var cornerRadius: Double
    public var opacity: Double
    public var maxLines: Int
    public var contentDensity: ContentDensity
    public var scrollIntervalSeconds: Double

    public init(
        width: Double = 0,   // 0 = auto-fill available space
        height: Double = 82,
        margin: Double = 18,
        cornerRadius: Double = 14,
        opacity: Double = 0.82,
        maxLines: Int = 2,
        contentDensity: ContentDensity = .comfortable,
        scrollIntervalSeconds: Double = 4
    ) {
        self.width = width
        self.height = height
        self.margin = margin
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.maxLines = maxLines
        self.contentDensity = contentDensity
        self.scrollIntervalSeconds = scrollIntervalSeconds
    }
}

public enum ContentDensity: String, Codable, Sendable {
    case compact
    case comfortable
    case spacious
}

public struct HUDDocument: Codable, Equatable, Sendable {
    public var version: Int
    public var slots: [HUDSlot]

    public init(version: Int = 1, slots: [HUDSlot]) {
        self.version = version
        self.slots = slots
    }
}

public struct HUDSection: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String?
    public var items: [HUDItem]

    public init(id: String, title: String? = nil, items: [HUDItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

public struct HUDSlot: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var anchor: HUDAnchor
    public var rotation: HUDRotation
    public var sections: [HUDSection]?
    public var items: [HUDItem]

    public init(
        id: String,
        anchor: HUDAnchor,
        rotation: HUDRotation = HUDRotation(),
        sections: [HUDSection]? = nil,
        items: [HUDItem]
    ) {
        self.id = id
        self.anchor = anchor
        self.rotation = rotation
        self.sections = sections
        self.items = items
    }

    /// Normalised access: always returns sections, synthesising a single
    /// unnamed section from flat `items` when `sections` is nil or empty.
    public var resolvedSections: [HUDSection] {
        if let sections, !sections.isEmpty { return sections }
        return [HUDSection(id: "default", title: nil, items: items)]
    }
}

public enum HUDAnchor: String, Codable, Sendable {
    case dockLeft = "dock.left"
    case dockRight = "dock.right"
}

public struct HUDRotation: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var intervalSeconds: Double

    public init(enabled: Bool = false, intervalSeconds: Double = 45) {
        self.enabled = enabled
        self.intervalSeconds = intervalSeconds
    }
}

public struct HUDItem: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var type: HUDItemType
    public var kind: String?
    public var title: String?
    public var subtitle: String?
    public var label: String?
    public var value: Double?
    public var unit: String?
    public var state: String?
    public var time: String?
    public var lines: [String]?

    public init(
        id: String,
        type: HUDItemType,
        kind: String? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        label: String? = nil,
        value: Double? = nil,
        unit: String? = nil,
        state: String? = nil,
        time: String? = nil,
        lines: [String]? = nil
    ) {
        self.id = id
        self.type = type
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.label = label
        self.value = value
        self.unit = unit
        self.state = state
        self.time = time
        self.lines = lines
    }
}

public enum HUDItemType: String, Codable, Sendable {
    case text
    case metric
    case progress
    case list
    case status
}

/// Lightweight payload for a single slot file (e.g. `hud_leftDock.json`).
/// Avoids the full HUDDocument envelope so writers only touch their slot.
public struct HUDSlotContent: Codable, Sendable {
    public var sections: [HUDSection]?
    public var items: [HUDItem]

    public init(sections: [HUDSection]? = nil, items: [HUDItem] = []) {
        self.sections = sections
        self.items = items
    }
}

public extension HUDDocument {
    static let empty = HUDDocument(version: 1, slots: [
        HUDSlot(id: "leftDock", anchor: .dockLeft, items: []),
        HUDSlot(id: "rightDock", anchor: .dockRight, items: [])
    ])
}
