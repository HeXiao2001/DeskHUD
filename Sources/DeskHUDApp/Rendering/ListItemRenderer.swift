import DeskHUDCore
import SwiftUI

final class ListItemRenderer: HUDItemRenderer {
    let itemType: HUDItemType = .list

    @MainActor
    func body(for item: HUDItem, config: HUDConfig) -> AnyView {
        AnyView(ListItemBody(item: item, maxLines: config.window.maxLines))
    }
}

private struct ListItemBody: View {
    let item: HUDItem
    let maxLines: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HUDTypography.title(for: item)
            ForEach(
                Array((item.lines ?? []).prefix(maxLines).enumerated()),
                id: \.offset
            ) { _, line in
                Text(line)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
                    .lineLimit(1)
            }
        }
    }
}
