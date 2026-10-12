#!/usr/bin/env bash
# Super+V clipboard picker: cliphist history in fuzzel, plus a "Clear all" entry.
# Replaces `caelestia clipboard` (same behaviour: pick an entry -> it becomes the live clipboard).
#
# The Clear-all entry is the LAST line, not the first, so pressing Enter right after opening
# (first line highlighted) can never wipe your history by accident. Type "clear" to jump to it.

set -euo pipefail

CLEAR='🗑  Clear all clipboard history'

chosen="$( { cliphist list; printf '%s\n' "$CLEAR"; } \
    | fuzzel --dmenu --placeholder='Type to search clipboard  ("clear" = wipe all)')" || exit 0
[ -n "$chosen" ] || exit 0

if [ "$chosen" = "$CLEAR" ]; then
    # history first, then the live clipboard, so the watcher can't re-store what's still in it
    cliphist wipe
    wl-copy --clear
    notify-send -a clipboard -u low 'Clipboard cleared' 'History and current clipboard wiped'
else
    printf '%s' "$chosen" | cliphist decode | wl-copy
fi
