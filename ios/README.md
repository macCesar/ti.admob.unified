# ti.admob.unified for iOS

This directory contains the native iOS implementation of
`ti.admob.unified`.

Community-facing JavaScript documentation starts at the
[module README](../README.md) and [documentation index](../documentation/index.md).

## Baseline

- Titanium SDK `13.4.0.GA`
- iOS deployment target `15.0`
- Google Mobile Ads `13.7.0`
- User Messaging Platform `3.1.0`

The distribution also vendors the matched adapters and native SDKs for Meta,
InMobi, Unity Ads, AppLovin, Liftoff Monetize, and ironSource. See
[DEPENDENCIES.md](../DEPENDENCIES.md) for the exact inventory and checksums.

## Native structure

| Source | Responsibility |
|---|---|
| `Classes/TiAdmobUnifiedModule.*` | Module constants, UMP, ATT, initialization, and factories |
| `Classes/TiAdmobUnifiedBannerAdProxy.*` | Standard banner proxy and native view |
| `Classes/TiAdmobUnifiedAdaptiveBannerAdProxy.*` | Large anchored adaptive banner proxy and native view |
| `Classes/TiAdmobUnifiedInterstitialAdProxy.*` | Preserved interstitial proxy |
| `Classes/TiAdmobUnifiedRewardedAdProxy.*` | Preserved rewarded proxy |

## Build

From the module root:

```sh
./ios/install_frameworks.sh
ti build -p ios --build-only --project-dir ios --no-prompt
```

`install_frameworks.sh` resolves the pinned CocoaPods dependencies, stages all
16 XCFrameworks, verifies their tree hashes, and prepares them for packaging.

Run contract and artifact checks before building:

```sh
npm test
./scripts/verify-artifacts.sh
```

## Consumer configuration

The consuming Titanium application owns:

- `GADApplicationIdentifier`
- `NSUserTrackingUsageDescription`, when ATT is requested
- current `SKAdNetworkItems`
- production/test ad-unit selection
- Privacy & messaging configuration in AdMob

See [Getting started](../documentation/getting-started.md). None of these
application values should be hardcoded into the native module.

## iOS-specific public behavior

- `requestTrackingAuthorization()` emits
  `tracking_authorization_completed`.
- `createAdaptiveBanner()` implements large anchored adaptive banners.
- Inline adaptive and collapsible banners are not implemented.
- `setAppVolume()` is a compatibility no-op with Google Mobile Ads `13.x`.
- `createAppOpen()` returns a working proxy that enforces Google's four hour
  validity window, matching Android.

Do not add a public method or constant on iOS without checking and documenting
the Android surface, payloads, lifecycle, cleanup, and tests.
