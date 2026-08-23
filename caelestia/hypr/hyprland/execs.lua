local vars = require("variables")
local fn   = require("utils.functions")

hl.on("hyprland.start", function()
    -- Keyring: upstream just starts a bare secrets-only daemon, which doesn't
    -- work on this system - see keyring_init.sh for why and what it does
    -- instead (ported from the serpantinum port, same bug, same fix).
    hl.exec_cmd("bash ~/.config/hypr/scripts/keyring_init.sh")
    -- Upstream's polkit-gnome agent doesn't exist on Fedora at all (confirmed:
    -- no package ships /usr/lib/polkit-gnome anywhere). Using hyprpolkitagent
    -- instead (systemd user service, enabled by install.sh) rather than a raw
    -- exec_cmd line here, matching the serpantinum port's proven approach.

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Auto delete trash 30 days old
    hl.exec_cmd("trash-empty 30")

    -- Cursors
    hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme " .. vars.cursorTheme)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. vars.cursorSize)

    -- Location provider and night light. Fedora's geoclue2 package installs
    -- to /usr/libexec, not /usr/lib like upstream's Arch path assumes.
    hl.exec_cmd("/usr/libexec/geoclue-2.0/demos/agent")
    hl.exec_cmd("sleep 1 && gammastep")

    -- Forward bluetooth media commands to MPRIS
    hl.exec_cmd("mpris-proxy")

    -- Start shell
    hl.exec_cmd("caelestia shell -d")
end)

-- Resizer listeners
local function apply_resizer_rules(win)
    local float_center = {
        hl.dsp.window.float({ action = "on", window = win }),
        hl.dsp.window.center({ window = win }),
    }
    local pip_actions = fn.move_actions(win) or {}

    -- Bitwarden
    fn.resizer(win, "Bitwarden", 20, 54, float_center, true, "class")                                       -- Native app
    fn.resizer(win, "^Extension: %(Bitwarden Password Manager%) %- Bitwarden", 20, 54, float_center, false) -- Firefox
    fn.resizer(win, "nngceckbapebfimnlniiiahkandclblb", 20, 54, float_center, true, "class")                -- Chromium

    -- Picture in picture
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip_actions, false)
end

hl.on("window.title", apply_resizer_rules)
hl.on("window.open", apply_resizer_rules)
