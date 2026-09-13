#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

APP_NAME="repo_manager.app"
BUILD_OUTPUT="build/macos/Build/Products/Release/${APP_NAME}"
DEST="/Applications/${APP_NAME}"

echo "Building macOS release..."
flutter build macos --release

if [ ! -d "$BUILD_OUTPUT" ]; then
  echo "Build output not found at $BUILD_OUTPUT" >&2
  exit 1
fi

if [ -d "$DEST" ]; then
  echo "Removing previous install at $DEST"
  rm -rf "$DEST"
fi

echo "Installing to $DEST"
cp -R "$BUILD_OUTPUT" "$DEST"

echo "Done. Launch with: open \"$DEST\""
