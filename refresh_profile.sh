#!/bin/bash
set -e

PROJECT_DIR="/Users/h0pe_wsv/Desktop/开发区域/艾宾浩斯记忆曲线工具"
LOG_FILE="$HOME/Library/Logs/com.local.EbbinghausMemory.refresh.log"
APP_SRC="$HOME/Library/Developer/Xcode/DerivedData/艾伦耶格尔-ahmxfpaqhdvczyakoxbdkbjeruzz/Build/Products/Release/艾宾浩斯遗忘曲线.app"
APP_DST="/Applications/艾伦耶格尔记忆曲线.app"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting profile refresh..." >> "$LOG_FILE"

# Build with auto provisioning (incremental, no clean)
cd "$PROJECT_DIR"
if xcodebuild -project "艾伦耶格尔.xcodeproj" \
    -scheme "艾宾浩斯遗忘曲线" \
    -configuration Release \
    -allowProvisioningUpdates \
    build >> "$LOG_FILE" 2>&1; then
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Build succeeded. Deploying..." >> "$LOG_FILE"
    
    # Replace the app
    rm -rf "$APP_DST"
    cp -R "$APP_SRC" "$APP_DST"
    
    # Get new expiry date
    EXPIRY=$(security cms -D -i "$APP_DST/Contents/embedded.provisionprofile" 2>/dev/null | grep -A1 ExpirationDate | tail -1 | sed 's/.*<date>\(.*\)<\/date>.*/\1/')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deployed. Profile expires: $EXPIRY" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done." >> "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Build FAILED!" >> "$LOG_FILE"
    exit 1
fi
