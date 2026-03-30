#!/bin/bash

# Shared Library for ASUS Fan Control
# Provides dynamic hardware detection and safe configuration parsing

# --- Hardware Detection ---

find_hwmon_path() {
    local chips=("nct6798" "nct6775")
    local found_path=""

    for chip in "${chips[@]}"; do
        # Search in /sys/class/hwmon
        for path in /sys/class/hwmon/hwmon*; do
            if [ -f "$path/name" ] && grep -q "$chip" "$path/name" 2>/dev/null; then
                found_path="$path"
                break 2
            fi
        done
        
        # Search in /sys/devices/platform/nct6775.*
        local platform_path=$(find /sys/devices/platform/nct6775.* -name "hwmon" 2>/dev/null | head -1)
        if [ -n "$platform_path" ]; then
            local hwmon_sub=$(find "$platform_path" -maxdepth 1 -name "hwmon*" 2>/dev/null | head -1)
            if [ -n "$hwmon_sub" ] && [ -f "$hwmon_sub/name" ] && grep -q "$chip" "$hwmon_sub/name" 2>/dev/null; then
                found_path="$hwmon_sub"
                break 2
            fi
        fi
    done

    if [ -z "$found_path" ]; then
        return 1
    fi
    echo "$found_path"
}

# --- Configuration Parsing ---

# Safe config parser that doesn't use 'source'
# Usage: get_config_val "key" "default_val" "config_file"
get_config_val() {
    local key="$1"
    local default="$2"
    local file="$3"
    
    if [ ! -f "$file" ]; then
        echo "$default"
        return
    fi
    
    local val=$(grep "^${key}=" "$file" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    if [ -z "$val" ]; then
        echo "$default"
    else
        echo "$val"
    fi
}

# --- Logging ---

log_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
log_success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
log_warn() { echo -e "\e[33m[WARNING]\e[0m $1"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $1"; }

# --- Initialization ---

# Export these so child scripts can use them easily
export -f find_hwmon_path
export -f get_config_val
export -f log_info
export -f log_success
export -f log_warn
export -f log_error
