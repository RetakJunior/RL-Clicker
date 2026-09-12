#!/bin/bash
set -e

echo "=== Building RL Clicker AppImage ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "[1/4] Building Flutter Linux Release..."
flutter build linux --release

APP_DIR="$ROOT_DIR/build/AppDir"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/lib"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps"

echo "[2/4] Copying bundle..."
cp -r build/linux/x64/release/bundle/* "$APP_DIR/usr/bin/"
cp linux/rl-clicker.desktop "$APP_DIR/usr/share/applications/"
cp linux/rl-clicker.desktop "$APP_DIR/rl-clicker.desktop"

# Create simple AppRun if not present
cat << 'EOF' > "$APP_DIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/bin/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/rl_clicker" "$@"
EOF
chmod +x "$APP_DIR/AppRun"

echo "[3/4] Checking appimagetool..."
if ! command -v appimagetool &> /dev/null; then
    echo "Notice: appimagetool not found on PATH. AppDir structure is prepared at: $APP_DIR"
    echo "To build AppImage directly, download appimagetool from https://github.com/AppImage/AppImageKit/releases and run:"
    echo "ARCH=x86_64 appimagetool $APP_DIR RL_Clicker-x86_64.AppImage"
else
    ARCH=x86_64 appimagetool "$APP_DIR" "$ROOT_DIR/build/RL_Clicker-x86_64.AppImage"
    echo "AppImage created at: $ROOT_DIR/build/RL_Clicker-x86_64.AppImage"
fi

echo "Done!"

