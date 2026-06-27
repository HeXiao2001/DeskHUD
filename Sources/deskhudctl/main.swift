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
        case "help", "-h", "--help":
            printUsage()
        case "schema":
            printSchema()
        case "sample":
            sample(Array(args.dropFirst()))
        case "slot":
            print(Self.slotSample)
        case "validate":
            validate(Array(args.dropFirst()))
        case "status":
            print("DeskHUD CLI ready. App IPC status is not implemented in this MVP.")
        default:
            fputs("Unknown command: \(command)\n", stderr)
            printUsage()
            Foundation.exit(2)
        }
    }

    private static func sample(_ args: [String]) {
        let name = args.first ?? "left"
        switch name {
        case "left", "minimal":
            print(Self.leftSample)
        case "right":
            print(Self.rightSample)
        case "todo":
            print(Self.todoSample)
        case "full":
            print(Self.fullSample)
        default:
            fputs("Unknown sample: \(name). Try: left, right, todo, full\n", stderr)
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
        DeskHUD CLI — validate, generate, and inspect HUD configuration.

        Commands:
          deskhudctl schema                  Print complete JSON field reference
          deskhudctl sample <name>           Output a ready-to-use HUD JSON template
            names: left  right  todo  full
          deskhudctl slot                    Output per-slot content template
          deskhudctl validate hud <path>     Validate a HUD content file
          deskhudctl validate config <path>  Validate a config file
          deskhudctl status                  Show app status

        Examples:
          deskhudctl schema                   # AI: read this for the full format
          deskhudctl sample left > hud_leftDock.json
          deskhudctl sample right > hud_rightDock.json
          deskhudctl sample todo              # task list variant
          deskhudctl validate hud hud_leftDock.json
        """)
    }

    private static func printSchema() {
        print("""
        # DeskHUD File Format Reference

        ## Convention — which file to edit

        | File | Panel | Purpose |
        |------|-------|---------|
        | `hud_leftDock.json` | Left | Tasks, todos, schedule, focus |
        | `hud_rightDock.json` | Right | Summary status, git branch, live progress |

        - Writers edit per-slot files directly — each file is independent.
        - Use `hud_leftDock.json` for agenda items, `hud_rightDock.json` for status.
        - Write atomically: write to `.tmp`, flush, rename to `.json`.

        ## HUD Document (hud.json or full document)
        {
          "version": 1,
          "slots": [
            {
              "id": "leftDock",              // required: "leftDock" or "rightDock"
              "anchor": "dock.left",         // required: "dock.left" or "dock.right"
              "rotation": {                  // optional
                "enabled": false,            //   bool, cycle through sections?
                "intervalSeconds": 45        //   seconds between rotations
              },
              "sections": [ ... ],           // preferred: array of HUDSection
              "items": [ ... ]               // legacy flat items (used if sections is empty)
            }
          ]
        }

        ## Per-slot content file (hud_leftDock.json, hud_rightDock.json)
        {
          "sections": [ ... ],
          "items": [ ... ]
        }

        ## HUD Section
        {
          "id": "tasks",           // required, unique within slot
          "title": "Tasks",        // optional section header
          "items": [ ... ]         // array of HUDItem
        }

        ## HUD Item — all fields
        {
          "id": "t1",              // required, unique identifier
          "type": "status",        // required: text | metric | progress | list | status
          "kind": "todo",          // optional semantic hint: todo, event, today, focus,
                                   //   goal, aiProgress, systemStatus
          "title": "Fix parser",   // primary text
          "subtitle": "Handle partial writes",  // secondary text (text type)
          "label": "14:00",        // auxiliary label (progress, status, event time)
          "value": 0.62,           // number 0–1 progress, or arbitrary metric value
          "unit": "%",             // unit string (metric type)
          "state": "running",      // drives status dot color:
                                   //   done/ok/ready=green   running/thinking/working=cyan
                                   //   blocked/warning=yellow   error/failed=red
                                   //   pending/todo/idle=dim
          "time": "14:32",         // free-form time / duration label
          "lines": ["line 1", "line 2"]  // multi-line text (list type)
        }

        ## Item types and which fields each uses
        type=text     uses: title, subtitle, (time)
        type=metric   uses: title, value, unit
        type=progress uses: title, label, value (0–1), state
        type=list     uses: title, lines[]
        type=status   uses: title, label, state

        ## Config file (config.json) — all fields
        {
          "version": 1,
          "effectProfile": "low",          // low | medium | high
          "fullscreenMode": "overlay",     // overlay | desktopOnly
          "displays": "all",               // all | main
          "backgroundStyle": "clear",      // glass | clear | dark
          "calendarEvents": false,         // bool: enable macOS Calendar?
          "watchDirectory": null,          // string or null: path to directory with config+hud JSONs
          "debugLogging": true,            // bool
          "window": {
            "width": 0,                    // 0 = auto-fill Dock-adjacent space
            "height": 82,
            "margin": 18,
            "cornerRadius": 14,
            "opacity": 0.84,              // used only when backgroundStyle=dark
            "maxLines": 2,                // max lines in list items
            "contentDensity": "comfortable", // compact | comfortable | spacious
            "scrollIntervalSeconds": 4     // seconds between auto-scroll pages
          }
        }

        ## Atomic write pattern (recommended)
        Write to a .tmp file, flush, then rename:
          echo '{"items":[...]}' > hud_leftDock.json.tmp && mv hud_leftDock.json.tmp hud_leftDock.json
        """)
    }

    private static let leftSample = """
    {
      "version": 1,
      "slots": [
        {
          "id": "leftDock", "anchor": "dock.left",
          "rotation": { "enabled": false, "intervalSeconds": 45 },
          "items": [
            { "id": "f1", "type": "text", "kind": "today", "title": "Focus", "subtitle": "Ship it" }
          ]
        },
        {
          "id": "rightDock", "anchor": "dock.right",
          "rotation": { "enabled": false, "intervalSeconds": 45 },
          "items": [
            { "id": "p1", "type": "progress", "kind": "aiProgress", "title": "Build", "label": "working", "value": 0.45, "state": "running" }
          ]
        }
      ]
    }
    """

    /// A todo / task list.  Writers add or update items; each `state` drives the status dot:
    ///   "done" = green, "running" = cyan, "blocked" = yellow, "pending" = dim white.
    private static let todoSample = """
    {
      "version": 1,
      "slots": [
        {
          "id": "leftDock", "anchor": "dock.left",
          "rotation": { "enabled": true, "intervalSeconds": 30 },
          "sections": [
            {
              "id": "tasks", "title": "Tasks",
              "items": [
                { "id": "t1", "type": "status", "kind": "todo", "title": "Design schema",       "state": "done" },
                { "id": "t2", "type": "status", "kind": "todo", "title": "Implement renderer",    "state": "running" },
                { "id": "t3", "type": "status", "kind": "todo", "title": "Write tests",           "state": "pending" },
                { "id": "t4", "type": "status", "kind": "todo", "title": "Polish UI",             "state": "pending" }
              ]
            }
          ],
          "items": []
        }
      ]
    }
    """

    /// Right panel — summary status, git branch, brief indicators.
    private static let rightSample = """
    {
      "sections": [
        {
          "id": "summary", "title": null,
          "items": [
            { "id": "r1", "type": "status", "kind": "systemStatus", "title": "Branch", "label": "main", "state": "ok" },
            { "id": "r2", "type": "text",   "kind": "today", "title": "Last sync", "subtitle": "14:32" }
          ]
        }
      ],
      "items": []
    }
    """

    /// Full master document showing both panels. Per-slot files are preferred.
    private static let fullSample = """
    {
      "version": 1,
      "slots": [
        {
          "id": "leftDock", "anchor": "dock.left",
          "rotation": { "enabled": true, "intervalSeconds": 30 },
          "sections": [
            { "id": "focus", "title": "Focus", "items": [
              { "id": "f1", "type": "text", "kind": "today", "title": "DeskHUD", "subtitle": "Ship display core" }
            ]},
            { "id": "tasks", "title": "Tasks", "items": [
              { "id": "t1", "type": "status", "kind": "todo", "title": "Design schema",  "state": "done" },
              { "id": "t2", "type": "status", "kind": "todo", "title": "Build renderer", "state": "running" },
              { "id": "t3", "type": "status", "kind": "todo", "title": "Write tests",    "state": "pending" }
            ]}
          ],
          "items": []
        },
        {
          "id": "rightDock", "anchor": "dock.right",
          "rotation": { "enabled": false, "intervalSeconds": 45 },
          "sections": [
            { "id": "summary", "title": null, "items": [
              { "id": "s1", "type": "status", "kind": "systemStatus", "title": "Branch", "label": "main", "state": "ok" }
            ]}
          ],
          "items": []
        }
      ]
    }
    """

    /// A per-slot content file — the format for `hud_leftDock.json` / `hud_rightDock.json`.
    private static let slotSample = """
    {
      "sections": [
        {
          "id": "main",
          "title": "Section Title",
          "items": [
            { "id": "i1", "type": "status", "kind": "todo", "title": "Task one",   "state": "done" },
            { "id": "i2", "type": "status", "kind": "todo", "title": "Task two",   "state": "running" },
            { "id": "i3", "type": "status", "kind": "todo", "title": "Task three", "state": "pending" }
          ]
        }
      ],
      "items": []
    }
    """
}
