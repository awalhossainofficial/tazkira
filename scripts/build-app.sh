#!/bin/sh
# Builds Zikr.app into build/ from the Swift package, ad-hoc signed for local use.
set -e
cd "$(dirname "$0")/.."
swift build -c release --product Zikr
APP=build/Zikr.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Zikr "$APP/Contents/MacOS/Zikr"
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
