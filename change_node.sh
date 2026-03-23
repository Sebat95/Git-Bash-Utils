#!/bin/bash
die () {
    echo >&2 "$@"
    exit 1
}

# cd into nodejs portable directory
rootDir=$(npm root --global)
cd "$rootDir" || die "Failed to CD"
cd .. || die "Failed to CD"

# find all node directories
dirs=$(find . -type d -name "___node*")
if [[ -z "$dirs" ]]; then
  echo "No directories matching '___node*' found."
  exit 1
fi
# convert it to array for looping over it
readarray -t dirs <<< "$dirs"

# display possible version choices
echo "Change node to which available version:"
for i in "${!dirs[@]}"; do
  d=$(echo "${dirs[i]}" | cut -c 11-)
  echo "[$((i + 1))] ${d}"
done
# collect choice adn verify it
read -r -p "Enter the number of your choice: " choice
# Validate the input
if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt "${#dirs[@]}" ]]; then
  echo "Invalid choice!"
  exit 1
fi
selected_dir="${dirs[$((choice - 1))]}"
selected_version=$(echo "${selected_dir}" | cut -c 11-)
echo "You selected: $selected_version"

echo "Moving old version back to its directory..."
current_version="$(node --version)"
# move all files
find . -maxdepth 1 -type f -exec mv {} ./___node-"$current_version"/ \;
# move node_modules
mv node_modules/ ___node-"$current_version"/
echo "Done"

echo "Moving new version out of its directory..."
mv "$selected_dir"/* ./
echo "Done"

#moving back where we came from
cd - > /dev/null || die "Failed to CD"