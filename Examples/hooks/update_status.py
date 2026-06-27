#!/usr/bin/env python3
"""
Claude Code → DeskHUD hook integration.

Usage (from .claude/settings.json hooks):
  {
    "Stop":        [{ "command": "python3 Examples/hooks/update_status.py idle" }],
    "PreToolUse":  [{ "command": "python3 Examples/hooks/update_status.py working" }],
    "PostToolUse": [{ "command": "python3 Examples/hooks/update_status.py working" }]
  }

Writes to Examples/hud_rightDock.json so DeskHUD shows live Claude Code state.
"""

import json, os, sys, time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(os.path.dirname(SCRIPT_DIR))
TARGET = os.path.join(PROJECT_DIR, "hud_rightDock.json")
TMP = TARGET + ".tmp"

STATE = sys.argv[1] if len(sys.argv) > 1 else "idle"

# Read current state from stdin (Claude Code hands hook metadata as JSON on stdin)
try:
    hook_input = json.load(sys.stdin)
except Exception:
    hook_input = {}

tool_name = hook_input.get("tool_name", "")
tool_input = hook_input.get("tool_input", {})
session_name = hook_input.get("session_name", "Claude Code")

# ── Build DeskHUD slot content ──────────────────────────────────────────
progress_value = 0.0
label = ""

if STATE == "idle":
    label = "Ready"
    progress_value = 1.0
elif STATE == "working":
    label = tool_name if tool_name else "Thinking"
    progress_value = 0.5  # unknown progress → show indeterminate-ish
elif STATE == "done":
    label = "Done"
    progress_value = 1.0

now = time.strftime("%H:%M")

payload = {
    "sections": [
        {
            "id": "live",
            "title": "Live",
            "items": [
                {
                    "id": "ai-progress",
                    "type": "progress",
                    "kind": "aiProgress",
                    "title": session_name,
                    "label": label,
                    "value": progress_value,
                    "state": "thinking" if STATE == "working" else STATE
                },
                {
                    "id": "current-tool",
                    "type": "text",
                    "kind": "focus",
                    "title": "Tool",
                    "subtitle": tool_name if tool_name else "-",
                    "time": now
                },
                {
                    "id": "branch",
                    "type": "status",
                    "kind": "systemStatus",
                    "title": "Branch",
                    "label": "main",
                    "state": "ok"
                }
            ]
        }
    ],
    "items": []
}

# ── Atomic write ─────────────────────────────────────────────────────────
os.makedirs(os.path.dirname(TARGET), exist_ok=True)
with open(TMP, "w") as f:
    json.dump(payload, f, indent=2)
    f.flush()
    os.fsync(f.fileno())
os.replace(TMP, TARGET)
