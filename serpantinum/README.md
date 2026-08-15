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
| `Super+Z` | Minimize the focused app |
| `Super+Shift+Z` | Show/hide minimized apps |
| `Super+Comma` | Minimize everything on the current workspace (show desktop) — `hypr/scripts/minimize_all.sh` |

Hyprland has no native minimize (tiling WM — windows are only tiled/floating/fullscreen, never minimized). These fake it with a hidden special workspace, the standard Hyprland scratchpad trick. `minimize_all.sh` targets a *specific* window by address (`window = "address:0x..."` — the `address:` prefix is required, silently no-ops without it) rather than only the focused one, since the built-in dispatchers otherwise only affect whichever window has focus.

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
- **Screenshots were completely non-functional** — `screenshot.sh` had a hard dependency check for ALL of `gpu-screen-recorder grim satty wl-copy pactl quickshell zbarimg python3` at the top of the script, before any argument parsing, and exited immediately if even one was missing. Neither `gpu-screen-recorder` nor `satty` were installed, so every screenshot keybind (`Print`, `Shift+Print`, `Super+Print`, `Super+Shift+Print`) silently failed with just a "missing dependencies" notification. Fixed: moved the dependency check to after argument parsing, and made `gpu-screen-recorder` conditional on `--record` mode only — plain screenshots and edit mode don't touch the recorder at all and shouldn't be blocked by it. `gpu-screen-recorder` itself was left uninstalled (its only working Fedora COPR, `brycensranch/gpu-screen-recorder-git`, has zero successful builds across all sub-packages — dead), so `--record` still won't work, but that was never asked for. Installed the real missing piece, `satty` (available from the already-enabled `sdegler/hyprland` COPR: `sudo dnf install -y satty`). Verified live: `screenshot.sh --full` produces a real screenshot (confirmed 1920x1080 PNG) and copies it to the clipboard (`image/png` present in `wl-paste --list-types`); `screenshot.sh --full --edit` launches `satty` as a real mapped Hyprland window (`com.gabm.satty`, confirmed via `hyprctl clients`) for annotation before saving/copying.
- **Colors didn't visually match the wallpaper's actual dominant color** — the picker's three `matugen image ...` calls (`WallpaperPicker.qml`) passed no color-selection flags at all. Matugen's default (`scheme-tonal-spot`, picks by raw pixel-frequency) can pick a color that's technically the most common pixel but reads as visually wrong — tested on a sunset lake photo: default picked a muted **purple** (`#6C538C`, almost certainly from shadow/sky pixels), when the obviously "correct" color a person would pick is the sunset's **orange**. Added `--prefer saturation --type scheme-vibrant` to all three call sites, which picks the most saturated/vivid color present instead of the most numerous one — confirmed on the same photo: now produces vivid orange (`#8D4F00` / `#FFB877`), applied and verified live (Hyprland border color actually changed to match).

- **Applauncher search couldn't actually open apps** — `appLauncher.qml`'s `launchApp()` used `Quickshell.execDetached(["hyprctl", "dispatch", "exec", "--", execStr])`, the same old hyprlang dispatch syntax this Hyprland build rejects everywhere else (see `hyprctl dispatch` note above). Every app click in the search UI silently failed — the launcher itself opened fine, it was only the launch action that was broken. Fixed by spawning the exec string directly (`Quickshell.execDetached(["bash", "-c", execStr])`), bypassing Hyprland's dispatcher entirely rather than routing through `hyprctl eval` — simpler, and `.desktop` `Exec=` lines already have their `%f`/`%u` placeholders stripped by `app_fetcher.py` so they're safe to hand straight to a shell. Verified live: launcher opens (`qs-floating-overlay` layer appears), and the fixed launch path was tested directly (spawned firefox via the same `bash -c` mechanism, confirmed as a mapped Hyprland client).

## Known limitations

- **Calendar's school-schedule feature is non-functional** — `scripts/quickshell/calendar/schedule/get_schedule.py` reads from `/home/ilyamiro/.mozilla/firefox/schedule.special`, a personal Firefox profile scraping setup specific to the author. Rest of the calendar (weather, diary) works fine.
- **`settings_watcher.sh` was missing from the published upstream repo** despite being referenced by `autostart.lua`. Rebuilt a working equivalent rather than leaving the autostart line broken.
- **Monitor drag-and-drop popup (`MonitorPopup.qml`) and part of `Config.qml`'s settings-apply path still use the old `hyprctl --batch 'dispatch ...'` string-building approach** — not yet ported to the new Lua eval syntax. The core shell, keybinds, and matugen theming all work; this specific GUI monitor-arrangement feature does not.
- **Firefox/Telegram/Obsidian keybinds** (`Super+F/T/O`) assume those apps are installed — they weren't tested/installed on this machine.
- **Settings app's dynamic keybind editor** (`SettingsPopup.qml`) still uses `["hyprctl", "dispatch", ...]` in a few places (submap reset/passthru, custom dispatcher assignment) — same broken syntax as the applauncher bug above, not yet ported to `hyprctl eval`. Not fixed since it's a separate, unused feature (in-app keybind rebinding UI), not the actual keybindings system.

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
