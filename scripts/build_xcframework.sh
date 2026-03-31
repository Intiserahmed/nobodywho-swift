#!/bin/bash
set -e

# Build XCFramework for NobodyWho Swift SDK
# This script builds the Rust uniffi crate for iOS and macOS, generates Swift bindings,
# and packages everything into an XCFramework.
#
# Usage:
#   ./build_xcframework.sh [OPTIONS]
#
# Options:
#   --debug                 Build debug instead of release
#   --skip-build            Skip cargo build, only recreate xcframework
#   --workspace DIR         Path to the nobodywho Cargo workspace
#                           (default: auto-detected relative to this script)
#   -h, --help              Show this help

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Auto-detect workspace: works both as submodule (../.. from swift/) and standalone (../nobodywho/nobodywho)
if [ -f "$SWIFT_DIR/../Cargo.toml" ] && grep -q "nobodywho-uniffi" "$SWIFT_DIR/../Cargo.toml" 2>/dev/null; then
    DEFAULT_WORKSPACE="$(cd "$SWIFT_DIR/.." && pwd)"
elif [ -f "$SWIFT_DIR/../nobodywho/nobodywho/Cargo.toml" ]; then
    DEFAULT_WORKSPACE="$(cd "$SWIFT_DIR/../nobodywho/nobodywho" && pwd)"
else
    DEFAULT_WORKSPACE="$(cd "$SWIFT_DIR/.." && pwd)"
fi

WORKSPACE_DIR="${NOBODYWHO_WORKSPACE:-$DEFAULT_WORKSPACE}"
UNIFFI_DIR="$WORKSPACE_DIR/uniffi"
TARGET_DIR="$WORKSPACE_DIR/target"
XCFRAMEWORK_OUTPUT="$SWIFT_DIR/NobodyWhoFFI.xcframework"
LIB_NAME="libnobodywho_uniffi"

# Parse arguments
BUILD_TYPE="release"
SKIP_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_TYPE="debug"
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --workspace)
            WORKSPACE_DIR="$2"
            UNIFFI_DIR="$WORKSPACE_DIR/uniffi"
            TARGET_DIR="$WORKSPACE_DIR/target"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --debug             Build debug instead of release"
            echo "  --skip-build        Skip cargo build, only recreate xcframework"
            echo "  --workspace DIR     Path to nobodywho Cargo workspace"
            echo "  -h, --help          Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

CARGO_PROFILE_FLAG=""
if [ "$BUILD_TYPE" = "release" ]; then
    CARGO_PROFILE_FLAG="--release"
fi

echo "========================================"
echo "Building NobodyWho Swift SDK"
echo "Build type:    $BUILD_TYPE"
echo "Workspace:     $WORKSPACE_DIR"
echo "========================================"

# Validate workspace
if [ ! -f "$WORKSPACE_DIR/Cargo.toml" ]; then
    echo "Error: Cargo workspace not found at $WORKSPACE_DIR"
    echo "  Set --workspace or NOBODYWHO_WORKSPACE to the nobodywho workspace directory."
    exit 1
fi

# Check for required tools
if ! command -v rustup &> /dev/null; then
    echo "Error: rustup not found. Please install Rust: https://rustup.rs"
    exit 1
fi
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: xcodebuild not found. Please install Xcode."
    exit 1
fi

# Ensure Apple targets are installed
echo ""
echo "Checking Rust targets..."
rustup target add \
    aarch64-apple-ios \
    aarch64-apple-ios-sim \
    x86_64-apple-ios \
    aarch64-apple-darwin \
    x86_64-apple-darwin \
    2>/dev/null || true

export IPHONEOS_DEPLOYMENT_TARGET=13.0
export MACOSX_DEPLOYMENT_TARGET=11.0

CARGO_MANIFEST="$WORKSPACE_DIR/Cargo.toml"

if [ "$SKIP_BUILD" = false ]; then
    echo ""
    echo "Building nobodywho-uniffi for all Apple targets..."

    echo "  [1/5] iOS device (aarch64-apple-ios)..."
    cargo build -p nobodywho-uniffi --target aarch64-apple-ios $CARGO_PROFILE_FLAG --manifest-path "$CARGO_MANIFEST"

    echo "  [2/5] iOS simulator arm64 (aarch64-apple-ios-sim)..."
    cargo build -p nobodywho-uniffi --target aarch64-apple-ios-sim $CARGO_PROFILE_FLAG --manifest-path "$CARGO_MANIFEST"

    echo "  [3/5] iOS simulator x86_64 (x86_64-apple-ios)..."
    cargo build -p nobodywho-uniffi --target x86_64-apple-ios $CARGO_PROFILE_FLAG --manifest-path "$CARGO_MANIFEST"

    echo "  [4/5] macOS arm64 (aarch64-apple-darwin)..."
    cargo build -p nobodywho-uniffi --target aarch64-apple-darwin $CARGO_PROFILE_FLAG --manifest-path "$CARGO_MANIFEST"

    echo "  [5/5] macOS x86_64 (x86_64-apple-darwin)..."
    cargo build -p nobodywho-uniffi --target x86_64-apple-darwin $CARGO_PROFILE_FLAG --manifest-path "$CARGO_MANIFEST"
else
    echo ""
    echo "Skipping cargo build (--skip-build flag)"
fi

echo ""
echo "Generating Swift bindings..."

mkdir -p "$SWIFT_DIR/Sources/NobodyWho/Generated"

cd "$WORKSPACE_DIR"
cargo run -p nobodywho-uniffi --bin uniffi-bindgen $CARGO_PROFILE_FLAG -- generate \
    --library "$TARGET_DIR/aarch64-apple-darwin/$BUILD_TYPE/${LIB_NAME}.dylib" \
    --language swift \
    --out-dir "$SWIFT_DIR/Sources/NobodyWho/Generated"
cd "$SWIFT_DIR"

echo "  Swift bindings written to Sources/NobodyWho/Generated/"

echo ""
echo "Creating frameworks..."

# Create universal simulator library (iOS)
mkdir -p "$TARGET_DIR/universal-ios-sim/$BUILD_TYPE"
lipo -create \
    "$TARGET_DIR/aarch64-apple-ios-sim/$BUILD_TYPE/${LIB_NAME}.dylib" \
    "$TARGET_DIR/x86_64-apple-ios/$BUILD_TYPE/${LIB_NAME}.dylib" \
    -output "$TARGET_DIR/universal-ios-sim/$BUILD_TYPE/${LIB_NAME}.dylib"

# Create universal macOS library
mkdir -p "$TARGET_DIR/universal-macos/$BUILD_TYPE"
lipo -create \
    "$TARGET_DIR/aarch64-apple-darwin/$BUILD_TYPE/${LIB_NAME}.dylib" \
    "$TARGET_DIR/x86_64-apple-darwin/$BUILD_TYPE/${LIB_NAME}.dylib" \
    -output "$TARGET_DIR/universal-macos/$BUILD_TYPE/${LIB_NAME}.dylib"

create_framework() {
    local FRAMEWORK_DIR="$1"
    local DYLIB_PATH="$2"
    local PLATFORM="$3"

    mkdir -p "$FRAMEWORK_DIR"

    if [ "$PLATFORM" = "macos" ]; then
        mkdir -p "$FRAMEWORK_DIR/Versions/A/Resources"
        mkdir -p "$FRAMEWORK_DIR/Versions/A/Headers"
        mkdir -p "$FRAMEWORK_DIR/Versions/A/Modules"
        cp "$DYLIB_PATH" "$FRAMEWORK_DIR/Versions/A/NobodyWhoFFI"
        install_name_tool -id @rpath/NobodyWhoFFI.framework/NobodyWhoFFI "$FRAMEWORK_DIR/Versions/A/NobodyWhoFFI"

        [ -f "$SWIFT_DIR/Sources/NobodyWho/Generated/nobodywhoFFI.h" ] && \
            cp "$SWIFT_DIR/Sources/NobodyWho/Generated/nobodywhoFFI.h" "$FRAMEWORK_DIR/Versions/A/Headers/"
        [ -f "$SWIFT_DIR/Sources/NobodyWho/Generated/nobodywhoFFI.modulemap" ] && \
            sed 's/^module nobodywhoFFI {/framework module nobodywhoFFI {/' \
                "$SWIFT_DIR/Sources/NobodyWho/Generated/nobodywhoFFI.modulemap" \
                > "$FRAMEWORK_DIR/Versions/A/Modules/module.modulemap"

        ln -sf A "$FRAMEWORK_DIR/Versions/Current"
        ln -sf Versions/Current/NobodyWhoFFI "$FRAMEWORK_DIR/NobodyWhoFFI"
        ln -sf Versions/Current/Resources "$FRAMEWORK_DIR/Resources"
        ln -sf Versions/Current/Headers "$FRAMEWORK_DIR/Headers"
        ln -sf Versions/Current/Modules "$FRAMEWORK_DIR/Modules"

        INFO_PLIST="$FRAMEWORK_DIR/Versions/A/Resources/Info.plist"
    else
        mkdir -p "$FRAMEWORK_DIR/Headers"
        mkdir -p "$FRAMEWORK_DIR/Modules"
        cp "$DYLIB_PATH" "$FRAMEWORK_DIR/NobodyWhoFFI"
        install_name_tool -id @rpath/NobodyWhoFFI.framework/NobodyWhoFFI "$FRAMEWORK_DIR/NobodyWhoFFI"

        [ -f "$SWIFT_DIR/Sources/NobodyWho/Generated/nobodywhoFFI.h" ] && \
            cp "$SWIFT_DIR/Sources/NobodyWho/Generated/nobodywhoFFI.h" "$FRAMEWORK_DIR/Headers/"
        [ -f "$SWIFT_DIR/Sources/NobodyWho/Generated/nobodywhoFFI.modulemap" ] && \
            sed 's/^module nobodywhoFFI {/framework module nobodywhoFFI {/' \
                "$SWIFT_DIR/Sources/NobodyWho/Generated/nobodywhoFFI.modulemap" \
                > "$FRAMEWORK_DIR/Modules/module.modulemap"

        INFO_PLIST="$FRAMEWORK_DIR/Info.plist"
    fi

    cat > "$INFO_PLIST" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>NobodyWhoFFI</string>
    <key>CFBundleIdentifier</key>
    <string>ooo.nobodywho.ffi</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>NobodyWhoFFI</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF
}

echo "  Creating iOS device framework..."
IOS_DEVICE_FRAMEWORK="$TARGET_DIR/aarch64-apple-ios/$BUILD_TYPE/NobodyWhoFFI.framework"
create_framework "$IOS_DEVICE_FRAMEWORK" "$TARGET_DIR/aarch64-apple-ios/$BUILD_TYPE/${LIB_NAME}.dylib" "ios"

echo "  Creating iOS simulator framework..."
IOS_SIM_FRAMEWORK="$TARGET_DIR/universal-ios-sim/$BUILD_TYPE/NobodyWhoFFI.framework"
create_framework "$IOS_SIM_FRAMEWORK" "$TARGET_DIR/universal-ios-sim/$BUILD_TYPE/${LIB_NAME}.dylib" "ios"

echo "  Creating macOS framework..."
MACOS_FRAMEWORK="$TARGET_DIR/universal-macos/$BUILD_TYPE/NobodyWhoFFI.framework"
create_framework "$MACOS_FRAMEWORK" "$TARGET_DIR/universal-macos/$BUILD_TYPE/${LIB_NAME}.dylib" "macos"

echo ""
echo "Creating XCFramework..."
rm -rf "$XCFRAMEWORK_OUTPUT"

xcodebuild -create-xcframework \
    -framework "$IOS_DEVICE_FRAMEWORK" \
    -framework "$IOS_SIM_FRAMEWORK" \
    -framework "$MACOS_FRAMEWORK" \
    -output "$XCFRAMEWORK_OUTPUT"

echo ""
echo "========================================"
echo "Build complete!"
echo "XCFramework: $XCFRAMEWORK_OUTPUT"
echo "========================================"
