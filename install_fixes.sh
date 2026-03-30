#!/bin/bash
# Install fixed polkit rules and updated detection script
set -e

echo "=== Installing ASUS Fan Control Fixes ==="

# 1. Install polkit rule
echo "[1/3] Installing polkit rule..."
sudo cp /home/quinton/asus--fanctrl--desktop-/noctalia-plugin/50-asus-fanctrl.rules /usr/share/polkit-1/rules.d/50-asus-fanctrl.rules
sudo chmod 644 /usr/share/polkit-1/rules.d/50-asus-fanctrl.rules
echo "  ✓ Polkit rule installed"

# 2. Install updated detection script
echo "[2/3] Installing updated detection script..."
sudo cp /home/quinton/asus--fanctrl--desktop-/noctalia-plugin/asus-fanctrl-detect /usr/local/bin/asus-fanctrl-detect
sudo chmod 755 /usr/local/bin/asus-fanctrl-detect
echo "  ✓ Detection script installed"

# 3. Kill zombie polkit-agent-helper processes
echo "[3/3] Cleaning up zombie polkit helpers..."
zombie_count=$(pgrep -f polkit-agent-helper | wc -l)
if [ "$zombie_count" -gt 0 ]; then
    sudo kill -9 $(pgrep -f polkit-agent-helper) 2>/dev/null || true
    sleep 1
    remaining=$(pgrep -f polkit-agent-helper 2>/dev/null | wc -l)
    echo "  ✓ Killed $zombie_count helpers ($remaining remaining - systemd orphans will clear on reboot)"
else
    echo "  ✓ No zombie helpers found"
fi

# 4. Restart polkit daemon to pick up new rules
echo "[4/4] Restarting polkit daemon..."
sudo systemctl restart polkit
echo "  ✓ Polkit restarted"

echo ""
echo "=== Verification ==="
echo "Testing passwordless pkexec..."
pkexec /usr/local/bin/asus-fanctrl-detect status 2>&1 | head -20
echo ""
echo "=== Done! Restart Noctalia Shell to apply QML changes ==="
