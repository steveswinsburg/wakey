#!/bin/bash
# Builds Wakey.app: compiles the Swift sources, generates the icon, and
# assembles a standard macOS .app bundle. No Xcode project required.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/Wakey.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Cleaning previous build"
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "==> Compiling Wakey executable"
swiftc -O \
    "$ROOT/Sources/main.swift" \
    "$ROOT/Sources/IconFactory.swift" \
    -o "$MACOS_DIR/Wakey" \
    -framework Cocoa -framework IOKit -framework ServiceManagement

echo "==> Compiling icon generator"
swiftc -O \
    "$ROOT/IconGen/main.swift" \
    "$ROOT/Sources/IconFactory.swift" \
    -o "$BUILD_DIR/icongen" \
    -framework Cocoa

echo "==> Generating icon artwork"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
"$BUILD_DIR/icongen" "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"

echo "==> Writing Info.plist"
cp "$ROOT/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP_DIR"

echo "==> Build complete: $APP_DIR"
