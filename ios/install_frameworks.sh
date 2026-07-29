#!/usr/bin/env bash
#
# Refresh the two vendored Google XCFrameworks from official downloads.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLATFORM_DIR="$SCRIPT_DIR/platform"
TEMP_DIR="$(mktemp -d /tmp/ti-admob-frameworks.XXXXXX)"

GMA_URL="https://dl.google.com/googleadmobadssdk/googlemobileadssdkios.zip"
GMA_SHA256="cc971f9c5e197bba82262424c7b5abcf8d7b895bfc8e59d474af696f28bebd59"
UMP_URL="https://dl.google.com/googleadmobadssdk/googleusermessagingplatform.zip"
UMP_SHA256="02b6b1925be8a6cfc294478c1a6bb1dd4de70cd9e4f31cbbfb789ab4de7b2955"

cleanup() {
  chmod -R u+w "$TEMP_DIR" 2>/dev/null || true
  command rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT

mkdir -p "$PLATFORM_DIR"

curl --fail --location --silent --show-error "$GMA_URL" \
  --output "$TEMP_DIR/googlemobileadssdkios.zip"
curl --fail --location --silent --show-error "$UMP_URL" \
  --output "$TEMP_DIR/googleusermessagingplatform.zip"

printf '%s  %s\n' "$GMA_SHA256" "$TEMP_DIR/googlemobileadssdkios.zip" \
  | shasum -a 256 -c -
printf '%s  %s\n' "$UMP_SHA256" "$TEMP_DIR/googleusermessagingplatform.zip" \
  | shasum -a 256 -c -

unzip -q "$TEMP_DIR/googlemobileadssdkios.zip" -d "$TEMP_DIR/gma"
unzip -q "$TEMP_DIR/googleusermessagingplatform.zip" -d "$TEMP_DIR/ump"

GMA_SOURCE="$TEMP_DIR/gma/GoogleMobileAdsSdkiOS-13.7.0/GoogleMobileAds.xcframework"
UMP_SOURCE="$TEMP_DIR/ump/UserMessagingPlatformSdkIos-3.1.0/UserMessagingPlatform.xcframework"

test -d "$GMA_SOURCE"
test -d "$UMP_SOURCE"

for framework_name in GoogleMobileAds.xcframework UserMessagingPlatform.xcframework; do
  destination="$PLATFORM_DIR/$framework_name"
  replacement="$PLATFORM_DIR/.replacement-$framework_name"
  previous="$TEMP_DIR/previous-$framework_name"

  if [ "$framework_name" = "GoogleMobileAds.xcframework" ]; then
    source_framework="$GMA_SOURCE"
  else
    source_framework="$UMP_SOURCE"
  fi

  cp -R "$source_framework" "$replacement"
  if [ -e "$destination" ]; then
    mv "$destination" "$previous"
  fi
  mv "$replacement" "$destination"
done

"$MODULE_ROOT/scripts/prepare-build.sh"
"$MODULE_ROOT/scripts/verify-artifacts.sh"

echo "GoogleMobileAds 13.7.0 and UserMessagingPlatform 3.1.0 are ready."
