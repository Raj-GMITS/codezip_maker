#!/bin/bash

full_code_dir_name=$FULL_CODE_DIR_NAME
updated_code_zip_name=$UPDATED_CODE_ZIP_NAME
final_code_zip_name=$FINAL_CODE_ZIP_NAME
full_code_files_path="$CI_PROJECT_DIR/code_zips/$full_code_dir_name"
updated_files_path="$CI_PROJECT_DIR/code_zips/$updated_code_zip_name"

# Step 3: Create a copy of the latest code
cd "$CI_PROJECT_DIR" || exit 1
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

zip -r "$full_code_dir_name.zip" "$full_code_files_path"

# # Open the modified configs.dart file with gedit
# gedit "$config_path_of_full_code_dir" &

# Add comments to indicate changes made to the configs.dart file
echo ""
echo "🤖 : Sir, I have made a copy of the latest code at $CI_PROJECT_DIR/code_zips/$full_code_dir_name."
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
updated_files=$UPDATED_FILES_DIFF

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
zip -r "$updated_code_zip_name.zip" "$updated_files_path"
echo "Updated files have been copied to: $updated_files_path"

# Modify the configs.dart file for the updated code
config_path_of_updated_code="$updated_files_path/lib/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$config_path_of_updated_code"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$config_path_of_updated_code"
config_path_of_updated_code="$updated_files_path/lib/utils/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$config_path_of_updated_code"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$config_path_of_updated_code"

echo "Changes made to configs.dart in the updated code."


# Step 5: Open updated files directory in the terminal and execute 'tree'
# echo "Opening terminal with updated files directory..."
# gnome-terminal -- bash -c "cd '$updated_files_path' && tree; exec bash"

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
# cd $CI_PROJECT_DIR
# mkdir -p "$final_code_zip_name"
# cd "$full_code_files_path"
# zip -r "$full_code_dir_name.zip" .
# mv "$full_code_dir_name.zip" "$CI_PROJECT_DIR/$final_code_zip_name"
# cd "$updated_files_path"
# zip -r "$updated_code_zip_name.zip" .
# mv "$updated_code_zip_name.zip" "$CI_PROJECT_DIR/$final_code_zip_name"
# cd "$CI_PROJECT_DIR/$final_code_zip_name"
# zip -r "$final_code_zip_name.zip" .
# mv "$final_code_zip_name.zip" "$CI_PROJECT_DIR"
# cd $CI_PROJECT_DIR
# echo "🤖 : Sir, I have created Final Zip $final_code_zip_name.zip at $CI_PROJECT_DIR"