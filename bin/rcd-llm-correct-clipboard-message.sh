#!/bin/bash

# Read input from clipboard
user_input=$(xclip -o -selection clipboard 2>&1)

# Check if the input was successfully retrieved
if [ -n "$user_input" ]; then
    echo "Clipboard content: $user_input"
else
    echo "No content found in clipboard."
    exit 1
fi

# Define the prompt without an extra newline before the user input
prompt="## Instruction: Please summarize the following situation in a concise manner without adding any personal comments or interpretations. Write it as me, write it as my own message:

$user_input"

# Debug: Print the prompt to verify formatting
echo "Debug: Prompt is: $prompt"

# Feed the prompt to rcd-llm.sh and capture stdout
output=$(echo -e "$prompt" | rcd-llm.sh 2>&1)

# Check if rcd-llm.sh executed successfully
if [ $? -ne 0 ]; then
    echo "Error: rcd-llm.sh failed to execute."
    exit 1
fi

# Debug: Print the output to verify it's correct
echo "Debug: Output is: $output"

# Copy the output to the clipboard
echo -e "$output" | xclip -selection clipboard

echo "Output copied to clipboard."
