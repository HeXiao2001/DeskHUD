import DeskHUDCore
import SwiftUI

// MARK: - Panel

struct HUDPanelView: View {
    let slot: HUDSlot
    let config: HUDConfig
    let width: CGFloat
    let height: CGFloat
    let sectionIndex: Int
    let scrollOffset: Int

    private var currentSection: HUDSection? {
        let sections = slot.resolvedSections
        guard sectionIndex < sections.count else { return nil }
        return sections[sectionIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section title
            if let title = currentSection?.title, !title.isEmpty {
                sectionTitle(title)
            }

            // Items — clipped to panel height with animated transitions
            if let section = currentSection {
                scrolledItems(section: section)
            }
        }
        .padding(padding)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: config.window.cornerRadius, style: .continuous))
        .overlay(panelBorder)
        .shadow(color: textShadowColor, radius: textShadowRadius, x: 0, y: 1)
        .clipped()
    }

    // MARK: - Section title

    private func sectionTitle(_ text: String) -> some View {
        HStack(spacing: 0) {
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Scrolled items

    private func scrolledItems(section: HUDSection) -> some View {
        VStack(alignment: .leading, spacing: itemSpacing) {
            ForEach(visibleItems(from: section)) { item in
                HUDItemView(item: item, config: config)
            }
            Spacer(minLength: 0)
        }
        .animation(.linear(duration: config.window.scrollIntervalSeconds), value: scrollOffset)
        .animation(.easeInOut(duration: 0.3), value: sectionIndex)
    }

    /// Returns up to `visibleCount` items starting at `scrollOffset`, wrapping around.
    private func visibleItems(from section: HUDSection) -> [HUDItem] {
        guard !section.items.isEmpty else { return [] }
        let count = section.items.count
        let maxVisible = maxVisibleItems()
        var result: [HUDItem] = []
        for i in 0 ..< maxVisible {
            let idx = (scrollOffset + i) % count
            result.append(section.items[idx])
        }
        return result
    }

    /// Estimate how many items fit in the remaining panel height.
    /// Always shows at least 2 items when available — compact text items fit.
    private func maxVisibleItems() -> Int {
        let titleOverhead: CGFloat = (currentSection?.title?.isEmpty == false ? 16 : 0)
        let available = height - padding * 2 - titleOverhead
        let perItem: CGFloat = itemSpacing + 18
        return max(2, Int(available / perItem))
    }

    // MARK: - Shared styling

    private var padding: CGFloat {
        switch config.window.contentDensity {
        case .compact: 10
        case .comfortable: 12
        case .spacious: 16
        }
    }

    private var itemSpacing: CGFloat {
        switch config.window.contentDensity {
        case .compact: 5
        case .comfortable: 7
        case .spacious: 9
        }
    }

    private var textShadowColor: Color {
        config.backgroundStyle == .clear ? .black.opacity(0.45) : .clear
    }

    private var textShadowRadius: CGFloat {
        config.backgroundStyle == .clear ? 3 : 0
    }

    @ViewBuilder
    private var panelBackground: some View {
        switch config.backgroundStyle {
        case .glass:
            Color.clear.background(.ultraThinMaterial)
        case .clear:
            Color.clear
        case .dark:
            Color.black.opacity(config.window.opacity)
        }
    }

    @ViewBuilder
    private var panelBorder: some View {
        if config.backgroundStyle != .clear {
            RoundedRectangle(cornerRadius: config.window.cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        }
    }
}

// MARK: - Item dispatch

private struct HUDItemView: View {
    let item: HUDItem
    let config: HUDConfig

    var body: some View {
        if let renderer = HUDItemRendererRegistry.shared.renderer(for: item.type) {
            renderer.body(for: item, config: config)
        } else if let fallback = HUDItemRendererRegistry.shared.defaultRenderer {
            fallback.body(for: item, config: config)
        }
    }
}
