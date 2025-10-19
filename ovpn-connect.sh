#!/bin/bash
# Must create a folder inside KDEWallet and entry with the password!

# Check if running in terminal, if not - open in Konsole
if [ ! -t 1 ]; then
    konsole -e "$0" "$@"
    exit 0
fi

# VPN credentials and file
VPN_USER="username"
VPN_CONFIG="ovpn_file_location"

# Check if config file exists
if [ ! -f "$VPN_CONFIG" ]; then
    echo "Error: VPN config file not found at $VPN_CONFIG"
    echo "Press any key to exit..."
    read -n 1
    exit 1
fi

# Check if wallet is accessible
if ! kwallet-query kdewallet -f VPN -r ovpn-uniza >/dev/null 2>&1; then
    echo "Error: Cannot access password from KDE Wallet. Is it unlocked?"
    echo "Press any key to close..."
    read -n 1
    exit 1
fi
# Find actual wallet name, kdewallet may be right. Change to your folder and entry.
VPN_PASSWORD="$(kwallet-query kdewallet -f folder -r entry_name)"

# Connect to VPN
echo "Connecting to UNIZA VPN..."
echo "User: $VPN_USER"
echo "Config: $VPN_CONFIG"
echo "---"

# Pass credentials via stdin
echo -e "$VPN_USER\n$VPN_PASSWORD" | sudo openvpn --config "$VPN_CONFIG" --auth-user-pass /dev/stdin

echo ""
echo "VPN connection terminated. Press any key to close..."
read -n 1
