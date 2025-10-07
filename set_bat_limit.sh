#!/bin/bash
# Sets battery charge threshold to specified value or cycles between 60 > 80 > 100 > 60

# REQUIRES: sudo privileges to write to /sys/class/power_supply/BAT0/charge_control_end_threshold
# Setup: Add to /etc/sudoers with visudo:
# yourusername ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/class/power_supply/BAT0/charge_control_end_threshold
# Create service that reads the file and sets remembered value
# Must have ownership and only read perms for .bat-limit in /etc

MY_THRESHOLD_FILE="/var/lib/battery-limit/threshold"
KERNEL_THRESHOLD_FILE="/sys/class/power_supply/BAT0/charge_control_end_threshold"
NOTIF_ID=69

# Check if threshold file exists
if [ ! -f "$KERNEL_THRESHOLD_FILE" ]; then
    echo "Error: Battery threshold file not found"
    notify-send "Error" "Battery threshold control not available" -i dialog-error
    exit 1
fi

# If argument provided, use it; otherwise cycle through values
if [ -n "$1" ]; then
    # Validate input is a number
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: Threshold must be a number"
        notify-send "Error" "Invalid threshold value: $1" -i dialog-error
        exit 1
    fi

    # Validate range (typically 1-100, adjust if needed)
    if [ "$1" -lt 1 ] || [ "$1" -gt 100 ]; then
        echo "Error: Threshold must be between 1 and 100"
        notify-send "Error" "Threshold must be between 1 and 100" -i dialog-error
        exit 1
    fi

    NEXT=$1
else
    # Original cycling behavior when no argument provided
    CURRENT=$(cat "$KERNEL_THRESHOLD_FILE" 2>/dev/null)

    case $CURRENT in
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

# Save new threshold to local file
echo $NEXT > "$MY_THRESHOLD_FILE"

# Set the new threshold
echo $NEXT | sudo tee "$KERNEL_THRESHOLD_FILE" > /dev/null

if [ $? -eq 0 ]; then
    # Success - show notification with appropriate icon
    if [ $NEXT -le 30 ]; then
        ICON="battery-caution"
    elif [ $NEXT -le 60 ]; then
        ICON="battery-low"
    elif [ $NEXT -le 80 ]; then
        ICON="battery-good"
    else
        ICON="battery-full"
    fi

    notify-send -a "Battery Manager" "Battery Threshold" "Charge limit set to ${NEXT}%" -i $ICON -t 3000
else
    # Error - likely sudo issue
    notify-send -a "Battery Manager" "Error" "Failed to set battery threshold. Check sudo permissions." -i dialog-error -t 10000
fi
