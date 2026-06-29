# DeskHUD Pager Rail And Preset UX Handoff

## Purpose

This document refines DeskHUD's default UX direction while preserving its core open-source promise:

> DeskHUD is a customizable HUD surface. Defaults are opinionated, but user content is not constrained by our personal workflow taste.

The user likes the default idea of:

```text
Left = short-term / today / next actions
Right = long-term / context / direction
```

But this must be treated as a **default preset**, not a hard product rule.

Users and AI agents should be able to decide what each side means by writing JSON and config. DeskHUD should provide good display primitives, not force a life-management philosophy.

## Current UX Problem

`HUDPanelView` currently renders a `VStack` of visible items and clips the panel. Even with `maxVisibleItems() = 2`, a third row can visually leak through when text height or spacing changes.

This makes the HUD feel like a clipped list rather than an intentional carousel.

The left panel also lacks a clear sense of position:

- How many items are in the queue?
- Which item is currently active?
- Is there more content after this?
- Does this item correspond to a time/event/state?

## Design Direction

### Left Default Preset: Focus Pager + Timeline Rail

For the default left panel preset, show one primary item at a time and a compact bottom rail.

Visual concept:

```text
14:30 Group meeting
Prepare 3 progress slides

●──○──○──○──+2
```

or:

```text
DeskHUD
Test release flow

○──●──○──○
```

The rail solves three problems:

1. It shows current position.
2. It shows the number of upcoming items.
3. It makes rotation feel intentional instead of like clipped overflow.

### Right Default Preset: Project Compass

The default right panel should avoid repeating the left panel's concrete todo items.

Right default should be calmer and higher-level:

```text
DeskHUD
Stabilize display layer

Decision
Ship reliability before new widgets
```

or:

```text
Today
Fewer features, more testing

Risk
Launchpad packaging still unverified
```

The right panel answers:

```text
What direction am I in?
What decision/risk/context should I remember?
```

It should not simply duplicate:

```text
Run release checks
```

if the left side already says that.

## Important Product Principle: Presets, Not Hard Rules

Do not hardcode the meaning of left and right.

Good:

```text
default preset: left = now queue, right = project compass
user override: left/right can display anything
```

Bad:

```text
left side must always be short-term
right side must always be long-term
```

DeskHUD should be flexible enough for users who want:

- left = calendar, right = system status
- left = build queue, right = AI agent progress
- left = weather, right = todos
- left = personal routine, right = project risk
- left/right both fully AI-authored

The default examples and schema guidance can be opinionated. The renderer and schema should remain general.

## Proposed Config Model

Keep this conservative. The first implementation can hardcode the default behavior by anchor, but the design should move toward configurable presentation.

Recommended future config shape:

```json
{
  "slots": {
    "leftDock": {
      "presentation": "pagerRail"
    },
    "rightDock": {
      "presentation": "stack"
    }
  }
}
```

Possible presentation values:

```text
stack       Existing 1-2 item stack behavior
pagerRail   One active item plus bottom node rail
minimal     One item only, no rail
```

If adding config is too much for the next pass, implement a minimal internal rule:

```text
dock.left  -> pagerRail
dock.right -> stack
```

But keep the code structured so a future `presentation` setting can select the layout without rewriting `HUDPanelView`.

## Left Pager Rail Rules

### Active Item

For `pagerRail`, render exactly one item:

```swift
let activeItem = section.items[scrollOffset % section.items.count]
```

Do not render a hidden clipped list.

This fixes the third-line leakage.

### Rail Node Count

Recommended:

```text
max visible nodes = 5
```

If total item count is <= 5, show all nodes:

```text
●──○──○──○
```

If total item count is > 5, show a sliding window around the active item plus `+N` overflow:

```text
○──●──○──○──+3
```

Simpler first version:

- show first 5 nodes
- if active item is after the first 5, make the 5th node active and show `+N`

Better later version:

- sliding node window centered on active index

### Node State

Each node can reflect item state:

```text
done / ok / ready       green
running / working       cyan or blue
warning / blocked       yellow
error / failed          red
pending / idle          dim white
```

Current node should be larger or brighter.

### Node Label

Node label is optional. Keep it tiny.

Priority:

```text
item.time -> item.label -> empty
```

Examples:

```text
14:30
next
now
```

If labels make the rail crowded, hide labels by default and only show the active item's label as right-side text above the rail.

### Animation

When `scrollOffset` changes:

- active item fades/slides
- current node changes in sync
- no complex animation
- no continuous motion while idle

## Right Project Compass Rules

Right side default should show up to two context items, but they should be semantically different from left-side action items.

Recommended content kinds:

```text
context
focus
decision
risk
reflection
summary
agent
systemStatus
```

Avoid default right content that is only another todo.

Good right content:

```json
{
  "type": "text",
  "kind": "decision",
  "title": "Decision",
  "subtitle": "Ship reliability before new widgets"
}
```

```json
{
  "type": "alert",
  "kind": "risk",
  "title": "Risk",
  "subtitle": "DMG verification still pending",
  "state": "warning"
}
```

Avoid right content like:

```json
{
  "type": "status",
  "kind": "todo",
  "title": "Run release checks",
  "state": "pending"
}
```

unless the user explicitly wants right-side todos.

## De-duplication Guidance For AI Writers

DeskHUD itself does not need to enforce de-duplication in code. This should be guidance in CLI schema and README.

Protocol:

```text
Left = concrete action/event
Right = context/decision/risk behind the action
```

If left says:

```text
Run release checks
```

Right should not say:

```text
Next: Run release checks
```

Right should say something one level higher:

```text
Release
Verify install path before publishing
```

or:

```text
Risk
Launchpad indexing still uncertain
```

## Suggested Implementation Plan For Claude Code

### Scope A: Fix Left Rendering Leakage + Add Pager Rail

Files likely involved:

- `Sources/DeskHUDApp/Views/HUDPanelView.swift`
- optionally new `Sources/DeskHUDApp/Views/TimelineRailView.swift`

Changes:

1. Detect left Dock slots with `slot.anchor == .dockLeft`.
2. For left Dock, render one active item instead of `visibleItems` stack.
3. Add bottom rail under active item.
4. Ensure panel height is respected without clipping ghost rows.
5. Keep right Dock stack behavior unchanged.

### Scope B: Make Presentation Configurable

Only do this if small and clean.

Potential model addition:

```swift
public enum HUDPresentation: String, Codable, Sendable {
    case stack
    case pagerRail
    case minimal
}
```

Possible config placement:

```swift
HUDWindowConfig.leftPresentation
HUDWindowConfig.rightPresentation
```

However, avoid over-expanding config if this slows the release. A default-by-anchor implementation is acceptable for first pass as long as the code is easy to generalize.

### Scope C: Update Examples And Docs

Update examples so defaults show:

- left = pager-friendly queue with several items
- right = context/decision/risk, not duplicate todo

Update:

- `Examples/hud_leftDock.json`
- `Examples/hud_rightDock.json`
- `Sources/deskhudctl/main.swift` schema text
- `README.md`

## Example Left JSON For Pager Rail

```json
{
  "sections": [
    {
      "id": "today",
      "title": "Today",
      "items": [
        {
          "id": "event1",
          "type": "countdown",
          "kind": "event",
          "title": "Group meeting",
          "subtitle": "Prepare 3 progress slides",
          "time": "14:30",
          "label": "in 12m",
          "state": "warning"
        },
        {
          "id": "focus1",
          "type": "text",
          "kind": "focus",
          "title": "DeskHUD",
          "subtitle": "Test release package",
          "label": "now",
          "state": "running"
        },
        {
          "id": "task1",
          "type": "status",
          "kind": "todo",
          "title": "Verify Launchpad",
          "label": "next",
          "state": "pending"
        },
        {
          "id": "task2",
          "type": "status",
          "kind": "todo",
          "title": "Update README install notes",
          "state": "pending"
        }
      ]
    }
  ],
  "items": []
}
```

## Example Right JSON For Project Compass

```json
{
  "sections": [
    {
      "id": "compass",
      "title": null,
      "items": [
        {
          "id": "ctx1",
          "type": "text",
          "kind": "context",
          "title": "DeskHUD",
          "subtitle": "Stabilize display layer before adding widgets"
        },
        {
          "id": "risk1",
          "type": "alert",
          "kind": "risk",
          "title": "Risk",
          "subtitle": "DMG verification still pending",
          "state": "warning"
        }
      ]
    }
  ],
  "items": []
}
```

## Acceptance Criteria

### UX

- Left panel no longer shows ghost/clipped third item.
- Left panel shows exactly one active item in pager mode.
- Left panel bottom rail reflects the active item.
- If there are more items than visible nodes, the rail communicates overflow.
- Right panel remains calm and does not duplicate default left actions.

### Product Flexibility

- The implementation does not hardcode that left must always be short-term and right must always be long-term as a product rule.
- Defaults can be opinionated.
- JSON authors can still put any supported item type on either side.
- Future config can choose presentation per slot.

### Technical

- No continuous high-frequency work is added while idle.
- Animation remains fade/slide/opacity only.
- Existing item renderers continue to work.
- `swift test` passes.
- `script/build_and_run.sh --verify` passes if local permissions allow launching.

## Verification Commands

```bash
cd /Users/hex/Documents/projects/DeskHuD
swift test
./script/build_and_run.sh --verify
swift run deskhudctl sample left
swift run deskhudctl sample right
```

Manual checks:

1. Put 1 item in left JSON: rail should handle it gracefully.
2. Put 4 items in left JSON: rail shows 4 nodes.
3. Put 8 items in left JSON: rail shows overflow.
4. Wait for auto-scroll: active text and node update together.
5. Confirm no third item is visible through clipping.
6. Confirm right panel still shows normal stack/context content.

## Suggested Commit Message

```text
feat: add left pager rail presentation
```

If only docs/examples are updated first:

```text
docs: define pager rail and preset UX
```
