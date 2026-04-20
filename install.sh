#!/bin/bash
#
# DailyPaper — One-command installer for macOS
# Usage: curl -sL https://raw.githubusercontent.com/Mariusrme/dailypaper/main/install.sh | bash
#

set -e

REPO="Mariusrme/dailypaper"  # <-- Change this to your GitHub username/repo
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
WALLPAPER_URL="${RAW_BASE}/output/wallpaper.png"

INSTALL_DIR="$HOME/.dailypaper"
WALLPAPER_PATH="$INSTALL_DIR/wallpaper.png"
SCRIPT_PATH="$INSTALL_DIR/update.sh"
PLIST_NAME="com.dailypaper.update"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

echo ""
echo "  ╔═══════════════════════════════╗"
echo "  ║   DailyPaper — Installing     ║"
echo "  ╚═══════════════════════════════╝"
echo ""

# 1. Create install directory
mkdir -p "$INSTALL_DIR"
echo "  [1/4] Created $INSTALL_DIR"

# 2. Create the update script
cat > "$SCRIPT_PATH" << 'UPDATESCRIPT'
#!/bin/bash
# DailyPaper — Fetch today's wallpaper and set it

INSTALL_DIR="$HOME/.dailypaper"
WALLPAPER_PATH="$INSTALL_DIR/wallpaper.png"
UPDATESCRIPT

# Inject the URL (not single-quoted so it expands)
cat >> "$SCRIPT_PATH" << UPDATESCRIPT2
WALLPAPER_URL="${WALLPAPER_URL}"
UPDATESCRIPT2

cat >> "$SCRIPT_PATH" << 'UPDATESCRIPT3'

# Download today's wallpaper
curl -sL "$WALLPAPER_URL" -o "${WALLPAPER_PATH}.tmp"

# Only update if download succeeded (file > 100KB)
FILE_SIZE=$(stat -f%z "${WALLPAPER_PATH}.tmp" 2>/dev/null || echo 0)
if [ "$FILE_SIZE" -gt 100000 ]; then
    mv "${WALLPAPER_PATH}.tmp" "$WALLPAPER_PATH"

    # Set as wallpaper on all desktops
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"${WALLPAPER_PATH}\""
    osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"${WALLPAPER_PATH}\""

    echo "[DailyPaper] Wallpaper updated: $(date)"
else
    rm -f "${WALLPAPER_PATH}.tmp"
    echo "[DailyPaper] Download failed or too small, keeping current wallpaper"
fi
UPDATESCRIPT3

chmod +x "$SCRIPT_PATH"
echo "  [2/4] Created update script"

# 3. Create LaunchAgent (runs at login + every day at 6 AM)
cat > "$PLIST_PATH" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPT_PATH}</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>6</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${INSTALL_DIR}/dailypaper.log</string>
    <key>StandardErrorPath</key>
    <string>${INSTALL_DIR}/dailypaper.log</string>
</dict>
</plist>
PLIST

echo "  [3/4] Created LaunchAgent (runs at boot + 6 AM daily)"

# 4. Load the agent and run first update
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo "  [4/4] Fetching today's wallpaper..."
bash "$SCRIPT_PATH"

echo ""
echo "  Done! Your wallpaper will update automatically every day."
echo "  To uninstall: bash $INSTALL_DIR/uninstall.sh"
echo ""
