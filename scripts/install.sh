#!/bin/bash
# DoodlePin installer.
#
#   From the downloaded zip:   bash install.sh
#   Straight from the web:     curl -fsSL https://xoftverse.com/doodle-pin/install.sh | bash
#   Remove DoodlePin:          bash install.sh --uninstall
set -euo pipefail

APP_NAME="DoodlePin"
BUNDLE_ID="com.harshgaba.DoodlePin"
# Where the web installer downloads the app from. Set this when you publish a release.
DOWNLOAD_URL="${DOODLEPIN_URL:-https://github.com/HarshGaba1196/doodlePin/releases/latest/download/DoodlePin.zip}"

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
say()  { printf "  %s\n" "$1"; }
fail() { printf "\033[31m✗ %s\033[0m\n" "$1" >&2; exit 1; }

[[ "$(uname)" == "Darwin" ]] || fail "DoodlePin only runs on macOS."
MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
(( MACOS_MAJOR >= 14 )) || fail "DoodlePin needs macOS 14 Sonoma or later (you have $(sw_vers -productVersion))."

# Prefer /Applications; fall back to ~/Applications if we can't write there.
if [[ -w /Applications ]]; then DEST_DIR="/Applications"; else DEST_DIR="$HOME/Applications"; fi
DEST="$DEST_DIR/$APP_NAME.app"

if [[ "${1:-}" == "--uninstall" ]]; then
  bold "Removing DoodlePin…"
  pkill -x "$APP_NAME" 2>/dev/null || true
  rm -rf "/Applications/$APP_NAME.app" "$HOME/Applications/$APP_NAME.app"
  say "App removed."
  if [[ "${2:-}" == "--purge" ]]; then
    rm -rf "$HOME/Library/Containers/$BUNDLE_ID"
    defaults delete "$BUNDLE_ID" >/dev/null 2>&1 || true
    say "Pets and settings removed."
  else
    say "Your pets and settings were kept. Add --purge to remove them too."
  fi
  bold "Bye! 👋"
  exit 0
fi

bold "🐾 Installing DoodlePin"

# Use the app next to this script (zip install), or download it (web install).
# (When piped from curl there is no script file, so always download.)
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/$APP_NAME.app" ]]; then
  SRC="$SCRIPT_DIR/$APP_NAME.app"
  say "Using the app from this folder."
else
  [[ "$DOWNLOAD_URL" != *YOUR-GITHUB-USERNAME* ]] || fail "No download link has been set up yet. Download the zip and run install.sh from inside it."
  say "Downloading…"
  curl -fL --progress-bar "$DOWNLOAD_URL" -o "$WORK/app.zip" || fail "Download failed. Check your internet connection and try again."
  ditto -x -k "$WORK/app.zip" "$WORK" || fail "The download looks damaged. Try again."
  SRC=$(find "$WORK" -maxdepth 3 -name "$APP_NAME.app" -type d | head -1)
  [[ -n "$SRC" ]] || fail "Couldn't find DoodlePin.app in the download."
fi

[[ "$(cd "$SRC" && pwd)" != "$DEST" ]] || fail "Run this from the unzipped download folder, not from $DEST_DIR."

# Replace any running/older copy.
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5
mkdir -p "$DEST_DIR"
rm -rf "$DEST"
ditto "$SRC" "$DEST"

# DoodlePin isn't notarized by Apple yet, so clear the "downloaded from the internet"
# flag that would otherwise make macOS refuse to open it.
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

say "Installed to $DEST"
open "$DEST"
bold "Done! Look for your new pet on the desktop, and the blob face in the menu bar ↗"
