# ASUS ROG B550-F Fan Control System

A comprehensive fan control solution for the ASUS ROG STRIX B550-F motherboard with NCT6775 chip, featuring GUI control, keyboard shortcuts, and smart temperature-based automation.

![Fan Control Demo](https://img.shields.io/badge/Platform-Linux-blue) ![Hardware-ASUS_B550F-green](https://img.shields.io/badge/Hardware-ASUS_B550F-green) ![License-MIT-yellow](https://img.shields.io/badge/License-MIT-yellow)

## ✨ Features

- 🎛️ **GUI Fan Control** - Clean Rofi-based interface for easy fan management
- ⌨️ **Keyboard Shortcuts** - Hyprland keybindings for instant fan control
- 🤖 **Smart Automation** - Temperature-based automatic fan control daemon
- 🔧 **Manual Control** - Precise PWM control for each fan channel
- 📊 **Real-time Monitoring** - Live temperature and RPM monitoring
- 🎯 **Quick Presets** - Silent, Quiet, Performance, and Auto modes
- 🔒 **Secure** - Passwordless sudo configuration for seamless operation

## 🖥️ Screenshots

### Main Control Interface
- Temperature monitoring with real-time updates
- Individual PWM channel control (PWM1, PWM3, PWM6)
- Fan RPM display for connected fans

### Quick Presets
- **Silent Mode**: 30% fan speed for quiet operation
- **Quiet Mode**: 50% fan speed for balanced noise/cooling
- **Performance Mode**: 80% fan speed for high-performance tasks
- **Auto Mode**: Return to BIOS automatic control

## 🚀 Quick Installation

### One-Command Installation
```bash
git clone https://github.com/yourusername/asus-b550f-fanctrl.git
cd asus-b550f-fanctrl
./install_complete_fanctrl.sh
```

That's it! The script will automatically:
- Detect your Linux distribution
- Install required dependencies (rofi, lm-sensors)
- Detect NCT6775 hardware automatically
- Configure passwordless sudo
- Set up Hyprland keybindings
- Test the complete installation

## 💻 Supported Systems

### Distributions
- ✅ Arch Linux / CachyOS / Manjaro
- ✅ Ubuntu / Debian
- ✅ Fedora / RHEL / CentOS
- ✅ openSUSE

### Hardware Requirements
- ASUS ROG STRIX B550-F motherboard
- NCT6775 Super I/O chip
- Linux kernel with nct6775 module support

### Desktop Environments
- **Hyprland** (automatic keybinding configuration)
- **Any X11/Wayland environment** (manual configuration needed)

## 🎮 Usage

### Keyboard Shortcuts (Hyprland)
| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+F` | Open fan control GUI |
| `Ctrl+Alt+1` | Silent mode (30%) |
| `Ctrl+Alt+2` | Quiet mode (50%) |
| `Ctrl+Alt+3` | Performance mode (80%) |
| `Ctrl+Alt+0` | Auto mode (BIOS control) |
| `Ctrl+Alt+T` | Temperature monitoring |

### Command Line
```bash
# Show current status
./fan_control.sh

# Set specific fan speed
./fan_control.sh set 1 60    # Set PWM1 to 60%

# Return to automatic mode
./fan_control.sh auto 1      # Set PWM1 to auto

# Launch GUI
./rofi_fan_control.sh

# Configure smart daemon
./smart_fan_daemon.sh config

# Run smart daemon
./smart_fan_daemon.sh run
```

## 🧠 Smart Fan Daemon

The smart fan daemon provides temperature-based automatic fan control:

- **Configurable temperature thresholds** (default: 30°C - 70°C)
- **Configurable fan speed range** (default: 20% - 100%)
- **Linear interpolation** between temperature points
- **Graceful shutdown** returns fans to BIOS control

### Configuration Example
```bash
./smart_fan_daemon.sh config
```

Configuration is saved to `~/.fan_control_config` and persists between sessions.

## 🔧 Manual Installation

If the automatic installer doesn't work for your setup:

### 1. Install Dependencies
```bash
# Arch/CachyOS
sudo pacman -S rofi lm_sensors

# Ubuntu/Debian  
sudo apt install rofi lm-sensors

# Fedora
sudo dnf install rofi lm_sensors
```

### 2. Load Kernel Module
```bash
sudo modprobe nct6775
```

### 3. Install Sudoers Configuration
```bash
sudo ./install_sudoers.sh
```

### 4. Configure Window Manager
Add the keybindings from `hyprland_fan_keybind.conf` to your window manager configuration.

## 🛠️ Hardware Detection

The system automatically detects your NCT6775 chip location. If you need to manually check:

```bash
# Find NCT6775 devices
find /sys/devices/platform/nct6775.* -name "hwmon"

# Check available PWM channels
ls /sys/devices/platform/nct6775.*/hwmon/hwmon*/pwm*
```

## 🧪 Testing

Test your installation:
```bash
./test_fan_gui.sh
```

This will verify:
- Rofi functionality
- Script permissions
- Hardware access
- Sudo configuration

## 📋 File Structure

```
asus-b550f-fanctrl/
├── install_complete_fanctrl.sh    # One-click installer
├── fan_control.sh                 # Core fan control script
├── rofi_fan_control.sh           # GUI interface
├── smart_fan_daemon.sh           # Smart automation daemon
├── test_fan_gui.sh               # Testing utilities
├── install_sudoers.sh            # Sudoers configuration (legacy)
├── hyprland_fan_keybind.conf     # Keybinding reference
├── README.md                     # This file
├── README_INSTALLATION.md        # Detailed installation guide
└── FAN_CONTROL_GUIDE.md         # Original documentation
```

## 🔒 Security

- Uses sudoers configuration for specific fan control commands only
- No password storage or caching
- Minimal privilege escalation scope
- Validates all sudoers configurations before applying

## 🐛 Troubleshooting

### Hardware Not Detected
```bash
# Load the kernel module
sudo modprobe nct6775

# Check if chip is detected
ls /sys/devices/platform/nct6775.*
```

### Permission Denied
```bash
# Check sudoers configuration
sudo visudo -c -f /etc/sudoers.d/fan-control

# Reinstall if needed
sudo ./install_sudoers.sh
```

### GUI Not Working
```bash
# Test rofi
rofi -e "Test message"

# Check if X11/Wayland is running
echo $DISPLAY
echo $WAYLAND_DISPLAY
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Test on your hardware
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This software controls hardware fans. Use at your own risk. Monitor your system temperatures and ensure adequate cooling at all times. The authors are not responsible for any hardware damage.

## 🙏 Acknowledgments

- NCT6775 kernel module developers
- Rofi project for the excellent menu system
- ASUS for detailed hardware documentation
