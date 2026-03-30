#!/bin/bash

# Fan Control Script for ASUS ROG STRIX B550-F motherboard
# Usage: ./fan_control.sh [pwm_channel] [speed_percentage]
# Example: ./fan_control.sh 1 50    (set PWM1 to 50%)

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

# Function to show current fan status
show_status() {
    echo "=== Current Fan Status ==="
    echo "Fan RPMs:"
    for i in {1..7}; do
        if [ -f "${PWM_BASE_PATH}/fan${i}_input" ]; then
            rpm=$(cat "${PWM_BASE_PATH}/fan${i}_input" 2>/dev/null)
            if [ -n "$rpm" ] && [ "$rpm" != "0" ]; then
                echo "  Fan$i: ${rpm} RPM"
            fi
        fi
    done
    
    echo -e "\nPWM Channels:"
    for i in {1..6}; do
        if [ -f "${PWM_BASE_PATH}/pwm${i}" ]; then
            pwm_val=$(cat "${PWM_BASE_PATH}/pwm${i}" 2>/dev/null)
            enable_val=$(cat "${PWM_BASE_PATH}/pwm${i}_enable" 2>/dev/null)
            percentage=$((pwm_val * 100 / 255))
            
            case $enable_val in
                0) mode="No control" ;;
                1) mode="Manual PWM" ;;
                2) mode="Thermal cruise" ;;
                3) mode="Fan speed cruise" ;;
                4) mode="Smart Fan III" ;;
                5) mode="Smart Fan IV" ;;
                *) mode="Unknown" ;;
            esac
            
            echo "  PWM$i: ${percentage}% (${pwm_val}/255) - Mode: $mode"
        fi
    done
    
    echo -e "\nTemperatures:"
    cpu_temp=$(sensors | grep 'Tctl:' | awk '{print $2}')
    sys_temp=$(sensors | grep 'SYSTIN:' | awk '{print $2}')
    echo "  CPU: ${cpu_temp:-N/A}"
    echo "  System: ${sys_temp:-N/A}"
}

# Function to set PWM to manual mode
set_manual_mode() {
    local pwm_channel=$1
    log_info "Setting PWM${pwm_channel} to manual mode..."
    if echo 1 > "${PWM_BASE_PATH}/pwm${pwm_channel}_enable" 2>/dev/null; then
        log_success "PWM${pwm_channel} is now in manual mode"
    else
        log_error "Failed to set PWM${pwm_channel} to manual mode. Permission denied?"
        return 1
    fi
}

# Function to set fan speed
set_fan_speed() {
    local pwm_channel=$1
    local percentage=$2
    
    # Convert percentage to PWM value (0-255)
    local pwm_value=$((percentage * 255 / 100))
    
    log_info "Setting PWM${pwm_channel} to ${percentage}% (${pwm_value}/255)..."
    if echo $pwm_value > "${PWM_BASE_PATH}/pwm${pwm_channel}" 2>/dev/null; then
        log_success "PWM${pwm_channel} set to ${percentage}%"
    else
        log_error "Failed to set PWM${pwm_channel}. Permission denied?"
        return 1
    fi
}

# Function to reset PWM to automatic mode
set_auto_mode() {
    local pwm_channel=$1
    log_info "Setting PWM${pwm_channel} to automatic mode (Smart Fan IV)..."
    if echo 5 > "${PWM_BASE_PATH}/pwm${pwm_channel}_enable" 2>/dev/null; then
        log_success "PWM${pwm_channel} is now in automatic mode"
    else
        log_error "Failed to set PWM${pwm_channel} to automatic mode. Permission denied?"
        return 1
    fi
}

# Main script logic
case "$1" in
    "status"|"")
        show_status
        ;;
    "manual")
        if [ -z "$2" ]; then
            echo "Usage: $0 manual [pwm_channel]"
            exit 1
        fi
        set_manual_mode $2
        ;;
    "auto")
        if [ -z "$2" ]; then
            echo "Usage: $0 auto [pwm_channel]"
            exit 1
        fi
        set_auto_mode $2
        ;;
    "set")
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 set [pwm_channel] [percentage]"
            exit 1
        fi
        
        pwm_channel=$2
        percentage=$3
        
        # Validate percentage
        if [ "$percentage" -lt 0 ] || [ "$percentage" -gt 100 ]; then
            log_error "Percentage must be between 0 and 100"
            exit 1
        fi
        
        # Set to manual mode first, then set speed
        if [ "$EUID" -ne 0 ]; then
            sudo -n /usr/local/bin/asus-fanctrl-detect set-enable "$pwm_channel" 1 && \
            sudo -n /usr/local/bin/asus-fanctrl-detect set-pwm "$pwm_channel" "$percentage"
        else
            set_manual_mode $pwm_channel && set_fan_speed $pwm_channel $percentage
        fi
        ;;
    "help"|"-h"|"--help")
        echo "Fan Control Script for ASUS ROG STRIX B550-F"
        echo "Usage:"
        echo "  $0 [status]              - Show current fan status (default)"
        echo "  $0 manual [channel]      - Set PWM channel to manual mode"
        echo "  $0 auto [channel]        - Set PWM channel to automatic mode"
        echo "  $0 set [channel] [%]     - Set PWM channel to specific percentage"
        echo ""
        echo "Available PWM channels: 1, 2, 3, 4, 5, 6"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac

