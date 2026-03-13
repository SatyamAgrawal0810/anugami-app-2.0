#!/bin/sh

# Fail the script if any command fails
set -e

# 1. Navigate to the root of your project
cd $CI_PRIMARY_REPOSITORY_PATH

# 2. Install Flutter (using depth 1 for speed)
if [ ! -d "$HOME/flutter" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
fi

# 3. Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"

# 4. CRITICAL: Pre-download iOS artifacts
flutter precache --ios

# 5. Get Flutter dependencies (generates Generated.xcconfig)
flutter pub get

# 6. Install CocoaPods (using brew if needed)
# Xcode Cloud has CocoaPods, but sometimes it needs a refresh
export HOMEBREW_NO_AUTO_UPDATE=1
brew install cocoapods

# 7. Rebuild the Pods environment
cd ios
rm -rf Pods
rm -rf Podfile.lock
pod install --repo-update

echo "✅ Environment preparation complete."
exit 0