#!/usr/bin/env bash

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

command -v jq >/dev/null || { echo "faltando: jq" >&2; exit 1; }

mkdir -p "$DEST"

for name in skills output-styles scripts; do
  rm -rf "${DEST:?}/$name"
  cp -R "$SRC/$name" "$DEST/$name"
  echo "+ $name"
done

[ -f "$DEST/settings.json" ] || echo '{}' > "$DEST/settings.json"

tmp="$(mktemp)"
jq -s '.[0] * .[1]' "$DEST/settings.json" "$SRC/settings.json" > "$tmp"
mv "$tmp" "$DEST/settings.json"
echo "+ settings.json"

# MARKETPLACE="claude-plugins-official"
# PLUGINS=(rust-analyzer-lsp typescript-lsp pyright-lsp)

# CLAUDE_CONFIG_DIR="$DEST" claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1 || true

# for p in "${PLUGINS[@]}"; do
#   CLAUDE_CONFIG_DIR="$DEST" claude plugin install "$p@$MARKETPLACE" >/dev/null 2>&1 || true
#   echo "+ plugin $p"
# done

# if command -v npm >/dev/null; then
#   for bin in typescript-language-server pyright-langserver; do
#     command -v "$bin" >/dev/null || {
#       npm install -g typescript@5 typescript-language-server pyright >/dev/null
#       echo "+ npm language servers"
#       break
#     }
#   done
# fi
