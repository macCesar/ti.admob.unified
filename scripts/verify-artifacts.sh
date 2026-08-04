#!/usr/bin/env bash
#
# Fail before packaging if ios/platform contains undeclared or stale content.
#
set -euo pipefail

MODULE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLATFORM_DIR="$MODULE_ROOT/ios/platform"
CHECKSUM_FILE="$MODULE_ROOT/ios/framework-checksums.sha256"

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

if [ ! -f "$CHECKSUM_FILE" ]; then
  echo "Missing framework checksum inventory." >&2
  exit 1
fi

unexpected_frameworks=""
for framework in "$PLATFORM_DIR"/*.xcframework; do
  [ -e "$framework" ] || continue
  framework_name="$(basename "$framework")"
  if ! awk -v name="$framework_name" \
    '$2 == name { found = 1 } END { exit !found }' "$CHECKSUM_FILE"; then
    unexpected_frameworks="${unexpected_frameworks}${framework_name}\n"
  fi
done

while read -r expected_sha256 framework_name; do
  [ -n "$framework_name" ] || continue
  framework_path="$PLATFORM_DIR/$framework_name"
  if [ ! -d "$framework_path" ]; then
    echo "Missing declared framework: $framework_name" >&2
    exit 1
  fi

  actual_sha256="$(tree_sha256 "$framework_path")"
  if [ "$actual_sha256" != "$expected_sha256" ]; then
    echo "$framework_name checksum mismatch: $actual_sha256" >&2
    exit 1
  fi
done < "$CHECKSUM_FILE"

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

framework_count="$(wc -l < "$CHECKSUM_FILE" | tr -d ' ')"
echo "Artifact inventory and checksums verified: $framework_count XCFrameworks."
