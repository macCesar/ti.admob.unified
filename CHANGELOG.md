# Changelog

All notable changes to `ti.admob.unified` will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] — Unreleased

### Added

- Recoverable pre-change tag and Git bundle for the 1.1.0 baseline.
- `canRequestAds()` on iOS and Android; `canShowAds()` remains an alias.
- Terminal `consent_complete` event with `success`, `canRequestAds`,
  `privacyOptionsRequired`, and optional `error`/`code`.
- Idempotent state machines for native initialization and UMP consent.
- Age treatment constants and `ageRestrictedTreatment` initialization option.
- Reproducible iOS dependency inventory with official URLs and checksums.
- Static contract tests and artifact inventory verification.
- Shared standard/adaptive banner lifecycle contract tests for iOS and Android.
- Regression coverage for density-independent adaptive banner heights, dynamic
  Titanium proxy sizing, and safe native-view teardown on Android.
- `pause()` and `resume()` on the iOS adaptive banner proxy.
- Both banner destruction aliases on both iOS proxy types.
- Complete English documentation for installation, privacy, banners,
  fullscreen proxies, every exported method and constant, and migration.
- Documentation contract tests that validate API coverage, internal links, and
  the executable example's privacy and lifecycle patterns.
- Portable `requestTrackingAuthorization()` on Android, which completes with
  `applicable: false` so consumers can use the same UMP → tracking → SDK call
  sequence on both platforms.
- Shared interstitial and rewarded lifecycle state: serialized loads, explicit
  showing state, single-use references, and terminal idempotent destruction.

### Changed

- Titanium baseline: `12.8.0.GA` → `13.4.0.GA`.
- iOS deployment target: mixed 12/13 → 15.0.
- Google Mobile Ads iOS: `13.4.0` → `13.7.0`.
- Google Mobile Ads Android: `25.3.0` → `25.4.0`.
- UMP remains iOS `3.1.0` and Android `4.0.0`.
- Consent uses UMP's load-and-present-if-required flow.
- Full-screen iOS presentation uses Titanium's top presented controller.
- Public privacy documentation is event-based; callback options are deprecated.
- Standard and adaptive banners now share `load()`, `pause()`, `resume()`,
  `destroy()`, `isLoaded()`, event names, and common event payload keys.
- Interstitial and rewarded proxies now share the same load/show/destroy
  semantics and `adUnitId`/`adType` event payload on iOS and Android.
- Fullscreen error payloads now consistently include `error`, `message`, and
  `code`; iOS now emits `showed_fullscreen_content` like Android.
- Android forwards fullscreen `extras` through `AdMobAdapter`, matching the
  existing iOS request behavior.
- Banner events now consistently include `adUnitId`, `adType`, and
  `isAdaptive`; adaptive banners also include `adaptiveType`.
- Adaptive `loaded` events report the measured `height` and `heightUnit`
  (`dp`) on both platforms. Android additionally reports diagnostic
  `width`, `widthUnit`, pixel dimensions, and display density.
- Banner loads are serialized to one active request, with at most one request
  deferred while paused.
- Android adaptive banners update the Titanium proxy height from the Google
  Mobile Ads size in density-independent units whenever the native size is
  created or loaded.
- Android request-configuration updates preserve previously configured values
  through `RequestConfiguration.toBuilder()`.
- The example application now uses only official test constants, the
  `consent_complete` contract, UMP → ATT → initialization ordering, dynamic
  banner height, and explicit listener cleanup.

### Fixed

- Every accepted consent operation reaches a terminal event, including errors
  and missing Android activity.
- Removed manual parsing of `IABTCF_TCString`.
- `canShowPersonalizedAds()` no longer claims that ad-request permission
  represents personalization permission; it remains as a deprecated safe
  `false` result.
- `privacy_options_dismissed` now fires regardless of a callback property.
- Banner load state now reflects native success and failure on iOS.
- Repeated banner destruction is safe and terminal on both platforms.
- iOS banner destruction clears delegates, root controllers, paid-event
  handlers, and native view references.
- Android banner destruction clears ad listeners, destroys the native `AdView`,
  releases Titanium views, and unregisters activity lifecycle listeners.
- Android adaptive banners retain a stable native container, replace or remove
  only the child `AdView`, and unregister layout listeners during teardown
  instead of detaching the Titanium native view with `setNativeView(null)`.
- Adaptive banner height is no longer treated as raw display pixels on Android,
  preventing density-dependent over-allocation of the host view.
- Android `isTestDevice()` now delegates to the native ad request instead of
  returning a permanent compatibility `false`.
- Fullscreen callbacks arriving after destruction are ignored, and native
  delegates/callbacks are detached during cleanup.
- Fullscreen proxies also perform terminal native cleanup when Titanium
  releases the proxy, matching the banner lifecycle safety net.

### Removed

- Required Meta, InMobi, AppLovin, IronSource, Unity, and Liftoff/Vungle
  mediation dependencies from both core artifacts.
- Stale dependency/version claims and unsupported revenue assertions.

## [1.1.0] — 2026-05-28

Minor version bump: significant additions (parity constants/methods, iOS rescue),
breaking changes none. Detailed inventory below.

### Added — iOS
- 46 JS constants for parity with Android: `AD_TYPE_*`, banner size names
  (`BANNER`, `LARGE_BANNER`, `MEDIUM_RECTANGLE`, `FULLBANNER`, `LEADERBOARD`,
  `ADAPTIVE_ANCHORED`, `ADAPTIVE_INLINE`, `COLLAPSIBLE_TOP`, `COLLAPSIBLE_BOTTOM`),
  event names (`AD_LOADED`, `AD_FAILED_TO_LOAD`, `AD_OPENED`, `AD_CLOSED`,
  `AD_CLICKED`, `AD_IMPRESSION`, `AD_REWARDED`, `AD_FAILED_TO_SHOW`,
  `AD_SHOWED_FULLSCREEN_CONTENT`, `AD_DESTROYED`), consent status, debug geography,
  max ad content rating, error codes, and test ad unit IDs.
- 7 module methods for parity with Android: `isAppLovinAvailable`,
  `isInMobiAvailable`, `isVungleAvailable`, `setAppLovinGDPRConsent`,
  `setInMobiGDPRConsent`, `setVungleGDPRConsent`, `enableOptionalMediationNetworks`.
- `pendingLoad` flag in Banner Proxy to defer `load()` until the view is
  actually instantiated by TitaniumKit's layout pass.

### Added — Android
- Properly-spelled `destroyAdViewAndCancelRequest()` method on Banner +
  AdaptiveBanner proxies. The misspelled legacy `destoyAdViewAndCancelRequest()`
  is kept as deprecated alias for backwards compatibility.

### Changed — Android (SDK bump)
- `play-services-ads`: 22.6.0 → 25.3.0 (latest stable May 2026).
- `user-messaging-platform`: 2.1.0 → 4.0.0.
- Mediation adapters bumped to versions compatible with GMA 25.x:
  `facebook` 6.20.0.0 → 6.21.0.3, `inmobi` 10.8.7.0 → 11.3.0.0,
  `unity` 4.16.0.0 → 4.18.0.0, `ironsource` 8.10.0.0 → 9.4.2.0.
- Re-enabled previously commented adapters: `applovin` 13.6.2.0 + `vungle` 7.7.4.0
  (GMA 25.x uses reflection-based adapter init; the v22 init delay no longer
  applies).
- `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize` →
  `AdSize.getLargeAnchoredAdaptiveBannerAdSize` (the deprecated method's
  replacement, already in 25.x).

### Changed — iOS (SDK bump, partial)
- `GoogleMobileAds.xcframework`: 12.9.0 → 13.4.0 (May 2026).
- `UserMessagingPlatform.xcframework`: → 3.1.0.
- The 13 bundled mediation adapter xcframeworks are NOT yet bumped — pending
  a dedicated session to coordinate downloads from each vendor portal.
- `module.xcconfig`: removed `-framework iAd`, `-framework OpenGLES`,
  `-framework GLKit` from `OTHER_LDFLAGS`. These frameworks were removed
  from iOS SDK 26.5 and caused link errors in consumer apps.

### Fixed — iOS (multiple critical fixes)
- `ti.admob.unified.xcodeproj/project.pbxproj` did not register the proxy `.m`
  files in `Sources/Headers` build phases. Result: `libti.admob.unified.a` was
  missing `TiAdmobUnifiedBannerAdProxy.o`, `TiAdmobUnifiedInterstitialAdProxy.o`,
  and `TiAdmobUnifiedRewardedAdProxy.o`. Consumer apps failed with
  `Undefined symbols for architecture arm64`. Added 12 new pbxproj entries
  (6 BuildFile + 6 FileReference + 6 group children + 3 Headers + 3 Sources).
- `TiAdmobUnifiedRewardedAdProxy.m` source file was corrupted: from line 89
  onward the entire `@implementation` body was a single megaline with literal
  `\n` (escape sequences as text) instead of actual newlines. The file was
  unparseable by Obj-C compiler. Restored to 241 lines of valid Obj-C.
- `TiAdmobUnifiedBannerAdProxy.m` overrode a method `configurationSet` that
  does not exist in TitaniumKit 13.2. Replaced with the standard
  `_initWithProperties:` lifecycle method.
- `TiAdmobUnifiedBannerAdProxy.m` setters and public methods (load, destroy,
  pause, resume, isLoaded) now use `isKindOfClass:` guards before forwarding
  to the inner `TiAdmobUnifiedBannerAdView`. Previously a C-cast was used
  unconditionally, leading to `unrecognized selector` crashes when
  `[self view]` returned a placeholder `TiUIView` during init.
- `TiAdmobUnifiedBannerAdProxy.m` init no longer sets `self.adSize = @"banner"`
  (which triggered `setAdSize:` and the placeholder-view crash). Sets the
  ivar `_adSize` directly.
- `TiAdmobUnifiedBannerAdProxy.m:275` used `GADAdSizeSmartBannerPortrait`
  (undeclared identifier); fixed to `kGADAdSizeSmartBannerPortrait`.
- `TiAdmobUnifiedBannerAdProxy.m` missing `#import "TiApp.h"` — added.
- `TiAdmobUnifiedBannerAdView` `createBannerView` was being called from `init`,
  but `self.proxy` is `nil` at init time (the proxy assignment happens AFTER
  `init` returns in the Proxy's `createView`). The result was that
  `bannerView` (GADBannerView) was never created and subsequent `loadAd`
  calls silently bailed. Moved the `createBannerView` call to the Proxy's
  `createView` method, where `self.proxy` has just been assigned.
- `canShowPersonalizedAds` no longer does brittle parsing of the
  `IABTCF_TCString` from NSUserDefaults. Returns `UMPConsentInformation`'s
  `canRequestAds` instead — the SDK is the authoritative source.
- `setAppVolume` is now a documented no-op. `GADMobileAds.applicationVolume`
  was removed by Google. Method kept for parity/backwards compatibility.
- `isTestDevice` actually queries `GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers`
  (previously returned `@NO` unconditionally).
- Banner `pauseAd`/`resumeAd` no-ops documented as such (GADBannerView lifecycle
  is handled automatically by iOS).

### Fixed — Android
- Replaced deprecated `getCurrentOrientationAnchoredAdaptiveBannerAdSize` with
  `getLargeAnchoredAdaptiveBannerAdSize` per Google's deprecation note.
- `SMART_BANNER` case in `getAdSizeFromString` now falls back to `AdSize.BANNER`
  with a logged note suggesting `createAdaptiveBanner()` for full-width.
- Wrapped legacy `WindowManager.getDefaultDisplay().getMetrics()` fallback (used
  on Android API <30 where `WindowMetrics` is unavailable) with
  `@SuppressWarnings("deprecation")` to silence the noise from intentional
  legacy code paths.
- Wrapped deprecated `setTagForChildDirectedTreatment` + `setTagForUnderAgeOfConsent`
  in a `setAgeRestrictionsLegacy` helper with `@SuppressWarnings("deprecation")`.
  Google docs reference `setAgeRestrictedTreatment(AgeRestrictedTreatment)` as
  the replacement but the API is not yet shipped in `play-services-ads 25.3.0`.
  Helper will be replaced when the new API ships.
- All distribution xcframework files under `ios/platform/` now have writable
  permissions (`chmod u+w`). Some adapter xcframeworks (AppLovin in particular)
  ship from Google with `r--r--r--` mode on Info.plist files. When a consumer
  app re-extracts the module ZIP over an existing install, the overwrite hits
  EACCES and silently keeps the old install. This was a recurring frustration
  during the audit. Source files are now writable so the ZIP entries are too,
  and re-installs no longer require manually `rm -rf modules/iphone/ti.admob.unified/`.

### Build / housekeeping
- Audit doc: `AUDIT-2026-05.md` records the May 2026 toolchain validation and
  all the iOS rescue work.
- Roadmap doc: `ROADMAP.md` describes the 4 unimplemented ad types
  (App Open, Rewarded Interstitial, Adaptive Banner iOS, Native) with API
  surface, native classes, files to create, and effort estimates.
- After this set of changes, `ti build -p android --build-only` and
  `ti build -p ios --build-only` both produce zero warnings on the module's
  own code (Android: GMA 25.3 deprecation warnings silenced with documented
  suppressions; iOS: clean).

### Maintenance notes for future xcframework updates

When dropping NEW vendor xcframeworks into `ios/platform/` (e.g. bumping
GoogleMobileAds, an adapter, or a third-party SDK), vendors typically ship some
internal files (Info.plist, Mach-O binary) with read-only mode. Before zipping
the module, run:

```bash
./scripts/prepare-build.sh
```

This sets `u+w` on all files in `ios/platform/`. Otherwise the resulting ZIP
will have read-only entries and consumer apps will hit EACCES on subsequent
module updates.

### Added — iOS Adaptive Banner (parity with Android)

- New proxy `TiAdmobUnifiedAdaptiveBannerAdProxy` with full-width adaptive
  banners using `GADLargeAnchoredAdaptiveBannerAdSizeWithWidth`. The size is
  computed dynamically at `loadAd` time based on the actual container width.
- `Admob.createAdaptiveBanner({adUnitId})` on iOS now returns a real proxy
  instead of `nil`. Paridad with the Android implementation. JS API:
  ```js
  var ad = Admob.createAdaptiveBanner({ adUnitId: '...', width: Ti.UI.FILL });
  container.add(ad);
  ad.load();
  // events: loaded, failed_to_load, impression, clicked, opened, closed
  ```
- Registered in `project.pbxproj` (4 entries, UUID prefix `240C0F00...E0XX`).
- `TiAdmobUnifiedModule.m` `createAdaptiveBanner:` no longer returns `nil`.

### Fixed — iOS Banner runtime (the long-running bug)
- `TiAdmobUnifiedBannerAdProxy` override of `createView` renamed to `newView`.
  TitaniumKit 13.2 (TiDev era) calls `newView` to obtain the view, not
  `createView` (the Appcelerator-era name). With `createView`, our override
  was silently never called and the proxy received a generic `TiUIView`
  placeholder — the container rendered with the correct frame but no ad
  content inside. Renaming to `newView` immediately resolved the rendering.
  Validated runtime on iPad Pro 13-inch simulator.

### Superseded development notes

Early `1.1.0` development notes listed iOS adaptive banners, mediation adapter
updates, and a full method audit as unresolved. The final adaptive proxy was
added later in the same development cycle. Version `1.2.0` removed third-party
adapters from the core and completed the shared banner lifecycle audit.
