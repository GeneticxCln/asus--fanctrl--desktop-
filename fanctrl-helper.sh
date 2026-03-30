#!/bin/bash
# Fan control helper script - runs via sudo
# Usage: fanctrl-helper set <pwm_channel> <value>
#        fanctrl-helper enable <pwm_channel> <mode>

PWM_BASE=$(/usr/local/bin/asus-fanctrl-detect detect 2>/dev/null)
if [ -z "$PWM_BASE" ]; then
    echo "ERROR: Hardware not detected" >&2
    exit 1
fi

case "$1" in
    set)
        echo "$3" > "$PWM_BASE/pwm$2" 2>/dev/null
        exit $?
        ;;
    enable)
        echo "$3" > "$PWM_BASE/pwm${2}_enable" 2>/dev/null
        exit $?
        ;;
    *)
        echo "Usage: $0 {set|enable} <channel> <value>"
        exit 1
        ;;
esac
