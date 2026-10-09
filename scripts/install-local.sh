#!/usr/bin/env bash
# Install this theme into the user qylock themes dir and activate it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/qylock/themes/felix-lock-strip"

mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
mkdir -p "$DEST"

cp -a "$ROOT/content/." "$DEST/"
cp -a "$ROOT/LICENSE" "$DEST/LICENSE"
cp -a "$ROOT/PROVENANCE.txt" "$DEST/PROVENANCE.txt"
# Runtime preview optional; hub list may show file://preview when present.
cp -a "$ROOT/assets/preview.png" "$DEST/preview.png"

echo "Installed → $DEST"
if command -v ryoku-hub >/dev/null 2>&1; then
  ryoku-hub lock set felix-lock-strip
  echo "Active lock skin: felix-lock-strip"
  echo
  echo "Preview in-session:  ryoku-shell lock"
  echo "Apply SDDM greeter:  ryoku-hub lock apply-greeter   # may need root"
else
  echo "ryoku-hub not on PATH; copy done — activate manually when available."
fi
