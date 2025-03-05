#!/bin/bash

# Define the base directory
BASE_DIR="/home/data1/protected/.config/fabric/patterns"

# Find all directories containing system.md and store them in an array
mapfile -t dirs < <(find "$BASE_DIR" -type f -name "system.md" | awk -F'/system.md' '{print $1}')

# Create an associative array to store directory names and their system.md paths
declare -A dir_map
for dir in "${dirs[@]}"; do
    dir_name=$(basename "$dir")
    dir_map["$dir_name"]="$dir/system.md"
done

# Use dmenu to let the user select a directory name
selected=$(printf "%s\n" "${!dir_map[@]}" | dmenu -fn "DejaVu:pixelsize=24" -l 10 -i -b -nf blue -nb pink -p "Select a prompt:")

# If a selection was made, print the content of the corresponding system.md
if [[ -n "$selected" ]]; then
    cat "${dir_map[$selected]}"
fi
