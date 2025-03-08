#!/bin/bash

# This script allows the user to select a language from a list using a
# graphical interface.  Once a language is selected, the script
# initiates a process where the user can speak in English, and the
# speech is then typed on the screen in the selected language.

while true; do
    SCRIPT=$(yad --center \
        --title="Language Selection" \
        --text="Select a language to type for English speech:" \
        --width=300 --height=500 \
        --list \
        --column="Languages" \
        "Chinese" \
	"Croatian" \
        "Danish" \
        "French" \
        "German" \
        "Italian" \
        "Marathi" \
        "Pidgin" \
        "Portuguese" \
        "Russian" \
        "Spanish" \
        "Swedish" \
        "Exit" \
        --default-item="Italian" \
        --print-column=1 \
        --separator="" \
        --button="Run" \
        2>/dev/null)

    echo $SCRIPT >&2

    case $SCRIPT in
        "Chinese")  bash rcd-llm-to-chinese.sh ;;
        "Danish")  bash rcd-llm-to-danish.sh ;;
        "French")  bash rcd-llm-to-french.sh ;;
        "German")  bash rcd-llm-to-german.sh ;;
        "Italian")  bash rcd-llm-to-italian.sh ;;
        "Marathi")  bash rcd-llm-to-marathi.sh ;;
        "Pidgin")  bash rcd-llm-to-pidgin.sh ;;
        "Portuguese")  bash rcd-llm-to-portuguese.sh ;;
        "Croatian")  bash rcd-llm-to-croatian.sh ;;
        "Russian")  bash rcd-llm-to-russian.sh ;;
        "Spanish")  bash rcd-llm-to-spanish.sh ;;
        "Swedish")  bash rcd-llm-to-swedish.sh ;;
        "Exit")  exit 0 ;;
        *) echo "No script selected" && exit 0 ;;
    esac
done
