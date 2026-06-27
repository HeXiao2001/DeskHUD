# DeskHUD Display Core MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the smallest native macOS DeskHUD app that displays two read-only click-through HUD panels at the bottom-left and bottom-right of each screen, backed by local JSON files.

**Architecture:** Use a SwiftPM package with one GUI executable (`DeskHUD`) and one CLI executable (`deskhudctl`). The GUI app owns AppKit overlay windows through a narrow `HUDWindowManager`, renders SwiftUI `HUDPanelView` content, and reads local `config.json` / `hud.json` through a focused store. The first milestone keeps rendering static after load; file watching is scaffolded but can be completed after the windows are verified.

**Tech Stack:** Swift 6-compatible SwiftPM, SwiftUI, AppKit, Foundation JSON decoding, XCTest.

---

### File Structure

- `Package.swift`: SwiftPM package definition for app, CLI, library, and tests.
- `Sources/DeskHUDApp/main.swift`: AppKit app entrypoint.
- `Sources/DeskHUDCore/Models/HUDModels.swift`: Codable models for config, slots, and items.
- `Sources/DeskHUDCore/Loading/HUDFileLoader.swift`: Reads and decodes JSON files with previous-good fallback surface.
- `Sources/DeskHUDCore/Rendering/EffectProfile.swift`: Low/medium/high profile enum for future rendering behavior.
- `Sources/DeskHUDApp/Windowing/HUDWindowManager.swift`: Creates click-through overlay windows per screen and slot.
- `Sources/DeskHUDApp/Views/HUDPanelView.swift`: SwiftUI read-only panel view.
- `Sources/DeskHUDApp/App/AppDelegate.swift`: Starts app, loads state, creates windows.
- `Sources/deskhudctl/main.swift`: Minimal CLI for `sample`, `validate`, and `status` stubs.
- `Examples/config.json`: Default config sample.
- `Examples/hud.json`: Default HUD content sample.
- `Tests/DeskHUDCoreTests/HUDModelDecodingTests.swift`: Model decoding tests.
- `script/build_and_run.sh`: Build, bundle, and run SwiftPM macOS GUI app.
- `.codex/environments/environment.toml`: Codex Run button wiring.

### Task 1: Scaffold SwiftPM Package

**Files:**
- Create: `Package.swift`
- Create directories listed above.

- [ ] Create the package with a `DeskHUDCore` library, `DeskHUD` executable, `deskhudctl` executable, and `DeskHUDCoreTests` test target.
- [ ] Run `swift package describe` and confirm SwiftPM recognizes all targets.

### Task 2: Define JSON Models

**Files:**
- Create: `Sources/DeskHUDCore/Models/HUDModels.swift`
- Create: `Tests/DeskHUDCoreTests/HUDModelDecodingTests.swift`

- [ ] Add Codable models: `HUDConfig`, `HUDDocument`, `HUDSlot`, `HUDRotation`, `HUDItem`, `HUDItemType`, `HUDAnchor`, `EffectProfile`.
- [ ] Write tests that decode a minimal two-slot HUD document and a config with `effectProfile: "low"`.
- [ ] Run `swift test` and confirm model tests pass.

### Task 3: Add Samples

**Files:**
- Create: `Examples/config.json`
- Create: `Examples/hud.json`

- [ ] Add sample config with default bottom Dock slots, low effect profile, stable size, and full-screen overlay mode.
- [ ] Add sample HUD with `dock.left` text/list content and `dock.right` progress/status content.
- [ ] Use tests or `deskhudctl validate` after Task 7 to keep these samples valid.

### Task 4: Implement File Loader

**Files:**
- Create: `Sources/DeskHUDCore/Loading/HUDFileLoader.swift`
- Modify: `Tests/DeskHUDCoreTests/HUDModelDecodingTests.swift`

- [ ] Add a loader that decodes config and HUD files from explicit paths.
- [ ] Return structured errors without crashing.
- [ ] Add a test for invalid JSON returning failure while not throwing out of process.

### Task 5: Build SwiftUI HUD Panel View

**Files:**
- Create: `Sources/DeskHUDApp/Views/HUDPanelView.swift`

- [ ] Render a fixed-size translucent panel from one `HUDSlot`.
- [ ] Support `text`, `metric`, `progress`, `list`, and `status` primitives in a simple visual style.
- [ ] Keep the view read-only and non-interactive.

### Task 6: Build AppKit Overlay Window Manager

**Files:**
- Create: `Sources/DeskHUDApp/Windowing/HUDWindowManager.swift`

- [ ] Create one borderless `NSWindow` per screen per slot.
- [ ] Set `isOpaque = false`, clear background, no titlebar, no shadow or subtle shadow only.
- [ ] Set `ignoresMouseEvents = true` for click-through behavior.
- [ ] Set collection behavior to join spaces and support full-screen auxiliary display.
- [ ] Compute bottom-left and bottom-right frames from `NSScreen.visibleFrame`.

### Task 7: App Entrypoint and Default Load

**Files:**
- Create: `Sources/DeskHUDApp/main.swift`
- Create: `Sources/DeskHUDApp/App/AppDelegate.swift`

- [ ] Start `NSApplication` with accessory activation policy.
- [ ] Load `Examples/config.json` and `Examples/hud.json` when no user config exists.
- [ ] Create HUD windows on launch.
- [ ] Add a minimal menu bar item with Quit for recovery during development.

### Task 8: Minimal CLI

**Files:**
- Create: `Sources/deskhudctl/main.swift`

- [ ] Implement `deskhudctl sample minimal` to print a minimal valid HUD JSON.
- [ ] Implement `deskhudctl validate hud <path>` using `HUDFileLoader`.
- [ ] Implement `deskhudctl status` as a placeholder that reports local validation availability, not app IPC yet.

### Task 9: Build and Run Script

**Files:**
- Create: `script/build_and_run.sh`
- Create: `.codex/environments/environment.toml`

- [ ] Build the `DeskHUD` executable with `swift build`.
- [ ] Stage `dist/DeskHUD.app` with a minimal `Info.plist`.
- [ ] Kill any previous `DeskHUD` process.
- [ ] Launch via `/usr/bin/open -n dist/DeskHUD.app`.
- [ ] Add `--verify` mode using `pgrep -x DeskHUD`.

### Task 10: Verify Display MVP

**Files:**
- Modify only files needed to fix build/runtime issues.

- [ ] Run `swift test`.
- [ ] Run `./script/build_and_run.sh --verify`.
- [ ] Confirm the process starts.
- [ ] If GUI launch is blocked by bundle or activation issues, fix the bundle script first.
- [ ] Manually inspect that two HUD panels appear on the current display and do not block clicks.

### Self-Review

Spec coverage for this MVP:

- Covers native macOS App + CLI + JSON-backed display.
- Covers click-through read-only overlay windows.
- Covers bottom Dock-side default display.
- Covers primitive renderer scaffolding and effect profile type.
- Defers live file watching, settings window, login item, GitHub publishing, and MCP because the first milestone is display verification.

No placeholders are intended in executable source. The CLI `status` command is explicitly scoped as a local validation placeholder for this MVP and must not pretend app IPC exists yet.
