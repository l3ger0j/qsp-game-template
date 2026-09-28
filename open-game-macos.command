#!/bin/bash
ROOT="$(cd "$(dirname "$0")" && pwd)"
unset ELECTRON_RUN_AS_NODE
for v in $(env | sed -n 's/^\(VSCODE_[A-Za-z0-9_]*\)=.*/\1/p'); do unset "$v"; done
. "$ROOT/setup/paths.sh"
if [ ! -d "$EDITOR_APP" ]; then
  echo "Сначала запустите install-macos.command. / Run install-macos.command first."
  exit 1
fi
open -n "$EDITOR_APP" --args --user-data-dir "$USER_DATA_DIR" --extensions-dir "$EXTENSIONS_DIR" \
  --locale "$(cat "$ROOT/tools/lang.txt" 2>/dev/null || echo en)" "$ROOT/game"
echo "Это окно можно закрыть. / You can close this window."
