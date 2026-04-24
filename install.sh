#!/bin/bash
#
# DailyPaper — One-command installer for macOS
# Usage: curl -sL https://raw.githubusercontent.com/Mariusrme/dailypaper/main/install.sh | bash
#

set -e

REPO="Mariusrme/dailypaper"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
WALLPAPER_URL="${RAW_BASE}/output/wallpaper.jpg"

INSTALL_DIR="$HOME/.dailypaper"
WALLPAPER_PATH="$INSTALL_DIR/wallpaper.jpg"
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
TODAY=$(date +%Y-%m-%d)
WALLPAPER_PATH="$INSTALL_DIR/wallpaper-${TODAY}.jpg"
UPDATESCRIPT

# Inject the URL (not single-quoted so it expands)
cat >> "$SCRIPT_PATH" << UPDATESCRIPT2
WALLPAPER_URL="${WALLPAPER_URL}"
UPDATESCRIPT2

cat >> "$SCRIPT_PATH" << 'UPDATESCRIPT3'
MAX_RETRIES=3
RETRY_DELAY=30
LOG_FILE="$INSTALL_DIR/dailypaper.log"
LOG_MAX_LINES=200

# Rotate log if it exceeds LOG_MAX_LINES
if [ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE")" -gt "$LOG_MAX_LINES" ]; then
    tail -n "$LOG_MAX_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi

# Wait for network (max 60s)
for i in $(seq 1 12); do
    curl -s --max-time 5 -o /dev/null https://github.com && break
    sleep 5
done

# Download with retries
for attempt in $(seq 1 $MAX_RETRIES); do
    curl -sL --max-time 60 "$WALLPAPER_URL" -o "${WALLPAPER_PATH}.tmp"

    # Validate it's a real JPEG (magic bytes: FF D8 FF) AND > 100 KB
    FILE_SIZE=$(stat -f%z "${WALLPAPER_PATH}.tmp" 2>/dev/null || echo 0)
    MAGIC=$(xxd -p -l 3 "${WALLPAPER_PATH}.tmp" 2>/dev/null)
    if [ "$FILE_SIZE" -gt 100000 ] && [ "$MAGIC" = "ffd8ff" ]; then
        mv "${WALLPAPER_PATH}.tmp" "$WALLPAPER_PATH"

        # Clean up old wallpapers (keep only today's)
        find "$INSTALL_DIR" -name "wallpaper-*.jpg" -o -name "wallpaper-*.png" | grep -v "wallpaper-${TODAY}.jpg" | xargs rm -f 2>/dev/null

        # Set as wallpaper (desktoppr if available, fallback to osascript)
        if command -v desktoppr &>/dev/null; then
            desktoppr "${WALLPAPER_PATH}"
        else
            osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"${WALLPAPER_PATH}\""
        fi

        echo "[DailyPaper] Wallpaper updated (attempt $attempt): $(date)"
        exit 0
    fi

    rm -f "${WALLPAPER_PATH}.tmp"
    echo "[DailyPaper] Attempt $attempt failed, retrying in ${RETRY_DELAY}s..."
    [ "$attempt" -lt "$MAX_RETRIES" ] && sleep $RETRY_DELAY
done

echo "[DailyPaper] All $MAX_RETRIES attempts failed, keeping current wallpaper: $(date)"
UPDATESCRIPT3

chmod +x "$SCRIPT_PATH"
echo "  [2/4] Created update script"

# 3. Create LaunchAgent (runs at login + every day at 7 AM)
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
        <integer>7</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
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
