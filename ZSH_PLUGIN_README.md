# Zsh Plugin Integration

> Terminal-based fan control with convenient aliases and minimal resource usage

[![Zsh](https://img.shields.io/badge/Zsh-Plugin-red)]()
[![Shell](https://img.shields.io/badge/Shell-Bash-orange)]()
[![License](https://img.shields.io/badge/License-MIT-yellow)]()

---

## Features

- **⚡ Quick Aliases** - One-command fan control presets
- **📊 Status Display** - Colorful fan status overview
- **🎯 Manual Control** - Precise PWM channel adjustment
- **🖥️ Optional GUI** - Launch Rofi GUI if installed
- **🔒 Secure** - Minimal sudoers configuration
- **💪 Lightweight** - Minimal resource usage
- **🔄 Auto-detection** - Hardware detection and module loading

---

## Installation

### Quick Install

```bash
# Run the installer
./setup_zsh_plugin.sh

# Reload shell (or restart terminal)
source ~/.zshrc
```

The installer will:
1. ✅ Check/install dependencies (lm_sensors, rofi)
2. ✅ Detect NCT6775/NCT6798 hardware
3. ✅ Configure passwordless sudo
4. ✅ Add plugin to `.zshrc`
5. ✅ Configure auto-loading of kernel module

---

### Manual Installation

```bash
# 1. Install dependencies
sudo pacman -S lm_sensors rofi

# 2. Load kernel module
sudo modprobe nct6775

# 3. Add plugin to ~/.zshrc
cat >> ~/.zshrc << 'EOF'

# ASUS Fan Control Plugin
if [ -f "/path/to/fan_control_zsh_plugin.zsh" ]; then
    source "/path/to/fan_control_zsh_plugin.zsh"
fi
EOF

# 4. Install sudoers (replace USERNAME with your username)
sudo sed "s/USERNAME_PLACEHOLDER/$(whoami)/g" fanctrl_sudoers_zsh | \
  sudo tee /etc/sudoers.d/fanctrl
sudo chmod 0440 /etc/sudoers.d/fanctrl

# 5. Reload shell
source ~/.zshrc
```

---

## Usage

### Quick Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `fanctrl-status` | `fcs` | Show fan status |
| `fanctrl-silent` | `fcsilent` | Silent mode (30%) |
| `fanctrl-quiet` | `fcquiet` | Quiet mode (50%) |
| `fanctrl-performance` | `fcperf` | Performance (80%) |
| `fanctrl-max` | `fcmax` | Max speed (100%) |
| `fanctrl-auto` | `fcauto` | Return to auto |
| `fanctrl-set` | - | Manual control |
| `fanctrl-gui` | - | Launch Rofi GUI |
| `fanctrl-help` | - | Show help |

---

### Examples

#### Check Status
```bash
$ fcs
╭──────────────────────────────────────╮
│       🖥️  ASUS Fan Control Status    │
╰──────────────────────────────────────╯

🌡️  Temperatures:
   CPU: 45.0°C

💨  Fan RPMs:
   Fan3: 587 RPM
   Fan6: 1724 RPM

🔧  PWM Channels:
   PWM1:  50% - Smart Fan IV (Auto)
   PWM3:  43% - Smart Fan IV (Auto)
   PWM6:  20% - Smart Fan IV (Auto)
```

#### Quick Presets
```bash
# Silent mode for quiet work
fcsilent

# Performance mode for gaming/rendering
fcperf

# Max cooling for stress testing
fcmax

# Return to automatic control
fcauto
```

#### Manual Control
```bash
# Set CPU fan (PWM1) to 60%
fanctrl-set 1 60

# Set chassis fan (PWM3) to 40%
fanctrl-set 3 40

# Set chassis fan (PWM6) to 50%
fanctrl-set 6 50
```

#### Launch GUI
```bash
# Open Rofi fan control menu
fanctrl-gui
```

---

## PWM Channels

| Channel | Typical Use | Notes |
|---------|-------------|-------|
| PWM1 | CPU Fan | Primary cooling |
| PWM2 | CPU Fan 2 / Pump | May be unused |
| PWM3 | Chassis Fan 1 | Case ventilation |
| PWM4 | Chassis Fan 2 | May be unused |
| PWM5 | AIO Pump | May be unused |
| PWM6 | Chassis Fan 3 | Case ventilation |

**Note:** Your motherboard may have different channel assignments. Use `fcs` to see which channels are active.

---

## Configuration

### Auto-Load Kernel Module

The installer configures auto-loading. To verify:

```bash
cat /etc/modules-load.d/nct6775.conf
# Should output: nct6775
```

### Sudoers Configuration

Passwordless sudo is configured for minimal PWM control:

```bash
# Verify configuration
sudo visudo -c -f /etc/sudoers.d/fanctrl

# Expected output:
# /etc/sudoers.d/fanctrl: parsed OK
```

### Welcome Message

Enable welcome message on shell load by editing the plugin file:

```bash
# Uncomment this line in fan_control_zsh_plugin.zsh
_fanctrl_welcome
```

---

## Advanced Usage

### Scripting Examples

#### Temperature-Based Control
```bash
#!/bin/bash
# Simple temperature-based fan control

temp=$(sensors | grep 'Tctl:' | awk '{print $2}' | sed 's/+//g' | cut -d'.' -f1)

if [ "$temp" -gt 70 ]; then
    fanctrl-max
elif [ "$temp" -gt 50 ]; then
    fanctrl-performance
elif [ "$temp" -gt 30 ]; then
    fanctrl-quiet
else
    fanctrl-silent
fi
```

#### Cron Job for Scheduled Control
```bash
# Edit crontab
crontab -e

# Add scheduled performance mode during work hours
0 9 * * 1-5 /home/username/.config/noctalia/plugins/asus-fan-control/fanctrl-performance
0 18 * * 1-5 /home/username/.config/noctalia/plugins/asus-fan-control/fanctrl-quiet
```

#### System Monitor Integration
```bash
# Add to .zshrc for status in prompt
prompt_fanctrl() {
    local temp=$(sensors | grep 'Tctl:' | awk '{print $2}' | sed 's/+//g')
    echo "%{$fg[green]%}${temp}%{$reset_color%}"
}
```

---

## Integration with Window Managers

### Hyprland

Add to `~/.config/hypr/hyprland.conf`:

```bash
# Fan control keybinds using zsh plugin aliases
bind = CTRL ALT, F, exec, fanctrl-gui
bind = CTRL ALT, 1, exec, fanctrl-silent
bind = CTRL ALT, 2, exec, fanctrl-quiet
bind = CTRL ALT, 3, exec, fanctrl-performance
bind = CTRL ALT, 0, exec, fanctrl-auto
bind = CTRL ALT, T, exec, rofi -e "$(sensors)" -theme-str 'window {width: 400px;}'
```

### i3/Sway

Add to `~/.config/i3/config` or `~/.config/sway/config`:

```bash
# Fan control keybinds
bindsym Ctrl+Mod1+f exec --no-startup-id fanctrl-gui
bindsym Ctrl+Mod1+1 exec --no-startup-id fanctrl-silent
bindsym Ctrl+Mod1+2 exec --no-startup-id fanctrl-quiet
bindsym Ctrl+Mod1+3 exec --no-startup-id fanctrl-performance
bindsym Ctrl+Mod1+0 exec --no-startup-id fanctrl-auto
```

### GNOME/KDE

Use system keyboard shortcuts:
1. Open Settings → Keyboard Shortcuts
2. Add custom shortcuts pointing to `fanctrl-silent`, `fanctrl-quiet`, etc.

---

## Troubleshooting

### Plugin Not Loading

```bash
# Check if plugin is sourced
grep fan_control ~/.zshrc

# Check if file exists
ls -la /path/to/fan_control_zsh_plugin.zsh

# Reload shell
source ~/.zshrc

# Test command
fanctrl-help
```

---

### Hardware Not Detected

```bash
# Check if module is loaded
lsmod | grep nct6775

# Load manually
sudo modprobe nct6775

# Check for chip
ls /sys/class/hwmon/hwmon*/name | xargs cat

# Run sensors-detect
sudo sensors-detect
```

---

### Permission Denied

```bash
# Verify sudoers configuration
sudo visudo -c -f /etc/sudoers.d/fanctrl

# Test sudo access
echo 1 | sudo tee /sys/class/hwmon/hwmon5/pwm1_enable

# Reinstall if needed
./setup_zsh_plugin.sh
```

---

### Command Not Found

```bash
# Check PATH
echo $PATH

# Source plugin manually
source /path/to/fan_control_zsh_plugin.zsh

# Verify aliases
alias | grep fanctrl
```

---

### Rofi GUI Not Working

```bash
# Check if rofi is installed
which rofi

# Install if missing
sudo pacman -S rofi

# Test rofi
rofi -e "test"

# Run GUI directly
/path/to/rofi_fan_control.sh
```

---

## Uninstallation

```bash
# Remove from ~/.zshrc
sed -i '/fan_control_zsh_plugin/d' ~/.zshrc

# Remove sudoers
sudo rm /etc/sudoers.d/fanctrl

# Remove module auto-load
sudo rm /etc/modules-load.d/nct6775.conf

# Reload shell
source ~/.zshrc
```

---

## Development

### Plugin Structure

```
fan_control_zsh_plugin.zsh    # Main plugin file
fanctrl_sudoers_zsh           # Sudoers configuration
setup_zsh_plugin.sh           # Installer
```

### Adding Custom Commands

Edit `fan_control_zsh_plugin.zsh`:

```bash
# Add custom function
fanctrl-custom() {
    echo "Custom fan control"
    _fanctrl_set_speed 1 45
    _fanctrl_set_speed 3 45
}

# Add alias
alias fccustom='fanctrl-custom'
```

---

## Requirements

- **zsh** shell
- **Linux** with NCT6775/NCT6798 chip
- **lm_sensors** package
- **rofi** (optional, for GUI)
- **sudo** access

---

## Security

The plugin uses **sudoers** for privileged operations:

- Only allows `tee` commands to PWM sysfs files
- Restricted to specific hardware paths
- No password caching or storage
- Minimal privilege escalation scope

**Sudoers allows:**
- Writing to `/sys/class/hwmon/hwmon*/pwm*`
- Writing to `/sys/class/hwmon/hwmon*/pwm*_enable`
- Running `asus-fanctrl-detect`

---

## Tips

### 1. Add Status to Prompt
```bash
# Add to ~/.zshrc
PROMPT='$(fanctrl-status 2>/dev/null | head -1)'$PROMPT
```

### 2. Create Custom Presets
```bash
# Add to ~/.zshrc
alias fcnight='fanctrl-set 1 20; fanctrl-set 3 20'  # Night mode
alias fcturbo='fanctrl-set 1 100; fanctrl-set 3 80' # Turbo mode
```

### 3. Quick Temperature Check
```bash
# Add to ~/.zshrc
alias temp='sensors | grep -E "(Tctl|SYSTIN)"'
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

**Stay cool and code on! 🌡️💻**
