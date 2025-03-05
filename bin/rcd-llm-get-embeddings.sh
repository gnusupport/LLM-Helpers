#!/bin/bash

# Get LAN IP address
HOST=$(/home/data1/protected/bin/rcd/get_ethernet_interface.sh)

# Configuration
API_ENDPOINT="http://$HOST:9999/v1/embeddings"
API_KEY="any"
MODEL="nomic-embed-text-v1.5-Q8_0.gguf"

# Read input from standard input
INPUT_TEXT=$(cat)

# Prepare JSON payload
JSON_PAYLOAD=$(jq -n \
  --arg model "$MODEL" \
  --arg input "$INPUT_TEXT" \
  '{model: $model, input: $input}')

# Send request to the API and get the response
RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d "$JSON_PAYLOAD")

# Extract the embedding from the response
EMBEDDING=$(echo "$RESPONSE" | jq -r '.data[0].embedding')

# Output the embedding
echo "$EMBEDDING"
