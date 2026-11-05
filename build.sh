#!/bin/sh
# Builds ShakeShelf.app in the project root.
set -e
cd "$(dirname "$0")"

swift build -c release

APP=ShakeShelf.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/ShakeShelf "$APP/Contents/MacOS/ShakeShelf"
mkdir -p "$APP/Contents/Resources"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>com.vyke.ShakeShelf</string>
    <key>CFBundleName</key><string>ShakeShelf</string>
    <key>CFBundleExecutable</key><string>ShakeShelf</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"
