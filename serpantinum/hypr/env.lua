hl.env("NIXOS_OZONE_WL", "1")

-- Cursor theme was set to "ArcMidnight-Cursors" via gsettings (autostart.lua)
-- but that theme doesn't exist anywhere on this system (checked
-- /usr/share/icons, ~/.icons, ~/.local/share/icons, Flatpak exports - not
-- installed at all). GTK apps silently fall back to whatever they can find,
-- while Hyprland's own native/hardware cursor rendering had no theme env set
-- at all, defaulting separately. Different apps landing on different
-- fallbacks is exactly what produces visible shape-changing/flickering as
-- focus moves between windows. Point both at the same real, installed theme.
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
