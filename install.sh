#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="TimeCleaner"
INSTALL_PATH="/Applications/$APP_NAME.app"
LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/com.timecleaner.app.plist"

# Build first
bash "$SCRIPT_DIR/build.sh"

echo "→ Installazione in /Applications..."
rm -rf "$INSTALL_PATH"
cp -R "$SCRIPT_DIR/$APP_NAME.app" "$INSTALL_PATH"

echo "→ Installazione LaunchAgent..."
mkdir -p "$HOME/Library/LaunchAgents"

cat > "$LAUNCH_AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.timecleaner.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_PATH/Contents/MacOS/$APP_NAME</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/timecleaner.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/timecleaner.log</string>
</dict>
</plist>
EOF

# Ricarica il LaunchAgent
launchctl unload "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
launchctl load "$LAUNCH_AGENT_PLIST"

echo ""
echo "✓ TimeCleaner installato con successo!"
echo "  L'icona apparirà nella menu bar e si riavvierà automaticamente al login."
