# Where the editor installed by setup.sh keeps things on macOS and Linux.
# Sourced by setup.sh and the open-game scripts, so both use the same places.
# Expects ROOT (the game folder's parent: the template's root).
#
# Not VSCodium's portable mode: in it the editor puts a Unix socket inside
# its data folder, and a socket path longer than 107 bytes (103 on macOS)
# stops the editor from starting. A game kept in "Documents/Мои игры/…"
# passes that easily. So the extensions stay in tools/, and the profile
# (settings, window state, the local history of edits) goes where the
# socket path stays short:
#   Linux with XDG_RUNTIME_DIR (any desktop session): tools/vscodium/profile,
#     since the socket then goes to XDG_RUNTIME_DIR instead;
#   otherwise, and always on macOS: a folder of its own per game in the
#     user's config directory.
# Windows (setup.ps1) keeps the portable mode: its pipes have no such limit.

EDITOR_DIR="$ROOT/tools/vscodium"
EXTENSIONS_DIR="$EDITOR_DIR/extensions"

game_id() { printf '%s' "$ROOT" | cksum | cut -d' ' -f1; }

case "$(uname -s)" in
  Darwin)
    EDITOR_APP="$EDITOR_DIR/VSCodium.app"
    EDITOR_CLI="$EDITOR_APP/Contents/Resources/app/bin/codium"
    USER_DATA_DIR="$HOME/Library/Application Support/qsp-editor/$(game_id)"
    ;;
  *)
    EDITOR_APP="$EDITOR_DIR/codium"
    EDITOR_CLI="$EDITOR_DIR/bin/codium"
    if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
      USER_DATA_DIR="$EDITOR_DIR/profile"
    else
      USER_DATA_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/qsp-editor/$(game_id)"
    fi
    ;;
esac

