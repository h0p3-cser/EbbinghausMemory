#!/bin/bash
set -e

PROJECT_DIR="/Users/h0pe_wsv/Desktop/开发区域/艾宾浩斯记忆曲线工具"
SIGN_ID="Apple Development: xiaobutou_20091214@163.com (4VQY79Z8D9)"
DMG_NAME="艾伦耶格尔记忆曲线"
STAGING="/tmp/dmg_staging"

echo "=== Step 1: xcodebuild (with profile for correct entitlements) ==="
cd "$PROJECT_DIR"
xcodebuild -project "艾伦耶格尔.xcodeproj" \
    -scheme "艾宾浩斯遗忘曲线" \
    -configuration Release \
    -allowProvisioningUpdates \
    clean build 2>&1 | grep -E "BUILD|error:" | tail -3

BUILT="$HOME/Library/Developer/Xcode/DerivedData/艾伦耶格尔-ahmxfpaqhdvczyakoxbdkbjeruzz/Build/Products/Release/艾宾浩斯遗忘曲线.app"

echo ""
echo "=== Step 2: 剥离 profile，重签（永不过期）==="
cp -R "$BUILT" /tmp/signed_app.app

# Remove profiles
rm -rf /tmp/signed_app.app/Contents/embedded.provisionprofile
rm -rf /tmp/signed_app.app/Contents/PlugIns/TodayReviewWidgetExtension.appex/Contents/embedded.provisionprofile 2>/dev/null

# Widget entitlements (minimum needed for Notification Center discovery)
cat > /tmp/widget_ent.plist << 'WEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.local.EbbinghausMemory</string>
	</array>
</dict>
</plist>
WEOF

# Main app: empty (no sandbox = UserDefaults(suiteName:) works without app-groups)
cat > /tmp/main_ent.plist << 'MEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
MEOF

# Sign widget first, then app
codesign --force --sign "$SIGN_ID" --entitlements /tmp/widget_ent.plist \
    /tmp/signed_app.app/Contents/PlugIns/TodayReviewWidgetExtension.appex 2>&1
codesign --force --sign "$SIGN_ID" --entitlements /tmp/main_ent.plist \
    /tmp/signed_app.app 2>&1

# Verify
codesign --verify --verbose /tmp/signed_app.app 2>&1
codesign --verify --verbose /tmp/signed_app.app/Contents/PlugIns/TodayReviewWidgetExtension.appex 2>&1
echo "✓ 重签完成，无 profile"

echo ""
echo "=== Step 3: 打包 DMG ==="
rm -rf "$STAGING"
mkdir -p "$STAGING"

cp -R /tmp/signed_app.app "$STAGING/艾伦耶格尔记忆曲线.app"
ln -s /Applications "$STAGING/Applications"

# 安装说明
cat > "$STAGING/安装说明.txt" << 'README'
艾伦耶格尔记忆曲线 - 安装说明
================================

📦 拖拽 App 到 Applications 即完成安装
🔐 首次右键 → 打开
📊 小组件: 桌面右键 → 编辑小组件 → 搜索"艾伦耶格尔"
✅ 无需 Xcode，永不过期

🔗 https://github.com/h0p3-cser/EbbinghausMemory
README

# DMG
DMG_TMP="/tmp/${DMG_NAME}_tmp.dmg"
DMG_FINAL="$PROJECT_DIR/${DMG_NAME}.dmg"
rm -f "$DMG_TMP" "$DMG_FINAL"

hdiutil create -size 300m -fs HFS+ -volname "$DMG_NAME" -ov "$DMG_TMP"
hdiutil attach "$DMG_TMP" -nobrowse -mountpoint /tmp/dmg_mount
cp -R "$STAGING"/* /tmp/dmg_mount/
sync
sleep 2
hdiutil detach /tmp/dmg_mount -force
hdiutil convert "$DMG_TMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL"
rm -f "$DMG_TMP" /tmp/signed_app.app

echo ""
echo "=== ✅ 完成 ==="
ls -lh "$DMG_FINAL"
echo "SHA256: $(shasum -a 256 "$DMG_FINAL" | awk '{print $1}')"
echo "特点: dev证书 + 完整entitlements + 无profile = 永不过期"
