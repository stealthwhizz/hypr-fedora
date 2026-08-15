#!/usr/bin/env bash

# Reload Hyprland's border colors (colors.lua). Unlike the old hyprlang `.conf`
# format, Lua config files aren't hot-sourced — need an explicit reload.
hyprctl reload >/dev/null 2>&1

# Reload Kitty instances
killall -USR1 .kitty-wrapped


# Reload CAVA
if pgrep -x "cava" > /dev/null; then
    # Rebuild the final config file from the base and newly generated colors
    cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null
    # Tell CAVA to reload the config
    killall -USR1 cava
fi

# Reload SwayNC CSS styling dynamically without killing the daemon.
# Check the daemon is actually running (not just that the client binary exists) —
# swaync-client hangs indefinitely ("Will wait for connection...") if the daemon
# isn't up, which silently stalled every wallpaper change forever.
if pgrep -x swaync > /dev/null; then
    timeout 2 swaync-client -rs
fi

# Restarting swayosd.service is currently the ONLY way to reload its CSS.
# WARNING: This is what causes the sound problems. Because swayosd-server 
# forcefully reconnects to an audio server on boot, restarting it causes audio drops/pops.
if systemctl --user is-active --quiet swayosd.service; then
    systemctl --user restart swayosd.service &
fi

# ==============================================================================
# GTK Live-Reload Hack
# Rapidly toggles the global theme to force GTK3 and GTK4 apps to flush 
# their caches and read the newly generated Matugen CSS.
# ==============================================================================
if command -v gsettings &> /dev/null; then
    # GTK3 apps
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    sleep 0.05
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    
    # GTK4 / Libadwaita apps
    gsettings set org.gnome.desktop.interface color-scheme 'default'
    sleep 0.05
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi

wait
