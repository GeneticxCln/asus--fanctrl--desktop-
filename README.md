<div align="center">
  <h1>🌬️ ASUS ROG Fan Control System</h1>
  <p>A comprehensive, modular fan control solution for the ASUS ROG STRIX B550-F (NCT6775) with multiple integrations.</p>

  [![Platform-Linux](https://img.shields.io/badge/Platform-Linux-blue)](https://kernel.org/)
  [![Hardware-ASUS_B550F](https://img.shields.io/badge/Hardware-ASUS_B550F-green)]()
  [![License-MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
</div>

---

## ✨ Features

- 🎛️ **Modular Design**: Choose between Noctalia Shell, Zsh, Rofi, or raw CLI integrations
- ⚡ **No-Password Sudo**: Uses Polkit and restricted sudoers for secure, seamless operation
- 🌡️ **Smart Daemon**: Optional background daemon for automatic temperature-based fan curves
- 🎯 **Quick Presets**: Jump between Silent (30%), Quiet (50%), Performance (80%), and Auto modes instantly
- 📊 **Real-time Monitoring**: Live CPU and System temperature along with fan RPM displays

---

## 🧩 Integration Options

This project includes multiple ways to interact with your fans. You can install one or all of them depending on your workflow.

### 1. 🌌 Noctalia Shell Plugin (Native GUI)
A beautiful, native QML plugin for Noctalia Shell users. Includes a bar widget with a live temperature badge and a full control panel with sliders.
```bash
./install_noctalia_plugin.sh
qs -c noctalia-shell reload
```
**Usage:** `Ctrl+Alt+F` to open the panel, or click the tray icon.

### 2. 💻 Zsh Plugin (CLI Aliases)
Perfect for terminal power-users. Adds fast aliases for quick fan adjustments directly in your shell.
```bash
./setup_zsh_plugin.sh
source ~/.zshrc
```
**Usage:** `fcsilent` (Silent), `fcquiet` (Quiet), `fcperf` (Performance), `fcs` (Status).

### 3. 🖥️ Rofi GUI (Any Window Manager)
A lightweight menu-based interface. Works great on any DE or Window Manager (especially Hyprland).
```bash
./install_complete_fanctrl.sh  # Installs scripts and dependencies
./rofi_fan_control.sh          # Launch GUI
```

### 4. ⚙️ Smart SystemD Daemon (Background Automation)
Runs in the background and adjusts fan speed based on linear temperature curves (e.g. 30°C–70°C).
```bash
./install_systemd_service.sh
sudo systemctl enable --now smart-fan-daemon
```

---

## 🚀 Quick Install (All-in-One)

If you want the base scripts, Rofi menu, and Hyprland bindings without installing the Noctalia/Zsh specific plugins:

```bash
git clone https://github.com/yourusername/asus-b550f-fanctrl.git
cd asus-b550f-fanctrl
./install_complete_fanctrl.sh
```

**What it does:**
1. Installs dependencies (`rofi`, `lm_sensors`)
2. Probes the kernel (`modprobe nct6775`)
3. Automatically detects your hardware PWM paths
4. Configures secure, passwordless execution

---

## 🎮 Standard Usage & Keybinds

### CLI Commands
```bash
./fan_control.sh status         # Show full fan/temperature status
./fan_control.sh set 1 60       # Set PWM1 (CPU Fan) to 60%
./fan_control.sh auto 1         # Return PWM1 to BIOS control
```

### Hyprland Keybinds Reference
Add these to your `hyprland.conf`:
| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+F` | Open Rofi/Noctalia GUI |
| `Ctrl+Alt+1` | Silent Mode (30%) |
| `Ctrl+Alt+2` | Quiet Mode (50%) |
| `Ctrl+Alt+3` | Performance Mode (80%) |
| `Ctrl+Alt+0` | Auto Mode (BIOS Default) |

---

## 🧠 Smart Fan Configuration

If you installed the daemon, configure your temperature curve:
```bash
./smart_fan_daemon.sh config
```
This saves your settings to `~/.config/fanctrl.conf`. The daemon uses linear interpolation between your `temp_min` and `temp_max` values to ensure smooth transitions.

---

## 🛠️ Troubleshooting

**Hardware Not Detected**
Manually check if the module is loaded and paths exist:
```bash
sudo modprobe nct6775
ls /sys/devices/platform/nct6775.*
find /sys/class/hwmon/ -name "hwmon*"
```

**Permission Denied Issues**
Verify the sudoers rule or polkit policy is correct:
```bash
sudo visudo -c -f /etc/sudoers.d/fanctrl
# For Noctalia Plugin:
cat /etc/polkit-1/rules.d/50-asus-fanctrl.rules
```

---

## 🤝 Contributing

Contributions are highly welcome! Since this is hardware-specific, testing on your own NCT-based motherboard is greatly appreciated. Submit a PR or open an issue.

## 📄 License & Disclaimer

- **License:** MIT License. Feel free to modify and adapt.
- **Disclaimer:** Controlling hardware fans entails risk. Ensure adequate cooling at all times to prevent thermal damage. The authors are not responsible for burned hardware.
