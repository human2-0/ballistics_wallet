#!/bin/sh

set -eu

cd "$CI_PRIMARY_REPOSITORY_PATH"

GENERATED_XCCONFIG="ios/Flutter/Generated.xcconfig"

BUILD_NAME="$(sed -nE 's/^version:[[:space:]]*([^+[:space:]]+).*/\1/p' pubspec.yaml | head -1)"
BUILD_NUMBER="${CI_BUILD_NUMBER:-}"

if [ -z "$BUILD_NAME" ]; then
  echo "Could not read FLUTTER_BUILD_NAME from pubspec.yaml" >&2
  exit 1
fi

if [ -z "$BUILD_NUMBER" ]; then
  BUILD_NUMBER="$(sed -nE 's/^version:[[:space:]]*[^+[:space:]]+\+([0-9]+).*/\1/p' pubspec.yaml | head -1)"
fi

if [ -z "$BUILD_NUMBER" ]; then
  echo "Could not determine FLUTTER_BUILD_NUMBER" >&2
  exit 1
fi

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "$GENERATED_XCCONFIG does not exist; ci_post_clone.sh must run flutter pub get first" >&2
  exit 1
fi

tmp_file="$(mktemp)"
awk -v build_name="$BUILD_NAME" -v build_number="$BUILD_NUMBER" '
  /^FLUTTER_BUILD_NAME=/ {
    print "FLUTTER_BUILD_NAME=" build_name
    seen_name = 1
    next
  }
  /^FLUTTER_BUILD_NUMBER=/ {
    print "FLUTTER_BUILD_NUMBER=" build_number
    seen_number = 1
    next
  }
  { print }
  END {
    if (!seen_name) {
      print "FLUTTER_BUILD_NAME=" build_name
    }
    if (!seen_number) {
      print "FLUTTER_BUILD_NUMBER=" build_number
    }
  }
' "$GENERATED_XCCONFIG" > "$tmp_file"
mv "$tmp_file" "$GENERATED_XCCONFIG"

echo "Configured Flutter iOS version $BUILD_NAME ($BUILD_NUMBER)"
