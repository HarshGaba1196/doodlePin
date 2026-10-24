#!/bin/zsh
# Builds a universal DoodlePin.app and packages it for download:
#   dist/DoodlePin.zip   – app + install.sh + READ ME.txt
#   docs/install.sh      – the same installer, for the website's one-line install
set -e
cd "$(dirname "$0")/.."
VERSION=$(grep -m1 "MARKETING_VERSION" DoodlePin.xcodeproj/project.pbxproj | sed -E 's/.*= ([0-9.]+);/\1/')

UNIVERSAL=1 ./build.sh

STAGE=$(mktemp -d)/DoodlePin
mkdir -p "$STAGE"
ditto build/DoodlePin.app "$STAGE/DoodlePin.app"
cp scripts/install.sh "$STAGE/install.sh"
chmod +x "$STAGE/install.sh"
cat > "$STAGE/READ ME.txt" <<TXT
DoodlePin $VERSION – tiny doodle pets for your Mac desktop

TO INSTALL
  1. Open Terminal (Applications → Utilities → Terminal).
  2. Type "bash " (with a space), drag install.sh from this folder into the
     Terminal window, and press Return.

  The installer copies DoodlePin to your Applications folder and opens it.
  Look for the blob face in your menu bar.

TO UNINSTALL
  bash install.sh --uninstall           (keeps your pets)
  bash install.sh --uninstall --purge   (removes everything)

Needs macOS 14 Sonoma or later. Works on Apple Silicon and Intel Macs.
DoodlePin collects no data and never connects to the internet.
TXT

mkdir -p dist
rm -f dist/DoodlePin.zip
(cd "$(dirname "$STAGE")" && ditto -c -k --sequesterRsrc --keepParent DoodlePin "$OLDPWD/dist/DoodlePin.zip")
cp scripts/install.sh docs/install.sh
rm -rf "$(dirname "$STAGE")"

echo "Version $VERSION"
lipo -info build/DoodlePin.app/Contents/MacOS/DoodlePin
ls -lh dist/DoodlePin.zip
