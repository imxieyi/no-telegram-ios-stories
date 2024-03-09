#!/bin/bash
set -e

trap "exit" INT

SCRIPT_PATH=$(realpath $(dirname $0))
BUILD_CONFIG="$SCRIPT_PATH/release_config.json"
CODESIGNING_INFO="$SCRIPT_PATH/codesigning"
REQUIRED_PATCH="$SCRIPT_PATH/0001-Get-rid-of-stories.patch"
OPTIONAL_PATCH="$SCRIPT_PATH/0002-Change-app-name.patch"

source "$SCRIPT_PATH/env.sh"

export PATH="/opt/homebrew/bin:$PATH"

cd $TG_IOS_ROOT
git reset --hard
git clean . -dfX
git pull

# Check version
OLD_VERSION=""
if [[ -f "$SCRIPT_PATH/version" ]]; then
    OLD_VERSION=$(< "$SCRIPT_PATH/version")
fi
NEW_VERSION=$(jq -r .app "$TG_IOS_ROOT/versions.json")

if [[ "$OLD_VERSION" == "$NEW_VERSION" ]]; then
    echo "No new version"
    exit
fi
echo "Version updated: $OLD_VERSION -> $NEW_VERSION"

git submodule update --init --recursive
git apply $REQUIRED_PATCH

if [[ -f "$OPTIONAL_PATCH" ]]; then
    git apply $OPTIONAL_PATCH
fi

# Override Xcode version
XCODE_VERSION="$(xcodebuild -version | head -1 | awk -F ' ' '{print $2}')"
echo "Xcode version: $XCODE_VERSION"
jq ".xcode = \"$XCODE_VERSION\"" "$TG_IOS_ROOT/versions.json" > "$TG_IOS_ROOT/temp.json"
mv "$TG_IOS_ROOT/temp.json" "$TG_IOS_ROOT/versions.json"

# Clear bazel cache if Xcode is updated
OLD_XCODE_VERSION=""
if [[ -f "$SCRIPT_PATH/xcode_version" ]]; then
    OLD_XCODE_VERSION=$(< "$SCRIPT_PATH/xcode_version")
fi
if [[ "$OLD_XCODE_VERSION" != "$XCODE_VERSION" ]]; then
    echo "Xcode version updated: $OLD_XCODE_VERSION -> $XCODE_VERSION"
    bazel clean --expunge
fi

# Get rid of -warnings-as-errors
find "$TG_IOS_ROOT" -type f -name BUILD -exec sed -i -e 's/-warnings-as-errors//g' {} \;

if [[ -d "$SCRIPT_PATH/DefaultAppIcon.xcassets" ]]; then
    echo "Replace app icon"
    rm -fr "$TG_IOS_ROOT/Telegram/Telegram-iOS/DefaultAppIcon.xcassets"
    cp -r "$SCRIPT_PATH/DefaultAppIcon.xcassets" "$TG_IOS_ROOT/Telegram/Telegram-iOS/DefaultAppIcon.xcassets"
fi

# Increase build number
BUILD_NUM=100000
if [[ -f "$SCRIPT_PATH/build_num" ]]; then
    BUILD_NUM=$(< "$SCRIPT_PATH/build_num")
fi
BUILD_NUM=$(($BUILD_NUM + 1))
echo $BUILD_NUM > "$SCRIPT_PATH/build_num"

echo "Build number:" $BUILD_NUM

python3 build-system/Make/Make.py --cacheDir=$BAZEL_CACHE build --configurationPath=$BUILD_CONFIG --codesigningInformationPath=$CODESIGNING_INFO --buildNumber=$BUILD_NUM --configuration=release_arm64

echo "Uploading artifact"

xcrun altool --upload-app --type ios -f $TG_IOS_ROOT/bazel-bin/Telegram/Telegram.ipa -u $APPLE_ID -p $APPLE_ID_PASSWORD

# Save version
echo $NEW_VERSION > "$SCRIPT_PATH/version"
echo $XCODE_VERSION > "$SCRIPT_PATH/xcode_version"

echo "Completed"
