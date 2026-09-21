#!/bin/bash
set -euo pipefail

SELF=$(basename "$0")

APP="$1"
if [ ! -d "$APP" ]; then
    echo "Usage: $SELF <App Bundle>"
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${APP}/Contents/Info.plist")
APP_BASE_NAME=$(basename "${APP}")
APP_NAME=${APP_BASE_NAME%.*}
DMG="${APP_NAME// /}-${VERSION}.dmg"

WINDOW_W=500; WINDOW_H=300
ICON_SIZE=100
APP_X=120; APP_Y=150
DROP_X=380; DROP_Y=150

create-dmg \
  --volname "${APP_NAME}" \
  --window-size $WINDOW_W $WINDOW_H \
  --icon-size "${ICON_SIZE}" \
  --icon "${APP_BASE_NAME}" $APP_X $APP_Y \
  --app-drop-link $DROP_X $DROP_Y \
  --volicon "${APP}/Contents/Resources/AppIcon.icns" \
  --skip-jenkins \
  "$DMG" \
  "$APP"

echo "Disk image created: ${DMG}"
shasum -a 256 "$DMG"
