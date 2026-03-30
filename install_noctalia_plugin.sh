#!/bin/bash
# ASUS Fan Control - Noctalia Shell Plugin Installer
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$HOME/.config/noctalia/plugins/asus-fan-control"
USERNAME="${SUDO_USER:-$(whoami)}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERR]${NC} $1"; }

echo "========================================"
echo "  ASUS Fan Control - Noctalia Plugin   "
echo "========================================"
echo ""

print_status "Checking for Noctalia Shell..."
if ! command -v qs > /dev/null 2>&1; then
    print_error "Noctalia Shell (qs) not found!"
    echo "Please install: yay -S noctalia-shell"
    exit 1
fi
print_success "Noctalia Shell detected"

print_status "Checking dependencies..."
if command -v sensors > /dev/null 2>&1; then
    print_success "lm_sensors is installed"
else
    print_warning "lm_sensors not found"
    echo -n "Install lm_sensors? [Y/n]: "
    read -r install_sensors
    if [ "$install_sensors" != "n" ] && [ "$install_sensors" != "N" ]; then
        sudo pacman -S lm_sensors --noconfirm
        print_success "lm_sensors installed"
    else
        print_error "Cannot continue without lm_sensors"
        exit 1
    fi
fi

print_status "Checking hardware detection..."
sudo modprobe nct6775 2>/dev/null || true
sleep 2

if ls /sys/class/hwmon/hwmon*/name 2>/dev/null | xargs grep -q "nct6798\|nct6775" 2>/dev/null; then
    print_success "NCT6775/NCT6798 chip detected"
else
    print_warning "Hardware not detected - plugin may not work correctly"
fi

print_status "Verifying hardware detection helper..."
if [ -x /usr/local/bin/asus-fanctrl-detect ]; then
    print_success "Detection helper already installed"
fi

print_status "Installing polkit rule..."
POLKIT_RULE="/etc/polkit-1/rules.d/50-asus-fanctrl.rules"
POLKIT_TMP=$(mktemp /tmp/50-asus-fanctrl.XXXXXX.rules)

# Create polkit rule with current username
cat > "$POLKIT_TMP" << POLKIT_EOF
// Polkit rule for ASUS Fan Control
// Allows passwordless control of fan PWM via asus-fanctrl-detect
// Generated for user: $USERNAME

polkit.addRule(function(action, subject) {
    if (action.id === "org.freedesktop.policykit.exec" &&
        subject.user === "$USERNAME") {
        
        var command = action.lookup("command");
        
        // 1. Allow loading of nct6775 kernel module
        if (command === "/usr/bin/modprobe nct6775" || 
            command === "/sbin/modprobe nct6775") {
            return polkit.Result.YES;
        }

        // 2. Allow execution of fan control helper script (with any arguments)
        if (command && command.startsWith("/usr/local/bin/asus-fanctrl-detect")) {
            return polkit.Result.YES;
        }
    }
});
POLKIT_EOF

sudo mkdir -p /etc/polkit-1/rules.d
sudo cp "$POLKIT_TMP" "$POLKIT_RULE"
sudo chown root:root "$POLKIT_RULE"
sudo chmod 644 "$POLKIT_RULE"
rm -f "$POLKIT_TMP"

# Also update the bundled rule file for reference (skipped as it is redundant)
# The rule file in /etc/polkit-1/rules.d is the only one needed.

print_success "Polkit rule installed"

print_status "Installing plugin to $PLUGIN_DIR..."
mkdir -p "$PLUGIN_DIR"
cp -r "$SCRIPT_DIR/noctalia-plugin/"* "$PLUGIN_DIR/"
chmod -R 755 "$PLUGIN_DIR"

# Install detection helper to system path
print_status "Installing hardware detection helper..."
sudo cp "$SCRIPT_DIR/noctalia-plugin/asus-fanctrl-detect" /usr/local/bin/asus-fanctrl-detect
sudo chmod +x /usr/local/bin/asus-fanctrl-detect
print_success "Detection helper installed to /usr/local/bin/asus-fanctrl-detect"

print_success "Plugin installed"

echo ""
echo "========================================"
echo "        Installation Complete!          "
echo "========================================"
echo ""
echo "Plugin location: $PLUGIN_DIR"
echo ""
echo "Reload Noctalia Shell (either via your display manager or by killing/restarting the shell process)."
echo ""
echo "After reloading, click the fan icon in your bar!"
echo ""
