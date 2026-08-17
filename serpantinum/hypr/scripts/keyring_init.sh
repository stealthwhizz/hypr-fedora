#!/usr/bin/env bash
# Start (or connect to) gnome-keyring-daemon with every component, and publish
# its control socket / ssh-agent env vars to systemd --user and D-Bus's
# activation environment.
#
# Why this is needed: PAM (pam_gnome_keyring.so, wired into /etc/pam.d/gdm-password)
# does start and unlock a login keyring at actual login time - confirmed via
# journalctl ("gkr-pam: gnome-keyring-daemon started properly and unlocked
# keyring"). But Hyprland's own process never inherits those env vars (checked
# /proc/<hyprland-pid>/environ directly - GNOME_KEYRING_CONTROL/SSH_AUTH_SOCK
# are simply absent), so any app that asks for secrets via D-Bus later can't
# find that already-unlocked daemon. Systemd's D-Bus activation then spawns a
# completely separate, unrelated gnome-keyring-daemon instance from scratch -
# one with no knowledge of the login password - which has to interactively
# prompt to create/unlock its own keyring. That second daemon also throws
# internal D-Bus assertion errors on this system's gnome-keyring build,
# crashing shortly after. This was reproduced live: a fresh, unrelated
# login.keyring got created mid-session purely from testing app launches.
#
# Fix: explicitly start one daemon with all components ourselves and publish
# its env vars everywhere that matters, so every app's D-Bus secret lookup
# converges on the same instance instead of a second one spawning blind.

eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)"
export GNOME_KEYRING_CONTROL SSH_AUTH_SOCK

systemctl --user import-environment GNOME_KEYRING_CONTROL SSH_AUTH_SOCK 2>/dev/null
command -v dbus-update-activation-environment &>/dev/null && \
    dbus-update-activation-environment --systemd GNOME_KEYRING_CONTROL SSH_AUTH_SOCK 2>/dev/null

exit 0
