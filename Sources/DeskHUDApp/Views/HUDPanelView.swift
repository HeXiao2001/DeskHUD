import DeskHUDCore
import SwiftUI

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

    private var presentation: HUDPresentation {
        switch slot.anchor {
        case .dockLeft:  return config.window.leftPresentation
        case .dockRight: return config.window.rightPresentation
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = currentSection?.title, !title.isEmpty {
                sectionTitle(title)
            }
            if let section = currentSection {
                switch presentation {
                case .pagerRail:
                    pagerContent(section: section)
                case .minimal:
                    minimalContent(section: section)
                case .stack:
                    stackContent(section: section)
                }
            }
        }
        .padding(padding)
        .frame(width: width, height: height, alignment: .topLeading)
        .clipped()
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: config.window.cornerRadius, style: .continuous))
        .overlay(panelBorder)
        .shadow(color: textShadowColor, radius: textShadowRadius, x: 0, y: 1)
    }

    // MARK: - Minimal (1 item, no rail)

    private func minimalContent(section: HUDSection) -> some View {
        let items = section.items
        guard !items.isEmpty else { return AnyView(EmptyView()) }
        let idx = scrollOffset % max(1, items.count)

        return AnyView(
            HUDItemView(item: items[idx], config: config)
                .id(idx)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.35), value: scrollOffset)
        )
    }

    // MARK: - Pager (1 item + rail)

    private func pagerContent(section: HUDSection) -> some View {
        let items = section.items
        guard !items.isEmpty else { return AnyView(EmptyView()) }
        let idx = scrollOffset % max(1, items.count)

        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                HUDItemView(item: items[idx], config: config)
                    .id(idx)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.35), value: scrollOffset)
                Spacer(minLength: 0)
                TimelineRailView(section: section, activeIndex: idx, config: config)
            }
        )
    }

    // MARK: - Stack (right panel: 2 items)

    private func stackContent(section: HUDSection) -> some View {
        VStack(alignment: .leading, spacing: itemSpacing) {
            ForEach(visibleItems(from: section)) { item in
                HUDItemView(item: item, config: config)
            }
        }
        .id(scrollOffset)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.35), value: scrollOffset)
    }

    private func visibleItems(from section: HUDSection) -> [HUDItem] {
        guard !section.items.isEmpty else { return [] }
        let count = section.items.count
        var result: [HUDItem] = []
        for i in 0 ..< 2 {
            let idx = (scrollOffset + i) % count
            result.append(section.items[idx])
        }
        return result
    }

    // MARK: - Shared

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

    private var padding: CGFloat {
        switch config.window.contentDensity {
        case .compact: 10; case .comfortable: 12; case .spacious: 16
        }
    }

    private var itemSpacing: CGFloat {
        switch config.window.contentDensity {
        case .compact: 5; case .comfortable: 7; case .spacious: 9
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
        case .glass: Color.clear.background(.ultraThinMaterial)
        case .clear: Color.clear
        case .dark:  Color.black.opacity(config.window.opacity)
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
