# Step 3: Checkout and create a copy of the latest code from the specified target commit
cd "$project_path" || exit 1

# Fetch the latest updates from the remote repository
git fetch origin

# Checkout the specific branch or commit (assuming 'target_commit' contains the branch or commit hash)
git checkout "$target_commit" || {
    echo "Error: Could not checkout commit/branch '$target_commit'. Exiting."
    exit 1
}

# Pull the latest changes from the branch (if target_commit is a branch name)
git pull origin "$target_commit" || {
    echo "Error: Could not pull latest changes from '$target_commit'. Exiting."
    exit 1
}

# Create directory for the full code
mkdir -p "$CI_PROJECT_DIR/code_zips/$full_code_dir_name"

# Define additional items to exclude
manual_exclusions="android/local.properties android/app/release android/app/build pubspec.lock *.lock *.rest *.iml ios/Pods ios/Podfile.lock"

# Use rsync to copy the full code while excluding all hidden files/folders except .gitignore and .gitkeep, and applying the manual exclusions
rsync -av \
    --exclude='.*' \
    --include='.gitignore' \
    --include='.gitkeep' \
    --exclude={$manual_exclusions} \
    . "$CI_PROJECT_DIR/code_zips/$full_code_dir_name"

# Verify that excluded items were not copied
for excluded_item in $manual_exclusions; do
    if [ -e "$CI_PROJECT_DIR/code_zips/$full_code_dir_name/$excluded_item" ]; then
        echo "Error: Excluded item '$excluded_item' found in the copied directory."
        exit 1
    fi
done

# Modify the configs.dart file
config_path_of_full_code_dir="$CI_PROJECT_DIR/code_zips/$full_code_dir_name/lib/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$config_path_of_full_code_dir"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$config_path_of_full_code_dir"

echo "Copy of the latest code created from commit/branch '$target_commit' and changes made to configs.dart."

# Step 4: Create updated code directory
mkdir -p "$updated_files_path"
updated_files=$(git diff --name-only "$source_commit" "$target_commit")

# Use rsync to copy only the updated files while excluding all hidden files/folders except .gitignore and .gitkeep, and applying the manual exclusions
for file in $updated_files; do
    rsync -av \
        --exclude='.*' \
        --include='.gitignore' \
        --include='.gitkeep' \
        --exclude={$manual_exclusions} \
        "$file" "$updated_files_path/$(dirname "$file")"
done

# Verify that excluded items were not copied in updated files
for excluded_item in $manual_exclusions; do
    if [ -e "$updated_files_path/$excluded_item" ]; then
        echo "Error: Excluded item '$excluded_item' found in the updated files directory."
        exit 1
    fi
done

# Modify the configs.dart file for the updated code
config_path_of_updated_code="$updated_files_path/lib/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$config_path_of_updated_code"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$config_path_of_updated_code"

echo "Changes made to configs.dart in the updated code."
