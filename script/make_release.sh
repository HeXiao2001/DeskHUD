#!/usr/bin/env bash
set -euo pipefail

APP_NAME="DeskHUD"
BUNDLE_ID="dev.hex.deskhud"
VERSION="${1:-0.1.0}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release"
APP_DIR="$RELEASE_DIR/$APP_NAME.app"
CERT_NAME="DeskHUD Development"

echo "=== Building DeskHUD v$VERSION (release) ==="

# Clean
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Release build
swift build -c release --product "$APP_NAME"

# Assemble app bundle
mkdir -p "$APP_DIR/Contents/MacOS" \
         "$APP_DIR/Contents/Resources/Examples"

cp "$ROOT_DIR/.build/release/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Examples/config.json" "$APP_DIR/Contents/Resources/Examples/config.json"
cp "$ROOT_DIR/Examples/hud.json" "$APP_DIR/Contents/Resources/Examples/hud.json"
cp "$ROOT_DIR/Examples/hud_leftDock.json" "$APP_DIR/Contents/Resources/Examples/hud_leftDock.json" 2>/dev/null || true
cp "$ROOT_DIR/Examples/hud_rightDock.json" "$APP_DIR/Contents/Resources/Examples/hud_rightDock.json" 2>/dev/null || true

# Icon
if [[ -f "$ROOT_DIR/script/DeskHUD.icns" ]]; then
  cp "$ROOT_DIR/script/DeskHUD.icns" "$APP_DIR/Contents/Resources/DeskHUD.icns"
  ICON_KEY="<key>CFBundleIconFile</key><string>DeskHUD</string>"
else
  ICON_KEY=""
fi

# Info.plist
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
  <key>CFBundleDisplayName</key>
  <string>DeskHUD</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSCalendarsUsageDescription</key>
  <string>DeskHUD shows your today's events and reminders in the left HUD panel.</string>
  $ICON_KEY
</dict>
</plist>
PLIST

# Sign
if security find-identity -v -p codesigning 2>/dev/null | grep -qF "$CERT_NAME"; then
  /usr/bin/codesign --force --deep --sign "$CERT_NAME" "$APP_DIR"
  echo "Signed with: $CERT_NAME"
else
  /usr/bin/codesign --force --deep --sign - "$APP_DIR"
  echo "Ad-hoc signed"
fi

# Create DMG
DMG_PATH="$RELEASE_DIR/DeskHUD-v$VERSION.dmg"
hdiutil create -fs HFS+ -srcfolder "$RELEASE_DIR/$APP_NAME.app" -volname "DeskHUD v$VERSION" "$DMG_PATH" >/dev/null
echo ""
echo "=== Release built ==="
echo "DMG: $DMG_PATH"
echo "App: $APP_DIR"
ls -lh "$DMG_PATH"
