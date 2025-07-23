#!/bin/bash

# YaLL Release Build Script
# Builds packages for Linux distribution

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.2"
    exit 1
fi

echo "Building YaLL version $VERSION..."

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean
flutter pub get

# Run tests
echo "Running tests..."
flutter test

# Build for Linux
echo "Building Linux application..."
flutter build linux --release

# Create release directory
RELEASE_DIR="releases/v$VERSION"
mkdir -p "$RELEASE_DIR"

# Copy built application
echo "Creating release package..."
cp -r build/linux/x64/release/bundle "$RELEASE_DIR/yall-$VERSION-linux-x64"

# Create archive
cd "$RELEASE_DIR"
tar -czf "yall-$VERSION-linux-x64.tar.gz" "yall-$VERSION-linux-x64"

echo "Release $VERSION built successfully!"
echo "Location: $RELEASE_DIR"
echo "Archive: $RELEASE_DIR/yall-$VERSION-linux-x64.tar.gz"
