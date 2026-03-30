# ASUS Fan Control - Integration Options Summary

This repository now includes **two plugin integration options** for using the fan control system on Arch Linux with Noctalia Shell.

---

## 🎯 Option 1: Noctalia Shell Native Plugin (Recommended for Noctalia)

A **native Noctalia Shell plugin** with full GUI integration.

### Features
- ✅ Bar widget with temperature badge
- ✅ Full control panel with sliders
- ✅ Real-time monitoring
- ✅ Settings integration
- ✅ IPC commands for keybinds
- ✅ Beautiful QML interface

### Installation
```bash
./install_noctalia_plugin.sh
```

### Usage
- Click fan icon in bar widget
- Use control panel with sliders
- IPC commands for keybinds

### Best For
- Noctalia Shell users
- GUI-focused workflow
- Want seamless desktop integration

### Files
- `noctalia-plugin/` - Complete plugin source
- `install_noctalia_plugin.sh` - Installer
- `NOCTALIA_PLUGIN_README.md` - Documentation

---

## 💻 Option 2: Zsh Plugin (Shell Integration)

A **command-line plugin** for zsh shell integration.

### Features
- ✅ Terminal-based control
- ✅ Quick aliases (fcs, fcsilent, fcquiet, etc.)
- ✅ Status display with colors
- ✅ Optional GUI via rofi
- ✅ Lightweight

### Installation
```bash
./setup_zsh_plugin.sh
```

### Usage
```bash
fcs          # Status
fcsilent     # Silent mode
fcquiet      # Quiet mode
fcperf       # Performance
fanctrl-gui  # GUI (if rofi installed)
```

### Best For
- Terminal-focused workflow
- Minimal resource usage
- Quick command-line access
- Works with any WM/DE

### Files
- `fan_control_zsh_plugin.zsh` - Plugin source
- `setup_zsh_plugin.sh` - Installer
- `ZSH_PLUGIN_README.md` - Documentation

---

## 🔄 Can I Use Both?

**Yes!** They can coexist:
- Noctalia plugin provides GUI and bar widget
- Zsh plugin provides CLI access
- Both use the same hardware interface

Install both:
```bash
./install_noctalia_plugin.sh
./setup_zsh_plugin.sh
```

---

## 📊 Comparison

| Feature | Noctalia Plugin | Zsh Plugin |
|---------|----------------|------------|
| **Interface** | GUI (QML) | CLI (Terminal) |
| **Bar Widget** | ✅ Yes | ❌ No |
| **Control Panel** | ✅ Full GUI | ❌ No |
| **CLI Commands** | Via IPC | ✅ Native |
| **Aliases** | ❌ No | ✅ Yes |
| **Rofi GUI** | ❌ No | ✅ Optional |
| **Settings UI** | ✅ Integrated | ❌ Config file |
| **Resource Usage** | Medium | Minimal |
| **WM/DE Support** | Noctalia only | Any |

---

## 🚀 Quick Start

### For Noctalia Shell Users (Recommended)
```bash
# Install Noctalia plugin
./install_noctalia_plugin.sh

# Reload Noctalia
qs -c noctalia-shell reload

# Click the fan icon in your bar!
```

### For CLI-First Users
```bash
# Install zsh plugin
./setup_zsh_plugin.sh

# Reload shell
source ~/.zshrc

# Use commands
fcs          # Check status
fcquiet      # Set quiet mode
```

### For Power Users (Both)
```bash
# Install both
./install_noctalia_plugin.sh
./setup_zsh_plugin.sh

# Reload everything
source ~/.zshrc
qs -c noctalia-shell reload

# Use GUI via bar widget or CLI via aliases
```

---

## 🎮 Example Keybinds

### Noctalia Plugin (via IPC)
Add to Noctalia config:
```json
{
  "keybinds": {
    "Ctrl+Alt+F": "qs -c noctalia-shell ipc call plugin:asus-fan-control openPanel",
    "Ctrl+Alt+1": "qs -c noctalia-shell ipc call plugin:asus-fan-control setSilent",
    "Ctrl+Alt+2": "qs -c noctalia-shell ipc call plugin:asus-fan-control setQuiet",
    "Ctrl+Alt+3": "qs -c noctalia-shell ipc call plugin:asus-fan-control setPerformance"
  }
}
```

### Zsh Plugin (via Hyprland)
Add to Hyprland config:
```bash
bind = CTRL ALT, F, exec, ~/.config/noctalia/plugins/asus-fan-control/Panel.qml
bind = CTRL ALT, 1, exec, fanctrl-silent
bind = CTRL ALT, 2, exec, fanctrl-quiet
bind = CTRL ALT, 3, exec, fanctrl-performance
```

---

## 📁 Complete File Structure

```
asus--fanctrl--desktop-/
├── noctalia-plugin/              # Noctalia Shell plugin
│   ├── manifest.json
│   ├── Main.qml
│   ├── BarWidget.qml
│   ├── Panel.qml
│   ├── Settings.qml
│   └── 50-asus-fanctrl.rules
│
├── fan_control_zsh_plugin.zsh    # Zsh plugin
├── setup_zsh_plugin.sh           # Zsh installer
├── install_noctalia_plugin.sh    # Noctalia installer
│
├── fan_control.sh                # Original CLI tool
├── rofi_fan_control.sh           # Original Rofi GUI
├── smart_fan_daemon.sh           # Temperature daemon
│
└── Documentation/
    ├── NOCTALIA_PLUGIN_README.md
    ├── ZSH_PLUGIN_README.md
    └── INTEGRATION_OPTIONS.md    # This file
```

---

## 🛠️ Hardware Requirements

Both options require:
- **ASUS ROG STRIX B550-F** or compatible motherboard
- **NCT6775/NCT6798** Super I/O chip
- **nct6775** kernel module loaded
- **lm_sensors** package installed

---

## 🔒 Security

Both use secure privilege escalation:
- **Noctalia Plugin**: polkit rules
- **Zsh Plugin**: sudoers configuration

Both restrict access to PWM control commands only.

---

## 📞 Troubleshooting

### Noctalia Plugin Issues
1. Check plugin directory: `~/.config/noctalia/plugins/asus-fan-control/`
2. Reload shell: `qs -c noctalia-shell reload`
3. Check logs: `journalctl --user -u noctalia-shell`

### Zsh Plugin Issues
1. Check plugin sourced: `grep fan_control ~/.zshrc`
2. Reload shell: `source ~/.zshrc`
3. Test command: `fanctrl-help`

### Hardware Detection (Both)
```bash
# Load module
sudo modprobe nct6775

# Check detection
ls /sys/class/hwmon/hwmon*/name | xargs cat

# Run sensors-detect
sudo sensors-detect
```

---

## ✅ Recommendation

**Use Noctalia Plugin if:**
- You use Noctalia Shell
- You prefer GUI interfaces
- You want bar widget integration
- You want seamless desktop experience

**Use Zsh Plugin if:**
- You live in the terminal
- You want minimal resource usage
- You use multiple WMs/DEs
- You prefer keyboard-driven workflow

**Use Both if:**
- You want the best of both worlds
- GUI at home, CLI over SSH
- No conflicts between them

---

## 🎉 Enjoy Your Fan Control System!

Both integration options provide full control over your ASUS motherboard fans. Choose the one that fits your workflow, or use both for maximum flexibility!
