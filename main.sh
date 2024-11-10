#!/bin/bash

# Default value for enable_detailed_tree_view
disply_detailed_tree_view=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --disply_detailed_tree_view=*)
        disply_detailed_tree_view="${arg#*=}"
        ;;
        *)
        echo "Unknown option $arg"
        ;;
    esac
done


# Function to check and install necessary tools
check_and_install_tools() {
    tools=("jq" "zip" "git" "rsync" "tree")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Tool '$tool' is not installed. Attempting to install..."
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo apt update
                sudo apt install -y "$tool"
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                # Check for Homebrew and install if necessary
                if ! command -v brew &> /dev/null; then
                    echo "Homebrew not found. Installing Homebrew first."
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                fi
                brew install "$tool"
            else
                echo "Please install '$tool' manually."
            fi
        else
            echo "Tool '$tool' is already installed."
        fi
    done
}

# Run the tool check and installation function
check_and_install_tools

# Function to read parameters from params.json
read_params() {
    if [ -f "$params_file" ]; then
        project_path=$(jq -r '.project_path' "$params_file")
        source_commit=$(jq -r '.source_commit' "$params_file")
        target_commit=$(jq -r '.target_commit' "$params_file")
        full_code_dir_name=$(jq -r '.full_code_dir_name' "$params_file")
        updated_code_zip_name=$(jq -r '.updated_code_zip_name' "$params_file")
        final_code_zip_name=$(jq -r '.final_code_zip_name' "$params_file")
    else
        echo "Error: params.json file not found at $params_file."
        read -p "Please enter the path to params.json file: " params_file
        read_params  # Re-run the function to try reading again
    fi
}

# Initial path to params.json on Desktop
params_file="$HOME/Desktop/params.json"

# Start the parameter reading process
read_params

# Print the parameters (optional)
echo "Project Path: $project_path"
echo "Source Commit: $source_commit"
echo "Target Commit: $target_commit"
echo "Full Code Directory Name: $full_code_dir_name"
echo "Updated Code Zip Name: $updated_code_zip_name"
echo "Final Code Zip Name: $final_code_zip_name"

full_code_files_path="$HOME/Desktop/code_zips/$full_code_dir_name"
updated_files_path="$HOME/Desktop/code_zips/$updated_code_zip_name"


# Step 3: Create a copy of the latest code
cd "$project_path" || exit 1
mkdir -p "$full_code_files_path"


# Use rsync to copy the full code while excluding all hidden files/folders except .gitignore and .gitkeep, and applying the manual exclusions
rsync -av \
    --exclude='build/' \
    --exclude='android/app/build/' \
    --exclude='android/app/release/' \
    --exclude='ios/build/' \
    --exclude='ios/Pods/' \
    --exclude='.*' \
    --exclude='*.jks' \
    --exclude='*.lock' \
    --exclude='*.rest' \
    --exclude='*.iml' \
    --exclude='*.log' \
    --exclude='android/local.properties' \
    --include='.gitignore' \
    --include='.gitkeep' \
    . "$full_code_files_path"

# Modify the configs.dart file
config_path_of_full_code_dir="$full_code_files_path/lib/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$config_path_of_full_code_dir"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$config_path_of_full_code_dir"
config_path_of_full_code_dir="$full_code_files_path/lib/utils/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$config_path_of_full_code_dir"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$config_path_of_full_code_dir"

echo "Copy of the latest code created from '$target_commit' and changes made to configs.dart."

# Cleaning our key.properties
key_properties="$full_code_files_path/android/key.properties"
rm "$key_properties"
echo "storePassword=" >> "$key_properties"
echo "keyPassword=" >> "$key_properties"
echo "keyAlias=" >> "$key_properties"
echo "storeFile=" >> "$key_properties"


# # Open the modified configs.dart file with gedit
# gedit "$config_path_of_full_code_dir" &

# Add comments to indicate changes made to the configs.dart file
echo ""
echo "🤖 : Sir, I have made a copy of the latest code at $HOME/Desktop/code_zips/$full_code_dir_name."
echo ""
echo "🤖 : And I made the following changes to the configs.dart file:"
echo ""
echo "- Removed commented and 'Development Url' lines related to DOMAIN_URL."
echo "- Set DOMAIN_URL to an empty string."
echo ""
echo "🤖 : The configs.dart file has been opened in a text editor for your review."
echo ""


# Step 4: Make updated code directory
# Create the destination directory if it doesn't exist
mkdir -p "$updated_files_path"

# Use git diff to list the updated files between commits
updated_files=$(git diff --name-only "$source_commit" "$target_commit")

# Loop through the updated files and copy them to the destination directory
for file in $updated_files; do
    # Create the directory structure within the destination directory
    mkdir -p "$updated_files_path/$(dirname "$file")"

    # Use rsync to copy the file, excluding certain files and keeping specific ones
    rsync -av \
        --exclude='build/' \
        --exclude='android/app/build/' \
        --exclude='android/app/release/' \
        --exclude='ios/build/' \
        --exclude='ios/Pods/' \
        --exclude='.*' \
        --exclude='*.jks' \
        --exclude='*.lock' \
        --exclude='*.rest' \
        --exclude='*.iml' \
        --exclude='*.log' \
        --exclude='android/local.properties' \
        --include='.gitignore' \
        --include='.gitkeep' \
        "$file" "$updated_files_path/$file"
done

rm -r "$updated_files_path/.vscode"
echo "Updated files have been copied to: $updated_files_path"

# Modify the configs.dart file for the updated code
config_path_of_updated_code="$updated_files_path/lib/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$config_path_of_updated_code"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$config_path_of_updated_code"
config_path_of_updated_code="$updated_files_path/lib/utils/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$config_path_of_updated_code"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$config_path_of_updated_code"

echo "Changes made to configs.dart in the updated code."

# Step 5: Optionally open updated files directory in the terminal and execute 'tree'
if [ "$disply_detailed_tree_view" = true ]; then
    echo "Opening terminal with updated files directory..."
    gnome-terminal -- bash -c "cd '$updated_files_path' && tree; exec bash"
else
    echo "Detailed tree view is disabled."
fi

# # Open the modified configs.dart file with gedit
# gedit "$config_path_of_updated_code" &

echo ""
echo "🤖 : Sir, I have made a copy of the updated code at $updated_files_path."
echo ""
echo "🤖 : And I made the following changes to the configs.dart file in the updated code:"
echo ""
echo "- Removed commented and 'Development Url' lines related to DOMAIN_URL."
echo "- Set DOMAIN_URL to an empty string."
echo ""
echo "🤖 : The configs.dart file in the updated code has been modified."
echo ""

# Step 9: Make zips of full code and updated code separately
cd $HOME/Desktop
mkdir -p "$final_code_zip_name"
cd "$full_code_files_path"
zip -r "$full_code_dir_name.zip" .
mv "$full_code_dir_name.zip" "$HOME/Desktop/$final_code_zip_name"
cd "$updated_files_path"
zip -r "$updated_code_zip_name.zip" .
mv "$updated_code_zip_name.zip" "$HOME/Desktop/$final_code_zip_name"
cd "$HOME/Desktop/$final_code_zip_name"
zip -r "$final_code_zip_name.zip" .
mv "$final_code_zip_name.zip" "$HOME/Desktop"
cd $HOME/Desktop
rm -r code_zips  
echo "🤖 : Sir, I have created Final Zip $final_code_zip_name.zip at $HOME/Desktop"


# # Step 9: Make zips of full code and updated code separately
# echo "🤖 : Creating separate zip files for the full code, updated code, and the entire code zips directory..."

# # Open a new terminal to run zip commands
# gnome-terminal -- bash -c "cd '$HOME/Desktop' && zip -r '$full_code_dir_name.zip' '$full_code_files_path'; zip -r '$updated_code_zip_name.zip' '$updated_files_path'; zip -r '$final_code_zip_name.zip' '$HOME/Desktop/code_zips'; echo '🤖 : Zip files have been created.'; exec bash"

# # Provide a message in the current terminal
# echo "🤖 : Running zip commands in a separate terminal. Please wait..."
