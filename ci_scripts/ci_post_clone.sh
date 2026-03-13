#!/bin/bash

# 1. Get Flutter packages and create config files
flutter pub get

# 2. Setup iOS dependencies
cd ios
rm -rf Pods
rm -rf Podfile.lock
pod install
cd ..

# 3. Build the app
xcodebuild build -scheme Runner \
-workspace /Volumes/workspace/repository/ios/Runner.xcworkspace \
-destination generic/platform=iOS \
-derivedDataPath /Volumes/workspace/DerivedData \
CODE_SIGN_IDENTITY=- \
AD_HOC_CODE_SIGNING_ALLOWED=YES