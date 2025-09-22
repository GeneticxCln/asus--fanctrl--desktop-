#!/usr/bin/env bash
set -euo pipefail

# Fan Control Health Check
# Verifies that passwordless sudo writes to PWM sysfs are working and that
# fan_control.sh can set and reset a PWM channel.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
FANCTL="${REPO_DIR}/fan_control.sh"

pass() { echo "[PASS] $1"; }
fail() { echo "[FAIL] $1"; exit 1; }
info() { echo "[INFO] $1"; }

# 1) Locate PWM base path
info "Locating PWM hwmon path (nct67xx preferred)..."
PWM_BASE_PATH=$(find /sys/class/hwmon/ -maxdepth 1 -name "hwmon*" -exec sh -c 'p="$1"; if [ -f "$p/name" ] && grep -qi "nct67" "$p/name" 2>/dev/null; then echo "$p"; fi' _ {} \; | head -1 || true)

if [ -z "${PWM_BASE_PATH}" ]; then
  # Fallback: first hwmon with any pwm*_enable
  for d in /sys/class/hwmon/hwmon*; do
    [ -d "$d" ] || continue
    if compgen -G "$d/pwm*_enable" > /dev/null; then
      PWM_BASE_PATH="$d"
      break
    fi
  done
fi

[ -n "${PWM_BASE_PATH}" ] || fail "Could not locate a hwmon directory with PWM controls."
pass "Found PWM path: ${PWM_BASE_PATH}"

# 2) Pick a PWM channel to test
PWM_ENABLE_FILE="$(ls -1 ${PWM_BASE_PATH}/pwm*_enable 2>/dev/null | head -n1 || true)"
[ -n "${PWM_ENABLE_FILE}" ] || fail "No pwm*_enable file found under ${PWM_BASE_PATH}"

BASENAME="$(basename "${PWM_ENABLE_FILE}")"      # e.g., pwm1_enable
CHAN="${BASENAME#pwm}"                           # 1_enable
CHAN="${CHAN%_enable}"                           # 1

info "Testing channel PWM${CHAN} using ${PWM_ENABLE_FILE}"

# 3) Verify NOPASSWD sudo works via /usr/bin/tee
info "Checking NOPASSWD sudo access (manual -> auto toggle)..."
if echo 1 | sudo -n /usr/bin/tee "${PWM_ENABLE_FILE}" > /dev/null 2>&1; then
  pass "Manual mode set without password"
else
  fail "Failed to set manual mode via sudo -n tee (sudoers rule likely missing)"
fi

# Always try to return to auto at the end
cleanup() {
  echo 5 | sudo -n /usr/bin/tee "${PWM_ENABLE_FILE}" > /dev/null 2>&1 || true
}
trap cleanup EXIT

# 4) Try driving the channel via the core script (should also be passwordless)
if [ -x "${FANCTL}" ]; then
  info "Driving PWM${CHAN} to 40% via fan_control.sh"
  if timeout 5s "${FANCTL}" set "${CHAN}" 40 > /dev/null 2>&1; then
    pass "fan_control.sh set ${CHAN} 40"
  else
    fail "fan_control.sh set ${CHAN} 40 failed (sudoers rule may be missing or script error)"
  fi

  info "Returning PWM${CHAN} to auto via fan_control.sh"
  if timeout 5s "${FANCTL}" auto "${CHAN}" > /dev/null 2>&1; then
    pass "fan_control.sh auto ${CHAN}"
  else
    fail "fan_control.sh auto ${CHAN} failed"
  fi
else
  info "fan_control.sh not found or not executable at ${FANCTL}; skipping script-driven test"
fi

pass "Health check completed successfully."
