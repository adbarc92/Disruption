# Disruption - Distribution Guide

## Quick Start: Building for Distribution

### Prerequisites
1. Open Godot 4.6 (or later)
2. Install export templates: **Editor → Manage Export Templates → Download and Install**

### Building Exports

**Option 1: Via Godot Editor (Recommended)**
1. Open the project in Godot
2. Go to **Project → Export**
3. Select a preset (Windows Desktop, macOS, Linux/X11, or iOS)
4. Click **Export Project**
5. Builds will be saved to `godot/builds/[platform]/`

**Option 2: Via Command Line**
```bash
# From the godot/ directory

# Windows
godot --headless --export-release "Windows Desktop"

# macOS
godot --headless --export-release "macOS"

# Linux
godot --headless --export-release "Linux/X11"

# iOS (requires Mac + Xcode)
godot --headless --export-release "iOS"
```

---

## Platform-Specific Notes

### Windows Desktop
- **Output**: `builds/windows/Disruption.exe` + `.pck` file
- **Distribution**: Zip both files together
- **Testing**: Runs on any Windows 10+ machine
- **No signing required** for playtesting

### macOS
- **Output**: `builds/mac/Disruption.zip`
- **Distribution**: Use the .zip file directly
- **Important**: For smooth testing, you should sign the app:
  ```bash
  # Ad-hoc signing (for local testing)
  codesign --force --deep --sign - "Disruption.app"
  ```
- **Note**: Testers may need to right-click → Open first time (macOS Gatekeeper)

### Linux/X11
- **Output**: `builds/linux/Disruption.x86_64` + `.pck` file
- **Distribution**: Zip both files, mark executable as executable
- **Testing**: Works on most modern Linux distros
- **Note**: Testers may need to `chmod +x Disruption.x86_64`

### iOS (iPad)
- **Output**: `builds/ios/Disruption.ipa`
- **Requirements**:
  - Mac with Xcode installed
  - Apple Developer account ($99/year)
  - Provisioning profile configured
- **Distribution**: Upload to TestFlight
- **Setup Required**:
  1. Update `application/bundle_identifier` in export preset (must be unique)
  2. Configure provisioning profiles in Xcode
  3. Set your Team ID in the export preset

---

## Distribution Options

### Option A: itch.io (Easiest)
1. Create project at [itch.io/game/new](https://itch.io/game/new)
2. Set visibility to "Restricted" or "Draft"
3. Upload builds with clear naming:
   - `Disruption_v0.1_Windows.zip`
   - `Disruption_v0.1_Mac.zip`
   - `Disruption_v0.1_Linux.zip`
4. Share link + password with testers

### Option B: Google Drive / Dropbox
1. Zip each platform's build
2. Upload to shared folder
3. Share link with testers

### Option C: GitHub Releases (Private Repo)
1. Tag a release in your repo
2. Upload builds as release assets
3. Grant testers repo access

---

## Preparing Builds for Testers

### Windows
```bash
cd builds/windows
zip Disruption_v0.1_Windows.zip Disruption.exe Disruption.pck
```

### macOS
- The export already creates a .zip, just rename:
```bash
cd builds/mac
mv Disruption.zip Disruption_v0.1_Mac.zip
```

### Linux
```bash
cd builds/linux
zip Disruption_v0.1_Linux.zip Disruption.x86_64 Disruption.pck
```

---

## Include These Files in Distribution

Create a `README_FOR_TESTERS.txt` with:
```
DISRUPTION - Playtest Build v0.1.0

INSTALLATION:
1. Extract the .zip file
2. Run Disruption.exe (Windows) or Disruption.app (Mac) or Disruption.x86_64 (Linux)

CONTROLS:
WASD / Arrow Keys - Move
Space - Jump
Shift - Sprint
Left Ctrl - Roll
Q - Grapple
E - Interact
ESC - Pause

KNOWN ISSUES:
[List any known bugs here]

FEEDBACK:
Please report bugs and feedback to: [your email/form link]

VERSION: 0.1.0
BUILD DATE: [date]
```

---

## Troubleshooting

### "Missing export templates" error
- Go to **Editor → Manage Export Templates**
- Click **Download and Install**

### macOS build won't open (unsigned)
- Right-click → Open (instead of double-click)
- Or sign with: `codesign --force --deep --sign - "Disruption.app"`

### Linux: "Permission denied"
- Run: `chmod +x Disruption.x86_64`

### iOS: Code signing errors
- Ensure your Apple Developer account is active
- Configure provisioning profiles in Xcode
- Update bundle identifier to match your profile

---

## Current Build Configuration

- **Version**: 0.1.0
- **Window Size**: 1920x1080 (fullscreen)
- **Platforms**: Windows 64-bit, macOS Universal, Linux x86_64, iOS (iPad)
- **Godot Version**: 4.6+
