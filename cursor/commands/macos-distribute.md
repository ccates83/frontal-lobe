# macOS Distribute

Full distribution workflow: archive, sign, notarize, and package.

## Arguments

- `$ARGUMENTS` — Distribution format: `dmg` (default), `pkg`, or `app-store`.

## Instructions

You are an orchestrator. Do NOT run commands yourself. Delegate to the `xcode-builder` agent.

## Phase 1: Gather Context

1. Read project guidance (CLAUDE.md or project guidance (CLAUDE.md or AGENTS.md)) for project-specific distribution commands, signing identity, and team ID
2. Detect the project type and primary scheme
3. Check for existing `ExportOptions.plist` in the project
4. Verify signing identity: `security find-identity -v -p codesigning 2>&1 | head -10`

## Phase 2: Archive

Delegate to `xcode-builder`:
```bash
xcodebuild -project <name>.xcodeproj -scheme <scheme> \
  -destination 'generic/platform=macOS' \
  -archivePath build/<name>.xcarchive \
  archive 2>&1
```

## Phase 3: Export

Delegate to `xcode-builder`:
- For `dmg` or `pkg`: export with Developer ID method
- For `app-store`: export with app-store method

```bash
xcodebuild -exportArchive \
  -archivePath build/<name>.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist 2>&1
```

## Phase 4: Package (dmg or pkg)

For DMG:
```bash
hdiutil create -volname "<AppName>" \
  -srcfolder build/export/<name>.app \
  -ov -format UDZO build/<name>.dmg 2>&1
```

For pkg:
```bash
productbuild --component build/export/<name>.app /Applications \
  build/<name>.pkg 2>&1
```

## Phase 5: Notarize (Developer ID only)

```bash
xcrun notarytool submit build/<name>.dmg \
  --keychain-profile "notarization-profile" --wait 2>&1
```

Then staple:
```bash
xcrun stapler staple build/<name>.dmg
```

## Phase 6: Verify

```bash
spctl --assess --type open --context context:primary-signature build/<name>.dmg
codesign --verify --deep --strict build/export/<name>.app
```

## Phase 7: Report

Present:
- **Archive**: pass/fail
- **Export**: pass/fail, signing identity used
- **Package**: format and path
- **Notarization**: status (submitted, approved, rejected)
- **Verification**: codesign and spctl results
- **Output path**: where the distributable artifact is
