#!/bin/sh
set -e

echo "Installing Flutter"

git clone https://github.com/flutter/flutter.git --depth 1 -b stable
export PATH="$PATH:`pwd`/flutter/bin"

flutter doctor

echo "Fetching Flutter packages"
flutter pub get

echo "Generating iOS Flutter files"
flutter build ios --debug --no-codesign

echo "Installing CocoaPods"
cd ios
pod install --repo-update
cd ..