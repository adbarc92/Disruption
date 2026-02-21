#!/bin/bash
# Build script for all platforms
# Usage: ./build_all.sh [version]
# Example: ./build_all.sh 0.1.0

VERSION=${1:-"0.1.0"}
BUILD_DATE=$(date +"%Y-%m-%d")

echo "======================================"
echo "Building Disruption v${VERSION}"
echo "Build Date: ${BUILD_DATE}"
echo "======================================"

# Path to Godot executable (modify if needed)
GODOT_BIN="godot"

# Check if Godot is available
if ! command -v $GODOT_BIN &> /dev/null; then
    echo "Error: Godot executable not found!"
    echo "Please ensure 'godot' is in your PATH or modify GODOT_BIN in this script"
    echo "Example: GODOT_BIN=\"/Applications/Godot.app/Contents/MacOS/Godot\""
    exit 1
fi

echo ""
echo "Building Windows..."
$GODOT_BIN --headless --export-release "Windows Desktop" 2>&1 | grep -v "^Godot Engine"

echo ""
echo "Building macOS..."
$GODOT_BIN --headless --export-release "macOS" 2>&1 | grep -v "^Godot Engine"

echo ""
echo "Building Linux..."
$GODOT_BIN --headless --export-release "Linux/X11" 2>&1 | grep -v "^Godot Engine"

echo ""
echo "======================================"
echo "Creating distribution packages..."
echo "======================================"

# Create distribution directory
DIST_DIR="builds/dist"
mkdir -p "$DIST_DIR"

# Package Windows
echo "Packaging Windows build..."
cd builds/windows
zip -q "../../${DIST_DIR}/Disruption_v${VERSION}_Windows.zip" Disruption.exe Disruption.pck
cp ../../README_FOR_TESTERS.txt .
cd ../..

# Package macOS (already zipped by Godot)
echo "Packaging macOS build..."
cp builds/mac/Disruption.zip "${DIST_DIR}/Disruption_v${VERSION}_Mac.zip"

# Package Linux
echo "Packaging Linux build..."
cd builds/linux
zip -q "../../${DIST_DIR}/Disruption_v${VERSION}_Linux.zip" Disruption.x86_64 Disruption.pck
cp ../../README_FOR_TESTERS.txt .
cd ../..

echo ""
echo "======================================"
echo "Build complete!"
echo "======================================"
echo ""
echo "Distribution packages created in: builds/dist/"
echo ""
ls -lh "${DIST_DIR}/"
echo ""
echo "Next steps:"
echo "1. Test each build on their respective platforms"
echo "2. Update README_FOR_TESTERS.txt with current build date"
echo "3. Upload to itch.io or your distribution platform"
echo "4. Share links with playtesters"
echo ""
echo "For iOS builds, use Xcode or 'godot --export-release iOS'"
echo "and distribute via TestFlight"
