#!/usr/bin/env bash
set -euo pipefail

APP_NAME="DeskHUD"
BUNDLE_ID="dev.hex.deskhud"
VERSION="${1:-0.1.0}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release"
STAGING="$RELEASE_DIR/dmg_staging"
APP_DIR="$STAGING/$APP_NAME.app"
CERT_NAME="DeskHUD Development"

echo "=== Building DeskHUD v$VERSION (release) ==="

# Clean
rm -rf "$RELEASE_DIR"
mkdir -p "$STAGING"

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

# ── DMG with drag-to-install layout ──────────────────────────────────────

# Create Applications symlink for drag-to-install
ln -s /Applications "$STAGING/Applications"

DMG_PATH="$RELEASE_DIR/DeskHUD-v$VERSION.dmg"
DMG_TMP="$RELEASE_DIR/DeskHUD-tmp.dmg"
VOLNAME="DeskHUD v$VERSION"

# Create read-write DMG
hdiutil create -fs HFS+ -volname "$VOLNAME" -srcfolder "$STAGING" -size 10m "$DMG_TMP" >/dev/null

# Mount and set layout
DEV=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TMP" 2>&1 | grep /Volumes | awk '{print $1}')
MOUNT="/Volumes/$VOLNAME"

# Arrange icons (left=DeskHUD, right=Applications symlink)
osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$VOLNAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {200, 200, 580, 420}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 80
    set position of item "$APP_NAME.app" to {90, 100}
    set position of item "Applications" to {290, 100}
    update without registering applications
    close
  end tell
end tell
APPLESCRIPT

# Detach and convert to compressed read-only
hdiutil detach "$DEV" >/dev/null
hdiutil convert "$DMG_TMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" >/dev/null
rm -f "$DMG_TMP"

# Clean staging
rm -rf "$STAGING"

echo ""
echo "=== Release built ==="
echo "DMG: $DMG_PATH"
ls -lh "$DMG_PATH"
