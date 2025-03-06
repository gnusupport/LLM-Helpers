#!/bin/bash

# This script listens for speech using `sox` with Voice Activity Detection (VAD),
# generates a transcript using `rcd-canary.sh`, and immediately types the
# transcript using `xdotool`. It is designed for single input sessions.

# Default target language (English)
TARGET_LANGUAGE="English"

# Initialize no_typing to false by default
no_typing=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --language)
            if [[ -n "$2" ]]; then
                TARGET_LANGUAGE="$2"
                shift 2
            else
                echo "Error: --language requires a value (Spanish, French, or German)." >&2
                exit 1
            fi
            ;;
        --no-typing)
            no_typing=true
            shift
            ;;
        *)
            echo "Error: Unknown argument '$1'." >&2
            exit 1
            ;;
    esac
done

# Validate the target language
if [[ "$TARGET_LANGUAGE" != "English" && "$TARGET_LANGUAGE" != "Spanish" && "$TARGET_LANGUAGE" != "French" && "$TARGET_LANGUAGE" != "German" ]]; then
    echo "Error: Unsupported target language '$TARGET_LANGUAGE'. Supported languages: Spanish, French, German (default: English)." >&2
    exit 1
fi

# Notify the user that speech recognition has started
notify-send "Speech recognition started..."

# Define a temporary audio file for recording
audio_file=$(mktemp $TMPDIR/audio-notes/speech/audio_recording_XXXXXX.wav)
echo "Temporary audio file created: $audio_file" >&2

# Start recording with VAD using sox
echo "Starting recording..." >&2
sox -t alsa default "$audio_file" silence 1 0.1 3% 1 1.0 3% &
RECORD_PID=$!
echo "Recording started with PID: $RECORD_PID" >&2

# Wait for the recording to finish (sox stops on silence)
echo "Waiting for recording to finish..." >&2
wait "$RECORD_PID" >&2
echo "Recording finished." >&2

# Generate transcript using rcd-canary.sh with the target language
echo "Generating transcript with target language: $TARGET_LANGUAGE..." >&2

# Use a temporary file to capture the output
temp_file=$(mktemp $TMPDIR/audio-notes/speech/transcript_XXXXXX.txt)
timeout 10s rcd-canary.sh "$audio_file" "$TARGET_LANGUAGE" > "$temp_file" 2>&1
exit_status=$?

# Debug: Print the exit status and raw transcript
echo "Exit status: $exit_status" >&2
echo "Raw transcript: $(cat "$temp_file")" >&2

if [ $exit_status -eq 0 ]; then
    echo "Transcript generated successfully." >&2
    transcript=$(cat "$temp_file")
    echo "Transcript: $transcript" >&2

    # Define the date in the desired format
    DATE=$(/usr/bin/date +%Y-%m-%d-%H-%M-%S)  # Adjust the date format as needed

    SQL_COMMAND="INSERT INTO speech (speech_speechtypes, speech_name, speech_text) 
    		      VALUES (1, 'Speech: $DATE', '$transcript')
    		   RETURNING speech_id;"

    # Execute the SQL command and capture the returned speech_id
    SPEECH_ID=$(psql -q -U maddox -d rcdbusiness -t -c "$SQL_COMMAND")

    # Check if the psql command was successful
    if [ $? -eq 0 ] && [ -n "$SPEECH_ID" ]; then
	echo "SQL command executed successfully. Inserted speech_id: $SPEECH_ID" >&2

	# Send the transcript to the embedding script and capture the output
	EMBEDDING=$(echo "$transcript" | rcd-llm-get-embeddings.sh)

	# Check if the embedding script was successful
	if [ $? -eq 0 ]; then
	    echo "Embedding generated successfully." >&2

	    # Insert the embedding into the speech_embeddings column using the speech_id
	    UPDATE_COMMAND="UPDATE speech 
                               SET speech_embeddings = '$EMBEDDING' 
                             WHERE speech_id = $SPEECH_ID;"

	    psql -U maddox -d rcdbusiness -t -c "$UPDATE_COMMAND" >&2

	    # Check if the update was successful
	    if [ $? -eq 0 ]; then
		echo "Embedding inserted into the database successfully." >&2
	    else
		echo "Failed to insert embedding into the database." >&2
	    fi
	else
	    echo "Failed to generate embedding." >&2
	fi
    else
	echo "Failed to execute SQL command or no speech_id returned." >&2
    fi

    # Handle typing based on the no_typing flag
    if [ "$no_typing" = false ]; then
	# Use xdotool to type the transcript
	echo "Typing transcript using xdotool..." >&2
	if xdotool type --delay 10 "$transcript"; then
            echo "Transcript typed successfully." >&2
	else
            echo "Failed to type transcript." >&2
	fi
    else
	# Handle the case when no_typing is true
	echo "Typing is disabled (no_typing is true)." >&2
    fi
    
elif [ $exit_status -eq 124 ]; then
    echo "rcd-canary.sh timed out after 10 seconds." >&2
else
    echo "Failed to generate transcript. Exit status: $exit_status" >&2
    echo "Error output: $(cat "$temp_file")" >&2
fi

cat "$temp_file"

# Clean up temporary files
echo "Cleaning up temporary files..." >&2
rm -f "$audio_file" "$temp_file"

# Notify the user that speech recognition has finished
notify-send "Speech recognition finished."
 
