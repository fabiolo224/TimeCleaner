#!/bin/bash

LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/com.timecleaner.app.plist"

echo "→ Rimozione TimeCleaner..."

launchctl unload "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
rm -f "$LAUNCH_AGENT_PLIST"
rm -rf "/Applications/TimeCleaner.app"
pkill -x TimeCleaner 2>/dev/null || true

echo "✓ TimeCleaner rimosso."
