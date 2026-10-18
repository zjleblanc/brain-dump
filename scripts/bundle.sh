#!/usr/bin/env bash
# bundle.sh — Build a Todos.app bundle from Swift Package Manager
# Usage:
#   ./scripts/bundle.sh          # debug build (fast, for local testing)
#   ./scripts/bundle.sh release  # release build (optimised, for distribution)
#
# The resulting Todos.app is placed in the project root.
# To run it: open Todos.app
# To sign it (requires Apple Developer ID):
#   ./scripts/bundle.sh release sign "Developer ID Application: Your Name (TEAMID)"
#
# Versioning:
#   The app version is the single source of truth from the git tag that
#   triggers a release (see .github/workflows/release.yml), passed in via
#   the VERSION environment variable, e.g.:
#     VERSION=1.2.0 ./scripts/bundle.sh release
#   When VERSION is unset (local dev builds), it falls back to "0.0.0-dev".

set -euo pipefail

# Fix SwiftBuild framework search paths for Command Line Tools installs
# (prevents "search path not found" linker warnings when Xcode.app is absent).
export DEVELOPER_DIR=/Library/Developer/CommandLineTools

BUILD_CONFIG="${1:-debug}"
SIGN_IDENTITY="${3:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="Todos"
BUNDLE="$REPO_ROOT/$APP_NAME.app"

# VERSION (CFBundleShortVersionString) — the user-facing version string.
# Falls back to a dev placeholder when not supplied by CI/a tagged build.
VERSION="${VERSION:-0.0.0-dev}"

# CFBundleVersion (build version) must contain only digits and periods.
# Derive it from VERSION by stripping any pre-release/build suffix
# (e.g. "1.2.0-dev" -> "1.2.0").
BUNDLE_VERSION="$(printf '%s' "$VERSION" | sed -E 's/[^0-9.].*$//')"
BUNDLE_VERSION="${BUNDLE_VERSION:-0.0.0}"

echo "▶ Building ($BUILD_CONFIG) — version ${VERSION}…"
cd "$REPO_ROOT"

if [ "$BUILD_CONFIG" = "release" ]; then
    swift build -c release 2>&1
    BINARY=".build/release/$APP_NAME"
else
    swift build 2>&1
    BINARY=".build/debug/$APP_NAME"
fi

echo "▶ Assembling $APP_NAME.app…"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY" "$BUNDLE/Contents/MacOS/$APP_NAME"

# Copy app icon (if present)
ICON_SRC="$REPO_ROOT/Sources/Todos/Resources/AppIcon.icns"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Write Info.plist
# LSUIElement=YES hides the Dock icon — essential for a menubar-only app.
cat > "$BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.todos.app</string>
    <key>CFBundleVersion</key>
    <string>$BUNDLE_VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>© 2026</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Write PkgInfo (required for macOS to recognise .app bundles)
printf "APPL????" > "$BUNDLE/Contents/PkgInfo"

echo "▶ Done: $BUNDLE"

# Optional codesign
if [ -n "$SIGN_IDENTITY" ]; then
    echo "▶ Signing with: $SIGN_IDENTITY"
    codesign \
        --force \
        --deep \
        --sign "$SIGN_IDENTITY" \
        --options runtime \
        "$BUNDLE"
    echo "▶ Signed."
    echo ""
    echo "To notarise (requires xcrun notarytool credentials):"
    echo "  ditto -c -k --keepParent Todos.app Todos.zip"
    echo "  xcrun notarytool submit Todos.zip --keychain-profile <profile> --wait"
    echo "  xcrun stapler staple Todos.app"
fi

echo ""
echo "Run the app:"
echo "  open Todos.app"
echo ""
echo "Or for a DMG (requires create-dmg):"
echo "  brew install create-dmg"
echo "  create-dmg --app-drop-link 400 150 Todos.dmg Todos.app"
