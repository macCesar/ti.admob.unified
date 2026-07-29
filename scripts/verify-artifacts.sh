#!/usr/bin/env bash
#
# Fail before packaging if ios/platform contains undeclared or stale content.
#
set -euo pipefail

MODULE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLATFORM_DIR="$MODULE_ROOT/ios/platform"
GMA_TREE_SHA256="86620aa1581fd67a513cac90582415fcb320a11f7d9e2cd7484b198760d9a188"
UMP_TREE_SHA256="a9817dd1b5288b6c8c6858e0a689ffd7af0d7ad85cc51628256cbd1ad93f5fdc"

tree_sha256() {
  framework_path="$1"
  (
    cd "$framework_path"
    find . -type f -print0 |
      LC_ALL=C sort -z |
      xargs -0 shasum -a 256
  ) | shasum -a 256 | awk '{print $1}'
}

if [ ! -d "$PLATFORM_DIR" ]; then
  echo "Missing ios/platform directory." >&2
  exit 1
fi

unexpected_frameworks=""
for framework in "$PLATFORM_DIR"/*.xcframework; do
  [ -e "$framework" ] || continue
  framework_name="$(basename "$framework")"
  case "$framework_name" in
    GoogleMobileAds.xcframework|UserMessagingPlatform.xcframework)
      ;;
    *)
      unexpected_frameworks="${unexpected_frameworks}${framework_name}\n"
      ;;
  esac
done

for required in GoogleMobileAds.xcframework UserMessagingPlatform.xcframework; do
  if [ ! -d "$PLATFORM_DIR/$required" ]; then
    echo "Missing declared framework: $required" >&2
    exit 1
  fi
done

stale_files="$(find "$PLATFORM_DIR" \( -name '*.old*' -o -name '.DS_Store' \) -print)"
if [ -n "$stale_files" ]; then
  echo "Stale files would be packaged:" >&2
  printf '%s\n' "$stale_files" >&2
  exit 1
fi

if [ -n "$unexpected_frameworks" ]; then
  echo "Undeclared frameworks would be packaged:" >&2
  printf '%b' "$unexpected_frameworks" >&2
  exit 1
fi

actual_gma_sha256="$(tree_sha256 "$PLATFORM_DIR/GoogleMobileAds.xcframework")"
actual_ump_sha256="$(tree_sha256 "$PLATFORM_DIR/UserMessagingPlatform.xcframework")"

if [ "$actual_gma_sha256" != "$GMA_TREE_SHA256" ]; then
  echo "GoogleMobileAds XCFramework checksum mismatch: $actual_gma_sha256" >&2
  exit 1
fi

if [ "$actual_ump_sha256" != "$UMP_TREE_SHA256" ]; then
  echo "UserMessagingPlatform XCFramework checksum mismatch: $actual_ump_sha256" >&2
  exit 1
fi

echo "Artifact inventory and checksums verified: GoogleMobileAds + UserMessagingPlatform only."
