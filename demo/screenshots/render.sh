#!/bin/sh
# Renders the settings window image for the README, from the project root.
set -e
cd "$(dirname "$0")/../.."
OUT="$(mktemp -d)"
swiftc -emit-module -emit-library -static -module-name ShakeCore -parse-as-library \
    -emit-module-path "$OUT/ShakeCore.swiftmodule" -o "$OUT/libShakeCore.a" Sources/ShakeCore/ShakeDetector.swift
swiftc -o "$OUT/render" -I "$OUT" -L "$OUT" -lShakeCore demo/screenshots/main.swift \
    Sources/ShakeShelf/Settings.swift Sources/ShakeShelf/SettingsWindow.swift \
    -framework AppKit -framework ServiceManagement
"$OUT/render"
