# DeskHUD Display Types And Visual Strategy Handoff

## Purpose

This is a product/design handoff for Claude Code.

The user wants DeskHUD to feel more useful and polished visually, while staying quiet, native, low-resource, and file-driven. Do not turn DeskHUD into a dashboard or widget gallery.

This document explains:

- How to improve the visual language of HUD items.
- What content types are worth supporting beyond plain text and progress bars.
- Which new item types should be considered first.
- Which examples and schema docs should be updated.

## Product Constraint

DeskHUD is a persistent macOS HUD. It lives beside the Dock and is visible for long periods.

Therefore default content should be:

- glanceable
- sparse
- actionable
- low-motion
- low-contrast enough to avoid distraction
- structured enough for AI agents to write correctly

Avoid:

- decorative progress bars
- motivational filler
- large dashboards
- dense cards
- noisy animations
- too many renderer types at once

## Current Renderer Types

The current model supports these item types:

```text
text
status
metric
progress
list
```

This is a good MVP base. It should not be thrown away.

The next design step should not simply add many more `type` values. Instead, DeskHUD should clarify the difference between:

```text
type = rendering shape
kind = semantic purpose
```

Example:

```json
{
  "type": "text",
  "kind": "event",
  "title": "14:30 Group meeting",
  "subtitle": "Prepare 3 progress slides"
}
```

Here `type: text` says how it renders. `kind: event` says what it means.

## Recommended Display Language

The default visual unit should feel like an information strip, not a full card stack.

Each item should usually fit into this pattern:

```text
Primary object / event / state
Secondary action / explanation / time
```

Examples:

```text
14:30 Group meeting
Prepare 3 progress slides
```

```text
DeskHUD
Stabilize release flow before adding features
```

```text
Claude Code
running tests
```

This two-line pattern keeps the HUD readable and makes it easy for AI writers to generate useful content.

## Left And Right Panel Roles

Use the content strategy from `docs/claude-hud-content-strategy.md` if present.

Default convention:

```text
Left Dock HUD  = Now Queue / today's execution layer
Right Dock HUD = Context Card / judgment layer
```

Left examples:

```text
14:30 Meeting
Join in 12m

DeskHUD
Test release package
```

Right examples:

```text
DeskHUD
Stabilize display core first

Today
Prefer boundary tests over new UI
```

## Display Type Recommendations

### Keep Existing Types

#### `text`

Most important type. Should remain the default for context, focus, events, reflections, and simple agent messages.

Use for:

- focus
- context
- event summary
- reflection
- next action

#### `status`

Good for compact state. Should be used when state color matters.

Use for:

- pending / running / done / blocked
- simple task state
- service state
- agent phase state

#### `metric`

Useful when the number itself matters.

Use for:

- failed tests count
- unread PR count
- current temperature
- remaining tasks
- writing word count
- CI queue count

Avoid using metrics for vanity numbers.

#### `progress`

Keep it, but demote it. It should not be the default right-panel content.

Use only for real active processes:

- AI agent progress
- build/test/release progress
- sync/upload/download percentage
- timer/focus countdown if value is measurable
- known multi-step workflow

Avoid:

- subjective long-term goals
- life progress
- vague MVP percentage

#### `list`

Useful but dangerous. Lists can make the HUD dense.

Use only for very short lists, ideally 2-3 lines.

Good:

```text
Release
- test
- package
- notarize
```

Bad:

```text
12 todo items in a tiny panel
```

## Suggested New Types

Do not add all of these immediately. Treat this as a roadmap.

### Tier 1: High Value, Low Complexity

These are worth considering first.

#### `countdown`

Purpose: show time remaining until something important.

Use for:

- meeting starts in 12m
- deadline today
- focus session remaining
- break timer
- release window

Suggested JSON:

```json
{
  "id": "meeting-countdown",
  "type": "countdown",
  "kind": "event",
  "title": "Group meeting",
  "label": "in 12m",
  "time": "14:30",
  "state": "warning"
}
```

Visual idea:

```text
14:30 Group meeting     in 12m
Prepare slides
```

This can render as text first. A circular timer or tiny bar can come later.

#### `alert`

Purpose: temporary override for things that need attention.

Use for:

- failed tests
- blocked agent
- sync error
- upcoming meeting
- release failure
- config parse error

Suggested JSON:

```json
{
  "id": "tests-failed",
  "type": "alert",
  "kind": "build",
  "title": "Tests failed",
  "subtitle": "Config decode regression",
  "state": "error"
}
```

Visual idea:

```text
Tests failed
Config decode regression
```

Make it visually distinct but not loud: color accent, stronger title weight, maybe a subtle left edge or icon. Avoid flashing.

#### `agent`

Purpose: first-class display for AI agent work.

Use for:

- Claude Code
- Codex
- build scripts
- test runners
- release automation

Suggested JSON:

```json
{
  "id": "claude-code",
  "type": "agent",
  "kind": "aiProgress",
  "title": "Claude Code",
  "subtitle": "updating renderer docs",
  "label": "testing",
  "state": "running",
  "value": 0.6
}
```

Visual idea:

```text
Claude Code        testing
updating renderer docs
```

If `value` exists, it may show a tiny progress indicator. If not, it should still render cleanly as status text.

### Tier 2: Useful Later

#### `checklist`

Purpose: compact multi-step workflow.

Use for:

- release checklist
- meeting prep
- task stages

Suggested JSON extension may require structured fields later. For now, this can be represented with `type: list`.

Do not implement as a new type unless `list` proves insufficient.

#### `timeline`

Purpose: small schedule strip for the left panel.

Use for:

- upcoming events
- today agenda
- deadline sequence

This is attractive, but more complex. It needs careful layout to avoid clutter.

#### `sparkline` / `trend`

Purpose: tiny trend line.

Use for:

- focus time trend
- commits over week
- sleep trend
- weather change

This is nice but not urgent. It requires array values and a renderer. Keep for later.

#### `weather`

Purpose: environment context.

Use for:

- weather now
- rain warning
- temperature
- sunset

Can be represented with `metric` or `text` for now. Do not add a dedicated renderer yet.

#### `git`

Purpose: developer project status.

Use for:

- branch
- dirty state
- PR count
- CI failure

Could be represented through `status`, `metric`, and `alert` first.

## Recommended Implementation Scope

For the next Claude Code pass, prefer a conservative update.

### Recommended Scope A: Documentation + Examples Only

Safest and fastest.

Update:

- `Examples/hud_leftDock.json`
- `Examples/hud_rightDock.json`
- `Sources/deskhudctl/main.swift` schema/sample text
- `README.md`

Explain:

- type vs kind
- progress bar policy
- suggested kinds
- future types
- AI writing rules

No renderer changes.

### Recommended Scope B: Add `alert` Type Only

Small renderer addition.

Add:

- `case alert` to `HUDItemType`
- `AlertItemRenderer.swift`
- renderer registration in `AppDelegate`
- schema/sample docs
- decoding tests

This gives immediate value for errors and urgent states.

### Recommended Scope C: Add `alert` + `countdown`

Useful, but slightly larger.

Add:

- `alert`
- `countdown`
- docs and examples
- tests

Only choose this if there is enough time to keep the code tidy.

## Recommendation

Start with Scope A, then add Scope B.

Reason:

DeskHUD's current weakness is not lack of renderers. It is that AI writers do not yet have a strong display grammar. Better examples and schema guidance will improve output immediately without increasing maintenance cost.

After examples/schema are clear, `alert` is the best first new renderer because it maps to real user value: tests failed, build blocked, meeting soon, sync broken.

`countdown` should be second because it is excellent for the left panel, but time handling and formatting deserve a little more care.

## Visual Style Guidance

Default styling should feel like native system HUD text, not a web dashboard.

Rules:

- Keep each item to 1-2 lines.
- Use title weight for the object, subtitle for action/context.
- Use color only for semantic state.
- Avoid large icons unless they carry meaning.
- Avoid flashing, bouncing, or decorative animation.
- Prefer opacity/slide/fade transitions.
- Preserve readability over decoration.
- Right panel should feel calmer than left panel.

State color intent:

```text
done / ok / ready       green
running / working       cyan or blue
warning / blocked       yellow
error / failed          red
pending / idle          dim white
```

## AI Writing Rules

AI agents writing HUD JSON should follow these rules:

1. Prefer `text` unless another type is clearly better.
2. Use `status` when state matters.
3. Use `metric` when a number matters.
4. Use `progress` only for a real active process.
5. Use `alert` for temporary urgent states, if implemented.
6. Use `countdown` for time-sensitive upcoming events, if implemented.
7. Keep every title short.
8. Keep every subtitle action-oriented.
9. Avoid generic motivational text.
10. If unsure, show less.

## Example: Improved Right Panel

```json
{
  "sections": [
    {
      "id": "context",
      "title": null,
      "items": [
        {
          "id": "ctx1",
          "type": "text",
          "kind": "focus",
          "title": "DeskHUD",
          "subtitle": "Stabilize display core before adding features"
        },
        {
          "id": "ctx2",
          "type": "text",
          "kind": "reflection",
          "title": "Today",
          "subtitle": "Prefer boundary tests over new UI ideas"
        }
      ]
    }
  ],
  "items": []
}
```

## Example: Active Agent Right Panel

If `agent` is not implemented yet, represent this with `status` or `progress`.

```json
{
  "sections": [
    {
      "id": "active-process",
      "title": null,
      "items": [
        {
          "id": "agent1",
          "type": "progress",
          "kind": "aiProgress",
          "title": "Claude Code",
          "subtitle": "updating display docs",
          "label": "testing",
          "value": 0.64,
          "state": "running"
        },
        {
          "id": "next1",
          "type": "text",
          "kind": "systemStatus",
          "title": "Next",
          "subtitle": "Package after tests pass"
        }
      ]
    }
  ],
  "items": []
}
```

## Example: Alert If Implemented

```json
{
  "sections": [
    {
      "id": "urgent",
      "title": null,
      "items": [
        {
          "id": "tests-failed",
          "type": "alert",
          "kind": "build",
          "title": "Tests failed",
          "subtitle": "Fix config decode regression",
          "state": "error"
        }
      ]
    }
  ],
  "items": []
}
```

## Example: Countdown If Implemented

```json
{
  "sections": [
    {
      "id": "now",
      "title": "Now",
      "items": [
        {
          "id": "meeting",
          "type": "countdown",
          "kind": "event",
          "title": "Group meeting",
          "subtitle": "Prepare 3 progress slides",
          "label": "in 12m",
          "time": "14:30",
          "state": "warning"
        }
      ]
    }
  ],
  "items": []
}
```

## Files Claude Code May Update

For docs/examples only:

- `docs/claude-hud-content-strategy.md` if present
- `Examples/hud_leftDock.json`
- `Examples/hud_rightDock.json`
- `Sources/deskhudctl/main.swift`
- `README.md`

For `alert` renderer:

- `Sources/DeskHUDCore/Models/HUDModels.swift`
- `Sources/DeskHUDApp/Rendering/AlertItemRenderer.swift`
- `Sources/DeskHUDApp/App/AppDelegate.swift`
- `Tests/DeskHUDCoreTests/HUDModelDecodingTests.swift`
- `Sources/deskhudctl/main.swift`
- example JSON files

For `countdown` renderer:

- same model/registry/test/schema files as above
- likely `CountdownItemRenderer.swift`

## Acceptance Criteria

For Scope A:

1. README and CLI schema explain type vs kind.
2. Examples stop using decorative long-term progress bars as default content.
3. Examples demonstrate left as Now Queue and right as Context Card.
4. Schema explains when progress bars should and should not be used.
5. No app behavior changes.
6. `swift test` passes.

For Scope B:

1. `alert` decodes as a valid `HUDItemType`.
2. `AlertItemRenderer` displays title/subtitle cleanly.
3. `state` controls alert color.
4. Existing item types still work.
5. CLI schema documents `alert`.
6. `swift test` passes.

For Scope C:

1. `countdown` decodes as a valid `HUDItemType`.
2. It renders a compact event/time row.
3. It does not require DeskHUD to continuously poll.
4. AI can either write a precomputed `label` such as `in 12m`, or future code can compute it from `time`.
5. `swift test` passes.

## Verification Commands

Run:

```bash
cd /Users/hex/Documents/projects/DeskHuD
swift test
swift run deskhudctl schema
swift run deskhudctl sample left
swift run deskhudctl sample right
/Users/hex/Documents/projects/DeskHuD/script/build_and_run.sh --verify
```

If new item types are added, also validate sample JSON that includes them.

## Suggested Commit Messages

For docs/examples only:

```text
docs: define HUD display type strategy
```

For alert renderer:

```text
feat: add alert HUD item renderer
```

For countdown renderer:

```text
feat: add countdown HUD item renderer
```
