#!/usr/bin/env bash
# Alt+Tab: walk the most-recently-used window list, across all normal workspaces.
#   alttab.sh next   -> one window deeper in the MRU list (Alt+Tab)
#   alttab.sh prev   -> one window back (Alt+Shift+Tab; first press = least recently used)
#
# Hyprland's own `focus({ last })` only toggles between the two latest windows, and
# `cycle_next` follows window-list order, not recency. So: snapshot the MRU order on the
# first press and keep stepping through that snapshot while presses come within
# TIMEOUT_MS of each other. (Focusing a window changes the live MRU order, which is why
# the snapshot is needed.) A gap longer than TIMEOUT_MS starts a fresh walk.
#
# shortcut: no Alt-release detection (needs a keyboard grab), so the walk resets by timeout
# instead; if it feels too short/long, change TIMEOUT_MS.
#
# Skipped: unmapped/hidden windows and windows on special workspaces (incl. special:minimized).

set -euo pipefail

DIR="${1:-next}"
TIMEOUT_MS=1500
STATE="${XDG_RUNTIME_DIR:-/tmp}/hypr-alttab.state"   # line1: last press (ms), line2: index, rest: addresses

now_ms() { date +%s%3N; }
NOW="$(now_ms)"

addrs=(); idx=0; last=0
if [ -r "$STATE" ]; then
    last="$(sed -n 1p "$STATE")"
    if [ $((NOW - last)) -le "$TIMEOUT_MS" ]; then
        idx="$(sed -n 2p "$STATE")"
        mapfile -t addrs < <(sed -n '3,$p' "$STATE")
    fi
fi

# fresh walk: snapshot MRU order (focusHistoryID 0 = currently focused)
if [ "${#addrs[@]}" -eq 0 ]; then
    mapfile -t addrs < <(hyprctl clients -j | jq -r \
        '[.[] | select(.mapped and (.hidden | not) and .workspace.id >= 0)]
         | sort_by(.focusHistoryID) | .[].address')
    idx=0
fi

n="${#addrs[@]}"
[ "$n" -gt 1 ] || exit 0   # nothing to switch to

if [ "$DIR" = prev ]; then idx=$(( (idx - 1 + n) % n )); else idx=$(( (idx + 1) % n )); fi
target="${addrs[$idx]}"

{ echo "$NOW"; echo "$idx"; printf '%s\n' "${addrs[@]}"; } > "$STATE"

hyprctl dispatch "hl.dsp.focus({ window = \"address:$target\" })" >/dev/null
# raise so a floating window isn't left under others
hyprctl dispatch 'hl.dsp.window.alter_zorder({ mode = "top" })' >/dev/null
