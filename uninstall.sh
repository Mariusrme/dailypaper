#!/bin/bash
#
# DailyPaper — Uninstaller
#

PLIST_PATH="$HOME/Library/LaunchAgents/com.dailypaper.update.plist"
INSTALL_DIR="$HOME/.dailypaper"

echo ""
echo "  Uninstalling DailyPaper..."

# Stop the agent
launchctl unload "$PLIST_PATH" 2>/dev/null || true
rm -f "$PLIST_PATH"
echo "  [1/2] Removed LaunchAgent"

# Remove files
rm -rf "$INSTALL_DIR"
echo "  [2/2] Removed $INSTALL_DIR"

echo ""
echo "  DailyPaper has been uninstalled."
echo "  Your current wallpaper will remain until you change it manually."
echo ""
