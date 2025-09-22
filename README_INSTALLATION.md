# Complete Fan Control System Installer

This directory contains a complete fan control system for ASUS ROG STRIX B550-F motherboard with NCT6775 chip.

## Quick Installation on Fresh System

Run this single command to install everything:

```bash
./install_complete_fanctrl.sh
```

## What Gets Installed

The installation script will automatically:

1. **Detect your Linux distribution** and install required packages:
   - `rofi` (for GUI interface)
   - `lm-sensors` (for temperature monitoring)

2. **Detect NCT6775 hardware** and configure the correct paths automatically

3. **Install fan control scripts** to `/home/username/fanctrl/`:
   - `fan_control.sh` - Command-line fan control
   - `rofi_fan_control.sh` - GUI fan control interface
   - `smart_fan_daemon.sh` - Temperature-based automatic control
   - `test_fan_gui.sh` - Installation testing

4. **Configure passwordless sudo** for fan control operations

5. **Add Hyprland keybindings** (if Hyprland config exists):
   - `Ctrl+Alt+F` - Open fan control GUI
   - `Ctrl+Alt+1` - Silent mode (30%)
   - `Ctrl+Alt+2` - Quiet mode (50%)
   - `Ctrl+Alt+3` - Performance mode (80%)
   - `Ctrl+Alt+0` - Auto mode
   - `Ctrl+Alt+T` - Temperature monitoring

6. **Create desktop entry** for easy access from application menus

7. **Test the complete installation** to ensure everything works

## Supported Distributions

- Arch Linux / CachyOS / Manjaro (pacman)
- Ubuntu / Debian (apt)
- Fedora / RHEL (dnf)
- openSUSE (zypper)

## Hardware Requirements

- ASUS ROG STRIX B550-F motherboard (or compatible NCT6775 chip)
- Linux kernel with nct6775 module support

## Manual Installation (if needed)

If the automatic script doesn't work for your setup:

1. Install dependencies manually:
   ```bash
   # Arch/CachyOS
   sudo pacman -S rofi lm_sensors
   
   # Ubuntu/Debian
   sudo apt install rofi lm-sensors
   
   # Fedora
   sudo dnf install rofi lm_sensors
   ```

2. Copy scripts to desired location
3. Run `sudo ./install_sudoers.sh` manually
4. Add keybindings to your window manager configuration

## Recommended sudoers install and quick verification

- Install sudoers rules:
  ```bash
  sudo ./install_sudoers.sh
  ```

- Verify passwordless control works (no password prompts expected):
  ```bash
  ./fan_control.sh set 1 40
  ./fan_control.sh auto 1
  ```

Notes:
- The installer targets the invoking user and uses generic /sys/class/hwmon paths.
- The ROFI GUI delegates privileged writes to fan_control.sh, keeping sudo touches in one place.

## Post-Installation

After installation, test everything with:
```bash
~/fanctrl/test_fan_gui.sh
```

Configure the smart daemon:
```bash
~/fanctrl/smart_fan_daemon.sh config
```

## Troubleshooting

If you encounter issues:

1. **Hardware not detected**: Ensure nct6775 module is loaded:
   ```bash
   sudo modprobe nct6775
   ```

2. **Permission denied**: The sudoers configuration may not be active yet. Try logging out and back in.

3. **GUI not working**: Ensure rofi is installed and X11/Wayland is running.

4. **Wrong hardware paths**: The script auto-detects hardware paths, but you may need to manually check `/sys/devices/platform/nct6775.*/hwmon/` for the correct path.

## Files Included

- `install_complete_fanctrl.sh` - Complete installation script
- `fan_control.sh` - Core fan control functionality
- `rofi_fan_control.sh` - GUI interface
- `smart_fan_daemon.sh` - Smart temperature-based control
- `test_fan_gui.sh` - Testing utilities
- `install_sudoers.sh` - Sudoers configuration (legacy)
- `hyprland_fan_keybind.conf` - Keybinding reference
