#!/usr/bin/env bash

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

command -v jq >/dev/null || { echo "faltando: jq" >&2; exit 1; }

mkdir -p "$DEST"

for name in skills output-styles scripts SYSTEM.md; do
  rm -rf "${DEST:?}/$name"
  cp -R "$SRC/$name" "$DEST/$name"
  echo "+ $name"
done

[ -f "$DEST/settings.json" ] || echo '{}' > "$DEST/settings.json"

tmp="$(mktemp)"
jq -s '.[0] * .[1]' "$DEST/settings.json" "$SRC/settings.json" > "$tmp"
mv "$tmp" "$DEST/settings.json"
echo "+ settings.json"
