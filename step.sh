#!/bin/bash

# Fail the script if any command fails
set -e

# Retrieve the input values from the step
INFO_PLIST_PATH="${info_plist_path}"
BUNDLE_VERSION="${bundle_version}"

# Ensure that the info plist path is provided
if [ -z "$INFO_PLIST_PATH" ]; then
    echo "Error: Info.plist path is required."
    exit 1
fi

# Get the latest tag in the format x.x.x (ignore any suffix like -pre or -beta)
LAST_TAG=$(git describe --tags --abbrev=0 --match '*.*.*' 2>/dev/null)

if [ -z "$LAST_TAG" ]; then
    echo "No valid tag found. Make sure a tag with format x.x.x exists."
    exit 1
fi

# Extract only the x.x.x part from the tag (e.g., from 1.2.3-pre to 1.2.3)
NEW_SHORT_VERSION=$(echo "$LAST_TAG" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')

# If BUNDLE_VERSION is not manually provided, calculate it as the number of commits since the last tag
if [ -z "$BUNDLE_VERSION" ]; then
    # Count the number of commits since the last tag
    BUNDLE_VERSION=$(git rev-list "$LAST_TAG"..HEAD --count)
fi

echo "Using version $NEW_SHORT_VERSION and build number $BUNDLE_VERSION based on the latest tag and commit count."

# Check if the Info.plist file exists
if [ ! -f "$INFO_PLIST_PATH" ]; then
    echo "Info.plist not found at $INFO_PLIST_PATH"
    exit 1
fi

# Update CFBundleShortVersionString (e.g., 1.2.3)
echo "Updating CFBundleShortVersionString to $NEW_SHORT_VERSION"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_SHORT_VERSION" "$INFO_PLIST_PATH"

# Update CFBundleVersion (e.g., build number 45)
echo "Updating CFBundleVersion to $BUNDLE_VERSION"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "$INFO_PLIST_PATH"

echo "Updated Info.plist at $INFO_PLIST_PATH with CFBundleShortVersionString=$NEW_SHORT_VERSION and CFBundleVersion=$BUNDLE_VERSION"
