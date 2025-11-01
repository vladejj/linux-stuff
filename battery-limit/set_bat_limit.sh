#!/bin/bash
# Battery Charge Threshold
# 
# Usage: 
#   ./set_bat_limit.sh [threshold]  - Set specific threshold (50-100)
#   ./set_bat_limit.sh              - Cycle through 60 → 80 → 100 → 60
#
# Setup Required:
# 1. Add sudo permission (run: sudo visudo) and add at the end of file:
#    YOUR_USERNAME ALL=NOPASSWD: /usr/bin/tee /sys/class/power_supply/BAT0/charge_control_end_threshold
#
# [Optional]
# 2. Create systemd service to restore threshold on boot:
#    sudo nano /etc/systemd/system/battery-limit.service
#    [Paste contents of service file "battery-limit.service" from repo]
#    sudo systemctl daemon-reload
#    sudo systemctl enable battery-limit.service

set -euo pipefail  # Exit on errors and undefined variables

MY_THRESHOLD_FILE="$HOME/.config/battery-limit/threshold"
KERNEL_THRESHOLD_FILE="/sys/class/power_supply/BAT0/charge_control_end_threshold"

# Create directory if it doesn't exist
mkdir -p "$(dirname "$MY_THRESHOLD_FILE")" 2>/dev/null || true

# Check if kernel threshold file exists
if [ ! -f "$KERNEL_THRESHOLD_FILE" ]; then
    echo "Error: Battery threshold file not found"
    notify-send "Error" "Battery threshold control not available" -i dialog-error
    exit 1
fi

# If argument provided, use it; otherwise cycle through values
if [ -n "${1:-}" ]; then
    # Validate input is a number
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: Threshold must be a number"
        notify-send "Error" "Invalid threshold value: $1" -i dialog-error
        exit 1
    fi
    # Validate range
    if [ "$1" -lt 1 ] || [ "$1" -gt 100 ]; then
        echo "Error: Threshold must be between 1 and 100"
        notify-send "Error" "Threshold must be between 1 and 100" -i dialog-error
        exit 1
    fi
    NEXT="$1"
else
    # Original cycling behavior when no argument provided
    CURRENT=$(cat "$KERNEL_THRESHOLD_FILE" 2>/dev/null || echo "60")
    case "$CURRENT" in
        60)
            NEXT=80
            ;;
        80)
            NEXT=100
            ;;
        100)
            NEXT=60
            ;;
        *)
            # If current value is something else, start with 60
            NEXT=60
            ;;
    esac
fi

# Save new threshold to local file (with error handling)
if ! echo "$NEXT" > "$MY_THRESHOLD_FILE" 2>/dev/null; then
    echo "Warning: Could not save threshold to $MY_THRESHOLD_FILE"
fi

# Set the new threshold
if echo "$NEXT" | sudo tee "$KERNEL_THRESHOLD_FILE" > /dev/null; then
    # Verify it was actually set
    VERIFY=$(cat "$KERNEL_THRESHOLD_FILE" 2>/dev/null)
    if [ "$VERIFY" = "$NEXT" ]; then
        # Success - show notification with appropriate icon
        if [ "$NEXT" -le 30 ]; then
            ICON="battery-caution"
        elif [ "$NEXT" -le 60 ]; then
            ICON="battery-low"
        elif [ "$NEXT" -le 80 ]; then
            ICON="battery-good"
        else
            ICON="battery-full"
        fi
        notify-send -a "Battery Manager" "Battery Threshold" "Charge limit set to ${NEXT}%" -i "$ICON" -t 3000
    else
        notify-send -a "Battery Manager" "Error" "Threshold set but verification failed (got: $VERIFY)" -i dialog-error -t 10000
        exit 1
    fi
else
    # Error - likely sudo issue
    notify-send -a "Battery Manager" "Error" "Failed to set battery threshold. Check sudo permissions." -i dialog-error -t 10000
    exit 1
fi
