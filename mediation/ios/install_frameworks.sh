#!/usr/bin/env bash
#
# Resolve and vendor the exact iOS mediation adapter and network SDK versions
# pinned in Podfile.
#
# Google Mobile Ads and UMP are resolved here because every adapter depends on
# them, but they are vendored by ti.admob.unified; refresh those with
# ios/install_frameworks.sh.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MODULE_ROOT/.." && pwd)"
MODULE_ARG="mediation"
PLATFORM_DIR="$SCRIPT_DIR/platform"
CHECKSUM_FILE="$SCRIPT_DIR/framework-checksums.sha256"
TEMP_DIR="$(mktemp -d /tmp/ti-admob-mediation-frameworks.XXXXXX)"
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
Pods/AppLovinSDK/applovin-ios-sdk-13.6.3/AppLovinSDK.xcframework|AppLovinSDK.xcframework
Pods/FBAudienceNetwork/Dynamic/FBAudienceNetwork.xcframework|FBAudienceNetwork.xcframework
Pods/GoogleMobileAdsMediationAppLovin/AppLovinAdapter-13.6.3.0/AppLovinAdapter.xcframework|AppLovinAdapter.xcframework
Pods/GoogleMobileAdsMediationFacebook/MetaAdapter-6.21.1.1/MetaAdapter.xcframework|MetaAdapter.xcframework
Pods/GoogleMobileAdsMediationInMobi/InMobiAdapter-11.4.0.0/InMobiAdapter.xcframework|InMobiAdapter.xcframework
Pods/GoogleMobileAdsMediationIronSource/IronSourceAdapter-9.5.0.0.0/IronSourceAdapter.xcframework|IronSourceAdapter.xcframework
Pods/GoogleMobileAdsMediationUnity/UnityAdapter-4.19.0.0/UnityAdapter.xcframework|UnityAdapter.xcframework
Pods/GoogleMobileAdsMediationVungle/LiftoffMonetizeAdapter-7.7.5.0/LiftoffMonetizeAdapter.xcframework|LiftoffMonetizeAdapter.xcframework
Pods/InMobiSDK/InMobiSDK.xcframework|InMobiSDK.xcframework
Pods/IronSourceAdQualitySDK/IronSourceAdQualitySDK.xcframework|IronSourceAdQualitySDK.xcframework
Pods/IronSourceSDK/IronSource/IronSource.xcframework|IronSource.xcframework
Pods/UnityAds/UnityAds.xcframework|UnityAds.xcframework
Pods/UnityCoherenceLib/UnityCoherenceLib.xcframework|UnityCoherenceLib.xcframework
Pods/VungleAds/static/VungleAdsSDK.xcframework|VungleAdsSDK.xcframework
FRAMEWORKS

# The dynamic network framework executables keep their vendor modes on purpose;
# prepare-build.sh below is what makes them writable for repackaging.

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

echo "Vendored six mediation networks."
