# Changelog

All notable changes to `ti.admob.unified` will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] — Unreleased

### Breaking: mediation moved to its own module

The six AdMob mediation adapters no longer ship inside `ti.admob.unified`. They ship in a new, optional module, `ti.admob.unified.mediation`, released at the same version.

**An application that mediates today and upgrades without installing the pack stops mediating, and nothing reports it.** Google Mobile Ads keeps serving AdMob demand with no error and no failed request; the mediated sources simply never participate. Install both modules and confirm with `getMediationStatus()` before publishing:

```xml
<modules>
  <module version="2.0.0">ti.admob.unified</module>
  <module version="2.0.0">ti.admob.unified.mediation</module>
</modules>
```

Nothing in the JavaScript API changed. Not one method, constant, event name, or payload key. `getMediationStatus()`, the six `isXxxAvailable()` probes, `enableOptionalMediationNetworks()`, and `initialize({ disableMediation: true })` all stay in `ti.admob.unified` and behave the same way; the availability probes report `false` for every network when the pack is absent, which is what they were always designed to do.

The reason is that bundling an adapter never raised fill on its own. A network participates only once its publisher account is approved, it is added as an ad source to an AdMob mediation group, and its credentials are mapped to the ad unit. Applications that had none of that were paying for six networks that could not bid:

| Artifact                                | iOS ZIP  |   Android ZIP |
| --------------------------------------- | -------: | ------------: |
| `ti.admob.unified` `1.0.0` (everything)  |  `89 MB` | ≈ unchanged   |
| `ti.admob.unified` `2.0.0`               |  `14 MB` |      `325 KB` |
| `ti.admob.unified.mediation` `2.0.0`     |  `75 MB` |      `102 KB` |

On Android the ZIP was never the cost: the module POM was. Through `1.x` it declared the six adapter coordinates as transitive dependencies, so every consuming application inherited six third-party SDKs in its APK with no way to opt out. Those coordinates now live in the pack's POM. An application that does not declare the pack also drops six Data Safety and App Privacy declarations, six adapter/SDK pairs to review on each Google Mobile Ads major upgrade, and the adapter startup `initialize()` waits on before the first ad.

### Changed

- `ios/platform/` holds Google Mobile Ads and UMP only; the fourteen mediation XCFrameworks moved to `mediation/ios/platform/`, with their link flags in `mediation/ios/module.xcconfig` and their tree hashes in `mediation/ios/framework-checksums.sha256`. Both `module.xcconfig` files keep `$(inherited)`, which is what lets Titanium concatenate them when an application installs both modules.
- `android/build.gradle` declares Google Mobile Ads and UMP only; the six `com.google.ads.mediation:*` coordinates moved to `mediation/android/build.gradle`.
- `scripts/prepare-build.sh` and `scripts/verify-artifacts.sh` take the module directory as an optional argument — `./scripts/verify-artifacts.sh mediation` — and default to the core.
- The iOS vendoring toolchain is split the same way: each module has its own `Podfile`, `Podfile.lock`, and `install_frameworks.sh`.
- A contract test fails if any network name reaches `ios/module.xcconfig`, `android/build.gradle`, the core `pbxproj`, or the core checksum inventory, so an adapter cannot drift back into the core unnoticed.
- A contract test compares each adapter's vendored iOS network SDK version against its Maven coordinate. Four match; Meta and Liftoff Monetize are pinned at the versions Google currently publishes per platform, so closing that lag becomes a deliberate change.

### Unchanged

No SDK or adapter version moved in this release. Google Mobile Ads stays at `13.7.0` on iOS and `25.4.0` on Android, UMP at `3.1.0` and `4.0.0`, and every adapter at the version `1.0.0` shipped. The frameworks were moved, not updated.

## [1.0.0] — Unreleased

First public release. It defines the JavaScript API that later versions are measured against. Development happened privately, and the numbered builds that circulated before this one were never published; their history lives in the Git log rather than here.

### Ad formats

- Standard banners through `createBanner()`, with the fixed Google sizes and `customAdSize` for a slot Google does not sell by name.
- Anchored and inline adaptive banners through `createAdaptiveBanner()`, reporting their real height in density-independent units after each load.
- Interstitial and rewarded ads through `createInterstitial()` and `createRewarded()`.
- App open ads through `createAppOpen()`, enforcing Google's four hour validity window. An ad older than four hours reports `isLoaded()` as `false`, and `show()` answers with `failed_to_show`. The check is a subtraction performed when something asks; nothing polls.

Rewarded interstitial and native are not implemented. Their constants are exported for source compatibility and no factory accepts them.

### Portable contracts

- Banners share `load()`, `pause()`, `resume()`, `isLoaded()`, `destroy()`, and both historical destruction aliases across platforms, with the same event names and payload keys.
- Fullscreen proxies share `load()`, `show()`, `isLoaded()`, and `destroy()`. Loads are serialized, native ads are single-use, and destruction is terminal and idempotent.
- Every fullscreen event carries `adUnitId` and `adType`; failures add `error`, `message`, and `code`; rewards add `rewardType` and `rewardAmount`.
- Application and host-lifecycle pauses are independent causes. Neither resumes the other's pause, so a banner paused because its tab is hidden stays paused when the app returns from the background.
- Banner pause/resume never changes native visibility, opacity, host, or layout. Android delegates processing to `AdView.pause()`/`resume()` and iOS disables/restores native autoload while preserving the creative on screen.
- Android activity recreation for configuration changes, including light/dark appearance, now releases only the stale native `AdView`. The JavaScript proxy remains usable, does not emit `destroyed`, and reloads after Titanium creates its replacement view.
- A copy-ready `example/lib/ads.js` integration covers startup, privacy, standard and adaptive banners, interstitial, rewarded, app open, and deterministic cleanup without application refresh timers.
- `keywords`, `contentUrl`, `requestAgent`, `extras`, and the experimental `collapsible` option reach the ad request from both banner types on both platforms, and `requestAgent` and `extras` also from all three fullscreen types.
- The adaptive `loaded` payload reports the same seven size keys on both platforms: `width`, `height`, `widthUnit`, `heightUnit`, `widthPx`, `heightPx`, and `density`.

### Privacy

- UMP consent as an event-based workflow ending in one terminal `consent_complete` event carrying `success`, `canRequestAds`, and `privacyOptionsRequired`.
- `canRequestAds()` is the only supported ad-request gate. `canShowPersonalizedAds()`, `isGDPR()`, and `canShowAds()` remain as documented deprecated compatibility surface and must not gate ads.
- `initialize()` and `requestConsent()` are idempotent: concurrent calls share one native operation and a later call re-emits the cached result.
- `requestTrackingAuthorization()` works on both platforms. iOS resolves ATT; Android completes immediately with `applicable: false`, so one call site serves both.
- `presentPrivacyOptions()` for the publisher-rendered entry point, always reaching a terminal `privacy_options_dismissed` event.

### Mediation

- Six AdMob mediation networks bundled on both platforms: Meta Audience Network, InMobi, Unity Ads, AppLovin, Liftoff Monetize (Vungle), and ironSource. Google Mobile Ads discovers the adapters; applications keep one ad API and add no platform branches.
- `getMediationStatus()` and per-network availability methods as portable installation diagnostics.
- `initialize({ disableMediation: true })` for applications serving AdMob demand only, which skips adapter startup and the timeout an unmapped provider would otherwise cost before the first ad.
- `openAdInspector()` with a terminal `ad_inspector_closed` event, for development diagnostics on a registered test device.

### Baselines

- Titanium SDK `13.4.0.GA`
- iOS `15.0+`, Android API `24+`
- Google Mobile Ads `13.7.0` on iOS and `25.4.0` on Android
- User Messaging Platform `3.1.0` on iOS and `4.0.0` on Android

Exact adapter and framework versions, with checksums, are in [DEPENDENCIES.md](DEPENDENCIES.md).

### Known gaps

Rewarded interstitial and native ads are not implemented on either platform.

Both platforms are meant to expose an identical JavaScript surface. An audit against the native sources found ten places where they did not, and all ten were closed before release; they are recorded in [ROADMAP.md](ROADMAP.md) along with the six differences that stay because one platform's SDK cannot offer what the other does.

Physical-device validation is still outstanding on both platforms.
