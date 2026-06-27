#!/usr/bin/env bash
set -euo pipefail

APP_NAME="DeskHUD"
APP_DIR="/Applications/$APP_NAME.app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DMG_PATH="$SCRIPT_DIR/../release/DeskHUD-v0.1.0.dmg"

echo "=== Installing DeskHUD ==="

# Kill running instance
pkill -x "$APP_NAME" 2>/dev/null || true

# If DMG exists, mount and copy
if [[ -f "$DMG_PATH" ]]; then
  echo "Mounting DMG..."
  MOUNT_POINT=$(hdiutil attach "$DMG_PATH" -nobrowse -noautoopen 2>&1 | grep /Volumes | awk '{print $NF}')
  cp -R "$MOUNT_POINT" "$APP_DIR"
  hdiutil detach "$MOUNT_POINT" 2>/dev/null
else
  # Dev install — copy from dist
  DIST_DIR="$SCRIPT_DIR/../dist"
  rm -rf "$APP_DIR"
  cp -R "$DIST_DIR/$APP_NAME.app" "$APP_DIR"
fi

echo "Installed to $APP_DIR"

# Launch
open "$APP_DIR"
echo "DeskHUD launched. Add to Login Items for auto-start."
echo ""
echo "=== Update instructions ==="
echo "Menu bar → Check for Updates... → download latest DMG → reinstall"
