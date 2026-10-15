#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build-release"
DESTINATION="${1:-$PROJECT_ROOT/Dist}"
mkdir -p "$DESTINATION"
xcodebuild -project "$PROJECT_ROOT/Komorebi Study.xcodeproj" -scheme 'Komorebi Study' -configuration Release -derivedDataPath "$BUILD_DIR" CODE_SIGNING_ALLOWED=NO build
/usr/bin/ditto "$BUILD_DIR/Build/Products/Release/Komorebi Study.app" "$DESTINATION/Komorebi Study.app"
/usr/bin/codesign --force --deep --sign - "$DESTINATION/Komorebi Study.app"
/usr/bin/codesign --verify --deep --strict "$DESTINATION/Komorebi Study.app"
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT
/usr/bin/ditto "$DESTINATION/Komorebi Study.app" "$STAGING_DIR/Komorebi Study.app"
ln -s /Applications "$STAGING_DIR/Applications"
/usr/bin/hdiutil create -volname 'Komorebi Study' -srcfolder "$STAGING_DIR" -ov -format UDZO "$DESTINATION/Komorebi Study.dmg"
/usr/bin/hdiutil verify "$DESTINATION/Komorebi Study.dmg"
