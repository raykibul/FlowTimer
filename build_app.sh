#!/bin/bash
set -e

APP_NAME="FlowTimer"
BUNDLE_ID="com.flowtimer.app"
BUILD_DIR=".build/app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "==> Cleaning previous build..."
rm -rf "$BUILD_DIR"

echo "==> Building with Swift Package Manager (release)..."
swift build -c release 2>&1

echo "==> Creating app bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "==> Copying executable..."
cp ".build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"

echo "==> Copying sound resources..."
# Copy processed resources from SPM build
RESOURCE_BUNDLE=$(find .build/release -name "${APP_NAME}_${APP_NAME}.bundle" -type d 2>/dev/null | head -1)
if [ -n "$RESOURCE_BUNDLE" ]; then
    echo "    Found SPM resource bundle: $RESOURCE_BUNDLE"
    cp -R "$RESOURCE_BUNDLE" "$RESOURCES_DIR/"
fi

# Also copy raw sound files as fallback
mkdir -p "$RESOURCES_DIR/Sounds"
cp Resources/Sounds/*.mp3 "$RESOURCES_DIR/Sounds/" 2>/dev/null || true

echo "==> Copying entitlements..."
cp FlowTimer.entitlements "$CONTENTS/Entitlements.plist"

echo "==> Generating Info.plist..."
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>FlowTimer</string>
    <key>CFBundleDisplayName</key>
    <string>Flow Timer</string>
    <key>CFBundleIdentifier</key>
    <string>com.flowtimer.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>FlowTimer</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
</dict>
</plist>
PLIST

echo "==> Copying asset catalog (if xcrun actool available)..."
if command -v xcrun &> /dev/null && [ -d "Resources/Assets.xcassets" ]; then
    xcrun actool Resources/Assets.xcassets \
        --compile "$RESOURCES_DIR" \
        --platform macosx \
        --minimum-deployment-target 14.0 \
        --app-icon AppIcon \
        --accent-color AccentColor \
        --output-partial-info-plist /dev/null 2>/dev/null || echo "    (asset catalog compilation skipped — non-critical)"
fi

echo ""
echo "==> Build complete!"
echo "    App bundle: $APP_BUNDLE"
echo ""
echo "==> To install, run:"
echo "    cp -R \"$APP_BUNDLE\" /Applications/"
echo ""
echo "==> Or open it directly:"
echo "    open \"$APP_BUNDLE\""
