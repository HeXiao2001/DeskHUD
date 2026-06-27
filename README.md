# DeskHUD

Native macOS persistent HUD overlay — file-driven, read-only, Dock-side.

DeskHUD watches JSON files and renders lightweight status panels in the unused space beside the macOS Dock. It does **not** generate content, call APIs, or run AI models. It only reads files, parses valid state, and displays it.

## Install

**AI agent / one-liner:**
```bash
VERSION=$(curl -s https://api.github.com/repos/HeXiao2001/DeskHUD/releases/latest | grep tag_name | head -1 | cut -d'"' -f4) && curl -fsSL "https://github.com/HeXiao2001/DeskHUD/releases/download/$VERSION/DeskHUD-${VERSION}.dmg" -o /tmp/DeskHUD.dmg && hdiutil attach /tmp/DeskHUD.dmg -nobrowse && cp -R /Volumes/DeskHUD*/DeskHUD.app /Applications/ && hdiutil detach /Volumes/DeskHUD* && open /Applications/DeskHUD.app
```

**Manual:**
1. Download from [Releases](https://github.com/HeXiao2001/DeskHUD/releases)
2. Open DMG, drag `DeskHUD.app` to `/Applications`
3. Launch, grant Accessibility permission when prompted

**Auto-start**: System Settings → General → Login Items → add DeskHUD.

**Updates**: Menu bar → Check for Updates... → download latest DMG.

## Development

```bash
git clone https://github.com/HeXiao2001/DeskHUD.git
cd DeskHUD
./script/build_and_run.sh --verify
swift test
swift run deskhudctl schema    # AI: start here
```

macOS 14+, Apple Silicon.

## Architecture

```
Any writer (AI / script / app / cloud sync)
  └─→ hud_leftDock.json   ──┐
  └─→ hud_rightDock.json  ──┤
  └─→ macOS Calendar      ──┼──→ DeskHUD ──→ Click-through HUD panels
  └─→ Remote JSON file    ──┘     (beside the Dock, every display)
```

## Configuration

Set `watchDirectory` in `config.json` to any local or cloud-synced directory. DeskHUD loads all files from there and auto-reloads on changes. Merge content from multiple locations by pointing `watchDirectory` at a sync folder (iCloud, Dropbox, any cloud drive).

```json
{
  "watchDirectory": "~/Library/CloudStorage/MyCloudDrive/DeskHUD",
  "calendarEvents": true
}
```

Left panel merges: per-slot files + macOS Calendar events/reminders. Right panel is free-form — AI decides what to show.

## CLI Reference

```
deskhudctl schema             Full JSON field reference + AI writing guide
deskhudctl sample left        Left panel template (tasks / schedule)
deskhudctl sample right       Right panel template (status / tips)
deskhudctl sample full        Both panels
deskhudctl slot               Per-slot content file template
deskhudctl validate hud <path>
deskhudctl validate config <path>
deskhudctl status
```

## Item Types

| type | renders | key fields |
|------|---------|------------|
| `text` | title + subtitle + time | `title`, `subtitle`, `time` |
| `metric` | title + numeric value + unit | `title`, `value`, `unit` |
| `progress` | progress bar + label | `title`, `label`, `value` (0–1), `state` |
| `list` | title + bullet lines | `title`, `lines[]` |
| `status` | colored dot + title + label | `title`, `label`, `state` |

**State colors**: done/ok/ready→green, running/working/thinking→cyan, blocked/warning→yellow, error/failed→red, pending/todo/idle→dim.

**Icons**: Any Apple-native Unicode emoji or SF Symbol works in `title` and `subtitle`. Use the full system emoji set (🎯📅✅⏰📄💻🚀⚠️💡🕗🕙🕑📋📝🌿🔴🟡🟢🔵).

## Settings

Menu bar → **Settings...** (⌘,) → live-preview Appearance, Layout, Behavior.

## AI Integration

```bash
deskhudctl schema              # AI: learn the format + writing conventions
deskhudctl sample left > hud_leftDock.json
deskhudctl validate hud hud_leftDock.json
```

Write atomically: `cat > file.json.tmp && mv file.json.tmp file.json`

DeskHUD auto-detects file changes via `DispatchSource` — no manual reload needed.

**Cross-device**: Write to a cloud-synced directory, point `watchDirectory` at it. DeskHUD merges content from all sources automatically.
