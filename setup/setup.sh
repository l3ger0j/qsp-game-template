#!/usr/bin/env bash
# Installs everything this game folder needs on macOS and Linux, into tools/:
# a portable VSCodium (the editor) with the QSP extension, the classic QSP
# player and qSpider. Nothing goes outside this folder, so no administrator
# rights are needed. Running it again updates to the versions in versions.env
# and keeps the author's editor settings and game.
#
#   bash setup/setup.sh [--lang ru|en] [--yes] [--no-qspider] [--qsp-vsix FILE]
#
#   --lang       interface language; asked when missing (and not --yes)
#   --yes        no questions, no pause at the end (for CI)
#   --no-qspider skip qSpider
#   --qsp-vsix   install this QSP extension file instead of the pinned release
#
# Written for bash 3.2, the version macOS ships.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
unset ELECTRON_RUN_AS_NODE
for v in $(env | sed -n 's/^\(VSCODE_[A-Za-z0-9_]*\)=.*/\1/p'); do unset "$v"; done
TOOLS="$ROOT/tools"
DOWNLOADS="$TOOLS/downloads"
LOG="$TOOLS/setup.log"

LANG_CHOICE=""
ASSUME_YES=0
WITH_QSPIDER=1
QSP_VSIX=""
while [ $# -gt 0 ]; do
  case "$1" in
    --lang) LANG_CHOICE="${2:-}"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    --no-qspider) WITH_QSPIDER=0; shift ;;
    --qsp-vsix) QSP_VSIX="${2:-}"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$DOWNLOADS"
exec > >(tee -a "$LOG") 2>&1
echo "── $(date '+%Y-%m-%d %H:%M:%S') ──"

# ── Language ────────────────────────────────────────────────────────
if [ -z "$LANG_CHOICE" ] && [ -f "$TOOLS/lang.txt" ]; then LANG_CHOICE="$(cat "$TOOLS/lang.txt")"; fi
if [ -z "$LANG_CHOICE" ]; then
  if [ "$ASSUME_YES" = 1 ]; then
    LANG_CHOICE=en
  else
    echo "Выберите язык / Choose a language:"
    echo "  1 — Русский"
    echo "  2 — English"
    printf "> "
    read -r answer
    case "$answer" in 2|en|EN|e|E) LANG_CHOICE=en ;; *) LANG_CHOICE=ru ;; esac
  fi
fi
case "$LANG_CHOICE" in ru|en) ;; *) echo "--lang must be ru or en" >&2; exit 2 ;; esac
echo "$LANG_CHOICE" > "$TOOLS/lang.txt"

# t "русский" "english": the message in the chosen language.
t() { if [ "$LANG_CHOICE" = ru ]; then printf '%s\n' "$1"; else printf '%s\n' "$2"; fi; }

pause_if_interactive() {
  if [ "$ASSUME_YES" = 0 ] && [ -t 0 ]; then
    t "Нажмите Enter, чтобы завершить." "Press Enter to finish."
    read -r _ || true
  fi
}

fail() {
  {
    echo
    t "Установка не удалась: $1" "Setup failed: $2"
    t "Подробности записаны в файл: $LOG" "Details are in this file: $LOG"
  } >&2
  touch "$TOOLS/.failed"
  if [ "$BASH_SUBSHELL" -eq 0 ]; then pause_if_interactive; fi
  exit 1
}
on_error() {
  if [ -f "$TOOLS/.failed" ]; then pause_if_interactive; exit 1; fi
  fail "ошибка в строке $1." "error at line $1."
}
rm -f "$TOOLS/.failed"
trap 'on_error $LINENO' ERR

# ── Platform ────────────────────────────────────────────────────────
# shellcheck source=versions.env
. "$ROOT/setup/versions.env"
case "$(uname -s)" in
  Darwin)
    OS=mac
    case "$(uname -m)" in
      arm64) VSCODIUM_URL="$VSCODIUM_MAC_ARM_URL"; VSCODIUM_SHA256="$VSCODIUM_MAC_ARM_SHA256" ;;
      *) VSCODIUM_URL="$VSCODIUM_MAC_X64_URL"; VSCODIUM_SHA256="$VSCODIUM_MAC_X64_SHA256" ;;
    esac
    QSPGUI_URL="$QSPGUI_MAC_URL"; QSPGUI_SHA256="$QSPGUI_MAC_SHA256"
    QSPIDER_URL="$QSPIDER_MAC_URL"; QSPIDER_SHA256="$QSPIDER_MAC_SHA256"
    ;;
  Linux)
    OS=linux
    # The players are built for 64-bit Intel/AMD Linux only.
    [ "$(uname -m)" = x86_64 ] || fail "нужен 64-битный Linux на процессоре Intel или AMD (x86_64)." \
      "this needs 64-bit Linux on an Intel or AMD processor (x86_64)."
    VSCODIUM_URL="$VSCODIUM_LINUX_URL"; VSCODIUM_SHA256="$VSCODIUM_LINUX_SHA256"
    QSPGUI_URL="$QSPGUI_LINUX_URL"; QSPGUI_SHA256="$QSPGUI_LINUX_SHA256"
    QSPIDER_URL="$QSPIDER_LINUX_URL"; QSPIDER_SHA256="$QSPIDER_LINUX_SHA256"
    ;;
  *) fail "эта система не поддерживается: $(uname -s)." "this system is not supported: $(uname -s)." ;;
esac

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

download() {
  local url="$1" sum="$2" file
  file="$DOWNLOADS/$(basename "$url")"
  if [ -f "$file" ] && { [ -z "$sum" ] || [ "$(sha256_of "$file")" = "$sum" ]; }; then
    echo "$file"; return
  fi
  t "Скачиваю $(basename "$url")…" "Downloading $(basename "$url")…" >&2
  curl -fL --retry 3 --progress-bar -o "$file.part" "$url" \
    || fail "не удалось скачать $url. Проверьте подключение к интернету и запустите установку ещё раз." \
            "could not download $url. Check the internet connection and run the setup again."
  if [ -n "$sum" ] && [ "$(sha256_of "$file.part")" != "$sum" ]; then
    rm -f "$file.part"
    fail "файл $(basename "$url") скачался повреждённым. Запустите установку ещё раз." \
         "$(basename "$url") arrived damaged. Run the setup again."
  fi
  mv "$file.part" "$file"
  echo "$file"
}

installed() { [ -f "$TOOLS/$1/.version" ] && [ "$(cat "$TOOLS/$1/.version")" = "$2" ]; }

extract_appimage() {
  local image="$1" dir="$2" tmp
  tmp="$(mktemp -d)"
  cp "$image" "$tmp/app.AppImage"
  chmod +x "$tmp/app.AppImage"
  (cd "$tmp" && ./app.AppImage --appimage-extract >/dev/null)
  rm -rf "$dir"
  mv "$tmp/squashfs-root" "$dir"
  rm -rf "$tmp"
}

# ── Editor ──────────────────────────────────────────────────────────
t "1/5. Редактор VSCodium $VSCODIUM_VERSION" "1/5. VSCodium editor $VSCODIUM_VERSION"
# shellcheck source=paths.sh
. "$ROOT/setup/paths.sh"
if [ "$OS" = linux ]; then
  export DONT_PROMPT_WSL_INSTALL=1
fi
export NODE_NO_WARNINGS=1
if ! installed vscodium "$VSCODIUM_VERSION"; then
  archive="$(download "$VSCODIUM_URL" "$VSCODIUM_SHA256")"
  kept="$(mktemp -d)"
  for d in extensions profile; do if [ -d "$EDITOR_DIR/$d" ]; then mv "$EDITOR_DIR/$d" "$kept/$d"; fi; done
  rm -rf "$EDITOR_DIR"
  mkdir -p "$EDITOR_DIR"
  if [ "$OS" = mac ]; then
    unzip -q "$archive" -d "$EDITOR_DIR"
    xattr -dr com.apple.quarantine "$EDITOR_DIR/VSCodium.app" 2>/dev/null || true
  else
    tar -xzf "$archive" -C "$EDITOR_DIR"
  fi
  for d in extensions profile; do if [ -d "$kept/$d" ]; then mv "$kept/$d" "$EDITOR_DIR/$d"; fi; done
  rm -rf "$kept"
  echo "$VSCODIUM_VERSION" > "$EDITOR_DIR/.version"
fi
mkdir -p "$USER_DATA_DIR/User" "$EXTENSIONS_DIR"

# ── Editor settings ─────────────────────────────────────────────────
t "2/5. Настройки редактора" "2/5. Editor settings"
[ -f "$USER_DATA_DIR/User/settings.json" ] || cp "$ROOT/setup/user-settings.json" "$USER_DATA_DIR/User/settings.json"

# ── Extensions ──────────────────────────────────────────────────────
t "3/5. Расширение QSP для редактора" "3/5. QSP extension for the editor"
install_extension() {
  "$EDITOR_CLI" --user-data-dir "$USER_DATA_DIR" --extensions-dir "$EXTENSIONS_DIR" --install-extension "$1" --force
}
if [ -n "$QSP_VSIX" ]; then
  install_extension "$QSP_VSIX"
else
  install_extension "$(download "$QSP_LSP_URL" "$QSP_LSP_SHA256")"
fi
if [ "$LANG_CHOICE" = ru ]; then
  install_extension "$(download "$LANGPACK_RU_URL" "$LANGPACK_RU_SHA256")"
fi

# ── Players ─────────────────────────────────────────────────────────
t "4/5. Плеер QSP $QSPGUI_VERSION" "4/5. QSP player $QSPGUI_VERSION"
if ! installed qspgui "$QSPGUI_VERSION"; then
  image="$(download "$QSPGUI_URL" "$QSPGUI_SHA256")"
  if [ "$OS" = mac ]; then
    mnt="$(mktemp -d)"
    PAGER=cat hdiutil attach -nobrowse -readonly -noautoopen -mountpoint "$mnt" "$image" < <(yes) >/dev/null
    app="$(find "$mnt" -maxdepth 2 -name '*.app' -print -quit)"
    rm -rf "$TOOLS/qspgui"
    mkdir -p "$TOOLS/qspgui"
    cp -R "$app" "$TOOLS/qspgui/qspgui.app"
    hdiutil detach "$mnt" >/dev/null
    xattr -dr com.apple.quarantine "$TOOLS/qspgui/qspgui.app" 2>/dev/null || true
  else
    extract_appimage "$image" "$TOOLS/qspgui"
  fi
  echo "$QSPGUI_VERSION" > "$TOOLS/qspgui/.version"
fi

if [ "$WITH_QSPIDER" = 1 ]; then
  t "      qSpider $QSPIDER_VERSION" "      qSpider $QSPIDER_VERSION"
  if ! installed qspider "$QSPIDER_VERSION"; then
    package="$(download "$QSPIDER_URL" "$QSPIDER_SHA256")"
    if [ "$OS" = mac ]; then
      rm -rf "$TOOLS/qspider"
      mkdir -p "$TOOLS/qspider"
      tar -xzf "$package" -C "$TOOLS/qspider"
      xattr -dr com.apple.quarantine "$TOOLS/qspider/qSpider.app" 2>/dev/null || true
    else
      extract_appimage "$package" "$TOOLS/qspider"
    fi
    echo "$QSPIDER_VERSION" > "$TOOLS/qspider/.version"
  fi
fi

# ── Game ────────────────────────────────────────────────────────────
t "5/5. Игра" "5/5. Game"
if ! ls "$ROOT/game"/*.qsps >/dev/null 2>&1; then
  cp "$ROOT/setup/samples/$LANG_CHOICE/main.qsps" "$ROOT/game/main.qsps"
  t "      Добавлена стартовая игра: game/main.qsps" "      Added a starter game: game/main.qsps"
fi

trap - ERR
rm -f "$DOWNLOADS"/*
echo
if [ "$OS" = mac ]; then
  t "Готово! Теперь дважды щёлкните файл «open-game-macos.command»." "Done! Now double-click the file “open-game-macos.command”."
else
  t "Готово! Теперь запустите файл «open-game-linux.sh»." "Done! Now run the file “open-game-linux.sh”."
fi
pause_if_interactive
