#!/usr/bin/env bash
set -euo pipefail
source /home/data1/protected/bin/rcd/rcd-llm-settings.sh

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

# Notify user
notify-send "Speech recognition started..."

# Create temporary files
audio_file=$(mktemp "${TMPDIR}/audio-notes/speech/audio_recording_XXXXXX.wav")
temp_file=$(mktemp "${TMPDIR}/audio-notes/speech/transcript_XXXXXX.txt")
log "DEBUG" "Temporary audio file: ${audio_file}"
log "DEBUG" "Temporary transcript file: ${temp_file}"

# Start visual feedback
pqiv -z 0.2 -F --fade-duration 10 -c -i -P 1700,50 "${BG_IMAGE}" 2>/dev/null &
PQIV_PID=$!
sleep 0.2
icesh -class pqiv setLayer 6

# Start recording with VAD
log "INFO" "Starting audio recording"
sox -t alsa default "$audio_file" silence 1 0.1 3% 1 1.0 3% &
RECORD_PID=$!

# Wait for recording to complete
wait "${RECORD_PID}" || {
    log "ERROR" "Recording failed"
    exit 1
}
kill "${PQIV_PID}" 2>/dev/null || true

# Transcription
log "INFO" "Starting transcription for ${TARGET_LANGUAGE}"

if check_port_usage 7860; then
    log "INFO" "Using rcd-canary.sh for transcription"
    timeout 50s rcd-canary.sh "${audio_file}" "${TARGET_LANGUAGE}" > "${temp_file}"
else
    log "INFO" "Using whisper-cli for transcription"
    TEMP_INPUT=$(mktemp "${TMPDIR}/temp_input_XXXXXX.wav")
    cp "${audio_file}" "${TEMP_INPUT}"
    sox "${TEMP_INPUT}" "${audio_file}" reverse pad 0.7 0 reverse
    whisper-cli -nt -m "${WHISPER_MODEL}" -f "${audio_file}" -np > "${temp_file}" 2>/dev/null
fi

transcript=$(<"${temp_file}")

# Get the embedding and find the closest match
embedding=$(echo "$transcript" | rcd-llm-get-embeddings.sh)
if [ -z "$embedding" ]; then
    log "ERROR" "Failed to generate embedding"
    exit 1
fi

# Properly escape for SQL (PostgreSQL dollar-quoting)
escaped_embedding="\$VECTOR\$${embedding}\$VECTOR\$"

# Query for matches
speech_id=$(psql -t <<EOF
    SELECT speech_id
    FROM speech
    WHERE speech_embeddings IS NOT NULL
      AND speech_speechtypes = 13
      AND speech_embeddings <=> ${escaped_embedding}::vector < 0.3
    ORDER BY speech_embeddings <=> ${escaped_embedding}::vector
    LIMIT 1
EOF
	 )

# Clean and validate the result
speech_id=$(echo "$speech_id" | tr -d '[:space:]')
if [[ -n "$speech_id" && "$speech_id" =~ ^[0-9]+$ ]]; then
    log "INFO" "Match found (speech_id: $speech_id). Aborting."
    exit 1
fi

log "DEBUG" "Raw transcript: ${transcript}"

# Database operations
# Database operations
DATE=$(date +'%Y-%m-%d-%H-%M-%S')

# Escape the transcript
ESCAPED_TRANSCRIPT=$(escape_sql "$transcript")

# Insert transcript
if SPEECH_ID=$(psql -v ON_ERROR_STOP=1 -q -U maddox -d rcdbusiness -t <<EOF
    INSERT INTO speech (speech_speechtypes, speech_name, speech_text)
    VALUES (1, 'Speech: ${DATE}', \$TRANSCRIPT\$${ESCAPED_TRANSCRIPT}\$TRANSCRIPT\$)
    RETURNING speech_id;
EOF
) && [ -n "${SPEECH_ID}" ]; then
    log "INFO" "Inserted record with ID: ${SPEECH_ID}"
    
    if EMBEDDING=$(echo "${transcript}" | rcd-llm-get-embeddings.sh); then
        # Validate and format the embedding
        if FORMATTED_EMBEDDING=$(format_embedding "$EMBEDDING"); then
            psql -v ON_ERROR_STOP=1 -U maddox -d rcdbusiness -t > /dev/null 2>&1 <<EOF
                UPDATE speech
                SET speech_embeddings = '${FORMATTED_EMBEDDING}'
                WHERE speech_id = ${SPEECH_ID};
EOF
            if [ $? -eq 0 ]; then
                log "INFO" "Successfully updated embedding"
            else
                log "ERROR" "Failed to update embedding"
            fi
        else
            log "ERROR" "Invalid embedding format"
        fi
    else
        log "ERROR" "Failed to generate embedding"
    fi
else
    log "ERROR" "Database operation failed"
fi

echo "${transcript}"

