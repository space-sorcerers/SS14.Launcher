#!/bin/bash
set -euo pipefail

VERSION="${1:-1.1.1}"
PUBLISH_DIR="bin/publish/macOS"
APP_NAME="Space Station 14 Launcher.app"
DMG_NAME="SS14.Launcher_macOS_${VERSION}.dmg"
DMG_DIR="bin/installers"

mkdir -p "$DMG_DIR"

# Create temporary DMG
TEMP_DMG=$(mktemp).dmg
DMG_SIZE_MB=500

hdiutil create -size "${DMG_SIZE_MB}m" -fs HFS+ -volname "SS14 Launcher" "$TEMP_DMG"

# Mount and copy app
MOUNT_POINT=$(hdiutil attach "$TEMP_DMG" -nobrowse -noautoopen | tail -1 | awk -F'\t' '{print $NF}')
cp -R "$PUBLISH_DIR/$APP_NAME" "$MOUNT_POINT/"
ln -s /Applications "$MOUNT_POINT/Applications"
hdiutil detach "$MOUNT_POINT" -quiet

# Convert to compressed DMG
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_DIR/$DMG_NAME"
rm -f "$TEMP_DMG"

echo "Created: $DMG_DIR/$DMG_NAME"
