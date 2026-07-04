#!/bin/sh

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PUBSPEC="$ROOT_DIR/pubspec.yaml"
GENERATED_XCCONFIG="$ROOT_DIR/ios/Flutter/Generated.xcconfig"

version_line="$(sed -nE 's/^version:[[:space:]]*([^[:space:]]+).*/\1/p' "$PUBSPEC" | head -1)"
build_name="${version_line%%+*}"

case "$version_line" in
  *+[0-9]*) build_number="${version_line##*+}" ;;
  *)
    echo "error: Expected a numeric Flutter build number in $PUBSPEC (for example: version: 1.9.2+1)" >&2
    exit 1
    ;;
esac

case "$build_number" in
  ''|*[!0-9]*)
    echo "error: Flutter build number must be a positive integer: $build_number" >&2
    exit 1
    ;;
esac

next_build_number="$((build_number + 1))"
tmp_pubspec="$(mktemp "${TMPDIR:-/tmp}/ballistics-pubspec.XXXXXX")"
trap 'rm -f "$tmp_pubspec" "${tmp_xcconfig:-}"' EXIT HUP INT TERM

awk -v version="$build_name+$next_build_number" '
  /^version:[[:space:]]*/ && !updated {
    print "version: " version
    updated = 1
    next
  }
  { print }
' "$PUBSPEC" > "$tmp_pubspec"
mv "$tmp_pubspec" "$PUBSPEC"

if [ -f "$GENERATED_XCCONFIG" ]; then
  tmp_xcconfig="$(mktemp "${TMPDIR:-/tmp}/ballistics-xcconfig.XXXXXX")"
  awk -v build_name="$build_name" -v build_number="$next_build_number" '
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
      if (!seen_name) print "FLUTTER_BUILD_NAME=" build_name
      if (!seen_number) print "FLUTTER_BUILD_NUMBER=" build_number
    }
  ' "$GENERATED_XCCONFIG" > "$tmp_xcconfig"
  mv "$tmp_xcconfig" "$GENERATED_XCCONFIG"
fi

echo "Incremented iOS archive version to $build_name ($next_build_number)"
