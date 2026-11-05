#!/bin/sh
# Renders README images from the real ShelfView, from the project root.
set -e
cd "$(dirname "$0")/../.."
OUT="$(mktemp -d)"
swiftc -emit-module -emit-library -static -module-name ShakeCore -parse-as-library \
    -emit-module-path "$OUT/ShakeCore.swiftmodule" -o "$OUT/libShakeCore.a" Sources/ShakeCore/ShakeDetector.swift
swiftc -o "$OUT/render" -I "$OUT" -L "$OUT" -lShakeCore demo/screenshots/main.swift \
    Sources/ShakeShelf/ShelfView.swift Sources/ShakeShelf/Settings.swift \
    Sources/ShakeShelf/SettingsWindow.swift Sources/ShakeShelf/OnboardingWindow.swift \
    -framework AppKit -framework QuickLookThumbnailing -framework ServiceManagement
"$OUT/render" demo/screenshots/main.swift Sources/ShakeShelf/ShelfView.swift \
    -framework AppKit -framework QuickLookThumbnailing
"$OUT/render"
