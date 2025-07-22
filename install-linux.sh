#!/bin/bash
# Yall Installation Script for Linux

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Installing Yall - Multi-Platform Social Media Poster${NC}"
echo "=================================================="

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "${RED}❌ This installer is designed for Linux systems only${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${BLUE}📁 Creating directories...${NC}"
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/share/icons

# Copy the executable
echo -e "${BLUE}📦 Installing executable...${NC}"
if [ -f "build/linux/x64/release/bundle/yall" ]; then
    cp -r build/linux/x64/release/bundle/* ~/.local/bin/
    chmod +x ~/.local/bin/yall
    echo -e "${GREEN}✅ Executable installed to ~/.local/bin/yall${NC}"
else
    echo -e "${RED}❌ Build not found. Please run 'flutter build linux' first${NC}"
    exit 1
fi

# Install desktop file
echo -e "${BLUE}🖥️  Installing desktop integration...${NC}"
cp linux/yall.desktop ~/.local/share/applications/
echo -e "${GREEN}✅ Desktop file installed${NC}"

# Install icon in proper freedesktop.org structure
echo -e "${BLUE}🎨 Installing application icon...${NC}"
mkdir -p ~/.local/share/icons/hicolor/{48x48,64x64,128x128,256x256,512x512}/apps

# Create different sizes
if command -v convert &> /dev/null; then
    convert assets/icons/app_icon.png -resize 48x48 ~/.local/share/icons/hicolor/48x48/apps/yall.png
    convert assets/icons/app_icon.png -resize 64x64 ~/.local/share/icons/hicolor/64x64/apps/yall.png
    convert assets/icons/app_icon.png -resize 128x128 ~/.local/share/icons/hicolor/128x128/apps/yall.png
    convert assets/icons/app_icon.png -resize 256x256 ~/.local/share/icons/hicolor/256x256/apps/yall.png
    cp assets/icons/app_icon.png ~/.local/share/icons/hicolor/512x512/apps/yall.png
    echo -e "${GREEN}✅ Icon installed in multiple sizes${NC}"
else
    # Fallback: just copy the original size
    cp assets/icons/app_icon.png ~/.local/share/icons/hicolor/512x512/apps/yall.png
    echo -e "${YELLOW}⚠️  ImageMagick not found, installed original size only${NC}"
fi

# Also install in legacy location for compatibility
cp assets/icons/app_icon.png ~/.local/share/icons/yall.png

# Update icon cache
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache ~/.local/share/icons/hicolor/ 2>/dev/null || true
    echo -e "${GREEN}✅ Icon cache updated${NC}"
fi

# Update desktop database
echo -e "${BLUE}🔄 Updating desktop database...${NC}"
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database ~/.local/share/applications/
    echo -e "${GREEN}✅ Desktop database updated${NC}"
else
    echo -e "${YELLOW}⚠️  update-desktop-database not found, but installation should still work${NC}"
fi

# Add to PATH if needed
echo -e "${BLUE}🛤️  Checking PATH...${NC}"
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${YELLOW}⚠️  ~/.local/bin is not in your PATH${NC}"
    echo "   Add the following to your ~/.bashrc or ~/.zshrc:"
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
else
    echo -e "${GREEN}✅ ~/.local/bin is already in PATH${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Installation complete!${NC}"
echo "=================================================="
echo -e "${BLUE}You can now:${NC}"
echo "• Find 'Yall' in your applications menu"
echo "• Pin it to your dock/taskbar"
echo "• Run it from terminal with: yall"
echo ""
echo -e "${BLUE}To uninstall:${NC}"
echo "• Remove ~/.local/bin/yall"
echo "• Remove ~/.local/share/applications/yall.desktop"
echo "• Remove ~/.local/share/icons/yall.png"
echo "• Remove ~/.local/share/icons/hicolor/*/apps/yall.png"
