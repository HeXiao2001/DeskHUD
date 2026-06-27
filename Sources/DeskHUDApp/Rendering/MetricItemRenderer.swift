import DeskHUDCore
import SwiftUI

final class MetricItemRenderer: HUDItemRenderer {
    let itemType: HUDItemType = .metric

    @MainActor
    func body(for item: HUDItem, config: HUDConfig) -> AnyView {
        AnyView(MetricItemBody(item: item, config: config))
    }
}

private struct MetricItemBody: View {
    let item: HUDItem
    let config: HUDConfig

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            HUDTypography.title(for: item, opacity: config.window.textOpacity)
            if let value = item.value {
                Text(value, format: .number.precision(.fractionLength(0...1)))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(config.window.textOpacity))
                HUDTypography.optional(item.unit, style: .secondary, opacity: config.window.textOpacity)
            }
        }
    }
}
