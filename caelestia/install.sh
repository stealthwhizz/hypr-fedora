#!/usr/bin/env bash
# install.sh — installs this repo's Hyprland Lua config + caelestia's own
# runtime config, plus the handful of plain-Fedora packages the config
# assumes. Does NOT install caelestia-shell/caelestia-cli/quickshell-git
# themselves — those come from the celestelove/caelestia COPR (see README's
# Dependencies section); this script assumes they're already installed.
#
# Needs sudo for package installs, so run this in a real terminal, not
# piped/non-interactively.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
CAELESTIA_CONFIG_DIR="$HOME/.config/caelestia"
BIN_DIR="$HOME/.local/bin"
SHELL_DIR="/etc/xdg/quickshell/caelestia"
BACKUP_DIR="$HOME/hypr-fedora-preinstall-backup-$(date +%Y%m%d-%H%M%S)"

if ! command -v caelestia >/dev/null 2>&1; then
    echo "ERROR: caelestia-cli not found on PATH."
    echo "Install caelestia-shell + caelestia-cli from the celestelove/caelestia"
    echo "COPR first (see this folder's README, Dependencies section), then re-run."
    exit 1
fi

echo "==> Backing up your current config to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
[ -d "$HYPR_DIR" ] && cp -r "$HYPR_DIR" "$BACKUP_DIR/hypr"
[ -d "$CAELESTIA_CONFIG_DIR" ] && cp -r "$CAELESTIA_CONFIG_DIR" "$BACKUP_DIR/caelestia"

echo "==> Installing missing plain-Fedora packages"
sudo dnf install -y gnome-keyring gammastep trash-cli hyprpolkitagent \
    pavucontrol ydotool

echo "==> Checking for VS Code (editor)"
# VSCodium was the original choice here, replaced with real VS Code (the
# admin account uses Zed instead, set via their own hypr-vars.lua override -
# see README).
if ! command -v code >/dev/null 2>&1; then
    echo "Adding Microsoft's official VS Code repo and installing"
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf install -y code
else
    echo "code already on PATH — skipping."
fi

echo "==> Installing hypr/ config"
mkdir -p "$HYPR_DIR"
cp -r "$REPO_DIR/hypr/." "$HYPR_DIR/"
chmod +x "$HYPR_DIR/scripts/"*.sh

echo "==> Installing caelestia's own runtime config (~/.config/caelestia)"
mkdir -p "$CAELESTIA_CONFIG_DIR"
cp -n "$REPO_DIR/caelestia-config/"* "$CAELESTIA_CONFIG_DIR/" 2>/dev/null || true

echo "==> Installing the breeze-full meta icon theme (~/.local/share/icons)"
mkdir -p "$HOME/.local/share/icons/breeze-full"
cp "$REPO_DIR/icons/breeze-full/index.theme" "$HOME/.local/share/icons/breeze-full/index.theme"
kwriteconfig6 --file kdeglobals --group Icons --key Theme breeze-full 2>/dev/null || \
    echo "WARNING: kwriteconfig6 not found — set kdeglobals [Icons] Theme=breeze-full manually."

echo "==> Installing System Settings desktop-entry overrides (hardcoded icon path — sidesteps the flaky icon-theme lookup entirely for these two)"
mkdir -p "$HOME/.local/share/applications"
cp "$REPO_DIR/applications/"*.desktop "$HOME/.local/share/applications/"

echo "==> Installing bin/display-switch"
mkdir -p "$BIN_DIR"
cp "$REPO_DIR/bin/display-switch" "$BIN_DIR/display-switch"
chmod +x "$BIN_DIR/display-switch"

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "WARNING: $BIN_DIR is not on your PATH. Add it in your shell config."
fi

echo "==> Wiring up pokefetch (fastfetch + a random pokemon on new terminals)"
if command -v fastfetch >/dev/null 2>&1 && command -v pokemon-colorscripts >/dev/null 2>&1; then
    if ! grep -q "caelestia/bash/pokefetch.sh" "$HOME/.bashrc" 2>/dev/null; then
        printf '\n# pokefetch (see hypr-fedora/caelestia/bash/pokefetch.sh)\nsource "%s/bash/pokefetch.sh"\n' "$REPO_DIR" >> "$HOME/.bashrc"
    fi
else
    echo "fastfetch and/or pokemon-colorscripts not installed — skipping. See caelestia/README.md."
fi

echo "==> Fixing dart-sass if the celestelove/caelestia COPR's build is broken"
"$REPO_DIR/bin/fix-dart-sass.sh"

echo "==> Installing xwaylandvideobridge autostart override (Hyprland sessions only)"
mkdir -p "$HOME/.config/autostart"
cp "$REPO_DIR/autostart/org.kde.xwaylandvideobridge.desktop" \
    "$HOME/.config/autostart/org.kde.xwaylandvideobridge.desktop"

echo "==> Applying shell-patches/ onto the caelestia-shell package (needs sudo)"
if [ -d "$SHELL_DIR" ]; then
    sudo cp -r "$REPO_DIR/shell-patches/." "$SHELL_DIR/"
else
    echo "WARNING: $SHELL_DIR not found — is caelestia-shell installed? Skipping patches."
fi

echo "==> Enabling hyprpolkitagent"
systemctl --user enable --now hyprpolkitagent 2>&1 || \
    echo "WARNING: couldn't enable hyprpolkitagent now — will start on next login."

echo "==> Reloading Hyprland (if running)"
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload
    echo "Reloaded."
else
    echo "Not running inside a Hyprland session — log in via the Hyprland session entry to test."
fi

echo
echo "Done. Previous config backed up to: $BACKUP_DIR"
echo "Verify AQ_DRM_DEVICES card numbering in ~/.config/environment.d/10-gpu.conf"
echo "before logging in — see this folder's README for why."
