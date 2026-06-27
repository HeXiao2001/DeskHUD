import DeskHUDCore
import Foundation

@main
struct DeskHUDCTL {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        guard let command = args.first else {
            printUsage()
            Foundation.exit(2)
        }

        switch command {
        case "sample":
            sample(Array(args.dropFirst()))
        case "validate":
            validate(Array(args.dropFirst()))
        case "status":
            print("DeskHUD CLI ready. App IPC status is not implemented in this MVP.")
        default:
            printUsage()
            Foundation.exit(2)
        }
    }

    private static func sample(_ args: [String]) {
        let name = args.first ?? "minimal"
        switch name {
        case "minimal", "today", "todo", "meeting", "ai-progress", "goal":
            print(Self.minimalHUDSample)
        default:
            fputs("Unknown sample: \(name)\n", stderr)
            Foundation.exit(2)
        }
    }

    private static func validate(_ args: [String]) {
        guard args.count == 2 else {
            fputs("Usage: deskhudctl validate hud <path>\n", stderr)
            Foundation.exit(2)
        }
        let kind = args[0]
        let url = URL(fileURLWithPath: args[1])
        let loader = HUDFileLoader()

        switch kind {
        case "hud":
            report(loader.loadHUD(from: url))
        case "config":
            report(loader.loadConfig(from: url))
        default:
            fputs("Unknown validation kind: \(kind)\n", stderr)
            Foundation.exit(2)
        }
    }

    private static func report<T>(_ result: Result<T, HUDFileLoaderError>) {
        switch result {
        case .success:
            print("OK")
        case .failure(let error):
            fputs("ERROR: \(error.description)\n", stderr)
            Foundation.exit(1)
        }
    }

    private static func printUsage() {
        print("""
        Usage:
          deskhudctl sample minimal
          deskhudctl validate hud <path>
          deskhudctl validate config <path>
          deskhudctl status
        """)
    }

    private static let minimalHUDSample = """
    {
      "version": 1,
      "slots": [
        {
          "id": "leftDock",
          "anchor": "dock.left",
          "rotation": { "enabled": false, "intervalSeconds": 45 },
          "items": [
            { "id": "focus", "type": "text", "kind": "today", "title": "Focus", "subtitle": "Ship the display core" }
          ]
        },
        {
          "id": "rightDock",
          "anchor": "dock.right",
          "rotation": { "enabled": false, "intervalSeconds": 45 },
          "items": [
            { "id": "progress", "type": "progress", "kind": "aiProgress", "title": "DeskHUD", "label": "MVP", "value": 0.35, "state": "running" }
          ]
        }
      ]
    }
    """
}
