#!/bin/bash

# Function to get the first active Ethernet interface with an IPv4 address
get_ethernet_interface() {
    # List all interfaces, filter for those that are UP and have an IPv4 address
    ip -o link show | awk -F': ' '{print $2}' | while read -r interface; do
        # Skip the loopback interface
        if [[ "$interface" == "lo" ]]; then
            continue
        fi

        # Check if the interface is UP and has an IPv4 address
        if ip -4 addr show "$interface" 2>/dev/null | grep -q 'inet'; then
            echo "$interface"
            return
        fi
    done
}

# Function to get the IP address of a given interface
get_interface_ip() {
    local interface=$1
    ip -4 addr show "$interface" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
}

# Main script logic
INTERFACE=$(get_ethernet_interface)

if [ -n "$INTERFACE" ]; then
    # Ethernet interface with an IP address found
    IP_ADDRESS=$(get_interface_ip "$INTERFACE")
else
    # No active Ethernet interface found, default to localhost
    IP_ADDRESS="127.0.0.1"
fi

# Check if the script is running interactively
if [ -t 0 ]; then
    # Interactive mode: output with a newline
    echo "$IP_ADDRESS"
else
    # Non-interactive mode: output without a newline
    echo -n "$IP_ADDRESS"
fi
