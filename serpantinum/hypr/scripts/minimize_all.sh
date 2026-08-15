#!/usr/bin/env bash
# Minimize every window on the currently active workspace (show desktop).
# Restore with the same key used to toggle the "minimized" special workspace.

active_ws=$(hyprctl activeworkspace -j | jq -r '.id')

hyprctl clients -j | jq -r --argjson ws "$active_ws" \
  '.[] | select(.workspace.id == $ws) | .address' | while read -r addr; do
    hyprctl eval "hl.dispatch(hl.dsp.window.move({workspace = 'special:minimized', window = 'address:$addr', follow = false}))" >/dev/null 2>&1
done
