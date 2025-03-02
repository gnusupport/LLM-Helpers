#!/bin/bash

# Records audio note, transcribes by using Nvidia Canary-1B and
# inserts transcription into clipboard.

# Define directories
AUDIO_DIR="/home/data1/protected/tmp/audio-notes"
TEMP_DIRS_DIR="/home/data1/protected/temp-dirs"

# Ensure directories exist
mkdir -p "$AUDIO_DIR"
mkdir -p "$TEMP_DIRS_DIR"

# Get current date and time
CURRENT_DATE=$(date +%Y-%m-%d)
CURRENT_TIME=$(date +%H-%M-%S)

# Define filename
FILENAME="audio-note-$CURRENT_DATE-$CURRENT_TIME.mp3"

# Function to start recording
start_recording() {
    # Start xterm with the recording command
    xterm -e "bash -c 'echo \"Starting recording...\"; arecord -f cd -t wav | lame -r - \"$AUDIO_DIR/$FILENAME\"; if [ $? -eq 0 ]; then echo \"Recording stopped. Press [Enter] to close this window...\"; else echo \"Recording failed. Press [Enter] to close this window...\"; fi; read'"
    
    # Check if the recording was successful
    if [ -f "$AUDIO_DIR/$FILENAME" ]; then
        echo "Recording stopped by user. File saved as $AUDIO_DIR/$FILENAME."
    else
        echo "Recording process ended unexpectedly or failed."
    fi
}

# Function to create temporary directory and symlink
create_temp_dir_and_symlink() {
    # Create a temporary directory named after the file (without extension)
    TEMP_DIR="$TEMP_DIRS_DIR/$(basename "$FILENAME" .mp3)"
    
    # Create the temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Create a symlink in the temporary directory pointing to the audio file
    ln -s "$AUDIO_DIR/$FILENAME" "$TEMP_DIR/$FILENAME"
    
    # Open the temporary directory with xdg-open (or any other lightweight file manager)
    rox "$TEMP_DIR"
    
    echo "Temporary directory created at $TEMP_DIR."
}

# Function to transcribe the audio file
transcribe_audio() {
    local audio_file="$1"
    local transcript_file="${audio_file%.mp3}.txt"

    # Call rcd-canary.sh to transcribe the audio file
    echo "Transcribing audio file: $audio_file"
    transcription=$(rcd-canary.sh "$audio_file")

    # Save the transcription to a .txt file
    echo "$transcription" > "$transcript_file"
    echo "Transcription saved as $transcript_file."
}

# Start recording in xterm
start_recording

# Create temp directory and symlink (only if recording succeeded)
if [ -f "$AUDIO_DIR/$FILENAME" ]; then
    create_temp_dir_and_symlink

    # Transcribe the audio file
    transcribe_audio "$AUDIO_DIR/$FILENAME"
fi

