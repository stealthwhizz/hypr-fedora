#!/usr/bin/env bash
# bootstrap.sh — one-shot caelestia setup on a fresh Fedora box.
#
# Does everything install.sh assumes is already done:
#   1. enables the third-party COPRs (asks first)
#   2. installs hyprland + caelestia-shell + caelestia-cli
#   3. (only with --float-all) seeds ~/.config/caelestia/hypr-user.lua with a
#      "float every window" rule. Default is tiling; Super+Alt+Space floats one window.
#   4. copies ../wallpapers/*.{jpg,jpeg,png} into ~/Pictures/Wallpapers
#      (caelestia's picker scans that folder; existing files are not overwritten)
#   5. runs ./install.sh (backs up existing config, copies the Lua config in)
#
# Usage:  ./bootstrap.sh [--float-all] [--no-wallpapers] [-y]
#   --float-all      float every window instead of tiling (step 3)
#   --no-wallpapers  don't copy the wallpaper set (skip step 4)
#   -y               don't prompt before enabling COPRs
#
# Run in a real terminal as your normal user (it calls sudo itself).
# Afterwards: log out and pick the "Hyprland" session.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COPRS=(
    lionheartp/Hyprland              # Hyprland with Lua config (0.55+)
    celestelove/caelestia            # caelestia-shell + caelestia-cli
    errornointernet/quickshell       # quickshell-git (caelestia dep)
)
FLOAT=0
ASSUME_YES=0
WALLPAPERS=1

for arg in "$@"; do
    case "$arg" in
        --float-all) FLOAT=1 ;;
        --no-wallpapers) WALLPAPERS=0 ;;
        -y|--yes)   ASSUME_YES=1 ;;
        -h|--help)  sed -n '2,19p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

if [ "$(id -u)" -eq 0 ]; then
    echo "Run as your normal user, not root — install.sh writes into your \$HOME." >&2
    exit 1
fi

if [ ! -r /etc/fedora-release ]; then
    echo "This script is for Fedora (no /etc/fedora-release found)." >&2
    exit 1
fi

echo "This will enable these THIRD-PARTY COPR repos (unreviewed by Fedora;"
echo "packages from them install as root and update automatically):"
for c in "${COPRS[@]}"; do echo "  - https://copr.fedorainfracloud.org/coprs/$c/"; done
if [ "$ASSUME_YES" -ne 1 ]; then
    read -r -p "Continue? [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

echo "==> Enabling COPRs"
sudo dnf install -y dnf-plugins-core
for c in "${COPRS[@]}"; do
    sudo dnf copr enable -y "$c"
done

echo "==> Installing hyprland, caelestia-shell, caelestia-cli"
# hyprland-guiutils: Hyprland's own startup/error dialogs (missing -> "guiutils not installed" popup).
# qt6-qtimageformats: WebP decoder; without it caelestia's default wallpaper.webp
# fails to decode and the desktop is solid black.
sudo dnf install -y hyprland hyprland-guiutils caelestia-shell caelestia-cli qt6-qtimageformats

if [ "$FLOAT" -eq 1 ]; then
    USER_LUA="$HOME/.config/caelestia/hypr-user.lua"
    mkdir -p "$(dirname "$USER_LUA")"
    if grep -qs "bootstrap.sh: float all" "$USER_LUA"; then
        echo "==> Float rule already in $USER_LUA — skipping"
    else
        echo "==> Adding float-all-windows rule to $USER_LUA"
        cat >> "$USER_LUA" <<'EOF'

-- bootstrap.sh: float all windows (free placement, no auto-tiling).
-- Super+LMB drag = move, Super+RMB drag = resize,
-- Super+Alt+Space = toggle one window back to tiled.
-- Delete this rule to restore tiling (the default).
hl.window_rule({ match = { class = ".*" }, float = true })
EOF
    fi
fi

if [ "$WALLPAPERS" -eq 1 ]; then
    # Copied BEFORE the shell first starts: it scans the folder at startup.
    SRC_WALLS="$REPO_DIR/../wallpapers"
    DEST_WALLS="$HOME/Pictures/Wallpapers"
    if [ -d "$SRC_WALLS" ]; then
        echo "==> Copying wallpapers to $DEST_WALLS"
        mkdir -p "$DEST_WALLS"
        # -n: never overwrite; .webp skipped (needs qt6-qtimageformats, installed above anyway)
        find "$SRC_WALLS" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
            -exec cp -n -t "$DEST_WALLS" {} +
        echo "    $(find "$DEST_WALLS" -maxdepth 1 -type f | wc -l) files in $DEST_WALLS"
    else
        echo "==> $SRC_WALLS not found — skipping wallpapers"
    fi
fi

echo "==> Running install.sh"
"$REPO_DIR/install.sh"

echo
echo "Done. Log out and choose the 'Hyprland' session to try it."
