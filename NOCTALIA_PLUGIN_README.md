# Noctalia Shell Plugin

> Native Noctalia Shell plugin for ASUS fan control with beautiful GUI integration

[![Noctalia](https://img.shields.io/badge/Noctalia-Plugin-purple)]()
[![Version](https://img.shields.io/badge/Version-1.0.0-blue)]()
[![License](https://img.shields.io/badge/License-MIT-yellow)]()

---

## Features

- **🎛️ Bar Widget** - Fan icon with color-coded temperature badge
- **📊 Control Panel** - Full-featured panel with sliders and monitoring
- **⚡ Quick Presets** - One-click Silent, Quiet, Performance, Max modes
- **🌡️ Live Monitoring** - Real-time CPU/System temperature and fan RPM
- **⚙️ Settings Panel** - Configurable update intervals and defaults
- **🔒 Secure** - Polkit authentication for privileged operations
- **🔄 Auto Mode** - Return fans to BIOS control

---

## Screenshots

### Bar Widget
- Fan icon displays in your bar
- Temperature badge shows current CPU temp
- Color-coded: Green (<50°C), Yellow (50-70°C), Red (>70°C)

### Control Panel
- Real-time temperature monitoring
- Fan RPM display for connected fans
- Individual PWM sliders (PWM1, PWM3, PWM6)
- Quick preset buttons
- Auto mode button

---

## Installation

### Quick Install

```bash
# Run the installer
./install_noctalia_plugin.sh

# Reload Noctalia Shell
qs -c noctalia-shell reload
```

The installer will:
1. ✅ Check for Noctalia Shell
2. ✅ Install dependencies (lm_sensors)
3. ✅ Detect NCT6775/NCT6798 hardware
4. ✅ Install polkit rule for passwordless control
5. ✅ Copy plugin files to `~/.config/noctalia/plugins/asus-fan-control`
6. ✅ Install hardware detection helper

---

### Manual Installation

```bash
# 1. Install dependencies
sudo pacman -S lm_sensors

# 2. Load kernel module
sudo modprobe nct6775

# 3. Copy plugin files
mkdir -p ~/.config/noctalia/plugins/asus-fan-control
cp -r noctalia-plugin/* ~/.config/noctalia/plugins/asus-fan-control/

# 4. Install polkit rule (replace USERNAME with your username)
sudo sed "s/USERNAME_PLACEHOLDER/$(whoami)/g" noctalia-plugin/50-asus-fanctrl.rules | \
  sudo tee /etc/polkit-1/rules.d/50-asus-fanctrl.rules
sudo chmod 644 /etc/polkit-1/rules.d/50-asus-fanctrl.rules

# 5. Install detection helper
sudo cp noctalia-plugin/asus-fanctrl-detect /usr/local/bin/
sudo chmod +x /usr/local/bin/asus-fanctrl-detect

# 6. Restart polkit
sudo systemctl restart polkit

# 7. Reload Noctalia Shell
qs -c noctalia-shell reload
```

---

## Usage

### Bar Widget

After installation, a **fan icon** appears in your bar:

- **Click** to open control panel
- **Temperature badge** shows current CPU temperature
- **Color coding:**
  - 🟢 Green: < 50°C (Normal)
  - 🟡 Yellow: 50-70°C (Elevated)
  - 🔴 Red: > 70°C (High)

---

### Control Panel

#### Temperature Monitoring
- **CPU (Tctl)** - Primary CPU temperature
- **System (SYSTIN)** - Motherboard temperature

#### Fan Speed Control
- **PWM1** - CPU Fan (primary control)
- **PWM3** - Chassis Fan 1
- **PWM6** - Chassis Fan 2

**How to use:**
1. Drag sliders to adjust fan speed (0-100%)
2. Changes apply when you release the slider
3. Values update in real-time

#### Quick Presets

| Button | Speed | Description |
|--------|-------|-------------|
| 🔇 Silent | 30% | Quiet operation for light tasks |
| 🔉 Quiet | 50% | Balanced noise/cooling |
| 🔊 Perf | 80% | High-performance tasks |
| 🚀 Max | 100% | Maximum cooling |
| 🔄 Auto | BIOS | Return to automatic control |

---

### Settings Panel

Access via Noctalia Settings → ASUS Fan Control:

- **Update Interval** - How often to refresh sensor data (500ms - 10s)
- **Default PWM Values** - Set default speeds for each channel
- **Apply Now** - Apply default values immediately
- **Reset to Defaults** - Restore factory settings

---

## IPC Commands

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

# Get current status (JSON output)
qs -c noctalia-shell ipc call plugin:asus-fan-control getStatus

# Set specific PWM channel
qs -c noctalia-shell ipc call plugin:asus-fan-control setPwm 1 60

# Retry hardware detection
qs -c noctalia-shell ipc call plugin:asus-fan-control retryDetection

# Load kernel module
qs -c noctalia-shell ipc call plugin:asus-fan-control loadNct6775Module
```

---

### Example Keybinds

#### Noctalia Config
```json
{
  "keybinds": {
    "Ctrl+Alt+F": "qs -c noctalia-shell ipc call plugin:asus-fan-control openPanel",
    "Ctrl+Alt+1": "qs -c noctalia-shell ipc call plugin:asus-fan-control setSilent",
    "Ctrl+Alt+2": "qs -c noctalia-shell ipc call plugin:asus-fan-control setQuiet",
    "Ctrl+Alt+3": "qs -c noctalia-shell ipc call plugin:asus-fan-control setPerformance",
    "Ctrl+Alt+0": "qs -c noctalia-shell ipc call plugin:asus-fan-control setAuto"
  }
}
```

#### Hyprland Config
```bash
# Using Noctalia IPC
bind = CTRL ALT, F, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control openPanel
bind = CTRL ALT, 1, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setSilent
bind = CTRL ALT, 2, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setQuiet
bind = CTRL ALT, 3, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setPerformance
bind = CTRL ALT, 0, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setAuto
```

---

## Plugin Structure

```
asus-fan-control/
├── manifest.json              # Plugin metadata
├── Main.qml                   # Background logic, IPC handlers
├── BarWidget.qml              # Bar widget with temperature badge
├── Panel.qml                  # Control panel UI
├── Settings.qml               # Settings panel UI
├── asus-fanctrl-detect        # Hardware detection helper
└── 50-asus-fanctrl.rules      # Polkit rule template
```

### File Descriptions

**manifest.json** - Plugin metadata:
```json
{
  "id": "asus-fan-control",
  "name": "ASUS Fan Control",
  "version": "1.0.0",
  "minNoctaliaVersion": "3.6.0",
  "entryPoints": {
    "main": "Main.qml",
    "barWidget": "BarWidget.qml",
    "panel": "Panel.qml"
  }
}
```

**Main.qml** - Core logic:
- Hardware detection with retry logic
- Sensor data reading
- PWM control functions
- IPC handlers
- Settings management

**BarWidget.qml** - Status bar widget:
- Temperature badge (color-coded)
- Quick access to control panel

**Panel.qml** - Main control interface:
- Real-time monitoring
- Fan speed sliders
- Preset buttons
- Hardware detection status

**Settings.qml** - Configuration panel:
- Update interval
- Default PWM values
- Apply/reset buttons

---

## Troubleshooting

### Plugin Not Showing Up

```bash
# Check if plugin is installed
ls ~/.config/noctalia/plugins/asus-fan-control/

# Reload Noctalia Shell
qs -c noctalia-shell reload

# Check for errors
journalctl --user -u noctalia-shell -f
```

---

### Hardware Not Detected

The plugin includes built-in hardware detection with retry logic:

1. **Automatic retry** - Plugin retries 5 times on load
2. **Manual retry** - Click "Retry" button in panel
3. **Load module** - Click "Load Module" button to load nct6775

**Manual verification:**
```bash
# Check if module is loaded
lsmod | grep nct6775

# Load manually if needed
sudo modprobe nct6775

# Check for chip
ls /sys/class/hwmon/hwmon*/name | xargs cat

# Use detection helper
asus-fanctrl-detect status
```

---

### Permission Denied

```bash
# Verify polkit rule is installed
cat /etc/polkit-1/rules.d/50-asus-fanctrl.rules

# Check username matches
whoami

# Restart polkit
sudo systemctl restart polkit

# Test pkexec
pkexec /usr/local/bin/asus-fanctrl-detect status
```

---

### Sliders Not Working

- Make sure you're **dragging and releasing** the slider
- Changes apply on slider release, not during drag
- Check if hardware is detected (see above)
- Verify polkit permissions (see above)

---

### Temperature Shows N/A

```bash
# Check lm_sensors
sensors

# If no output, run sensors-detect
sudo sensors-detect

# Restart Noctalia Shell
qs -c noctalia-shell reload
```

---

### High CPU Usage

If the plugin causes high CPU usage:

1. Open Settings panel
2. Increase update interval (default: 2000ms)
3. Try 3000ms or 5000ms for lower resource usage

---

## Development

### Testing Changes

After modifying plugin files:

```bash
# Reload Noctalia Shell
qs -c noctalia-shell reload

# Check logs
journalctl --user -u noctalia-shell -f
```

### Debug Mode

Enable verbose logging in Main.qml:

```qml
// Add debug logging
Logger.d("ASUS Fan Control", "Debug message: " + someValue);
```

### Plugin API

The plugin exposes these properties via `pluginApi.mainInstance`:

| Property | Type | Description |
|----------|------|-------------|
| `cpuTemp` | real | CPU temperature |
| `sysTemp` | real | System temperature |
| `pwm1Speed` | int | PWM1 speed percentage |
| `pwm3Speed` | int | PWM3 speed percentage |
| `pwm6Speed` | int | PWM6 speed percentage |
| `hardwareFound` | bool | Hardware detection status |
| `detectionStatus` | string | Detection status message |

---

## Requirements

- **Noctalia Shell** v3.6.0 or later
- **Linux** with NCT6775/NCT6798 chip
- **lm_sensors** package
- **polkit** for authentication

---

## Security

The plugin uses **polkit** for privileged operations:

- Only allows specific commands via `asus-fanctrl-detect`
- Restricted to your user account only
- No password caching or storage
- Minimal privilege escalation scope

**Polkit rule allows:**
- Loading nct6775 kernel module
- Executing `asus-fanctrl-detect` with any arguments

---

## Uninstallation

```bash
# Remove plugin directory
rm -rf ~/.config/noctalia/plugins/asus-fan-control

# Remove polkit rule
sudo rm /etc/polkit-1/rules.d/50-asus-fanctrl.rules

# Remove detection helper
sudo rm /usr/local/bin/asus-fanctrl-detect

# Reload Noctalia Shell
qs -c noctalia-shell reload
```

---

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test on your hardware
4. Submit a pull request

---

## License

MIT License - see [LICENSE](../LICENSE) for details.

---

## Disclaimer

This software controls hardware fans. Use at your own risk. Monitor system temperatures to ensure adequate cooling. The authors are not responsible for hardware damage.

---

## Support

- **Issues:** GitHub Issues
- **Discussions:** GitHub Discussions
- **Documentation:** [Noctalia Plugin Docs](https://docs.noctalia.dev/)

---

**Enjoy your silent (or performant) system! 🌡️💨**
