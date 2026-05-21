#!/bin/bash
# 艾伦耶格尔记忆曲线 - 自动刷新安装脚本
# 双击运行即可完成全部配置

set -e

APP_NAME="艾伦耶格尔记忆曲线"
PROJECT_NAME="艾伦耶格尔记忆曲线工具"
INSTALL_DIR="$HOME/Library/Application Support/$APP_NAME"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "   $APP_NAME - 自动刷新安装"
echo "========================================"
echo ""

# Check Xcode
if ! xcode-select -p &>/dev/null; then
    echo "❌ 未检测到 Xcode，自动刷新功能需要 Xcode。"
    echo "   你可以从 App Store 安装 Xcode 后重新运行此脚本。"
    echo "   没有 Xcode 的话，应用每 7 天需要重新下载一次。"
    echo ""
    echo "按任意键退出..."
    read -n 1
    exit 1
fi
echo "✓ Xcode 已安装"

# Create install directory
mkdir -p "$INSTALL_DIR"
echo "✓ 创建目录: $INSTALL_DIR"

# Copy project from DMG
PROJECT_SRC="$SCRIPT_DIR/$PROJECT_NAME"
if [ -d "$PROJECT_SRC" ]; then
    rm -rf "$INSTALL_DIR/$PROJECT_NAME"
    cp -R "$PROJECT_SRC" "$INSTALL_DIR/$PROJECT_NAME"
    echo "✓ 复制项目文件"
else
    echo "❌ 未找到项目文件夹，请确保 $PROJECT_NAME 与此脚本在同一目录"
    echo "按任意键退出..."
    read -n 1
    exit 1
fi

# Create refresh script with fixed derived data path
cat > "$INSTALL_DIR/refresh_profile.sh" << REFRESH
#!/bin/bash
set -e

BASE_DIR="$INSTALL_DIR/$PROJECT_NAME"
LOG_FILE="\$HOME/Library/Logs/com.local.EbbinghausMemory.refresh.log"
DERIVED_DIR="\$HOME/Library/Developer/Xcode/DerivedData/EbbinghausMemoryRefresh"
APP_DST="/Applications/艾伦耶格尔记忆曲线.app"

mkdir -p "\$DERIVED_DIR"

echo "[\$(date '+%Y-%m-%d %H:%M:%S')] Auto refresh starting..." >> "\$LOG_FILE"

cd "\$BASE_DIR"
if xcodebuild -project "艾伦耶格尔.xcodeproj" \\
    -scheme "艾宾浩斯遗忘曲线" \\
    -configuration Release \\
    -derivedDataPath "\$DERIVED_DIR" \\
    -allowProvisioningUpdates \\
    build >> "\$LOG_FILE" 2>&1; then
    
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] Build OK, deploying..." >> "\$LOG_FILE"
    
    BUILT_APP="\$DERIVED_DIR/Build/Products/Release/艾宾浩斯遗忘曲线.app"
    if [ -d "\$BUILT_APP" ]; then
        rm -rf "\$APP_DST"
        cp -R "\$BUILT_APP" "\$APP_DST"
        
        EXPIRY=\$(security cms -D -i "\$APP_DST/Contents/embedded.provisionprofile" 2>/dev/null | \\
            grep -A1 ExpirationDate | tail -1 | sed 's/.*<date>\(.*\)<\/date>.*/\1/')
        echo "[\$(date '+%Y-%m-%d %H:%M:%S')] Deployed. Profile expires: \$EXPIRY" >> "\$LOG_FILE"
    else
        echo "[\$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Built app not found at \$BUILT_APP" >> "\$LOG_FILE"
    fi
else
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] Build FAILED!" >> "\$LOG_FILE"
fi
REFRESH
chmod +x "$INSTALL_DIR/refresh_profile.sh"
echo "✓ 创建刷新脚本"

# Install LaunchAgent
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$HOME/Library/LaunchAgents/com.local.EbbinghausMemory.refresh.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.EbbinghausMemory.refresh</string>
    <key>Program</key>
    <string>$INSTALL_DIR/refresh_profile.sh</string>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/com.local.EbbinghausMemory.refresh.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/com.local.EbbinghausMemory.refresh.stderr.log</string>
</dict>
</plist>
PLIST

launchctl unload "$HOME/Library/LaunchAgents/com.local.EbbinghausMemory.refresh.plist" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/com.local.EbbinghausMemory.refresh.plist"
echo "✓ LaunchAgent 已安装并加载"

# Run first refresh
echo ""
echo "正在执行首次构建并刷新凭证（约 1-3 分钟）..."
echo ""

if bash "$INSTALL_DIR/refresh_profile.sh"; then
    echo ""
    echo "========================================"
    echo "   ✅ 全部完成！"
    echo "========================================"
    echo ""
    echo "  • 应用: /Applications/艾伦耶格尔记忆曲线.app"
    echo "  • 每天凌晨 3:00 自动刷新凭证"
    echo "  • 日志: ~/Library/Logs/com.local.EbbinghausMemory.refresh.log"
    echo ""
    echo "  💡 提示: 首次打开应用时，若提示"无法验证开发者""
    echo "     请右键点击应用 → 选择"打开"即可。"
    echo ""
else
    echo ""
    echo "⚠️  首次构建失败，但定时任务已安装。"
    echo "   请检查日志:"
    echo "   tail ~/Library/Logs/com.local.EbbinghausMemory.refresh.log"
fi

echo ""
echo "按任意键退出..."
read -n 1
