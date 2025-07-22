#!/bin/bash
# Yall Uninstaller Script for Linux

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🗑️  Uninstalling Yall${NC}"
echo "=========================="

# Kill any running instances
echo -e "${BLUE}🔄 Stopping running instances...${NC}"
pkill -f "yall" || true

# Remove files
echo -e "${BLUE}🗃️  Removing files...${NC}"

if [ -d ~/.local/bin ] && ls ~/.local/bin/yall* 1> /dev/null 2>&1; then
    rm -rf ~/.local/bin/yall*
    echo -e "${GREEN}✅ Removed executable${NC}"
fi

if [ -f ~/.local/share/applications/yall.desktop ]; then
    rm ~/.local/share/applications/yall.desktop
    echo -e "${GREEN}✅ Removed desktop file${NC}"
fi

if [ -f ~/.local/share/icons/yall.png ]; then
    rm ~/.local/share/icons/yall.png
    echo -e "${GREEN}✅ Removed icon${NC}"
fi

# Update desktop database
echo -e "${BLUE}🔄 Updating desktop database...${NC}"
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database ~/.local/share/applications/
    echo -e "${GREEN}✅ Desktop database updated${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Yall has been completely removed${NC}"
echo ""
echo -e "${BLUE}Note: User settings and credentials remain in:${NC}"
echo "~/.local/share/flutter_secure_storage/"
echo ""
echo -e "${BLUE}To remove all user data:${NC}"
echo "rm -rf ~/.local/share/flutter_secure_storage/"
