# Dependency inventory

This file records the native dependencies distributed by the module. Direct
iOS pod versions are pinned in `ios/Podfile`, transitive resolution is locked
in `ios/Podfile.lock`, and every vendored framework is covered by
`ios/framework-checksums.sha256`.

## iOS vendored XCFrameworks

| Component | Framework | Version |
|---|---|---:|
| Google Mobile Ads | `GoogleMobileAds.xcframework` | `13.7.0` |
| User Messaging Platform | `UserMessagingPlatform.xcframework` | `3.1.0` |
| AppLovin adapter | `AppLovinAdapter.xcframework` | `13.6.3.0` |
| AppLovin SDK | `AppLovinSDK.xcframework` | `13.6.3` |
| Meta adapter | `MetaAdapter.xcframework` | `6.21.1.1` |
| Meta Audience Network SDK | `FBAudienceNetwork.xcframework` | `6.21.1` |
| InMobi adapter | `InMobiAdapter.xcframework` | `11.4.0.0` |
| InMobi SDK | `InMobiSDK.xcframework` | `11.4.0` |
| Unity adapter | `UnityAdapter.xcframework` | `4.19.0.0` |
| Unity Ads SDK | `UnityAds.xcframework` | `4.19.0` |
| Unity support library | `UnityCoherenceLib.xcframework` | `0.1.0` |
| Liftoff Monetize adapter | `LiftoffMonetizeAdapter.xcframework` | `7.7.5.0` |
| Vungle Ads SDK | `VungleAdsSDK.xcframework` | `7.7.5` |
| ironSource adapter | `IronSourceAdapter.xcframework` | `9.5.0.0.0` |
| ironSource SDK | `IronSource.xcframework` | `9.5.0.0` |
| ironSource Ad Quality SDK | `IronSourceAdQualitySDK.xcframework` | `9.8.1` |

The official CocoaPods specifications resolve the adapter and matching network
SDK pairs. `ios/install_frameworks.sh` downloads the exact Podfile versions,
stages the complete framework set, verifies all 16 tree hashes, and restores
the previous platform directory if validation fails.

The tree checksum is calculated from the sorted list of relative file paths
and the SHA-256 of every file in the XCFramework:

```sh
find . -type f -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256 |
  shasum -a 256
```

## Android Maven dependencies

| Coordinate | Version |
|---|---:|
| `com.google.android.gms:play-services-ads` | 25.4.0 |
| `com.google.android.ump:user-messaging-platform` | 4.0.0 |
| `com.google.ads.mediation:facebook` | 6.21.0.4 |
| `com.google.ads.mediation:inmobi` | 11.4.0.0 |
| `com.google.ads.mediation:unity` | 4.19.0.0 |
| `com.google.ads.mediation:applovin` | 13.6.3.0 |
| `com.google.ads.mediation:vungle` | 7.7.6.0 |
| `com.google.ads.mediation:ironsource` | 9.5.0.0 |

The six adapter coordinates bring their matching network SDKs transitively.
The generated module POM is inspected during release validation to ensure all
coordinates remain present.

## Update policy

Adapters are upgraded as matched adapter/network SDK pairs from Google's
official mediation distributions. An update is accepted only after the module
builds for iOS device and simulator architectures, Android's four ABI, both
consumer applications link, and the framework inventory passes checksum
verification.
