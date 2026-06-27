import DeskHUDCore
import SwiftUI

/// Renders a single HUDItem of a specific type.
/// Conformers are registered with `HUDItemRendererRegistry` at app launch.
/// To add a new item type: implement this protocol, then call
/// `HUDItemRendererRegistry.shared.register(YourRenderer())`.
public protocol HUDItemRenderer: AnyObject, Sendable {
    /// The HUDItemType this renderer handles.
    var itemType: HUDItemType { get }

    /// Produce the SwiftUI view for the given item and config.
    /// Called on the main actor during each render pass.
    @MainActor
    func body(for item: HUDItem, config: HUDConfig) -> AnyView
}
