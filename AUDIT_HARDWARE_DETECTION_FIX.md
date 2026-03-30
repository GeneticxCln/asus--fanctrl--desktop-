# ASUS Fan Control Plugin - Hardware Detection Audit & Fixes

## Executive Summary

**Issue:** The Noctalia Shell plugin was reporting "no hardware" even when NCT6775/NCT6798 hardware was present.

**Root Cause:** The hardware detection ran synchronously during QML component initialization, before the kernel module was fully loaded and hardware was ready.

**Solution Implemented:** Deferred hardware detection with retry logic, module loading capability, and improved error messaging.

---

## Problem Analysis

### Original Issue

The original `Main.qml` used a QML property initializer for hardware detection:

```qml
property string pwmBasePath: {
  for (let i = 0; i < 15; i++) {
    const path = "/sys/class/hwmon/hwmon" + i;
    const name = Process.string(["cat", nameFile]).trim();
    if (name.includes("nct6798") || name.includes("nct6775")) {
      return path;
    }
  }
  return "";
}
```

**Problems:**
1. **Timing Issue**: Ran during component initialization before hardware ready
2. **No Retry**: Failed once = failed forever
3. **No Module Loading**: Couldn't load `nct6775` module if not loaded
4. **Silent Failures**: `catch (e) {}` swallowed all errors
5. **No User Feedback**: Users saw "Hardware not detected" with no recourse

### System Verification

Your system **DOES** have compatible hardware:

```
✅ hwmon5: nct6798
✅ Module: nct6775 loaded
✅ Sensors: Working correctly
✅ PWM Channels: 6 available
✅ Fan RPMs: 2 active (Fan3, Fan6)
```

---

## Fixes Implemented

### 1. Main.qml - Deferred Detection with Retry Logic

**Changes:**
- Changed from property initializer to deferred detection
- Added 5 retry attempts with 1-second delays
- Added module loading via pkexec
- Added detection status tracking
- Exposed IPC functions for manual retry/module load

**New Properties:**
```qml
property int detectionAttempts: 0
property int maxDetectionAttempts: 5
property bool detectionInProgress: false
property string detectionStatus: "Initializing..."
```

**New Functions:**
- `loadNct6775Module()` - Load kernel module via pkexec
- `retryDetection()` - Manual retry button
- `onHardwareDetected()` - Callback on success

### 2. Panel.qml - Improved Error UI

**Changes:**
- Added detection status display box
- Added "Retry" and "Load Module" buttons
- Shows detailed status messages
- Dynamic footer text based on detection state
- Shows "(Connected)" when hardware is found

**New UI Elements:**
- Red warning box when hardware not detected
- Interactive buttons for user action
- Real-time status updates
- Helpful tips for users

### 3. asus-fanctrl-detect - New Helper Script

**Location:** `/noctalia-plugin/asus-fanctrl-detect`

**Commands:**
- `detect` - Detect hardware and print path
- `load` - Load module and detect
- `status` - Full status report

**Features:**
- Standalone CLI tool
- Can be run independently of plugin
- Shows PWM channels and fan RPMs
- Supports pkexec/sudo for module loading

**Example Output:**
```
╭──────────────────────────────────────╮
│     ASUS Fan Control - Status        │
╰──────────────────────────────────────╯

[OK] nct6775 kernel module: LOADED

[INFO] Scanning for NCT6775/NCT6798 hardware...
[OK] Hardware detected at: /sys/class/hwmon/hwmon5

Available PWM channels:
  PWM1: 46% - Smart Fan IV (Auto)
  PWM3: 43% - Smart Fan IV (Auto)
  PWM6: 20% - Smart Fan IV (Auto)

Fan RPMs:
  Fan3: 743 RPM
  Fan6: 620 RPM
```

### 4. Polkit Rules - Module Loading Permission

**Updated:** `50-asus-fanctrl.rules`

**New Permissions:**
1. Load nct6775 kernel module: `/sbin/modprobe nct6775`
2. Control PWM files: `/sys/class/hwmon/hwmon*`
3. Run detection helper: `/asus-fanctrl-detect`

**Installation:** Automatically deployed by `install_noctalia_plugin.sh`

### 5. install_noctalia_plugin.sh - Enhanced Installer

**Changes:**
- Installs `asus-fanctrl-detect` to `/usr/local/bin/`
- Updated polkit rule with module loading permission
- Better hardware detection feedback
- Shows detection helper location

---

## Testing Results

### Detection Helper Script
```bash
$ asus-fanctrl-detect status
✅ Module: LOADED
✅ Hardware: /sys/class/hwmon/hwmon5
✅ PWM1: 46% - Smart Fan IV (Auto)
✅ PWM3: 43% - Smart Fan IV (Auto)
✅ PWM6: 20% - Smart Fan IV (Auto)
✅ Fan3: 743 RPM
✅ Fan6: 620 RPM
```

### Hardware Detection Flow

**Success Path:**
1. Plugin loads → Detection starts
2. hwmon5 found → Hardware detected
3. Status: "Hardware detected"
4. Panel shows temperatures and fan speeds
5. Sliders enabled for control

**Module Not Loaded Path:**
1. Plugin loads → Detection starts
2. No hardware found → Retry 5 times
3. Status: "Hardware not detected - try loading nct6775 module"
4. User clicks "Load Module" button
5. pkexec prompts for password
6. Module loads → 2 second wait
7. Detection retries → Success
8. Panel becomes functional

**Hardware Missing Path:**
1. Plugin loads → Detection starts
2. No hardware found → Retry 5 times
3. Module load fails or no hardware
4. Status: "Hardware not detected after 5 attempts"
5. User informed with clear error message

---

## Files Modified

| File | Changes |
|------|---------|
| `noctalia-plugin/Main.qml` | Complete detection rewrite with retry logic |
| `noctalia-plugin/Panel.qml` | Enhanced error UI with buttons |
| `noctalia-plugin/asus-fanctrl-detect` | NEW - Detection helper script |
| `noctalia-plugin/50-asus-fanctrl.rules` | Added module loading permission |
| `install_noctalia_plugin.sh` | Install detection helper, updated polkit |

---

## Installation/Upgrade

### Fresh Install
```bash
./install_noctalia_plugin.sh
```

### Update Existing Install
```bash
# Reload polkit rules
sudo systemctl restart polkit

# Reinstall plugin
./install_noctalia_plugin.sh

# Reload Noctalia Shell
qs -c noctalia-shell reload
```

### Verify Installation
```bash
# Test detection helper
asus-fanctrl-detect status

# Check polkit rules
ls -la /etc/polkit-1/rules.d/50-asus-fanctrl.rules

# Verify plugin installed
ls -la ~/.config/noctalia/plugins/asus-fan-control/
```

---

## Troubleshooting

### Hardware Still Not Detected

1. **Check module loaded:**
   ```bash
   lsmod | grep nct6775
   ```

2. **Check hwmon devices:**
   ```bash
   ls /sys/class/hwmon/hwmon*/name | xargs -I {} sh -c 'echo "=== {} ==="; cat {}'
   ```

3. **Try manual module load:**
   ```bash
   sudo modprobe nct6775
   asus-fanctrl-detect detect
   ```

4. **Check polkit permissions:**
   ```bash
   pkexec modprobe nct6775
   # Should not prompt for password after polkit rule installed
   ```

### Module Load Fails

1. **Check Secure Boot:**
   ```bash
   mokutil --sb-state
   ```
   If enabled, unsigned modules won't load.

2. **Check kernel messages:**
   ```bash
   dmesg | grep nct6775
   ```

3. **Verify module exists:**
   ```bash
   modinfo nct6775
   ```

---

## Recommendations

### For Users

1. **After installation:** Run `asus-fanctrl-detect status` to verify hardware
2. **If "no hardware":** Click "Load Module" button in panel
3. **Persistent issues:** Check `dmesg` for hardware errors

### For Developers

1. **Add logging:** Consider adding debug mode with verbose logging
2. **Auto-load module:** Consider systemd module to load at boot:
   ```bash
   # /etc/modules-load.d/asus-fanctrl.conf
   nct6775
   ```
3. **GUI notifications:** Add toast notifications for detection events

---

## Conclusion

The hardware detection issue has been resolved with:

✅ **Deferred detection** - No longer runs during fragile initialization phase
✅ **Retry logic** - 5 attempts with delays instead of single try
✅ **Module loading** - Can load nct6775 via UI button
✅ **Better UX** - Clear status messages and actionable buttons
✅ **CLI tool** - Standalone detection for troubleshooting
✅ **Polkit rules** - Proper permissions for all operations

The plugin should now reliably detect hardware on systems with NCT6775/NCT6798 chips, even if the kernel module isn't loaded at startup.
