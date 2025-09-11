# Systemd Service Integration

This document covers the systemd service integration for the Smart Fan Control Daemon.

## Overview

The systemd service provides:
- Automatic fan control based on CPU temperature
- Secure service execution with restricted permissions
- Proper logging to systemd journal
- Automatic restart on failure
- Clean shutdown with fan restoration to auto mode

## Installation

### Automatic Installation

Run the installation script to set up both the systemd service and sudoers rule:

```bash
./install_systemd_service.sh
```

This will:
- Install a sudoers rule for passwordless fan control
- Install the systemd service file
- Test the installation

### Manual Installation

If you prefer manual installation:

1. **Install sudoers rule:**
   ```bash
   sudo cp fan_control_sudoers /etc/sudoers.d/90-fan-control
   sudo chmod 440 /etc/sudoers.d/90-fan-control
   ```

2. **Install systemd service:**
   ```bash
   sudo cp smart-fan-daemon.service /etc/systemd/system/
   sudo systemctl daemon-reload
   ```

## Service Management

### Start/Stop Service
```bash
# Start the service
sudo systemctl start smart-fan-daemon

# Stop the service
sudo systemctl stop smart-fan-daemon

# Check status
sudo systemctl status smart-fan-daemon
```

### Auto-start on Boot
```bash
# Enable auto-start
sudo systemctl enable smart-fan-daemon

# Disable auto-start
sudo systemctl disable smart-fan-daemon
```

### View Logs
```bash
# View recent logs
journalctl -u smart-fan-daemon

# Follow logs in real-time
journalctl -u smart-fan-daemon -f

# View logs from specific time
journalctl -u smart-fan-daemon --since "1 hour ago"
```

## Configuration

The service uses the same configuration file as the interactive daemon:
- **Location:** `~/.fan_control_config`
- **Configure:** Run `./smart_fan_daemon.sh config` to set up temperature ranges and fan curves

### Default Configuration
- PWM Channel: 1 (CPU fan)
- Temperature Range: 30°C - 70°C
- Fan Speed Range: 20% - 100%
- Update Interval: 5 seconds

## Security Features

The systemd service includes several security hardening features:

### Filesystem Protection
- `ProtectSystem=strict` - Read-only filesystem except for allowed paths
- `ReadWritePaths=/sys/class/hwmon/hwmon2` - Only hwmon directory is writable
- `ProtectHome=read-only` - Home directories are read-only
- `PrivateTmp=yes` - Private /tmp directory

### Process Restrictions
- `NoNewPrivileges=yes` - Cannot gain new privileges
- `RestrictSUIDSGID=yes` - Cannot use SUID/SGID binaries
- `MemoryDenyWriteExecute=yes` - Cannot create executable memory
- `SystemCallFilter=@system-service` - Restricted system calls

### Resource Limits
- `MemoryMax=64M` - Maximum 64MB RAM usage
- `CPUQuota=10%` - Maximum 10% CPU usage

## Sudoers Rule

The sudoers rule allows passwordless access to specific fan control files:

```
# Allow writing to PWM enable files (to switch between manual/auto modes)
%sudo ALL=(root) NOPASSWD: /usr/bin/tee /sys/class/hwmon/hwmon*/pwm*_enable
%sudo ALL=(root) NOPASSWD: /bin/tee /sys/class/hwmon/hwmon*/pwm*_enable

# Allow writing to PWM control files (to set fan speeds)
%sudo ALL=(root) NOPASSWD: /usr/bin/tee /sys/class/hwmon/hwmon*/pwm[1-6]
%sudo ALL=(root) NOPASSWD: /bin/tee /sys/class/hwmon/hwmon*/pwm[1-6]
```

This rule:
- Only allows `tee` commands to specific PWM files
- Uses wildcards for hwmon path flexibility
- Restricts PWM channels to 1-6
- Applies to users in the `sudo` group

## Troubleshooting

### Service Won't Start
```bash
# Check service status
sudo systemctl status smart-fan-daemon

# Check detailed logs
journalctl -u smart-fan-daemon --no-pager
```

Common issues:
- **PWM files not found:** Check if hwmon path has changed
- **Permission denied:** Verify sudoers rule is installed correctly
- **Script not found:** Ensure the ExecStart path in service file is correct

### Auto-detection Failed
If hwmon auto-detection fails, the service will fall back to `/sys/class/hwmon/hwmon2`. You can check the correct path:

```bash
find /sys/class/hwmon/ -name "hwmon*" -exec sh -c 'if [ -f "$1/name" ]; then echo "$1: $(cat "$1/name")"; fi' _ {} \;
```

Look for the `nct6798` entry and update the service file if needed.

### Fan Not Responding
1. Check if PWM files exist:
   ```bash
   ls -la /sys/class/hwmon/hwmon*/pwm*
   ```

2. Test manual control:
   ```bash
   ./fan_control.sh set 1 50
   ```

3. Verify configuration:
   ```bash
   ./smart_fan_daemon.sh test
   ```

## Integration with GUI

The systemd service runs independently of the rofi GUI. You can:
- Use the GUI for manual control while service is running
- Stop the service to use GUI presets
- The service will detect if fans are already in manual mode

To temporarily override the service:
```bash
# Stop service
sudo systemctl stop smart-fan-daemon

# Use GUI or manual commands
./rofi_fan_control.sh

# Restart service when done
sudo systemctl start smart-fan-daemon
```

## Uninstallation

To remove the systemd service and sudoers rule:

```bash
# Stop and disable service
sudo systemctl stop smart-fan-daemon
sudo systemctl disable smart-fan-daemon

# Remove service file
sudo rm /etc/systemd/system/smart-fan-daemon.service
sudo systemctl daemon-reload

# Remove sudoers rule
sudo rm /etc/sudoers.d/90-fan-control

# Return fans to automatic control
./smart_fan_daemon.sh stop
```
