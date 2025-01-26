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

# Step 1: Get the IP address
HOST=$(get_ethernet_interface.sh)
ENDPOINT="http://$HOST:8080/v1/chat/completions"

# Step 2: Define the directory to process
DIR="$1"

# Step 3: Generate the prompt
PROMPT=$(cat <<EOF
For directory $DIR review if this sounds as name of movie and if you think it is movie, then describe the movie, the plot, the genre, and major actors in the form such as:

Movie title:

Year:

Genre:

The plot:

Actors:
EOF
)

# Step 4: Send the prompt to the LLM and save the response
RESPONSE_FILE="${DIR}/$(basename "$DIR")-description.txt"

curl -X POST "$ENDPOINT" \
     -H "Content-Type: application/json" \
     -d @- <<EOF | jq -r '.choices[0].message.content' > "$RESPONSE_FILE"
{
  "model": "local",
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful assistant that describes movies based on directory and file names."
    },
    {
      "role": "user",
      "content": "$PROMPT"
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

echo "Response saved to $RESPONSE_FILE"
