#!/usr/bin/env bash
# YourImageShare - Flameshot upload script
#
# Captures a screenshot with Flameshot, uploads it to YourImageShare, copies
# the resulting direct link to the clipboard, and shows a desktop
# notification. Bind this script to a keyboard shortcut in your desktop
# environment instead of the default Flameshot shortcut.
#
# Setup:
#   1. export YIS_API_KEY="your-api-key-here" in your shell profile,
#      or create ~/.config/yourimageshare/api_key containing just the key.
#   2. chmod +x yis-flameshot-upload.sh
#   3. Bind this script to a hotkey (e.g. Print Screen) in your DE's
#      keyboard shortcut settings.
#
# Requires: flameshot, curl. Optional: jq (more reliable JSON parsing),
# xclip or wl-copy (clipboard), notify-send (notifications).

set -uo pipefail

API_URL="https://yourimageshare.com/api"
CONFIG_KEY_FILE="$HOME/.config/yourimageshare/api_key"

API_KEY="${YIS_API_KEY:-}"
if [ -z "$API_KEY" ] && [ -f "$CONFIG_KEY_FILE" ]; then
    API_KEY="$(tr -d '[:space:]' < "$CONFIG_KEY_FILE")"
fi

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send "YourImageShare" "$1"
}

if [ -z "$API_KEY" ]; then
    notify "No API key set. See the top of this script for setup."
    echo "No API key set. Export YIS_API_KEY or create $CONFIG_KEY_FILE." >&2
    exit 1
fi

TMP_FILE="$(mktemp --suffix=.png)"
trap 'rm -f "$TMP_FILE"' EXIT

flameshot gui --raw > "$TMP_FILE"

if [ ! -s "$TMP_FILE" ]; then
    # Empty file means the user cancelled the capture.
    exit 0
fi

RESPONSE="$(curl -s "$API_URL" -H "X-API-Key: $API_KEY" -F "uploads=@$TMP_FILE")"

if command -v jq >/dev/null 2>&1; then
    TYPE="$(echo "$RESPONSE" | jq -r '.type // empty')"
    URL="$(echo "$RESPONSE" | jq -r '.data.src // empty')"
    ERROR="$(echo "$RESPONSE" | jq -r '.errors // empty')"
else
    TYPE="$(echo "$RESPONSE" | grep -oE '"type":"[a-z]+"' | head -1 | cut -d'"' -f4)"
    URL="$(echo "$RESPONSE" | grep -oE '"src":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/\\\//\//g')"
    ERROR="$(echo "$RESPONSE" | grep -oE '"errors":"[^"]*"' | head -1 | cut -d'"' -f4)"
fi

if [ "$TYPE" != "success" ] || [ -z "$URL" ]; then
    notify "Upload failed: ${ERROR:-unknown error}"
    echo "Upload failed: $RESPONSE" >&2
    exit 1
fi

if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$URL" | xclip -selection clipboard
elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$URL" | wl-copy
fi

notify "Uploaded! Link copied to clipboard:
$URL"
echo "$URL"
