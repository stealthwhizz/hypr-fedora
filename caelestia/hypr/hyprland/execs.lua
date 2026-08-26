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

    -- Icon theme: upstream never sets this at all, and nothing else on this
    -- system does either. Without it, icons resolved by name (not an app's
    -- own bundled icon) fail to load - seen live for both system-tray icons
    -- (Discover/PackageKit's update-checker) and launcher action items
    -- (preferences-system, tools-report-bug, etc, all rendering as Qt's
    -- generic broken-icon placeholder every time the launcher opened).
    --
    -- gsettings alone (org.gnome.desktop.interface icon-theme) does NOT
    -- control this for this shell - confirmed live, changing it had zero
    -- effect. The real control point is kdeglobals' [Icons] Theme= key,
    -- read by KDEPlasmaPlatformTheme6 (the actual active Qt platform theme -
    -- QT_QPA_PLATFORMTHEME is set to "qtengine" below, which doesn't exist
    -- as an installed plugin at all, so Qt silently falls back to this one).
    --
    -- Plain "breeze" alone isn't enough either: several action icons only
    -- exist in breeze-dark or AdwaitaLegacy, and breeze's own Inherits=
    -- chain is just "hicolor" (near-empty) - doesn't pull those in. Using a
    -- small local meta-theme (~/.local/share/icons/breeze-full, seeded by
    -- install.sh from icons/breeze-full/ in this repo) that inherits from
    -- breeze, breeze-dark, Adwaita, AdwaitaLegacy, and hicolor in one chain.
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme breeze-full")
    hl.exec_cmd("kwriteconfig6 --file kdeglobals --group Icons --key Theme breeze-full")

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

-- Note on xwaylandvideobridge (KDE's screen-share helper for X11 apps): it
-- used to auto-close itself here on open, which would have broken screen
-- sharing entirely - it needs to actually keep running for that to work.
-- Under KWin it's specially hidden from view; Hyprland has no such
-- special-casing so it just tiles it like a normal window (looks like a
-- blank terminal you never opened). Fixed properly instead by preventing it
-- from auto-starting in Hyprland sessions specifically at the XDG autostart
-- level (see ~/.config/autostart/org.kde.xwaylandvideobridge.desktop,
-- NotShowIn=Hyprland - Plasma sessions are untouched, still autostart it
-- normally there). If you ever start it manually while in Hyprland for
-- screen-sharing, it now behaves as a completely normal window - closes on
-- Super+Q like anything else, no special handling here at all.
