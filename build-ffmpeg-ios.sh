#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Initial Setup and Error Checking ---
# Check if Xcode command-line tools are configured
if ! xcode-select -p &> /dev/null; then
    echo "Xcode command-line tools are not configured. Please run 'sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer'."
    exit 1
fi

# Check for required SDK
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
if [ ! -d "$SDK_PATH" ]; then
    echo "iOS SDK not found. Please ensure Xcode is fully installed and up to date."
    exit 1
fi

# Define the build parameters
ARCH="arm64"
PLATFORM="iPhoneOS"
SDK=$(xcrun --sdk $PLATFORM --show-sdk-path)
CC=$(xcrun --sdk $PLATFORM --find clang)

# --- Build Process ---
# Navigate to the FFmpeg source directory
# CORRECTED PATH: Use 'thirdparty/ffmpeg'
if [ ! -d "thirdparty/ffmpeg" ]; then
    echo "FFmpeg submodule not found. Please run 'git submodule update --init' in the project's root directory."
    exit 1
fi
cd "thirdparty/ffmpeg"

# Clean any previous builds
make clean

# Configure FFmpeg for iOS
./configure \
    --prefix="$(pwd)/ios/$ARCH" \
    --enable-cross-compile \
    --disable-programs \
    --disable-doc \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-asm \
    --enable-shared \
    --target-os=darwin \
    --arch=$ARCH \
    --cc=$CC \
    --extra-cflags="-arch $ARCH -fembed-bitcode -mios-version-min=12.0" \
    --extra-ldflags="-arch $ARCH -fembed-bitcode -mios-version-min=12.0" \
    --sysroot=$SDK \
    --disable-x86asm \
    --disable-neon \
    --disable-stripping

# Build and install the libraries
make -j$(sysctl -n hw.ncpu)
make install

echo "FFmpeg libraries for iOS have been successfully built and installed to: $(pwd)/ios/$ARCH"