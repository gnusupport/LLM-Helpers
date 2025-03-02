#!/bin/bash

# What the Script Does
# --------------------

# 1. Check for Tools:
#    - Ensures `jq` and `curl` are installed. These tools are needed for
#      JSON handling and making web requests.

# 2. Get User Input:
#    - Waits for you to type a prompt and press Enter. This is the text
#      you want the language model to process.

# 3. Ensure Input is Valid:
#    - Checks if you typed something. If not, it stops and tells you no
#      prompt was provided.

# 4. Prepare the Prompt:
#    - Formats your input for JSON by escaping special characters like
#      newlines.

# 5. Find the Server Address:
#    - Uses a custom script to find the IP address of your ethernet
#      connection.

# 6. Set Up the URL:
#    - Constructs a URL using the IP address to point to a local service
#      that processes language models.

# 7. Create a Request:
#    - Prepares a JSON request with your prompt and instructions for the
#      language model.

# 8. Send the Request:
#    - Sends the request to the local language model service and waits
#      for a response.

# 9. Check for Success:
#    - Verifies if the request was successfully sent. If not, it reports
#      an error.

# 10. Extract the Answer:
#     - Uses `jq` to extract the response from the language model.

# 11. Show the Result:
#     - Prints the language model's response to the screen.

# How to Use the Script
# ---------------------

# 1. Install Tools:
#    - Ensure `jq` and `curl` are installed. You can usually install
#      them with a command like `sudo apt install`.

# 2. Save the Script:
#    - Save the script to a file, e.g., `llm_script.sh`.

# 3. Make Script Executable:
#    - Run `chmod +x llm_script.sh` to make the script executable.

# 4. Run the Script:
#    - Execute the script by running: `./llm_script.sh`
#    - Type your prompt and press Enter to get the processed result.


# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed. Please install jq and try again."
  exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
  echo "Error: curl is required but not installed. Please install curl and try again."
  exit 1
fi

# Read prompt from stdin
read -r PROMPT

# Check if prompt is not empty
if [ -z "$PROMPT" ]; then
  echo "Error: No prompt provided."
  exit 1
fi

# Escape newlines in the prompt for JSON compatibility
PROMPT_ESCAPED=$(echo "$PROMPT" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')

# Get the IP address
HOST=$(/home/data1/protected/bin/rcd/get_ethernet_interface.sh)
ENDPOINT="http://$HOST:8080/v1/chat/completions"

# Prepare the JSON payload
JSON_PAYLOAD=$(cat <<EOF
  {
    "model": "local",
    "messages": [
      {
        "role": "system",
        "content": "You are a helpful assistant that describes movies based on directory and file names."
      },
      {
        "role": "user",
        "content": "$PROMPT_ESCAPED"
      }
    ],
    "temperature": 0.7,
    "max_tokens": 500,
    "top_p": 1.0,
    "frequency_penalty": 1.2,
    "repeat_penalty": 1.2,
    "stream": false
  }
EOF
	    )

# Suppress JSON payload output
# echo "JSON Payload: $JSON_PAYLOAD"

# Send the request and capture the response
RESPONSE=$(curl -s -X POST "$ENDPOINT" \
		-H "Content-Type: application/json" \
		-d "$JSON_PAYLOAD")

# Check if the curl command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to send request to LLM endpoint."
    continue
fi

# Suppress raw response output
# echo "Raw Response: $RESPONSE"

# Extract the content from the response using jq
CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

# Check if jq succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to parse LLM response."
    continue
fi

# Save the content to the response file
echo "$CONTENT"
