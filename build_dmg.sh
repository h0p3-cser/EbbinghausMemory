#!/bin/bash
set -e

PROJECT_DIR="/Users/h0pe_wsv/Desktop/开发区域/艾宾浩斯记忆曲线工具"
SIGN_IDENTITY="Apple Development: xiaobutou_20091214@163.com (4VQY79Z8D9)"
DMG_NAME="艾伦耶格尔记忆曲线"
STAGING="/tmp/dmg_staging"

echo "=== Step 1: Build with ad-hoc signing ==="
cd "$PROJECT_DIR"
xcodebuild -project "艾伦耶格尔.xcodeproj" \
    -scheme "艾宾浩斯遗忘曲线" \
    -configuration Release \
    clean build 2>&1 | grep -E "BUILD|error:" | tail -3

BUILT="$HOME/Library/Developer/Xcode/DerivedData/艾伦耶格尔-ahmxfpaqhdvczyakoxbdkbjeruzz/Build/Products/Release/艾宾浩斯遗忘曲线.app"

echo "=== Step 2: Re-sign with dev cert (no profile, never expires) ==="
rm -f "$BUILT/Contents/embedded.provisionprofile" 2>/dev/null || true
rm -f "$BUILT/Contents/PlugIns/TodayReviewWidgetExtension.appex/Contents/embedded.provisionprofile" 2>/dev/null || true
codesign --force --deep --sign "$SIGN_IDENTITY" "$BUILT" 2>&1
echo "✓ Signed: $(codesign -dvvv "$BUILT" 2>&1 | grep Authority | head -1 | sed 's/Authority=//')"

echo ""
echo "=== Step 3: Package DMG ==="
rm -rf "$STAGING"
mkdir -p "$STAGING"

# Simple DMG: just app + Applications link
cp -R "$BUILT" "$STAGING/艾伦耶格尔记忆曲线.app"
ln -s /Applications "$STAGING/Applications"

# Create README for DMG
cat > "$STAGING/安装说明.txt" << 'README'
艾伦耶格尔记忆曲线 - 安装说明
================================

📦 安装
拖拽 "艾伦耶格尔记忆曲线.app" 到 Applications 文件夹即可。

🔐 首次打开
若提示"无法验证开发者"，请右键点击应用 → 选择"打开"。

✅ 无需 Xcode，无需额外配置，永不过期。

📊 桌面小组件
安装后在桌面右键 → 编辑小组件 → 搜索"艾伦耶格尔"即可添加。

🔗 源码 & 更新
https://github.com/h0p3-cser/EbbinghausMemory
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
echo "=== ✅ DMG 就绪 ==="
ls -lh "$DMG_FINAL"
echo "SHA256: $(shasum -a 256 "$DMG_FINAL" | awk '{print $1}')"
echo ""
echo "📌 特点："
echo "  - Apple 开发证书签名，无需 Xcode"
echo "  - 无 Provisioning Profile，永不过期"  
echo "  - 含桌面小组件 (TeamIdentifier: 8M93XXXUTF)"
