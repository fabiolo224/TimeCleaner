#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="TimeCleaner"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"

echo "→ Compilazione..."

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

swiftc \
  "$SCRIPT_DIR/Sources/main.swift" \
  "$SCRIPT_DIR/Sources/AppDelegate.swift" \
  "$SCRIPT_DIR/Sources/AppInfo.swift" \
  "$SCRIPT_DIR/Sources/ContentView.swift" \
  "$SCRIPT_DIR/Sources/Onboarding.swift" \
  "$SCRIPT_DIR/Sources/Localization.swift" \
  "$SCRIPT_DIR/Sources/Updater.swift" \
  "$SCRIPT_DIR/Sources/Settings.swift" \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
  -framework Cocoa \
  -framework SwiftUI \
  -framework ServiceManagement \
  -framework UserNotifications

cp "$SCRIPT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$SCRIPT_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
cp "$SCRIPT_DIR/menubar_template@2x.png" "$APP_BUNDLE/Contents/Resources/menubar_template@2x.png"

echo "✓ Build completata: $APP_BUNDLE"
