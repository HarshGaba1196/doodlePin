#!/bin/zsh
# Regenerates the app icon PNGs in the asset catalog from the doodle drawing code.
# Optional: pass a path to also write a preview sheet of every doodle.
set -e
cd "$(dirname "$0")/.."
ICONSET=DoodlePin/Assets.xcassets/AppIcon.appiconset
TMP=$(mktemp -d)
swiftc -O -target "$(uname -m)-apple-macos14.0" -o "$TMP/iconmaker" \
  Tools/IconMaker/main.swift \
  DoodlePin/Model/DoodleType.swift \
  DoodlePin/Doodles/*.swift
"$TMP/iconmaker" "$ICONSET" "$@"
rm -rf "$TMP"
echo "Icons written to $ICONSET"

# Website artwork (docs/assets) uses the same drawings.
swiftc -O -target "$(uname -m)-apple-macos14.0" -o "${TMPDIR:-/tmp}/sitemaker" \
  Tools/IconMaker/main.swift DoodlePin/Model/DoodleType.swift DoodlePin/Doodles/*.swift
"${TMPDIR:-/tmp}/sitemaker" --site docs/assets
echo "Website art written to docs/assets"
