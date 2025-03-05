#!/bin/bash

# This script listens for speech using `sox` with Voice Activity Detection (VAD),
# generates a transcript using `rcd-canary.sh`, and immediately types the
# transcript using `xdotool`. It is designed for single input sessions.

# Notify the user that speech recognition has started
notify-send "Speech recognition started..."

# Define a temporary audio file for recording
audio_file=$(mktemp $TMPDIR/audio-notes/speech/audio_recording_XXXXXX.wav)
echo "Temporary audio file created: $audio_file"

# Start recording with VAD using sox
echo "Starting recording..."
sox -t alsa default "$audio_file" silence 1 0.1 3% 1 1.0 3% &
RECORD_PID=$!
echo "Recording started with PID: $RECORD_PID"

# Wait for the recording to finish (sox stops on silence)
echo "Waiting for recording to finish..."
wait "$RECORD_PID"
echo "Recording finished."

# Generate transcript using rcd-canary.sh
echo "Generating transcript..."

# Use a temporary file to capture the output
temp_file=$(mktemp $TMPDIR/audio-notes/speech/transcript_XXXXXX.txt)
timeout 10s rcd-canary.sh "$audio_file" > "$temp_file" 2>&1
exit_status=$?

# Debug: Print the exit status and raw transcript
echo "Exit status: $exit_status"
echo "Raw transcript: $(cat "$temp_file")"

if [ $exit_status -eq 0 ]; then
    echo "Transcript generated successfully."
    transcript=$(cat "$temp_file")
    echo "Transcript: $transcript"

    # Define the date in the desired format
    DATE=$(/usr/bin/date +%Y-%m-%d-%H-%M-%S)  # Adjust the date format as needed

    SQL_COMMAND="INSERT INTO speech (speech_speechtypes, speech_name, speech_text) 
    		      VALUES (1, 'Speech: $DATE', '$transcript')
    		   RETURNING speech_id;"

    # Execute the SQL command and capture the returned speech_id
    SPEECH_ID=$(psql -q -U maddox -d rcdbusiness -t -c "$SQL_COMMAND")

    # Check if the psql command was successful
    if [ $? -eq 0 ] && [ -n "$SPEECH_ID" ]; then
	echo "SQL command executed successfully. Inserted speech_id: $SPEECH_ID"

	# Send the transcript to the embedding script and capture the output
	EMBEDDING=$(echo "$transcript" | rcd-llm-get-embeddings.sh)

	# Check if the embedding script was successful
	if [ $? -eq 0 ]; then
	    echo "Embedding generated successfully."

	    # Insert the embedding into the speech_embeddings column using the speech_id
	    UPDATE_COMMAND="UPDATE speech 
                               SET speech_embeddings = '$EMBEDDING' 
                             WHERE speech_id = $SPEECH_ID;"

	    psql -U maddox -d rcdbusiness -t -c "$UPDATE_COMMAND"
	    
	    # Check if the update was successful
	    if [ $? -eq 0 ]; then
		echo "Embedding inserted into the database successfully."
	    else
		echo "Failed to insert embedding into the database."
	    fi
	else
	    echo "Failed to generate embedding."
	fi
    else
	echo "Failed to execute SQL command or no speech_id returned."
    fi

    # Use xdotool to type the transcript
    echo "Typing transcript using xdotool..."
    if xdotool type --delay 10 "$transcript"; then
        echo "Transcript typed successfully."
    else
        echo "Failed to type transcript."
    fi
elif [ $exit_status -eq 124 ]; then
    echo "rcd-canary.sh timed out after 10 seconds."
else
    echo "Failed to generate transcript. Exit status: $exit_status"
    echo "Error output: $(cat "$temp_file")"
fi

# Clean up temporary files
echo "Cleaning up temporary files..."
rm -f "$audio_file" "$temp_file"

# Notify the user that speech recognition has finished
notify-send "Speech recognition finished."
