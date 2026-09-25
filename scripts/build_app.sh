#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "[1/4] 正在编译 Release 二进制..."
swift build -c release

APP_NAME="TaskCleaner.app"
BUILD_DIR="$DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "[2/4] 正在生成 $APP_NAME 目录结构..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "[3/4] 拷贝可执行文件、图标并写入 Info.plist..."
cp "$DIR/.build/release/TaskCleanerGUI" "$MACOS_DIR/TaskCleanerGUI"
chmod +x "$MACOS_DIR/TaskCleanerGUI"

if [ ! -f "$DIR/Resources/AppIcon.icns" ] || [ "$DIR/scripts/generate_app_icon.swift" -nt "$DIR/Resources/AppIcon.icns" ]; then
    echo "       正在生成 AppIcon.icns..."
    swift "$DIR/scripts/generate_app_icon.swift"
    iconutil -c icns /tmp/AppIcon.iconset -o "$DIR/Resources/AppIcon.icns"
fi

cp "$DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TaskCleanerGUI</string>
    <key>CFBundleIdentifier</key>
    <string>com.donjone.taskcleaner-gui</string>
    <key>CFBundleName</key>
    <string>Task Cleaner</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string>
        <string>zh-Hans</string>
        <string>zh-Hant</string>
        <string>ja</string>
        <string>ko</string>
        <string>fr</string>
        <string>de</string>
        <string>es</string>
        <string>pt</string>
        <string>it</string>
        <string>ru</string>
        <string>nl</string>
        <string>pl</string>
        <string>tr</string>
        <string>ar</string>
        <string>th</string>
        <string>vi</string>
        <string>id</string>
        <string>sv</string>
        <string>da</string>
        <string>nb</string>
        <string>fi</string>
        <string>cs</string>
        <string>uk</string>
    </array>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "       生成 24 种语言本地化资源包 (.lproj)..."
LANGS=("en" "zh-Hans" "zh-Hant" "ja" "ko" "fr" "de" "es" "pt" "it" "ru" "nl" "pl" "tr" "ar" "th" "vi" "id" "sv" "da" "nb" "fi" "cs" "uk")
for lang in "${LANGS[@]}"; do
    mkdir -p "$RESOURCES_DIR/$lang.lproj"
    cat << EOF > "$RESOURCES_DIR/$lang.lproj/InfoPlist.strings"
"CFBundleDisplayName" = "Task Cleaner";
"CFBundleName" = "Task Cleaner";
EOF
done

echo "[4/4] 打包完成: $APP_DIR"
echo "[提示] 可将应用移动到 Applications 目录:"
echo "       cp -R \"$APP_DIR\" /Applications/"
echo "       或"
echo "       open \"$APP_DIR\""
