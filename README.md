# DeskHUD

DeskHUD is a native macOS persistent HUD runtime. The app is intentionally read-only: it watches JSON files, renders the latest valid state, and otherwise stays idle.

This repository is at the first display-core MVP stage.

## Current MVP

- SwiftPM macOS app executable: `DeskHUD`
- CLI executable: `deskhudctl`
- Core JSON models for `config.json` and `hud.json`
- Two default slots: `dock.left` and `dock.right`
- Click-through AppKit overlay windows
- SwiftUI renderer for text, metric, progress, list, and status items
- Sample files in `Examples/`

## Run

```bash
./script/build_and_run.sh --verify
```

The script builds the SwiftPM product, stages `dist/DeskHUD.app`, copies the example JSON files into the bundle, launches the app, and verifies the process is running.

## Test

```bash
swift test
```

## CLI

```bash
swift run deskhudctl validate hud Examples/hud.json
swift run deskhudctl validate config Examples/config.json
swift run deskhudctl sample minimal
```

## Product Principle

DeskHUD does not care who writes the files. The writer can be a user, script, app, sync process, or agent. DeskHUD only watches files, parses valid state, and renders.
