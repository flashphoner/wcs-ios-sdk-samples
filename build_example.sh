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

rm -rf ~/Library/Developer/Xcode/DerivedData/*

rm -rf out-build
mkdir out-build

#install deps
pod install

#build and export
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -UseModernBuildSystem=NO -workspace 'WCSExample.xcworkspace' -scheme "TwoWayStreaming" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/TwoWayStreaming -archivePath out-build/TwoWayStreaming
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -allowProvisioningUpdates -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/TwoWayStreaming.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -UseModernBuildSystem=NO -workspace 'WCSExample.xcworkspace' -scheme "MediaDevices" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/MediaDevices -archivePath out-build/MediaDevices
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -allowProvisioningUpdates -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/MediaDevices.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -UseModernBuildSystem=NO -workspace 'WCSExample.xcworkspace' -scheme "Player" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/Player -archivePath out-build/Player
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -allowProvisioningUpdates -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/Player.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -UseModernBuildSystem=NO -workspace 'WCSExample.xcworkspace' -scheme "TwoPlayers" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/TwoPlayers -archivePath out-build/TwoPlayers
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -allowProvisioningUpdates -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/TwoPlayers.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -UseModernBuildSystem=NO -workspace 'WCSExample.xcworkspace' -scheme "Streamer" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/Streamer -archivePath out-build/Streamer
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -allowProvisioningUpdates -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/Streamer.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -UseModernBuildSystem=NO -workspace 'WCSExample.xcworkspace' -scheme "StreamRecording" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/StreamRecording -archivePath out-build/StreamRecording
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -allowProvisioningUpdates -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/StreamRecording.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -UseModernBuildSystem=NO -workspace 'WCSExample.xcworkspace' -scheme "Conference" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/Conference -archivePath out-build/Conference
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -allowProvisioningUpdates -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/Conference.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -UseModernBuildSystem=NO -workspace 'WCSExample.xcworkspace' -scheme "VideoChat" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/VideoChat -archivePath out-build/VideoChat
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -allowProvisioningUpdates -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/VideoChat.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -UseModernBuildSystem=NO -workspace 'WCSExample.xcworkspace' -scheme "PhoneMinVideo" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/PhoneMinVideo -archivePath out-build/PhoneMinVideo
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -allowProvisioningUpdates -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/PhoneMinVideo.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -UseModernBuildSystem=NO -workspace 'WCSExample.xcworkspace' -scheme "PhoneMin" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/PhoneMin -archivePath out-build/PhoneMin
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -allowProvisioningUpdates -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/PhoneMin.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -UseModernBuildSystem=NO -workspace 'WCSExample.xcworkspace' -scheme "ClickToCall" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/ClickToCall -archivePath out-build/ClickToCall
xcodebuild CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$1" -allowProvisioningUpdates -exportArchive -exportOptionsPlist Info.plist -archivePath out-build/ClickToCall.xcarchive -exportPath out-build

echo "Build complete"

