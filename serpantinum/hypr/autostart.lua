hl.on("hyprland.start", function()
    hl.exec_cmd("swww-daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("playerctld")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("systemctl --user enable --now easyeffects")
    -- swayosd-server (the OSD popup renderer) has no autostart mechanism of its
    -- own on this system — only swayosd-libinput-backend is a system service.
    -- Without this, volume/brightness/capslock OSDs never appear, and its
    -- matugen-generated CSS theme never gets applied.
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("~/.config/hypr/scripts/settings_watcher.sh &")
    hl.exec_cmd("~/.config/hypr/scripts/volume_listener.sh")
    -- swww defaults a newly-connected monitor to solid black until told
    -- otherwise — without this, every future external-monitor connection
    -- shows a blank screen until manually fixed. See serpantinum README.
    hl.exec_cmd("bash ~/.config/hypr/scripts/monitor_watcher.sh &")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'ArcMidnight-Cursors'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
    hl.exec_cmd("quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml")
    hl.exec_cmd("python3 ~/.config/hypr/scripts/quickshell/focustime/focus_daemon.py &")
end)
