-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

hl.bind("ALT + Space", hl.dsp.global("quickshell:searchToggleRelease"), { description = "Shell: Toggle search (custom)" })

hl.unbind("SUPER + Tab")
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "r+1" }), { description = "Workspace: Cycle to next screen (custom)" })

hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "Window: Cycle to next app (custom)" })
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ prev = true }), { description = "Window: Cycle to previous app (custom)" })

hl.bind("SUPER + ALT + P", hl.dsp.exec_cmd("$HOME/.local/bin/display-switch"),
    { description = "Display: Cycle mode (extend/external/internal/mirror) (custom)" })

-- Drop kitty's -1 (single-instance) flag: it makes new terminals open via IPC to the
-- first kitty process instead of spawning independently, so Hyprland can't reliably
-- place the new window on the currently active workspace.
local terminalNoSingleInstance = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'foot' 'kitty' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
hl.unbind("SUPER + Return")
hl.unbind("SUPER + T")
hl.unbind("CTRL + ALT + T")
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminalNoSingleInstance), { description = "App: Terminal (custom)" })
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminalNoSingleInstance))
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd(terminalNoSingleInstance))
