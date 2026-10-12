#!/usr/bin/env bash
# Super+V clipboard picker: cliphist history in fuzzel, plus pinned entries and a "Clear all".
#   clipboard-menu.sh          main picker (pinned entries first, then history)
#   clipboard-menu.sh pin      pin picker: pick a history entry to PIN, or a pinned one to UNPIN
#
# Pins live in $XDG_DATA_HOME/clipboard-pins/<sha256-prefix>.bin (raw content; text or images),
# completely separate from cliphist's database, so "Clear all" (cliphist wipe) can never touch them.
# Only unpinning removes a pin.
#
# The action entries ("Pin / unpin", "Clear all") are the LAST lines, so pressing Enter right after
# opening (first line highlighted) can never wipe or change anything. Type "clear" or "pin" to jump.
#
# shortcut: pins are stored unencrypted on disk (same trust level as cliphist's own database);
# don't pin passwords.

set -euo pipefail

PINS="${XDG_DATA_HOME:-$HOME/.local/share}/clipboard-pins"
CLEAR='🗑  Clear all clipboard history  (pinned entries are kept)'
PINMENU='📌  Pin / unpin an entry…'
mkdir -p "$PINS"; chmod 700 "$PINS"

notify() { notify-send -a clipboard -u low "$1" "$2"; }

# one-line preview of a pin file, in cliphist's style
preview() {
    local f="$1" mime
    mime="$(file -b --mime-type "$f")"
    if [[ "$mime" == text/* ]]; then
        head -c 300 "$f" | tr '\n\t\r' '   ' | iconv -c -f UTF-8 -t UTF-8
    else
        printf '[[ binary data %s bytes %s ]]' "$(stat -c %s "$f")" "${mime#*/}"
    fi
}

# "📌 <id><TAB><preview>" lines, newest pin first
pin_lines() {
    local f id
    for f in $(ls -t "$PINS"/*.bin 2>/dev/null); do
        id="$(basename "$f" .bin)"
        printf '📌 %s\t%s\n' "$id" "$(preview "$f")"
    done
}

pin_id() { local s="${1#📌 }"; printf '%s' "${s%%$'\t'*}"; }

copy_pin() {
    local f="$PINS/$1.bin" mime
    mime="$(file -b --mime-type "$f")"
    if [[ "$mime" == text/* ]]; then wl-copy < "$f"; else wl-copy --type "$mime" < "$f"; fi
}

pick() { fuzzel --dmenu --placeholder="$1"; }

pin_mode() {
    local chosen tmp hash
    # history first (Enter on the first line = pin the newest copy, harmless), pins last
    chosen="$( { cliphist list; pin_lines; } \
        | pick 'Pick a copy to PIN  (or a 📌 entry to UNPIN)')" || exit 0
    [ -n "$chosen" ] || exit 0

    if [[ "$chosen" == '📌 '* ]]; then
        rm -f "$PINS/$(pin_id "$chosen").bin"
        notify 'Unpinned' 'Removed from pinned clipboard entries'
    else
        tmp="$(mktemp)"
        printf '%s' "$chosen" | cliphist decode > "$tmp"
        if [ ! -s "$tmp" ]; then rm -f "$tmp"; exit 0; fi
        hash="$(sha256sum < "$tmp" | cut -c1-12)"
        mv "$tmp" "$PINS/$hash.bin"     # re-pinning the same content just refreshes it
        notify 'Pinned' 'This copy now survives "Clear all"'
    fi
}

main_mode() {
    local chosen
    chosen="$( { pin_lines; cliphist list; printf '%s\n%s\n' "$PINMENU" "$CLEAR"; } \
        | pick 'Type to search clipboard  ("pin" = pin/unpin, "clear" = wipe)')" || exit 0
    [ -n "$chosen" ] || exit 0

    if [ "$chosen" = "$CLEAR" ]; then
        # history first, then the live clipboard, so the watcher can't re-store what's still in it.
        # Pins are untouched: they aren't in cliphist's database.
        cliphist wipe
        wl-copy --clear
        notify 'Clipboard cleared' "History wiped. Pinned entries kept: $(ls "$PINS"/*.bin 2>/dev/null | wc -l)"
    elif [ "$chosen" = "$PINMENU" ]; then
        exec "$0" pin
    elif [[ "$chosen" == '📌 '* ]]; then
        copy_pin "$(pin_id "$chosen")"
    else
        printf '%s' "$chosen" | cliphist decode | wl-copy
    fi
}

case "${1:-}" in
    pin) pin_mode ;;
    *)   main_mode ;;
esac
