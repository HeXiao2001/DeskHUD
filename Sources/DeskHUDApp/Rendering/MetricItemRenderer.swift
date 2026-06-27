import DeskHUDCore
import SwiftUI

final class MetricItemRenderer: HUDItemRenderer {
    let itemType: HUDItemType = .metric

    @MainActor
    func body(for item: HUDItem, config: HUDConfig) -> AnyView {
        AnyView(MetricItemBody(item: item))
    }
}

private struct MetricItemBody: View {
    let item: HUDItem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            HUDTypography.title(for: item)
            if let value = item.value {
                Text(value, format: .number.precision(.fractionLength(0...1)))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                HUDTypography.optional(item.unit, style: .secondary)
            }
        }
    }
}
