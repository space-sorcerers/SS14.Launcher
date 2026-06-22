#!/bin/bash
set -euo pipefail

VERSION="${1:-1.1.1}"
PUBLISH_DIR="bin/publish/Linux"
APP_DIR="bin/appimage/SS14.Launcher.AppDir"
APPDATA_DIR="$APP_DIR/usr/share/metainfo"
DESKTOP_FILE="$APP_DIR/SS14.Launcher.desktop"
APPRUN="$APP_DIR/AppRun"
ICON_FILE="$APP_DIR/ss14-launcher.png"

mkdir -p "$APP_DIR"
mkdir -p "$APPDATA_DIR"

# Generate minimal 256x256 PNG icon using Python
python3 -c "
import struct, zlib
def create_png(width, height, color):
    def chunk(ctype, data):
        c = ctype + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    header = b'\\x89PNG\\r\\n\\x1a\\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
    raw = b''
    for y in range(height):
        raw += b'\\x00'
        for x in range(width):
            raw += bytes(color)
    idat = chunk(b'IDAT', zlib.compress(raw))
    iend = chunk(b'IEND', b'')
    return header + ihdr + idat + iend
with open('$ICON_FILE', 'wb') as f:
    f.write(create_png(256, 256, (50, 50, 80)))
"

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

# Download appimagetool (extract to avoid FUSE dependency on CI)
APPIMAGETOOL_DIR="bin/appimage/appimagetool-extracted"
if [ ! -d "$APPIMAGETOOL_DIR" ]; then
    mkdir -p bin/appimage
    curl -sL "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -o "bin/appimage/appimagetool.AppImage"
    chmod +x "bin/appimage/appimagetool.AppImage"
    cd bin/appimage
    ./appimagetool.AppImage --appimage-extract > /dev/null 2>&1
    mv squashfs-root appimagetool-extracted
    cd ../..
fi
APPIMAGETOOL="$APPIMAGETOOL_DIR/AppRun"

mkdir -p bin/installers
ARCH=x86_64 "$APPIMAGETOOL" "$APP_DIR" "bin/installers/SS14.Launcher_Linux_${VERSION}.AppImage"
echo "Created: bin/installers/SS14.Launcher_Linux_${VERSION}.AppImage"
