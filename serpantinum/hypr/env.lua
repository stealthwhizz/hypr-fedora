hl.env("NIXOS_OZONE_WL", "1")

-- Hyprland is launched directly by GDM, not through a login shell that
-- sources .bashrc, so ~/.local/bin was never on its PATH at all - anything
-- Quickshell spawns via execDetached() (a direct PATH-based exec, not a
-- shell) with just a bare command name (e.g. "powerprofilesctl") silently
-- fails to find user-local scripts/binaries there. Confirmed by reading
-- /proc/<hyprland-pid>/environ directly: PATH was just
-- /usr/local/bin:/usr/bin:/var/lib/snapd/snap/bin, no ~/.local/bin at all.
-- Only takes effect on a fresh Hyprland session, not `hyprctl reload`.
hl.env("PATH", "$HOME/.local/bin:$HOME/bin:$PATH")

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
