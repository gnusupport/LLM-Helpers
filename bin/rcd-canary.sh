#!/bin/bash

# Transcribes audio file to text

# Check if an audio file is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <audio_file> [target_language]"
  echo "Supported target languages: Spanish, French, German (default: English)"
  exit 1
fi

# Path to the virtual environment
VENV_PATH="/home/data1/protected/venv"

# Path to the Python script
PYTHON_SCRIPT="/mnt/data/LLM/nvidia/canary-1b.py"

# Audio file provided as an argument
AUDIO_FILE="$1"

# Target language (optional, default: English)
TARGET_LANGUAGE="${2:-English}"

# Validate the target language
if [[ "$TARGET_LANGUAGE" != "English" && "$TARGET_LANGUAGE" != "Spanish" && "$TARGET_LANGUAGE" != "French" && "$TARGET_LANGUAGE" != "German" ]]; then
  echo "Error: Unsupported target language '$TARGET_LANGUAGE'. Supported languages: Spanish, French, German (default: English)."
  exit 1
fi

# Activate the virtual environment
source "$VENV_PATH/bin/activate"

# Check if the virtual environment was activated successfully
if [ $? -ne 0 ]; then
  echo "Error: Failed to activate virtual environment at $VENV_PATH."
  exit 1
fi

# Run the Python script with the audio file and target language as arguments
output=$(python "$PYTHON_SCRIPT" "$AUDIO_FILE" "$TARGET_LANGUAGE")

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
