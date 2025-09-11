#!/bin/bash

# Smart Fan Control Daemon for ASUS ROG STRIX B550-F
# This script provides temperature-based automatic fan control
# Modified for systemd service integration with better logging

# Auto-detect the correct hwmon path for NCT6798 chip
PWM_BASE_PATH=$(find /sys/class/hwmon/ -name "hwmon*" -exec sh -c 'if [ -f "$1/name" ] && grep -q "nct6798" "$1/name" 2>/dev/null; then echo "$1"; fi' _ {} \; | head -1)
# Fallback to hwmon2 if auto-detection fails
if [ -z "$PWM_BASE_PATH" ]; then
    PWM_BASE_PATH="/sys/class/hwmon/hwmon2"
    echo "Warning: Auto-detection failed, using fallback path $PWM_BASE_PATH" >&2
fi

# Log to journal with the correct identifier when running as a service
log() {
    echo "$@"
    if [ "${INVOCATION_ID:-}" != "" ]; then
        echo "$@" | systemd-cat -t smart-fan-daemon -p info
    fi
}

CONFIG_FILE="/home/sasha/.fan_control_config"

# Default configuration
declare -A FAN_CONFIG
FAN_CONFIG[pwm_channel]=1
FAN_CONFIG[temp_min]=30
FAN_CONFIG[temp_max]=70
FAN_CONFIG[fan_min]=20
FAN_CONFIG[fan_max]=100
FAN_CONFIG[update_interval]=5

# Load configuration if exists
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        log "Configuration loaded from $CONFIG_FILE"
    else
        log "Using default configuration. Run '$0 config' to customize."
    fi
}

# Save current configuration
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Fan Control Configuration
# PWM channel to control (1-6)
FAN_CONFIG[pwm_channel]=${FAN_CONFIG[pwm_channel]}

# Temperature range (°C)
FAN_CONFIG[temp_min]=${FAN_CONFIG[temp_min]}
FAN_CONFIG[temp_max]=${FAN_CONFIG[temp_max]}

# Fan speed range (%)
FAN_CONFIG[fan_min]=${FAN_CONFIG[fan_min]}
FAN_CONFIG[fan_max]=${FAN_CONFIG[fan_max]}

# Update interval (seconds)
FAN_CONFIG[update_interval]=${FAN_CONFIG[update_interval]}
EOF
    log "Configuration saved to $CONFIG_FILE"
}

# Get CPU temperature
get_cpu_temp() {
    local temp=$(sensors | grep 'Tctl:' | awk '{print $2}' | sed 's/+//g' | sed 's/°C//g')
    echo ${temp%.*}  # Remove decimal part
}

# Calculate fan speed based on temperature
calculate_fan_speed() {
    local temp=$1
    local temp_min=${FAN_CONFIG[temp_min]}
    local temp_max=${FAN_CONFIG[temp_max]}
    local fan_min=${FAN_CONFIG[fan_min]}
    local fan_max=${FAN_CONFIG[fan_max]}
    
    if [ $temp -le $temp_min ]; then
        echo $fan_min
    elif [ $temp -ge $temp_max ]; then
        echo $fan_max
    else
        # Linear interpolation
        local temp_range=$((temp_max - temp_min))
        local fan_range=$((fan_max - fan_min))
        local temp_offset=$((temp - temp_min))
        local speed=$((fan_min + (temp_offset * fan_range / temp_range)))
        echo $speed
    fi
}

# Set fan speed
set_fan_speed() {
    local pwm_channel=$1
    local percentage=$2
    local pwm_value=$((percentage * 255 / 100))
    
    # Ensure PWM is in manual mode
    echo 1 > "${PWM_BASE_PATH}/pwm${pwm_channel}_enable" 2>/dev/null
    if [ $? -ne 0 ]; then
        log "Error: Failed to set PWM${pwm_channel} to manual mode" >&2
        return 1
    fi
    
    # Set the speed
    echo $pwm_value > "${PWM_BASE_PATH}/pwm${pwm_channel}" 2>/dev/null
    if [ $? -ne 0 ]; then
        log "Error: Failed to set PWM${pwm_channel} speed to ${percentage}%" >&2
        return 1
    fi
    
    return 0
}

# Main daemon loop
run_daemon() {
    local pwm_channel=${FAN_CONFIG[pwm_channel]}
    local interval=${FAN_CONFIG[update_interval]}
    
    log "Starting smart fan control daemon..."
    log "PWM Base Path: $PWM_BASE_PATH"
    log "PWM Channel: $pwm_channel"
    log "Temperature range: ${FAN_CONFIG[temp_min]}°C - ${FAN_CONFIG[temp_max]}°C"
    log "Fan speed range: ${FAN_CONFIG[fan_min]}% - ${FAN_CONFIG[fan_max]}%"
    log "Update interval: ${interval}s"
    
    # Check if PWM files exist and are writable
    if [ ! -f "${PWM_BASE_PATH}/pwm${pwm_channel}" ] || [ ! -f "${PWM_BASE_PATH}/pwm${pwm_channel}_enable" ]; then
        log "Error: PWM files for channel ${pwm_channel} not found at ${PWM_BASE_PATH}" >&2
        return 1
    fi
    
    # Set initial manual mode
    echo 1 > "${PWM_BASE_PATH}/pwm${pwm_channel}_enable"
    if [ $? -ne 0 ]; then
        log "Error: Cannot set PWM${pwm_channel} to manual mode. Check permissions." >&2
        return 1
    fi
    
    # Trap to restore automatic mode on exit (when running interactively)
    trap "echo 5 > '${PWM_BASE_PATH}/pwm${pwm_channel}_enable'; log 'Restored automatic fan control'; exit 0" INT TERM
    
    # Log initial temperature and fan speed
    local temp=$(get_cpu_temp)
    local target_speed=$(calculate_fan_speed $temp)
    log "Initial CPU temperature: ${temp}°C, Setting fan speed: ${target_speed}%"
    
    # Main loop
    while true; do
        local temp=$(get_cpu_temp)
        local target_speed=$(calculate_fan_speed $temp)
        
        set_fan_speed $pwm_channel $target_speed
        
        log "$(date '+%Y-%m-%d %H:%M:%S') - CPU: ${temp}°C, Fan Speed: ${target_speed}%"
        
        sleep $interval
    done
}

# Interactive configuration
configure() {
    echo "=== Fan Control Configuration ==="
    echo ""
    
    echo "Current PWM channel: ${FAN_CONFIG[pwm_channel]}"
    echo "Available channels: 1, 2, 3, 4, 5, 6"
    read -p "Enter PWM channel [${FAN_CONFIG[pwm_channel]}]: " new_channel
    if [ -n "$new_channel" ]; then
        FAN_CONFIG[pwm_channel]=$new_channel
    fi
    
    echo ""
    echo "Temperature range configuration:"
    read -p "Minimum temperature (°C) [${FAN_CONFIG[temp_min]}]: " new_temp_min
    if [ -n "$new_temp_min" ]; then
        FAN_CONFIG[temp_min]=$new_temp_min
    fi
    
    read -p "Maximum temperature (°C) [${FAN_CONFIG[temp_max]}]: " new_temp_max
    if [ -n "$new_temp_max" ]; then
        FAN_CONFIG[temp_max]=$new_temp_max
    fi
    
    echo ""
    echo "Fan speed range configuration:"
    read -p "Minimum fan speed (%) [${FAN_CONFIG[fan_min]}]: " new_fan_min
    if [ -n "$new_fan_min" ]; then
        FAN_CONFIG[fan_min]=$new_fan_min
    fi
    
    read -p "Maximum fan speed (%) [${FAN_CONFIG[fan_max]}]: " new_fan_max
    if [ -n "$new_fan_max" ]; then
        FAN_CONFIG[fan_max]=$new_fan_max
    fi
    
    echo ""
    read -p "Update interval (seconds) [${FAN_CONFIG[update_interval]}]: " new_interval
    if [ -n "$new_interval" ]; then
        FAN_CONFIG[update_interval]=$new_interval
    fi
    
    echo ""
    echo "Configuration summary:"
    echo "  PWM Channel: ${FAN_CONFIG[pwm_channel]}"
    echo "  Temperature: ${FAN_CONFIG[temp_min]}°C - ${FAN_CONFIG[temp_max]}°C"
    echo "  Fan Speed: ${FAN_CONFIG[fan_min]}% - ${FAN_CONFIG[fan_max]}%"
    echo "  Interval: ${FAN_CONFIG[update_interval]}s"
    echo ""
    
    read -p "Save configuration? [Y/n]: " save_confirm
    if [ "$save_confirm" != "n" ] && [ "$save_confirm" != "N" ]; then
        save_config
    fi
}

# Show help
show_help() {
    echo "Smart Fan Control Daemon for ASUS ROG STRIX B550-F"
    echo ""
    echo "Usage:"
    echo "  $0 run         - Start the fan control daemon"
    echo "  $0 config      - Configure fan control settings"
    echo "  $0 test        - Test current configuration"
    echo "  $0 stop        - Stop manual control (return to BIOS control)"
    echo "  $0 status      - Show current status"
    echo ""
    echo "Configuration file: $CONFIG_FILE"
    echo "PWM Base Path: $PWM_BASE_PATH"
}

# Test configuration
test_config() {
    load_config
    local temp=$(get_cpu_temp)
    local speed=$(calculate_fan_speed $temp)
    
    echo "=== Configuration Test ==="
    echo "PWM Base Path: $PWM_BASE_PATH"
    echo "Current CPU temperature: ${temp}°C"
    echo "Calculated fan speed: ${speed}%"
    echo ""
    echo "Temperature curve:"
    for test_temp in 25 30 40 50 60 70 80; do
        local test_speed=$(calculate_fan_speed $test_temp)
        echo "  ${test_temp}°C -> ${test_speed}%"
    done
}

# Stop daemon and return to auto
stop_daemon() {
    load_config
    local pwm_channel=${FAN_CONFIG[pwm_channel]}
    echo "Returning PWM${pwm_channel} to automatic control..."
    echo 5 > "${PWM_BASE_PATH}/pwm${pwm_channel}_enable" 2>/dev/null
    echo "✓ PWM${pwm_channel} returned to automatic mode"
}

# Load configuration
load_config

# Main command handling
case "$1" in
    "run"|"daemon")
        run_daemon
        ;;
    "config"|"configure")
        configure
        ;;
    "test")
        test_config
        ;;
    "stop")
        stop_daemon
        ;;
    "status")
        ./fan_control.sh status
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
