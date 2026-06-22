#!/bin/bash
set -euo pipefail

VERSION="${1:-1.1.1}"
PUBLISH_DIR="bin/publish/Linux"
APP_DIR="bin/appimage/SS14.Launcher.AppDir"
APPDATA_DIR="$APP_DIR/usr/share/metainfo"
DESKTOP_FILE="$APP_DIR/SS14.Launcher.desktop"
APPRUN="$APP_DIR/AppRun"
ICON_DIR="$APP_DIR/usr/share/icons/hicolor/scalable/apps"

mkdir -p "$APP_DIR"
mkdir -p "$APPDATA_DIR"
mkdir -p "$ICON_DIR"

cp -r "$PUBLISH_DIR"/* "$APP_DIR/"

# Create AppRun
cat > "$APPRUN" << 'EOF'
#!/bin/bash
SELF_DIR="$(dirname "$(readlink -f "$0")")"
exec "$SELF_DIR/SS14.Launcher"
EOF
chmod +x "$APPRUN"

# Create desktop file
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Space Station 14 Launcher
Comment=Launcher for Space Station 14
Exec=SS14.Launcher
Icon=ss14-launcher
Terminal=false
Type=Application
Categories=Game;
EOF

# Create metainfo
cat > "$APPDATA_DIR/ss14-launcher.appdata.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>ss14-launcher</id>
  <name>Space Station 14 Launcher</name>
  <summary>Launcher for Space Station 14</summary>
  <metadata_license>MIT</metadata_license>
  <project_license>MIT</project_license>
</component>
EOF

# Download appimagetool
APPIMAGETOOL="bin/appimage/appimagetool"
if [ ! -f "$APPIMAGETOOL" ]; then
    mkdir -p bin/appimage
    curl -sL "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -o "$APPIMAGETOOL"
    chmod +x "$APPIMAGETOOL"
fi

mkdir -p bin/installers
ARCH=x86_64 "$APPIMAGETOOL" "$APP_DIR" "bin/installers/SS14.Launcher_Linux_${VERSION}.AppImage"
echo "Created: bin/installers/SS14.Launcher_Linux_${VERSION}.AppImage"
