#!/bin/sh

# Get location of the script itself .. thanks SO ! http://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
PROJECT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

CONFIGURATION="Release"
PROVISIONING_PROFILE=$1

rm -rf out-build
mkdir out-build

#install deps
pod install

#build and export
xcodebuild -workspace 'WCSExample.xcworkspace' -scheme "TwoWayStreaming" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/TwoWayStreaming -archivePath out-build/TwoWayStreaming
xcodebuild -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/TwoWayStreaming.xcarchive -exportPath out-build

xcodebuild -workspace 'WCSExample.xcworkspace' -scheme "MediaDevices" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/MediaDevices -archivePath out-build/MediaDevices
xcodebuild -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/MediaDevices.xcarchive -exportPath out-build

xcodebuild -workspace 'WCSExample.xcworkspace' -scheme "Player" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/Player -archivePath out-build/Player
xcodebuild -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/Player.xcarchive -exportPath out-build

xcodebuild -workspace 'WCSExample.xcworkspace' -scheme "TwoPlayers" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/TwoPlayers -archivePath out-build/TwoPlayers
xcodebuild -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/TwoPlayers.xcarchive -exportPath out-build


echo "Build complete"

