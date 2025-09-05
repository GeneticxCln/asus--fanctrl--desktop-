# ASUS Fan Control Installation Guide

## Prerequisites

- Arch Linux or compatible distribution
- `lm_sensors` package installed
- `rofi` for GUI menu
- `sudo` access

## Installation Steps

### 1. Install Required Packages
```bash
sudo pacman -S lm_sensors rofi
```

### 2. Setup Hardware Monitoring
```bash
sudo sensors-detect
```
Follow the prompts and accept the defaults.

### 3. Clone and Setup Fan Control
```bash
git clone <your-repo-url>
cd asus--fanctrl--desktop-
chmod +x *.sh
```

### 4. Configure Passwordless Sudo (IMPORTANT)

Create a sudoers file to allow passwordless fan control:

```bash
sudo tee /etc/sudoers.d/fan-control << 'EOF'
# Allow user to run fan control commands without password
$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/class/hwmon/hwmon*/pwm*_enable
$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/class/hwmon/hwmon*/pwm*
EOF

sudo chmod 440 /etc/sudoers.d/fan-control
```

### 5. Add Keybinds to Hyprland

Add these lines to your Hyprland configuration:

```bash
# Fan Control Keybindings
bind = CTRL ALT, F, exec, /path/to/your/rofi_fan_control.sh
bind = CTRL ALT, 1, exec, /path/to/your/fan_control.sh set 1 30; /path/to/your/fan_control.sh set 3 30; /path/to/your/fan_control.sh set 6 30  # Silent mode
bind = CTRL ALT, 2, exec, /path/to/your/fan_control.sh set 1 50; /path/to/your/fan_control.sh set 3 50; /path/to/your/fan_control.sh set 6 50  # Quiet mode  
bind = CTRL ALT, 3, exec, /path/to/your/fan_control.sh set 1 80; /path/to/your/fan_control.sh set 3 80; /path/to/your/fan_control.sh set 6 80  # Performance mode
bind = CTRL ALT, 0, exec, /path/to/your/fan_control.sh auto 1; /path/to/your/fan_control.sh auto 3; /path/to/your/fan_control.sh auto 6  # Auto mode
bind = CTRL ALT, T, exec, rofi -e "$(sensors | grep -E '(Tctl|SYSTIN|fan[36]):')" -theme-str 'window {width: 400px;}'
```

### 6. Test Installation

```bash
# Test fan control script
./fan_control.sh status

# Test GUI (should not ask for password)
./rofi_fan_control.sh
```

## Usage

### Keyboard Shortcuts
- `Ctrl+Alt+F` - Open fan control GUI
- `Ctrl+Alt+1` - Silent mode (30%)
- `Ctrl+Alt+2` - Quiet mode (50%)
- `Ctrl+Alt+3` - Performance mode (80%)
- `Ctrl+Alt+0` - Auto mode (BIOS control)
- `Ctrl+Alt+T` - Show temperatures

### Command Line
```bash
./fan_control.sh status              # Show current status
./fan_control.sh set 1 60            # Set PWM1 to 60%
./fan_control.sh auto 1              # Return PWM1 to automatic
```

## Troubleshooting

### Permission Denied Errors
Make sure the sudoers file is properly configured as shown in step 4.

### Wrong Hardware Path
The script auto-detects the NCT6798 chip location. If it fails, check:
```bash
find /sys/class/hwmon/ -name name -exec sh -c 'echo -n "$1: "; cat "$1"' _ {} \;
```

### Keybinds Not Working
1. Restart Hyprland after adding keybinds
2. Check that the script paths are correct
3. Test scripts manually first

## Compatible Hardware
- ASUS ROG STRIX B550-F Gaming motherboard
- NCT6798 sensor chip
- Should work with other ASUS motherboards using NCT6798

## Security Note
The sudoers configuration only allows specific commands related to PWM control. This minimizes security risk while enabling passwordless fan control.
