# hypr-fedora / serpantinum

[ilyamiro](https://github.com/ilyamiro)'s **Serpantinum** shell — a Quickshell-based Hyprland desktop, ported to **Fedora Linux 44** with Hyprland's Lua config (post-0.55).

This is my alternate/experimental setup — my actual daily driver is the `ii`/end-4 setup in the [`ii/`](../ii) folder of this repo.

## What's here

A full Quickshell-based shell: top bar, applauncher, battery, calendar (weather + diary, minus the author's personal school-schedule scraper — see Known limitations), clipboard, focustime (screen-time tracker with a Python daemon), guide, monitors popup, movies, music, network, notifications, quickactions, settings, the author's own "Stewart" voice assistant integration hooks, updater, volume, and a wallpaper picker with online search — all wallpaper-reactive via matugen.

```
hypr/
├── hyprland.lua        # Entry point
├── autostart.lua
├── colors.lua           # Fallback colors; matugen overwrites this at runtime
├── env.lua
├── keybindings.lua
├── monitors.lua          # Adapted to actual hardware (original was hardcoded to author's laptop)
├── rules.lua
├── settings.lua
├── variables.lua
├── hypridle.conf         # Not converted — hypridle doesn't support Lua config; ii's proven-working version reused
├── scripts/               # Original scripts/quickshell tree
└── templates/             # Config-editor templates (settings app), not matugen templates

matugen/
├── config.toml            # Trimmed to templates for apps actually installed (kitty, cava, swayosd, gtk, quickshell, Hyprland)
└── templates/
    └── hyprland-colors.lua.template   # Rewritten for Lua (original targeted the old .conf format)

bin/
└── display-switch          # Windows "Win+P"-style display mode cycler (referenced by keybindings.lua)

wallpaper/                   # ~320 images (417 MB) — drop into ~/Pictures/Wallpapers/ to use with the picker

kitty/
└── kitty.conf                # Original repo's kitty config — the `include /tmp/kitty-matugen-colors.conf`
                               # line is what makes the terminal wallpaper-reactive too
```

## Custom keybinds (ported over from my `ii` setup)

Appended to the end of `keybindings.lua`, on top of everything from the original:

| Keybind | Action |
|---|---|
| `Alt+Space` | Toggle search (same as `Super+D`) |
| `Super+Tab` | Cycle to next workspace |
| `Alt+Tab` / `Alt+Shift+Tab` | Cycle to next/previous open window |
| `Super+Alt+P` | Cycle display mode: Extend → External only → Laptop only → Mirror (`bin/display-switch`) |

None of these conflict with the original bindings — `Tab` wasn't bound to anything in the original, and `Super+Alt+P` was free (`Super+P` isn't bound here either, unlike in `ii`).

## Why this needed real porting work, not just a copy-paste

- **Hyprland config format**: the original repo is `.conf` (hyprlang), which this Hyprland build (0.56.2, Lua-only) rejects outright. Every `.conf` file was hand-converted to the Lua API (`hl.bind`, `hl.config`, `hl.monitor`, `hl.gesture`, `hl.window_rule`, `hl.layer_rule`) preserving the *exact* original behavior — including Firefox/Telegram/Obsidian keybinds, the `us,ru` keyboard layout toggle, and the CS2 window rules.
- **`hyprctl dispatch <name> <args>` no longer works** on this Hyprland build at all — it now expects a Lua expression (`hyprctl eval 'hl.dispatch(...)'`). Fixed in `exit.sh`, `qs_manager.sh`'s workspace-switching fast path.
- **Matugen → Hyprland colors**: the original template generated a `.conf` file sourced live by hyprlang. Lua config isn't hot-sourced, so this needed: (1) rewriting the template to emit a Lua table instead of `$var = ...` lines, targeting `colors.lua` instead of `colors.conf`, and (2) adding an explicit `hyprctl reload` to `matugen_reload.sh` so the new colors actually take effect after a wallpaper change.
- **`awww` → `swww`**: not actually needed here — that rename only happens inside `imperative-dots`' own `install.sh` (a `sed` pass, to dodge an Arch package name conflict). The original repo already uses plain `swww` natively.
- **Hardcoded paths**: the only hardcoded path in the original is the author's own `/home/ilyamiro` in the schedule scraper (see below), left as-is since it's not fixable without his Firefox profile anyway.
- **`swaync-client -rs` hung forever** in `matugen_reload.sh`, silently stalling *every single wallpaper change* — the script only checked that the `swaync-client` binary exists, not that the `swaync` notification daemon is actually running. On a system without swaync running, the client waits indefinitely for a D-Bus connection that never comes. Fixed to check `pgrep -x swaync` first, plus a `timeout 2` as a safety net regardless. Rapidly clicking through wallpapers before this fix could queue up dozens of permanently-hung processes.
- **Whole-theme matching required app-level dotfiles we hadn't ported yet.** The original repo's `config/programs/` directory (kitty, cava, swayosd, rofi, zsh, neovim — all separate from `config/sessions/hyprland/`, which is all we'd ported) contains the actual application configs that reference the matugen-generated files. Two concrete gaps found and fixed:
  - `~/.config/kitty/kitty.conf` was still **`ii`'s old config** — kitty config lives outside `~/.config/hypr/`, so swapping the Hyprland config never touched it. It had zero connection to this setup's matugen pipeline. Replaced with the original repo's `kitty.conf` (`kitty/kitty.conf` in this repo), which has `include /tmp/kitty-matugen-colors.conf`.
  - `swayosd-server` (the GTK process that actually renders volume/brightness/capslock OSDs and reads the matugen-themed CSS) was never running — only `swayosd-libinput-backend` has a systemd unit; the two are separate binaries with separate roles. Added `swayosd-server` to `autostart.lua`.
  - The Quickshell bar/popups' colors (`qs_colors.json` → `MatugenColors.qml`, self-polling every second) were structurally fine the whole time — this was never actually broken, just easy to miss when kitty (the most visible/used app) was silently stuck on someone else's stale theme.

## Known limitations

- **Calendar's school-schedule feature is non-functional** — `scripts/quickshell/calendar/schedule/get_schedule.py` reads from `/home/ilyamiro/.mozilla/firefox/schedule.special`, a personal Firefox profile scraping setup specific to the author. Rest of the calendar (weather, diary) works fine.
- **`settings_watcher.sh` was missing from the published upstream repo** despite being referenced by `autostart.lua`. Rebuilt a working equivalent rather than leaving the autostart line broken.
- **Monitor drag-and-drop popup (`MonitorPopup.qml`) and part of `Config.qml`'s settings-apply path still use the old `hyprctl --batch 'dispatch ...'` string-building approach** — not yet ported to the new Lua eval syntax. The core shell, keybinds, and matugen theming all work; this specific GUI monitor-arrangement feature does not.
- **Firefox/Telegram/Obsidian keybinds** (`Super+F/T/O`) assume those apps are installed — they weren't tested/installed on this machine.

## Notes on this port

- `monitors.lua`: adapted to actual hardware. Original hardcoded `eDP-1 @144Hz`; this machine's panel doesn't have that exact mode, so it uses `preferred` instead, plus an explicit `HDMI-A-1` entry and a wildcard fallback for any other monitor.
- `hypridle.conf` is **not** part of this port — hypridle doesn't support Lua config at all (confirmed via `hypridle --help`), so the proven-working config from [`ii/`](../ii) is reused unchanged.

## Dependencies (Fedora)

Already covered by a typical `ii`/dots-hyprland install: `quickshell`, `hypridle`, `kitty`, `matugen`, `ffmpeg`, `imagemagick`, `playerctld`, `cliphist`, `nautilus`, `mpvpaper`.

Additional, from the `sdegler/hyprland` COPR (already enabled if you have `ii` installed): `swww`, `hyprpolkitagent`, `cava`, `zbar`, `power-profiles-daemon`.

From the `erikreider/swayosd` COPR:
```
sudo curl -sL -o /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:erikreider:swayosd.repo https://copr.fedorainfracloud.org/coprs/erikreider/swayosd/repo/fedora-$(rpm -E %fedora)/erikreider-swayosd-fedora-$(rpm -E %fedora).repo
sudo dnf install -y swayosd
sudo systemctl enable --now swayosd-libinput-backend.service
```

Plain Fedora repo: `pamixer`, `inotify-tools` (for `inotifywait`).

## Install

No automated installer for this one (yet) — it's an experimental alternate setup, not the daily-driver config. Manually:

1. Install the dependencies above.
2. Back up your current `~/.config/hypr`, `~/.config/matugen`, and `~/.config/kitty`.
3. Copy `hypr/` → `~/.config/hypr/`, `matugen/` → `~/.config/matugen/`, `kitty/kitty.conf` → `~/.config/kitty/kitty.conf`, `bin/display-switch` → `~/.local/bin/display-switch` (`chmod +x` it).
4. `hyprctl reload`.

To go back to `ii`: restore your backup, or follow [`ii/install.sh`](../ii/install.sh).
