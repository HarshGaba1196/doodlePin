#!/bin/zsh
# Quick development build without Xcode: compiles everything into build/DoodlePin.app.
# For App Store builds, open DoodlePin.xcodeproj in Xcode instead.
set -e
cd "$(dirname "$0")"
APP=build/DoodlePin.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

SOURCES=($(find DoodlePin -name '*.swift'))
if [[ "$UNIVERSAL" == "1" ]]; then
  # Apple Silicon + Intel in one binary, for distribution.
  TMPBIN=$(mktemp -d)
  swiftc -O -target arm64-apple-macos14.0 -o "$TMPBIN/arm64" $SOURCES
  swiftc -O -target x86_64-apple-macos14.0 -o "$TMPBIN/x86_64" $SOURCES
  lipo -create "$TMPBIN/arm64" "$TMPBIN/x86_64" -output "$APP/Contents/MacOS/DoodlePin"
  rm -rf "$TMPBIN"
else
  swiftc -O -target "$(uname -m)-apple-macos14.0" -o "$APP/Contents/MacOS/DoodlePin" $SOURCES
fi

# App icon
ICONSET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET"
cp DoodlePin/Assets.xcassets/AppIcon.appiconset/*.png "$ICONSET/"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
cp DoodlePin/PrivacyInfo.xcprivacy "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>DoodlePin</string>
  <key>CFBundleDisplayName</key><string>DoodlePin</string>
  <key>CFBundleIdentifier</key><string>com.harshgaba.DoodlePin</string>
  <key>CFBundleExecutable</key><string>DoodlePin</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSCalendarsFullAccessUsageDescription</key><string>DoodlePin's pets can remind you shortly before your meetings start. Your calendar never leaves your Mac.</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "Built $(pwd)/$APP"
