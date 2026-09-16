#!/usr/bin/env bash
set -e

# Change directory to the script's folder
cd "$(dirname "$0")"

APP_NAME="Repo Manager"
SOURCE_APP="${APP_NAME}.app"
SOURCE_ZIP="${APP_NAME}.app.zip"
DEST_PATH="/Applications/${APP_NAME}.app"

echo "=================================================="
echo "   Installing ${APP_NAME} (Ad-Hoc Uncertified)    "
echo "=================================================="

# The release build is distributed zipped (a release asset can't be a
# bare directory) — unzip it here if that's what's sitting next to this
# script rather than an already-extracted app.
if [ ! -d "$SOURCE_APP" ] && [ -f "$SOURCE_ZIP" ]; then
    echo "==> Unzipping ${SOURCE_ZIP}..."
    ditto -x -k "$SOURCE_ZIP" .
fi

# Check if source app exists
if [ ! -d "$SOURCE_APP" ]; then
    echo "Error: Could not find ${SOURCE_APP} (or ${SOURCE_ZIP}) in this directory."
    read -p "Press Enter to exit..."
    exit 1
fi

# 1. Ad-Hoc Sign (Uses '-' identity: no developer account needed)
echo "==> Deep ad-hoc code-signing bundle and embedded frameworks..."
codesign --force --deep --sign "-" "$SOURCE_APP"

# 2. Strip Gatekeeper Quarantine Attributes
echo "==> Stripping quarantine flags..."
xattr -cr "$SOURCE_APP"

# 3. Move to /Applications
echo "==> Moving app to /Applications..."
if [ -d "$DEST_PATH" ]; then
    rm -rf "$DEST_PATH"
fi
cp -R "$SOURCE_APP" "$DEST_PATH"

# 4. Strip quarantine again on destination just in case
xattr -cr "$DEST_PATH" 2>/dev/null || true

echo "=================================================="
echo "  Success! ${APP_NAME} installed to /Applications."
echo "=================================================="
read -p "Press Enter to close..."