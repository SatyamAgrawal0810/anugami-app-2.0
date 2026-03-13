#!/bin/sh
set -e

echo "Installing Flutter"
git clone https://github.com/flutter/flutter.git --depth 1 -b stable
export PATH="$PATH:`pwd`/flutter/bin"

flutter --version

echo "Install packages"
flutter pub get

echo "Prepare iOS"
cd ios
pod install --repo-update
cd ..

echo "Generate Flutter iOS config"
flutter build ios --no-codesign