#!/bin/bash
# Installs the built Wakey.app into ~/Applications (no admin rights needed).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT/build/Wakey.app"
DEST="$HOME/Applications"

if [ ! -d "$APP_DIR" ]; then
    echo "Wakey.app not found — run ./build.sh first." >&2
    exit 1
fi

mkdir -p "$DEST"

if [ -d "$DEST/Wakey.app" ]; then
    echo "==> Removing previous install"
    rm -rf "$DEST/Wakey.app"
fi

echo "==> Copying Wakey.app to $DEST"
cp -R "$APP_DIR" "$DEST/"

echo "==> Done. Launch it with:"
echo "    open \"$DEST/Wakey.app\""
echo "Or find it in Finder under your personal Applications folder."
