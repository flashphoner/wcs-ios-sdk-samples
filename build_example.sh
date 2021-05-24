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

# Prepare plist to build examples
cat << EOF > Info_ipa.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>method</key>
        <string>ad-hoc</string>
        <key>signingStyle</key>
        <string>manual</string>
        <key>teamID</key>
        <string>SXWV5Z47NK</string>
        <key>provisioningProfiles</key>
        <dict>
               <key>com.flashphoner.ios.TwoWayStreaming</key>
               <string>$2</string>
               <key>com.flashphoner.ios.MediaDevices</key>
               <string>$2</string>
               <key>com.flashphoner.ios.Player</key>
               <string>$2</string>
               <key>com.flashphoner.ios.TwoPlayers</key>
               <string>$2</string>
               <key>com.flashphoner.ios.Streamer</key>
               <string>$2</string>
               <key>com.flashphoner.ios.StreamRecording</key>
               <string>$2</string>
               <key>com.flashphoner.ios.Conference</key>
               <string>$2</string>
               <key>com.flashphoner.ios.VideoChat</key>
               <string>$2</string>
               <key>com.flashphoner.ios.PhoneMinVideo</key>
               <string>$2</string>
               <key>com.flashphoner.ios.PhoneMin</key>
               <string>$2</string>
               <key>com.flashphoner.ios.ClickToCall</key>
               <string>$2</string>
               <key>com.flashphoner.ios.GPUImageDemo</key>
               <string>$2</string>
               <key>com.flashphoner.ios.TwoWayStreamingSwift</key>
               <string>$2</string>
               <key>com.flashphoner.ios.MediaDevicesSwift</key>
               <string>$2</string>
               <key>com.flashphoner.ios.MCUClientSwift</key>
               <string>$2</string>
               <key>com.flashphoner.ios.ImageOverlaySwift</key>
               <string>$2</string>

        </dict>
</dict>
</plist>
EOF

rm -rf out-build
mkdir out-build

#install deps
pod install

#build and export
xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "TwoWayStreaming" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/TwoWayStreaming -archivePath out-build/TwoWayStreaming
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/TwoWayStreaming.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "MediaDevices" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/MediaDevices -archivePath out-build/MediaDevices
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/MediaDevices.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "Player" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/Player -archivePath out-build/Player
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/Player.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "TwoPlayers" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/TwoPlayers -archivePath out-build/TwoPlayers
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/TwoPlayers.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "Streamer" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/Streamer -archivePath out-build/Streamer
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/Streamer.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "StreamRecording" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/StreamRecording -archivePath out-build/StreamRecording
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/StreamRecording.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "Conference" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/Conference -archivePath out-build/Conference
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/Conference.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "VideoChat" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/VideoChat -archivePath out-build/VideoChat
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/VideoChat.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "PhoneMinVideo" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/PhoneMinVideo -archivePath out-build/PhoneMinVideo
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/PhoneMinVideo.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "PhoneMin" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/PhoneMin -archivePath out-build/PhoneMin
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/PhoneMin.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "ClickToCall" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/ClickToCall -archivePath out-build/ClickToCall
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/ClickToCall.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "GPUImageDemo" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/GPUImageDemo -archivePath out-build/GPUImageDemo
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/GPUImageDemo.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "TwoWayStreamingSwift" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/TwoWayStreamingSwift -archivePath out-build/TwoWayStreamingSwift
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/TwoWayStreamingSwift.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "MediaDevicesSwift" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/MediaDevicesSwift -archivePath out-build/MediaDevicesSwift
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/MediaDevicesSwift.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "MCUClientSwift" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/MCUClientSwift -archivePath out-build/MCUClientSwift
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/MCUClientSwift.xcarchive -exportPath out-build

xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "ImageOverlaySwift" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/ImageOverlaySwift -archivePath out-build/ImageOverlaySwift
xcodebuild -exportArchive -exportOptionsPlist Info_ipa.plist -archivePath out-build/ImageOverlaySwift.xcarchive -exportPath out-build


# Remove plist
rm -rf Info_ipa.plist

echo "Build complete"

