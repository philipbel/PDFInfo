#!/bin/bash
set -euo pipefail

SCHEME="PDF Info—Release"
CONFIGURATION="Release"
APP_NAME="PDF Info.app"
DERIVED_DATA="${TMPDIR:-/tmp}/PDFInfo-release"
APP="$DERIVED_DATA/Build/Products/${CONFIGURATION}/${APP_NAME}"

#
# Git checks
#
cd "$(git rev-parse --show-toplevel)"
if [ -n "$(git status --porcelain)" ]; then
    echo "error: working tree is not clean:"
    git status --short
    exit 1
fi


#
# Build
#
echo "Building scheme '${SCHEME}'"
xcodebuild \
    -project PDFInfo.xcodeproj \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${DERIVED_DATA}" \
    -destination "generic/platform=macOS" \
    -quiet \
    clean build
if [ ! -d "$APP" ]; then
    echo "error: built app not found at ${APP}"
    exit 1
fi
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP/Contents/Info.plist")
echo "Built: ${APP_NAME} at '${APP}' version '${VERSION}' build '${BUILD}'"


#
# Package
#
echo "Building disk image"
./etc/make-dmg.sh "${APP}"


#
# Release
#
TAG="v$VERSION"
git tag -a "$TAG" -m "PDF Info $VERSION"
git push --atomic origin master "$TAG"
gh release create "$TAG" "$DMG" \
    --draft \
    --verify-tag \
    --title "PDF Info $VERSION" \
    --generate-notes
