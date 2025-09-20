#!/bin/bash
# Cycles battery charge threshold between 60 > 80 > 100 > 60

# REQUIRES:
#     sudo privileges to write to /sys/class/power_supply/BAT0/charge_control_end_threshold
# SETUP:
#     Add to /etc/sudoers with visudo:
#         yourusername ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/class/power_supply/BAT0/charge_control_end_threshold
#     Create service that reads the file and sets remembered value
#     Set 644 perms for /var/lib/battery-limit/threshold

MY_THRESHOLD_FILE="/var/lib/battery-limit/threshold"
KERNEL_THRESHOLD_FILE="/sys/class/power_supply/BAT0/charge_control_end_threshold"
NOTIF_ID=69

# Get current threshold
if [ -f "$KERNEL_THRESHOLD_FILE" ]; then
    CURRENT=$(cat "$KERNEL_THRESHOLD_FILE" 2>/dev/null)
else
    echo "Error: Battery threshold file not found"
    notify-send "Error" "Battery threshold control not available" -i dialog-error
    exit 1
fi

# Determine next threshold
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

# Save new threshold to local file
echo $NEXT > "$MY_THRESHOLD_FILE"
# Set the new threshold
echo $NEXT | sudo tee "$KERNEL_THRESHOLD_FILE" > /dev/null

if [ $? -eq 0 ]; then
    # Success - show notification with appropriate icon
    case $NEXT in
        60)
            ICON="battery-low"
            ;;
        80)
            ICON="battery-good"
            ;;
        100)
            ICON="battery-full"
            ;;
    esac

    notify-send -a "Battery Manager" "Battery Threshold" "Charge limit set to ${NEXT}%" -i $ICON -t 3000


else
    # Error - likely sudo issue
    notify-send -a "Battery Manager" "Error" "Failed to set battery threshold. Check sudo permissions." -i dialog-error -t 10000
fi
