import DeskHUDCore
import Foundation

/// Reads todo / agenda items from an arbitrary user-specified JSON path.
/// Supports two formats:
///   1. `[HUDItem]` — flat array of items
///   2. `HUDSlotContent` — sections + items (flattened)
/// Returns `[HUDItem]` sorted: incomplete first, then by label time.
enum ExternalAgendaReader {

    static func fetch(from path: String) -> [HUDItem] {
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url)
        else { return [] }

        let decoder = JSONDecoder()

        // Try flat array first
        if let items = try? decoder.decode([HUDItem].self, from: data) {
            return sorted(items)
        }
        // Try HUDSlotContent (flatten sections)
        if let content = try? decoder.decode(HUDSlotContent.self, from: data) {
            if let sections = content.sections {
                return sorted(sections.flatMap { $0.items })
            }
            return sorted(content.items)
        }
        return []
    }

    private static func sorted(_ items: [HUDItem]) -> [HUDItem] {
        items.sorted { a, b in
            let aDone = a.state == "done", bDone = b.state == "done"
            if aDone != bDone { return !aDone }
            return (a.label ?? "") < (b.label ?? "")
        }
    }
}
