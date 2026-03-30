# Integration Options Comparison

> Choose the right fan control integration for your workflow

---

## Overview

This project offers **four integration options**, each designed for different use cases:

| Option | Interface | Best For |
|--------|-----------|----------|
| **Noctalia Plugin** | Native GUI | Noctalia Shell users |
| **Zsh Plugin** | CLI aliases | Terminal-focused users |
| **Rofi GUI** | Simple menu | Quick access, any DE |
| **CLI Scripts** | Command-line | Scripts, automation |

---

## Detailed Comparison

### 🎯 Noctalia Shell Plugin

**What it is:** Native Noctalia Shell plugin with QML-based GUI

**Components:**
- Bar widget with temperature badge
- Full control panel with sliders
- Settings panel
- IPC commands for keybinds

**Installation:**
```bash
./install_noctalia_plugin.sh
qs -c noctalia-shell reload
```

**Features:**
| Feature | Available |
|---------|-----------|
| Bar widget | ✅ |
| Control panel | ✅ |
| Temperature badge | ✅ |
| Fan RPM display | ✅ |
| Slider controls | ✅ |
| Quick presets | ✅ |
| Settings UI | ✅ |
| IPC commands | ✅ |
| Real-time updates | ✅ |

**Resource Usage:**
- Memory: ~50-100 MB
- CPU: Minimal (updates every 2 seconds)

**Best for:**
- Noctalia Shell users
- Desktop integration
- Visual feedback
- Click-to-control workflow

**Limitations:**
- Requires Noctalia Shell
- Higher resource usage than CLI

---

### 💻 Zsh Plugin

**What it is:** Shell integration with convenient aliases

**Components:**
- `fan_control_zsh_plugin.zsh` - Main plugin file
- `fanctrl_sudoers_zsh` - Sudoers configuration
- `setup_zsh_plugin.sh` - Installer

**Installation:**
```bash
./setup_zsh_plugin.sh
source ~/.zshrc
```

**Commands:**
| Command | Alias | Description |
|---------|-------|-------------|
| `fanctrl-status` | `fcs` | Show status |
| `fanctrl-silent` | `fcsilent` | 30% speed |
| `fanctrl-quiet` | `fcquiet` | 50% speed |
| `fanctrl-performance` | `fcperf` | 80% speed |
| `fanctrl-max` | `fcmax` | 100% speed |
| `fanctrl-auto` | `fcauto` | Auto mode |
| `fanctrl-set` | - | Manual control |
| `fanctrl-gui` | - | Launch Rofi |

**Features:**
| Feature | Available |
|---------|-----------|
| CLI aliases | ✅ |
| Status display | ✅ |
| Quick presets | ✅ |
| Manual control | ✅ |
| GUI access | ✅ (via rofi) |
| Hardware detection | ✅ |
| Auto module loading | ✅ |

**Resource Usage:**
- Memory: < 1 MB
- CPU: Only when commands run

**Best for:**
- Terminal-focused workflow
- Minimal resource usage
- Any desktop environment
- SSH/remote access

**Limitations:**
- No native GUI
- Requires zsh shell

---

### 🖥️ Rofi GUI

**What it is:** Simple menu-based GUI interface

**Components:**
- `rofi_fan_control.sh` - Main GUI script

**Installation:**
```bash
# Part of complete install
./install_complete_fanctrl.sh

# Or run directly
./rofi_fan_control.sh
```

**Features:**
| Feature | Available |
|---------|-----------|
| Main menu | ✅ |
| Temperature display | ✅ |
| Fan RPM display | ✅ |
| Quick presets | ✅ |
| Manual PWM control | ✅ |
| Monitoring view | ✅ |
| Daemon management | ✅ |

**Resource Usage:**
- Memory: ~20-30 MB (when open)
- CPU: Only when open

**Best for:**
- Quick access
- Any X11/Wayland environment
- Users who prefer menus
- Lightweight GUI option

**Limitations:**
- Requires rofi
- No bar widget
- No persistent display

---

### ⚙️ CLI Scripts

**What it is:** Core bash scripts for fan control

**Components:**
- `fan_control.sh` - Main control script
- `fan_control_lib.sh` - Shared library
- `smart_fan_daemon.sh` - Temperature daemon

**Installation:**
```bash
# Manual or via complete install
./install_complete_fanctrl.sh
```

**Commands:**
```bash
./fan_control.sh status           # Show status
./fan_control.sh set 1 60         # Set PWM1 to 60%
./fan_control.sh auto 1           # PWM1 to auto
./fan_control.sh manual 1         # PWM1 to manual

./smart_fan_daemon.sh config      # Configure daemon
./smart_fan_daemon.sh run         # Run daemon
./smart_fan_daemon.sh test        # Test config
```

**Features:**
| Feature | Available |
|---------|-----------|
| Status display | ✅ |
| Manual control | ✅ |
| Auto mode | ✅ |
| Temperature daemon | ✅ |
| Hardware detection | ✅ |
| Scriptable | ✅ |

**Resource Usage:**
- Memory: < 1 MB
- CPU: Only when running

**Best for:**
- Automation scripts
- System integration
- Minimal setups
- Daemon operation

**Limitations:**
- No GUI
- Manual configuration

---

## Feature Matrix

| Feature | Noctalia | Zsh | Rofi | CLI |
|---------|----------|-----|------|-----|
| **Interface Type** | Native GUI | CLI | Menu GUI | CLI |
| **Bar Widget** | ✅ | ❌ | ❌ | ❌ |
| **Control Panel** | ✅ | ❌ | ✅ | ❌ |
| **CLI Commands** | Via IPC | ✅ Native | ❌ | ✅ |
| **Quick Presets** | ✅ | ✅ | ✅ | ✅ |
| **Real-time Monitoring** | ✅ | Manual | ✅ | Manual |
| **Temperature Badge** | ✅ | ❌ | ❌ | ❌ |
| **Slider Control** | ✅ | ❌ | ❌ | ❌ |
| **Daemon Support** | ❌ | ❌ | ✅ | ✅ |
| **Scriptable** | Via IPC | ✅ | Limited | ✅ |
| **Desktop Integration** | ✅ | ❌ | ✅ | ❌ |
| **Resource Usage** | Medium | Minimal | Low | Minimal |
| **Requires** | Noctalia | zsh | rofi | bash |

---

## Can I Use Multiple Options?

**Yes!** They can coexist without conflicts:

### Recommended Combinations

#### Noctalia User + CLI Access
```bash
# Install Noctalia plugin (primary GUI)
./install_noctalia_plugin.sh

# Install zsh plugin (CLI access)
./setup_zsh_plugin.sh

# Result: Bar widget + terminal commands
```

#### Minimal Setup + GUI Option
```bash
# Install complete system (scripts + rofi)
./install_complete_fanctrl.sh

# Result: CLI scripts + rofi GUI + daemon
```

#### Full Setup (Everything)
```bash
# Install Noctalia plugin
./install_noctalia_plugin.sh

# Install zsh plugin
./setup_zsh_plugin.sh

# Install systemd daemon
./install_systemd_service.sh

# Result: All features available
```

---

## Decision Guide

### Choose Noctalia Plugin if:
- ✅ You use Noctalia Shell
- ✅ You want desktop integration
- ✅ You prefer visual interfaces
- ✅ You want a bar widget
- ✅ You like click-to-control

### Choose Zsh Plugin if:
- ✅ You live in the terminal
- ✅ You want minimal resources
- ✅ You use multiple WMs/DEs
- ✅ You prefer keyboard-driven workflow
- ✅ You want quick aliases

### Choose Rofi GUI if:
- ✅ You want simple GUI
- ✅ You don't use Noctalia
- ✅ You prefer menu navigation
- ✅ You want lightweight interface
- ✅ You use any X11/Wayland DE

### Choose CLI Scripts if:
- ✅ You want automation
- ✅ You're building custom integration
- ✅ You want minimal dependencies
- ✅ You prefer scripting
- ✅ You want daemon support

---

## Example Setups

### Setup 1: Noctalia Power User
```bash
# Primary: Noctalia plugin
./install_noctalia_plugin.sh

# Secondary: Zsh plugin for CLI
./setup_zsh_plugin.sh

# Keybinds via IPC in Noctalia config
{
  "keybinds": {
    "Ctrl+Alt+F": "qs -c noctalia-shell ipc call plugin:asus-fan-control openPanel",
    "Ctrl+Alt+1": "qs -c noctalia-shell ipc call plugin:asus-fan-control setSilent"
  }
}
```

### Setup 2: Minimalist Terminal User
```bash
# Just zsh plugin
./setup_zsh_plugin.sh

# Keybinds in Hyprland config
bind = CTRL ALT, 1, exec, fanctrl-silent
bind = CTRL ALT, 2, exec, fanctrl-quiet
bind = CTRL ALT, 3, exec, fanctrl-performance
```

### Setup 3: Complete System
```bash
# Everything
./install_complete_fanctrl.sh
./install_noctalia_plugin.sh
./install_systemd_service.sh

# Enable daemon
sudo systemctl enable --now smart-fan-daemon
```

---

## Installation Time Comparison

| Option | Install Time | Configuration |
|--------|--------------|---------------|
| Noctalia Plugin | ~1 minute | Automatic |
| Zsh Plugin | ~1 minute | Automatic |
| Rofi GUI | Included in complete | Automatic |
| CLI Scripts | Included in complete | Manual |
| Complete System | ~3 minutes | Automatic |

---

## Security Comparison

| Option | Privilege Method | Scope |
|--------|------------------|-------|
| Noctalia Plugin | Polkit rules | `asus-fanctrl-detect` |
| Zsh Plugin | Sudoers | PWM sysfs files |
| Rofi GUI | Sudoers (via scripts) | PWM sysfs files |
| CLI Scripts | Sudoers | PWM sysfs files |
| Systemd Service | Root service | PWM sysfs files |

All options use minimal privilege escalation restricted to PWM control only.

---

## Troubleshooting by Option

### Noctalia Plugin Issues
```bash
# Reload plugin
qs -c noctalia-shell reload

# Check logs
journalctl --user -u noctalia-shell -f

# Verify installation
ls ~/.config/noctalia/plugins/asus-fan-control/
```

### Zsh Plugin Issues
```bash
# Check if sourced
grep fan_control ~/.zshrc

# Reload shell
source ~/.zshrc

# Test command
fanctrl-help
```

### Rofi GUI Issues
```bash
# Test rofi
rofi -e "test"

# Run script directly
./rofi_fan_control.sh
```

### CLI Script Issues
```bash
# Verify hardware
asus-fanctrl-detect status

# Test script
./fan_control.sh status

# Check permissions
./scripts/verify_fanctrl.sh
```

---

## Summary

| Use Case | Recommended Option |
|----------|-------------------|
| **Noctalia Shell user** | Noctalia Plugin (+ optional zsh) |
| **Terminal-focused** | Zsh Plugin |
| **Simple GUI** | Rofi GUI |
| **Automation/Scripts** | CLI Scripts |
| **Everything** | All of the above |

---

**Ready to install?** See [INSTALL.md](INSTALL.md) for detailed installation instructions.

**Need quick commands?** See [QUICK_START.md](QUICK_START.md) for usage reference.
