# DeskHUD Launchpad Visibility Bug

## Symptom

DeskHUD.app installed to `/Applications` does NOT appear in Launchpad, even though:

- The app is at `/Applications/DeskHUD.app`
- Spotlight can find and launch it
- `open /Applications/DeskHUD.app` works
- The app runs correctly once launched

## What was tried

1. `lsregister -f /Applications/DeskHUD.app` → no effect
2. `killall Dock` → no effect
3. Reinstalling the DMG → no effect

## App details

- Self-signed with "DeskHUD Development" certificate (not a paid Apple Developer ID)
- `CFBundleIdentifier`: `dev.hex.deskhud`
- `CFBundlePackageType`: `APPL`
- `CFBundleExecutable`: `DeskHUD`
- `LSMinimumSystemVersion`: `14.0`
- `NSPrincipalClass`: `NSApplication`
- Has `CFBundleIconFile` pointing to `DeskHUD.icns`
- Not sandboxed
- Ad-hoc signed initially, now signed with a self-signed certificate

## Likely cause

Launchpad requires apps to be properly registered in the Launch Services database. Self-signed apps that lack a valid Apple code signature may not be indexed by Launchpad automatically.

On recent macOS versions (26+), Launchpad may require one or more of:

- A valid Developer ID certificate signature
- An `LSApplicationCategoryType` key in Info.plist
- The app to be launched at least once before appearing
- Proper quarantine flag handling (`com.apple.quarantine` extended attribute removed)

## Info.plist (from release build)

```xml
<key>CFBundleExecutable</key><string>DeskHUD</string>
<key>CFBundleIdentifier</key><string>dev.hex.deskhud</string>
<key>CFBundleName</key><string>DeskHUD</string>
<key>CFBundleDisplayName</key><string>DeskHUD</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>0.1.5</string>
<key>CFBundleShortVersionString</key><string>0.1.5</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>CFBundleIconFile</key><string>DeskHUD</string>
<key>NSCalendarsUsageDescription</key><string>DeskHUD shows your today's events and reminders.</string>
```

## App bundle structure

```
DeskHUD.app/
  Contents/
    Info.plist
    MacOS/
      DeskHUD          (arm64 binary, release build)
    Resources/
      DeskHUD.icns      (multi-res icon)
      Examples/
        config.json
        hud.json
        hud_leftDock.json
        hud_rightDock.json
    _CodeSignature/
      CodeResources
```

## Signing

```bash
codesign -dvvv /Applications/DeskHUD.app
# Authority=DeskHUD Development
# Identifier=dev.hex.deskhud
# Format=app bundle with Mach-O thin (arm64)
# TeamIdentifier=not set
```

## Desired outcome

When a user installs DeskHUD to `/Applications`, it should appear in Launchpad within a reasonable time without manual intervention.

Potential fixes to try (in order of likelihood):

1. Add `LSApplicationCategoryType` to Info.plist (e.g. `public.app-category.productivity`)
2. Remove quarantine flag: `xattr -dr com.apple.quarantine /Applications/DeskHUD.app`
3. Re-launch the app at least once after install so macOS "sees" it
4. Rebuild with a non-self-signed certificate (requires Apple Developer account)
5. Use `mdimport` to force Spotlight re-indexing of the app
