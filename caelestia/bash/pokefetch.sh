# fastfetch with a random pokemon as the logo, via pokemon-colorscripts
# (https://gitlab.com/phoneybadger/pokemon-colorscripts - installed from
# source with its own install.sh, not packaged for Fedora).
# Sourced from ~/.bashrc by install.sh - not part of caelestia-shell itself,
# just a personal terminal-startup addition kept in this folder since it's
# used from caelestia's kitty session.
alias pokefetch='pokemon-colorscripts --no-title -r | fastfetch --file-raw -'

# Run it automatically on every new interactive terminal (guarded so it
# doesn't fire for non-interactive shells, e.g. scripts sourcing .bashrc)
case $- in
    *i*) pokefetch ;;
esac
