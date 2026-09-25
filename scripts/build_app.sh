#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

TARGET="${1:-native}"

echo "=============================================="
echo " Task Cleaner 应用程序打包构建脚本"
echo " 目标架构模式: $TARGET"
echo "=============================================="

# 确保图标文件存在
ensure_app_icon() {
    if [ ! -f "$DIR/Resources/AppIcon.icns" ] || [ "$DIR/scripts/generate_app_icon.swift" -nt "$DIR/Resources/AppIcon.icns" ]; then
        echo "[图标] 正在生成 AppIcon.icns..."
        swift "$DIR/scripts/generate_app_icon.swift"
        iconutil -c icns /tmp/AppIcon.iconset -o "$DIR/Resources/AppIcon.icns"
    fi
}

# 查找对应架构的 mtc 引擎
find_mtc_binary() {
    local target_arch="$1"
    local cli_dir="$DIR/../macos-task-cleaner-cli"
    local candidate=""

    case "$target_arch" in
        arm64)
            if [ -f "$cli_dir/dist/arm64/mtc" ]; then
                candidate="$cli_dir/dist/arm64/mtc"
            elif [ -f "$cli_dir/target/aarch64-apple-darwin/release/mtc" ]; then
                candidate="$cli_dir/target/aarch64-apple-darwin/release/mtc"
            fi
            ;;
        x86_64)
            if [ -f "$cli_dir/dist/x86_64/mtc" ]; then
                candidate="$cli_dir/dist/x86_64/mtc"
            elif [ -f "$cli_dir/target/x86_64-apple-darwin/release/mtc" ]; then
                candidate="$cli_dir/target/x86_64-apple-darwin/release/mtc"
            fi
            ;;
        universal)
            if [ -f "$cli_dir/dist/universal/mtc" ]; then
                candidate="$cli_dir/dist/universal/mtc"
            elif [ -f "$cli_dir/target/aarch64-apple-darwin/release/mtc" ] && [ -f "$cli_dir/target/x86_64-apple-darwin/release/mtc" ]; then
                mkdir -p "$DIR/.build/universal"
                lipo -create "$cli_dir/target/aarch64-apple-darwin/release/mtc" "$cli_dir/target/x86_64-apple-darwin/release/mtc" -output "$DIR/.build/universal/mtc"
                candidate="$DIR/.build/universal/mtc"
            fi
            ;;
    esac

    # 回退检查：默认 target/release/mtc 或已安装的 mtc
    if [ -z "$candidate" ] || [ ! -f "$candidate" ]; then
        if [ -f "$cli_dir/target/release/mtc" ]; then
            candidate="$cli_dir/target/release/mtc"
        elif command -v mtc >/dev/null 2>&1; then
            candidate="$(command -v mtc)"
        fi
    fi

    echo "$candidate"
}

# 组装 TaskCleaner.app
assemble_bundle() {
    local target_arch="$1"
    local swift_bin="$2"
    local dest_dir="$3"

    echo "[组装] 正在组装 $target_arch 版本 -> $dest_dir"
    rm -rf "$dest_dir"
    local macos_dir="$dest_dir/Contents/MacOS"
    local resources_dir="$dest_dir/Contents/Resources"
    mkdir -p "$macos_dir" "$resources_dir"

    cp "$swift_bin" "$macos_dir/TaskCleanerGUI"
    chmod +x "$macos_dir/TaskCleanerGUI"

    local mtc_bin
    mtc_bin="$(find_mtc_binary "$target_arch")"
    if [ -n "$mtc_bin" ] && [ -f "$mtc_bin" ]; then
        echo "       嵌入内置 mtc 引擎: $mtc_bin"
        cp "$mtc_bin" "$macos_dir/mtc"
        chmod +x "$macos_dir/mtc"
    else
        echo "       [说明] 未检测到内置 mtc 引擎，应用将在运行时查找系统 PATH"
    fi

    cp "$DIR/Resources/AppIcon.icns" "$resources_dir/AppIcon.icns"

    cat << 'EOF' > "$dest_dir/Contents/Info.plist"
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

    local langs=("en" "zh-Hans" "zh-Hant" "ja" "ko" "fr" "de" "es" "pt" "it" "ru" "nl" "pl" "tr" "ar" "th" "vi" "id" "sv" "da" "nb" "fi" "cs" "uk")
    for lang in "${langs[@]}"; do
        mkdir -p "$resources_dir/$lang.lproj"
        cat << EOF > "$resources_dir/$lang.lproj/InfoPlist.strings"
"CFBundleDisplayName" = "Task Cleaner";
"CFBundleName" = "Task Cleaner";
EOF
    done
}

# 压缩归档并计算 SHA256
package_zip() {
    local target_arch="$1"
    local source_app_dir="$2"
    local zip_file="$DIR/build/TaskCleaner-macOS-${target_arch}.zip"

    echo "[归档] 正在打包 $(basename "$zip_file")..."
    (
        cd "$(dirname "$source_app_dir")"
        rm -f "$zip_file" "${zip_file}.sha256"
        zip -r -y -q "$zip_file" "$(basename "$source_app_dir")"
        cd "$DIR/build"
        shasum -a 256 "TaskCleaner-macOS-${target_arch}.zip" > "TaskCleaner-macOS-${target_arch}.zip.sha256"
        echo "       SHA256: $(cat "TaskCleaner-macOS-${target_arch}.zip.sha256")"
    )
}

ensure_app_icon
mkdir -p "$DIR/build"

build_arm64() {
    echo "[编译] 正在准备 Apple Silicon (arm64) Release 二进制..."
    swift build -c release --triple arm64-apple-macosx13.0 --scratch-path "$DIR/.build/arm64"
    mkdir -p "$DIR/build/arm64"
    assemble_bundle "arm64" "$DIR/.build/arm64/out/Products/Release/TaskCleanerGUI" "$DIR/build/arm64/TaskCleaner.app"
    package_zip "arm64" "$DIR/build/arm64/TaskCleaner.app"
}

build_x86_64() {
    echo "[编译] 正在准备 AMD64 / Intel (x86_64) Release 二进制..."
    swift build -c release --triple x86_64-apple-macosx13.0 --scratch-path "$DIR/.build/x86_64"
    mkdir -p "$DIR/build/x86_64"
    assemble_bundle "x86_64" "$DIR/.build/x86_64/out/Products/Release/TaskCleanerGUI" "$DIR/build/x86_64/TaskCleaner.app"
    package_zip "x86_64" "$DIR/build/x86_64/TaskCleaner.app"
}

build_universal() {
    echo "[编译] 准备构建 Universal 通用架构版本..."
    if [ ! -f "$DIR/.build/arm64/out/Products/Release/TaskCleanerGUI" ]; then
        build_arm64
    fi
    if [ ! -f "$DIR/.build/x86_64/out/Products/Release/TaskCleanerGUI" ]; then
        build_x86_64
    fi

    mkdir -p "$DIR/.build/universal"
    lipo -create \
        "$DIR/.build/arm64/out/Products/Release/TaskCleanerGUI" \
        "$DIR/.build/x86_64/out/Products/Release/TaskCleanerGUI" \
        -output "$DIR/.build/universal/TaskCleanerGUI"
    chmod +x "$DIR/.build/universal/TaskCleanerGUI"

    mkdir -p "$DIR/build/universal"
    assemble_bundle "universal" "$DIR/.build/universal/TaskCleanerGUI" "$DIR/build/universal/TaskCleaner.app"
    package_zip "universal" "$DIR/build/universal/TaskCleaner.app"

    # 同步兼容旧名称 TaskCleaner-macOS.zip
    cp "$DIR/build/TaskCleaner-macOS-universal.zip" "$DIR/build/TaskCleaner-macOS.zip"
    shasum -a 256 "$DIR/build/TaskCleaner-macOS.zip" > "$DIR/build/TaskCleaner-macOS.zip.sha256"
}

build_native() {
    echo "[编译] 开始编译本机原生架构 Release 二进制..."
    swift build -c release
    assemble_bundle "native" "$DIR/.build/release/TaskCleanerGUI" "$DIR/build/TaskCleaner.app"
    echo "[完成] 原生应用组装完成: $DIR/build/TaskCleaner.app"
    echo "[提示] 可将应用移动到 Applications 目录:"
    echo "       cp -R \"$DIR/build/TaskCleaner.app\" /Applications/"
}

case "$TARGET" in
    arm64)
        build_arm64
        rm -rf "$DIR/build/TaskCleaner.app"
        cp -R "$DIR/build/arm64/TaskCleaner.app" "$DIR/build/TaskCleaner.app"
        ;;
    x86_64|amd64)
        build_x86_64
        rm -rf "$DIR/build/TaskCleaner.app"
        cp -R "$DIR/build/x86_64/TaskCleaner.app" "$DIR/build/TaskCleaner.app"
        ;;
    universal)
        build_universal
        rm -rf "$DIR/build/TaskCleaner.app"
        cp -R "$DIR/build/universal/TaskCleaner.app" "$DIR/build/TaskCleaner.app"
        ;;
    all)
        build_arm64
        build_x86_64
        build_universal
        rm -rf "$DIR/build/TaskCleaner.app"
        cp -R "$DIR/build/universal/TaskCleaner.app" "$DIR/build/TaskCleaner.app"
        ;;
    native)
        build_native
        ;;
    *)
        echo "[错误] 未知架构目标: $TARGET"
        echo "支持选项: arm64 | x86_64 | amd64 | universal | all | native"
        exit 1
        ;;
esac

echo "[全部就绪] 构建与打包流程已顺利完成。"
