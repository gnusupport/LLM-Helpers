#!/bin/bash
cd /home/data1/protected/Programming/git/Kokoros

# Function to check if koko openai is already running
is_koko_running() {
    # Use pgrep to check if a process matching "koko openai" is running
    if pgrep -f "koko openai" > /dev/null; then
        return 0 # True, process is running
    else
        return 1 # False, process is not running
    fi
}

# Function to calculate the port number for "AUDIO"
get_audio_port() {
    local word="AUDIO"
    local sum=0

    # Calculate the sum of ASCII values of the letters in "AUDIO"
    for (( i=0; i<${#word}; i++ )); do
        sum=$((sum + $(printf "%d" "'${word:$i:1}")))
    done

    # Scale the sum to get the desired port number 3700
    port=$((sum * 10))

    # Return the port number
    echo "$port"
}

# Determine the IP address
ip_address=$(rcd-get-ethernet-interface.sh)

# Get the port number for "AUDIO"
port=$(get_audio_port)

# Check if koko openai is running
if is_koko_running; then
    echo "Koko OpenAI is already running."
else
    echo "Starting Koko OpenAI on IP: $ip_address, Port: $port"
    koko openai --ip "$ip_address" --port "$port"
fi
