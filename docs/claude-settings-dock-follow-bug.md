# DeskHUD Settings Window Dock-follow Bug Handoff

## Context

Project path:

```text
/Users/hex/Documents/projects/DeskHuD
```

Current user-reported bug:

1. DeskHUD normally follows the Dock width/magnification when the mouse moves over the Dock.
2. Open DeskHUD Settings from the menu bar.
3. Close Settings.
4. After closing Settings, the HUD no longer follows the Dock width/magnification reliably.
5. Click the desktop once, then return/move near the Dock again.
6. Dock-follow starts working again.

This strongly suggests an event-monitoring/lifecycle bug around DeskHUD becoming the active foreground app when Settings is opened.

## Current suspected root cause

In `Sources/DeskHUDApp/Windowing/HUDWindowManager.swift`, DeskHUD currently installs only a global mouse monitor:

```swift
private var mouseMonitor: Any?

private func installMouseMonitor(config: HUDConfig) {
    if mouseMonitor != nil { return }
    mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
        Task { @MainActor in
            self?.handleMouseMoved(config: config)
        }
    }
}
```

`NSEvent.addGlobalMonitorForEvents` is good for observing mouse movement while another app is active, but it does not reliably cover events delivered to DeskHUD itself while DeskHUD is foreground/key.

`SettingsWindowController.show()` does this:

```swift
func show() {
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}
```

So opening Settings activates DeskHUD. After closing Settings, DeskHUD may still be the active app. In that state, relying only on a global monitor means mouse movement near the Dock may not trigger `handleMouseMoved` consistently. Clicking the desktop makes another app/Finder active, and the global monitor starts seeing events again, which matches the user-observed recovery behavior.

There is also a smaller robustness issue: the global monitor closure captures `config` from install time. Settings changes update `activeConfig`, so monitor callbacks should read `activeConfig` at event time instead of retaining an older config value.

## Recommended fix

Use both a global and a local mouse monitor:

- Global monitor: observes mouse movement when another app is active.
- Local monitor: observes mouse movement when DeskHUD/Settings is active.
- Both should call the same `handleMouseMoved()` method.
- `handleMouseMoved()` should read `activeConfig` dynamically.

### Suggested patch shape

In `HUDWindowManager`, replace:

```swift
private var mouseMonitor: Any?
```

with:

```swift
private var globalMouseMonitor: Any?
private var localMouseMonitor: Any?
```

In `closeAll()`, replace the old removal block:

```swift
if let mouseMonitor {
    NSEvent.removeMonitor(mouseMonitor)
    self.mouseMonitor = nil
}
```

with:

```swift
if let globalMouseMonitor {
    NSEvent.removeMonitor(globalMouseMonitor)
    self.globalMouseMonitor = nil
}
if let localMouseMonitor {
    NSEvent.removeMonitor(localMouseMonitor)
    self.localMouseMonitor = nil
}
```

Replace `installMouseMonitor(config:)` and `handleMouseMoved(config:)` with:

```swift
private func installMouseMonitor(config: HUDConfig) {
    if globalMouseMonitor == nil {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleMouseMoved()
            }
        }
    }

    if localMouseMonitor == nil {
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleMouseMoved()
            }
            return event
        }
    }
}

private func handleMouseMoved() {
    guard let config = activeConfig else { return }
    lastMouseLocation = NSEvent.mouseLocation
    let shouldFollow = isInBottomDockTrackingArea(lastMouseLocation)
    if shouldFollow == isMouseNearBottomDock { return }

    isMouseNearBottomDock = shouldFollow
    if shouldFollow {
        stopIdleRefreshTimer()
        startDockFollowTimer()
    } else {
        stopDockFollowTimer()
        updateFrames(config: config, mouseLocation: nil)
        installIdleRefreshTimer()
    }
}
```

The `config` parameter on `installMouseMonitor(config:)` can be kept for minimal churn, even if unused, or removed and call sites updated. Keeping it is the smaller change.

## Why this fix is narrowly scoped

This fix does not change Dock geometry math, rendering, AX Dock bounds lookup, Settings UI, or configuration schema. It only ensures mouse movement is observed in both app-active and app-inactive states.

That matters because the bug is specifically triggered by opening Settings, which changes app activation state.

## Verification checklist

Run from the project root:

```bash
cd /Users/hex/Documents/projects/DeskHuD
swift test
/Users/hex/Documents/projects/DeskHuD/script/build_and_run.sh --verify
```

Manual verification:

1. Launch DeskHUD.
2. Move mouse over Dock and confirm HUD follows Dock width/magnification.
3. Open DeskHUD Settings from menu bar.
4. Close Settings.
5. Without clicking desktop, move mouse over Dock.
6. Confirm HUD still follows Dock width/magnification.
7. Change a Settings value that calls `reconfigure(config:)`, close Settings, repeat step 5.
8. Confirm CPU remains low when mouse is away from the Dock.

Optional log check if `debugLogging` is enabled:

```bash
tail -f /tmp/DeskHUDDockDebug.log
```

Expected: when hovering near Dock, logs should continue updating after Settings is closed, without requiring a desktop click.

## Existing nearby stability notes

There are currently a few other local fixes that may already be in the working tree depending on handoff timing:

1. `script/build_and_run.sh` should contain `cd "$ROOT_DIR"` near the top so absolute-path invocation works from `~`.
2. `HUDConfig` and `HUDWindowConfig` should decode missing config fields with defaults, so older `config.json` files remain valid after schema evolution.
3. Tests should cover missing `fontSize`, `textOpacity`, `launchAtLogin`, and `hideMenuBar` defaults.

If those changes are still uncommitted, avoid overwriting them.

## Suggested commit message

```text
fix: keep Dock follow active after Settings closes
```
