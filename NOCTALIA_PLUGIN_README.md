# ASUS Fan Control - Noctalia Shell Plugin

A native Noctalia Shell plugin for controlling ASUS motherboard fans with a beautiful GUI integration.

![Plugin Demo](https://img.shields.io/badge/Platform-Linux-blue) ![Shell-Noctalia-green) ![License-MIT-yellow)

## ✨ Features

- 🎛️ **Bar Widget** - Quick access fan control icon with temperature badge
- 📊 **Control Panel** - Full-featured panel with sliders and real-time monitoring
- ⚡ **Quick Presets** - One-click Silent, Quiet, Performance, and Max modes
- 🌡️ **Live Monitoring** - Real-time CPU/System temperature and fan RPM display
- ⚙️ **Settings Panel** - Configurable update intervals and display options
- 🔒 **Secure** - Uses polkit for passwordless privileged operations

## 📸 Screenshots

### Bar Widget
- Fan icon with temperature badge (color-coded)
- Click to open control panel

### Control Panel
- Temperature monitoring (CPU & System)
- Fan RPM display
- Individual PWM channel sliders (PWM1, PWM3, PWM6)
- Quick preset buttons

## 🚀 Installation

### Prerequisites

1. **Noctalia Shell** must be installed
2. **ASUS ROG STRIX B550-F** or compatible motherboard with NCT6775/NCT6798 chip
3. **lm_sensors** package

### Quick Install

```bash
# Run the installer
./install_noctalia_plugin.sh
```

The installer will:
- ✅ Check for Noctalia Shell
- ✅ Install dependencies (lm_sensors)
- ✅ Detect your NCT6775 hardware
- ✅ Install polkit rule for passwordless control
- ✅ Copy plugin files to `~/.config/noctalia/plugins/asus-fan-control`
- ✅ Reload Noctalia Shell

### Manual Installation

```bash
# 1. Install dependencies
sudo pacman -S lm_sensors

# 2. Load kernel module
sudo modprobe nct6775

# 3. Copy plugin
mkdir -p ~/.config/noctalia/plugins/asus-fan-control
cp -r noctalia-plugin/* ~/.config/noctalia/plugins/asus-fan-control/

# 4. Install polkit rule (edit username first!)
sudo cp noctalia-plugin/50-asus-fanctrl.rules /etc/polkit-1/rules.d/
sudo chown root:root /etc/polkit-1/rules.d/50-asus-fanctrl.rules

# 5. Reload Noctalia Shell
qs -c noctalia-shell reload
```

## 🎮 Usage

### Bar Widget
After installation, you'll see a **fan icon** in your bar with a temperature badge:
- **Green** (< 50°C) - Normal temperature
- **Yellow** (50-70°C) - Elevated temperature
- **Red** (> 70°C) - High temperature

Click the icon to open the control panel.

### Control Panel

#### Temperature Monitoring
- Real-time CPU temperature (Tctl)
- System temperature (SYSTIN)

#### Fan Speed Control
- **PWM1** - CPU Fan (primary control)
- **PWM3** - Chassis Fan 3
- **PWM6** - Chassis Fan 6

Use sliders to adjust individual fan speeds (0-100%).

#### Quick Presets
| Button | Speed | Description |
|--------|-------|-------------|
| 🔇 Silent | 30% | Quiet operation for light tasks |
| 🔉 Quiet | 50% | Balanced noise/cooling |
| 🔊 Performance | 80% | High-performance tasks |
| 🚀 Max | 100% | Maximum cooling |
| 🔄 Auto | BIOS | Return to automatic control |

### Settings

Access via Noctalia Settings → ASUS Fan Control:

- **Update Interval**: How often to refresh sensor data (500ms - 10s)
- **Display Options**: Show/hide temperature badge and RPM display
- **Default PWM Values**: Set default speeds for each channel

## ⌨️ IPC Commands

Use these commands for keybinds or scripts:

```bash
# Open control panel
qs -c noctalia-shell ipc call plugin:asus-fan-control openPanel

# Set presets
qs -c noctalia-shell ipc call plugin:asus-fan-control setSilent
qs -c noctalia-shell ipc call plugin:asus-fan-control setQuiet
qs -c noctalia-shell ipc call plugin:asus-fan-control setPerformance
qs -c noctalia-shell ipc call plugin:asus-fan-control setMax
qs -c noctalia-shell ipc call plugin:asus-fan-control setAuto

# Get current status (JSON)
qs -c noctalia-shell ipc call plugin:asus-fan-control getStatus

# Set specific PWM channel
qs -c noctalia-shell ipc call plugin:asus-fan-control setPwm 1 60  # PWM1 to 60%
```

### Example Hyprland Keybinds

Add to your Hyprland config:

```bash
# Fan control keybinds using Noctalia IPC
bind = CTRL ALT, F, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control openPanel
bind = CTRL ALT, 1, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setSilent
bind = CTRL ALT, 2, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setQuiet
bind = CTRL ALT, 3, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setPerformance
bind = CTRL ALT, 0, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setAuto
```

## 📁 Plugin Structure

```
asus-fan-control/
├── manifest.json         # Plugin metadata (required)
├── Main.qml             # Background logic, IPC handlers
├── BarWidget.qml        # Bar widget with temperature badge
├── Panel.qml            # Control panel UI
├── Settings.qml         # Settings panel UI
└── 50-asus-fanctrl.rules # Polkit rule for passwordless control
```

## 🔧 Troubleshooting

### Plugin Not Showing Up

1. Check if plugin is in correct directory:
   ```bash
   ls ~/.config/noctalia/plugins/asus-fan-control/
   ```

2. Reload Noctalia Shell:
   ```bash
   qs -c noctalia-shell reload
   ```

3. Check for errors in logs:
   ```bash
   journalctl --user -u noctalia-shell -f
   ```

### Hardware Not Detected

1. Load the kernel module:
   ```bash
   sudo modprobe nct6775
   ```

2. Check if chip is detected:
   ```bash
   ls /sys/class/hwmon/hwmon*/name | xargs cat
   ```

3. Run sensors-detect:
   ```bash
   sudo sensors-detect
   ```

### Permission Denied

1. Verify polkit rule is installed:
   ```bash
   ls -l /etc/polkit-1/rules.d/50-asus-fanctrl.rules
   ```

2. Check username in polkit rule matches your user:
   ```bash
   cat /etc/polkit-1/rules.d/50-asus-fanctrl.rules
   ```

3. Restart polkit service:
   ```bash
   sudo systemctl restart polkit
   ```

### Sliders Not Working

Make sure you're **clicking and dragging** the sliders (not just clicking). The fan speed updates when you release the slider.

## 🔒 Security

The plugin uses **polkit** for privileged operations:
- Only allows specific `tee` commands to PWM sysfs files
- Restricted to your user account only
- No password caching or storage
- Minimal privilege escalation scope

## 🛠️ Development

### Plugin Files Explained

**manifest.json** - Plugin metadata:
```json
{
  "id": "asus-fan-control",
  "name": "ASUS Fan Control",
  "version": "1.0.0",
  "entryPoints": {
    "main": "Main.qml",
    "barWidget": "BarWidget.qml",
    "panel": "Panel.qml",
    "settings": "Settings.qml"
  }
}
```

**Main.qml** - Core logic:
- Sensor data reading
- PWM control functions
- IPC handlers for external commands
- Settings management

**BarWidget.qml** - Status bar widget:
- Temperature badge (color-coded)
- Quick access to control panel

**Panel.qml** - Main control interface:
- Real-time monitoring
- Fan speed sliders
- Preset buttons

**Settings.qml** - Configuration panel:
- Update interval
- Display options
- Default PWM values

### Testing Changes

After modifying plugin files:
```bash
qs -c noctalia-shell reload
```

Check logs for errors:
```bash
journalctl --user -u noctalia-shell -n 50
```

## 📋 Requirements

- **Noctalia Shell** (v3.6.0 or later)
- **Linux** with NCT6775/NCT6798 chip
- **lm_sensors** package
- **polkit** for authentication

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test on your hardware
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](../LICENSE) for details.

## ⚠️ Disclaimer

This software controls hardware fans. Use at your own risk. Monitor system temperatures to ensure adequate cooling. The authors are not responsible for hardware damage.

## 🙏 Acknowledgments

- Noctalia Shell team for the excellent plugin system
- NCT6775 kernel module developers
- QML and QtQuick communities

## 📞 Support

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Documentation**: [Noctalia Plugin Docs](https://docs.noctalia.dev/development/plugins/overview/)
