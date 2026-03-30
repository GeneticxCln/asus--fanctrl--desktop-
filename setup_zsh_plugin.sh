#!/bin/bash

# ASUS Fan Control - Zsh Plugin Setup Script
# This script sets up the fan control plugin for zsh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME=$(whoami)
ZSHRC="$HOME/.zshrc"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

echo "╭──────────────────────────────────────────────╮"
echo "│   ASUS Fan Control - Zsh Plugin Installer   │"
echo "╰──────────────────────────────────────────────╯"
echo ""

# Step 1: Check dependencies
print_status "Checking dependencies..."
if command -v lm_sensors &> /dev/null || command -v sensors &> /dev/null; then
    print_success "lm_sensors is installed"
else
    print_warning "lm_sensors not found"
    read -p "Install lm_sensors? [Y/n]: " install_sensors
    if [ "$install_sensors" != "n" ] && [ "$install_sensors" != "N" ]; then
        sudo pacman -S lm_sensors
        print_success "lm_sensors installed"
    fi
fi

if command -v rofi &> /dev/null; then
    print_success "Rofi is installed (GUI support enabled)"
else
    print_warning "Rofi not found (GUI will be disabled)"
    read -p "Install rofi for GUI support? [Y/n]: " install_rofi
    if [ "$install_rofi" != "n" ] && [ "$install_rofi" != "N" ]; then
        sudo pacman -S rofi
        print_success "Rofi installed"
    fi
fi

# Step 2: Load kernel module
print_status "Checking hardware detection..."
if ls /sys/class/hwmon/hwmon*/name 2>/dev/null | xargs grep -q "nct6798\|nct6775" 2>/dev/null; then
    print_success "NCT6775/NCT6798 chip detected"
else
    print_warning "Chip not detected, loading nct6775 module..."
    sudo modprobe nct6775
    sleep 2
    if ls /sys/class/hwmon/hwmon*/name 2>/dev/null | xargs grep -q "nct6798\|nct6775" 2>/dev/null; then
        print_success "NCT6775/NCT6798 chip detected after loading module"
    else
        print_error "Hardware not detected. Your motherboard may not be supported."
        echo "Continue anyway? (You can configure manually later)"
        read -p "Continue? [y/N]: " continue_install
        if [ "$continue_install" != "y" ] && [ "$continue_install" != "Y" ]; then
            exit 1
        fi
    fi
fi

# Step 3: Configure sudoers
print_status "Configuring passwordless sudo for fan control..."
SUDOERS_FILE="/etc/sudoers.d/fanctrl"

# Create sudoers content
sudoers_content="# ASUS Fan Control - Passwordless Sudo Configuration
# Generated for user: $USERNAME

$USERNAME ALL=(root) NOPASSWD: /usr/bin/tee /sys/class/hwmon/hwmon*/pwm*_enable
$USERNAME ALL=(root) NOPASSWD: /usr/bin/tee /sys/class/hwmon/hwmon*/pwm*
$USERNAME ALL=(root) NOPASSWD: /usr/bin/tee /sys/devices/platform/nct6775.*/hwmon/hwmon*/pwm*_enable
$USERNAME ALL=(root) NOPASSWD: /usr/bin/tee /sys/devices/platform/nct6775.*/hwmon/hwmon*/pwm*"

# Create temporary file and install
temp_file=$(mktemp)
echo "$sudoers_content" > "$temp_file"

sudo cp "$temp_file" "$SUDOERS_FILE"
sudo chmod 0440 "$SUDOERS_FILE"
sudo chown root:root "$SUDOERS_FILE"

# Validate sudoers file
if sudo visudo -c -f "$SUDOERS_FILE" 2>/dev/null; then
    print_success "Sudoers configuration installed"
else
    print_error "Invalid sudoers configuration!"
    sudo rm -f "$SUDOERS_FILE"
    rm -f "$temp_file"
    exit 1
fi
rm -f "$temp_file"

# Test sudo access
print_status "Testing sudo access..."
pwm_path=$(find /sys/class/hwmon/ -name "hwmon*" -exec sh -c 'if [ -f "$1/name" ] && grep -q "nct6798\|nct6775" "$1/name" 2>/dev/null; then echo "$1"; fi' _ {} \; | head -1)
if [ -n "$pwm_path" ]; then
    if echo 1 | sudo tee "${pwm_path}/pwm1_enable" > /dev/null 2>&1; then
        echo 5 | sudo tee "${pwm_path}/pwm1_enable" > /dev/null 2>&1
        print_success "Sudo access verified"
    else
        print_warning "Sudo access test failed (you may need to troubleshoot manually)"
    fi
fi

# Step 4: Add plugin to zshrc
print_status "Adding plugin to .zshrc..."

# Check if already configured
if grep -q "fan_control_zsh_plugin.zsh" "$ZSHRC" 2>/dev/null; then
    print_warning "Plugin already configured in .zshrc"
else
    # Add to zshrc
    cat >> "$ZSHRC" << EOF

# ASUS Fan Control Plugin
# Source fan control plugin
if [ -f "$SCRIPT_DIR/fan_control_zsh_plugin.zsh" ]; then
    source "$SCRIPT_DIR/fan_control_zsh_plugin.zsh"
fi
EOF
    print_success "Plugin added to .zshrc"
fi

# Step 5: Configure module auto-loading
print_status "Configuring nct6775 module for auto-load..."
MODULES_FILE="/etc/modules-load.d/nct6775.conf"
if [ -f "$MODULES_FILE" ] && grep -q "nct6775" "$MODULES_FILE" 2>/dev/null; then
    print_warning "nct6775 module already configured for auto-load"
else
    echo "nct6775" | sudo tee "$MODULES_FILE" > /dev/null
    print_success "nct6775 module configured for auto-load on boot"
fi

# Step 6: Run sensors-detect if needed
if [ ! -f "/etc/conf.d/lm_sensors" ]; then
    print_status "Running sensors-detect..."
    echo "yes" | sudo sensors-detect > /dev/null 2>&1
    print_success "Sensors configured"
fi

# Completion message
echo ""
echo "╭──────────────────────────────────────────────╮"
echo "│          Installation Complete! 🎉           │"
echo "╰──────────────────────────────────────────────╯"
echo ""
echo "Installation directory: $SCRIPT_DIR"
echo ""
echo "Available commands (after restarting shell):"
echo "  fanctrl-status      or  fcs        - Show status"
echo "  fanctrl-silent      or  fcsilent   - Silent mode (30%)"
echo "  fanctrl-quiet       or  fcquiet    - Quiet mode (50%)"
echo "  fanctrl-performance or  fcperf     - Performance (80%)"
echo "  fanctrl-max         or  fcmax      - Max speed (100%)"
echo "  fanctrl-auto        or  fcauto     - Return to auto"
echo "  fanctrl-set <ch> %                 - Set specific channel"
echo "  fanctrl-gui                        - Launch GUI (if rofi installed)"
echo "  fanctrl-help                       - Show help"
echo ""
echo "To activate now, run:"
echo "  source $ZSHRC"
echo ""
echo "Or restart your terminal."
echo ""
print_success "Setup complete!"
