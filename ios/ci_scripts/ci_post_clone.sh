#!/bin/sh

set -eu

cd "$CI_PRIMARY_REPOSITORY_PATH"

FLUTTER_VERSION="$(tr -d '[:space:]' < .flutter-version)"
FLUTTER_HOME="$HOME/flutter"

git clone \
  --branch "$FLUTTER_VERSION" \
  --depth 1 \
  https://github.com/flutter/flutter.git \
  "$FLUTTER_HOME"

export PATH="$FLUTTER_HOME/bin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE=1

flutter config --no-analytics
flutter precache --ios
flutter pub get

if ! command -v pod >/dev/null 2>&1; then
  brew install cocoapods
fi

cd ios
pod install
