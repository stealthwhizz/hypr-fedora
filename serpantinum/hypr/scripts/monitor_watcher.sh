#!/usr/bin/env bash
# Auto-apply the current wallpaper to any newly-connected monitor.
#
# swww defaults a newly-discovered output to solid black until explicitly
# told to display something — a monitor that's perfectly enabled in
# Hyprland (correct EDID, mode, position) still shows nothing until an
# `swww img -o <name>` targets it specifically. Without this watcher,
# every future external-monitor connection repeats that "blank screen"
# confusion. Listens for Hyprland's monitoraddedv2 event and reapplies
# whatever's currently showing on the primary output to the new one.

while true; do
    socat -u UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while read -r line; do
        case "$line" in
            monitoraddedv2\>\>*)
                info="${line#monitoraddedv2>>}"
                mon_name="$(echo "$info" | cut -d',' -f2)"
                [ -z "$mon_name" ] && continue

                # Give swww-daemon a moment to register the new output before targeting it
                sleep 1.5

                current_wp="$(swww query 2>/dev/null | grep -oP 'image: \K.*' | head -n1)"
                if [ -n "$current_wp" ]; then
                    swww img -o "$mon_name" "$current_wp" --transition-type fade --transition-fps 60 --transition-duration 1 >/dev/null 2>&1
                fi
                ;;
        esac
    done
done
