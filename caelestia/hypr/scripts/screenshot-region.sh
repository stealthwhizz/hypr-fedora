#!/usr/bin/env bash
# Region screenshot: select an area, save it to ~/Pictures/Screenshots AND copy it to the
# clipboard (so it also lands in the Super+V history), then notify.
# Replaces caelestia's default region flow, which opens swappy and copies nothing by itself.
# Esc / right-click while selecting cancels without doing anything.
#
# shortcut: plain slurp, no freeze-frame or window snapping like caelestia's picker
# (that one is still on Super+Shift+Alt+S, with swappy editing).

set -euo pipefail

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/Screenshot_$(date +%Y%m%d_%H%M%S).png"

geometry="$(slurp -d)" || exit 0   # slurp exits non-zero on cancel
grim -g "$geometry" "$FILE"
wl-copy --type image/png < "$FILE"

notify-send -a screenshot -i "$FILE" "Screenshot taken" "Saved to $DIR and copied to clipboard"
