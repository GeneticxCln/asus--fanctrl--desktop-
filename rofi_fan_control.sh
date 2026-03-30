#!/bin/bash

# Rofi Fan Control GUI for ASUS ROG STRIX B550-F
# A clean, simple interface for controlling fans

# Load shared library
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${LIB_DIR}/fan_control_lib.sh" ]; then
    source "${LIB_DIR}/fan_control_lib.sh"
else
    # Fallback to current directory for development/testing
    if [ -f "./fan_control_lib.sh" ]; then
        source "./fan_control_lib.sh"
    else
        echo "Error: fan_control_lib.sh not found!" >&2
        exit 1
    fi
fi

# Auto-detect the correct hwmon path
PWM_BASE_PATH=$(find_hwmon_path)
if [ $? -ne 0 ]; then
    rofi -e "Error: Could not locate fan control hardware."
    exit 1
fi

# Determine the core control script path
# Prefer /usr/local/bin if it exists, otherwise use local path
if [ -x "/usr/local/bin/fan_control.sh" ]; then
    FAN_CONTROL_SCRIPT="/usr/local/bin/fan_control.sh"
else
    FAN_CONTROL_SCRIPT="${LIB_DIR}/fan_control.sh"
fi

# Determine the daemon script path
if [ -x "/usr/local/bin/smart_fan_daemon.sh" ]; then
    DAEMON_SCRIPT="/usr/local/bin/smart_fan_daemon.sh"
else
    DAEMON_SCRIPT="${LIB_DIR}/smart_fan_daemon.sh"
fi

# Get current fan status
get_fan_status() {
    local pwm_channel=$1
    local pwm_val=$(cat "${PWM_BASE_PATH}/pwm${pwm_channel}" 2>/dev/null || echo "0")
    local enable_val=$(cat "${PWM_BASE_PATH}/pwm${pwm_channel}_enable" 2>/dev/null || echo "0")
    local percentage=$((pwm_val * 100 / 255))
    
    case $enable_val in
        0) echo "OFF" ;;
        1) echo "${percentage}% (Manual)" ;;
        2) echo "Thermal" ;;
        5) echo "Auto" ;;
        *) echo "Unknown ($enable_val)" ;;
    esac
}

# Get fan RPM
get_fan_rpm() {
    local fan_num=$1
    local rpm=$(cat "${PWM_BASE_PATH}/fan${fan_num}_input" 2>/dev/null || echo "0")
    if [ -z "$rpm" ] || [ "$rpm" -eq 0 ]; then
        echo "N/A"
    else
        echo "${rpm} RPM"
    fi
}

# Get CPU temperature
get_cpu_temp() {
    sensors | grep 'Tctl:' | awk '{print $2}' | sed 's/+//g'
}

# Set fan speed
set_fan_speed() {
    local pwm_channel=$1
    local percentage=$2
    "$FAN_CONTROL_SCRIPT" set "${pwm_channel}" "${percentage}" >/dev/null 2>&1
}

# Set fan to auto mode
set_fan_auto() {
    local pwm_channel=$1
    "$FAN_CONTROL_SCRIPT" auto "${pwm_channel}" >/dev/null 2>&1
}

# Main menu
show_main_menu() {
    local cpu_temp=$(get_cpu_temp)
    local pwm1_status=$(get_fan_status 1)
    local pwm3_status=$(get_fan_status 3)
    local pwm6_status=$(get_fan_status 6)
    
    local menu_options=""
    menu_options+="🌡️  CPU Temp: ${cpu_temp:-N/A}\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="🔧  PWM1 (CPU Fan): ${pwm1_status}\n"
    menu_options+="🔧  PWM3 (Chassis): ${pwm3_status} - $(get_fan_rpm 3)\n"
    menu_options+="🔧  PWM6 (Chassis): ${pwm6_status} - $(get_fan_rpm 6)\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="⚡  Quick Presets\n"
    menu_options+="🔧  Manual Control\n"
    menu_options+="📊  Monitoring\n"
    menu_options+="🔄  Smart Daemon\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="❌  Exit"
    
    local choice
    choice=$(echo -e "$menu_options" | rofi -dmenu -i -p "Fan Control" \
        -theme-str 'window {width: 450px;} listview {lines: 12;}' \
        -no-custom)
    
    case "$choice" in
        *"Quick Presets"*) show_presets_menu ;;
        *"Manual Control"*) show_manual_menu ;;
        *"Monitoring"*) show_monitoring ;;
        *"Smart Daemon"*) show_daemon_menu ;;
        *"PWM1"*) show_pwm_menu 1 "CPU Fan" ;;
        *"PWM3"*) show_pwm_menu 3 "Chassis Fan 1" ;;
        *"PWM6"*) show_pwm_menu 6 "Chassis Fan 2" ;;
        *"Exit"*|"") exit 0 ;;
    esac
}

# Quick presets menu
show_presets_menu() {
    local menu_options=""
    menu_options+="🔇  Silent Mode (30%)\n"
    menu_options+="🔉  Quiet Mode (50%)\n"
    menu_options+="🔊  Performance Mode (80%)\n"
    menu_options+="🚀  Max Speed (100%)\n"
    menu_options+="🔄  Auto Mode (BIOS)\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="⬅️  Back to Main Menu"
    
    local choice
    choice=$(echo -e "$menu_options" | rofi -dmenu -i -p "Quick Presets" \
        -theme-str 'window {width: 400px;} listview {lines: 8;}')
    
    case "$choice" in
        *"Silent"*) 
            set_fan_speed 1 30; set_fan_speed 3 30; set_fan_speed 6 30
            show_main_menu ;;
        *"Quiet"*)
            set_fan_speed 1 50; set_fan_speed 3 50; set_fan_speed 6 50
            show_main_menu ;;
        *"Performance"*)
            set_fan_speed 1 80; set_fan_speed 3 80; set_fan_speed 6 80
            show_main_menu ;;
        *"Max Speed"*)
            set_fan_speed 1 100; set_fan_speed 3 100; set_fan_speed 6 100
            show_main_menu ;;
        *"Auto Mode"*)
            set_fan_auto 1; set_fan_auto 3; set_fan_auto 6
            show_main_menu ;;
        *"Back"*|"") show_main_menu ;;
    esac
}

# PWM control menu
show_pwm_menu() {
    local pwm_channel=$1
    local fan_name=$2
    local current_status=$(get_fan_status $pwm_channel)
    
    local menu_options=""
    menu_options+="Current: ${current_status}\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="🔇  20% (Silent)\n"
    menu_options+="🔉  40% (Quiet)\n"
    menu_options+="🔊  60% (Balanced)\n"
    menu_options+="⚡  80% (Performance)\n"
    menu_options+="🚀  100% (Maximum)\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="🔄  Auto Mode\n"
    menu_options+="⬅️  Back to Main Menu"
    
    local choice
    choice=$(echo -e "$menu_options" | rofi -dmenu -i -p "Control ${fan_name}" \
        -theme-str 'window {width: 350px;} listview {lines: 10;}')
    
    case "$choice" in
        *"20%"*) set_fan_speed $pwm_channel 20; show_pwm_menu $pwm_channel "$fan_name" ;;
        *"40%"*) set_fan_speed $pwm_channel 40; show_pwm_menu $pwm_channel "$fan_name" ;;
        *"60%"*) set_fan_speed $pwm_channel 60; show_pwm_menu $pwm_channel "$fan_name" ;;
        *"80%"*) set_fan_speed $pwm_channel 80; show_pwm_menu $pwm_channel "$fan_name" ;;
        *"100%"*) set_fan_speed $pwm_channel 100; show_pwm_menu $pwm_channel "$fan_name" ;;
        *"Auto"*) set_fan_auto $pwm_channel; show_pwm_menu $pwm_channel "$fan_name" ;;
        *"Back"*|"") show_main_menu ;;
    esac
}

# Manual control menu
show_manual_menu() {
    local menu_options=""
    for i in {1..6}; do
        menu_options+="🔧  PWM${i}: $(get_fan_status $i)\n"
    done
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="⬅️  Back to Main Menu"
    
    local choice
    choice=$(echo -e "$menu_options" | rofi -dmenu -i -p "Manual Control" \
        -theme-str 'window {width: 400px;} listview {lines: 8;}')
    
    if [[ "$choice" =~ PWM([1-6]) ]]; then
        local ch="${BASH_REMATCH[1]}"
        show_pwm_menu "$ch" "PWM${ch}"
    else
        show_main_menu
    fi
}

# Monitoring display
show_monitoring() {
    local cpu_temp=$(get_cpu_temp)
    local monitor_info=""
    monitor_info+="🌡️  CPU Temperature: ${cpu_temp:-N/A}\n"
    monitor_info+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    for i in {1..7}; do
        local rpm=$(get_fan_rpm $i)
        if [ "$rpm" != "N/A" ]; then
            monitor_info+="💨  Fan${i}: ${rpm}\n"
        fi
    done
    monitor_info+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    monitor_info+="🔄  Refresh\n"
    monitor_info+="⬅️  Back to Main Menu"
    
    local choice
    choice=$(echo -e "$monitor_info" | rofi -dmenu -i -p "Monitoring" \
        -theme-str 'window {width: 400px;} listview {lines: 11;}')
    
    case "$choice" in
        *"Refresh"*) show_monitoring ;;
        *) show_main_menu ;;
    esac
}

# Smart daemon menu
show_daemon_menu() {
    local status="Stopped"
    if systemctl is-active --quiet smart-fan-daemon; then
        status="Running"
    fi
    
    local menu_options=""
    menu_options+="Status: ${status}\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="⚙️  Configure\n"
    menu_options+="▶️  Start\n"
    menu_options+="⏹️  Stop\n"
    menu_options+="🔄  Restart\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="⬅️  Back to Main Menu"
    
    local choice
    choice=$(echo -e "$menu_options" | rofi -dmenu -i -p "Daemon Management" \
        -theme-str 'window {width: 350px;} listview {lines: 7;}')
    
    case "$choice" in
        *"Configure"*) 
            rofi -e "Run '${DAEMON_SCRIPT} config' in a terminal"
            show_daemon_menu ;;
        *"Start"*)
            pkexec systemctl start smart-fan-daemon
            show_daemon_menu ;;
        *"Stop"*)
            pkexec systemctl stop smart-fan-daemon
            show_daemon_menu ;;
        *"Restart"*)
            pkexec systemctl restart smart-fan-daemon
            show_daemon_menu ;;
        *) show_main_menu ;;
    esac
}

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    exit 1
fi

# Main execution
show_main_menu

