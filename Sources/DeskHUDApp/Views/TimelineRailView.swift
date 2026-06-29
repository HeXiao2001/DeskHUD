import DeskHUDCore
import SwiftUI

/// Bottom rail of small dots showing position in the item queue.
/// Max 5 visible nodes; overflow shows "+N".
struct TimelineRailView: View {
    let section: HUDSection
    let activeIndex: Int
    let config: HUDConfig

    private let maxNodes = 5

    var body: some View {
        let count = section.items.count
        guard count > 0 else { return AnyView(EmptyView()) }

        let active = activeIndex % max(1, count)
        let visibleCount = min(count, maxNodes)

        return AnyView(
            HStack(spacing: 3) {
                ForEach(0 ..< visibleCount, id: \.self) { i in
                    Circle()
                        .fill(nodeColor(i == active, item: section.items[i]))
                        .frame(width: i == active ? 5 : 3,
                               height: i == active ? 5 : 3)
                }
                if count > maxNodes {
                    Text("+\(count - maxNodes)")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.top, 2)
        )
    }

    private func nodeColor(_ isActive: Bool, item: HUDItem) -> Color {
        if isActive { return .white.opacity(0.7) }
        let s = item.state?.lowercased() ?? ""
        if s == "running" || s == "working" || s == "thinking" { return .cyan.opacity(0.5) }
        if s == "done" || s == "ok" { return .green.opacity(0.5) }
        if s == "blocked" || s == "warning" { return .yellow.opacity(0.5) }
        if s == "error" || s == "failed" { return .red.opacity(0.5) }
        return .white.opacity(0.2)
    }
}
