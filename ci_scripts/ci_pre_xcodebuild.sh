#!/bin/sh
set -e

echo "Installing Flutter"

git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

flutter doctor

echo "Getting packages"
flutter pub get

echo "Installing pods"
cd ios
pod install
cd ..

echo "Generating iOS files"
flutter build ios --no-codesign