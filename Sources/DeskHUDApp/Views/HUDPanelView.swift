import DeskHUDCore
import SwiftUI

struct HUDPanelView: View {
    let slot: HUDSlot
    let config: HUDConfig
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(slot.items.prefix(3)) { item in
                HUDItemView(item: item, config: config)
            }
            Spacer(minLength: 0)
        }
        .padding(padding)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: config.window.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: config.window.cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var padding: CGFloat {
        switch config.window.contentDensity {
        case .compact: 10
        case .comfortable: 12
        case .spacious: 16
        }
    }

    private var spacing: CGFloat {
        switch config.window.contentDensity {
        case .compact: 6
        case .comfortable: 8
        case .spacious: 10
        }
    }

    private var panelBackground: some View {
        ZStack {
            Color.black.opacity(config.window.opacity)
            if config.effectProfile != .low {
                LinearGradient(
                    colors: [Color.white.opacity(0.10), Color.cyan.opacity(0.08), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

private struct HUDItemView: View {
    let item: HUDItem
    let config: HUDConfig

    var body: some View {
        switch item.type {
        case .text:
            textBlock
        case .metric:
            metricBlock
        case .progress:
            progressBlock
        case .list:
            listBlock
        case .status:
            statusBlock
        }
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            title
            optionalText(item.subtitle, style: .secondary)
        }
    }

    private var metricBlock: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            title
            if let value = item.value {
                Text(value, format: .number.precision(.fractionLength(0...1)))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                optionalText(item.unit, style: .secondary)
            }
        }
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                title
                Spacer(minLength: 8)
                optionalText(item.label, style: .secondary)
            }
            ProgressView(value: clampedProgress)
                .progressViewStyle(.linear)
                .tint(progressTint)
        }
    }

    private var listBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            title
            ForEach(Array((item.lines ?? []).prefix(config.window.maxLines).enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
                    .lineLimit(1)
            }
        }
    }

    private var statusBlock: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            title
            optionalText(item.label, style: .secondary)
        }
    }

    private var title: some View {
        Text(item.title ?? item.kind ?? item.id)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
    }

    @ViewBuilder
    private func optionalText(_ text: String?, style: TextStyle) -> some View {
        if let text, !text.isEmpty {
            Text(text)
                .font(.system(size: style == .secondary ? 11 : 12, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(style == .secondary ? 0.62 : 0.76))
                .lineLimit(1)
        }
    }

    private var clampedProgress: Double {
        min(max(item.value ?? 0, 0), 1)
    }

    private var progressTint: Color {
        switch config.effectProfile {
        case .low: .white.opacity(0.82)
        case .medium: .cyan
        case .high: .mint
        }
    }

    private var statusColor: Color {
        switch item.state?.lowercased() {
        case "ok", "ready", "done": .green
        case "running", "active", "working": .cyan
        case "warning", "blocked": .yellow
        case "error", "failed": .red
        default: .white.opacity(0.7)
        }
    }
}

private enum TextStyle {
    case primary
    case secondary
}
