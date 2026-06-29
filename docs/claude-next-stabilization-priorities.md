# DeskHUD Next Stabilization Priorities

## Purpose

This handoff tells Claude Code what to do next after the core DeskHUD features are in place.

Current core features are mostly present:

- native macOS HUD overlay
- Dock-side placement
- file-driven JSON content
- left pager rail basic implementation
- right context stack
- Settings window
- CLI/schema/sample commands
- release script and icon resources

Do **not** start Sparkle auto-update work in this pass.

This pass should make DeskHUD more customizable, diagnosable, testable, and easier to install locally.

## Product Principle

DeskHUD is an open-source, user-customizable HUD surface.

The project can ship opinionated defaults, but must not hardcode the user's life/workflow model.

Default recommendation:

```text
leftDock  = short-term / now queue / today
rightDock = long-term / context / project compass
```

But this is only a preset. Users and AI agents may put any supported content on either side.

## Priority Order

1. Presentation configurability and pager rail refinement
2. Settings diagnostics / error display
3. Test coverage expansion
4. DMG / Launchpad / local install verification and README guidance

Sparkle auto-update is intentionally out of scope for now.

---

# 1. Presentation Configurability + Pager Rail Refinement

## Current Problem

Current `HUDPanelView` uses:

```swift
private var isPager: Bool { slot.anchor == .dockLeft }
```

This makes the left side always use pager rail and the right side always use stack. It works for the default preset but violates DeskHUD's broader purpose: users should be able to decide how each side presents content.

## Goal

Add configurable presentation mode per side while keeping current defaults.

Default behavior should remain:

```text
leftDock  -> pagerRail
rightDock -> stack
```

But config should allow:

```text
leftDock  -> stack | pagerRail | minimal
rightDock -> stack | pagerRail | minimal
```

## Recommended Model

Add a presentation enum in `DeskHUDCore`:

```swift
public enum HUDPresentation: String, Codable, Sendable, CaseIterable {
    case stack
    case pagerRail
    case minimal
}
```

Add to `HUDWindowConfig`:

```swift
public var leftPresentation: HUDPresentation
public var rightPresentation: HUDPresentation
```

Defaults:

```swift
leftPresentation = .pagerRail
rightPresentation = .stack
```

Decoding must be backward compatible. Missing fields should decode to defaults.

## HUDPanelView Rule

Replace hardcoded anchor logic with config:

```swift
private var presentation: HUDPresentation {
    switch slot.anchor {
    case .dockLeft: return config.window.leftPresentation
    case .dockRight: return config.window.rightPresentation
    }
}
```

Then render:

```text
stack      -> current 2-item stack
pagerRail  -> one active item + timeline rail
minimal    -> one active item, no rail
```

## Pager Rail Refinement

Current `TimelineRailView` has basic max 5 dots and `+N`. Improve only if straightforward.

### Required

- One active item only.
- No clipped ghost/third item.
- Rail active node syncs with active item.
- Handles 1 item gracefully.
- Handles more than 5 items with overflow.

### Nice To Have

- Sliding node window around active item.
- Optional active label from `time` -> `label`.
- More precise active-index mapping when active item is beyond first 5.

Do not let pager rail become visually noisy. It should stay quiet.

## Settings UI

Add presentation controls to Settings if small:

```text
Left Presentation:  Stack | Pager Rail | Minimal
Right Presentation: Stack | Pager Rail | Minimal
```

If Settings layout is already cramped, add it under Layout or Behavior with compact Pickers.

## CLI / Schema / README

Update schema docs to explain:

- presentations are visual modes, not content rules
- default preset is left pager rail, right stack
- users can override either side

## Acceptance Criteria

- Existing config files still decode.
- Defaults match current behavior.
- Users can set right side to `pagerRail` or left side to `stack` in config.
- `swift test` passes.
- `deskhudctl schema` documents presentation fields.

---

# 2. Settings Diagnostics / Error Display

## Current Problem

`AppDelegate` has:

```swift
private var lastError: String?
```

but it is not rendered in Settings. If JSON parsing fails, watch directory is wrong, login item registration fails, or reload fails, users have little feedback.

A file-driven app needs diagnostics. Otherwise users will think DeskHUD is frozen.

## Goal

Add a small diagnostics/status section in Settings.

This should be practical, not fancy.

## Recommended Diagnostics Fields

Track and show:

```text
Last reload status: OK / Error
Last error message
Watch directory path
Loaded source: bundled examples / watchDirectory
Last reload time
Accessibility trusted: yes/no
Calendar events enabled: yes/no
```

Optional later:

```text
left item count
right item count
current config path
current HUD source files
```

## Suggested Implementation

Create a lightweight app state struct:

```swift
struct HUDRuntimeStatus: Equatable {
    var lastReloadAt: Date?
    var lastReloadSucceeded: Bool
    var lastError: String?
    var watchDirectory: String?
    var sourceDescription: String
    var accessibilityTrusted: Bool
}
```

Store it in `AppDelegate`, update it on:

- initial render
- CLI reload
- file watcher reload
- config load failure
- HUD load failure
- slot file load failure
- login item failure

Pass to SettingsWindowController / SettingsView.

If that is too much for one pass, start smaller:

- expose `lastError`
- expose `watchDirectory`
- expose `lastReloadAt`

## UX Guidance

Settings should show diagnostics quietly:

```text
Status: OK
Watch Dir: ~/Library/CloudStorage/DeskHUD
Last Reload: 22:18:04
```

If error:

```text
Status: Error
hud_leftDock.json: decode failed at line ...
```

Do not show intrusive alerts for every file parse failure. Persistent Settings status is enough.

## Acceptance Criteria

- Login item error is visible in Settings.
- JSON/config load error is visible in Settings.
- User can see what directory DeskHUD is watching.
- User can see last reload time/status.
- No excessive polling is introduced.
- `swift test` passes.

---

# 3. Test Coverage Expansion

## Current State

There are only 3 tests in `DeskHUDCoreTests`. They pass, but coverage is thin.

Focus on model, decoding, CLI-adjacent, and pure logic tests. Do not attempt fragile UI snapshot tests yet.

## Recommended Tests

### Config Decoding

- Missing `leftPresentation` / `rightPresentation` defaults correctly.
- Unknown presentation value fails clearly.
- Old config files still decode.
- New full config encodes/decodes round trip.

### HUD Item Types

- `alert` decodes.
- `countdown` decodes.
- Existing `text/status/metric/progress/list` still decode.

### Slot Content

- `HUDSlotContent` decodes per-slot JSON.
- Empty `sections` falls back to `items` correctly through `resolvedSections`.

### Loader Errors

- Missing file returns `fileNotFound`.
- Invalid JSON returns `decodeFailed`.
- Valid config loads successfully.

### Pager Rail Pure Logic

If possible, extract rail window calculation into a pure helper in Core or a testable app helper:

```swift
TimelineRailModel.window(total:active:maxNodes:)
```

Test:

- total 0
- total 1
- total 4
- total 8 active 0
- total 8 active 4
- total 8 active 7
- overflow count

If extracting this is awkward, keep it for later. Do not make UI code ugly just for tests.

### CLI Validation

If `deskhudctl validate slot` does not exist, consider adding it:

```bash
deskhudctl validate slot hud_leftDock.json
```

This is useful for AI writers because primary files are per-slot files.

Acceptance for CLI:

- `validate hud` still works for full HUD documents.
- `validate config` still works.
- `validate slot` works for per-slot files.

## Acceptance Criteria

- Meaningful tests increase beyond 3.
- Tests cover backward compatibility and new presentation config.
- `swift test` passes.
- Tests do not require launching the macOS app.

---

# 4. DMG / Launchpad / Local Install Verification + README Guidance

## Context

We are not paying for Apple Developer Program right now. So DeskHUD should be source-first open-source software.

That means:

- Do not block progress on notarization.
- Do not promise fully Gatekeeper-trusted public binaries.
- Keep DMG builds useful for local/self-signed testing.
- Make README clear: source-first, self-build recommended.

## Current State

Resource files and `generate_assets.swift` appear to be integrated into `make_release.sh`.

Still verify locally:

```bash
cd /Users/hex/Documents/projects/DeskHuD
./script/make_release.sh 0.1.6-test
```

Then inspect:

```bash
hdiutil attach release/DeskHUD-v0.1.6-test.dmg
ls /Volumes/DeskHUD_0.1.6-test
cp -R /Volumes/DeskHUD_0.1.6-test/DeskHUD.app /Applications/
open /Applications/DeskHUD.app
```

Check:

```bash
plutil -p /Applications/DeskHUD.app/Contents/Info.plist
codesign -dvvv /Applications/DeskHUD.app
mdls -name kMDItemDisplayName -name kMDItemCFBundleIdentifier -name kMDItemKind /Applications/DeskHUD.app
```

Optional Launch Services refresh:

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/DeskHUD.app
killall Dock
```

## README Guidance

Add clear install modes:

### Recommended For Now: Source Build

```bash
git clone https://github.com/HeXiao2001/DeskHUD.git
cd DeskHUD
./script/build_and_run.sh --verify
```

### Experimental DMG

Say clearly:

```text
DMG builds are currently self-signed for local testing. They are not notarized.
macOS may show extra security prompts. If you want the cleanest experience, build from source.
```

### Why No Notarized Builds Yet

Short version:

```text
Official notarized builds require Apple Developer Program membership. DeskHUD is currently source-first while the project is young.
```

Do not over-explain or sound apologetic. This is normal for early open-source tools.

## Launchpad Reality

Without Developer ID notarization, Launchpad/Gatekeeper behavior may vary.

We can improve:

- `CFBundleDisplayName`
- `LSApplicationCategoryType`
- proper `.app` bundle structure
- icon resources
- Launch Services registration

But we should not promise perfect Launchpad behavior until notarized distribution exists.

## Acceptance Criteria

- `make_release.sh` builds a DMG locally.
- DMG contains `DeskHUD.app` and `Applications` symlink.
- Copied app opens from `/Applications`.
- Info.plist contains display name, category, icon key.
- README clearly describes source-first distribution.
- README labels DMG as self-signed/experimental if release assets are uploaded.

---

# Explicitly Out Of Scope: Sparkle

Do not integrate Sparkle in this pass.

Reasons:

- It adds release complexity.
- It implies stable public binary distribution.
- It is less useful without notarized official builds.
- DeskHUD is still changing quickly.

Revisit Sparkle after:

- presentation config is stable
- diagnostics exist
- test coverage is stronger
- releases have a consistent process
- there are actual external users asking for updates

## Suggested Work Order For Claude Code

1. Add presentation config and tests.
2. Update Settings UI for presentation if simple.
3. Add diagnostics runtime status to Settings.
4. Add `validate slot` and core tests.
5. Verify DMG locally and update README install section.

## Suggested Commit Split

Prefer multiple small commits:

```text
feat: make HUD presentation configurable
feat: show runtime diagnostics in Settings
feat: expand core validation tests
docs: clarify source-first install flow
```

If DMG script fixes are needed:

```text
fix: improve local DMG install metadata
```

## Final Verification Commands

Run before reporting done:

```bash
cd /Users/hex/Documents/projects/DeskHuD
swift test
swift run deskhudctl validate config Examples/config.json
swift run deskhudctl validate slot Examples/hud_leftDock.json
swift run deskhudctl validate slot Examples/hud_rightDock.json
./script/build_and_run.sh --verify
./script/make_release.sh 0.1.6-test
```

If local permissions prevent launching or mounting DMGs, report exactly which command could not run and why.
