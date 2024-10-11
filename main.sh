#!/bin/bash

# Fetch and check out the correct branch from the CI project repo
cd "$CI_PROJECT_DIR" || exit 1

# Fetch the latest updates from the remote repository
git fetch origin

# Fetch all branches and tags from the remote repository
git fetch --all

# List all remote branches with their corresponding SHA
echo "Available remote branches with their SHA:"
git for-each-ref --format='%(refname:short) %(objectname:short)' refs/remotes/

# Step 1: Print available branches
echo "Available branches:"
git branch -a  # Show all branches
echo "Available remote branches with their SHA:"
git for-each-ref --format='%(refname:short) %(objectname:short)' refs/remotes/

# Check out the target branch
if git show-ref --verify --quiet refs/remotes/origin/$TARGET_COMMIT; then
    # Check out the specific branch or commit (assuming 'target_branch' is set)
    git checkout "$TARGET_COMMIT" || {
        echo "Error: Could not checkout branch '$TARGET_COMMIT'. Exiting."
        exit 1
    }
else
    echo "Branch '$TARGET_COMMIT' does not exist."
    exit 1
fi

# Checkout the specific branch or commit (assuming 'target_commit' contains the branch or commit hash)
git checkout "$TARGET_COMMIT" || {
    echo "Error: Could not checkout commit/branch '$TARGET_COMMIT'. Exiting."
    exit 1
}

# Pull the latest changes from the branch (if target_commit is a branch name)
git pull origin "$TARGET_COMMIT" || {
    echo "Error: Could not pull latest changes from '$TARGET_COMMIT'. Exiting."
    exit 1
}

# Create directory for the full code
mkdir -p "$CI_PROJECT_DIR/code_zips/$FULL_CODE_DIR_NAME"

# Define additional items to exclude
MANUAL_EXCLUSIONS="android/local.properties android/app/release android/app/build pubspec.lock *.lock *.rest *.iml ios/Pods ios/Podfile.lock"


# Use rsync to copy the full code while excluding all hidden files/folders except .gitignore and .gitkeep, and applying the manual exclusions
rsync -av \
    --exclude='.*' \
    --include='.gitignore' \
    --include='.gitkeep' \
    --exclude={$manual_exclusions} \
    . "$CI_PROJECT_DIR/code_zips/$full_code_dir_name"

# Verify that excluded items were not copied and remove them if found
for excluded_item in $manual_exclusions; do
    find "$CI_PROJECT_DIR/code_zips/$full_code_dir_name" -name "$excluded_item" -exec rm -rf {} \;
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

# Verify that excluded items were not copied in updated files and remove them if found
for excluded_item in $manual_exclusions; do
    find "$updated_files_path" -name "$excluded_item" -exec rm -rf {} \;
done

# Modify the configs.dart file for the updated code
config_path_of_updated_code="$updated_files_path/lib/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$config_path_of_updated_code"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$config_path_of_updated_code"

echo "Changes made to configs.dart in the updated code."