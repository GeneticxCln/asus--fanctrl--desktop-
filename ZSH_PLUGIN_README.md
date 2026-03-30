# ASUS Fan Control - Zsh Plugin Integration

Quick integration guide for using the fan control system as a zsh plugin on Arch/Noctalia.

## 🚀 Quick Setup

### One-Command Installation
```bash
./setup_zsh_plugin.sh
```

This will:
- ✅ Install dependencies (lm_sensors, rofi)
- ✅ Detect your NCT6775 hardware
- ✅ Configure passwordless sudo
- ✅ Add plugin to your `.zshrc`
- ✅ Configure auto-loading of kernel module

After setup, **restart your terminal** or run:
```bash
source ~/.zshrc
```

## 📋 Manual Installation

### 1. Install Dependencies
```bash
sudo pacman -S lm_sensors rofi
```

### 2. Load Kernel Module
```bash
sudo modprobe nct6775
```

### 3. Configure Sudoers
```bash
sudo cp fanctrl_sudoers_zsh /etc/sudoers.d/fanctrl
sudo chmod 0440 /etc/sudoers.d/fanctrl
# Edit the file to replace 'quinton' with your username if needed
```

### 4. Add Plugin to Zshrc
Add this to `~/.zshrc`:
```bash
# ASUS Fan Control Plugin
if [ -f "/home/quinton/asus--fanctrl--desktop-/fan_control_zsh_plugin.zsh" ]; then
    source "/home/quinton/asus--fanctrl--desktop-/fan_control_zsh_plugin.zsh"
fi
```

### 5. Reload Shell
```bash
source ~/.zshrc
```

## 🎯 Usage

### Check Status
```bash
fanctrl-status
# or short alias:
fcs
```

### Quick Presets
```bash
fanctrl-silent      # 30% - Silent mode (fcsilent)
fanctrl-quiet       # 50% - Quiet mode (fcquiet)
fanctrl-performance # 80% - Performance (fcperf)
fanctrl-max         # 100% - Max speed (fcmax)
fanctrl-auto        # Return to automatic (fcauto)
```

### Manual Control
```bash
# Set PWM channel 1 to 60%
fanctrl-set 1 60

# Set PWM channel 3 to 40%
fanctrl-set 3 40
```

### GUI Control (if rofi installed)
```bash
fanctrl-gui
```

### Help
```bash
fanctrl-help
```

## 🎨 Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `fcs` | fanctrl-status | Show status |
| `fcsilent` | fanctrl-silent | Silent mode |
| `fcquiet` | fanctrl-quiet | Quiet mode |
| `fcperf` | fanctrl-performance | Performance mode |
| `fcmax` | fanctrl-max | Max speed |
| `fcauto` | fanctrl-auto | Auto mode |

## 🔧 PWM Channels

- **PWM1** - CPU Fan (usually connected here)
- **PWM3** - Fan3 (chassis fan)
- **PWM6** - Fan6 (chassis fan)

## 🛠️ Troubleshooting

### Hardware Not Detected
```bash
# Check if module is loaded
lsmod | grep nct6775

# Load manually if needed
sudo modprobe nct6775

# Check for chip
ls /sys/class/hwmon/hwmon*/name | xargs cat
```

### Permission Denied
```bash
# Verify sudoers configuration
sudo visudo -c -f /etc/sudoers.d/fanctrl

# Reinstall if needed
sudo cp fanctrl_sudoers_zsh /etc/sudoers.d/fanctrl
sudo chmod 0440 /etc/sudoers.d/fanctrl
```

### Plugin Not Loading
```bash
# Check if plugin path is correct in .zshrc
grep fan_control ~/.zshrc

# Source manually
source /home/quinton/asus--fanctrl--desktop-/fan_control_zsh_plugin.zsh
```

## 📦 Files

- `fan_control_zsh_plugin.zsh` - Main zsh plugin (source this)
- `fanctrl_sudoers_zsh` - Sudoers configuration
- `setup_zsh_plugin.sh` - Automated setup script
- `fan_control.sh` - Original CLI tool (also available)
- `rofi_fan_control.sh` - GUI interface (requires rofi)

## ⚙️ Advanced: Smart Daemon

For temperature-based automatic control:

```bash
# Configure daemon
./smart_fan_daemon.sh config

# Run daemon
./smart_fan_daemon.sh run

# Or use systemd service
sudo systemctl enable smart-fan-daemon
sudo systemctl start smart-fan-daemon
```

## 🔒 Security

The sudoers configuration only allows specific PWM control commands:
- `/usr/bin/tee /sys/class/hwmon/hwmon*/pwm*`
- `/usr/bin/tee /sys/devices/platform/nct6775.*/hwmon/hwmon*/pwm*`

This is the minimum required for fan control with no broader system access.

## ⚠️ Disclaimer

Use at your own risk. Monitor system temperatures to ensure adequate cooling. The authors are not responsible for hardware damage.
