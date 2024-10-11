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
    --exclude={$MANUAL_EXCLUSIONS} \
    . "$CI_PROJECT_DIR/code_zips/$FULL_CODE_DIR_NAME"

# Verify that excluded items were not copied
for excluded_item in $MANUAL_EXCLUSIONS; do
    if [ -e "$CI_PROJECT_DIR/code_zips/$FULL_CODE_DIR_NAME/$excluded_item" ]; then
        echo "Error: Excluded item '$excluded_item' found in the copied directory."
        exit 1
    fi
done

# Modify the configs.dart file
CONFIG_PATH_OF_FULL_CODE_DIR="$CI_PROJECT_DIR/code_zips/$FULL_CODE_DIR_NAME/lib/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$CONFIG_PATH_OF_FULL_CODE_DIR"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$CONFIG_PATH_OF_FULL_CODE_DIR"

echo "Copy of the latest code created from commit/branch '$TARGET_COMMIT' and changes made to configs.dart."

# Step 4: Create updated code directory
mkdir -p "$updated_files_path"
updated_files=$(git diff --name-only "$SOURCE_COMMIT" "$TARGET_COMMIT")

# Use rsync to copy only the updated files while excluding all hidden files/folders except .gitignore and .gitkeep, and applying the manual exclusions
for file in $updated_files; do
    # Ensure that the file exists before attempting to rsync
    if [ -e "$file" ]; then
        rsync -av \
            --exclude='.*' \
            --include='.gitignore' \
            --include='.gitkeep' \
            --exclude={$MANUAL_EXCLUSIONS} \
            "$file" "$updated_files_path/$(dirname "$file")"
    else
        echo "Warning: Updated file '$file' does not exist."
    fi
done

# Verify that excluded items were not copied in updated files
for excluded_item in $MANUAL_EXCLUSIONS; do
    if [ -e "$updated_files_path/$excluded_item" ]; then
        echo "Error: Excluded item '$excluded_item' found in the updated files directory."
        exit 1
    fi
done

# Modify the configs.dart file for the updated code
CONFIG_PATH_OF_UPDATED_CODE="$updated_files_path/lib/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$CONFIG_PATH_OF_UPDATED_CODE"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$CONFIG_PATH_OF_UPDATED_CODE"

echo "Changes made to configs.dart in the updated code."
