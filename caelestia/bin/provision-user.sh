#!/usr/bin/env bash
# Pushes the caelestia setup (config, icon fixes, GPU crash workaround, etc.)
# into ANOTHER user's home directory, run by an admin with sudo — for when
# that user can't/shouldn't run install.sh themselves (no wheel/sudo access).
#
# Only handles the per-user files. Assumes the system-wide packages
# (caelestia-shell, caelestia-cli, quickshell-git, and everything else
# install.sh's `dnf install` steps cover) are already installed — they are,
# once installed via dnf/COPR they're available to every user on the
# machine already, nothing per-user needed there.
#
# Usage: sudo ./provision-user.sh <username>

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: must be run with sudo." >&2
    exit 1
fi

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    echo "Usage: sudo $0 <username>" >&2
    exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET" | cut -d: -f6)"
if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
    echo "ERROR: user '$TARGET' not found or has no home directory." >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$TARGET_HOME/hypr-fedora-preinstall-backup-$(date +%Y%m%d-%H%M%S)"

echo "==> Provisioning caelestia for '$TARGET' ($TARGET_HOME)"

echo "==> Backing up any existing config"
mkdir -p "$BACKUP_DIR"
[ -d "$TARGET_HOME/.config/hypr" ] && cp -r "$TARGET_HOME/.config/hypr" "$BACKUP_DIR/hypr"
[ -d "$TARGET_HOME/.config/caelestia" ] && cp -r "$TARGET_HOME/.config/caelestia" "$BACKUP_DIR/caelestia"

echo "==> Copying hypr/ and caelestia-config/"
mkdir -p "$TARGET_HOME/.config/hypr" "$TARGET_HOME/.config/caelestia"
cp -r "$REPO_DIR/hypr/." "$TARGET_HOME/.config/hypr/"
chmod +x "$TARGET_HOME/.config/hypr/scripts/"*.sh
cp -n "$REPO_DIR/caelestia-config/"* "$TARGET_HOME/.config/caelestia/" 2>/dev/null || true

echo "==> Installing bin/display-switch"
mkdir -p "$TARGET_HOME/.local/bin"
cp "$REPO_DIR/bin/display-switch" "$TARGET_HOME/.local/bin/display-switch"
chmod +x "$TARGET_HOME/.local/bin/display-switch"

echo "==> Fixing dart-sass (as $TARGET, installs to their own ~/.local, no sudo needed inside)"
sudo -u "$TARGET" -H bash "$REPO_DIR/bin/fix-dart-sass.sh" || \
    echo "WARNING: dart-sass fix failed — color scheme switching may not work for $TARGET."

echo "==> Wiring up pokefetch"
if command -v fastfetch >/dev/null 2>&1 && command -v pokemon-colorscripts >/dev/null 2>&1; then
    if ! grep -q "caelestia/bash/pokefetch.sh" "$TARGET_HOME/.bashrc" 2>/dev/null; then
        printf '\n# pokefetch (see hypr-fedora/caelestia/bash/pokefetch.sh)\nsource "%s/bash/pokefetch.sh"\n' "$REPO_DIR" >> "$TARGET_HOME/.bashrc"
    fi
fi

echo "==> Installing the breeze-full meta icon theme"
mkdir -p "$TARGET_HOME/.local/share/icons/breeze-full"
cp "$REPO_DIR/icons/breeze-full/index.theme" "$TARGET_HOME/.local/share/icons/breeze-full/index.theme"
sudo -u "$TARGET" kwriteconfig6 --file "$TARGET_HOME/.config/kdeglobals" --group Icons --key Theme breeze-full 2>&1 || \
    echo "WARNING: kwriteconfig6 failed — set kdeglobals [Icons] Theme=breeze-full manually for $TARGET."

echo "==> Installing app-icon desktop-entry overrides"
mkdir -p "$TARGET_HOME/.local/share/applications"
cp "$REPO_DIR/applications/"*.desktop "$TARGET_HOME/.local/share/applications/"

echo "==> Installing xwaylandvideobridge autostart override (Hyprland sessions only)"
mkdir -p "$TARGET_HOME/.config/autostart"
cp "$REPO_DIR/autostart/org.kde.xwaylandvideobridge.desktop" \
    "$TARGET_HOME/.config/autostart/org.kde.xwaylandvideobridge.desktop"

echo "==> Copying the hybrid-GPU crash workaround (machine-hardware-specific, applies to every user)"
GPU_CONF_SRC="/home/dex/.config/environment.d/10-gpu.conf"
mkdir -p "$TARGET_HOME/.config/environment.d"
if [ -f "$GPU_CONF_SRC" ]; then
    cp "$GPU_CONF_SRC" "$TARGET_HOME/.config/environment.d/10-gpu.conf"
else
    echo "WARNING: $GPU_CONF_SRC not found — copy it manually if this machine has the hybrid-GPU crash issue."
fi

echo "==> Installing xdg-desktop-portal.service override (drops the Requisite=graphical-session.target that permanently blocks it under plain Hyprland — see hypr/hyprland/execs.lua)"
mkdir -p "$TARGET_HOME/.config/systemd/user"
cp "$REPO_DIR/systemd-user-overrides/xdg-desktop-portal.service" "$TARGET_HOME/.config/systemd/user/xdg-desktop-portal.service"

echo "==> Applying shell-patches/ onto the caelestia-shell package (already applied system-wide, skipping — it's not per-user)"

echo "==> Fixing ownership"
chown -R "$TARGET:$TARGET" \
    "$TARGET_HOME/.config/hypr" \
    "$TARGET_HOME/.config/caelestia" \
    "$TARGET_HOME/.local/bin/display-switch" \
    "$TARGET_HOME/.local/share/icons/breeze-full" \
    "$TARGET_HOME/.local/share/applications" \
    "$TARGET_HOME/.config/autostart" \
    "$TARGET_HOME/.config/environment.d" \
    "$TARGET_HOME/.config/kdeglobals" \
    "$TARGET_HOME/.config/systemd" \
    "$TARGET_HOME/.bashrc" \
    "$BACKUP_DIR" \
    2>/dev/null || true
[ -d "$TARGET_HOME/.local/share/dart-sass" ] && chown -R "$TARGET:$TARGET" "$TARGET_HOME/.local/share/dart-sass" "$TARGET_HOME/.local/bin/sass" 2>/dev/null || true

echo
echo "Done. $TARGET can now log in and pick the Hyprland session — hyprpolkitagent"
echo "starts automatically via execs.lua, no per-user systemd enable needed."
echo "Previous config (if any) backed up to: $BACKUP_DIR"
