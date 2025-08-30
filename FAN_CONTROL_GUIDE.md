# Fan Control Setup for ASUS ROG STRIX B550-F Gaming WiFi II

## System Information
- **Motherboard**: ASUS ROG STRIX B550-F Gaming WiFi II
- **CPU**: AMD Ryzen 7 5800XT 8-Core Processor
- **Hardware Monitoring Chip**: Nuvoton NCT6798D Super I/O Sensors
- **Connected Fans**: Fan3 (587 RPM), Fan6 (1724 RPM)
- **PWM Channels**: 6 available (PWM1-PWM6)

## What Was Set Up

### 1. Hardware Detection
- Installed and configured `lm-sensors` package
- Ran `sensors-detect` to identify the Nuvoton NCT6798D chip
- Loaded the `nct6775` kernel module for hardware monitoring support
- All sensors are now accessible via `/sys/devices/platform/nct6775.656/hwmon/hwmon5/`

### 2. Available Tools

#### Basic Fan Control Script: `fan_control.sh`
A simple command-line tool for manual fan control:

**Usage:**
```bash
./fan_control.sh                    # Show current status
./fan_control.sh set 1 60           # Set PWM1 to 60%
./fan_control.sh manual 1           # Set PWM1 to manual mode
./fan_control.sh auto 1             # Return PWM1 to automatic mode
./fan_control.sh help               # Show help
```

#### Advanced Temperature-Based Daemon: `smart_fan_daemon.sh`
A smart daemon that automatically adjusts fan speed based on CPU temperature:

**Usage:**
```bash
./smart_fan_daemon.sh config        # Configure settings
./smart_fan_daemon.sh test          # Test configuration
./smart_fan_daemon.sh run           # Start the daemon
./smart_fan_daemon.sh stop          # Return to BIOS control
./smart_fan_daemon.sh status        # Show current status
```

#### GUI Monitoring Tool
- **psensor**: Graphical temperature and fan monitoring application
- Run `psensor` to launch the GUI

## PWM Control Modes

The NCT6798D chip supports several control modes for each PWM channel:
- `0`: No fan speed control
- `1`: Manual PWM mode (direct speed control)
- `2`: Thermal cruise mode (BIOS controlled)
- `3`: Fan speed cruise mode 
- `4`: Smart Fan III mode
- `5`: Smart Fan IV mode (default)

## Current Status

### Fan Detection
- **Fan3**: Connected, running at ~587 RPM
- **Fan6**: Connected, running at ~1724 RPM
- Other fan headers (1, 2, 4, 5, 7) appear to be unconnected

### PWM Channels Status
- **PWM1-4, PWM6**: Smart Fan IV automatic mode
- **PWM5**: Manual PWM mode (already controllable)

## Quick Commands

### Check Current Status
```bash
sensors
./fan_control.sh status
```

### Manual Fan Control Examples
```bash
# Set CPU fan (PWM1) to 50%
./fan_control.sh set 1 50

# Set case fan (PWM3) to 75%
./fan_control.sh set 3 75

# Return to automatic control
./fan_control.sh auto 1
```

### Temperature-Based Control
```bash
# Configure smart control
./smart_fan_daemon.sh config

# Start automatic temperature-based control
./smart_fan_daemon.sh run
```

## Configuration Examples

### Smart Daemon Default Settings
- **PWM Channel**: 1 (CPU fan)
- **Temperature Range**: 30°C - 70°C
- **Fan Speed Range**: 20% - 100%
- **Update Interval**: 5 seconds

### Temperature Curve (Default)
- 25°C → 20% fan speed
- 30°C → 20% fan speed
- 40°C → 40% fan speed
- 50°C → 60% fan speed
- 60°C → 80% fan speed
- 70°C → 100% fan speed
- 80°C+ → 100% fan speed

## Available PWM Channels for Your Fans

Based on your system detection:
- **PWM1**: Likely CPU fan header
- **PWM2**: May control a system fan or CPU cooler pump
- **PWM3**: Controls Fan3 (chassis fan)
- **PWM4**: Available for additional fans
- **PWM5**: Currently in manual mode
- **PWM6**: Controls Fan6 (chassis fan)

## Advanced Features

### System Integration
The kernel module `nct6775` is automatically loaded on boot thanks to the sensors configuration.

### Safe Operation
- All scripts include safety measures
- Manual control can be easily returned to automatic mode
- The daemon automatically restores BIOS control when stopped (Ctrl+C)

### Temperature Monitoring
Multiple temperature sensors available:
- **CPU (Tctl)**: Primary CPU temperature
- **SYSTIN**: System/motherboard temperature
- **AUXTIN0-4**: Additional temperature sensors
- **TSI0_TEMP**: CPU die temperature

## Recommendations

1. **For basic control**: Use `fan_control.sh` for manual adjustments
2. **For automatic control**: Use `smart_fan_daemon.sh` for temperature-based control
3. **For monitoring**: Use `psensor` GUI or `sensors` command
4. **Safety**: Always test changes gradually and monitor temperatures

## Troubleshooting

### If fans don't respond:
1. Check if the fan is connected to the right header
2. Verify the PWM channel corresponds to your fan header
3. Some fans may require minimum speed to start spinning
4. Try different PWM channels to find the right one for your fans

### To restore default behavior:
```bash
# Return all PWMs to automatic mode
for i in {1..6}; do ./fan_control.sh auto $i; done
```

### If the system seems unstable:
The motherboard BIOS will take over fan control if the system overheats, so hardware protection remains active.

## Files Created
- `fan_control.sh` - Basic fan control script
- `smart_fan_daemon.sh` - Advanced temperature-based daemon
- `FAN_CONTROL_GUIDE.md` - This guide
- `.fan_control_config` - Configuration file (created when using smart daemon)

## GUI Interface - Rofi Fan Control

### Quick Access
- **Terminal alias**: `fanctl` (launches the GUI)
- **Application menu**: Search for "Fan Control"
- **Keyboard shortcut**: Ctrl+Alt+F (after setup)

### Features
- 🌡️ Real-time temperature monitoring
- ⚡ Quick presets (Silent/Quiet/Performance/Max)
- 🔧 Individual PWM channel control
- 📊 Live fan RPM monitoring
- 🔄 Smart daemon integration
- Clean rofi-based interface

### Hyprland Keybinds (add to ~/.config/hypr/hyprland.conf)
```
# Fan Control GUI
bind = CTRL ALT, F, exec, /home/sasha/rofi_fan_control.sh

# Quick presets
bind = CTRL ALT, 1, exec, /home/sasha/fan_control.sh set 1 30; /home/sasha/fan_control.sh set 3 30; /home/sasha/fan_control.sh set 6 30  # Silent
bind = CTRL ALT, 2, exec, /home/sasha/fan_control.sh set 1 50; /home/sasha/fan_control.sh set 3 50; /home/sasha/fan_control.sh set 6 50  # Quiet
bind = CTRL ALT, 3, exec, /home/sasha/fan_control.sh set 1 80; /home/sasha/fan_control.sh set 3 80; /home/sasha/fan_control.sh set 6 80  # Performance
bind = CTRL ALT, 0, exec, /home/sasha/fan_control.sh auto 1; /home/sasha/fan_control.sh auto 3; /home/sasha/fan_control.sh auto 6  # Auto
```

## Additional Tools Available
- `sensors` - Command-line sensor readings
- `psensor` - GUI monitoring application
- `pwmconfig` - Built-in PWM configuration tool (advanced users)
- `rofi_fan_control.sh` - Modern rofi-based GUI

Your ASUS Strix motherboard now has full fan control capabilities with both CLI and GUI interfaces!
