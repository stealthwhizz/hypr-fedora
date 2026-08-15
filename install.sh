#!/usr/bin/env bash
# install.sh — apply this config on top of an existing end-4/dots-hyprland (ii) setup.
#
# This does NOT install Hyprland, Quickshell, or the ii shell itself — it only
# layers my custom/ overrides, lock screen config, and companion script on top.
# See README.md for the full prerequisite (end-4/dots-hyprland) install steps.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
BIN_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/hypr-fedora-preinstall-backup-$(date +%Y%m%d-%H%M%S)"

echo "==> Checking prerequisites"

if [ ! -d "$HYPR_DIR/hyprland" ]; then
    echo "ERROR: $HYPR_DIR/hyprland not found."
    echo "This config layers on top of end-4/dots-hyprland (ii) — install that first:"
    echo "  https://github.com/end-4/dots-hyprland"
    exit 1
fi

if ! command -v hyprctl >/dev/null 2>&1; then
    echo "ERROR: hyprctl not found. Is Hyprland installed?"
    exit 1
fi

if ! command -v quickshell >/dev/null 2>&1 && ! command -v qs >/dev/null 2>&1; then
    echo "WARNING: quickshell/qs not found on PATH. The ii shell won't run without it."
fi

echo "==> Backing up your current config to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
[ -d "$HYPR_DIR/custom" ] && cp -r "$HYPR_DIR/custom" "$BACKUP_DIR/custom"
[ -f "$HYPR_DIR/hypridle.conf" ] && cp "$HYPR_DIR/hypridle.conf" "$BACKUP_DIR/hypridle.conf"
[ -f "$HYPR_DIR/hyprlock.conf" ] && cp "$HYPR_DIR/hyprlock.conf" "$BACKUP_DIR/hyprlock.conf"
[ -d "$HYPR_DIR/hyprlock" ] && cp -r "$HYPR_DIR/hyprlock" "$BACKUP_DIR/hyprlock"

echo "==> Installing custom/ overrides"
mkdir -p "$HYPR_DIR/custom"
cp -r "$REPO_DIR/hypr/custom/." "$HYPR_DIR/custom/"

echo "==> Installing hypridle.conf, hyprlock.conf, hyprlock/"
cp "$REPO_DIR/hypr/hypridle.conf" "$HYPR_DIR/hypridle.conf"
cp "$REPO_DIR/hypr/hyprlock.conf" "$HYPR_DIR/hyprlock.conf"
mkdir -p "$HYPR_DIR/hyprlock"
cp "$REPO_DIR/hypr/hyprlock/check-capslock.sh" "$HYPR_DIR/hyprlock/check-capslock.sh"
cp "$REPO_DIR/hypr/hyprlock/status.sh" "$HYPR_DIR/hyprlock/status.sh"
chmod +x "$HYPR_DIR/hyprlock/check-capslock.sh" "$HYPR_DIR/hyprlock/status.sh"

echo "==> Installing bin/display-switch"
mkdir -p "$BIN_DIR"
cp "$REPO_DIR/bin/display-switch" "$BIN_DIR/display-switch"
chmod +x "$BIN_DIR/display-switch"

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "WARNING: $BIN_DIR is not on your PATH. Add it in your shell config."
fi

echo "==> Reloading Hyprland (if running)"
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload
    echo "Reloaded."
else
    echo "Not running inside a Hyprland session — reload manually next login."
fi

echo
echo "Done. Previous config backed up to: $BACKUP_DIR"
