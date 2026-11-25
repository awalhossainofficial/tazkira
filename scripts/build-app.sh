#!/bin/sh
# Builds Zikr.app into build/ from the Swift package, ad-hoc signed.
# --universal builds for both Apple-chip and Intel Macs, for a download.
set -e
cd "$(dirname "$0")/.."
if [ "$1" = "--universal" ]; then
  for ARCH in arm64 x86_64; do
    swift build -c release --product Zikr --triple "$ARCH-apple-macosx14.0"
  done
  BIN=.build/Zikr-universal
  lipo -create -output "$BIN" .build/arm64-apple-macosx/release/Zikr .build/x86_64-apple-macosx/release/Zikr
else
  swift build -c release --product Zikr --triple "$(uname -m)-apple-macosx14.0"
  BIN=".build/$(uname -m)-apple-macosx/release/Zikr"
fi
APP=build/Zikr.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Zikr"
if [ -d Resources/Fonts ]; then cp Resources/Fonts/* "$APP/Contents/Resources/"; fi
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Zikr</string>
  <key>CFBundleDisplayName</key><string>Zikr</string>
  <key>CFBundleIdentifier</key><string>app.zikr.mac</string>
  <key>CFBundleExecutable</key><string>Zikr</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
codesign --force --deep --sign - "$APP"
echo "Built $APP"
