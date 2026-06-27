import DeskHUDCore
import SwiftUI

final class ProgressItemRenderer: HUDItemRenderer {
    let itemType: HUDItemType = .progress

    @MainActor
    func body(for item: HUDItem, config: HUDConfig) -> AnyView {
        AnyView(ProgressItemBody(item: item, config: config))
    }
}

private struct ProgressItemBody: View {
    let item: HUDItem
    let config: HUDConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                HUDTypography.title(for: item, opacity: config.window.textOpacity)
                Spacer(minLength: 8)
                HUDTypography.optional(item.label, style: .secondary, opacity: config.window.textOpacity)
            }
            ProgressView(value: clamped)
                .progressViewStyle(.linear)
                .tint(HUDTypography.progressTint(for: config.effectProfile))
        }
    }

    private var clamped: Double {
        min(max(item.value ?? 0, 0), 1)
    }
}
