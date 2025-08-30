#!/bin/bash

# Rofi Fan Control GUI for ASUS ROG STRIX B550-F
# A clean, simple interface for controlling fans

# Auto-detect the correct hwmon path for NCT6775 chip
PWM_BASE_PATH=$(find /sys/devices/platform/nct6775.656/hwmon/ -name "pwm1" 2>/dev/null | head -1 | sed 's/\/pwm1$//' || echo "/sys/devices/platform/nct6775.656/hwmon/hwmon5")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get current fan status
get_fan_status() {
    local pwm_channel=$1
    local pwm_val=$(cat "${PWM_BASE_PATH}/pwm${pwm_channel}" 2>/dev/null || echo "0")
    local enable_val=$(cat "${PWM_BASE_PATH}/pwm${pwm_channel}_enable" 2>/dev/null || echo "0")
    local percentage=$((pwm_val * 100 / 255))
    
    case $enable_val in
        0) echo "OFF" ;;
        1) echo "${percentage}% (Manual)" ;;
        5) echo "Auto" ;;
        *) echo "Unknown" ;;
    esac
}

# Get fan RPM
get_fan_rpm() {
    local fan_num=$1
    local rpm=$(cat "${PWM_BASE_PATH}/fan${fan_num}_input" 2>/dev/null || echo "0")
    if [ "$rpm" -eq 0 ]; then
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
    
    # Call the fan control script directly
    "${SCRIPT_DIR}/fan_control.sh" set "${pwm_channel}" "${percentage}" 2>/dev/null
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Set fan to auto mode
set_fan_auto() {
    local pwm_channel=$1
    echo 5 | sudo tee "${PWM_BASE_PATH}/pwm${pwm_channel}_enable" > /dev/null 2>&1
}

# Main menu
show_main_menu() {
    local cpu_temp=$(get_cpu_temp)
    local fan3_rpm=$(get_fan_rpm 3)
    local fan6_rpm=$(get_fan_rpm 6)
    
    local pwm1_status=$(get_fan_status 1)
    local pwm3_status=$(get_fan_status 3)
    local pwm6_status=$(get_fan_status 6)
    
    local menu_options=""
    menu_options+="🌡️  CPU Temp: ${cpu_temp}\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="🔧  PWM1 (CPU Fan): ${pwm1_status}\n"
    menu_options+="🔧  PWM3 (Fan3): ${pwm3_status} - ${fan3_rpm}\n"
    menu_options+="🔧  PWM6 (Fan6): ${pwm6_status} - ${fan6_rpm}\n"
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
        *"PWM3"*) show_pwm_menu 3 "Fan3" ;;
        *"PWM6"*) show_pwm_menu 6 "Fan6" ;;
        *"Exit"*|"") exit 0 ;;
    esac
}

# Quick presets menu
show_presets_menu() {
    local menu_options=""
    menu_options+="🔇  Silent Mode (All fans 30%)\n"
    menu_options+="🔉  Quiet Mode (All fans 50%)\n"
    menu_options+="🔊  Performance Mode (All fans 80%)\n"
    menu_options+="🚀  Max Speed (All fans 100%)\n"
    menu_options+="🔄  Auto Mode (Return to BIOS control)\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="⬅️  Back to Main Menu"
    
    local choice
    choice=$(echo -e "$menu_options" | rofi -dmenu -i -p "Quick Presets" \
        -theme-str 'window {width: 400px;} listview {lines: 8;}')
    
    case "$choice" in
        *"Silent"*) 
            set_fan_speed 1 30; set_fan_speed 3 30; set_fan_speed 6 30
            rofi -e "Silent mode activated (30%)" -theme-str 'window {width: 300px;}'
            show_main_menu ;;
        *"Quiet"*)
            set_fan_speed 1 50; set_fan_speed 3 50; set_fan_speed 6 50
            rofi -e "Quiet mode activated (50%)" -theme-str 'window {width: 300px;}'
            show_main_menu ;;
        *"Performance"*)
            set_fan_speed 1 80; set_fan_speed 3 80; set_fan_speed 6 80
            rofi -e "Performance mode activated (80%)" -theme-str 'window {width: 300px;}'
            show_main_menu ;;
        *"Max Speed"*)
            set_fan_speed 1 100; set_fan_speed 3 100; set_fan_speed 6 100
            rofi -e "Maximum speed activated (100%)" -theme-str 'window {width: 300px;}'
            show_main_menu ;;
        *"Auto Mode"*)
            set_fan_auto 1; set_fan_auto 3; set_fan_auto 6
            rofi -e "All fans returned to automatic control" -theme-str 'window {width: 350px;}'
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
    choice=$(echo -e "$menu_options" | rofi -dmenu -i -p "Control ${fan_name} (PWM${pwm_channel})" \
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
    menu_options+="🔧  PWM1 (CPU Fan): $(get_fan_status 1)\n"
    menu_options+="🔧  PWM2 (System): $(get_fan_status 2)\n"
    menu_options+="🔧  PWM3 (Fan3): $(get_fan_status 3) - $(get_fan_rpm 3)\n"
    menu_options+="🔧  PWM4 (Fan4): $(get_fan_status 4)\n"
    menu_options+="🔧  PWM5 (Fan5): $(get_fan_status 5)\n"
    menu_options+="🔧  PWM6 (Fan6): $(get_fan_status 6) - $(get_fan_rpm 6)\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="⬅️  Back to Main Menu"
    
    local choice
    choice=$(echo -e "$menu_options" | rofi -dmenu -i -p "Manual Fan Control" \
        -theme-str 'window {width: 400px;} listview {lines: 8;}')
    
    case "$choice" in
        *"PWM1"*) show_pwm_menu 1 "CPU Fan" ;;
        *"PWM2"*) show_pwm_menu 2 "System Fan" ;;
        *"PWM3"*) show_pwm_menu 3 "Fan3" ;;
        *"PWM4"*) show_pwm_menu 4 "Fan4" ;;
        *"PWM5"*) show_pwm_menu 5 "Fan5" ;;
        *"PWM6"*) show_pwm_menu 6 "Fan6" ;;
        *"Back"*|"") show_main_menu ;;
    esac
}

# Monitoring display
show_monitoring() {
    local cpu_temp=$(get_cpu_temp)
    local sys_temp=$(sensors | grep 'SYSTIN:' | awk '{print $2}' | sed 's/+//g')
    
    local monitor_info=""
    monitor_info+="🌡️  CPU Temperature: ${cpu_temp}\n"
    monitor_info+="🌡️  System Temperature: ${sys_temp}\n"
    monitor_info+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    monitor_info+="💨  Fan3 RPM: $(get_fan_rpm 3)\n"
    monitor_info+="💨  Fan6 RPM: $(get_fan_rpm 6)\n"
    monitor_info+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    monitor_info+="🔧  PWM1: $(get_fan_status 1)\n"
    monitor_info+="🔧  PWM3: $(get_fan_status 3)\n"
    monitor_info+="🔧  PWM6: $(get_fan_status 6)\n"
    monitor_info+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    monitor_info+="🔄  Refresh\n"
    monitor_info+="⬅️  Back to Main Menu"
    
    local choice
    choice=$(echo -e "$monitor_info" | rofi -dmenu -i -p "System Monitoring" \
        -theme-str 'window {width: 400px;} listview {lines: 11;}')
    
    case "$choice" in
        *"Refresh"*) show_monitoring ;;
        *"Back"*|"") show_main_menu ;;
    esac
}

# Smart daemon menu
show_daemon_menu() {
    local menu_options=""
    menu_options+="⚙️  Configure Smart Daemon\n"
    menu_options+="🧪  Test Configuration\n"
    menu_options+="▶️  Start Smart Daemon\n"
    menu_options+="⏹️  Stop Smart Daemon\n"
    menu_options+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    menu_options+="⬅️  Back to Main Menu"
    
    local choice
    choice=$(echo -e "$menu_options" | rofi -dmenu -i -p "Smart Fan Daemon" \
        -theme-str 'window {width: 350px;} listview {lines: 7;}')
    
    case "$choice" in
        *"Configure"*) 
            rofi -e "Opening terminal for configuration..." -theme-str 'window {width: 300px;}'
            x-terminal-emulator -e "${SCRIPT_DIR}/smart_fan_daemon.sh config" &
            ;;
        *"Test"*)
            x-terminal-emulator -e "${SCRIPT_DIR}/smart_fan_daemon.sh test" &
            ;;
        *"Start"*)
            rofi -e "Starting smart daemon in terminal..." -theme-str 'window {width: 300px;}'
            x-terminal-emulator -e "${SCRIPT_DIR}/smart_fan_daemon.sh run" &
            ;;
        *"Stop"*)
            "${SCRIPT_DIR}/smart_fan_daemon.sh" stop
            rofi -e "Smart daemon stopped" -theme-str 'window {width: 250px;}'
            show_daemon_menu
            ;;
        *"Back"*|"") show_main_menu ;;
    esac
}

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    echo "Error: rofi is not installed. Please install it first:"
    echo "sudo pacman -S rofi"
    exit 1
fi

# Main execution
show_main_menu
