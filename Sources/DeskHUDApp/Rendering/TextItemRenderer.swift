import DeskHUDCore
import SwiftUI

final class TextItemRenderer: HUDItemRenderer {
    let itemType: HUDItemType = .text

    @MainActor
    func body(for item: HUDItem, config: HUDConfig) -> AnyView {
        AnyView(TextItemBody(item: item, config: config))
    }
}

private struct TextItemBody: View {
    let item: HUDItem
    let config: HUDConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                HUDTypography.title(for: item, opacity: config.window.textOpacity, fontSize: config.window.fontSize)
                Spacer(minLength: 4)
                if let time = item.time, !time.isEmpty {
                    Text(time)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(config.window.textOpacity * 0.5))
                        .lineLimit(1)
                }
            }
            HUDTypography.optional(item.subtitle, style: .secondary, opacity: config.window.textOpacity, fontSize: config.window.fontSize)
        }
    }
}
