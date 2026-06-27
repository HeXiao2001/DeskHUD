# DeskHUD HUD Content Strategy Handoff

## Purpose

This document is a product/content handoff for Claude Code.

The goal is not to redesign DeskHUD rendering. The current native overlay, Dock-follow behavior, file watcher, CLI, and JSON schema should stay intact unless a small text/schema/sample update is required.

The goal is to improve what DeskHUD recommends by default:

- What should the left Dock HUD show?
- What should the right Dock HUD show?
- When should progress bars be used?
- How should AI agents write concise, useful HUD JSON?

DeskHUD is a persistent HUD system, not a dashboard and not a decorative widget. It should reduce cognitive load.

## Product Principle

DeskHUD has only two default panels:

```text
Left Dock HUD  = Today / execution layer
Right Dock HUD = Context / judgment layer
```

Short version:

> Left pulls the user back to today. Right pulls the user back to direction.

The left panel answers:

```text
What should I pay attention to next?
```

The right panel answers:

```text
Why am I doing this, and what is the next good decision?
```

## Current Issue

The current right panel sample is something like:

```text
💡 Next        Review open PRs
DeskHUD MVP   7/1 -> 7/15 progress bar
```

This is not bad, but the progress bar is often weak as persistent HUD content.

A long-term project progress bar is usually subjective and low-action. It can look useful while not changing what the user should do next. In a persistent HUD, every line competes with attention, so default content should be more directly useful.

## Recommended Default Model

### Left Panel: Now Queue

The left panel should be operational. It should show the immediate queue of things the user may need to act on today.

Recommended priority order:

1. Active meeting / current time-sensitive event
2. Next meeting / upcoming deadline
3. Current focus task
4. Blocked item that needs attention
5. 1-2 important remaining tasks for today

Good left-panel content:

```text
14:30  Group meeting
Prepare 3 progress slides

DeskHUD
Test Settings Dock-follow fix
```

Bad left-panel content:

```text
Productivity
Be better today
```

### Right Panel: Context Card

The right panel should not be another todo list. It should be stable, quiet context.

Recommended priority order:

1. Active agent/build/test/release state, if something is actually running
2. Current project context
3. One-line next decision
4. Short reflection or warning
5. Long-term direction, only if it affects today

Good right-panel content:

```text
DeskHUD
Stabilize release flow before adding features

Today
Less feature work, more boundary testing
```

Bad right-panel content:

```text
Life Goal 72%
Become excellent
```

## Progress Bar Policy

Progress bars should not be used as default decoration.

Use progress bars only for real, measurable, active processes:

- Claude Code / Codex / other AI agent progress
- Build / test / packaging / release process
- Download / upload / sync with real percentage
- Timer, meeting countdown, focus session countdown
- Multi-step workflow with known stages

Do not use progress bars for vague long-term goals:

- MVP 72%
- Life goal 40%
- Weekly growth 60%
- Writing project 0.35 unless this is backed by a real measurable source

If a progress bar is used, its `label` should explain the concrete phase, not a vague date range.

Prefer:

```json
{
  "id": "agent1",
  "type": "progress",
  "kind": "aiProgress",
  "title": "Claude Code",
  "label": "running tests",
  "value": 0.64,
  "state": "running"
}
```

Avoid:

```json
{
  "id": "goal1",
  "type": "progress",
  "kind": "goal",
  "title": "DeskHUD MVP",
  "label": "7/1 -> 7/15",
  "value": 0.72,
  "state": "running"
}
```

## Content Priority Protocol For AI Writers

AI agents or scripts that write `hud_leftDock.json` and `hud_rightDock.json` should follow this protocol.

### Emergency Override

If there is an error, failed test, blocked release, or urgent meeting, show that first.

Examples:

```text
Tests failed
Fix config decode regression
```

```text
14:00 Meeting
Join in 5 minutes
```

### Agent-running Override

If Claude Code, Codex, build, test, or release is actively running, the right panel may temporarily become an active process card.

Example:

```text
Claude Code
Refactoring Settings monitor

Tests
swift test running
```

Use a progress item only if progress is real or phase-based.

### Calm Default

If nothing urgent is happening:

- Left: today / now / next concrete actions
- Right: project context / one-line judgment

### Sparse Is Better Than Filler

If the AI is unsure what to display, it should write fewer items.

Do not fill the HUD with generic motivational text, decorative progress, or redundant status.

## Recommended Example Files

### `Examples/hud_leftDock.json`

Recommended sample:

```json
{
  "sections": [
    {
      "id": "now",
      "title": "Now",
      "items": [
        {
          "id": "focus1",
          "type": "text",
          "kind": "focus",
          "title": "DeskHUD",
          "subtitle": "Test Settings Dock-follow fix"
        },
        {
          "id": "next1",
          "type": "status",
          "kind": "todo",
          "title": "Run release checks",
          "label": "next",
          "state": "pending"
        }
      ]
    },
    {
      "id": "agenda",
      "title": "Agenda",
      "items": [
        {
          "id": "event1",
          "type": "text",
          "kind": "event",
          "title": "14:30 Group meeting",
          "subtitle": "Prepare 3 progress slides"
        }
      ]
    }
  ],
  "items": []
}
```

### `Examples/hud_rightDock.json`

Recommended sample:

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

### Active Agent Example For Right Panel

This is a temporary state, not the default sample:

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
          "label": "running tests",
          "value": 0.64,
          "state": "running"
        },
        {
          "id": "agent2",
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

## Suggested Code/documentation Updates

Claude Code should make small, focused updates only.

Recommended files to update:

1. `Examples/hud_leftDock.json`
2. `Examples/hud_rightDock.json`
3. `Sources/deskhudctl/main.swift`
4. `README.md`

### `Examples/hud_leftDock.json`

Replace the current generic focus/tasks sample with a Now Queue sample.

### `Examples/hud_rightDock.json`

Replace the default progress-bar sample with a Context Card sample.

### `Sources/deskhudctl/main.swift`

Update CLI schema text and sample output so AI writers learn the new policy:

- Left panel = Now Queue
- Right panel = Context Card
- Progress bars only for real active processes
- Sparse content is better than filler

Also update `rightSample` if it currently uses a default long-term progress bar.

### `README.md`

Add a short section, likely under AI Integration or Architecture:

```text
Default content convention:
Left Dock = today's execution queue.
Right Dock = quiet context and next decision.
Progress bars are reserved for real active processes such as agents, builds, tests, sync, or timers.
```

## Acceptance Criteria

After the update:

1. Default left sample clearly shows concrete next actions.
2. Default right sample no longer uses a decorative long-term progress bar.
3. CLI schema tells AI agents when to use progress bars and when not to.
4. README explains the left/right convention in one short section.
5. Existing app behavior does not change.
6. `swift test` passes.
7. `swift run deskhudctl sample right` outputs a context-card style sample, not a vague goal progress sample.

## Verification Commands

Run:

```bash
cd /Users/hex/Documents/projects/DeskHuD
swift test
swift run deskhudctl schema
swift run deskhudctl sample left
swift run deskhudctl sample right
swift run deskhudctl validate config Examples/config.json
```

If validation supports per-slot files, also validate:

```bash
swift run deskhudctl validate slot Examples/hud_leftDock.json
swift run deskhudctl validate slot Examples/hud_rightDock.json
```

If validation does not yet support per-slot files, do not expand scope unless requested. This handoff is primarily a content-strategy update.

## Suggested Commit Message

```text
docs: define default HUD content strategy
```

or, if examples and CLI samples are updated:

```text
feat: refine default HUD content strategy
```
