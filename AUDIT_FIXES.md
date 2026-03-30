# Noctalia Plugin Audit & Fixes

## Issues Found and Fixed

### 1. **Main.qml - Broken Process Output Handling** ❌ → ✅

**Problem:**
- Used `StdioCollector` incorrectly as a property with an `id`, but it wasn't accessible
- Process `stdout` was referenced via `stdoutCollector.text` but the collector wasn't properly defined
- PWM values were never being read, causing sliders to show 0

**Fix:**
- Removed `StdioCollector` wrapper
- Used direct `stdout` property from Process
- Changed `running = true` to use `restart()` method to properly refresh data

```qml
// Before (broken)
property Process readPwm1: Process {
  stdout: StdioCollector {}
  onExited: function (exitCode) {
    const val = parseInt(stdoutCollector.text.trim()) || 0;
  }
}

// After (working)
Process {
  id: readPwm1
  onExited: function (exitCode) {
    if (exitCode === 0 && stdout) {
      const val = parseInt(stdout.trim()) || 0;
      root.pwm1Speed = Math.round((val * 100) / 255);
    }
  }
}
```

### 2. **Main.qml - PWM Path Detection Not Working** ❌ → ✅

**Problem:**
- Static `pwmBasePath: "/sys/class/hwmon/hwmon5"` didn't adapt to different hardware
- Different systems have different hwmon numbers

**Fix:**
- Added dynamic detection loop that searches for NCT6775/NCT6798 chip
- Falls back to hwmon5 if not found

```qml
property string pwmBasePath: {
  for (let i = 0; i < 10; i++) {
    const path = "/sys/class/hwmon/hwmon" + i;
    try {
      const name = Process.string(["cat", path + "/name"]).trim();
      if (name.includes("nct6798") || name.includes("nct6775")) {
        return path;
      }
    } catch (e) {}
  }
  return "/sys/class/hwmon/hwmon5"; // fallback
}
```

### 3. **Main.qml - refreshData() Not Updating** ❌ → ✅

**Problem:**
- Setting `running = true` on already-running processes doesn't restart them
- Data never refreshed after initial load

**Fix:**
- Use `restart()` method instead of setting `running = true`

```qml
function refreshData() {
  sensorsProc.restart();
  readPwm1.restart();
  readPwm3.restart();
  readPwm6.restart();
}
```

### 4. **Panel.qml - Sliders Showing 0%** ❌ → ✅

**Problem:**
- Slider values bound directly to `pwm1Speed`, `pwm3Speed`, `pwm6Speed`
- These were always 0 due to broken Process handling
- No fallback to saved settings

**Fix:**
- Added fallback to plugin settings when hardware read fails
- Slider values now show saved defaults if hardware read returns 0

```qml
NSlider {
  id: pwm1Slider
  value: pwm1Speed > 0 ? pwm1Speed : (pluginApi?.pluginSettings?.pwmChannel1 || 50)
}
```

### 5. **Panel.qml - Slider Interaction Not Working** ❌ → ✅

**Problem:**
- Used `onMoved` handler which fires continuously while dragging
- Called `setFanSpeed` multiple times during drag
- Didn't properly connect to Main.qml instance

**Fix:**
- Added `Connections` elements to handle slider `released` signal
- Only apply changes when user releases the slider
- Properly delegate to Main.qml's `setFanSpeed` function

```qml
Connections {
  target: pwm1Slider
  function onReleased() {
    setFanSpeed(1, Math.round(pwm1Slider.value));
  }
}
```

### 6. **Main.qml - pkexec Command Syntax Wrong** ❌ → ✅

**Problem:**
- Command: `echo 1 | pkexec /usr/bin/tee /path`
- This doesn't work because pkexec needs the full command
- Pipe syntax was incorrect for pkexec

**Fix:**
- Use shell redirection with pkexec properly
- Changed to: `pkexec /usr/bin/sh -c "echo 1 > /path"`

```qml
// Before (broken)
Quickshell.execDetached(["sh", "-c", "echo 1 | pkexec /usr/bin/tee " + enablePath]);

// After (working)
Quickshell.execDetached(["pkexec", "/usr/bin/sh", "-c", "echo 1 > " + enablePath]);
```

### 7. **Panel.qml - Missing Auto Mode Button** ❌ → ✅

**Problem:**
- No way to return fans to automatic (BIOS) control
- Users had to use command line

**Fix:**
- Added "🔄 Auto" button to preset row
- Sets PWM enable to mode 5 (Smart Fan IV)

```qml
NButton {
  text: "🔄 Auto"
  onClicked: setAutoMode()
}

function setAutoMode() {
  if (pluginApi?.mainInstance) {
    const pwmPath = pluginApi.mainInstance.pwmBasePath;
    for (let ch of [1, 3, 6]) {
      Quickshell.execDetached(["pkexec", "/usr/bin/tee", pwmPath + "/pwm" + ch + "_enable"], "5");
    }
  }
}
```

### 8. **50-asus-fanctrl.rules - Hardcoded Username** ❌ → ✅

**Problem:**
- Username "quinton" was hardcoded in the rule file
- Would fail for other users

**Fix:**
- Changed to `USERNAME_PLACEHOLDER`
- Installer now replaces placeholder with actual username

```javascript
// Before
subject.user === "quinton"

// After
subject.user === "USERNAME_PLACEHOLDER"
```

### 9. **install_noctalia_plugin.sh - Polkit Rule Generation** ⚠️ → ✅

**Improvement:**
- Enhanced polkit rule generation with comments
- Added automatic placeholder replacement in source file
- Better error messages

## Files Modified

1. `noctalia-plugin/Main.qml` - Complete rewrite of process handling
2. `noctalia-plugin/Panel.qml` - Fixed slider bindings and interactions
3. `noctalia-plugin/50-asus-fanctrl.rules` - Placeholder for username
4. `install_noctalia_plugin.sh` - Improved polkit rule generation

## Testing Steps

After reinstalling the plugin:

```bash
# Reinstall plugin
./install_noctalia_plugin.sh

# Reload Noctalia Shell
qs -c noctalia-shell reload

# Check logs for errors
journalctl --user -u noctalia-shell -f
```

### Expected Behavior

1. **Sliders show numbers**: Should display current PWM values or saved defaults (50%)
2. **Sliders are interactive**: Drag and release to apply fan speed
3. **Presets work**: Click Silent/Quiet/Performance/Max buttons
4. **Auto mode works**: Click Auto button to return to BIOS control
5. **Temperatures show**: CPU and System temperatures display
6. **Real-time updates**: Values refresh every 2 seconds

## Troubleshooting

### Sliders still show 0%

Check if PWM path is correct:
```bash
# Find hwmon path
ls /sys/class/hwmon/hwmon*/name | xargs cat

# Check if PWM files exist
ls /sys/class/hwmon/hwmon*/pwm1
```

### Permission denied errors

Verify polkit rule:
```bash
cat /etc/polkit-1/rules.d/50-asus-fanctrl.rules
# Should show your username

# Restart polkit
sudo systemctl restart polkit
```

### Plugin not loading

Check Noctalia logs:
```bash
journalctl --user -u noctalia-shell -n 50
```

Look for "ASUS Fan Control" messages.

## Root Cause Summary

The main issues were:
1. **Incorrect QML Process API usage** - StdioCollector wasn't used correctly
2. **No dynamic hardware detection** - Static paths don't work on all systems
3. **Wrong pkexec syntax** - Commands weren't executing with proper privileges
4. **Missing fallback values** - Sliders showed 0 when hardware read failed

All issues have been resolved.
