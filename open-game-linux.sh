#!/bin/bash
ROOT="$(cd "$(dirname "$0")" && pwd)"
unset ELECTRON_RUN_AS_NODE
for v in $(env | sed -n 's/^\(VSCODE_[A-Za-z0-9_]*\)=.*/\1/p'); do unset "$v"; done
. "$ROOT/setup/paths.sh"
if [ ! -x "$EDITOR_APP" ]; then
  echo "Сначала запустите install-linux.sh. / Run install-linux.sh first."
  exit 1
fi
nohup "$EDITOR_APP" --user-data-dir "$USER_DATA_DIR" --extensions-dir "$EXTENSIONS_DIR" \
  --locale "$(cat "$ROOT/tools/lang.txt" 2>/dev/null || echo en)" "$ROOT/game" >/dev/null 2>&1 &
