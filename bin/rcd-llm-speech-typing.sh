#!/bin/bash

# This script continuously records audio using the `sox` utility with
# Voice Activity Detection (VAD) to automatically stop recording when
# silence is detected. It creates a temporary audio file for each
# recording session, processes it to generate a transcript using the
# `rcd-canary.sh` script, and checks if the phrase "please stop
# recording" appears in the transcript. If detected, the script exits;
# otherwise, it uses `xdotool` to type out the transcript. The script
# handles errors during transcript generation and ensures temporary
# files are cleaned up after each cycle, maintaining a loop until the
# termination condition is met.

notify-send "Speech recognition started..."

# Function to start recording with VAD using sox
start_recording() {
    echo "Starting recording..."
    # Record audio with silence detection
    sox -t alsa default "$audio_file" silence 1 0.1 3% 1 1.0 3% &
    RECORD_PID=$!
    echo "Recording started with PID: $RECORD_PID"
}

# Function to process the transcript
process_transcript() {
    local input_file="$1"
    echo "Processing transcript for file: $input_file"

    # Generate transcript using rcd-canary.sh
    echo "Generating transcript..."
    echo "Running: rcd-canary.sh $input_file"

    # Use a temporary file to capture the output
    temp_file=$(mktemp $TMPDIR/transcript_XXXXXX.txt)
    rcd-canary.sh "$input_file" > "$temp_file" 2>&1
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

        # Convert transcript and target phrase to lowercase for case-insensitive comparison
        if [[ "${transcript,,}" == *"please stop recording"* ]]; then
            echo "Detected 'Please stop recording' in transcript. Exiting..."
	    notify-send "Finished speech recognition."
            exit 0;
        fi
    else
        echo "Failed to generate transcript. Exit status: $exit_status"
        echo "Error output: $(cat "$temp_file")"
        rm -f "$temp_file"
        return 1
    fi

    # Use xdotool to type the transcript
    echo "Typing transcript using xdotool..."
    if xdotool type --delay 10 "$transcript"; then
        echo "Transcript typed successfully."
    else
        echo "Failed to type transcript."
    fi

    # Clean up the temporary file
    rm -f "$temp_file"
}

# Main loop
while true; do
    echo "Starting new recording cycle..."

    # Define a temporary audio file for recording
    audio_file=$(mktemp $TMPDIR/audio_recording_XXXXXX.wav)
    echo "Temporary audio file created: $audio_file"

    # Start recording
    start_recording

    # Wait for the recording to finish (sox stops on silence)
    echo "Waiting for recording to finish..."
    wait "$RECORD_PID"
    echo "Recording finished."

    # Process the transcript immediately after recording
    process_transcript "$audio_file"

    # Clean up the previous audio file
    echo "Cleaning up audio file: $audio_file"
    rm -f "$audio_file"
done

echo "Script stopped."
