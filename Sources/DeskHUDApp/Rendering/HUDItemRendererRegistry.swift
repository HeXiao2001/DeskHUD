import DeskHUDCore

/// Thread-safe registry mapping HUDItemType values to renderer instances.
/// Populated once at app launch; queried during every HUD render pass.
@MainActor
public final class HUDItemRendererRegistry: Sendable {
    public static let shared = HUDItemRendererRegistry()

    private var renderers: [HUDItemType: any HUDItemRenderer] = [:]

    /// Fallback for unknown types (future-proofing). Nil → EmptyView.
    public var defaultRenderer: (any HUDItemRenderer)?

    public init() {}

    public func register(_ renderer: any HUDItemRenderer) {
        renderers[renderer.itemType] = renderer
    }

    public func renderer(for type: HUDItemType) -> (any HUDItemRenderer)? {
        renderers[type]
    }
}
