# hypr-fedora

My Hyprland configs on **Fedora Linux 44**, running Hyprland's Lua-based config (post-0.55).

Two setups, two folders:

- **[`ii/`](ii)** — my actual daily driver, built on [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) ("illogical-impulse"). Has a one-shot `install.sh`.
- **[`serpantinum/`](serpantinum)** — an alternate/experimental setup running [ilyamiro](https://github.com/ilyamiro)'s Serpantinum shell, ported to Fedora + Lua config. Manual install only.

Each folder has its own README with full details — layout, keybinds, dependencies, install steps, and known limitations.

Hyprland only runs one config at a time (`~/.config/hypr/hyprland.lua` is a single entry point), so switching between these on an actual machine means backing up whichever is currently active and copying the other one in — see each folder's README for exact steps.
