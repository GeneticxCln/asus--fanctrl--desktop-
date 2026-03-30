# 🚀 Quick Start Guide

> Get your ASUS fan control system running in minutes

---

## Choose Your Setup

### 🎯 For Noctalia Shell Users (Recommended)

**Best for:** Desktop integration, GUI lovers, bar widget fans

```bash
# One command install
./install_noctalia_plugin.sh

# Reload Noctalia Shell
qs -c noctalia-shell reload
```

**You get:**
- ✅ Fan icon in your bar with temperature badge
- ✅ Click to open full control panel
- ✅ Slider controls for PWM1, PWM3, PWM6
- ✅ Quick preset buttons (Silent, Quiet, Performance, Max, Auto)
- ✅ Real-time temperature and RPM monitoring

---

### 💻 For Terminal Users

**Best for:** CLI workflow, minimal resources, any desktop environment

```bash
# Install zsh plugin
./setup_zsh_plugin.sh

# Activate (or restart terminal)
source ~/.zshrc
```

**You get:**
- ✅ `fcs` - Quick status check
- ✅ `fcsilent` - Silent mode (30%)
- ✅ `fcquiet` - Quiet mode (50%)
- ✅ `fcperf` - Performance mode (80%)
- ✅ `fanctrl-set 1 60` - Manual control

---

### 🏗️ Complete System Install

**Best for:** Full setup with all components, systemd daemon, keybindings

```bash
./install_complete_fanctrl.sh
```

**You get:**
- ✅ All CLI scripts installed
- ✅ Rofi GUI interface
- ✅ Smart fan daemon with systemd
- ✅ Hyprland keybindings (if config exists)
- ✅ Desktop menu entry

---

## ⚡ Quick Commands Reference

### Zsh Plugin Aliases

| Command | Alias | Action |
|---------|-------|--------|
| `fanctrl-status` | `fcs` | Show fan status |
| `fanctrl-silent` | `fcsilent` | Silent mode (30%) |
| `fanctrl-quiet` | `fcquiet` | Quiet mode (50%) |
| `fanctrl-performance` | `fcperf` | Performance (80%) |
| `fanctrl-max` | `fcmax` | Max speed (100%) |
| `fanctrl-auto` | `fcauto` | Return to auto |
| `fanctrl-set 1 60` | - | Set PWM1 to 60% |
| `fanctrl-gui` | - | Launch Rofi GUI |

---

### Noctalia Shell IPC Commands

```bash
# Open control panel
qs -c noctalia-shell ipc call plugin:asus-fan-control openPanel

# Presets
qs -c noctalia-shell ipc call plugin:asus-fan-control setSilent
qs -c noctalia-shell ipc call plugin:asus-fan-control setQuiet
qs -c noctalia-shell ipc call plugin:asus-fan-control setPerformance
qs -c noctalia-shell ipc call plugin:asus-fan-control setMax
qs -c noctalia-shell ipc call plugin:asus-fan-control setAuto

# Get status (JSON output)
qs -c noctalia-shell ipc call plugin:asus-fan-control getStatus

# Set specific PWM channel
qs -c noctalia-shell ipc call plugin:asus-fan-control setPwm 1 60
```

---

### CLI Scripts

```bash
# Status
./fan_control.sh status

# Set fan speed
./fan_control.sh set 1 60      # PWM1 to 60%
./fan_control.sh set 3 40      # PWM3 to 40%

# Return to auto
./fan_control.sh auto 1        # PWM1 to automatic
./fan_control.sh auto 3        # PWM3 to automatic

# Launch GUI
./rofi_fan_control.sh

# Daemon control
./smart_fan_daemon.sh config   # Configure
./smart_fan_daemon.sh run      # Run manually
sudo systemctl start smart-fan-daemon  # Via systemd
```

---

## 🎮 Example Keybinds

### Hyprland Configuration

Add to `~/.config/hypr/hyprland.conf`:

```bash
# Fan Control GUI
bind = CTRL ALT, F, exec, ~/.config/noctalia/plugins/asus-fan-control/Panel.qml

# Using Noctalia IPC (recommended if plugin installed)
bind = CTRL ALT, 1, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setSilent
bind = CTRL ALT, 2, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setQuiet
bind = CTRL ALT, 3, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setPerformance
bind = CTRL ALT, 0, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setAuto

# Using zsh plugin aliases
bind = CTRL ALT, 1, exec, fanctrl-silent
bind = CTRL ALT, 2, exec, fanctrl-quiet
bind = CTRL ALT, 3, exec, fanctrl-performance
bind = CTRL ALT, 0, exec, fanctrl-auto

# Temperature monitoring
bind = CTRL ALT, T, exec, rofi -e "$(sensors | grep -E '(Tctl|SYSTIN|fan):')" -theme-str 'window {width: 400px;}'
```

---

## 🛠️ Troubleshooting Quick Fixes

### Hardware Not Detected

```bash
# Load kernel module
sudo modprobe nct6775

# Check if chip detected
ls /sys/class/hwmon/hwmon*/name | xargs cat

# Test detection helper
asus-fanctrl-detect status
```

---

### Noctalia Plugin Issues

```bash
# Reload plugin
qs -c noctalia-shell reload

# Check logs
journalctl --user -u noctalia-shell -f

# Verify installation
ls ~/.config/noctalia/plugins/asus-fan-control/
```

---

### Permission Denied

```bash
# Noctalia: Restart polkit
sudo systemctl restart polkit

# CLI: Verify sudoers
sudo visudo -c -f /etc/sudoers.d/fanctrl

# Reinstall if needed
./setup_zsh_plugin.sh
```

---

### Zsh Plugin Not Loading

```bash
# Check if sourced
grep fan_control ~/.zshrc

# Reload shell
source ~/.zshrc

# Test command
fanctrl-help
```

---

## ✅ Verify Installation

Run the health check:

```bash
./scripts/verify_fanctrl.sh
```

Expected output:
```
[PASS] Found PWM path: /sys/class/hwmon/hwmon5
[PASS] Testing channel PWM1
[PASS] Manual mode set without password
[PASS] fan_control.sh set 1 40
[PASS] fan_control.sh auto 1
[PASS] Health check completed successfully.
```

---

## 📊 PWM Channels

| Channel | Typical Use | Notes |
|---------|-------------|-------|
| PWM1 | CPU Fan | Primary cooling |
| PWM3 | Chassis Fan 1 | Case ventilation |
| PWM6 | Chassis Fan 2 | Case ventilation |

---

## 🌡️ Temperature Monitoring

```bash
# Quick temperature check
sensors | grep -E '(Tctl|SYSTIN)'

# Via zsh plugin
fcs

# Via Noctalia IPC
qs -c noctalia-shell ipc call plugin:asus-fan-control getStatus | jq
```

---

## 🔄 Smart Fan Daemon Setup

For automatic temperature-based control:

```bash
# 1. Configure thresholds
./smart_fan_daemon.sh config

# 2. Enable systemd service
sudo systemctl enable --now smart-fan-daemon

# 3. Monitor
journalctl -u smart-fan-daemon -f
```

**Default settings:**
- Temperature range: 30°C - 70°C
- Fan speed range: 20% - 100%
- Update interval: 5 seconds

---

## 📖 Next Steps

- **[INSTALL.md](INSTALL.md)** - Detailed manual installation
- **[INTEGRATION_OPTIONS.md](INTEGRATION_OPTIONS.md)** - Compare plugin options
- **[FAN_CONTROL_GUIDE.md](FAN_CONTROL_GUIDE.md)** - Hardware guide
- **[SYSTEMD_SERVICE.md](SYSTEMD_SERVICE.md)** - Daemon configuration

---

**Need help?** Check the [troubleshooting section](README.md#troubleshooting) or view full documentation above.
