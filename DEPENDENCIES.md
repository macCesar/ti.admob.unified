# Dependency inventory

This file records the native dependencies distributed by the two modules in this repository. Each module pins its direct iOS pod versions in its own `Podfile`, locks transitive resolution in its own `Podfile.lock`, and covers every vendored framework in its own `framework-checksums.sha256`.

| Module                       | Repository path | iOS pins                                       | Android pins                     |
| ---------------------------- | --------------- | ---------------------------------------------- | -------------------------------- |
| `ti.admob.unified`           | repository root | `ios/Podfile`, `ios/framework-checksums.sha256` | `android/build.gradle`           |
| `ti.admob.unified.mediation` | `mediation/`    | `mediation/ios/Podfile`, `mediation/ios/framework-checksums.sha256` | `mediation/android/build.gradle` |

## iOS vendored XCFrameworks — `ti.admob.unified`

| Component               | Framework                           | Version  |
| ----------------------- | ----------------------------------- | -------: |
| Google Mobile Ads       | `GoogleMobileAds.xcframework`       | `13.7.0` |
| User Messaging Platform | `UserMessagingPlatform.xcframework` |  `3.1.0` |

## iOS vendored XCFrameworks — `ti.admob.unified.mediation`

All fourteen live in `mediation/ios/platform/`.

| Component                 | Framework                            |      Version |
| ------------------------- | ------------------------------------ | -----------: |
| AppLovin adapter          | `AppLovinAdapter.xcframework`        |   `13.6.3.0` |
| AppLovin SDK              | `AppLovinSDK.xcframework`            |     `13.6.3` |
| Meta adapter              | `MetaAdapter.xcframework`            | `6.21.1.1.1` |
| Meta Audience Network SDK | `FBAudienceNetwork.xcframework`      |     `6.21.1` |
| InMobi adapter            | `InMobiAdapter.xcframework`          |   `11.4.0.0` |
| InMobi SDK                | `InMobiSDK.xcframework`              |     `11.4.0` |
| Unity adapter             | `UnityAdapter.xcframework`           |   `4.19.0.0` |
| Unity Ads SDK             | `UnityAds.xcframework`               |     `4.19.0` |
| Unity support library     | `UnityCoherenceLib.xcframework`      |      `0.1.0` |
| Liftoff Monetize adapter  | `LiftoffMonetizeAdapter.xcframework` |    `7.7.5.0` |
| Vungle Ads SDK            | `VungleAdsSDK.xcframework`           |      `7.7.5` |
| ironSource adapter        | `IronSourceAdapter.xcframework`      |  `9.5.0.0.0` |
| ironSource SDK            | `IronSource.xcframework`             |    `9.5.0.0` |
| ironSource Ad Quality SDK | `IronSourceAdQualitySDK.xcframework` |      `9.8.1` |

The version column is the pinned CocoaPods version. Google's Meta adapter pod carries a fifth component that its own payload does not: `GoogleMobileAdsMediationFacebook 6.21.1.1.1` unpacks a directory named `MetaAdapter-6.21.1.1`, and the framework inside reports `6.21.1`. All three refer to the same artifact; the pod version is the one to pin and the one `mediation/ios/Podfile.lock` records.

Meta and Liftoff Monetize currently wrap a different network SDK version per platform — Meta `6.21.1` on iOS against `6.22.0` on Android, Liftoff `7.7.5` against `7.7.7` — because Google publishes those two adapters on different schedules. The lag is pinned by a contract test so that closing it is a deliberate change rather than a silent one. The other four match.

The official CocoaPods specifications resolve the adapter and matching network SDK pairs. Each module has its own `ios/install_frameworks.sh`: it downloads that module's exact Podfile versions, stages its framework set, verifies its tree hashes, and restores the previous platform directory if validation fails. Run `ios/install_frameworks.sh` for the two core frameworks and `mediation/ios/install_frameworks.sh` for the fourteen mediation ones.

The tree checksum is calculated from the sorted list of relative file paths and the SHA-256 of every file in the XCFramework:

```sh
find . -type f -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256 |
  shasum -a 256
```

## Android Maven dependencies — `ti.admob.unified`

Declared in `android/build.gradle`.

| Coordinate                                       | Version |
| ------------------------------------------------ | ------: |
| `com.google.android.gms:play-services-ads`       |  25.4.0 |
| `com.google.android.ump:user-messaging-platform` |   4.0.0 |

## Android Maven dependencies — `ti.admob.unified.mediation`

Declared in `mediation/android/build.gradle`.

| Coordinate                            |  Version |
| ------------------------------------- | -------: |
| `com.google.ads.mediation:facebook`   | 6.22.0.0 |
| `com.google.ads.mediation:inmobi`     | 11.4.0.0 |
| `com.google.ads.mediation:unity`      | 4.19.0.0 |
| `com.google.ads.mediation:applovin`   | 13.6.3.0 |
| `com.google.ads.mediation:vungle`     |  7.7.7.0 |
| `com.google.ads.mediation:ironsource` |  9.5.0.0 |

The six adapter coordinates bring their matching network SDKs transitively, and they reach the consuming application through the pack's generated POM. That is the mechanism the separation rests on: an application that does not declare `ti.admob.unified.mediation` inherits none of them. Both generated POMs are inspected during release validation — the core's to confirm it declares only Google Mobile Ads and UMP, the pack's to confirm all six coordinates remain present.

## Update policy

Adapters are upgraded as matched adapter/network SDK pairs from Google's official mediation distributions. An update is accepted only after all four artifacts build for iOS device and simulator architectures and Android's four ABI, both consumer applications link, and both framework inventories pass checksum verification.

The two modules are versioned and released together. An adapter is compiled against a specific Google Mobile Ads version, so a pack must never be installed alongside a core module of a different version.
