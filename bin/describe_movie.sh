#!/bin/bash

# Generate movie description for directory, something like:
# Title:"The Watersprite" (2015)
# Year:: 2016 
# Genre :Fantasy/Adventure/Drama/Musical/Family/Superhero 

# Plot:
# In a small seaside town, young Tom discovers the magical existence of water sprites and begins to save his family's failing business. When he learns that there is an ancient curse threatening their livelihoods, it leads him on a journey through time as well as space.

# Actors: 
# - John Rhys-Davies (as "The Watersprite")
# - Charlotte Leakey
# - Tom Holland

# Define a log file
LOGFILE="/tmp/describe_movie.log"

# Redirect all output (stdout and stderr) to the log file
exec > "$LOGFILE" 2>&1


# Step 1: Get the IP address
HOST=$(/home/data1/protected/bin/rcd/get_ethernet_interface.sh)
ENDPOINT="http://$HOST:8080/v1/chat/completions"

# Step 2: Define the directory to process
for DIR in "$@"; do
    # Ensure the directory is a full path
    DIR=$(realpath "$DIR")

    # Check if the directory exists
    if [ ! -d "$DIR" ]; then
	echo "Directory $DIR does not exist. Skipping."
	continue
    fi

    # Step 3: Generate the prompt with directory name and list of files
    DIR_BASENAME=$(basename "$DIR")  # Extract the base name of the directory
    FILES=$(ls "$DIR")  # Get the list of files in the directory
    PROMPT=$(cat <<EOF
For directory "$DIR_BASENAME", which contains the following files:
$FILES

review if this sounds as name of movie and if you think it is movie,
then describe the movie, the plot, the genre, and major actors in the
form such as:

Movie title: 

Year: 

Genre: 

The plot: 

Actors: 
EOF
	  )

      # Escape newlines in the prompt for JSON compatibility
    PROMPT_ESCAPED=$(echo "$PROMPT" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
   
    # Step 4: Send the prompt to the LLM and save the response
    RESPONSE_FILE="${DIR}/$(basename "$DIR")-description.txt"

    # Step 5: Send the prompt to the LLM and save the response
    echo "Sending request to LLM for directory: $DIR"
    echo "Endpoint: $ENDPOINT"

    # Log the JSON payload being sent
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
    echo "JSON Payload: $JSON_PAYLOAD"

    # Send the request and capture the response
    RESPONSE=$(curl -s -X POST "$ENDPOINT" \
		    -H "Content-Type: application/json" \
		    -d "$JSON_PAYLOAD")

    # Check if the curl command succeeded
    if [ $? -ne 0 ]; then
	echo "Error: Failed to send request to LLM endpoint."
	continue
    fi

    # Log the raw response
    echo "Raw Response: $RESPONSE"

    # Extract the content from the response using jq
    CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

    # Check if jq succeeded
    if [ $? -ne 0 ]; then
	echo "Error: Failed to parse LLM response."
	continue
    fi

    # Save the content to the response file
    echo "$CONTENT" > "$RESPONSE_FILE"

    # Check if the file was written successfully
    if [ $? -eq 0 ]; then
	echo "Response saved to $RESPONSE_FILE"
    else
	echo "Error: Failed to write response to file."
    fi
done
