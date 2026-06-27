import DeskHUDCore
import SwiftUI

final class StatusItemRenderer: HUDItemRenderer {
    let itemType: HUDItemType = .status

    @MainActor
    func body(for item: HUDItem, config: HUDConfig) -> AnyView {
        AnyView(StatusItemBody(item: item))
    }
}

private struct StatusItemBody: View {
    let item: HUDItem

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(HUDTypography.statusColor(for: item.state))
                .frame(width: 7, height: 7)
            HUDTypography.title(for: item)
            HUDTypography.optional(item.label, style: .secondary)
        }
    }
}
