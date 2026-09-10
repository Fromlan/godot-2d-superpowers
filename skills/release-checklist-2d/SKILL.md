---
name: release-checklist-2d
description: Use when user is about to release/build a 2D Godot game, or says 'export' / 'package' / 'release version' / 'release'. Platform-specific checklist (Windows/Mac/Linux/Web/Android), version bumping, changelog, build artifacts, and post-release smoke testing.
last_reviewed: 2026-09-10
---

<!-- argument-hint: [windows | mac | linux | web | android | full] -->

# Release Checklist 2D (Godot)

> 2D Godot game pre-release full-process checklist.
> Output: distributable build artifacts + version number + changelog.

## 0. Routing (single question)

| Option | Path |
|last_reviewed: 2026-09-10
------|------|
| A. Windows only | 1-6 |
| B. Mac | 1-6 + Mac signing (7) |
| C. Linux | 1-6 |
| D. Web (itch.io) | 1-6 + Web export (8) |
| E. Android | 1-6 + Android APK (9) |
| F. All platforms | 1-9 |

## 0.5. Godot API claims audit (must do, before bumping)

Run the docs-alignment check first; any FAIL blocks the release:

```powershell
.\scripts\verify-godot-claims.ps1 -Strict
```

Output goes to `build/audit/godot-claims-<date>.md`. If FAILs appear, fix the SKILL.md (this skills pack) **first**, then re-run.

**Add new fact**: extend the `$facts` array in `scripts/verify-godot-claims.ps1`. Each entry needs an id, the asserting skill file, the claim, the doc URL, and a regex that proves the claim.

## 1. Version Number (must do)

> **Skill freshness**: any Godot knowledge skill (`godot-*`) whose `last_reviewed` in frontmatter is more than 90 days old must be re-reviewed before this release. Use `grep -l "last_reviewed" skills/godot-*/SKILL.md` to enumerate.

Use SemVer vX.Y.Z:

- X = major (gameplay / engine overhaul)
- Y = minor (new mechanic / new level)
- Z = patch (bug fix / balance)

Modify:
- project.godot: config/version = "X.Y.Z"
- README.md: version badge

## 2. Changelog (must do, user-visible)

Write to CHANGELOG.md:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- new feature 1
- new feature 2

### Changed
- behavior change 1

### Fixed
- bug fix 1

### Removed
- removed feature (if any)
```

## 3. Export Presets (must do)

Add export_presets.cfg to project.godot or save from editor:

### 3.1 Windows Desktop

- Name: Windows Desktop
- Platform: Windows
- Format: Game.exe (with PCK)
- Include PDB: false (release)
- Encryption: off (affects load)

### 3.2 Web

- Name: Web
- Format: index.html + index.pck + index.wasm
- Disable physics multithread: physics/2d/run_on_thread = false (Web compatible)
- Optimization: html/canvas_resize_policy = 1

### 3.3 Android

- Package: com.yourstudio.yourgame
- Min SDK: 24 (Android 7.0)
- Target SDK: 34
- Signing: debug keystore (test) / release keystore (publish)

## 4. Build (must do)

Run scripts/export-build.ps1 <platform>, generates:

```
build/
  windows/yourgame-v1.0.0.exe
  windows/yourgame-v1.0.0.pck
  web/index.html
  web/index.pck
  web/index.wasm
```

## 5. Post-Build Smoke (must do)

### Windows

```powershell
# Run 60s, pass if no error
& "build/windows/yourgame.exe" --quit-after 60

# Check no fatal error
Get-Content build/windows/console.log
```

### Web

```powershell
# Start local HTTP server
cd build/web && python -m http.server 8080

# Open http://localhost:8080 in browser, manual verify
```

### Android

- adb install build/android/yourgame.apk
- Run on real device + play 5 min
- Verify input, audio, performance

## 6. Assets + License (must do)

- [ ] All assets have ATTRIBUTION (assets/ATTRIBUTION.md)
- [ ] Third-party library license texts included (THIRD_PARTY_LICENSES.md)
- [ ] Font / music / art license covers distribution

## 7. Mac Signing (Mac only)

- [ ] Apple Developer certificate
- [ ] codesign --deep --force --options=runtime --sign "Developer ID Application: ..." yourgame.app
- [ ] xcrun notarytool submit yourgame.zip --keychain-profile <profile>
- [ ] Notarization complete (staple ticket)

## 8. Web Specific (Web only)

- [ ] physics/2d/run_on_thread = false
- [ ] Audio uses AudioStreamPlayer (not 3D positioned AudioStreamPlayer2D)
- [ ] Input supports touch (InputEventScreenTouch) if needed
- [ ] Upload to itch.io: zip entire web/ directory

## 9. Android Specific (Android only)

- [ ] editor/export/android keystore set
- [ ] use_apk_expansion = false (unless OBB needed)
- [ ] Permissions minimal (INTERNET only if network needed)
- [ ] Multi-resolution support: stretch/mode = "canvas_items", stretch/aspect = "expand"
- [ ] Background pause: Main Loop Type = Standard

## 10. Performance Baseline Compare (recommended)

Run once before release, record:

```
- Startup time: <X>s
- Main scene FPS: <X>
- Memory peak: <X>MB
- Package size: <X>MB
```

Compare with last version, pass if no regression.

## 11. Git Tag (must do)

```powershell
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## 12. Distribution

| Platform | Channel |
|------|------|
| Windows | itch.io / Steam / self-host |
| Mac | Steam / Mac App Store |
| Linux | Steam / itch.io / self-host |
| Web | itch.io (HTML5) |
| Android | Google Play |

## 13. Anti-Patterns (forbidden pre-release)

- Includes debug print()
- Includes dev-branch TODO
- Includes uncompressed dev assets (large files)
- Includes test scenes (tests/)
- Includes .godot/ cache
- Version not bumped
- Changelog missing
- No smoke run before release

## 14. Follow-up

- After release: monitor feedback, prepare hotfix (Z version)
- Steam integration: separate skill/wiki (out of scope)

## Appendix — Common Commands

```powershell
# Export
godot --headless --export-release "Windows Desktop" build/windows/yourgame.exe

# Run build
& "build/windows/yourgame.exe"

# View console.log
# Windows: create console.log in game dir, game writes to it

# Upload to itch.io (using butler CLI)
butler push build/windows yourname/yourgame:windows --userversion 1.0.0
```
