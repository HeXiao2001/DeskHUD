import DeskHUDCore
import SwiftUI

final class ListItemRenderer: HUDItemRenderer {
    let itemType: HUDItemType = .list

    @MainActor
    func body(for item: HUDItem, config: HUDConfig) -> AnyView {
        AnyView(ListItemBody(item: item, config: config))
    }
}

private struct ListItemBody: View {
    let item: HUDItem
    let config: HUDConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HUDTypography.title(for: item, opacity: config.window.textOpacity)
            ForEach(
                Array((item.lines ?? []).prefix(config.window.maxLines).enumerated()),
                id: \.offset
            ) { _, line in
                Text(line)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(config.window.textOpacity * 0.7))
                    .lineLimit(1)
            }
        }
    }
}
