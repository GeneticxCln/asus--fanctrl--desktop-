# ASUS Fan Control Zsh Plugin
# Source this file in your .zshrc
# Add: source /path/to/fan_control_zsh_plugin.zsh

# Plugin directory
FANCTRL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running as root
_fanctrl_check_root() {
    if [ "$EUID" -eq 0 ]; then
        echo "⚠️  Fan control should not be run as root"
        return 1
    fi
}

# Check hardware detection
_fanctrl_check_hardware() {
    if ! ls /sys/class/hwmon/hwmon*/name 2>/dev/null | xargs grep -q "nct6798\|nct6775" 2>/dev/null; then
        echo "⚠️  NCT6775/NCT6798 chip not detected. Loading module..."
        sudo modprobe nct6775 2>/dev/null || return 1
        sleep 2
    fi
    return 0
}

# Get PWM base path
_fanctrl_get_pwm_path() {
    local path=$(find /sys/class/hwmon/ -name "hwmon*" -exec sh -c 'if [ -f "$1/name" ] && grep -q "nct6798\|nct6775" "$1/name" 2>/dev/null; then echo "$1"; fi' _ {} \; | head -1)
    if [ -z "$path" ]; then
        echo "/sys/class/hwmon/hwmon5"  # Fallback
    else
        echo "$path"
    fi
}

# Get current fan speed percentage
_fanctrl_get_speed() {
    local pwm_channel=$1
    local pwm_path=$(_fanctrl_get_pwm_path)
    local pwm_val=$(cat "${pwm_path}/pwm${pwm_channel}" 2>/dev/null || echo "0")
    echo $((pwm_val * 100 / 255))
}

# Get fan RPM
_fanctrl_get_rpm() {
    local fan_num=$1
    local pwm_path=$(_fanctrl_get_pwm_path)
    local rpm=$(cat "${pwm_path}/fan${fan_num}_input" 2>/dev/null || echo "0")
    if [ "$rpm" -eq 0 ]; then
        echo "N/A"
    else
        echo "${rpm} RPM"
    fi
}

# Get CPU temperature
_fanctrl_get_temp() {
    sensors 2>/dev/null | grep -E 'Tctl|Package id 0' | head -1 | awk '{print $2}' | sed 's/+//g; s/°C//g'
}

# Set fan speed
_fanctrl_set_speed() {
    local pwm_channel=$1
    local percentage=$2
    local pwm_path=$(_fanctrl_get_pwm_path)
    
    if [ "$percentage" -lt 0 ] || [ "$percentage" -gt 100 ]; then
        echo "❌ Error: Percentage must be between 0 and 100"
        return 1
    fi
    
    local pwm_value=$((percentage * 255 / 100))
    
    # Set to manual mode
    echo 1 | sudo tee "${pwm_path}/pwm${pwm_channel}_enable" > /dev/null 2>&1
    # Set speed
    echo $pwm_value | sudo tee "${pwm_path}/pwm${pwm_channel}" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ PWM${pwm_channel} set to ${percentage}% (${pwm_value}/255)"
        return 0
    else
        echo "❌ Failed to set PWM${pwm_channel}"
        return 1
    fi
}

# Set fan to auto mode
_fanctrl_set_auto() {
    local pwm_channel=$1
    local pwm_path=$(_fanctrl_get_pwm_path)
    
    echo 5 | sudo tee "${pwm_path}/pwm${pwm_channel}_enable" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ PWM${pwm_channel} returned to automatic mode"
        return 0
    else
        echo "❌ Failed to set PWM${pwm_channel} to auto"
        return 1
    fi
}

# Show fan status
fanctrl-status() {
    local pwm_path=$(_fanctrl_get_pwm_path)
    
    echo "╭──────────────────────────────────────╮"
    echo "│       🖥️  ASUS Fan Control Status    │"
    echo "╰──────────────────────────────────────╯"
    
    echo ""
    echo "🌡️  Temperatures:"
    local cpu_temp=$(_fanctrl_get_temp)
    echo "   CPU: ${cpu_temp:-N/A}°C"
    
    echo ""
    echo "💨  Fan RPMs:"
    for i in {1..7}; do
        if [ -f "${pwm_path}/fan${i}_input" ]; then
            local rpm=$(_fanctrl_get_rpm $i)
            if [ "$rpm" != "N/A" ]; then
                printf "   Fan%d: %s\n" $i "$rpm"
            fi
        fi
    done
    
    echo ""
    echo "🔧  PWM Channels:"
    for i in {1..6}; do
        if [ -f "${pwm_path}/pwm${i}" ]; then
            local speed=$(_fanctrl_get_speed $i)
            local enable=$(cat "${pwm_path}/pwm${i}_enable" 2>/dev/null || echo "0")
            local mode="Unknown"
            case $enable in
                0) mode="Disabled" ;;
                1) mode="Manual" ;;
                2) mode="Thermal Cruise" ;;
                3) mode="Speed Cruise" ;;
                4) mode="Smart Fan III" ;;
                5) mode="Smart Fan IV (Auto)" ;;
            esac
            printf "   PWM%d: %3d%% - %s\n" $i $speed "$mode"
        fi
    done
    echo ""
}

# Quick preset: Silent mode (30%)
fanctrl-silent() {
    echo "🔇 Activating Silent Mode (30%)"
    _fanctrl_set_speed 1 30
    _fanctrl_set_speed 3 30
    _fanctrl_set_speed 6 30
}

# Quick preset: Quiet mode (50%)
fanctrl-quiet() {
    echo "🔉 Activating Quiet Mode (50%)"
    _fanctrl_set_speed 1 50
    _fanctrl_set_speed 3 50
    _fanctrl_set_speed 6 50
}

# Quick preset: Performance mode (80%)
fanctrl-performance() {
    echo "🔊 Activating Performance Mode (80%)"
    _fanctrl_set_speed 1 80
    _fanctrl_set_speed 3 80
    _fanctrl_set_speed 6 80
}

# Quick preset: Max speed (100%)
fanctrl-max() {
    echo "🚀 Activating Max Speed (100%)"
    _fanctrl_set_speed 1 100
    _fanctrl_set_speed 3 100
    _fanctrl_set_speed 6 100
}

# Return all fans to auto
fanctrl-auto() {
    echo "🔄 Returning all fans to automatic control"
    _fanctrl_set_auto 1
    _fanctrl_set_auto 3
    _fanctrl_set_auto 6
}

# Set specific fan speed
fanctrl-set() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: fanctrl-set <pwm_channel> <percentage>"
        echo "Example: fanctrl-set 1 60  (Set PWM1 to 60%)"
        return 1
    fi
    _fanctrl_set_speed $1 $2
}

# Launch GUI (if rofi is installed)
fanctrl-gui() {
    if command -v rofi &> /dev/null; then
        "${FANCTRL_DIR}/rofi_fan_control.sh"
    else
        echo "❌ Rofi is not installed. Install with: sudo pacman -S rofi"
        echo "   Or use fanctrl-status instead"
        return 1
    fi
}

# Show help
fanctrl-help() {
    cat << EOF
╭──────────────────────────────────────────────────╮
│          🖥️  ASUS Fan Control - Help            │
╰──────────────────────────────────────────────────╯

Usage:
  fanctrl-status      Show current fan status
  fanctrl-silent      Silent mode (30% all fans)
  fanctrl-quiet       Quiet mode (50% all fans)
  fanctrl-performance Performance mode (80% all fans)
  fanctrl-max         Max speed (100% all fans)
  fanctrl-auto        Return to automatic control
  fanctrl-set <ch> %  Set specific PWM channel
  fanctrl-gui         Launch Rofi GUI (requires rofi)
  fanctrl-help        Show this help

Examples:
  fanctrl-set 1 60    # Set PWM1 (CPU fan) to 60%
  fanctrl-set 3 40    # Set PWM3 to 40%

Keyboard Shortcuts (if configured):
  Ctrl+Alt+F          Open fan control GUI
  Ctrl+Alt+1          Silent mode
  Ctrl+Alt+2          Quiet mode
  Ctrl+Alt+3          Performance mode
  Ctrl+Alt+0          Auto mode
  Ctrl+Alt+T          Temperature monitoring

EOF
}

# Aliases for quick access
alias fcs='fanctrl-status'
alias fcsilent='fanctrl-silent'
alias fcquiet='fanctrl-quiet'
alias fcperf='fanctrl-performance'
alias fcmax='fanctrl-max'
alias fcauto='fanctrl-auto'

# Print welcome message on shell load (optional)
_fanctrl_welcome() {
    echo "✅ ASUS Fan Control plugin loaded"
    echo "   Type 'fanctrl-help' for usage info"
    echo "   Quick: fcsilent | fcquiet | fcperf | fcs"
}

# Uncomment to show welcome message on each shell load
# _fanctrl_welcome
