#!/bin/bash

# Transcribes audio file to text

# Check if an audio file is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <audio_file>"
  exit 1
fi

# Path to the virtual environment
VENV_PATH="/home/data1/protected/venv"

# Path to the Python script
PYTHON_SCRIPT="/mnt/data/LLM/nvidia/canary-1b.py"

# Audio file provided as an argument
AUDIO_FILE="$1"

# Activate the virtual environment
source "$VENV_PATH/bin/activate"

# Check if the virtual environment was activated successfully
if [ $? -ne 0 ]; then
  echo "Error: Failed to activate virtual environment at $VENV_PATH."
  exit 1
fi

# Run the Python script with the audio file as an argument and capture the output
output=$(python "$PYTHON_SCRIPT" "$AUDIO_FILE")

# Check if the Python script ran successfully
if [ $? -ne 0 ]; then
  echo "Error: Failed to run the Python script."
  exit 1
fi

# Print the output to stdout
echo "$output"

# Copy the output to the clipboard
if command -v xclip &> /dev/null; then
  # Linux: Use xclip
  echo "$output" | xclip -selection clipboard
elif command -v pbcopy &> /dev/null; then
  # macOS: Use pbcopy
  echo "$output" | pbcopy
else
  echo "Clipboard utility not found. Install xclip (Linux) or pbcopy (macOS)."
fi

# Deactivate the virtual environment (optional)
deactivate
