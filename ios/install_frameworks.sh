#!/usr/bin/env bash
#
# Resolve and vendor the exact iOS AdMob and UMP versions pinned in Podfile.
#
# The mediation adapters and their network SDKs live in the separate
# ti.admob.unified.mediation module; refresh those with
# mediation/ios/install_frameworks.sh.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$MODULE_ROOT"
MODULE_ARG="."
PLATFORM_DIR="$SCRIPT_DIR/platform"
CHECKSUM_FILE="$SCRIPT_DIR/framework-checksums.sha256"
TEMP_DIR="$(mktemp -d /tmp/ti-admob-frameworks.XXXXXX)"
STAGED_PLATFORM="$TEMP_DIR/platform"
PREVIOUS_PLATFORM="$TEMP_DIR/previous-platform"

cleanup() {
  chmod -R u+w "$TEMP_DIR" 2>/dev/null || true
  command rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT

tree_sha256() {
  framework_path="$1"
  (
    cd "$framework_path"
    find . -type f -print0 |
      LC_ALL=C sort -z |
      xargs -0 shasum -a 256
  ) | shasum -a 256 | awk '{print $1}'
}

(
  cd "$SCRIPT_DIR"
  pod install --repo-update
)

mkdir -p "$STAGED_PLATFORM"

while IFS='|' read -r source_path framework_name; do
  source_framework="$SCRIPT_DIR/$source_path"
  test -d "$source_framework"
  cp -R "$source_framework" "$STAGED_PLATFORM/$framework_name"
done <<'FRAMEWORKS'
Pods/Google-Mobile-Ads-SDK/Frameworks/GoogleMobileAdsFramework/GoogleMobileAds.xcframework|GoogleMobileAds.xcframework
Pods/GoogleUserMessagingPlatform/Frameworks/Release/UserMessagingPlatform.xcframework|UserMessagingPlatform.xcframework
FRAMEWORKS

# Google's static GMA and UMP archives are published with executable bits on
# every file. Normalize both trees so refreshes do not create permission churn
# in Git.
find "$STAGED_PLATFORM/GoogleMobileAds.xcframework" \
  "$STAGED_PLATFORM/UserMessagingPlatform.xcframework" \
  -type f -exec chmod 644 {} +

while read -r expected_sha256 framework_name; do
  [ -n "$framework_name" ] || continue
  framework_path="$STAGED_PLATFORM/$framework_name"
  test -d "$framework_path"
  actual_sha256="$(tree_sha256 "$framework_path")"
  if [ "$actual_sha256" != "$expected_sha256" ]; then
    echo "$framework_name checksum mismatch: $actual_sha256" >&2
    exit 1
  fi
done < "$CHECKSUM_FILE"

if [ -d "$PLATFORM_DIR" ]; then
  mv "$PLATFORM_DIR" "$PREVIOUS_PLATFORM"
fi
mv "$STAGED_PLATFORM" "$PLATFORM_DIR"

if ! "$REPO_ROOT/scripts/prepare-build.sh" "$MODULE_ARG"; then
  mv "$PLATFORM_DIR" "$TEMP_DIR/failed-platform"
  if [ -d "$PREVIOUS_PLATFORM" ]; then
    mv "$PREVIOUS_PLATFORM" "$PLATFORM_DIR"
  fi
  exit 1
fi

echo "Vendored Google Mobile Ads and UMP."
