import AppKit
import DeskHUDCore
import SwiftUI

struct SettingsView: View {
    @State private var config: HUDConfig
    let onConfigChanged: (HUDConfig) -> Void

    init(config: HUDConfig, onConfigChanged: @escaping (HUDConfig) -> Void) {
        _config = State(initialValue: config)
        self.onConfigChanged = onConfigChanged
    }

    var body: some View {
        TabView {
            AppearancePane(config: $config)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
                .frame(width: 380, height: 280)
            LayoutPane(config: $config)
                .tabItem { Label("Layout", systemImage: "rectangle.resize") }
                .frame(width: 380, height: 280)
            BehaviorPane(config: $config)
                .tabItem { Label("Behavior", systemImage: "gearshape") }
                .frame(width: 380, height: 280)
        }
        .frame(width: 420, height: 330)
        .padding(.top, 8)
        .scenePadding()
        .onChange(of: config) { _, newValue in
            onConfigChanged(newValue)
        }
    }
}

// MARK: - Appearance

private struct AppearancePane: View {
    @Binding var config: HUDConfig

    var body: some View {
        Form {
            Picker("Background:", selection: $config.backgroundStyle) {
                Text("Liquid Glass").tag(DeskHUDCore.BackgroundStyle.glass)
                Text("Clear (No BG)").tag(DeskHUDCore.BackgroundStyle.clear)
                Text("Dark").tag(DeskHUDCore.BackgroundStyle.dark)
            }

            Picker("Effect:", selection: $config.effectProfile) {
                Text("Low").tag(EffectProfile.low)
                Text("Medium").tag(EffectProfile.medium)
                Text("High").tag(EffectProfile.high)
            }

            Picker("Density:", selection: $config.window.contentDensity) {
                Text("Compact").tag(ContentDensity.compact)
                Text("Comfortable").tag(ContentDensity.comfortable)
                Text("Spacious").tag(ContentDensity.spacious)
            }

            Slider(value: $config.window.opacity, in: 0.3 ... 1.0) {
                Text("Opacity: \(Int(config.window.opacity * 100))%")
            }
        }
    }
}

// MARK: - Layout

private struct LayoutPane: View {
    @Binding var config: HUDConfig

    var body: some View {
        Form {
            LabeledContent("Width (0=auto):") {
                TextField("", value: $config.window.width, format: .number)
                    .frame(width: 80)
                Stepper("", value: $config.window.width, in: 0 ... 600, step: 4)
            }

            LabeledContent("Height:") {
                TextField("", value: $config.window.height, format: .number)
                    .frame(width: 80)
                Stepper("", value: $config.window.height, in: 40 ... 200, step: 2)
            }

            LabeledContent("Margin:") {
                TextField("", value: $config.window.margin, format: .number)
                    .frame(width: 80)
                Stepper("", value: $config.window.margin, in: 2 ... 40, step: 2)
            }

            LabeledContent("Corner Radius:") {
                TextField("", value: $config.window.cornerRadius, format: .number)
                    .frame(width: 80)
                Stepper("", value: $config.window.cornerRadius, in: 0 ... 32, step: 2)
            }

            LabeledContent("Max Lines:") {
                TextField("", value: Binding(
                    get: { Double(config.window.maxLines) },
                    set: { config.window.maxLines = Int($0) }
                ), format: .number)
                .frame(width: 80)
                Stepper("", value: Binding(
                    get: { Double(config.window.maxLines) },
                    set: { config.window.maxLines = Int($0) }
                ), in: 1 ... 8, step: 1)
            }
        }
    }
}

// MARK: - Behavior

private struct BehaviorPane: View {
    @Binding var config: HUDConfig

    var body: some View {
        Form {
            Picker("Fullscreen:", selection: $config.fullscreenMode) {
                Text("Overlay").tag(FullscreenMode.overlay)
                Text("Desktop Only").tag(FullscreenMode.desktopOnly)
            }

            Picker("Displays:", selection: $config.displays) {
                Text("All Displays").tag(DisplayMode.all)
                Text("Main Only").tag(DisplayMode.main)
            }

            LabeledContent("Scroll speed:") {
                Stepper("\(Int(config.window.scrollIntervalSeconds))s per page",
                        value: Binding(
                            get: { config.window.scrollIntervalSeconds },
                            set: { config.window.scrollIntervalSeconds = $0 }
                        ), in: 2 ... 15, step: 1)
            }

            Toggle("Calendar Events", isOn: $config.calendarEvents)

            LabeledContent("Watch Dir:") {
                HStack(spacing: 4) {
                    TextField("OneDrive or custom path", text: Binding(
                        get: { config.watchDirectory ?? "" },
                        set: { config.watchDirectory = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minWidth: 200)
                    Button("Choose...") {
                        browseWatchDir()
                    }
                }
            }

            Toggle("Calendar Events", isOn: $config.calendarEvents)

            Toggle("Debug Logging", isOn: $config.debugLogging)
        }
    }

    private func browseWatchDir() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.prompt = "Select Watch Directory"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        config.watchDirectory = url.path
    }
}
