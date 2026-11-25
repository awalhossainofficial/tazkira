#!/bin/sh
# Builds Tazkira.app into build/ from the Swift package, ad-hoc signed.
# --universal builds for both Apple-chip and Intel Macs, for a download.
set -e
cd "$(dirname "$0")/.."
if [ "$1" = "--universal" ]; then
  for ARCH in arm64 x86_64; do
    swift build -c release --product Tazkira --triple "$ARCH-apple-macosx14.0"
  done
  BIN=.build/Tazkira-universal
  lipo -create -output "$BIN" .build/arm64-apple-macosx/release/Tazkira .build/x86_64-apple-macosx/release/Tazkira
else
  swift build -c release --product Tazkira --triple "$(uname -m)-apple-macosx14.0"
  BIN=".build/$(uname -m)-apple-macosx/release/Tazkira"
fi
APP=build/Tazkira.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Tazkira"
if [ -d Resources/Fonts ]; then cp Resources/Fonts/* "$APP/Contents/Resources/"; fi
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Tazkira</string>
  <key>CFBundleDisplayName</key><string>Tazkira</string>
  <key>CFBundleIdentifier</key><string>app.tazkira.mac</string>
  <key>CFBundleExecutable</key><string>Tazkira</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.1</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
codesign --force --deep --sign - "$APP"
echo "Built $APP"
