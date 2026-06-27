#!/usr/bin/env bash
set -euo pipefail

APP_NAME="DeskHUD"
BUNDLE_ID="dev.hex.deskhud"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
EXECUTABLE="$ROOT_DIR/.build/debug/$APP_NAME"
BUNDLE_EXECUTABLE="$APP_DIR/Contents/MacOS/$APP_NAME"
ICONSET_DIR="$ROOT_DIR/script/DeskHUD.iconset"
ICNS_FILE="$ROOT_DIR/script/DeskHUD.icns"
CERT_NAME="DeskHUD Development"

cd "$ROOT_DIR"

VERIFY=false
if [[ "${1:-}" == "--verify" ]]; then
  VERIFY=true
fi

# ------------------------------------------------------------------
# 1. Rebuild the icon if it doesn't exist or iconset is newer
# ------------------------------------------------------------------
if [[ ! -f "$ICNS_FILE" ]] || [[ "$ICONSET_DIR" -nt "$ICNS_FILE" ]]; then
  if [[ -d "$ICONSET_DIR" ]]; then
    echo "Regenerating app icon..."
    iconutil -c icns -o "$ICNS_FILE" "$ICONSET_DIR" 2>/dev/null || true
  fi
fi

# ------------------------------------------------------------------
# 2. Build (hash comparison to detect real binary changes)
# ------------------------------------------------------------------
OLD_HASH=""
if [[ -f "$EXECUTABLE" ]]; then
  OLD_HASH="$(shasum -a 256 "$EXECUTABLE" | awk '{print $1}')"
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
swift build --product "$APP_NAME"

NEW_HASH="$(shasum -a 256 "$EXECUTABLE" | awk '{print $1}')"

# ------------------------------------------------------------------
# 3. Pick a signing identity
# ------------------------------------------------------------------
SIGN_IDENTITY="-"
if security find-identity -v -p codesigning 2>/dev/null | grep -qF "$CERT_NAME"; then
  SIGN_IDENTITY="$CERT_NAME"
  echo "Signing with: $CERT_NAME"
else
  echo "Signing with: ad-hoc (run script/setup_codesign.sh for a stable identity)"
fi

# ------------------------------------------------------------------
# 4. Assemble or update the app bundle
# ------------------------------------------------------------------
if [[ "$OLD_HASH" == "$NEW_HASH" && -d "$APP_DIR" ]]; then
  # Binary unchanged — keep existing bundle signature (preserves TCC grants).
  echo "Binary unchanged — launching existing bundle (TCC grants preserved)"
  mkdir -p "$APP_DIR/Contents/Resources/Examples"
  cp "$ROOT_DIR/Examples/config.json" "$APP_DIR/Contents/Resources/Examples/config.json"
  cp "$ROOT_DIR/Examples/hud.json" "$APP_DIR/Contents/Resources/Examples/hud.json"
  cp "$ROOT_DIR/Examples/hud_leftDock.json" "$APP_DIR/Contents/Resources/Examples/hud_leftDock.json" 2>/dev/null || true
  cp "$ROOT_DIR/Examples/hud_rightDock.json" "$APP_DIR/Contents/Resources/Examples/hud_rightDock.json" 2>/dev/null || true
else
  # Binary changed (or first build) — full bundle setup.
  echo "Binary changed — full bundle setup"
  rm -rf "$APP_DIR"
  mkdir -p "$APP_DIR/Contents/MacOS" \
           "$APP_DIR/Contents/Resources/Examples"

  cp "$EXECUTABLE" "$BUNDLE_EXECUTABLE"
  cp "$ROOT_DIR/Examples/config.json" "$APP_DIR/Contents/Resources/Examples/config.json"
  cp "$ROOT_DIR/Examples/hud.json" "$APP_DIR/Contents/Resources/Examples/hud.json"
  cp "$ROOT_DIR/Examples/hud_leftDock.json" "$APP_DIR/Contents/Resources/Examples/hud_leftDock.json" 2>/dev/null || true
  cp "$ROOT_DIR/Examples/hud_rightDock.json" "$APP_DIR/Contents/Resources/Examples/hud_rightDock.json" 2>/dev/null || true

  if [[ -f "$ICNS_FILE" ]]; then
    cp "$ICNS_FILE" "$APP_DIR/Contents/Resources/DeskHUD.icns"
    ICON_KEY="<key>CFBundleIconFile</key><string>DeskHUD</string>"
  else
    ICON_KEY=""
  fi

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
  <key>NSCalendarsUsageDescription</key>
  <string>DeskHUD shows your today's events and reminders in the left HUD panel.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  $ICON_KEY
</dict>
</plist>
PLIST

  /usr/bin/codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR" >/dev/null
  echo "Rebuild complete — AX permission may need to be re-granted"
fi

# ------------------------------------------------------------------
# 5. Launch
# ------------------------------------------------------------------
/usr/bin/open -n "$APP_DIR"

if [[ "$VERIFY" == true ]]; then
  sleep 1
  pgrep -x "$APP_NAME" >/dev/null
  echo "$APP_NAME is running"
fi
