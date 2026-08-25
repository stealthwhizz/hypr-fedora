# hypr-fedora / caelestia

[caelestia-dots](https://github.com/caelestia-dots)'s Quickshell-based Hyprland desktop shell, ported to **Fedora Linux 44** with Hyprland's Lua config (post-0.55).

This is the third shell port in this repo, alongside [`ii/`](../ii) (end-4/dots-hyprland, daily driver) and [`serpantinum/`](../serpantinum) (ilyamiro's Serpantinum, alternate/experimental). Tried after serpantinum hit a hard-to-diagnose delayed shell crash — caelestia's Hyprland config is already native Lua upstream (no `.conf`→Lua syntax translation needed, unlike serpantinum), which meant this port was much less about rewriting config and much more about path/package adaptation.

**Versions this was built against**: Fedora 44, Hyprland 0.56.2, `caelestia-shell` 2.3.0, `caelestia-cli` 1.1.2, `quickshell-git` 0.3.1^847.

Upstream is split across three repos: [caelestia-dots/shell](https://github.com/caelestia-dots/shell) (the Quickshell app + a compiled C++/Qt6 plugin), [caelestia-dots/caelestia](https://github.com/caelestia-dots/caelestia) (the "dots" — Hyprland config + other app configs), [caelestia-dots/cli](https://github.com/caelestia-dots/cli) (the `caelestia` command). `shell`/`cli` are GPL-3.0; the `caelestia` dots repo itself has no LICENSE file — this folder treats personal-config adaptation as fair use, same as `ii/` and `serpantinum/` already do with their own upstreams.

## What's here

Only the Hyprland compositor layer + the shell's own runtime config — **not** caelestia's other app-config components (fish, foot, btop, thunar, firefox theme, vscode, zed, spicetify). This machine (and this repo's convention) uses kitty/nautilus instead, so those are out of scope here, same scoping `ii/`/`serpantinum/` already use.

The shell itself provides: top bar, app launcher, notifications, lock screen, OSD (volume/brightness/capslock), sidebar, dashboard, screenshot/recording (via `caelestia-cli`), clipboard/emoji picker (via `fuzzel`), and Material-You-style theming — done with a **compiled C++ image-analysis plugin**, not matugen (no matugen dependency anywhere in this port).

```
hypr/
├── hyprland.lua              # Entry point — unmodified from upstream, already fully portable
├── variables.lua              # ADAPTED: terminal/fileExplorer/audioSettings/cursorTheme app choices
├── scheme/default.lua         # Fallback colour scheme; current.lua is runtime-generated, gitignored
├── hyprland/
│   ├── env.lua                 # unchanged (upstream already sets XDG_CURRENT_DESKTOP/etc via hl.env correctly)
│   ├── execs.lua                # ADAPTED — see Notable fixes below
│   ├── general.lua, input.lua, misc.lua, animations.lua, decoration.lua, group.lua, gestures.lua, rules.lua, keybinds.lua   # unchanged
│   └── scripts/keyring_init.sh  # ported from serpantinum/hypr/scripts/keyring_init.sh
└── utils/                      # helper Lua required by hyprland/*.lua, copied as-is

caelestia-config/                # mirrors ~/.config/caelestia/ (separate from ~/.config/hypr/)
├── hypr-vars.lua                # empty override seed (upstream's own mechanism, "return {}")
├── hypr-user.lua                # empty override seed (upstream's own mechanism)
└── (shell.json intentionally not committed — see Known limitations)

bin/
└── display-switch                # reused verbatim from serpantinum/bin/display-switch — confirmed generic (autodetects eDP-*/LVDS* vs external via hyprctl monitors + jq, no shell-specific IPC)

bash/
└── pokefetch.sh                  # not part of caelestia-shell itself — fastfetch + a random pokemon (via pokemon-colorscripts) on every new terminal, sourced from ~/.bashrc by install.sh
```

## Dependencies

**COPR**: [`celestelove/caelestia`](https://copr.fedorainfracloud.org/coprs/celestelove/caelestia/) — builds `caelestia-shell` and `caelestia-cli` for Fedora 44 directly (no CMake/native-plugin build needed). Its coprdeps ([`errornointernet/quickshell`](https://copr.fedorainfracloud.org/coprs/errornointernet/quickshell/) for `quickshell-git`, `celestelove/app2unit`, `celestelove/libcava`, `brycensranch/gpu-screen-recorder-git`) get pulled in automatically when you `dnf install caelestia-shell caelestia-cli` with the main COPR enabled. `hyprpolkitagent` comes from the already-enabled `lionheartp/Hyprland` COPR.

> **Third-party COPR trust note**: `celestelove/caelestia` is a single, unofficial maintainer's COPR — not Fedora, not upstream caelestia. It's the path used here because it avoids a from-source CMake build of caelestia-shell's compiled C++/Qt6 plugin against a matching `quickshell-git` build (real ABI risk). If it ever disappears or you don't trust it, upstream's own from-source build docs (`caelestia-dots/shell`'s README, "Manual installation" section) are the fallback — not covered further here.

**Plain Fedora repo** (installed by `install.sh`): `gnome-keyring`, `gammastep`, `trash-cli`, `hyprpolkitagent`, `pavucontrol`, `ydotool`.

**VSCodium** (editor): not in any Fedora repo or the COPRs above — `install.sh` adds VSCodium's own official repo (`download.vscodium.com`, GPG-verified) and installs from there.

**Already installed / assumed present**: `hyprpicker`, `fuzzel`, `geoclue2`, `wireplumber`/`wpctl`, `cliphist`, `wl-clipboard` — all confirmed present on this machine already (from prior serpantinum/base setup work).

**Optional, for `bash/pokefetch.sh`**: `fastfetch` (plain Fedora repo) and [`pokemon-colorscripts`](https://gitlab.com/phoneybadger/pokemon-colorscripts) (installs from source via its own `install.sh`, not packaged for Fedora). `install.sh` only wires up the auto-run-on-terminal-open hook if both are already on `PATH` — otherwise it's skipped silently, no hard dependency.

## Notable fixes/decisions

- **Keyring — same bug serpantinum already diagnosed on this exact OS+session stack.** Upstream's `execs.lua` just runs `gnome-keyring-daemon --start --components=secrets`. On this machine, PAM (`pam_gnome_keyring.so`, wired into `/etc/pam.d/sddm` — this machine's login manager is `plasmalogin`, an SDDM derivative, not GDM as serpantinum's own comments originally assumed) already unlocks a keyring at login, but Hyprland's process never inherits its env vars, so a second blind keyring spawns and forces an interactive prompt. Fixed by porting `serpantinum/hypr/scripts/keyring_init.sh` over and calling that instead — same root cause, same fix, not yet re-verified live in this specific shell (**Unverified** until first-boot testing, see below).
- **Polkit agent path doesn't exist on Fedora.** Upstream execs `/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1` — confirmed via `dnf repoquery polkit-gnome` across every enabled repo (including all COPRs on this machine) that this package genuinely doesn't exist for Fedora. Removed that line; `install.sh` instead does `systemctl --user enable --now hyprpolkitagent`, the same fix already proven working for serpantinum on this machine. **Unverified** in this shell specifically until tested.
- **Geoclue path.** Upstream execs `/usr/lib/geoclue-2.0/demos/agent` — Fedora's `geoclue2` package installs to `/usr/libexec`, not `/usr/lib`. Confirmed via `rpm -ql geoclue2` that `/usr/libexec/geoclue-2.0/demos/agent` is the real path. One-line fix, not yet tested live.
- **`terminal`/`fileExplorer`**: upstream defaults to `foot`/`thunar`, neither installed here. Repointed at `kitty`/`nautilus`, matching `ii/`'s and `serpantinum/`'s existing convention.
- **`audioSettings`**: upstream defaults to `pwvucontrol`. No Fedora package or COPR for it was found (checked all COPRs already enabled on this machine, all returned nothing). Substituted `pavucontrol` — same purpose (PipeWire volume mixer GUI), available directly from Fedora's own repos, rather than guessing at an unverified third-party repo.
- **`cursorTheme`**: upstream defaults to `sweet-cursors`, not installed anywhere (same class of bug serpantinum documented — theme mismatch causes flicker between GTK's fallback and Hyprland's own compositor-level cursor rendering, which has no theme set independently otherwise). Serpantinum's own fix (`Bibata-Modern-Classic`) also has no verified Fedora source. Used `breeze_cursors` instead — it's already installed as this KDE Plasma spin's own system-default cursor theme (`breeze-cursor-theme` package), which sidesteps the "theme not installed" root cause entirely rather than trading one availability risk for another.
- **`QT_QPA_PLATFORMTHEME = "qtengine"`** (in `env.lua`, unchanged): `qtengine` is an AUR-only Qt theming engine with no Fedora equivalent found. Left as-is rather than guessing a substitute — Qt apps will just fall back to default Qt styling instead of caelestia's intended theme. Cosmetic only, not fixed — see Known limitations.
- **Icon theme was never set at all.** Upstream sets a cursor theme via `gsettings` but never an icon theme, and nothing else in this port did either. Confirmed live: system-tray icons resolved by freedesktop icon-theme lookup (rather than an app's own bundled icon) failed to resolve anything and rendered as Qt's generic broken-icon placeholder — reproduced with the Discover/PackageKit update-checker's tray icon and its context menu items. Fixed by adding `gsettings set org.gnome.desktop.interface icon-theme breeze` alongside the existing cursor-theme line — `breeze` is already installed as this KDE spin's own default icon theme, no new dependency needed. **Unverified** — added after the bug was seen live, not yet re-tested.

## Known limitations

- **First real login confirmed the shell starts, renders, and the system tray works** (bar, sidebar, clock, wallpaper, media widget, tray icons all confirmed live via screenshot) — this is real progress beyond "written but never tested." But most of the specific fixes above (keyring, polkit, geoclue path) haven't been individually exercised yet — a working shell doesn't by itself prove those particular code paths ran correctly, just that nothing in them was fatal. Treat each "Unverified" item above as still open until specifically checked (see Verification below).
- **`shell.json` is not committed.** Caelestia-shell's own runtime settings (`~/.config/caelestia/shell.json` — bar/dashboard/launcher/lock/notifs/osd/sidebar/utilities schema, plus per-monitor overrides) aren't seeded here; the shell runs on its compiled-in defaults until you customize it, then `caelestia scheme set -n caelestia` (or any bundled scheme) generates the initial `scheme/current.lua`. Committing a speculative `shell.json` before it's ever been tested against this machine's real monitor/DPI felt worse than just documenting the gap.
- **Qt app theming (`qtengine`) doesn't work** — see Notable fixes above. Cosmetic only.
- **Multi-monitor / HDMI-A-1 hotplug**: untested. Serpantinum documented a real hybrid-GPU (Intel + NVIDIA/nouveau) issue where an external monitor modesets correctly at the DRM level but never gets re-announced to Wayland clients until a physical unplug/replug. Caelestia-shell's own `services/Screens.qml` monitor handling has **not** been assumed to avoid this just because it's different code — needs the same explicit `grim -o HDMI-A-1` probe test serpantinum used.
- **`sleepGestureCmd = "systemctl suspend-then-hibernate"`** (unchanged from upstream): whether hibernate is actually configured on this machine (swap size, etc.) hasn't been checked. Untested.
- **`~/.config/environment.d/10-gpu.conf` card-numbering drift** (orthogonal to this port, not fixed here): this file's `AQ_DRM_DEVICES` value depends on `/dev/dri/cardN` numbering, which isn't guaranteed stable across boots. Re-verify with `udevadm info --query=all --name=/dev/dri/cardN | grep ID_PATH` before every first login of a new boot if Hyprland fails to start at all — a bad value here crashes Hyprland before any Lua config loads (this exact failure already happened once during the serpantinum port).

## Install

1. Make sure `caelestia-shell`/`caelestia-cli`/`quickshell-git` are installed (via the `celestelove/caelestia` COPR — see Dependencies above; already done on this machine as of this port).
2. `./install.sh` — backs up any existing `~/.config/hypr`/`~/.config/caelestia`, installs the short missing-package list + VSCodium, copies `hypr/` and `caelestia-config/` into place, installs `bin/display-switch`, enables `hyprpolkitagent`, reloads Hyprland if already running.
3. Re-verify `AQ_DRM_DEVICES` (see Known limitations) before logging in.
4. Log in via the `Hyprland` session entry at the login screen (not the UWSM variant, to match how this and the other two ports were built/tested).

To go back: restore from the timestamped backup `install.sh` creates, or follow [`ii/install.sh`](../ii/install.sh) / [`serpantinum/README.md`](../serpantinum/README.md#install).

## Verification / debugging playbook

Recommended incremental approach, given serpantinum's own experience of a shell that looked fine in logs and crashed later:

1. `hyprctl monitors` — confirm `eDP-1` live (upstream's monitor block is a generic wildcard, no per-machine edit needed here, unlike serpantinum).
2. Confirm the shell process survives past the first ~60 seconds, then keep re-checking every couple minutes rather than assuming a clean start means stable: `pgrep -a quickshell` / `pgrep -a caelestia`.
3. Test polkit: `udisksctl mount` on an NTFS/exFAT partition (neutral test, no auth-agent prompt should appear if the fix worked). Test keyring: `systemctl --user show-environment | grep SSH_AUTH_SOCK` should be present.
4. Test external monitor: connect HDMI, run `bin/display-switch`, probe with `grim -o HDMI-A-1`.
5. If anything crashes: `~/.cache/hyprland/hyprlandCrashReport*.txt` for Hyprland-level crashes, `coredumpctl list quickshell` / `coredumpctl list caelestia-shell` for the shell process, `journalctl -b` / `journalctl --list-boots` if it looks like the delayed-reboot GSP-firmware crash class documented in `serpantinum/README.md`.
6. Only mark the "Unverified" items above as "Verified live" after a realistic-length stable session, not immediately after first successful start.
