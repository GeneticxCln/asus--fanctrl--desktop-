#!/bin/bash
# ASUS Fan Control - Noctalia Shell Plugin Installer (Manual Guide)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$HOME/.config/noctalia/plugins/asus-fan-control"
USERNAME=$(whoami)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "  ASUS Fan Control - Noctalia Plugin   "
echo "========================================"
echo ""
echo "This script will guide you through the manual installation."
echo ""

# Step 1: Check Noctalia
echo -e "${BLUE}[Step 1/5]${NC} Checking Noctalia Shell..."
if command -v qs > /dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} Noctalia Shell found"
else
    echo "Please install Noctalia Shell first:"
    echo "  yay -S noctalia-shell"
    exit 1
fi

# Step 2: Check sensors
echo -e "${BLUE}[Step 2/5]${NC} Checking lm_sensors..."
if command -v sensors > /dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} lm_sensors is installed"
else
    echo "Install with: sudo pacman -S lm_sensors"
    exit 1
fi

# Step 3: Load kernel module
echo -e "${BLUE}[Step 3/5]${NC} Loading nct6775 kernel module..."
echo "Run this command:"
echo "  ${GREEN}sudo modprobe nct6775${NC}"
echo ""
echo -n "Have you loaded the module? [y/N]: "
read -r loaded
if [ "$loaded" != "y" ] && [ "$loaded" != "Y" ]; then
    echo "Please load the module first, then run this script again."
    exit 0
fi

# Step 4: Install polkit rule
echo -e "${BLUE}[Step 4/5]${NC} Installing polkit rule..."
echo "Run these commands:"
echo "  ${GREEN}sudo mkdir -p /etc/polkit-1/rules.d${NC}"
echo "  ${GREEN}sudo cp $SCRIPT_DIR/noctalia-plugin/50-asus-fanctrl.rules /etc/polkit-1/rules.d/${NC}"
echo "  ${GREEN}sudo chown root:root /etc/polkit-1/rules.d/50-asus-fanctrl.rules${NC}"
echo "  ${GREEN}sudo chmod 644 /etc/polkit-1/rules.d/50-asus-fanctrl.rules${NC}"
echo ""
echo -n "Have you installed the polkit rule? [y/N]: "
read -r polkit_done
if [ "$polkit_done" != "y" ] && [ "$polkit_done" != "Y" ]; then
    echo "Please install the polkit rule first."
    exit 0
fi

# Step 5: Install plugin
echo -e "${BLUE}[Step 5/5]${NC} Installing plugin..."
mkdir -p "$PLUGIN_DIR"
cp -r "$SCRIPT_DIR/noctalia-plugin/"* "$PLUGIN_DIR/"
chmod -R 755 "$PLUGIN_DIR"
echo -e "${GREEN}[OK]${NC} Plugin installed to $PLUGIN_DIR"

echo ""
echo "========================================"
echo "        Installation Complete!          "
echo "========================================"
echo ""
echo "Now reload Noctalia Shell:"
echo "  ${GREEN}qs -c noctalia-shell reload${NC}"
echo ""
echo "Or restart the shell completely."
echo ""
echo "After reload, you should see a fan icon in your bar!"
echo ""
