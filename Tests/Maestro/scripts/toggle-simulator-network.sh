#!/usr/bin/env bash
# Toggle the iOS simulator's network to verify Mosh UDP roaming survives.
# Maestro runs this between assertVisible steps.

set -euo pipefail
DEVICE="${MAESTRO_DEVICE_UDID:-booted}"

# Drop network for 4 seconds then restore. The Mosh client should re-roam.
xcrun simctl status_bar "$DEVICE" override --dataNetwork hide || true
sleep 4
xcrun simctl status_bar "$DEVICE" clear || true
