#!/bin/bash

# Smart Fan Control Daemon for ASUS ROG STRIX B550-F
# This script provides temperature-based automatic fan control

# Load shared library
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${LIB_DIR}/fan_control_lib.sh" ]; then
    source "${LIB_DIR}/fan_control_lib.sh"
else
    echo "Error: fan_control_lib.sh not found!" >&2
    exit 1
fi

# Auto-detect the correct hwmon path
PWM_BASE_PATH=$(find_hwmon_path)
if [ $? -ne 0 ]; then
    log_error "Could not locate hardware monitor for NCT6775/NCT6798 chips."
    exit 1
fi

# Journal integration
log_journal() {
    if [ -n "${INVOCATION_ID:-}" ]; then
        echo "$1" | systemd-cat -t smart-fan-daemon -p info
    fi
}

CONFIG_FILE="${HOME}/.config/fanctrl.conf"

# Default configuration
PWM_CHANNEL=$(get_config_val "pwm_channel" "1" "$CONFIG_FILE")
TEMP_MIN=$(get_config_val "temp_min" "30" "$CONFIG_FILE")
TEMP_MAX=$(get_config_val "temp_max" "70" "$CONFIG_FILE")
FAN_MIN=$(get_config_val "fan_min" "20" "$CONFIG_FILE")
FAN_MAX=$(get_config_val "fan_max" "100" "$CONFIG_FILE")
UPDATE_INTERVAL=$(get_config_val "update_interval" "5" "$CONFIG_FILE")

# Save current configuration
save_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Fan Control Configuration
pwm_channel=${PWM_CHANNEL}
temp_min=${TEMP_MIN}
temp_max=${TEMP_MAX}
fan_min=${FAN_MIN}
fan_max=${FAN_MAX}
update_interval=${UPDATE_INTERVAL}
EOF
    log_success "Configuration saved to $CONFIG_FILE"
}

# Get CPU temperature
get_cpu_temp() {
    local temp=$(sensors | grep 'Tctl:' | awk '{print $2}' | sed 's/+//g' | sed 's/°C//g')
    echo ${temp%.*}  # Remove decimal part
}

# Calculate fan speed based on temperature
calculate_fan_speed() {
    local temp=$1
    
    if [ $temp -le $TEMP_MIN ]; then
        echo $FAN_MIN
    elif [ $temp -ge $TEMP_MAX ]; then
        echo $FAN_MAX
    else
        # Linear interpolation
        local temp_range=$((TEMP_MAX - TEMP_MIN))
        local fan_range=$((FAN_MAX - FAN_MIN))
        local temp_offset=$((temp - TEMP_MIN))
        local speed=$((FAN_MIN + (temp_offset * fan_range / temp_range)))
        echo $speed
    fi
}

# Set fan speed
set_fan_speed() {
    local channel=$1
    local percentage=$2
    local pwm_value=$((percentage * 255 / 100))
    
    # Ensure PWM is in manual mode
    if ! echo 1 > "${PWM_BASE_PATH}/pwm${channel}_enable" 2>/dev/null; then
        log_error "Failed to set PWM${channel} to manual mode"
        return 1
    fi
    
    # Set the speed
    if ! echo $pwm_value > "${PWM_BASE_PATH}/pwm${channel}" 2>/dev/null; then
        log_error "Failed to set PWM${channel} speed to ${percentage}%"
        return 1
    fi
    
    return 0
}

# Main daemon loop
run_daemon() {
    log_info "Starting smart fan control daemon..."
    log_info "PWM Base Path: $PWM_BASE_PATH"
    log_info "PWM Channel: $PWM_CHANNEL"
    log_info "Temperature range: ${TEMP_MIN}°C - ${TEMP_MAX}°C"
    log_info "Fan speed range: ${FAN_MIN}% - ${FAN_MAX}%"
    log_info "Update interval: ${UPDATE_INTERVAL}s"
    
    log_journal "Daemon started on PWM$PWM_CHANNEL"

    # Check if PWM files exist
    if [ ! -f "${PWM_BASE_PATH}/pwm${PWM_CHANNEL}" ]; then
        log_error "PWM file for channel ${PWM_CHANNEL} not found at ${PWM_BASE_PATH}"
        exit 1
    fi
    
    # Set initial manual mode
    if ! echo 1 > "${PWM_BASE_PATH}/pwm${PWM_CHANNEL}_enable" 2>/dev/null; then
        log_error "Cannot set PWM${PWM_CHANNEL} to manual mode. Check permissions/udev rules."
        exit 1
    fi
    
    # Trap to restore automatic mode on exit
    trap "echo 5 > '${PWM_BASE_PATH}/pwm${PWM_CHANNEL}_enable' 2>/dev/null; log_info 'Restored automatic fan control'; exit 0" INT TERM
    
    # Main loop
    while true; do
        local temp=$(get_cpu_temp)
        if [ -z "$temp" ]; then
            log_warn "Failed to read temperature"
            sleep $UPDATE_INTERVAL
            continue
        fi

        local target_speed=$(calculate_fan_speed $temp)
        set_fan_speed $PWM_CHANNEL $target_speed
        
        log_journal "CPU: ${temp}°C, Fan Speed: ${target_speed}%"
        
        sleep $UPDATE_INTERVAL
    done
}

# Interactive configuration
configure() {
    echo "=== Fan Control Configuration ==="
    echo ""
    
    read -p "Enter PWM channel [$PWM_CHANNEL]: " val; PWM_CHANNEL=${val:-$PWM_CHANNEL}
    read -p "Minimum temperature (°C) [$TEMP_MIN]: " val; TEMP_MIN=${val:-$TEMP_MIN}
    read -p "Maximum temperature (°C) [$TEMP_MAX]: " val; TEMP_MAX=${val:-$TEMP_MAX}
    read -p "Minimum fan speed (%) [$FAN_MIN]: " val; FAN_MIN=${val:-$FAN_MIN}
    read -p "Maximum fan speed (%) [$FAN_MAX]: " val; FAN_MAX=${val:-$FAN_MAX}
    read -p "Update interval (seconds) [$UPDATE_INTERVAL]: " val; UPDATE_INTERVAL=${val:-$UPDATE_INTERVAL}
    
    echo ""
    echo "Configuration summary:"
    echo "  PWM Channel: $PWM_CHANNEL"
    echo "  Temperature: ${TEMP_MIN}°C - ${TEMP_MAX}°C"
    echo "  Fan Speed: ${FAN_MIN}% - ${FAN_MAX}%"
    echo "  Interval: ${UPDATE_INTERVAL}s"
    echo ""
    
    read -p "Save configuration? [Y/n]: " save_confirm
    if [[ ! "$save_confirm" =~ ^[nN] ]]; then
        save_config
    fi
}

# Command handling
case "$1" in
    "run")
        run_daemon
        ;;
    "config")
        configure
        ;;
    "test")
        temp=$(get_cpu_temp)
        speed=$(calculate_fan_speed $temp)
        echo "Current CPU temperature: ${temp}°C"
        echo "Calculated fan speed: ${speed}%"
        ;;
    "stop")
        echo 5 > "${PWM_BASE_PATH}/pwm${PWM_CHANNEL}_enable" 2>/dev/null
        log_success "PWM${PWM_CHANNEL} returned to automatic mode"
        ;;
    "status")
        "${LIB_DIR}/fan_control.sh" status
        ;;
    *)
        echo "Usage: $0 {run|config|test|stop|status}"
        exit 1
        ;;
esac

