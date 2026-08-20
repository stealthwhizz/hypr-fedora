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

## All keybinds

Full reference, `keybindings.lua` — everything from the original repo plus the custom additions below.

**Window management**

| Keybind | Action |
|---|---|
| `Super+Shift+←/→/↑/↓` | Resize focused window |
| `Super+Ctrl+←/→/↑/↓` | Swap focused window in that direction |
| `Super+←/→/↑/↓` | Move focus in that direction |
| `Super+Q` | Close focused window (matches `ii`; moved off `Alt+F4`, which is now unbound) |

**System & hardware**

| Keybind | Action |
|---|---|
| `Caps_Lock` | Caps-lock OSD (swayosd) |
| `XF86MonBrightnessDown/Up` | Brightness OSD |
| `Print` | Screenshot: region select overlay |
| `Shift+Print` | Screenshot: region select, then edit in satty |
| `Super+Print` | Screenshot: instant full screen |
| `Super+Shift+Print` | Screenshot: instant full screen, then edit in satty |
| `Super+Shift+S` | Screenshot: region select (same as `Print`, matches ii's own Shift+S convention) |
| `XF86PowerOff` | Lock screen |
| `Super+L` | Lock screen |

**Media & audio**

| Keybind | Action |
|---|---|
| `Super+Space` / `XF86AudioPlay` / `XF86AudioPause` | Play/pause |
| `XF86AudioMicMute` | Mute mic |
| `XF86AudioMute` | Mute output |
| `XF86AudioLowerVolume` / `XF86AudioRaiseVolume` | Volume down/up |

**Applications & launchers**

| Keybind | Action |
|---|---|
| `Super+F` | Firefox |
| `Super+E` | Nautilus (file manager) |
| `Super+Alt+T` | Telegram (moved off `Super+T` — see terminal below) |
| `Super+O` | Obsidian |
| `Super+D` | Discord (Flatpak — `flatpak run com.discordapp.Discord`) |
| `Super+T` | Terminal (kitty) |
| `Ctrl+Alt+T` | Terminal (`ptyxis` — Fedora's default GNOME terminal, deliberately a *different* terminal app than `Super+T`, not a duplicate of it) |
| `Super+I` | System Settings (`gnome-control-center`, real GNOME Settings — not the shell's own settings panel). It refuses to launch outside a GNOME/Unity session by default (checks `XDG_CURRENT_DESKTOP` and exits immediately), so the bind overrides that env var for just this one launch: `XDG_CURRENT_DESKTOP=GNOME gnome-control-center`. |
| `Super+Shift+I` | The shell's own Quickshell settings panel (wallpaper dir, UI scale, weather config, the Keybinds reference tab itself, etc.) — gave this back a keybind since `Super+I` and `Super+Shift+S` were both reassigned away from it. |

**Quickshell panels** (all `Super+<key>`, toggle open/close)

| Keybind | Panel | Keybind | Panel |
|---|---|---|---|
| `M` | Music (matches `ii`) | `S` | Calendar |
| `Alt+M` | Monitors (moved off `Super+M` to make room for music) | `N` | Network |
| `R` | Reload shell | `Shift+T` | Focustime |
| `C` | Clipboard | `V` | Volume |
| — | (the shell's own settings panel has no dedicated key right now — `Super+I` was reassigned to real System Settings, see above) | `H` | Guide |
| `B` | Battery/power | `W` | Wallpaper picker |

`Super+D` used to duplicate `Alt+Space` for search (dropped, kept only `Alt+Space`) — now reassigned to Discord, see Applications above.

**Workspaces**

| Keybind | Action |
|---|---|
| `Super+1..9,0` | Switch to workspace 1–10 |
| `Super+Shift+1..9,0` | Move focused window to workspace 1–10 |

**Custom additions** (ported over from my `ii` setup, appended to the end of `keybindings.lua`)

| Keybind | Action |
|---|---|
| `Alt+Space` | Toggle search (the only key for this now — `Super+D` was dropped, see above) |
| `Super+Tab` | Cycle to next workspace |
| `Super+Shift+Tab` | Back to previous workspace — a true toggle (Hyprland's `workspace = "previous"` target), not "go down one number". Verified live: flips back and forth between the last two active workspaces. |
| `Alt+Tab` / `Alt+Shift+Tab` | Cycle to next/previous open window |
| `Super+Alt+P` | Cycle display mode: Extend → External only → Laptop only → Mirror (`bin/display-switch`) |
| `Super+Z` | Minimize the focused app |
| `Super+Shift+Z` | Show/hide minimized apps |
| `Super+Comma` | Minimize everything on the current workspace (show desktop) — `hypr/scripts/minimize_all.sh` |

**Note on the power buttons** (`Super+B` → lock/suspend/reboot/poweroff): these are **hold-to-confirm**, not single-click — press and hold until the button's fill animation completes (lock/suspend ≈0.55s, reboot ≈1.4s, poweroff ≈1.9s) and flashes. A quick click drains the fill back to empty and does nothing, by design (accidental-poweroff protection). Verified polkit authorizes all three actions for this user with no auth-agent prompt needed, so a normal hold works with no further setup.

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

- **Battery health readout added** (ported from a feature originally added on the `ii` setup). The battery popup (`Super+B`) only showed live charge %/status, no wear/health info. `sysPoller`'s data-fetching one-liner now also reads `charge_full`/`charge_full_design` from `/sys/class/power_supply/BAT*` (falls back to `energy_full`/`energy_full_design` if the driver only exposes those), computes `(full / full_design) * 100`, and displays it as `HEALTH XX%` under the status text in the central battery ring. RAM usage needed no porting — it was already present and working in this setup's Quick Actions panel (`scripts/quickshell/watchers/sys_fetcher.sh` computes CPU%, RAM% + RAM GB, temperature, and network throughput; displayed by `quickactions/SystemUsage.qml`), just easy to miss since it's a different popup than battery.

- **Weather now auto-detects location** — the original `weather.sh` required a manually-looked-up `OPENWEATHER_CITY_ID` in `.env`. Replaced with IP-based geolocation: a `get_location()` function calls `ipinfo.io/json` (free, keyless, HTTPS) for lat/lon, caches it for 24h (a desktop's location rarely changes, and this avoids hammering the geolocation service on every 15-minute weather refresh), and falls back to the last-known cached location if the lookup fails (offline, rate-limited). Both OpenWeatherMap API calls switched from `id=${ID}` to `lat=${LAT}&lon=${LON}`. Verified live: resolves to real coordinates end-to-end, cache read/write confirmed. **Setup still needs one thing from you**: a free `OPENWEATHER_KEY` in `scripts/quickshell/calendar/.env` (sign up at openweathermap.org/api, free tier: 60 calls/min, 1M/month — this widget uses a tiny fraction of that). Without a key, weather silently shows dummy data (`0.0°`, "No API Key") rather than breaking — this was already true of the original, just easy to miss since there's no error shown anywhere in the UI. `.env` is gitignored, never committed.

- **Screenshot widget added to the top bar** — there was no way to trigger a screenshot without a physical `Print` key press. Added a camera icon (`TopBar.qml`, in the same icon row as guide/search/settings/updater, between search and settings) that runs `screenshot.sh` (region-select) on click, reusing the same glyph (`󰄄`) the screenshot overlay itself uses for its photo-mode toggle. Verified live: click path (`Quickshell.execDetached` → `screenshot.sh`) launches the real overlay as a `qs-screenshot-overlay` layer, confirmed via `hyprctl layers`.
- **Settings → Keybinds tab was empty** — this is a separate, self-contained keybind reference/editor built into the Settings popup (`SettingsPopup.qml`'s "Keybinds" tab, backed by `Config.qml`'s `keybindsData`), decoupled from the actual Hyprland `keybindings.lua` — it reads from `settings.json`'s `"keybinds"` array, which had 0 entries, so the tab showed nothing. Populated it with all 75 real bindings from `keybindings.lua` (window management, screenshots, media, launchers, all 11 quickshell panel toggles, all 20 workspace binds, and the custom ii-ported additions), in the schema `Config.qml` expects (`type`/`mods`/`key`/`dispatcher`/`command`). Note: this tab is a reference/editor, not the live keybind source — editing and saving here writes back to `settings.json` only, it does **not** change `keybindings.lua` or take effect in Hyprland itself. `settings.json` is now tracked in this repo as a seed default (also contains your `wallpaperDir`, `uiScale`, and other app-level Settings-panel state).

- **Top bar icon row (help/search/screenshot/settings/updater) could get permanently stuck hidden** — real bug, found while testing the screenshot widget above. That row is deliberately hidden while the Settings popup is open (`TopBar.qml`'s `isSettingsOpen`, read from a `current_widget` file on disk that `Main.qml` writes reactively via `onCurrentActiveChanged`). Problem: QML doesn't fire that signal for a property's *initial default value* — so if `Quickshell.reload(true)` (triggered by `Super+R`, or any script that edits shell config and reloads) happens while a widget was still open or mid-close-animation, the live `currentActive` correctly resets to `"hidden"` on the fresh load, but the on-disk file never gets told, since no "change" fires from a fresh default. The file is left stuck on the last widget name forever — even though nothing is actually open — permanently hiding that whole icon row with no visible cause. Fixed: `Main.qml`'s `Component.onCompleted` now force-writes `current_widget` on every load, resyncing it regardless of what it said before. Verified live: manually poisoned the file to `"settings"`, reloaded, confirmed it corrected itself to `"hidden"`.

- **External monitor showed fully blank (no wallpaper, no bar, nothing)** — two separate causes, found by testing with `grim -o HDMI-A-1` (an unrelated Wayland client, useful as a neutral probe) which reported `unknown output 'HDMI-A-1'` even though `hyprctl monitors` showed it perfectly configured (correct EDID, mode, position, `disabled: false`).
  1. **Root cause (compositor-level, not a config bug)**: this machine has hybrid graphics — the laptop panel and the HDMI port are on two different GPUs (Intel/laptop panel vs. the NVIDIA RTX 3060 the HDMI port is routed through). The Hyprland log showed several rapid disable→enable cycles for `HDMI-A-1` during session startup while the NVIDIA GPU's renderer was still initializing, leaving the monitor correctly modeset at the DRM level but never properly announced as a `wl_output` to Wayland clients (Quickshell, swww, and `grim` all failed to see it identically). **Fix: unplug and replug the cable** — forces one clean hotplug event instead of the tangled multi-cycle one from boot. Confirmed live: `grim -o HDMI-A-1` and the Quickshell bar both started working on that output immediately after replugging, no config or script changes needed.
  2. **swww defaults a newly-discovered output to solid black** until explicitly told what to display — a real, permanent gap that would repeat on every future monitor connection, not a one-off. Fixed with a new watcher, `scripts/monitor_watcher.sh`: listens on Hyprland's event socket (`socat` on `.socket2.sock`, same pattern `workspaces.sh` already used) for `monitoraddedv2`, and on any new monitor, applies whatever's currently showing on the existing outputs to it (`swww img -o <name> <path>`). Added to `autostart.lua`. Verified live with `hyprctl output create headless` (a safe virtual monitor, no cable needed) — the wallpaper applied automatically within ~1.5s of the monitor appearing, no manual intervention.

- **Top bar disappearing / keybinds not responding after toggling display mode (`Super+Alt+P`)** — two distinct causes found, one fixed properly, one is a hardware/driver limitation that can only be worked around.
  1. **Real, fixable bug**: `Main.qml` (the single window hosting every widget toggle — search, calendar, network, battery, everything except the per-monitor bar itself) never set an explicit `screen:` property, so Quickshell defaulted it to whichever monitor was primary/first at startup and never re-evaluated. Disabling that monitor (exactly what `display-switch`'s "external only" mode does) orphaned the window on a dead screen — confirmed via the Quickshell log (`Layershell screen does not correspond to a real screen`) and reproduced directly: toggling a widget while a monitor was disabled left it stuck rendered at 1×1 pixels (invisible, unresponsive), confirmed via `hyprctl layers`. Fixed by binding `screen: Quickshell.screens[0]` in `Main.qml` (always points at a currently-live screen, re-evaluates automatically when the monitor set changes) plus having `display-switch` trigger a full Quickshell reload ~2s after any mode change, so any transient binding issues from the switch itself get cleanly resolved rather than lingering. Verified live: before the fix, a widget toggle during a disabled-monitor state rendered at 1×1; after, it rendered at full size, in the exact same state.
  2. **Not fixable from software — hybrid-GPU driver limitation**: this laptop has the laptop panel and the HDMI port on two different GPUs. Reconfiguring a monitor — even purely via `hyprctl eval` from `display-switch`, not just a physical cable event — can leave it stuck at the driver level: Hyprland's own state (`hyprctl monitors`) reports it as enabled and correctly modeset, but the Wayland output itself is never (re-)announced to any client. Confirmed with `grim` (a neutral, unrelated Wayland client) failing identically to Quickshell and swww with `unknown output`. No config or script can force Hyprland to re-announce it — reproduced this by rapidly re-running `display-switch` back-to-back during testing, which is itself part of what `display-switch` now guards against (see below). The only fix is a real hotplug event: **unplug and replug the cable**. Since the failure is otherwise silent (screen just goes blank with no explanation), `display-switch` now probes the target output with `grim` after switching and sends a clear critical notification telling you to replug, instead of leaving you guessing.
  3. **Debounce added**: pressing `Super+Alt+P` a second time while a previous switch is still settling (~2-3s) used to let both `hyprctl eval` calls race, which could itself trigger cause #2 above purely through repeated software toggling. `display-switch` now holds an `flock` lock for its entire switch+settle+verify sequence — a second press during that window is rejected outright with a "Still switching, one moment..." notification instead of racing. Verified live: held the lock manually in a background process and confirmed a concurrent invocation was cleanly rejected without touching monitor state.

- **Keyring prompting for a password / creating a fresh keyring mid-session** — real bug, traced through `journalctl`. PAM (`pam_gnome_keyring.so`, wired into `/etc/pam.d/gdm-password`, confirmed as this session's actual PAM service via `loginctl`) does correctly start and unlock a keyring daemon at login — confirmed via `gkr-pam: gnome-keyring-daemon started properly and unlocked keyring` in the journal. But Hyprland's own process never inherits that daemon's environment variables at all (checked directly: `/proc/<hyprland-pid>/environ` has no `GNOME_KEYRING_CONTROL`/`SSH_AUTH_SOCK`, not just "not propagated to systemd" — genuinely absent). So the first app that asks for secrets over D-Bus later can't find the PAM-unlocked daemon; D-Bus service activation spawns a second, unrelated `gnome-keyring-daemon` from scratch instead, with no knowledge of the login password, forcing an interactive create/unlock prompt — reproduced live: a fresh `login.keyring` got created mid-session purely from testing app launches (Discord, ptyxis), and the resulting daemon threw internal D-Bus assertion errors handling the prompt response on this system's gnome-keyring build. Fixed with `scripts/keyring_init.sh`, run first in `autostart.lua`: explicitly starts/connects to a single daemon with all components (`pkcs11,secrets,ssh`) and publishes its env vars to `systemctl --user import-environment` + `dbus-update-activation-environment`, so every app's D-Bus secret lookup converges on one daemon instead of a second spawning blind. Verified live: restarted with the fix, confirmed `SSH_AUTH_SOCK` now present in `systemctl --user show-environment`, and all three sockets (`control`, `pkcs11`, `ssh`) active on the one daemon. Full effect needs a fresh login (autostart only runs on Hyprland's actual startup, not `hyprctl reload`).

- **Cursor flickering / changing shape, including on the normal desktop** — root cause: `autostart.lua` set the cursor theme to `ArcMidnight-Cursors` via `gsettings`, but that theme isn't installed anywhere on this system at all (checked `/usr/share/icons`, `~/.icons`, `~/.local/share/icons`, Flatpak exports — genuinely absent, only Adwaita/Bibata/Breeze are actually present). Worse, Hyprland's own native/hardware cursor rendering had **no theme env var set at all**, completely independent of the (broken) `gsettings` value GTK apps use. Different apps falling back differently — GTK apps silently retrying/reverting, Hyprland's compositor-level cursor defaulting separately — is exactly what produces visible shape flicker as focus moves between windows. Fixed on both sides to a real, installed theme (`Bibata-Modern-Classic`): `env.lua` now sets `HYPRCURSOR_THEME`/`HYPRCURSOR_SIZE`/`XCURSOR_THEME`/`XCURSOR_SIZE`, and `autostart.lua`'s `gsettings` call points at the same theme. Verified live with `hyprctl setcursor Bibata-Modern-Classic 24` (takes effect immediately, no restart needed) plus the `gsettings` change (immediate for GTK apps); `env.lua`'s vars apply to the compositor itself on next login.
- **No PolicyKit authentication agent running at all** — surfaced as `Cannot request authentication for this action... PolicyKit authentication system appears to be not available` (e.g. udisks2 refusing to mount an NTFS/Windows partition, since user-mount is polkit-gated). `hyprpolkitagent` was installed (from the already-enabled `sdegler/hyprland` COPR) but never started anywhere — autostart.lua never referenced it, and there's no XDG-autostart processing to fall back on outside a full DE. Fixed: enabled its systemd user service (`systemctl --user enable --now hyprpolkitagent`, matching the existing `easyeffects` pattern in `autostart.lua` rather than a raw `exec_cmd`). Verified live: mounted both of this machine's NTFS partitions via `udisksctl mount` with zero errors immediately after starting the agent (confirmed real Windows files visible on the main partition) — same command failed with the PolicyKit error before.
- **Calendar's schedule strip rebuilt to pull from Google Calendar via `gcalcli`** — the original feature (`scripts/quickshell/calendar/schedule/get_schedule.py`) scraped a Danish school timetable site via Selenium, tied to the original author's own Firefox profile (`/home/ilyamiro/.mozilla/firefox/schedule.special`) and invoked through `nix-shell` (`schedule_manager.sh`) — which isn't even installed on this system, so this was never going to work here at all, not just a wrong-profile issue. Rewrote `get_schedule.py` from scratch: shells out to [gcalcli](https://github.com/insanum/gcalcli) and renders its output into the *exact same JSON shape* the QML UI already expects, so `CalendarPopup.qml` needed zero changes. Chose `gcalcli` over a plain private-iCal-URL fetch (an earlier, simpler version of this fix used that instead) because it authenticates once via OAuth against the whole Google account and then sees every calendar automatically — no per-calendar secret URL to find and list, which matters since this account has several calendars. Uses `gcalcli agenda today tomorrow --details location --tsv`, not `--json` — `--json` only exists on gcalcli's unreleased GitHub main branch; the actual installed version (4.5.1, from PyPI via `pipx`) only has `--tsv`, found by checking the real installed version's `--help` rather than assuming the GitHub docs matched. The header row is parsed dynamically (column name → index) instead of hardcoding positions, so a different gcalcli version's column order won't silently break it. All-day events are deliberately skipped (empty `start_time`/`end_time` in gcalcli's output): the UI is a fixed horizontal timeline (originally shaped for an 8:30–15:40 school day, kept as a 07:00–22:00 waking-hours window here) that a full-day event doesn't fit visually. `schedule_manager.sh` simplified to a plain `python3` call, dropping the dead `nix-shell`/`shell.nix` dependency entirely. Verified in stages: a fake `gcalcli` binary on `PATH` reproducing the real TSV shape (two timed events parsed correctly, the all-day one skipped, gaps computed correctly), the "gcalcli not installed" fallback, and finally a real end-to-end run against the actual authenticated Google account (correctly returned "No events today" for a genuinely empty agenda) — with the calendar popup confirmed rendering cleanly the whole way (via `hyprctl layers`, no 1×1 stuck-render or crash). **One-time setup, done** — `gcalcli` installed via `pipx`, OAuth client created on an existing Google Cloud project, `init` completed and authenticated live during this session:
  for a fresh install elsewhere: `sudo dnf install -y pipx && pipx ensurepath && pipx install gcalcli`, then follow [gcalcli's OAuth setup guide](https://github.com/insanum/gcalcli/blob/HEAD/docs/api-auth.md) (an existing Google Cloud project can be reused — just needs the Calendar API enabled and a new OAuth Desktop-app client ID created on it) and run `gcalcli --client-id=xxx.apps.googleusercontent.com init`. After that one-time `init`, no further auth handling needed — `get_schedule.py` just calls plain `gcalcli agenda ...` and reuses its cached token.

- **Power profile switcher in the battery popup did nothing** — the buttons call `powerprofilesctl set <profile>`, but that CLI wasn't installed at all. Installing its usual package, `power-profiles-daemon`, conflicts at the RPM level with `tuned-ppd` (already installed, enabled, and running — Fedora's newer TuneD-based replacement, which implements the same `net.hadess.PowerProfiles`/`org.freedesktop.UPower.PowerProfiles` D-Bus API `powerprofilesctl` talks to). Rather than replacing a working, currently-recommended backend just to get one CLI script, extracted just `powerprofilesctl` from the package without installing it: `dnf download power-profiles-daemon` (no sudo needed, just a file download) → `rpm2cpio *.rpm | cpio -idmv` → copy `usr/bin/powerprofilesctl` out (it's a plain Python 3 script using `gi.repository.Gio`/`GLib`, both already present — no missing dependencies).
  - Placing it in `~/.local/bin/` still didn't work — a second, deeper bug: `Quickshell.execDetached()` (both the click handler and the background `sysPoller`) does a direct PATH-based exec with a bare command name, no shell involved. Reading `/proc/<hyprland-pid>/environ` directly showed Hyprland's own `PATH` is just `/usr/local/bin:/usr/bin:/var/lib/snapd/snap/bin` — `~/.local/bin` was never on it at all, since Hyprland is launched directly by GDM, not through a login shell that sources `.bashrc`. This is a real, general gap: `display-switch`'s own keybind already works around the identical issue by hardcoding its full `$HOME/.local/bin/...` path rather than relying on PATH.
  - Fixed two ways: (1) proper root-cause fix, added to `env.lua` — `hl.env("PATH", "$HOME/.local/bin:$HOME/bin:$PATH")`, so every future Hyprland/Quickshell-spawned process has `~/.local/bin` on its PATH (takes effect on the next full login, not `hyprctl reload`); (2) immediate fix for today, since a logout wasn't wanted right then — copied `powerprofilesctl` to `/usr/local/bin/` instead (already on Quickshell's PATH), one `sudo cp`. Verified live, simulating Quickshell's exact PATH via `env -i PATH=...`: `get`/`set`/`list` all round-trip correctly through all three profiles. Not tracked in this repo (extracted from Fedora's own package, not vendored into git) — reproduce with the steps above on a fresh install if `tuned-ppd` is present there too.

## Known limitations

- **Calendar's schedule strip now pulls from Google Calendar instead of a dead scraper** (see the "port work" section above for the fix itself) — no longer a limitation.
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
