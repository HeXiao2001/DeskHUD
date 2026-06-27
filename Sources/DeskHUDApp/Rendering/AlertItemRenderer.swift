import DeskHUDCore
import SwiftUI

/// Renders urgent temporary states: errors, failures, blocked items.
/// Uses state-driven color for the title; subtitle for action context.
final class AlertItemRenderer: HUDItemRenderer {
    let itemType: HUDItemType = .alert

    @MainActor
    func body(for item: HUDItem, config: HUDConfig) -> AnyView {
        AnyView(AlertItemBody(item: item, config: config))
    }
}

private struct AlertItemBody: View {
    let item: HUDItem
    let config: HUDConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HUDTypography.title(for: item,
                                opacity: config.window.textOpacity,
                                fontSize: config.window.fontSize)
                .fontWeight(.bold)
                .foregroundStyle(accentColor)
            if let subtitle = item.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: config.window.fontSize - 2,
                                  weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(config.window.textOpacity * 0.8))
                    .lineLimit(1)
            }
        }
    }

    private var accentColor: Color {
        switch item.state?.lowercased() {
        case "error", "failed":  .red
        case "warning", "blocked": .yellow
        default:                  .orange
        }
    }
}
