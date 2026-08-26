#!/usr/bin/env bash
# The dart-sass package pulled in by the celestelove/caelestia COPR (not in
# Fedora's official repos - a "local build" per its own changelog) shipped
# broken: /usr/bin/sass is the bare Dart VM binary, not the real dart-sass
# wrapper+snapshot. Every `caelestia scheme set` call fails its
# apply_discord() step as a result (calls `sass -I <path> <file>`, which the
# bare Dart VM misinterprets as "-I is not an AOT snapshot"), on every scheme,
# not just some.
#
# Fixes it by installing the real, official dart-sass release directly from
# sass/dart-sass's GitHub releases into ~/.local - no sudo needed, since
# ~/.local/bin already takes PATH precedence over /usr/bin (see ~/.bashrc).
# This shadows the broken system package without touching/fighting it, so a
# future fixed COPR rebuild won't conflict with this either.

set -euo pipefail

VERSION="1.103.1"
TARBALL="dart-sass-${VERSION}-linux-x64.tar.gz"
URL="https://github.com/sass/dart-sass/releases/download/${VERSION}/${TARBALL}"

if sass --help 2>&1 | grep -q "Compile Sass to CSS"; then
    echo "sass already resolves to a working dart-sass build - nothing to do."
    exit 0
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "==> Downloading dart-sass ${VERSION} from upstream GitHub releases"
curl -sL -o "$TMPDIR/$TARBALL" "$URL"

echo "==> Installing to ~/.local/share/dart-sass"
mkdir -p "$HOME/.local/share"
rm -rf "$HOME/.local/share/dart-sass"
tar -xzf "$TMPDIR/$TARBALL" -C "$HOME/.local/share/"
chmod +x "$HOME/.local/share/dart-sass/sass" "$HOME/.local/share/dart-sass/src/dart"

echo "==> Linking into ~/.local/bin/sass"
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/.local/share/dart-sass/sass" "$HOME/.local/bin/sass"

hash -r 2>/dev/null || true
echo "Done. $(sass --version 2>&1)"
