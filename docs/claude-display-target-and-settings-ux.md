# DeskHUD Display Target + Settings UX Handoff

## Why This Exists

The current DeskHUD core is usable, but there is a real-world issue:

When the user watches video in full screen, the left/right HUD panels may appear on top of that full-screen video instead of staying on the intended primary working display.

This is not only a coordinate bug. DeskHUD needs an explicit display targeting policy in Settings.

The Settings window also works, but it still feels too bare for an open-source app that is becoming highly configurable. This pass should make Settings richer, clearer, and safer without turning DeskHUD into a heavy interactive app.

## Current State Observed

### Existing Display Settings

`SettingsView` currently exposes:

```swift
Picker("Fullscreen:", selection: $config.fullscreenMode) {
    Text("Overlay").tag(FullscreenMode.overlay)
    Text("Desktop Only").tag(FullscreenMode.desktopOnly)
}

Picker("Displays:", selection: $config.displays) {
    Text("All Displays").tag(DisplayMode.all)
    Text("Main Only").tag(DisplayMode.main)
}
```

`HUDWindowManager.show(document:config:)` currently chooses screens like this:

```swift
let screens = config.displays == .main ? [NSScreen.main].compactMap { $0 } : NSScreen.screens
```

So the app only has two choices:

```text
all screens
NSScreen.main only
```

That is not enough for the full-screen-video case.

### Existing Fullscreen Behavior

`HUDWindowManager.collectionBehavior(for:)` currently does:

```swift
if config.fullscreenMode == .desktopOnly {
    return [.stationary, .ignoresCycle]
}
return [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
```

When `fullscreenMode == overlay`, HUD windows can join full-screen Spaces. This is required for the original DeskHUD use case, but it also means the HUD can appear over a full-screen video Space.

### Existing Settings UI

Current Settings has three tabs:

- Appearance
- Layout
- Behavior

It is functional but sparse. It exposes important controls, but lacks clearer grouping, explanations, diagnostics, and display targeting options.

## Root Cause

DeskHUD currently treats display selection as a static `all/main` choice.

That does not model the user's intent:

- Sometimes the user wants HUD on every display.
- Sometimes only on the primary work display.
- Sometimes only on the display containing the mouse.
- Sometimes only on one fixed display.
- Sometimes the user wants HUD to appear in full-screen Word/Safari/PowerPoint, but not over a full-screen video on another display.

`NSScreen.main` is also not a reliable product-level concept for this app. It can change based on active window, menu bar, display arrangement, and Spaces behavior. It is not the same as "the screen where I want DeskHUD".

## Product Principle

DeskHUD should remain read-only and extremely lightweight.

Settings may be richer, but runtime HUD behavior must stay passive:

- no HUD clicks
- no hover UI on HUD
- no continuous polling beyond necessary Dock-follow logic
- no AI integration inside the app
- no heavy window inspection loops

Display policy should be configurable and event-driven as much as possible.

## Required Product Behavior

Add explicit display targeting so the user can decide where HUD panels appear.

Recommended first-pass options:

```text
All Displays
Primary Display
Mouse Display
Fixed Display
```

Recommended later option:

```text
Active App Display
```

Optional future heuristic:

```text
Avoid Full-Screen Video
```

Do not make "avoid video" the first implementation if it becomes fragile. The stronger first fix is explicit user-controlled display targeting.

## Recommended Data Model

Replace or extend current `DisplayMode`.

Current likely model:

```swift
public enum DisplayMode: String, Codable, CaseIterable, Sendable {
    case all
    case main
}
```

Recommended model:

```swift
public enum DisplayMode: String, Codable, CaseIterable, Sendable {
    case all
    case primary
    case mouse
    case fixed

    // Optional future case:
    // case activeApp

    // Backward compatibility:
    // keep old `main` decoding if needed, then resolve it as `primary`.
}
```

If changing the enum risks migration pain, keep `.main` as a deprecated compatibility case and map it to `.primary` in screen resolution.

Add optional fixed display identity:

```swift
public var fixedDisplayID: String?
```

or, if using CG display identifiers:

```swift
public var fixedDisplayID: UInt32?
```

A readable config may look like:

```json
{
  "displays": "fixed",
  "fixedDisplayID": "1"
}
```

or:

```json
{
  "displays": "fixed",
  "fixedDisplayName": "Built-in Liquid Retina Display"
}
```

Prefer a stable display ID internally. Display names are friendlier, but may not be stable enough as stored config.

## Screen Resolution Strategy

Create a dedicated resolver instead of spreading display logic through `HUDWindowManager`.

Suggested type:

```swift
@MainActor
struct HUDDisplayResolver {
    static func screens(for config: HUDConfig) -> [NSScreen] {
        switch config.displays {
        case .all:
            return NSScreen.screens
        case .primary:
            return primaryScreen()
        case .mouse:
            return mouseScreen()
        case .fixed:
            return fixedScreen(config: config) ?? primaryScreen()
        }
    }
}
```

If `.main` remains for backward compatibility:

```swift
case .main:
    return primaryScreen()
```

Important: do not call expensive APIs continuously. Resolve screens when:

- app starts
- config changes
- display arrangement changes
- mouse moves to another display, only if using Mouse Display mode
- active app / active Space changes, only if activeApp mode is implemented later

### Primary Display

For DeskHUD product language, "Primary Display" should mean the display the user expects DeskHUD to use as the main work display.

Implementation options:

1. Use `NSScreen.screens.first` as a simple first pass.
2. Prefer the screen with the menu bar if detectable.
3. Let the user choose a fixed display and treat it as the DeskHUD primary display.

Avoid assuming `NSScreen.main` always matches user intent.

### Mouse Display

Find the screen containing `NSEvent.mouseLocation`.

This is useful for users who move between displays and want HUD to follow their current attention.

Do not update at 60 Hz except while Dock-follow is already active. Outside Dock-follow, update only when the mouse crosses into a different screen, with debounce.

### Fixed Display

Settings should list detected screens.

Suggested label format:

```text
Built-in Display - 3456 x 2234
LG UltraFine - 3840 x 2160
```

On missing display:

- show a Settings warning
- fall back to Primary Display
- do not crash

### Active App Display Later

This is harder and can be postponed.

Possible sources:

- `NSWorkspace.shared.frontmostApplication`
- Accessibility API focused window position
- fallback to Primary Display when permission is missing

If implemented, mark it as requiring Accessibility permission.

## Fullscreen Policy

The existing `fullscreenMode` is still useful but should be described more clearly.

Recommended Settings labels:

```text
Show in Full-Screen Spaces
Desktop Spaces Only
```

Current labels:

```text
Overlay
Desktop Only
```

are short, but vague.

### Future Fullscreen Exclusion

A future option could be:

```swift
public enum FullscreenExclusionPolicy: String, Codable, CaseIterable, Sendable {
    case none
    case avoidVideoApps
    case avoidPresentationApps
}
```

Example config:

```json
{
  "fullscreenMode": "overlay",
  "fullscreenExclusion": "avoidVideoApps"
}
```

But detecting "full-screen video" robustly is difficult. Safari, Chrome, YouTube, QuickTime, VLC, PowerPoint, and Keynote can all behave differently.

For now, explicit display targeting is more reliable.

## Window Manager Changes

### Replace Static Screen Selection

Current:

```swift
let screens = config.displays == .main ? [NSScreen.main].compactMap { $0 } : NSScreen.screens
```

Replace with:

```swift
let screens = HUDDisplayResolver.screens(for: config)
```

### Rebuild Windows When Target Screens Change

`reconfigure(config:)` currently updates existing windows without tearing them down. That is good for visual settings, but display target changes may require a different window set.

Add logic similar to:

```swift
func reconfigure(config: HUDConfig) {
    let oldScreenIDs = managedWindows.map { screenID($0.screen) }
    let newScreens = HUDDisplayResolver.screens(for: config)
    let newScreenIDs = newScreens.map { screenID($0) }

    if oldScreenIDs != newScreenIDs || config.displays != activeConfig?.displays {
        guard let document = activeDocument else { return }
        show(document: document, config: config)
        return
    }

    // existing lightweight update path for visual/layout changes
}
```

Keep the lightweight reconfigure path for opacity, width, height, margin, presentation, etc.

### Observe Display Changes

Add an observer for:

```swift
NSApplication.didChangeScreenParametersNotification
```

On screen changes:

- recalculate target screens
- rebuild windows if needed
- update `hud_context.json`

### Observe Mouse Screen Changes

Only for `displays == .mouse`:

- track current screen ID
- when mouse enters a different screen, rebuild HUD windows for that screen
- debounce to avoid churn

### Observe Active Space / App Changes Later

For future activeApp mode or fullscreen exclusion, consider:

```swift
NSWorkspace.activeSpaceDidChangeNotification
NSWorkspace.didActivateApplicationNotification
```

Do not add these observers for every mode if not needed.

## Settings UX Improvements

Settings should feel like a small native utility app, not a debug panel.

Recommended tabs:

```text
Display
Appearance
Content
Advanced
Diagnostics
```

If five tabs feels too many, use four tabs:

```text
Display
Appearance
Content
Advanced
```

and put diagnostics at the bottom of Advanced.

### Recommended Window Size

Current size is too cramped:

```swift
.frame(width: 420, height: 330)
```

Use something closer to:

```swift
.frame(width: 560, height: 460)
```

This is still compact, but gives the app enough room to breathe.

## Suggested Settings Tabs

### Display Tab

Fields:

- Display Target
- Fixed Display picker, enabled only when target is Fixed Display
- Full-Screen Spaces behavior
- resolved target screens
- short warning if fixed display is missing

Example labels:

```text
Display Target:      All Displays / Primary Display / Mouse Display / Fixed Display
Fixed Display:       Built-in Display - 3456 x 2234
Full-Screen Spaces:  Show HUD in full-screen Spaces / Desktop Spaces only
Resolved Target:     Built-in Display
```

Keep descriptions short and native-looking.

### Appearance Tab

Fields:

- Background style
- Effect profile
- Opacity
- Corner radius
- Font size
- Density
- Text opacity if already supported

### Content Tab

Fields:

- Left presentation
- Right presentation
- Scroll interval
- Max lines
- Calendar events
- Watch directory

This is more logical than putting presentation under Layout and watch directory under Behavior.

### Advanced Tab

Fields:

- Launch at Login
- Hide Menu Bar
- Debug Logging
- Reset to defaults
- Open config folder
- Open examples folder

These actions are normal utility-app controls and make DeskHUD feel more complete.

### Diagnostics Tab Or Section

Show:

- Status OK/Error
- Last reload time
- Last error
- Watch directory
- Active config source
- Accessibility permission status
- Resolved display target
- Resolved screen count
- Dock source: AX or fallback estimate, if easy to expose

This helps debug the exact display/full-screen issue users report.

## Settings Design Guidance

Do not make the UI decorative.

Use native macOS controls:

- `Form`
- `Picker`
- `Toggle`
- `Stepper`
- `Slider`
- `LabeledContent`
- `DisclosureGroup` for diagnostics if space is tight

Avoid card-heavy marketing layouts. DeskHUD Settings should feel calm, precise, and utility-like.

Recommended details:

- Use grouped sections with small headers.
- Align controls consistently.
- Keep labels readable.
- Prefer descriptive picker values over raw enum names.
- Apply changes live when safe.
- Rebuild HUD windows only when display target changes.

## Config Example

Update `Examples/config.json` with something like:

```json
{
  "fullscreenMode": "overlay",
  "displays": "primary",
  "fixedDisplayID": null,
  "backgroundStyle": "glass",
  "effectProfile": "low",
  "window": {
    "leftPresentation": "pagerRail",
    "rightPresentation": "stack",
    "width": 0,
    "height": 78,
    "margin": 12,
    "cornerRadius": 14,
    "opacity": 0.82,
    "maxLines": 2,
    "contentDensity": "compact",
    "fontSize": 13,
    "textOpacity": 0.92,
    "scrollIntervalSeconds": 6
  }
}
```

If maintaining old `"displays": "main"` compatibility, document that `main` is deprecated and maps to `primary`.

## CLI / Schema Updates

Update `deskhudctl schema` text.

Current:

```text
"displays": "all",               // all | main
```

New:

```text
"displays": "primary",           // all | primary | mouse | fixed
"fixedDisplayID": null,           // used when displays = fixed
```

Do not advertise `activeApp` as fully supported unless it is actually implemented.

## Testing Plan

Add unit tests for model decoding:

- old config with `"displays": "all"` decodes
- old config with `"displays": "main"` decodes or maps safely
- new config with `"displays": "primary"` decodes
- new config with `"displays": "mouse"` decodes
- new config with `"displays": "fixed"` decodes
- fixed mode with missing fixed ID falls back safely
- missing display fields use defaults

Add pure tests for resolver logic if possible:

- all returns all provided screens
- primary returns primary/fallback screen
- fixed returns matching screen
- fixed missing falls back to primary

If `NSScreen` is hard to unit test directly, isolate pure selection logic from AppKit structures.

## Manual Verification

Run:

```bash
cd /Users/hex/Documents/projects/DeskHuD
swift test
./script/build_and_run.sh --verify
```

Manual checks:

1. Set Display Target = All Displays. Confirm HUD appears on all displays.
2. Set Display Target = Primary Display. Confirm HUD appears only on intended primary display.
3. Play full-screen video on secondary display. Confirm HUD does not appear there when target is Primary Display.
4. Set Display Target = Fixed Display. Confirm HUD stays on that display.
5. Set Display Target = Mouse Display. Move mouse to another display and confirm HUD moves/rebuilds there after debounce.
6. Set Full-Screen Spaces = Desktop Spaces Only. Confirm HUD does not join full-screen Spaces.
7. Set Full-Screen Spaces = Show HUD in Full-Screen Spaces. Confirm HUD can still appear over full-screen Safari/Word/PowerPoint when target display matches.
8. Open Settings and change target display. Confirm windows rebuild cleanly without duplicate HUDs.
9. Confirm CPU stays near idle when nothing changes.

## Acceptance Criteria

- User can choose where DeskHUD appears from Settings.
- Full-screen video on another display no longer gets HUD panels when user selects Primary or Fixed Display.
- Existing configs continue to work.
- Settings is visibly richer and organized by real user intent.
- Display target changes apply live or with a clear one-click reload path.
- No duplicate HUD windows after changing display target.
- `hud_context.json` updates after target screen/window size changes.
- Tests cover config compatibility.
- `swift test` passes.

## Suggested Commit Split

```text
feat: add configurable HUD display targeting
feat: expand Settings display and diagnostics panes
test: cover display config compatibility
docs: document display targeting behavior
```

Keep Sparkle and notarized distribution out of this pass.
