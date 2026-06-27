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
        HStack(spacing: 4) {
            HUDTypography.title(for: item)
                .foregroundStyle(HUDTypography.statusColor(for: item.state))
            if let label = item.label, !label.isEmpty {
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
        }
    }
}
