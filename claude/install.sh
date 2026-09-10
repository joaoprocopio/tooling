#!/usr/bin/env bash

set -euo pipefail

TOOLS="Agent,Bash,Edit,EnterWorktree,ExitWorktree,Glob,Grep,ListAgents,Monitor,PushNotification,Read,SendMessage,Skill,WebFetch,WebSearch,Write"
FN_NAME="claude"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
ZSHRC="$HOME/.zshrc"
STAMP="$(date +%Y%m%d-%H%M%S)"

BEGIN_MARK="# >>> claude-code (joaoprocopio/tools/claude) >>>"
END_MARK="# <<< claude-code (joaoprocopio/tools/claude) <<<"

ITEMS=(skills output-styles scripts SYSTEM.md)

for arg in "$@"; do
  case "$arg" in
    -h|--help) sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 0 ;;
    *)         echo "argumento desconhecido: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '%s\n' "$*"; }

command -v jq >/dev/null || { echo "faltando: jq" >&2; exit 1; }

say "==> copiando para $DEST"
[ -d "$DEST" ] || mkdir -p "$DEST"

for name in "${ITEMS[@]}"; do
  src="$SRC/$name"
  target="$DEST/$name"

  [ -e "$src" ] || { say "  ! $name nao existe em $SRC, pulando"; continue; }

  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -L "$target" ]; then
      # sobra de uma instalacao anterior que usava symlink
      rm "$target"
      say "  ~ $name (era symlink, agora e copia)"
    elif diff -rq "$src" "$target" >/dev/null 2>&1; then
      say "  = $name (ja identico)"
      continue
    else
      mv "$target" "$target.bak-$STAMP"
      say "  ~ $name (divergia; backup em $name.bak-$STAMP)"
    fi
  fi

  cp -R "$src" "$target"
  say "  + $name"
done

say "==> mesclando settings.json em $DEST/settings.json"
SETTINGS="$DEST/settings.json"
PATCH="$SRC/settings.json"

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

for f in "$SETTINGS" "$PATCH"; do
  jq empty "$f" 2>/dev/null || { echo "  ! $f nao e JSON valido, abortando" >&2; exit 1; }
done

cp "$SETTINGS" "$SETTINGS.bak-$STAMP"
tmp="$(mktemp)"
jq -s '.[0] * .[1]' "$SETTINGS" "$PATCH" > "$tmp"
mv "$tmp" "$SETTINGS"
say "  + $(jq -r 'keys | join(", ")' "$PATCH") (backup: settings.json.bak-$STAMP)"

say "==> funcao '$FN_NAME' em $ZSHRC"

BLOCK="$BEGIN_MARK
# Editado por: $SRC/install.sh
$FN_NAME() {
  command claude \\
    --system-prompt-file \"$DEST/SYSTEM.md\" \\
    --tools $TOOLS \\
    \"\$@\"
}
$END_MARK"

touch "$ZSHRC"
if grep -qF "$BEGIN_MARK" "$ZSHRC"; then
  cp "$ZSHRC" "$ZSHRC.bak-$STAMP"
  sed -i "/${BEGIN_MARK//\//\\/}/,/${END_MARK//\//\\/}/d" "$ZSHRC"
  say "  ~ bloco anterior substituido (backup: .zshrc.bak-$STAMP)"
fi
printf '\n%s\n' "$BLOCK" >> "$ZSHRC"
say "  + funcao $FN_NAME (tools: $TOOLS)"

# --- fim --------------------------------------------------------------------

say
say "Pronto. Rode:  source $ZSHRC"
say "Depois:        claude          -> prompt minimo"
say "               command claude  -> padrao completo"
