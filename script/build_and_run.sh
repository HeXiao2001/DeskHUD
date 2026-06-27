#!/usr/bin/env bash
set -euo pipefail

APP_NAME="DeskHUD"
BUNDLE_ID="dev.hex.deskhud"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
EXECUTABLE="$ROOT_DIR/.build/debug/$APP_NAME"

VERIFY=false
if [[ "${1:-}" == "--verify" ]]; then
  VERIFY=true
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
swift build --product "$APP_NAME"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources/Examples"
cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Examples/config.json" "$APP_DIR/Contents/Resources/Examples/config.json"
cp "$ROOT_DIR/Examples/hud.json" "$APP_DIR/Contents/Resources/Examples/hud.json"
cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/open -n "$APP_DIR"

if [[ "$VERIFY" == true ]]; then
  sleep 1
  pgrep -x "$APP_NAME" >/dev/null
  echo "$APP_NAME is running"
fi
