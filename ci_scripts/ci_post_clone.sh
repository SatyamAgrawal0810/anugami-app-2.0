#!/bin/sh
set -e

echo "Installing Flutter"
git clone https://github.com/flutter/flutter.git --depth 1 -b stable
export PATH="$PATH:`pwd`/flutter/bin"

flutter --version

echo "Installing dependencies"
flutter pub get

echo "Preparing iOS project"
cd ios
pod install --repo-update
cd ..