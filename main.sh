#!/bin/bash

# Fetch and check out the correct branch from the CI project repo
cd "$CI_PROJECT_DIR" || exit 1

# Fetch the latest updates from the remote repository
git fetch origin --unshallow
git fetch --all --tags

# Step 1: Print available branches
echo "Available branches:"
git branch -a  # Show all branches
echo "Available remote branches with their SHA:"
git for-each-ref --format='%(refname:short) %(objectname:short)' refs/remotes/

# Function to check if input is a branch name or commit SHA
is_branch_name() {
    git show-ref --verify --quiet "refs/heads/$1"
}

# Function to check if input is a commit SHA
is_commit_sha() {
    git cat-file -e "$1^{commit}" 2>/dev/null
}

# Determine if SOURCE_COMMIT and TARGET_COMMIT are branches or SHA
if is_branch_name "$TARGET_COMMIT"; then
    echo "$TARGET_COMMIT is a branch"
    git checkout "$TARGET_COMMIT"
    git pull origin "$TARGET_COMMIT"
elif is_commit_sha "$TARGET_COMMIT"; then
    echo "$TARGET_COMMIT is a commit SHA"
    git checkout "$TARGET_COMMIT"
else
    echo "Error: $TARGET_COMMIT is neither a valid branch nor a commit SHA."
    exit 1
fi

# Pull the latest changes from the branch if it's a branch name
if is_branch_name "$TARGET_COMMIT"; then
    git pull origin "$TARGET_COMMIT"
fi

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
git fetch --all --tags
git branch -a
echo "Available remote branches with their SHA:"
git for-each-ref --format='%(refname:short) %(objectname:short)' refs/remotes/
echo "==================Available branches=========END=============="

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
