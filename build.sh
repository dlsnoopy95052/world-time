#!/usr/bin/env bash
# Builds "build/World Time.app". Pass --install to copy it to /Applications (shows in Launchpad) and launch it.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/World Time.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Work around a broken Command Line Tools install: a stale usr/include/swift/module.modulemap
# from an older CLT redefines SwiftBridging and breaks every Swift build. Mask it with an
# empty file via a VFS overlay (the permanent fix is to delete that file with sudo).
EXTRA_FLAGS=()
STALE_MAP="$(xcode-select -p)/usr/include/swift/module.modulemap"
if [[ -f "$STALE_MAP" && -f "$(dirname "$STALE_MAP")/bridging.modulemap" ]]; then
    : > build/empty.modulemap
    cat > build/vfs-overlay.yaml <<YAML
{ "version": 0, "roots": [ { "type": "file", "name": "$STALE_MAP", "external-contents": "$PWD/build/empty.modulemap" } ] }
YAML
    EXTRA_FLAGS+=(-vfsoverlay build/vfs-overlay.yaml -Xcc -ivfsoverlay -Xcc build/vfs-overlay.yaml)
fi

SWIFTC=(swiftc ${EXTRA_FLAGS[@]+"${EXTRA_FLAGS[@]}"} -sdk "$(xcrun --show-sdk-path --sdk macosx)")

# App icon, drawn by scripts/make_icon.swift.
if [[ ! -f build/AppIcon.icns || scripts/make_icon.swift -nt build/AppIcon.icns ]]; then
    "${SWIFTC[@]}" -O -o build/make_icon scripts/make_icon.swift
    rm -rf build/AppIcon.iconset
    build/make_icon build/AppIcon.iconset
    iconutil -c icns -o build/AppIcon.icns build/AppIcon.iconset
fi
cp build/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

"${SWIFTC[@]}" -O -parse-as-library \
    -target "$(uname -m)-apple-macos14.0" \
    -o "$APP/Contents/MacOS/WorldTime" \
    Sources/WorldTime/*.swift

cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x WorldTime 2>/dev/null || true
    rm -rf "/Applications/WorldTime.app" "/Applications/World Time.app"
    cp -R "$APP" /Applications/
    # Register with Launch Services so Launchpad and Spotlight pick up the app and its icon.
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/World Time.app"
    open "/Applications/World Time.app"
    echo "Installed to /Applications/World Time.app"
fi
