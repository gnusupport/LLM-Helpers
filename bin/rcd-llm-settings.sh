
# Configuration
TARGET_LANGUAGE="English"
TMPDIR="${TMPDIR:-/tmp}"
WHISPER_MODEL="/mnt/nvme0n1/LLM/git/whisper.cpp/models/ggml-small.en.bin"
BG_IMAGE="/mnt/nvme0n1/LLM/git/ComfyUI/output/ComfyUI_01563_.png"
CONFIG_DIR="${HOME}/.config/speech2text"
mkdir -p "${CONFIG_DIR}"


# Logging function
log() {
    local level="$1"
    shift
    printf "[%s] [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "${level}" "$@" >&2
}

check_port_usage() {
    local port="$1"
    
    # Check if port is numeric
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        log "ERROR" "Invalid port number: $port"
        return 2
    fi

    # Try multiple methods to check port availability
    if command -v ss >/dev/null; then
        # Modern Linux systems (preferred)
        if ss -tuln | grep -q ":$port "; then
            log "DEBUG" "Port $port is in use (ss)"
            return 0
        fi
    elif command -v netstat >/dev/null; then
        # Fallback for older systems
        if netstat -tuln | grep -q ":$port "; then
            log "DEBUG" "Port $port is in use (netstat)"
            return 0
        fi
    else
        # Last resort using /proc
        if grep -q ":$port " /proc/net/tcp 2>/dev/null || 
           grep -q ":$port " /proc/net/tcp6 2>/dev/null; then
            log "DEBUG" "Port $port is in use (procfs)"
            return 0
        fi
    fi

    log "DEBUG" "Port $port is available"
    return 1
}

# Function to properly escape SQL values
escape_sql() {
    local str="$1"
    # Replace single quotes with double single quotes
    str="${str//\'/\'\'}"
    # Remove newlines (or replace with spaces if preferred)
    str=$(tr -d '\n' <<< "$str")
    echo "$str"
}

format_embedding() {
    local embedding="$1"
    
    # Check if empty
    if [[ -z "$embedding" ]]; then
        log "ERROR" "Empty embedding generated"
        return 1
    fi
    
    # Ensure it's in vector format (starts with '[')
    if [[ "$embedding" != [* ]]; then
           # If not, try to convert it
           if [[ "$embedding" =~ ^[-0-9.,[:space:]]+$ ]]; then
               embedding="[${embedding}]"
           else
               log "ERROR" "Invalid embedding format: '$embedding'"
               return 1
           fi
       fi
	
	echo "$embedding"
       }

# Clean the transcript by removing markdown formatting and asterisks
clean_transcript() {
    sed -e 's/[*_]//g' -e 's/\\//g' "$1" > "${1}.clean"
    mv "${1}.clean" "$1"
}

clean_text() {
    local text="$1"
    # Remove asterisks, underscores, and other unwanted formatting
    cleaned="${text//[*_]/}"
    # Remove any remaining backslashes
    cleaned="${cleaned//\\/}"
    echo "$cleaned"
}

# Cleanup function
cleanup() {
    log "DEBUG" "Cleaning up temporary files"
    rm -f "${audio_file:-}" "${temp_file:-}" "${TEMP_INPUT:-}"
    if [ -n "${PQIV_PID:-}" ]; then
        kill "${PQIV_PID}" 2>/dev/null || true
    fi
    if [ -n "${RECORD_PID:-}" ]; then
        kill "${RECORD_PID}" 2>/dev/null || true
    fi
}
