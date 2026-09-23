#!/bin/bash

#!/bin/bash

# Get the current directory
current_dir="$(pwd)"

# Find the first parent directory containing "_quarto.yml"
search_dir="$current_dir"
quarto_dir=""

while [ "$search_dir" != "/" ]; do
    if [ -f "$search_dir/_quarto.yml" ]; then
        quarto_dir="$search_dir"
        break
    fi
    search_dir="$(dirname "$search_dir")"
done

# Check if we found a directory with _quarto.yml
if [ -z "$quarto_dir" ]; then
    echo "Error: No parent directory with _quarto.yml found" >&2
    exit 1
fi

# Calculate the relative path between current_dir and quarto_dir
relative_path="${current_dir#$quarto_dir}"
relative_path="${relative_path#/}"  # Remove leading slash if present

# Build the target directory path
if [ -n "$relative_path" ]; then
    target_dir="$quarto_dir/_output/$relative_path"
else
    target_dir="$quarto_dir/_output"
fi

# Check if the target directory exists
if [ ! -d "$target_dir" ]; then
    echo "Error: Target directory does not exist: $target_dir" >&2
    exit 1
fi

# Change to the target directory
firefox "$target_dir" || {
    echo "Error: Failed to load directory: $target_dir" >&2
    exit 1
}

echo "Changed to: $(pwd)"




# if [ $# -ne "1" ]; then
#         echo "Usage:  $0 <dossier à ouvrir>"
#         exit 1;
# fi

# if [ -d $1 ]; then
#    echo $1;
# else
#    echo "$1 n'existe pas";
#    exit 1;
# fi
# rootdir="$(pwd)/_output/versions/"
# workdir="$(ls -1 $rootdir | grep -e '^draft-.*' | sort | tail -n1)"

# firefox "$rootdir$workdir"