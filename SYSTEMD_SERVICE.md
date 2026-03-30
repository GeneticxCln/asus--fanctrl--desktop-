# Systemd Service Integration

> Automatic temperature-based fan control via systemd

---

## Overview

The Smart Fan Control Daemon provides:

- **🌡️ Temperature-based control** - Automatic fan speed adjustment
- **🔒 Secure execution** - Restricted service permissions
- **📝 Journal logging** - Integrated system logging
- **🔄 Auto-restart** - Recovery on failure
- **🛑 Clean shutdown** - Returns fans to auto mode

---

## Quick Setup

### One-Command Install

```bash
# Run installer
./install_systemd_service.sh

# Enable and start service
sudo systemctl enable --now smart-fan-daemon

# Check status
sudo systemctl status smart-fan-daemon
```

---

## Installation

### Method 1: Automated Installer

```bash
./install_systemd_service.sh
```

The installer will:
1. ✅ Install sudoers rule for passwordless fan control
2. ✅ Install systemd service file
3. ✅ Test the installation

---

### Method 2: Manual Installation

#### Step 1: Install Sudoers Rule

```bash
# Copy sudoers file
sudo cp fan_control_sudoers /etc/sudoers.d/90-fan-control
sudo chmod 440 /etc/sudoers.d/90-fan-control
```

#### Step 2: Install Service File

```bash
# Copy service file
sudo cp smart-fan-daemon.service /etc/systemd/system/

# Update ExecStart path (edit with your actual path)
sudo nano /etc/systemd/system/smart-fan-daemon.service

# Reload systemd
sudo systemctl daemon-reload
```

#### Step 3: Configure Daemon

```bash
# Interactive configuration
./smart_fan_daemon.sh config

# Test configuration
./smart_fan_daemon.sh test
```

---

## Service Management

### Start/Stop/Restart

```bash
# Start the service
sudo systemctl start smart-fan-daemon

# Stop the service
sudo systemctl stop smart-fan-daemon

# Restart the service
sudo systemctl restart smart-fan-daemon

# Reload configuration
sudo systemctl reload smart-fan-daemon
```

### Enable/Disable Auto-Start

```bash
# Enable auto-start on boot
sudo systemctl enable smart-fan-daemon

# Disable auto-start
sudo systemctl disable smart-fan-daemon

# Check if enabled
systemctl is-enabled smart-fan-daemon
```

### Check Status

```bash
# Basic status
sudo systemctl status smart-fan-daemon

# Detailed status
systemctl show smart-fan-daemon

# Check if running
systemctl is-active smart-fan-daemon
```

---

## Configuration

### Interactive Configuration

```bash
./smart_fan_daemon.sh config
```

**Configuration prompts:**

```
=== Fan Control Configuration ===

Enter PWM channel [1]: 1
Minimum temperature (°C) [30]: 30
Maximum temperature (°C) [70]: 70
Minimum fan speed (%) [20]: 20
Maximum fan speed (%) [100]: 100
Update interval (seconds) [5]: 5

Configuration summary:
  PWM Channel: 1
  Temperature: 30°C - 70°C
  Fan Speed: 20% - 100%
  Interval: 5s

Save configuration? [Y/n]: Y
```

### Configuration File

Configuration is saved to `~/.config/fanctrl.conf`:

```ini
# Fan Control Configuration
pwm_channel=1
temp_min=30
temp_max=70
fan_min=20
fan_max=100
update_interval=5
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `pwm_channel` | 1 | PWM channel to control (1-6) |
| `temp_min` | 30 | Temperature at minimum fan speed |
| `temp_max` | 70 | Temperature at maximum fan speed |
| `fan_min` | 20 | Minimum fan speed percentage |
| `fan_max` | 100 | Maximum fan speed percentage |
| `update_interval` | 5 | Update interval in seconds |

---

## Temperature Curve

The daemon uses linear interpolation between temperature points:

| Temperature | Fan Speed |
|-------------|-----------|
| ≤ temp_min | fan_min |
| temp_min → temp_max | Linear interpolation |
| ≥ temp_max | fan_max |

### Example Curve (Default Settings)

```
Temp (°C)  | Fan Speed (%)
-----------|---------------
    25     |     20%
    30     |     20%  ← temp_min
    40     |     40%
    50     |     60%
    60     |     80%
    70     |    100%  ← temp_max
    80     |    100%
```

### Custom Curve Examples

#### Silent Curve (Quiet Operation)
```ini
temp_min=30
temp_max=60
fan_min=15
fan_max=60
```

#### Performance Curve (Aggressive Cooling)
```ini
temp_min=40
temp_max=70
fan_min=40
fan_max=100
```

#### Balanced Curve (Recommended)
```ini
temp_min=35
temp_max=65
fan_min=25
fan_max=80
```

---

## Logging

### View Logs

```bash
# Recent logs
journalctl -u smart-fan-daemon -n 50

# Follow logs in real-time
journalctl -u smart-fan-daemon -f

# Logs from specific time
journalctl -u smart-fan-daemon --since "1 hour ago"

# Logs with priority filter
journalctl -u smart-fan-daemon -p info
```

### Log Output Example

```
Mar 30 10:00:00 hostname systemd[1]: Started Smart Fan Control Daemon.
Mar 30 10:00:01 hostname smart-fan-daemon[1234]: Starting smart fan control daemon...
Mar 30 10:00:01 hostname smart-fan-daemon[1234]: PWM Channel: 1
Mar 30 10:00:01 hostname smart-fan-daemon[1234]: Temperature range: 30°C - 70°C
Mar 30 10:00:01 hostname smart-fan-daemon[1234]: Fan speed range: 20% - 100%
Mar 30 10:00:05 hostname smart-fan-daemon[1234]: CPU: 45°C, Fan Speed: 40%
Mar 30 10:00:10 hostname smart-fan-daemon[1234]: CPU: 48°C, Fan Speed: 45%
```

---

## Security Features

### Service Hardening

The service includes several security restrictions:

```ini
# Filesystem protection
ProtectSystem=strict
ReadWritePaths=/sys/class/hwmon/hwmon2
ProtectHome=read-only
PrivateTmp=yes

# Process restrictions
NoNewPrivileges=yes
RestrictSUIDSGID=yes
MemoryDenyWriteExecute=yes
SystemCallFilter=@system-service

# Resource limits
MemoryMax=64M
CPUQuota=10%
```

### Sudoers Rule

The sudoers configuration allows specific PWM control:

```
# Allow writing to PWM enable files
%sudo ALL=(root) NOPASSWD: /usr/bin/tee /sys/class/hwmon/hwmon*/pwm*_enable

# Allow writing to PWM control files
%sudo ALL=(root) NOPASSWD: /usr/bin/tee /sys/class/hwmon/hwmon*/pwm[1-6]
```

**Security scope:**
- Only `tee` command to PWM files
- Restricted to hwmon paths
- Only PWM channels 1-6
- Users in `sudo` group only

---

## Troubleshooting

### Service Won't Start

```bash
# Check status
sudo systemctl status smart-fan-daemon

# Check detailed error
journalctl -u smart-fan-daemon --no-pager -n 50

# Test script manually
./smart_fan_daemon.sh test
```

**Common issues:**

1. **PWM files not found** - Check hwmon path
2. **Permission denied** - Verify sudoers rule
3. **Script not found** - Check ExecStart path

---

### Permission Denied

```bash
# Verify sudoers rule
sudo visudo -c -f /etc/sudoers.d/90-fan-control

# Test PWM access
echo 1 | sudo tee /sys/class/hwmon/hwmon5/pwm1_enable

# Reinstall sudoers
sudo cp fan_control_sudoers /etc/sudoers.d/90-fan-control
sudo chmod 440 /etc/sudoers.d/90-fan-control
```

---

### Auto-Detection Failed

If hwmon auto-detection fails:

```bash
# Find correct hwmon path
find /sys/class/hwmon/ -name "hwmon*" -exec sh -c '
    if [ -f "$1/name" ]; then
        echo "$1: $(cat $1/name)"
    fi
' _ {} \;

# Look for nct6798 entry
```

Update the service file with the correct path if needed.

---

### Fan Not Responding

```bash
# Check if PWM files exist
ls -la /sys/class/hwmon/hwmon*/pwm*

# Test manual control
./fan_control.sh set 1 50

# Verify configuration
./smart_fan_daemon.sh test

# Check daemon logs
journalctl -u smart-fan-daemon -f
```

---

### High CPU Usage

If the daemon uses too much CPU:

```bash
# Increase update interval
./smart_fan_daemon.sh config
# Set update_interval to 10 or higher

# Or edit config directly
nano ~/.config/fanctrl.conf
# update_interval=10
```

---

## Integration with GUI

The systemd service runs independently of GUI tools:

### Using GUI While Service Runs

```bash
# Service continues automatic control
# GUI can override temporarily

# Open GUI
./rofi_fan_control.sh

# Set manual speed (overrides daemon)
./fan_control.sh set 1 60

# Return to daemon control
./fan_control.sh auto 1
```

### Temporarily Override Service

```bash
# Stop service for manual control
sudo systemctl stop smart-fan-daemon

# Use GUI or manual commands
./rofi_fan_control.sh

# Restart service when done
sudo systemctl start smart-fan-daemon
```

---

## Advanced Configuration

### Multiple Fan Profiles

Create configuration files for different profiles:

```bash
# Silent profile
cat > ~/.config/fanctrl-silent.conf << EOF
pwm_channel=1
temp_min=30
temp_max=50
fan_min=15
fan_max=50
update_interval=10
EOF

# Performance profile
cat > ~/.config/fanctrl-performance.conf << EOF
pwm_channel=1
temp_min=40
temp_max=70
fan_min=40
fan_max=100
update_interval=3
EOF
```

Switch profiles:

```bash
# Stop service
sudo systemctl stop smart-fan-daemon

# Copy profile
cp ~/.config/fanctrl-silent.conf ~/.config/fanctrl.conf

# Restart service
sudo systemctl start smart-fan-daemon
```

### Custom PWM Channels

Control multiple fans by modifying the daemon script:

```bash
# Edit smart_fan_daemon.sh
# Add additional PWM channels in set_fan_speed function

set_fan_speed 1 $target_speed  # CPU fan
set_fan_speed 3 $target_speed  # Chassis fan 1
set_fan_speed 6 $target_speed  # Chassis fan 2
```

---

## Uninstallation

```bash
# Stop and disable service
sudo systemctl stop smart-fan-daemon
sudo systemctl disable smart-fan-daemon

# Remove service file
sudo rm /etc/systemd/system/smart-fan-daemon.service
sudo systemctl daemon-reload

# Remove sudoers rule
sudo rm /etc/sudoers.d/90-fan-control

# Remove configuration
rm ~/.config/fanctrl.conf

# Return fans to automatic control
./smart_fan_daemon.sh stop
```

---

## Service File Reference

```ini
[Unit]
Description=Smart Fan Control Daemon for ASUS ROG STRIX B550-F
After=multi-user.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/smart_fan_daemon.sh run
ExecStop=/usr/local/bin/smart_fan_daemon.sh stop
Restart=on-failure
RestartSec=30
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=read-only
PrivateDevices=no
ProtectKernelTunables=no
ProtectKernelModules=no
ProtectControlGroups=yes
RestrictSUIDSGID=yes
RemoveIPC=yes
RestrictNamespaces=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
RestrictRealtime=yes

[Install]
WantedBy=multi-user.target
```

---

## Commands Reference

| Command | Description |
|---------|-------------|
| `sudo systemctl start smart-fan-daemon` | Start the service |
| `sudo systemctl stop smart-fan-daemon` | Stop the service |
| `sudo systemctl restart smart-fan-daemon` | Restart the service |
| `sudo systemctl enable smart-fan-daemon` | Enable auto-start |
| `sudo systemctl disable smart-fan-daemon` | Disable auto-start |
| `sudo systemctl status smart-fan-daemon` | Check service status |
| `journalctl -u smart-fan-daemon -f` | View logs |
| `./smart_fan_daemon.sh config` | Configure daemon |
| `./smart_fan_daemon.sh test` | Test configuration |
| `./smart_fan_daemon.sh run` | Run manually |
| `./smart_fan_daemon.sh stop` | Stop and restore auto |

---

## Next Steps

- **[FAN_CONTROL_GUIDE.md](FAN_CONTROL_GUIDE.md)** - Usage guide
- **[QUICK_START.md](QUICK_START.md)** - Quick commands reference
- **[INSTALL.md](INSTALL.md)** - Installation guide

---

**Enjoy automatic temperature-based fan control! 🌡️💨**
