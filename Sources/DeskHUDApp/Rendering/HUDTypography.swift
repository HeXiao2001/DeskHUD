import DeskHUDCore
import SwiftUI

/// Shared typography and color primitives used by HUD item renderers.
enum HUDTypography {
    enum TextStyle {
        case primary
        case secondary
    }

    static func title(for item: HUDItem, opacity: Double = 0.85, fontSize: Double = 13) -> some View {
        Text(item.title ?? item.kind ?? item.id)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(opacity))
            .lineLimit(1)
    }

    @ViewBuilder
    static func optional(_ text: String?, style: TextStyle, opacity: Double = 0.85, fontSize: Double = 13) -> some View {
        if let text, !text.isEmpty {
            Text(text)
                .font(.system(size: style == .secondary ? fontSize - 2 : fontSize - 1,
                              weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(
                    style == .secondary ? opacity * 0.65 : opacity * 0.8
                ))
                .lineLimit(1)
        }
    }

    static func statusColor(for state: String?) -> Color {
        switch state?.lowercased() {
        case "ok", "ready", "done":    .green
        case "running", "active", "working", "thinking": .cyan
        case "warning", "blocked":     .yellow
        case "error", "failed":        .red
        case "idle", "pending", "todo": .white.opacity(0.35)
        default:                        .white.opacity(0.7)
        }
    }

    static func progressTint(for profile: EffectProfile) -> Color {
        switch profile {
        case .low: .white.opacity(0.82)
        case .medium: .cyan
        case .high: .mint
        }
    }
}
