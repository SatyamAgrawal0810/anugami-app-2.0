#!/bin/sh

# 1. Install Flutter (Xcode Cloud doesn't have it by default)
cd $CI_PRIMARY_REPOSITORY_PATH
git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 2. Get your dependencies (from your pubspec.yaml)
flutter pub get

# 3. Install CocoaPods (for Firebase, Razorpay, etc.)
# Xcode Cloud has CocoaPods, but we need to run it in the ios folder
cd ios
pod install

exit 0