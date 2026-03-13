#!/bin/sh
set -e

echo "Installing Flutter"
git clone https://github.com/flutter/flutter.git --depth 1 -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version"
flutter --version

echo "Getting packages"
flutter pub get

echo "Cleaning project"
flutter clean

echo "Install CocoaPods"
cd ios
pod install --repo-update
cd ..

echo "Generate iOS build files"
flutter build ios --debug --no-codesign