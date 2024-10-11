#!/bin/bash

# Fetch and check out the correct branch from the CI project repo
cd "$CI_PROJECT_DIR" || exit 1

# Fetch the latest updates from the remote repository
git fetch origin

# Fetch all branches and tags from the remote repository
git fetch --all

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

# Checkout the specific branch or commit (assuming 'TARGET_COMMIT' contains the branch or commit hash)
git checkout "$TARGET_COMMIT" || {
    echo "Error: Could not checkout commit/branch '$TARGET_COMMIT'. Exiting."
    exit 1
}

# Pull the latest changes from the branch (if TARGET_COMMIT is a branch name)
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

# Verify that excluded items were not copied and remove them if found
for excluded_item in $MANUAL_EXCLUSIONS; do
    find "$CI_PROJECT_DIR/code_zips/$FULL_CODE_DIR_NAME" -name "$excluded_item" -exec rm -rf {} \;
done

# Modify the configs.dart file
config_path_of_full_code_dir="$CI_PROJECT_DIR/code_zips/$FULL_CODE_DIR_NAME/lib/configs.dart"
sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$config_path_of_full_code_dir"
sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$config_path_of_full_code_dir"

echo "Copy of the latest code created from commit/branch '$TARGET_COMMIT' and changes made to configs.dart."
echo "==================Available branches=========START=============="
# Fetch all branches and tags from the remote repository
git fetch --all
git branch -a  # Show all branches
echo "Available remote branches with their SHA:"
git for-each-ref --format='%(refname:short) %(objectname:short)' refs/remotes/
echo "==================Available branches=========END=============="
echo "-------------------"
# Ensure all branches are fetched
git fetch origin --unshallow  # Fetch full history if a shallow clone was used
git fetch origin "$SOURCE_COMMIT" "$TARGET_COMMIT"  # Ensure both 'main' and 'dev' are fetched
echo "-------------------"
git diff --name-only "$SOURCE_COMMIT" "$TARGET_COMMIT"
echo "-------------------"
# Step 4: Create updated code directory only if there are changes
updated_files=$(git diff --name-only "$SOURCE_COMMIT" "$TARGET_COMMIT")

if [ -n "$updated_files" ]; then
    echo "Updated files found. Proceeding to copy them."

    mkdir -p "$UPDATED_CODE_ZIP_NAME"

    # Use rsync to copy only the updated files while excluding all hidden files/folders except .gitignore and .gitkeep, and applying the manual exclusions
    for file in $updated_files; do
        rsync -av \
            --exclude='.*' \
            --include='.gitignore' \
            --include='.gitkeep' \
            --exclude={$MANUAL_EXCLUSIONS} \
            "$file" "$UPDATED_CODE_ZIP_NAME/$(dirname "$file")"
    done

    # Verify that excluded items were not copied in updated files and remove them if found
    for excluded_item in $MANUAL_EXCLUSIONS; do
        find "$UPDATED_CODE_ZIP_NAME" -name "$excluded_item" -exec rm -rf {} \;
    done

    # Modify the configs.dart file for the updated code
    config_path_of_updated_code="$UPDATED_CODE_ZIP_NAME/lib/configs.dart"
    sed -i -e '/\/\/.*const.*DOMAIN_URL.*=/d' -e '/Development Url/d' "$config_path_of_updated_code"
    sed -i 's/^const.*DOMAIN_URL.*=.*https:\/\/.*/const DOMAIN_URL = "";/' "$config_path_of_updated_code"

    echo "Changes made to configs.dart in the updated code."

else
    echo "No updated files found between '$SOURCE_COMMIT' and '$TARGET_COMMIT'. Skipping updated code directory creation."
fi
