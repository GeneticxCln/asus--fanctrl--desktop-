# ASUS Fan Control System

> Complete fan control solution for ASUS ROG STRIX B550-F motherboards with NCT6775/NCT6798 chips

[![Platform](https://img.shields.io/badge/Platform-Linux-blue)]()
[![Hardware](https://img.shields.io/badge/Hardware-ASUS_B550F-green)]()
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash-orange)]()

---

## 🌟 Features

- **🎛️ Multiple Interfaces** - CLI, Rofi GUI, Noctalia Shell plugin, Zsh integration
- **🤖 Smart Automation** - Temperature-based automatic fan control daemon
- **⌨️ Keyboard Shortcuts** - Hyprland keybindings for instant control
- **📊 Real-time Monitoring** - Live temperature and RPM monitoring
- **🎯 Quick Presets** - Silent, Quiet, Performance, and Max modes
- **🔒 Secure** - Polkit/sudoers with minimal privilege escalation

---

## 🚀 Quick Start

### Option 1: Noctalia Shell Plugin (Recommended for Noctalia users)
```bash
./install_noctalia_plugin.sh
```
Provides: Bar widget with temperature badge + Full GUI control panel

### Option 2: Zsh Plugin (CLI-focused)
```bash
./setup_zsh_plugin.sh
source ~/.zshrc
```
Provides: Terminal aliases (`fcs`, `fcsilent`, `fcquiet`, `fcperf`)

### Option 3: Complete System (All components)
```bash
./install_complete_fanctrl.sh
```
Provides: Scripts + GUI + Daemon + Keybindings + Desktop entry

---

## 📋 Usage

### CLI Commands
```bash
# Check status
fanctrl-status          # or: fcs

# Quick presets
fanctrl-silent          # 30% - Silent mode
fanctrl-quiet           # 50% - Quiet mode
fanctrl-performance     # 80% - Performance mode
fanctrl-max             # 100% - Max speed
fanctrl-auto            # Return to BIOS control

# Manual control
fanctrl-set 1 60        # Set PWM1 (CPU fan) to 60%
fanctrl-set 3 40        # Set PWM3 to 40%
```

### Noctalia Shell IPC
```bash
# Open panel
qs -c noctalia-shell ipc call plugin:asus-fan-control openPanel

# Presets
qs -c noctalia-shell ipc call plugin:asus-fan-control setSilent
qs -c noctalia-shell ipc call plugin:asus-fan-control setPerformance

# Get status (JSON)
qs -c noctalia-shell ipc call plugin:asus-fan-control getStatus
```

### Smart Daemon
```bash
# Configure
./smart_fan_daemon.sh config

# Run as systemd service
sudo systemctl enable --now smart-fan-daemon

# View logs
journalctl -u smart-fan-daemon -f
```

---

## ⌨️ Keyboard Shortcuts (Hyprland)

| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+F` | Open fan control GUI |
| `Ctrl+Alt+1` | Silent mode (30%) |
| `Ctrl+Alt+2` | Quiet mode (50%) |
| `Ctrl+Alt+3` | Performance mode (80%) |
| `Ctrl+Alt+0` | Auto mode (BIOS) |
| `Ctrl+Alt+T` | Temperature monitoring |

---

## 🖥️ Interfaces Comparison

| Feature | Noctalia Plugin | Zsh Plugin | Rofi GUI | CLI Script |
|---------|----------------|------------|----------|------------|
| Bar Widget | ✅ | ❌ | ❌ | ❌ |
| Control Panel | ✅ | ❌ | ✅ | ❌ |
| Terminal Commands | Via IPC | ✅ Native | ❌ | ✅ |
| Resource Usage | Medium | Minimal | Low | Minimal |
| Best For | GUI lovers | Terminal users | Quick access | Scripts |

---

## 🛠️ Hardware Requirements

- **Motherboard:** ASUS ROG STRIX B550-F (or compatible NCT6775/NCT6798 chip)
- **Kernel Module:** `nct6775`
- **Packages:** `lm_sensors`, `rofi` (for GUI)
- **Desktop:** Noctalia Shell (for plugin) or any WM/DE (for CLI/GUI)

---

## 📦 Installation Options

### One-Command Installers

| Installer | Installs | Best For |
|-----------|----------|----------|
| `./install_noctalia_plugin.sh` | Noctalia plugin + polkit | Noctalia Shell users |
| `./setup_zsh_plugin.sh` | Zsh plugin + sudoers | Terminal-focused users |
| `./install_complete_fanctrl.sh` | All scripts + keybinds + daemon | Full system setup |

### Manual Installation

See [INSTALL.md](INSTALL.md) for detailed manual installation steps.

---

## 📁 Project Structure

```
asus--fanctrl--desktop-/
├── Core Scripts
│   ├── fan_control.sh              # Main CLI tool
│   ├── fan_control_lib.sh          # Shared library
│   ├── rofi_fan_control.sh         # Rofi GUI
│   └── smart_fan_daemon.sh         # Temperature daemon
│
├── Noctalia Plugin
│   ├── noctalia-plugin/
│   │   ├── Main.qml               # Background logic
│   │   ├── BarWidget.qml          # Bar widget
│   │   ├── Panel.qml              # Control panel
│   │   ├── Settings.qml           # Settings UI
│   │   ├── asus-fanctrl-detect    # Hardware detection
│   │   └── 50-asus-fanctrl.rules  # Polkit rules
│   └── install_noctalia_plugin.sh
│
├── Zsh Plugin
│   ├── fan_control_zsh_plugin.zsh
│   ├── setup_zsh_plugin.sh
│   └── fanctrl_sudoers_zsh
│
├── Systemd Integration
│   ├── smart-fan-daemon.service
│   ├── fan_control_sudoers
│   └── install_systemd_service.sh
│
├── Installers
│   ├── install_complete_fanctrl.sh
│   ├── install_sudoers.sh
│   ├── install_fixes.sh
│   └── install.sh
│
└── Documentation
    ├── QUICK_START.md
    ├── INSTALL.md
    ├── INTEGRATION_OPTIONS.md
    ├── FAN_CONTROL_GUIDE.md
    ├── SYSTEMD_SERVICE.md
    ├── NOCTALIA_PLUGIN_README.md
    └── ZSH_PLUGIN_README.md
```

---

## 🔧 Troubleshooting

### Hardware Not Detected
```bash
# Load kernel module
sudo modprobe nct6775

# Check detection
ls /sys/class/hwmon/hwmon*/name | xargs cat

# Run detection helper
asus-fanctrl-detect status
```

### Permission Denied
```bash
# For Noctalia plugin: restart polkit
sudo systemctl restart polkit

# For CLI: verify sudoers
sudo visudo -c -f /etc/sudoers.d/fanctrl
```

### Plugin Not Loading (Noctalia)
```bash
# Reload shell
qs -c noctalia-shell reload

# Check logs
journalctl --user -u noctalia-shell -f
```

### Verify Installation
```bash
./scripts/verify_fanctrl.sh
```

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [QUICK_START.md](QUICK_START.md) | Quick installation and usage |
| [INSTALL.md](INSTALL.md) | Detailed installation guide |
| [INTEGRATION_OPTIONS.md](INTEGRATION_OPTIONS.md) | Plugin comparison and selection |
| [FAN_CONTROL_GUIDE.md](FAN_CONTROL_GUIDE.md) | Hardware setup and usage guide |
| [SYSTEMD_SERVICE.md](SYSTEMD_SERVICE.md) | Daemon and systemd setup |
| [NOCTALIA_PLUGIN_README.md](NOCTALIA_PLUGIN_README.md) | Noctalia plugin documentation |
| [ZSH_PLUGIN_README.md](ZSH_PLUGIN_README.md) | Zsh plugin documentation |

---

## 🔒 Security

- **Polkit rules** (Noctalia) - Passwordless control via `asus-fanctrl-detect`
- **Sudoers configuration** (CLI) - Restricted to PWM sysfs files only
- **Systemd hardening** - `ProtectSystem`, `NoNewPrivileges`, resource limits
- **Minimal scope** - Only PWM control commands, no broader system access

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test on your hardware
4. Submit a pull request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## ⚠️ Disclaimer

This software controls hardware fans. Use at your own risk. Monitor system temperatures to ensure adequate cooling. The authors are not responsible for hardware damage.

---

## 🙏 Acknowledgments

- NCT6775 kernel module developers
- Noctalia Shell team for the plugin system
- Rofi project for the excellent menu system
- ASUS for hardware documentation

---

**Made with ❤️ for ASUS ROG STRIX B550-F users**
