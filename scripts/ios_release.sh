#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-build}"

case "$MODE" in
  build|release|upload) ;;
  *)
    echo "Usage: $0 [build|release|upload]" >&2
    exit 2
    ;;
esac

default_build_number() {
  # CFBundleVersion supports up to three numeric components. This produces a
  # monotonically increasing, minute-unique value such as 2365.14.7.
  local now epoch_2020 days hour minute
  now="$(date -u +%s)"
  epoch_2020=1577836800
  days="$(( (now - epoch_2020) / 86400 ))"
  hour="$((10#$(date -u +%H)))"
  minute="$((10#$(date -u +%M)))"
  printf '%d.%d.%d\n' "$days" "$hour" "$minute"
}

find_ipa() {
  local ipa
  ipa="$(find build/ios/ipa -maxdepth 1 -type f -name '*.ipa' -print -quit 2>/dev/null || true)"
  if [[ -z "$ipa" ]]; then
    echo "No IPA found in build/ios/ipa. Run '$0 build' first." >&2
    exit 1
  fi
  printf '%s\n' "$ipa"
}

upload_ipa() {
  local ipa="$1"
  : "${APP_STORE_CONNECT_API_KEY_ID:?Set APP_STORE_CONNECT_API_KEY_ID}"
  : "${APP_STORE_CONNECT_API_ISSUER_ID:?Set APP_STORE_CONNECT_API_ISSUER_ID}"

  if [[ "${IOS_VALIDATE_BEFORE_UPLOAD:-0}" == "1" ]]; then
    xcrun altool \
      --validate-app \
      --type ios \
      --file "$ipa" \
      --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
      --apiIssuer "$APP_STORE_CONNECT_API_ISSUER_ID"
  fi

  xcrun altool \
    --upload-app \
    --type ios \
    --file "$ipa" \
    --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
    --apiIssuer "$APP_STORE_CONNECT_API_ISSUER_ID"
}

if [[ "$MODE" == "upload" ]]; then
  upload_ipa "$(find_ipa)"
  exit 0
fi

BUILD_NAME="${IOS_BUILD_NAME:-$(sed -nE 's/^version:[[:space:]]*([^+[:space:]]+).*/\1/p' pubspec.yaml | head -1)}"
BUILD_NUMBER="${IOS_BUILD_NUMBER:-$(default_build_number)}"

if [[ -z "$BUILD_NAME" ]]; then
  echo "Could not read the version from pubspec.yaml; set IOS_BUILD_NAME." >&2
  exit 1
fi

echo "Building iOS $BUILD_NAME ($BUILD_NUMBER)"

build_args=(
  build ipa
  --release
  --build-name "$BUILD_NAME"
  --build-number "$BUILD_NUMBER"
)

if [[ -n "${IOS_EXPORT_OPTIONS_PLIST:-}" ]]; then
  build_args+=(--export-options-plist "$IOS_EXPORT_OPTIONS_PLIST")
fi

flutter "${build_args[@]}"

IPA_PATH="$(find_ipa)"
echo "Created $IPA_PATH"

if [[ "$MODE" == "release" ]]; then
  upload_ipa "$IPA_PATH"
fi
