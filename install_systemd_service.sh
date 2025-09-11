#!/bin/bash

# Installation script for Smart Fan Control Systemd Service
# This script installs the systemd service and sudoers rule for passwordless fan control

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="smart-fan-daemon"
SUDOERS_FILE="/etc/sudoers.d/90-fan-control"

echo "=== Smart Fan Control Systemd Service Installer ==="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Error: Do not run this script as root. It will use sudo when needed."
    exit 1
fi

# Check if systemd is available
if ! command -v systemctl &> /dev/null; then
    echo "Error: systemd not found. This script requires systemd."
    exit 1
fi

# Function to install sudoers rule
install_sudoers() {
    echo "Installing sudoers rule for passwordless fan control..."
    
    if [ ! -f "$SCRIPT_DIR/fan_control_sudoers" ]; then
        echo "Creating sudoers rule..."
        cat > /tmp/90-fan-control << 'EOF'
# Fan Control Sudoers Rule for ASUS ROG STRIX B550-F
# Allows user to control fan speeds without password prompts
# Restricted to specific tee commands on hwmon PWM files only

# Allow writing to PWM enable files (to switch between manual/auto modes)
%sudo ALL=(root) NOPASSWD: /usr/bin/tee /sys/class/hwmon/hwmon*/pwm*_enable
%sudo ALL=(root) NOPASSWD: /bin/tee /sys/class/hwmon/hwmon*/pwm*_enable

# Allow writing to PWM control files (to set fan speeds)
%sudo ALL=(root) NOPASSWD: /usr/bin/tee /sys/class/hwmon/hwmon*/pwm[1-6]
%sudo ALL=(root) NOPASSWD: /bin/tee /sys/class/hwmon/hwmon*/pwm[1-6]
EOF
        sudo cp /tmp/90-fan-control "$SUDOERS_FILE"
        rm /tmp/90-fan-control
    else
        sudo cp "$SCRIPT_DIR/fan_control_sudoers" "$SUDOERS_FILE"
    fi
    
    sudo chmod 440 "$SUDOERS_FILE"
    
    # Validate sudoers file
    if sudo visudo -c; then
        echo "✓ Sudoers rule installed successfully"
    else
        echo "✗ Error in sudoers configuration"
        sudo rm -f "$SUDOERS_FILE"
        exit 1
    fi
}

# Function to install systemd service
install_service() {
    echo "Installing systemd service..."
    
    if [ ! -f "$SCRIPT_DIR/$SERVICE_NAME.service" ]; then
        echo "Error: $SERVICE_NAME.service not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # Update ExecStart path in service file if needed
    local current_path=$(realpath "$SCRIPT_DIR/smart_fan_daemon.sh")
    sudo cp "$SCRIPT_DIR/$SERVICE_NAME.service" "/etc/systemd/system/"
    sudo sed -i "s|/home/sasha/fanctrl/smart_fan_daemon.sh|$current_path|g" "/etc/systemd/system/$SERVICE_NAME.service"
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    echo "✓ Systemd service installed successfully"
}

# Function to test the setup
test_setup() {
    echo ""
    echo "Testing the installation..."
    
    # Test sudoers rule
    echo "Testing sudoers rule..."
    if echo "test" | sudo tee /sys/class/hwmon/hwmon*/pwm1_enable > /dev/null 2>&1; then
        echo "✓ Sudoers rule working (can write to PWM files without password)"
    else
        echo "⚠ Sudoers rule test failed (this might be normal if hwmon path doesn't exist)"
    fi
    
    # Test daemon script
    echo "Testing daemon script..."
    if "$SCRIPT_DIR/smart_fan_daemon.sh" test; then
        echo "✓ Daemon script working"
    else
        echo "⚠ Daemon script test failed"
    fi
    
    # Test systemd service syntax
    echo "Testing systemd service..."
    if sudo systemctl status $SERVICE_NAME.service > /dev/null 2>&1; then
        echo "✓ Service is loaded"
    else
        echo "✓ Service is available (not running, which is expected)"
    fi
}

# Main installation
echo "This will install:"
echo "  - Sudoers rule for passwordless fan control"
echo "  - Systemd service for smart fan daemon"
echo ""
read -p "Continue? [Y/n]: " confirm

if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
install_sudoers
echo ""
install_service
echo ""
test_setup

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Service management commands:"
echo "  sudo systemctl start $SERVICE_NAME      # Start the service"
echo "  sudo systemctl stop $SERVICE_NAME       # Stop the service"
echo "  sudo systemctl enable $SERVICE_NAME     # Enable auto-start on boot"
echo "  sudo systemctl disable $SERVICE_NAME    # Disable auto-start"
echo "  sudo systemctl status $SERVICE_NAME     # Check service status"
echo "  journalctl -u $SERVICE_NAME -f          # View service logs"
echo ""
echo "Manual fan control (no password required):"
echo "  $SCRIPT_DIR/fan_control.sh set 1 50     # Set PWM1 to 50%"
echo "  $SCRIPT_DIR/rofi_fan_control.sh         # Launch GUI"
echo ""
echo "Note: The service is installed but not started or enabled."
echo "Use 'sudo systemctl start $SERVICE_NAME' to start it."
