#!/bin/bash

# Script untuk build Aplikasi Kasir Sederhana dalam mode Release
# Usage: ./build_release.sh [platform]
# Platforms: android, ios, web, windows, linux, macos, all

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default platform
PLATFORM=${1:-all}

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Aplikasi Kasir Sederhana            ║${NC}"
echo -e "${BLUE}║   Release Build Script                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Fungsi untuk build Android
build_android() {
    echo -e "${YELLOW}📱 Building for Android (Release)...${NC}"
    flutter build apk --release
    flutter build appbundle --release
    echo -e "${GREEN}✓ Android build complete!${NC}"
    echo "  APK: build/app/outputs/flutter-apk/app-release.apk"
    echo "  AAB: build/app/outputs/bundle/release/app-release.aab"
    echo ""
}

# Fungsi untuk build iOS
build_ios() {
    echo -e "${YELLOW}🍎 Building for iOS (Release)...${NC}"
    flutter build ios --release
    echo -e "${GREEN}✓ iOS build complete!${NC}"
    echo "  Output: build/ios/iphoneos/"
    echo ""
}

# Fungsi untuk build Web
build_web() {
    echo -e "${YELLOW}🌐 Building for Web (Release)...${NC}"
    flutter build web --release
    echo -e "${GREEN}✓ Web build complete!${NC}"
    echo "  Output: build/web/"
    echo ""
}

# Fungsi untuk build Windows
build_windows() {
    echo -e "${YELLOW}🪟 Building for Windows (Release)...${NC}"
    flutter build windows --release
    echo -e "${GREEN}✓ Windows build complete!${NC}"
    echo "  Output: build/windows/runner/Release/"
    echo ""
}

# Fungsi untuk build Linux
build_linux() {
    echo -e "${YELLOW}🐧 Building for Linux (Release)...${NC}"
    flutter build linux --release
    echo -e "${GREEN}✓ Linux build complete!${NC}"
    echo "  Output: build/linux/x64/release/bundle/"
    echo ""
}

# Fungsi untuk build macOS
build_macos() {
    echo -e "${YELLOW}🖥️  Building for macOS (Release)...${NC}"
    flutter build macos --release
    echo -e "${GREEN}✓ macOS build complete!${NC}"
    echo "  Output: build/macos/Build/Products/Release/"
    echo ""
}

# Jalankan build sesuai platform
case $PLATFORM in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    web)
        build_web
        ;;
    windows)
        build_windows
        ;;
    linux)
        build_linux
        ;;
    macos)
        build_macos
        ;;
    all)
        echo -e "${YELLOW}Building for all platforms...${NC}"
        echo ""
        build_android
        build_web
        build_windows
        build_linux
        echo -e "${GREEN}✓ All builds complete!${NC}"
        ;;
    *)
        echo "Platform tidak dikenal: $PLATFORM"
        echo ""
        echo "Gunakan: ./build_release.sh [platform]"
        echo "Platforms: android, ios, web, windows, linux, macos, all"
        exit 1
        ;;
esac

echo -e "${BLUE}Build process finished!${NC}"
