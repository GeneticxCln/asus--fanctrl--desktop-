#!/bin/bash

echo "Testing fan control GUI..."

# Test 1: Check if rofi is working
echo "Test 1: Testing Rofi..."
if rofi -e "Rofi test successful!" -theme-str 'window {width: 300px;}' 2>/dev/null; then
    echo "✓ Rofi is working"
else
    echo "✗ Rofi test failed"
fi

# Test 2: Check script permissions
echo "Test 2: Testing script execution..."
if /home/sasha/fanctrl/rofi_fan_control.sh --help 2>/dev/null; then
    echo "✓ Script can be executed"
else
    echo "✗ Script execution failed"
fi

# Test 3: Check hardware access
echo "Test 3: Testing hardware access..."
PWM_PATH=$(find /sys/devices/platform/nct6775.656/hwmon/ -name "pwm1" 2>/dev/null | head -1 | sed 's/\/pwm1$//')
if [ -r "${PWM_PATH}/pwm3" ]; then
    echo "✓ Hardware path accessible: $PWM_PATH"
else
    echo "✗ Hardware path not accessible: $PWM_PATH"
fi

# Test 4: Test sudo permissions
echo "Test 4: Testing sudo permissions..."
if echo 50 | sudo tee "${PWM_PATH}/pwm3" > /dev/null 2>&1; then
    echo "✓ Sudo permissions working"
else
    echo "✗ Sudo permissions failed"
fi

echo "Testing complete!"
