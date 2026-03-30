# 🚀 Quick Start - ASUS Fan Control

## Choose Your Integration

### 🎯 For Noctalia Shell (Recommended)
```bash
# Install the native Noctalia plugin
./install_noctalia_plugin.sh

# After installation:
# - Click the fan icon in your bar
# - Use the control panel
# - Configure in Settings
```

### 💻 For Terminal/CLI
```bash
# Install the zsh plugin
./setup_zsh_plugin.sh

# Then reload your shell
source ~/.zshrc

# Quick commands:
fcs          # Check status
fcsilent     # Silent mode (30%)
fcquiet      # Quiet mode (50%)
fcperf       # Performance (80%)
```

---

## ⚡ One-Command Installers

| Installer | What It Does |
|-----------|--------------|
| `./install_noctalia_plugin.sh` | Installs Noctalia Shell plugin with GUI |
| `./setup_zsh_plugin.sh` | Installs zsh plugin with CLI commands |
| `./install_complete_fanctrl.sh` | Original full system installer |

---

## 📋 Quick Commands Reference

### Noctalia Plugin (IPC Commands)
```bash
# Open panel
qs -c noctalia-shell ipc call plugin:asus-fan-control openPanel

# Presets
qs -c noctalia-shell ipc call plugin:asus-fan-control setSilent
qs -c noctalia-shell ipc call plugin:asus-fan-control setQuiet
qs -c noctalia-shell ipc call plugin:asus-fan-control setPerformance
qs -c noctalia-shell ipc call plugin:asus-fan-control setMax

# Get status (JSON)
qs -c noctalia-shell ipc call plugin:asus-fan-control getStatus
```

### Zsh Plugin (Aliases)
```bash
fcs          # Status display
fcsilent     # Silent (30%)
fcquiet      # Quiet (50%)
fcperf       # Performance (80%)
fcmax        # Max speed (100%)
fcauto       # Return to auto
fanctrl-gui  # Rofi GUI (if installed)
```

### Original Scripts
```bash
./fan_control.sh status              # Show status
./fan_control.sh set 1 60            # Set PWM1 to 60%
./fan_control.sh auto 1              # PWM1 to auto mode
./rofi_fan_control.sh                # Rofi GUI
./smart_fan_daemon.sh config         # Configure daemon
./smart_fan_daemon.sh run            # Run daemon
```

---

## 🎮 Example Keybinds

### Noctalia Shell Config
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

### Hyprland Config
```bash
# Using zsh plugin aliases
bind = CTRL ALT, F, exec, fanctrl-gui
bind = CTRL ALT, 1, exec, fanctrl-silent
bind = CTRL ALT, 2, exec, fanctrl-quiet
bind = CTRL ALT, 3, exec, fanctrl-performance

# Or using Noctalia IPC
bind = CTRL ALT, F, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control openPanel
bind = CTRL ALT, 1, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setSilent
bind = CTRL ALT, 2, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setQuiet
bind = CTRL ALT, 3, exec, qs -c noctalia-shell ipc call plugin:asus-fan-control setPerformance
```

---

## 🛠️ Troubleshooting Quick Fixes

### Hardware Not Detected
```bash
sudo modprobe nct6775
sudo sensors-detect
```

### Noctalia Plugin Not Showing
```bash
qs -c noctalia-shell reload
```

### Zsh Plugin Not Working
```bash
source ~/.zshrc
```

### Permission Denied
```bash
# For zsh plugin
sudo systemctl restart polkit

# Or reinstall
./setup_zsh_plugin.sh
```

---

## 📖 Full Documentation

| Document | What It Covers |
|----------|----------------|
| `NOCTALIA_PLUGIN_README.md` | Noctalia plugin full guide |
| `ZSH_PLUGIN_README.md` | Zsh plugin full guide |
| `INTEGRATION_OPTIONS.md` | Comparison of both options |
| `README.md` | Original project overview |
| `INSTALL.md` | Original installation guide |

---

## 🎯 Recommended Setup

**For most Noctalia users:**
```bash
# Install Noctalia plugin (primary)
./install_noctalia_plugin.sh

# Install zsh plugin (for CLI access)
./setup_zsh_plugin.sh

# Reload everything
source ~/.zshrc
qs -c noctalia-shell reload
```

This gives you:
- ✅ Bar widget with temperature
- ✅ Full GUI control panel
- ✅ CLI commands for terminal
- ✅ Keybind support via IPC
- ✅ Best of both worlds!

---

## ⚠️ Important Notes

1. **Requires ASUS motherboard** with NCT6775/NCT6798 chip
2. **Run installers as normal user** (not root)
3. **Reload shell/service** after installation
4. **Monitor temperatures** when testing new fan speeds

---

## 🆘 Need Help?

1. Check hardware detection: `sensors`
2. Verify plugin installed: `ls ~/.config/noctalia/plugins/`
3. Check logs: `journalctl --user -u noctalia-shell -n 50`
4. Read full docs: See documentation files above

---

**Good luck and stay cool! 🌡️💨**
