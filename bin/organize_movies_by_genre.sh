#!/bin/bash

# This is follow-up script to `describe-movie.sh' as once you have
# described all movies by using your favorite free software Large
# Language Model (LLM), then in the next step you may need to organize
# movies by genre.
# 
# The Large Language Model (LLM) has provided descriptions, and they
# contain names of actors, genres, plot, etc.
#
# By grepping descriptions, you may find the genre, and symlink movie
# directories into corresponding genre based directory.

# This script is designed to organize a set of movie files into
# separate directories, each representing a specific genre, based on
# their titles as indicated by a file named "description.txt". The
# script first defines the directories where movies are located and
# the directories where genre-specific symlinks will be created. It
# then iterates through each genre directory found in the specified
# path. For each genre, it searches for movie files whose titles match
# the genre name, as determined from a file named "*-description.txt"
# located in the "/mnt/Movies/MOVIE-ABC" directories. Once found, the
# script creates symbolic links (symlinks) within the genre-specific
# directory.

# The script accomplishes this by using the `find` command to locate
# files matching the genre name in the movie directory. It then
# constructs the target path for the symlink by concatenating the
# genre directory with the movie's directory. Before creating the
# symlink, it checks if a symlink with the same name already exists in
# the genre directory using the `symlink_exists` helper function. If a
# symlink exists, the script skips creating it; otherwise, it creates
# the symlink using the `ln` command.

# Upon successful completion of creating all symlinks, the script
# outputs a message indicating that the organization is done,
# signaling that movie files have been grouped by their respective
# genres.

# In that directory place names of genres:
GENRES_DIR="/mnt/Genres"
#
#
# ls -1 /mnt/Genres
# Action     
# Adventure  
# Animation  
# Comedy     
# Crime      
# Documentary
# Drama      
# Family     
# Fantasy    
# Historical 
# Horror     
# Musical    
# Mystery    
# Romance    
# Sci-Fi     
# Sport      
# Superhero  
# Thriller   
# War        
# Western    

# This is where all movies will be searched
MOVIES_DIR="/mnt/Movies"

# Function to check if a symlink already exists in the genre directory
symlink_exists() {
    local symlink_path="$1"
    
    # Checking if it's a symlink or a regular file
    if [ -e "$symlink_path" ]; then
        echo "Symlink or file $symlink_path already exists (skipping)"
        return 0
    fi

    return 1
}

# Process each genre directory
for genre_dir in "$GENRES_DIR"/*; do
    [ ! -d "$genre_dir" ] && continue

    genre_name=$(basename "$genre_dir")
    genre_name_lower=$(echo "$genre_name" | tr '[:upper:]' '[:lower:]')

    echo "Processing genre: $genre_name (searching for '$genre_name_lower')"

    find -L "$MOVIES_DIR" -type f -name "*-description.txt" -exec grep -wil "$genre_name_lower" {} + | while read -r file; do
        movie_dir=$(dirname "$file")
        movie_name=$(basename "$movie_dir")
        symlink_path="$genre_dir/$movie_name" # Symlink directly inside the genre dir

        # Check if symlink already exists
        symlink_exists "$symlink_path" && continue 

        # Creating symlink
        if ln -s "$(realpath "$movie_dir")" "$symlink_path"; then
            echo "Created symlink: $symlink_path -> $movie_dir"
        else
            echo "Error creating symlink: $?"
        fi
    done
done

echo "Done organizing movies by genre"
