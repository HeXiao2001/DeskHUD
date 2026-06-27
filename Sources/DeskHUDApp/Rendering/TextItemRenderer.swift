import DeskHUDCore
import SwiftUI

final class TextItemRenderer: HUDItemRenderer {
    let itemType: HUDItemType = .text

    @MainActor
    func body(for item: HUDItem, config: HUDConfig) -> AnyView {
        AnyView(TextItemBody(item: item))
    }
}

private struct TextItemBody: View {
    let item: HUDItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                HUDTypography.title(for: item)
                Spacer(minLength: 4)
                if let time = item.time, !time.isEmpty {
                    Text(time)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }
            }
            HUDTypography.optional(item.subtitle, style: .secondary)
        }
    }
}
