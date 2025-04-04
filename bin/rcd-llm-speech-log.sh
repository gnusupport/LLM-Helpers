#!/bin/bash

# Database connection details
DB_NAME="dbname"
DB_USER="user"
DB_HOST="localhost"
DB_PORT="5432"

# Track the last speech text we've processed
LAST_SPEECH=""

while true; do
    # This uses your exact channel-checking query
    NOTIFICATION=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
        LISTEN new_speech;
        SELECT 1 WHERE EXISTS (
            SELECT 1 FROM pg_listening_channels() WHERE pg_listening_channels() = 'new_speech'
        );
    " 2>&1)
    
    if [[ $NOTIFICATION == *"1"* ]]; then
        # Get the current latest speech with proper quote handling
        CURRENT_SPEECH=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
            SELECT speech_text FROM public.speech
            ORDER BY speech_datecreated DESC
            LIMIT 1;
        " | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/''/'/g")  # Fix doubled single quotes
        
        # Only show if it's different from last time
        if [ "$CURRENT_SPEECH" != "$LAST_SPEECH" ]; then
            echo -e "\nNew Speech Detected: $CURRENT_SPEECH"
            LAST_SPEECH="$CURRENT_SPEECH"
        fi
        
        # Clear the notification by doing a simple query
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" >/dev/null
    fi
    
    sleep 1
done
