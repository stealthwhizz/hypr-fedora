local vars     = require("variables")
local mainMod  = vars.mainMod
local terminal = vars.terminal

-- ───────── Mouse & Gestures ─────────
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ───────── Window Management ─────────
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -50, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })

hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "d" }))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))

-- ───────── System & Hardware ─────────
hl.bind("Caps_Lock", hl.dsp.exec_cmd("sleep 0.1 && swayosd-client --caps-lock"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true })

hl.bind("Print",                       hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"),               { locked = true })
hl.bind("SHIFT + Print",               hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --edit"),         { locked = true })
hl.bind(mainMod .. " + Print",         hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --full"),        { locked = true })
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --full --edit"), { locked = true })

hl.bind("XF86PowerOff",   hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/lock.sh"), { locked = true })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/lock.sh"), { locked = true, repeating = true })

-- ───────── Media & Audio ─────────
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),  { locked = true })
hl.bind("XF86AudioMute",    hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })

-- ───────── Applications & Launchers ─────────
hl.bind(mainMod .. " + F",      hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd("Telegram"))
hl.bind(mainMod .. " + O",      hl.dsp.exec_cmd("obsidian"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))

-- ───────── Quickshell Controls ─────────
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle monitors"))
hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/reload.sh"))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh toggle applauncher"))
hl.bind(mainMod .. " + C",      hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh toggle clipboard"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle settings"))
hl.bind(mainMod .. " + Q",      hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle music"))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle battery"))
hl.bind(mainMod .. " + W",      hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper"))
hl.bind(mainMod .. " + S",      hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle calendar"))
hl.bind(mainMod .. " + N",      hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle network"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle focustime"))
hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle volume"))
hl.bind(mainMod .. " + H",      hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle guide"))

-- ───────── Workspaces 1-9, 0 ─────────
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh " .. i))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh " .. i .. " move"))
end

-- ───────── Custom additions (ported from my ii setup) ─────────
hl.bind("ALT + Space", hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh toggle applauncher"), { description = "Shell: Toggle search" })
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "r+1" }), { description = "Workspace: Cycle to next screen" })
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "Window: Cycle to next app" })
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ prev = true }), { description = "Window: Cycle to previous app" })
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("$HOME/.local/bin/display-switch"),
    { description = "Display: Cycle mode (extend/external/internal/mirror)" })
