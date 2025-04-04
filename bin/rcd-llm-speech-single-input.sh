#!/usr/bin/env bash

# This shell script provides an end-to-end solution for speech
# recognition, transcription, and database integration. It records
# audio input, transcribes it using advanced language models,
# processes the transcript, and stores the results in a PostgreSQL
# database. The script also includes features for user notifications
# and visual feedback to enhance the user experience during the
# recording process.

# The script is designed to be flexible, supporting multiple languages
# and offering options to control the typing output of the transcript.

set -euo pipefail
setxkbmap -layout gb
source /home/data1/protected/bin/rcd/rcd-llm-settings.sh

trap cleanup EXIT

no_typing=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --language)
            if [[ -n "${2:-}" ]]; then
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
        -h|--help)
            echo "Usage: $0 [--language <Spanish|French|German>] [--no-typing]"
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'." >&2
            exit 1
            ;;
    esac
done

# Validate target language
declare -A valid_languages=(
    [English]=1
    [Spanish]=1
    [French]=1
    [German]=1
)

if [[ -z "${valid_languages[$TARGET_LANGUAGE]:-}" ]]; then
    log "ERROR" "Unsupported target language '$TARGET_LANGUAGE'"
    exit 1
fi

WINDOW_ID=$(xdotool getactivewindow)
transcript=$(rcd-llm-speech-to-stdout.sh)

# Typing output if enabled
if ! "${no_typing}"; then
    log "INFO" "Typing transcript"
    if xdotool windowactivate "${WINDOW_ID}" && sleep 0.3 && 
       xdotool type --delay 20 "${transcript}"; then
        log "INFO" "Typing completed"
        
        if [[ -f "/home/data1/protected/bin/rcd/show_m4a.config" ]]; then
            kokoro-stdin-to-audio-file.sh < "${temp_file}"
        fi
    else
        log "ERROR" "Typing failed"
    fi
fi

# Final output
cat "${temp_file}"
notify-send "Speech recognition finished"
exit 0
