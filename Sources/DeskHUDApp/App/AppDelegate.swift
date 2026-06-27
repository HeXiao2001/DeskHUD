import AppKit
import ApplicationServices
import DeskHUDCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let windowManager = HUDWindowManager()
    private let loader = HUDFileLoader()
    private var statusItem: NSStatusItem?
    private var currentConfig = HUDConfig()
    private var currentDocument = HUDDocument.empty
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        requestAccessibilityTrustIfNeeded()
        registerRenderers()
        installMenuBarItem()
        renderInitialHUD()
    }

    private func registerRenderers() {
        let registry = HUDItemRendererRegistry.shared
        registry.register(TextItemRenderer())
        registry.register(MetricItemRenderer())
        registry.register(ProgressItemRenderer())
        registry.register(ListItemRenderer())
        registry.register(StatusItemRenderer())
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowManager.closeAll()
    }

    private func renderInitialHUD() {
        // If a watch directory is configured, load everything from there.
        // Otherwise fall back to the bundled Examples/ directory.
        let baseDir: URL? = {
            if let dir = currentConfig.watchDirectory, !dir.isEmpty {
                let expanded = (dir as NSString).expandingTildeInPath
                let url = URL(fileURLWithPath: expanded)
                guard FileManager.default.fileExists(atPath: url.path) else { return nil }
                return url
            }
            return nil
        }()

        let configURL = baseDir?.appendingPathComponent("config.json")
            ?? resourceURL(named: "config", extension: "json")
        let hudURL = baseDir?.appendingPathComponent("hud.json")
            ?? resourceURL(named: "hud", extension: "json")

        currentConfig = configURL.flatMap { try? loader.loadConfig(from: $0).get() } ?? HUDConfig()
        var document = hudURL.flatMap { try? loader.loadHUD(from: $0).get() } ?? .empty

        // Merge per-slot content files (hud_leftDock.json, hud_rightDock.json, etc.)
        document = mergeSlotFiles(into: document, baseDir: baseDir)

        // Aggregate calendar into the left (agenda) slot.
        document = mergeAgendaSources(into: document)

        currentDocument = document
        applyConfigAndDocument()
    }

    /// For each slot, if a file named `hud_{slot.id}.json` exists, load it and
    /// replace that slot's sections/items.  Slot files use the lightweight
    /// `HUDSlotContent` format — no need for the full HUDDocument envelope.
    private func mergeSlotFiles(into document: HUDDocument, baseDir: URL?) -> HUDDocument {
        var doc = document
        for i in doc.slots.indices {
            let slot = doc.slots[i]
            let slotURL: URL? = {
                if let base = baseDir {
                    let url = base.appendingPathComponent("hud_\(slot.id).json")
                    return FileManager.default.fileExists(atPath: url.path) ? url : nil
                }
                return resourceURL(named: "hud_\(slot.id)", extension: "json")
            }()
            guard let slotURL,
                  case .success(let content) = loader.loadSlotContent(from: slotURL)
            else { continue }
            doc.slots[i].sections = content.sections
            doc.slots[i].items = content.items
        }
        return doc
    }

    /// Enrich the left (agenda) slot with calendar events and reminders.
    /// External file content is handled by `watchDirectory` — no separate path needed.
    private func mergeAgendaSources(into document: HUDDocument) -> HUDDocument {
        var doc = document
        guard let leftIndex = doc.slots.firstIndex(where: { $0.anchor == .dockLeft })
        else { return doc }

        var items = doc.slots[leftIndex].resolvedSections.flatMap { $0.items }

        // Calendar
        if currentConfig.calendarEvents {
            items.append(contentsOf: CalendarReader.fetch())
        }

        // Sort: incomplete first (running > pending), then by time label
        items.sort { a, b in
            let order: [String] = ["running", "active", "working", "thinking", "pending", "todo", "done"]
            let aIdx = order.firstIndex(of: a.state?.lowercased() ?? "") ?? order.count
            let bIdx = order.firstIndex(of: b.state?.lowercased() ?? "") ?? order.count
            if aIdx != bIdx { return aIdx < bIdx }
            return (a.label ?? a.time ?? "") < (b.label ?? b.time ?? "")
        }

        doc.slots[leftIndex].sections = [
            HUDSection(id: "agenda", title: "Agenda", items: items)
        ]
        doc.slots[leftIndex].items = items
        return doc
    }

    private func applyConfigAndDocument() {
        windowManager.show(document: currentDocument, config: currentConfig)
        settingsWindowController?.updateConfig(currentConfig)
    }

    private func resourceURL(named name: String, extension fileExtension: String) -> URL? {
        if let bundled = Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Examples") {
            return bundled
        }
        let fallback = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Examples")
            .appendingPathComponent("\(name).\(fileExtension)")
        return FileManager.default.fileExists(atPath: fallback.path) ? fallback : nil
    }

    // MARK: - Menu bar

    private func installMenuBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "DeskHUD"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...",
                                 action: #selector(openSettings),
                                 keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Reload", action: #selector(reloadHUD), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(config: currentConfig)
            settingsWindowController?.onConfigChanged = { [weak self] newConfig in
                Task { @MainActor [weak self] in
                    self?.currentConfig = newConfig
                    self?.windowManager.reconfigure(config: newConfig)
                }
            }
        }
        settingsWindowController?.updateConfig(currentConfig)
        settingsWindowController?.show()
    }

    // MARK: - Accessibility

    private func requestAccessibilityTrustIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    @objc private func reloadHUD() {
        renderInitialHUD()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
