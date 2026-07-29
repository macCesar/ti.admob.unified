#!/usr/bin/env bash
# Ensures bundled iOS xcframeworks are writable before zipping.
#
# Why: vendors (Google AdMob, AppLovin, Meta, etc.) ship some xcframework files
# with read-only mode (r--r--r-- on Info.plist or r-xr-xr-x on binaries).
# Once the module ZIP is extracted into a consumer app, the next ZIP update
# fails with EACCES because the existing files cannot be overwritten.
#
# Run this script after dropping new xcframeworks into ios/platform/ and
# before running `ti build`.
#
# Usage:
#   ./scripts/prepare-build.sh
#
set -euo pipefail
MODULE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLATFORM_DIR="$MODULE_ROOT/ios/platform"

if [ ! -d "$PLATFORM_DIR" ]; then
  echo "No ios/platform directory found at $PLATFORM_DIR — nothing to do." >&2
  exit 0
fi

echo "Setting writable permissions on $PLATFORM_DIR ..."
chmod -R u+w "$PLATFORM_DIR"

REMAINING=$(find "$PLATFORM_DIR" -type f ! -perm -u=w | wc -l | tr -d ' ')
if [ "$REMAINING" -eq "0" ]; then
  echo "OK: all files in ios/platform are writable. Safe to run 'ti build -p ios'."
else
  echo "WARN: $REMAINING files still read-only. Investigate before building." >&2
  exit 1
fi
