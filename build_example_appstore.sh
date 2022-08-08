#!/bin/sh

DEVELOPMENT_TEAM=$1
BUILD_NUMBER=$2
BUILD_COUNTER=$3

if [ -z $DEVELOPMENT_TEAM ]; then
  echo "No development team defined!"
  exit 1
fi

if [ -z $BUILD_NUMBER ]; then
  echo "No build number defined!"
  exit 1
fi

if [ -z $BUILD_COUNTER ]; then
  echo "No build counter defined!"
  exit 1
fi

# Prepare plist to build examples
cat << EOF > Info_ipa.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>method</key>
        <string>app-store</string>
        <key>teamID</key>
        <string>$DEVELOPMENT_TEAM</string>
        <key>compileBitcode</key>
        <false/>
        <key>uploadBitcode</key>
        <false/>
        <key>uploadSymbols</key>
        <false/>
</dict>
</plist>
EOF

rm -rf out-build
mkdir out-build

mv Podfile Podfile.public

# Prepare Podfile
cat << EOF > Podfile
platform :ios, '9.1'
use_frameworks!

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
      config.build_settings['ONLY_ACTIVE_ARCH'] = "YES"
      config.build_settings['VALID_ARCHS'] = "arm64"
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = "arm64 i386"
    end
  end
end

target 'TwoWayStreaming' do
  pod 'FPWCSApi2'
  pod 'FPWebRTC'
end

EOF

pod install

# Add build number as patch version
sed -i "" "s/<string>1.2<\/string>/<string>$BUILD_NUMBER.$BUILD_COUNTER<\/string>/g" WCSExample/TwoWayStreaming/Info.plist


xcodebuild CODE_SIGN_STYLE=Automatic -workspace 'WCSExample.xcworkspace' -scheme "TwoWayStreaming" -configuration="Release" clean archive OBJROOT=$(PWD)/out-build/TwoWayStreaming -archivePath out-build/TwoWayStreaming
xcodebuild -exportArchive -allowProvisioningUpdates -exportOptionsPlist Info_ipa.plist -archivePath out-build/TwoWayStreaming.xcarchive -exportPath out-build
