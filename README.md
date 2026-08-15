# hypr-fedora

My personal Hyprland configuration on **Fedora Linux 44**, running Hyprland's newer **Lua-based config** (post-0.55). This repo is a snapshot of `~/.config/hypr`, plus one companion script referenced by the keybinds.

Built on top of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) ("illogical-impulse" / `ii`) for the actual desktop shell (bar, launcher, sidebar, lockscreen UI, etc. — that lives in `~/.config/quickshell/ii`, not duplicated here). This repo covers the Hyprland compositor config layer specifically: window management, keybinds, monitor handling, idle/lock behavior, and my own customizations/fixes on top of the base.

## Versions this was built against

- Fedora Linux 44
- Hyprland 0.56.2 (Lua config)
- Quickshell 0.2.1 (git)
- Matugen 4.1.0

## Layout

```
hypr/
├── hyprland.lua          # Entry point — sources hyprland/* then custom/*
├── hyprland/              # Base config from end-4/dots-hyprland (defaults)
│   ├── env.lua
│   ├── execs.lua
│   ├── general.lua        # Patched: disabled 4-finger swipe overview gesture (crash workaround, see below)
│   ├── keybinds.lua
│   ├── rules.lua
│   ├── variables.lua
│   ├── lib/init.lua
│   ├── scripts/
│   ├── services/
│   └── shellOverrides/
├── custom/                 # My own overrides — loaded after hyprland/*, never touched by upstream updates
│   ├── keybinds.lua         # See "Custom keybinds" below
│   ├── env.lua
│   ├── execs.lua
│   ├── general.lua
│   ├── rules.lua
│   └── variables.lua
├── hypridle.conf           # Idle daemon config — lock_cmd fixed to call hyprlock directly
├── hyprlock.conf           # Lock screen appearance
├── hyprlock/
│   ├── check-capslock.sh
│   └── status.sh
├── monitors.conf           # nwg-displays managed (currently empty/auto)
└── workspaces.conf         # nwg-displays managed

bin/
└── display-switch          # Windows "Win+P"-style display mode cycler (referenced by custom/keybinds.lua)
```

## Custom keybinds (`custom/keybinds.lua`)

| Keybind | Action |
|---|---|
| `Alt+Space` | Toggle search |
| `Super+Tab` | Cycle to next workspace |
| `Alt+Tab` / `Alt+Shift+Tab` | Cycle to next/previous open window |
| `Super+Alt+P` | Cycle display mode: Extend → External only → Laptop only → Mirror (`bin/display-switch`) |
| `Super+Return` / `Super+T` / `Ctrl+Alt+T` | Open terminal (kitty, single-instance flag removed — see below) |

## Notable fixes/decisions baked into this config

- **Lua config migration**: this setup runs on a Hyprland build that dropped the legacy `hyprlang` `.conf` format (deprecated at 0.55, removed a couple releases later). Everything here uses the native Lua config API (`hl.bind`, `hl.monitor`, `hl.dispatch`, etc.), not the old `bind = ...` syntax.
- **Lock screen**: `hypridle.conf`'s `lock_cmd` was originally set to try a Quickshell-based lock UI first with a fallback to `hyprlock` that could never actually trigger (the fallback check always found a running `qs` process and skipped it). Changed to call `hyprlock` directly and unconditionally.
- **Terminal single-instance bug**: the default terminal launcher used `kitty -1` (single-instance mode). New terminal windows opened via IPC to the first kitty process instead of spawning independently, so Hyprland couldn't reliably place them on the currently active workspace. Dropped the `-1` flag in `custom/keybinds.lua`.
- **Overview gesture disabled**: the 4-finger swipe up/down gesture (opens Quickshell's workspace overview with live window screencasts) reliably segfaults Quickshell on this GPU/driver combination while rendering the window preview texture. Commented out in `hyprland/general.lua` — this is normally a default file that gets overwritten on updates, so re-check after any `dots-hyprland` update.
- **Multi-monitor**: laptop panel (`eDP-1`) + external monitor (`HDMI-A-1`). After any monitor mode change (disable/enable/mirror), Quickshell can fail to re-create its bar/background layers on a monitor until it receives a fresh hotplug event — a one-time reactivity quirk, not something fixed in config.

## Install

1. Install [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) first (`main` branch, for the Lua config support) — this provides Quickshell, the `ii` shell, and the base `hyprland/` files this config layers on top of.
2. Copy `hypr/custom/*` and `hypr/hypridle.conf`/`hypr/hyprlock.conf`/`hypr/hyprlock/*` into your `~/.config/hypr/`.
3. Copy `bin/display-switch` to `~/.local/bin/` and `chmod +x` it.
4. `hyprctl reload`.
