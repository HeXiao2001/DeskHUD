# DeskHUD

Native macOS persistent HUD overlay — file-driven, read-only, Dock-side.

DeskHUD watches JSON files and renders lightweight status panels in the unused space beside the macOS Dock. It does **not** generate content, call APIs, or run AI models. It only reads files, parses valid state, and displays it.

## Install

**AI agent / one-liner** (AI: replace `VERSION` with latest tag from releases):
```bash
VERSION=$(curl -s https://api.github.com/repos/HeXiao2001/DeskHUD/releases/latest | grep tag_name | head -1 | cut -d'"' -f4) && curl -fsSL "https://github.com/HeXiao2001/DeskHUD/releases/download/$VERSION/DeskHUD-${VERSION}.dmg" -o /tmp/DeskHUD.dmg && hdiutil attach /tmp/DeskHUD.dmg -nobrowse && cp -R /Volumes/DeskHUD*/DeskHUD.app /Applications/ && hdiutil detach /Volumes/DeskHUD* && open /Applications/DeskHUD.app
```

**Manual:**
1. Download from [Releases](https://github.com/HeXiao2001/DeskHUD/releases)
2. Open DMG, drag `DeskHUD.app` to `/Applications`
3. Launch from Applications
4. Grant Accessibility permission when prompted

**Auto-start**: System Settings → General → Login Items → add DeskHUD.

**Updates**: Menu bar → Check for Updates... → download latest → run the one-liner.

## Quick Start (Developers)

```bash
git clone https://github.com/HeXiao2001/DeskHUD.git
cd DeskHUD
./script/build_and_run.sh --verify
```
swift run deskhudctl validate hud Examples/hud.json
```

## Architecture

```
Any writer (AI / script / app / sync)
  └─→ hud_leftDock.json   ──┐
  └─→ hud_rightDock.json  ──┤
  └─→ macOS Calendar      ──┼──→ DeskHUD ──→ Click-through HUD overlay
  └─→ External JSON file  ──┘     (beside the Dock, every display)
```

## File Layout

```
Examples/
  config.json              ← Appearance settings
  hud.json                 ← Slot structure (optional, fallback)
  hud_leftDock.json        ← Left panel content (agenda / tasks)
  hud_rightDock.json       ← Right panel content (live AI status)
  hooks/
    update_status.py       ← Claude Code hook integration example
```

## CLI Reference

```
deskhudctl schema             Complete JSON field reference (AI scaffold)
deskhudctl sample minimal     Minimal HUD document
deskhudctl sample todo        Todo / task list template
deskhudctl sample live        Live AI status template
deskhudctl sample full        Both sides populated
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

### State colors

| state | color |
|-------|-------|
| `done`, `ok`, `ready` | green |
| `running`, `working`, `thinking` | cyan |
| `blocked`, `warning` | yellow |
| `error`, `failed` | red |
| `pending`, `todo`, `idle` | dim |

## Multi-source Agenda

Set in `config.json`:

```json
{
  "calendarEvents": true,
  "externalAgendaPath": "/Users/me/OneDrive/tasks.json"
}
```

The left panel merges: `hud_leftDock.json` + macOS Calendar events/reminders + external file.

## Settings

Menu bar → **Settings...** (⌘,) opens a live-preview settings window with Appearance, Layout, and Behavior tabs.

## AI Integration

### For AI agents writing to DeskHUD:

```bash
# 1. Learn the format
deskhudctl schema

# 2. Generate a template
deskhudctl sample todo > hud_leftDock.json

# 3. Write atomically (recommended)
cat > hud_leftDock.json.tmp <<'JSON'
{ "sections": [...], "items": [...] }
JSON
mv hud_leftDock.json.tmp hud_leftDock.json

# 4. Validate
deskhudctl validate hud hud_leftDock.json
```

### Claude Code hooks

See `Examples/hooks/update_status.py`. Configure in `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop":       [{"command": "python3 Examples/hooks/update_status.py idle"}],
    "PreToolUse": [{"command": "python3 Examples/hooks/update_status.py working"}]
  }
}
```

### Cross-platform sync (Windows ↔ Mac)

1. AI on Windows writes to a OneDrive-synced JSON file
2. OneDrive syncs to Mac at `~/OneDrive/tasks.json`
3. DeskHUD reads it via `"externalAgendaPath": "~/OneDrive/tasks.json"`
4. Point DeskHUD → Reload, or wait for file watcher (planned)

## Build

```bash
swift build --product DeskHUD
swift test
```

macOS 14+ required. Apple Silicon native.
