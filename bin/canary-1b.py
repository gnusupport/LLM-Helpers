import sys
import contextlib
from gradio_client import Client, handle_file

def transcribe_audio(filepath, target_language="English"):
    # Suppress Gradio client output during initialization
    with contextlib.redirect_stdout(None):
        client = Client("http://127.0.0.1:7860/")

    # Call the API to transcribe the audio
    result = client.predict(
        audio_filepath=handle_file(filepath),
        src_lang="English",
        tgt_lang=target_language,
        pnc=True,
        api_name="/transcribe"
    )

    # Return the transcription result
    return result

if __name__ == "__main__":
    # Check if a file path is provided as a command-line argument
    if len(sys.argv) < 2:
        print("Usage: python transcribe.py <audio_file> [target_language]")
        print("Supported target languages: Spanish, French, German (default: English)")
        sys.exit(1)

    # Get the audio file path from the command line
    audio_file = sys.argv[1]

    # Get the target language from the command line (if provided)
    target_language = "English"  # Default to English
    if len(sys.argv) >= 3:
        language = sys.argv[2].capitalize()  # Normalize input (e.g., "spanish" -> "Spanish")
        if language in ["Spanish", "French", "German"]:
            target_language = language
        # If the language is unsupported, silently default to English

    # Transcribe the audio and print the result
    try:
        transcription = transcribe_audio(audio_file, target_language)
        print(transcription)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
