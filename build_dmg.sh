#!/bin/bash
set -e

PROJECT_DIR="/Users/h0pe_wsv/Desktop/开发区域/艾宾浩斯记忆曲线工具"
DMG_NAME="艾伦耶格尔记忆曲线"
STAGING="/tmp/dmg_staging"

echo "=== 构建（含组件需要的 entitlements + profile）==="
cd "$PROJECT_DIR"
xcodebuild -project "艾伦耶格尔.xcodeproj" \
    -scheme "艾宾浩斯遗忘曲线" \
    -configuration Release \
    -allowProvisioningUpdates \
    clean build 2>&1 | grep -E "BUILD|error|Provisioning" | tail -5

BUILT="$HOME/Library/Developer/Xcode/DerivedData/艾伦耶格尔-ahmxfpaqhdvczyakoxbdkbjeruzz/Build/Products/Release/艾宾浩斯遗忘曲线.app"

echo ""
echo "=== 验证 ==="
EXPIRY=$(security cms -D -i "$BUILT/Contents/embedded.provisionprofile" 2>/dev/null | grep -A1 ExpirationDate | tail -1 | sed 's/.*<date>\(.*\)<\/date>.*/\1/')
echo "Profile 过期: $EXPIRY"
codesign -dvvv "$BUILT" 2>&1 | grep -E "Authority|TeamIdentifier" | head -2

echo ""
echo "=== 打包 DMG ==="
rm -rf "$STAGING"
mkdir -p "$STAGING"

# App
cp -R "$BUILT" "$STAGING/艾伦耶格尔记忆曲线.app"

# Applications link
ln -s /Applications "$STAGING/Applications"

# Setup script for auto-refresh  
cp "setup_auto_refresh.command" "$STAGING/"
cp -R "." "$STAGING/艾伦耶格尔记忆曲线工具"
rm -rf "$STAGING/艾伦耶格尔记忆曲线工具/.git" 2>/dev/null

# 安装说明
cat > "$STAGING/安装说明.txt" << 'README'
艾伦耶格尔记忆曲线 - 安装说明
================================

📦 安装
拖拽 App 到 Applications 文件夹。

🔐 首次打开
若提示"无法验证开发者"，右键点击 → "打开"。

📊 桌面小组件
安装应用后，桌面右键 → 编辑小组件 → 搜索"艾伦耶格尔"。

⚠️ 小组件需定期刷新凭证（7天）
如有 Xcode，双击运行 setup_auto_refresh.command 即可自动续期。
没有 Xcode 可从 GitHub 重新下载新版 DMG。

🔗 https://github.com/h0p3-cser/EbbinghausMemory
README

# Create DMG
DMG_TMP="/tmp/${DMG_NAME}_tmp.dmg"
DMG_FINAL="$PROJECT_DIR/${DMG_NAME}.dmg"
rm -f "$DMG_TMP" "$DMG_FINAL"

hdiutil create -size 800m -fs HFS+ -volname "$DMG_NAME" -ov "$DMG_TMP"
hdiutil attach "$DMG_TMP" -nobrowse -mountpoint /tmp/dmg_mount
cp -R "$STAGING"/* /tmp/dmg_mount/
sync
sleep 2
hdiutil detach /tmp/dmg_mount -force
hdiutil convert "$DMG_TMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL"
rm -f "$DMG_TMP"

echo ""
echo "=== ✅ DMG: $DMG_FINAL ==="
ls -lh "$DMG_FINAL"
echo "SHA256: $(shasum -a 256 "$DMG_FINAL" | awk '{print $1}')"
echo "Profile: $EXPIRY"
