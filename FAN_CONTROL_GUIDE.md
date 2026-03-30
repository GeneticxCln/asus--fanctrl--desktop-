# Fan Control Guide

> Comprehensive guide to controlling fans on ASUS ROG STRIX B550-F motherboards

---

## System Information

### Supported Hardware

| Component | Model |
|-----------|-------|
| **Motherboard** | ASUS ROG STRIX B550-F Gaming WiFi II |
| **CPU** | AMD Ryzen 5000/3000 series |
| **Sensor Chip** | Nuvoton NCT6798D Super I/O |
| **Kernel Module** | `nct6775` |

### Compatible Systems

This guide also applies to:
- ASUS ROG STRIX B550-F Gaming WiFi
- ASUS ROG STRIX B550-A Gaming
- ASUS TUF Gaming B550 series
- Any motherboard with NCT6775/NCT6798 chip

---

## Hardware Overview

### PWM Channels

Your motherboard has 6 PWM channels for fan control:

| Channel | Header | Typical Use |
|---------|--------|-------------|
| PWM1 | CPU_FAN | CPU cooler |
| PWM2 | CPU_OPT | AIO pump / secondary CPU fan |
| PWM3 | CHA_FAN1 | Chassis fan 1 |
| PWM4 | CHA_FAN2 | Chassis fan 2 |
| PWM5 | AIO_PUMP | Water cooling pump |
| PWM6 | CHA_FAN3 | Chassis fan 3 |

### Fan Headers

```
┌─────────────────────────────────────────┐
│                                         │
│   CPU_FAN (PWM1)    CPU_OPT (PWM2)      │
│                                         │
│                                         │
│   CHA_FAN1 (PWM3)   CHA_FAN2 (PWM4)     │
│                                         │
│   AIO_PUMP (PWM5)   CHA_FAN3 (PWM6)     │
│                                         │
└─────────────────────────────────────────┘
```

### Control Modes

The NCT6798D chip supports several control modes:

| Mode | Value | Description |
|------|-------|-------------|
| Disabled | 0 | No fan speed control |
| Manual PWM | 1 | Direct PWM value control |
| Thermal Cruise | 2 | BIOS temperature-based control |
| Fan Speed Cruise | 3 | BIOS RPM-based control |
| Smart Fan III | 4 | Older ASUS smart mode |
| Smart Fan IV | 5 | Latest ASUS smart mode (default) |

---

## Quick Start

### 1. Load Kernel Module

```bash
# Load the module
sudo modprobe nct6775

# Verify it's loaded
lsmod | grep nct6775

# Configure auto-load on boot
echo "nct6775" | sudo tee /etc/modules-load.d/nct6775.conf
```

### 2. Detect Hardware

```bash
# Run sensors-detect (answer yes to all)
sudo sensors-detect

# Check sensor output
sensors
```

Expected output:
```
nct6798-isa-0290
Adapter: ISA adapter
Tctl:         +45.0°C
SYSTIN:       +38.0°C
fan3:         587 RPM
fan6:        1724 RPM
```

### 3. Test Fan Control

```bash
# Check current status
./fan_control.sh status

# Set CPU fan to 50%
./fan_control.sh set 1 50

# Return to automatic
./fan_control.sh auto 1
```

---

## Using the Scripts

### fan_control.sh

The main CLI tool for fan control.

**Usage:**
```bash
./fan_control.sh                    # Show status
./fan_control.sh status             # Show detailed status
./fan_control.sh set 1 60           # Set PWM1 to 60%
./fan_control.sh manual 1           # Set PWM1 to manual mode
./fan_control.sh auto 1             # Set PWM1 to automatic mode
./fan_control.sh help               # Show help
```

**Examples:**

```bash
# Silent operation (30% all fans)
./fan_control.sh set 1 30
./fan_control.sh set 3 30
./fan_control.sh set 6 30

# Performance mode (80% all fans)
./fan_control.sh set 1 80
./fan_control.sh set 3 80
./fan_control.sh set 6 80

# Return all fans to BIOS control
./fan_control.sh auto 1
./fan_control.sh auto 3
./fan_control.sh auto 6
```

---

### rofi_fan_control.sh

GUI interface using Rofi.

**Usage:**
```bash
./rofi_fan_control.sh
```

**Menu Options:**
- 🌡️ CPU Temp - Current temperature
- 🔧 PWM Channels - Individual control
- ⚡ Quick Presets - Silent/Quiet/Performance/Max/Auto
- 🔧 Manual Control - Per-channel adjustment
- 📊 Monitoring - RPM display
- 🔄 Smart Daemon - Daemon management

---

### smart_fan_daemon.sh

Temperature-based automatic fan control.

**Usage:**
```bash
./smart_fan_daemon.sh config        # Configure
./smart_fan_daemon.sh test          # Test configuration
./smart_fan_daemon.sh run           # Run daemon
./smart_fan_daemon.sh stop          # Stop daemon
./smart_fan_daemon.sh status        # Show status
```

**Configuration:**
```
=== Fan Control Configuration ===

Enter PWM channel [1]: 1
Minimum temperature (°C) [30]: 30
Maximum temperature (°C) [70]: 70
Minimum fan speed (%) [20]: 20
Maximum fan speed (%) [100]: 100
Update interval (seconds) [5]: 5
```

**Default Temperature Curve:**

| Temperature | Fan Speed |
|-------------|-----------|
| ≤30°C | 20% |
| 40°C | 40% |
| 50°C | 60% |
| 60°C | 80% |
| ≥70°C | 100% |

---

## Rofi GUI Interface

### Main Menu

```
╭──────────────────────────────────────╮
│       Fan Control                    │
╰──────────────────────────────────────╯
🌡️  CPU Temp: 45.0°C
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧  PWM1 (CPU Fan): 50% (Manual)
🔧  PWM3 (Chassis): 43% - 587 RPM
🔧  PWM6 (Chassis): 20% - 1724 RPM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡  Quick Presets
🔧  Manual Control
📊  Monitoring
🔄  Smart Daemon
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌  Exit
```

### Quick Presets Menu

```
╭──────────────────────────────────────╮
│       Quick Presets                  │
╰──────────────────────────────────────╯
🔇  Silent Mode (30%)
🔉  Quiet Mode (50%)
🔊  Performance Mode (80%)
🚀  Max Speed (100%)
🔄  Auto Mode (BIOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⬅️  Back to Main Menu
```

---

## Keyboard Shortcuts

### Hyprland Configuration

Add to `~/.config/hypr/hyprland.conf`:

```bash
# Fan Control GUI
bind = CTRL ALT, F, exec, ./rofi_fan_control.sh

# Quick presets
bind = CTRL ALT, 1, exec, ./fan_control.sh set 1 30; ./fan_control.sh set 3 30; ./fan_control.sh set 6 30
bind = CTRL ALT, 2, exec, ./fan_control.sh set 1 50; ./fan_control.sh set 3 50; ./fan_control.sh set 6 50
bind = CTRL ALT, 3, exec, ./fan_control.sh set 1 80; ./fan_control.sh set 3 80; ./fan_control.sh set 6 80
bind = CTRL ALT, 0, exec, ./fan_control.sh auto 1; ./fan_control.sh auto 3; ./fan_control.sh auto 6

# Temperature monitoring
bind = CTRL ALT, T, exec, rofi -e "$(sensors | grep -E '(Tctl|SYSTIN|fan):')" -theme-str 'window {width: 400px;}'
```

### Keybind Reference

| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+F` | Open fan control GUI |
| `Ctrl+Alt+1` | Silent mode (30%) |
| `Ctrl+Alt+2` | Quiet mode (50%) |
| `Ctrl+Alt+3` | Performance mode (80%) |
| `Ctrl+Alt+0` | Auto mode (BIOS) |
| `Ctrl+Alt+T` | Temperature monitoring |

---

## Temperature Monitoring

### Command Line

```bash
# Quick temperature check
sensors | grep -E '(Tctl|SYSTIN)'

# Detailed sensor output
sensors

# Watch temperatures in real-time
watch -n 1 sensors
```

### Via Scripts

```bash
# Show status with temperatures
./fan_control.sh status

# Via zsh plugin
fcs
```

### Temperature Guidelines

| Temperature | Status | Recommended Action |
|-------------|--------|-------------------|
| < 40°C | Normal | Silent/Quiet mode |
| 40-60°C | Normal load | Quiet/Performance mode |
| 60-80°C | Heavy load | Performance mode |
| 80-90°C | High | Max speed, check cooling |
| > 90°C | Critical | Investigate cooling issues |

---

## Fan Curves

### Creating Custom Fan Curves

#### Simple Linear Curve

```bash
#!/bin/bash
# Simple temperature-based fan control

temp=$(sensors | grep 'Tctl:' | awk '{print $2}' | sed 's/+//g' | cut -d'.' -f1)

# Linear interpolation: 30°C=20%, 70°C=100%
if [ "$temp" -le 30 ]; then
    speed=20
elif [ "$temp" -ge 70 ]; then
    speed=100
else
    speed=$((20 + (temp - 30) * 80 / 40))
fi

./fan_control.sh set 1 $speed
```

#### Step-Based Curve

```bash
#!/bin/bash
# Step-based fan curve

temp=$(sensors | grep 'Tctl:' | awk '{print $2}' | sed 's/+//g' | cut -d'.' -f1)

if [ "$temp" -lt 40 ]; then
    speed=30   # Silent
elif [ "$temp" -lt 55 ]; then
    speed=50   # Quiet
elif [ "$temp" -lt 70 ]; then
    speed=70   # Balanced
elif [ "$temp" -lt 80 ]; then
    speed=85   # Performance
else
    speed=100  # Max
fi

./fan_control.sh set 1 $speed
./fan_control.sh set 3 $speed
./fan_control.sh set 6 $speed
```

---

## Systemd Service

### Installing the Daemon

```bash
# Run installer
./install_systemd_service.sh

# Enable and start
sudo systemctl enable --now smart-fan-daemon

# Check status
sudo systemctl status smart-fan-daemon

# View logs
journalctl -u smart-fan-daemon -f
```

### Service Management

```bash
# Start service
sudo systemctl start smart-fan-daemon

# Stop service
sudo systemctl stop smart-fan-daemon

# Restart service
sudo systemctl restart smart-fan-daemon

# Disable auto-start
sudo systemctl disable smart-fan-daemon
```

### Service Logs

```bash
# Recent logs
journalctl -u smart-fan-daemon -n 50

# Follow logs in real-time
journalctl -u smart-fan-daemon -f

# Logs from specific time
journalctl -u smart-fan-daemon --since "1 hour ago"
```

---

## Troubleshooting

### Hardware Not Detected

```bash
# Check if module is loaded
lsmod | grep nct6775

# Load module manually
sudo modprobe nct6775

# Check for chip
ls /sys/class/hwmon/hwmon*/name | xargs cat

# Check dmesg for errors
dmesg | grep nct6775
```

### Permission Denied

```bash
# Verify sudoers configuration
sudo visudo -c -f /etc/sudoers.d/fan-control

# Test sudo access
echo 1 | sudo tee /sys/class/hwmon/hwmon5/pwm1_enable

# Reinstall sudoers
sudo ./install_sudoers.sh
```

### Fan Not Responding

```bash
# Check if PWM file exists
ls -la /sys/class/hwmon/hwmon*/pwm*

# Test manual control
./fan_control.sh set 1 50

# Check fan mode
cat /sys/class/hwmon/hwmon5/pwm1_enable

# Try different PWM channel
./fan_control.sh set 3 50
```

### To Restore Default Behavior

```bash
# Return all PWMs to automatic mode
for i in {1..6}; do ./fan_control.sh auto $i; done

# Or use the quick command
fcauto
```

---

## Advanced Topics

### Finding Your hwmon Path

```bash
# Find all hwmon devices
for path in /sys/class/hwmon/hwmon*; do
    echo "$path: $(cat $path/name 2>/dev/null)"
done

# Example output:
# /sys/class/hwmon/hwmon0: k10temp
# /sys/class/hwmon/hwmon5: nct6798
```

### Understanding PWM Values

PWM values range from 0-255:

| Percentage | PWM Value | Description |
|------------|-----------|-------------|
| 0% | 0 | Fan off |
| 20% | 51 | Minimum speed |
| 30% | 77 | Silent |
| 50% | 128 | Quiet |
| 70% | 179 | Balanced |
| 80% | 204 | Performance |
| 100% | 255 | Maximum |

### Manual PWM Control

```bash
# Find your hwmon path
PWM_PATH=$(find /sys/class/hwmon/ -name "hwmon*" -exec sh -c 'grep -q "nct6798" "$1/name" 2>/dev/null && echo "$1"' _ {} \;)

# Set to manual mode
echo 1 | sudo tee $PWM_PATH/pwm1_enable

# Set PWM value (0-255)
echo 128 | sudo tee $PWM_PATH/pwm1

# Return to auto mode
echo 5 | sudo tee $PWM_PATH/pwm1_enable
```

---

## Safety Considerations

### ⚠️ Important Warnings

1. **Monitor temperatures** when testing new fan speeds
2. **Start conservative** - begin with higher speeds and reduce gradually
3. **Don't run too low** - ensure minimum cooling for your hardware
4. **Test under load** - verify cooling during gaming/rendering
5. **Return to auto** if unsure - BIOS control is always safe

### Safe Temperature Ranges

| Component | Safe Range | Warning | Critical |
|-----------|------------|---------|----------|
| CPU | < 80°C | 80-90°C | > 90°C |
| Motherboard | < 60°C | 60-70°C | > 70°C |
| VRM | < 100°C | 100-120°C | > 120°C |

### Emergency Recovery

If fans stop responding:

1. **Reboot** - BIOS will take control
2. **Clear CMOS** - Reset BIOS settings if needed
3. **Check connections** - Ensure fans are properly connected

---

## Files Reference

| File | Purpose |
|------|---------|
| `fan_control.sh` | Main CLI control script |
| `fan_control_lib.sh` | Shared library functions |
| `rofi_fan_control.sh` | Rofi GUI interface |
| `smart_fan_daemon.sh` | Temperature daemon |
| `fanctrl-helper.sh` | Sudo helper script |
| `asus-fanctrl-detect` | Hardware detection helper |

### Configuration Files

| File | Purpose |
|------|---------|
| `~/.config/fanctrl.conf` | Daemon configuration |
| `/etc/modules-load.d/nct6775.conf` | Kernel module auto-load |
| `/etc/sudoers.d/fanctrl` | Sudoers configuration |
| `/etc/polkit-1/rules.d/50-asus-fanctrl.rules` | Polkit rules |

---

## Additional Resources

- [lm_sensors Documentation](https://github.com/lm-sensors/lm-sensors)
- [NCT6775 Kernel Module](https://www.kernel.org/doc/html/latest/hwmon/nct6775.html)
- [ASUS ROG STRIX B550-F Manual](https://www.asus.com/support/)

---

**Stay cool! 🌡️💨**
