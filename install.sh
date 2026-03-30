#!/bin/bash
# Unified Installer for ASUS Fan Control
set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_error() { echo -e "${RED}[ERR]${NC} $1"; }

echo "========================================"
echo "      ASUS Fan Control - Installer     "
echo "========================================"
echo ""

# Check execution context
if [ "$EUID" -ne 0 ]; then
    print_error "This main installer must be run with sudo/root privileges."
    echo "Please run: sudo $0"
    exit 1
fi

TARGET_USER="${SUDO_USER:-$USER}"

# 1. Install Dependencies
print_info "Checking dependencies..."
if command -v pacman &>/dev/null; then
    pacman -S --needed --noconfirm lm_sensors rofi 2>/dev/null || true
elif command -v apt-get &>/dev/null; then
    apt-get update -y -qq && apt-get install -y -qq lm-sensors rofi || true
fi

# 2. Kernel Module
print_info "Configuring kernel module (nct6775)..."
if [ ! -f /etc/modules-load.d/nct6775.conf ]; then
    echo "nct6775" > /etc/modules-load.d/nct6775.conf
fi
modprobe nct6775 2>/dev/null || print_info "Module already loaded or busy."

# 3. Hardware Helper
print_info "Installing hardware detection helper..."
cp ./noctalia-plugin/asus-fanctrl-detect /usr/local/bin/asus-fanctrl-detect
chmod +x /usr/local/bin/asus-fanctrl-detect

# 4. Sudoers Configuration
print_info "Setting up sudoers permissions..."
if [ -f "./install_sudoers.sh" ]; then
    ./install_sudoers.sh
else
    print_error "install_sudoers.sh not found!"
fi

# 5. Noctalia Plugin
print_info "Setting up Noctalia Shell plugin..."
if [ -f "./install_noctalia_plugin.sh" ]; then
    ./install_noctalia_plugin.sh
else
    print_info "Skipping Noctalia plugin as install_noctalia_plugin.sh was not found."
fi

# 6. CLI Tools Installation
print_info "Installing CLI tools to /usr/local/bin..."
cp fan_control.sh smart_fan_daemon.sh fan_control_lib.sh /usr/local/bin/
chmod +x /usr/local/bin/fan_control.sh /usr/local/bin/smart_fan_daemon.sh

# 7. Systemd Service (Optional)
print_info "Setting up smart fan daemon service..."
if [ -f "smart-fan-daemon.service" ]; then
    cp smart-fan-daemon.service /etc/systemd/system/
    systemctl daemon-reload || true
    print_success "Service file installed. Use 'systemctl start smart-fan-daemon' to enable."
fi

echo ""
print_success "Unified installation complete!"
echo "You can now control your fans via CLI (fan_control.sh) or the Noctalia Shell plugin."
echo "If the plugin asks for a password, please restart your session or polkit."
