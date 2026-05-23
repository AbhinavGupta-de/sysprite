#!/usr/bin/env bash
# Sketchybar plugin: render Sysprite stats.
# Drop into ~/.config/sketchybar/plugins/sysprite.sh and chmod +x.
#
# Reads the JSON snapshot via the `sysprite` binary (symlinked from
# /Applications/Sysprite.app/Contents/MacOS/Sysprite) and updates $NAME with a
# CPU / MEM string plus a color tint that reflects combined pressure.

set -euo pipefail

SYSPRITE_BIN="${SYSPRITE_BIN:-/usr/local/bin/sysprite}"
if [ ! -x "$SYSPRITE_BIN" ] && [ -x "/Applications/Sysprite.app/Contents/MacOS/Sysprite" ]; then
    SYSPRITE_BIN="/Applications/Sysprite.app/Contents/MacOS/Sysprite"
fi

if ! JSON=$("$SYSPRITE_BIN" stats --json 2>/dev/null); then
    sketchybar --set "$NAME" label="sysprite ?" icon="" 2>/dev/null || true
    exit 0
fi

CPU=$(echo "$JSON" | /usr/bin/awk -F'[:,]' '/"cpu"/ {gsub(/[ \t]/,"",$2); printf "%d", $2; exit}')
MEM=$(echo "$JSON" | /usr/bin/awk -F'[:,]' '/"memory"/ {gsub(/[ \t]/,"",$2); printf "%d", $2; exit}')
PRESSURE=$(echo "$JSON" | /usr/bin/awk -F'[:,]' '/"pressure"/ {gsub(/[ \t]/,"",$2); printf "%d", $2; exit}')

LABEL=$(printf "CPU %d%%  MEM %d%%" "$CPU" "$MEM")

# Color tiers — tweak to your sketchybar palette
if   [ "$PRESSURE" -ge 90 ]; then COLOR=0xfff7768e   # red
elif [ "$PRESSURE" -ge 70 ]; then COLOR=0xffe0af68   # orange
else                              COLOR=0xff9ece6a   # green
fi

sketchybar --set "$NAME" \
    label="$LABEL" \
    label.color="$COLOR" \
    icon="󰓅"
