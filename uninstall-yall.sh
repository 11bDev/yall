#!/bin/bash

# Uninstall script for Yall

echo "Uninstalling Yall..."

# Remove the installed files
sudo rm -rf /usr/local/share/yall
sudo rm -f /usr/local/bin/yall
sudo rm -f /usr/share/applications/yall.desktop

# Update desktop database
sudo update-desktop-database

echo "Yall has been uninstalled successfully."
echo "Note: User data and settings are preserved in ~/.local/share/yall/"
