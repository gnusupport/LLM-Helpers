#!/bin/bash

# Step 1: Invoke rcd-llm-speech-single-input.sh and capture its output
german=$(rcd-llm-speech-single-input.sh --no-typing --language German)

# Check if the output is empty or the script failed
if [ -z "$german" ]; then
    echo "Error: No output received from rcd-llm-speech-single-input.sh" >&2
    exit 1
fi

# Step 4: Use xdotool to type the translated German text
xdotool type --delay 10 "$german"

echo "Translation completed and typed using xdotool." >&2
