#!/bin/sh
set -e

echo "Install Flutter"
git clone https://github.com/flutter/flutter.git --depth 1 -b stable
export PATH="$PATH:`pwd`/flutter/bin"

flutter --version

echo "Clean project"
flutter clean

echo "Get dependencies"
flutter pub get

echo "Install CocoaPods"
cd ios
pod install --repo-update
cd ..

echo "Generate iOS build files"
flutter build ios --debug --no-codesign