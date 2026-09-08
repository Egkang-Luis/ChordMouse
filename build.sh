#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
rm -rf build/ChordMouse.app build/ModuleCache
mkdir -p build/ChordMouse.app/Contents/MacOS build/ModuleCache
xcrun swiftc -module-cache-path build/ModuleCache -swift-version 5 -O -target "$(uname -m)-apple-macosx13.0" Sources/*.swift -framework Cocoa -o build/ChordMouse.app/Contents/MacOS/ChordMouse
cp Info.plist build/ChordMouse.app/Contents/Info.plist
# Finder may add metadata to app folders stored in cloud-synced directories.
xattr -cr build/ChordMouse.app
codesign --force --sign - build/ChordMouse.app
codesign --verify --deep --strict build/ChordMouse.app
printf 'Built: %s/build/ChordMouse.app\n' "$PWD"
