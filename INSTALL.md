# 📦 Installation Guide

> Detailed installation instructions for all components

---

## Prerequisites

### Hardware Requirements
- ASUS ROG STRIX B550-F motherboard (or compatible)
- NCT6775/NCT6798 Super I/O chip
- Linux kernel with `nct6775` module support

### Software Requirements
- `lm_sensors` package
- `rofi` (for GUI interfaces)
- Noctalia Shell (for Noctalia plugin only)

---

## Installation Methods

### Method 1: Automated Installers (Recommended)

Choose the installer based on your needs:

| Installer | Purpose | Command |
|-----------|---------|---------|
| Noctalia Plugin | Desktop integration | `./install_noctalia_plugin.sh` |
| Zsh Plugin | Terminal integration | `./setup_zsh_plugin.sh` |
| Complete System | Full installation | `./install_complete_fanctrl.sh` |

---

### Method 2: Manual Installation

#### Step 1: Install Dependencies

**Arch Linux / CachyOS / Manjaro:**
```bash
sudo pacman -S lm_sensors rofi
```

**Ubuntu / Debian:**
```bash
sudo apt update
sudo apt install lm-sensors rofi
```

**Fedora:**
```bash
sudo dnf install lm_sensors rofi
```

**openSUSE:**
```bash
sudo zypper install sensors rofi
```

---

#### Step 2: Load Kernel Module

```bash
# Load the module
sudo modprobe nct6775

# Verify it's loaded
lsmod | grep nct6775

# Configure auto-load on boot
echo "nct6775" | sudo tee /etc/modules-load.d/nct6775.conf
```

---

#### Step 3: Run Hardware Detection

```bash
# Run sensors-detect (answer yes to all)
sudo sensors-detect

# Verify hardware detection
sensors

# Or use the detection helper
asus-fanctrl-detect status
```

Expected output:
```
╭──────────────────────────────────────╮
│     ASUS Fan Control - Status        │
╰──────────────────────────────────────╯

[OK] nct6775 kernel module: LOADED

[INFO] Scanning for NCT6775/NCT6798 hardware...
[OK] Hardware detected at: /sys/class/hwmon/hwmon5

Available PWM channels:
  PWM1: 46% - Smart Fan IV (Auto)
  PWM3: 43% - Smart Fan IV (Auto)
  PWM6: 20% - Smart Fan IV (Auto)
```

---

#### Step 4: Install Noctalia Plugin (Optional)

```bash
# Run installer
./install_noctalia_plugin.sh

# Reload Noctalia Shell
qs -c noctalia-shell reload
```

**Manual installation:**
```bash
# Copy plugin files
mkdir -p ~/.config/noctalia/plugins/asus-fan-control
cp -r noctalia-plugin/* ~/.config/noctalia/plugins/asus-fan-control/

# Install polkit rule (replace USERNAME with your username)
sudo sed "s/USERNAME_PLACEHOLDER/$(whoami)/g" noctalia-plugin/50-asus-fanctrl.rules | \
  sudo tee /etc/polkit-1/rules.d/50-asus-fanctrl.rules

sudo chmod 644 /etc/polkit-1/rules.d/50-asus-fanctrl.rules

# Install detection helper
sudo cp noctalia-plugin/asus-fanctrl-detect /usr/local/bin/
sudo chmod +x /usr/local/bin/asus-fanctrl-detect

# Restart polkit
sudo systemctl restart polkit

# Reload Noctalia
qs -c noctalia-shell reload
```

---

#### Step 5: Install Zsh Plugin (Optional)

```bash
# Run installer
./setup_zsh_plugin.sh

# Reload shell
source ~/.zshrc
```

**Manual installation:**
```bash
# Add to ~/.zshrc
cat >> ~/.zshrc << 'EOF'

# ASUS Fan Control Plugin
if [ -f "/path/to/fan_control_zsh_plugin.zsh" ]; then
    source "/path/to/fan_control_zsh_plugin.zsh"
fi
EOF

# Install sudoers (replace USERNAME with your username)
sudo sed "s/USERNAME_PLACEHOLDER/$(whoami)/g" fanctrl_sudoers_zsh | \
  sudo tee /etc/sudoers.d/fanctrl

sudo chmod 0440 /etc/sudoers.d/fanctrl

# Reload shell
source ~/.zshrc
```

---

#### Step 6: Install Complete System (Optional)

```bash
# Run complete installer
./install_complete_fanctrl.sh

# Verify installation
~/fanctrl/test_fan_gui.sh
```

This installs:
- All scripts to `~/fanctrl/`
- Sudoers configuration
- Hyprland keybindings (if config exists)
- Desktop entry
- Systemd service files

---

#### Step 7: Install Systemd Service (Optional)

For automatic temperature-based fan control:

```bash
# Run installer
./install_systemd_service.sh

# Enable and start service
sudo systemctl enable --now smart-fan-daemon

# Check status
sudo systemctl status smart-fan-daemon

# View logs
journalctl -u smart-fan-daemon -f
```

**Manual installation:**
```bash
# Copy service file
sudo cp smart-fan-daemon.service /etc/systemd/system/

# Install sudoers rule
sudo cp fan_control_sudoers /etc/sudoers.d/90-fan-control
sudo chmod 440 /etc/sudoers.d/90-fan-control

# Update ExecStart path in service file
sudo sed -i "s|/path/to|$(pwd)|g" /etc/systemd/system/smart-fan-daemon.service

# Reload and start
sudo systemctl daemon-reload
sudo systemctl enable --now smart-fan-daemon
```

---

## Post-Installation

### Verify Installation

```bash
# Run health check
./scripts/verify_fanctrl.sh

# Test CLI
fanctrl-status

# Test GUI (if rofi installed)
./rofi_fan_control.sh

# Test Noctalia plugin (if installed)
qs -c noctalia-shell ipc call plugin:asus-fan-control getStatus
```

### Configure Smart Daemon

```bash
# Interactive configuration
./smart_fan_daemon.sh config

# Test configuration
./smart_fan_daemon.sh test
```

### Add Keybindings (Hyprland)

Add to `~/.config/hypr/hyprland.conf`:

```bash
# Import from provided config
source ~/.config/hypr/fan_keybinds.conf

# Or manually add:
bind = CTRL ALT, F, exec, fanctrl-gui
bind = CTRL ALT, 1, exec, fanctrl-silent
bind = CTRL ALT, 2, exec, fanctrl-quiet
bind = CTRL ALT, 3, exec, fanctrl-performance
bind = CTRL ALT, 0, exec, fanctrl-auto
bind = CTRL ALT, T, exec, rofi -e "$(sensors)" -theme-str 'window {width: 400px;}'
```

Then reload Hyprland: `Super+Shift+R`

---

## Distribution-Specific Notes

### Arch Linux / CachyOS

```bash
# Install from AUR (if available)
yay -S asus-fanctrl-git

# Or use the installers
./install_noctalia_plugin.sh
```

### Ubuntu / Debian

```bash
# Ensure kernel module is available
sudo apt install linux-modules-extra-$(uname -r)

# Load module
sudo modprobe nct6775
```

### Fedora

```bash
# Enable RPM Fusion if needed
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# Install dependencies
sudo dnf install lm_sensors rofi
```

---

## Uninstallation

### Remove Noctalia Plugin

```bash
# Remove plugin directory
rm -rf ~/.config/noctalia/plugins/asus-fan-control

# Remove polkit rule
sudo rm /etc/polkit-1/rules.d/50-asus-fanctrl.rules

# Remove detection helper
sudo rm /usr/local/bin/asus-fanctrl-detect

# Reload Noctalia
qs -c noctalia-shell reload
```

### Remove Zsh Plugin

```bash
# Remove from ~/.zshrc
sed -i '/fan_control_zsh_plugin/d' ~/.zshrc

# Remove sudoers
sudo rm /etc/sudoers.d/fanctrl

# Reload shell
source ~/.zshrc
```

### Remove Complete System

```bash
# Remove installation directory
rm -rf ~/fanctrl

# Remove sudoers
sudo rm /etc/sudoers.d/fan-control

# Remove desktop entry
rm ~/.local/share/applications/fan-control.desktop

# Remove keybindings from Hyprland config manually
```

### Remove Systemd Service

```bash
# Stop and disable
sudo systemctl stop smart-fan-daemon
sudo systemctl disable smart-fan-daemon

# Remove service file
sudo rm /etc/systemd/system/smart-fan-daemon.service
sudo systemctl daemon-reload

# Remove sudoers
sudo rm /etc/sudoers.d/90-fan-control
```

---

## Troubleshooting

### Installation Script Fails

```bash
# Check if running as correct user
whoami

# Check script permissions
chmod +x install_*.sh

# Run with verbose output
bash -x ./install_noctalia_plugin.sh
```

### Hardware Not Detected After Installation

```bash
# Force module reload
sudo modprobe -r nct6775
sudo modprobe nct6775

# Check dmesg for errors
dmesg | grep nct6775

# Verify hwmon devices
ls -la /sys/class/hwmon/
```

### Polkit Authentication Fails

```bash
# Check polkit rule
cat /etc/polkit-1/rules.d/50-asus-fanctrl.rules

# Verify username matches
whoami

# Restart polkit
sudo systemctl restart polkit

# Check polkit logs
journalctl -u polkit -f
```

### Sudoers Validation Fails

```bash
# Check syntax
sudo visudo -c -f /etc/sudoers.d/fanctrl

# If invalid, remove and reinstall
sudo rm /etc/sudoers.d/fanctrl
./setup_zsh_plugin.sh
```

---

## Next Steps

- **[QUICK_START.md](QUICK_START.md)** - Quick commands reference
- **[INTEGRATION_OPTIONS.md](INTEGRATION_OPTIONS.md)** - Compare integration options
- **[FAN_CONTROL_GUIDE.md](FAN_CONTROL_GUIDE.md)** - Usage guide
- **[SYSTEMD_SERVICE.md](SYSTEMD_SERVICE.md)** - Daemon configuration

---

**Installation complete!** See [QUICK_START.md](QUICK_START.md) for usage instructions.
