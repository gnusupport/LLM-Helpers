#!/bin/bash -x

# Fixed voice
fixed_voice="am_onyx"

# Get the current timestamp for the output filename
timestamp=$(date +"%Y-%m-%d-%H-%M-%S")

# Define the directory where the audio files will be saved
tmp_audio_dir="$TMPDIR/audio-notes/$timestamp"

# Ensure the directory exists, create it if not
mkdir -p "$tmp_audio_dir"

# Construct the output filename based on the fixed voice and timestamp
output_file="${tmp_audio_dir}/${timestamp}.mp3"

# Use printf to escape double quotes
escaped_sentence=$(echo " $(cat)" | jq -sR .)

# Make the POST request and save the output in MP3 format
curl -X POST http://192.168.1.68:3700/v1/audio/speech \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"kokoro\",
        \"input\": ${escaped_sentence},
        \"voice\": \"${fixed_voice}\",
	\"response_format\": \"mp3\"
    }" \
    -H "Accept: audio/mpeg" \
    --output "${output_file}"

# Initialize the m4a variable
m4a="${output_file}.m4a"

# Check if curl was successful
if [ $? -eq 0 ]; then
    # Open the generated audio file with rox
    ffmpeg -i "${output_file}" "${m4a}" 2>&1

    WINDOW_ID=$(xdotool getactivewindow)
    
    # Open the generated audio file with rox in a subshell
    (
        rox -n -s "${m4a}" &
        rox_pid=$!

        # Sleep for 30 seconds
        sleep 15

        # Kill the rox process
        kill $rox_pid 2>/dev/null

        # Disown the process to avoid it being killed when the subshell exits
        disown $rox_pid
    ) &

    xdotool windowactivate $WINDOW_ID
else
    echo "Error: Failed to generate audio."
    exit 1
fi
