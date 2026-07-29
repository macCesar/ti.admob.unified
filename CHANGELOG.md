# Changelog

All notable changes to `ti.admob.unified` will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] — 2026-05-28

Minor version bump: significant additions (paridad constants/methods, iOS rescue),
breaking changes none. Detailed inventory below.

### Added — iOS
- 46 JS constants for paridad with Android: `AD_TYPE_*`, banner size names
  (`BANNER`, `LARGE_BANNER`, `MEDIUM_RECTANGLE`, `FULLBANNER`, `LEADERBOARD`,
  `ADAPTIVE_ANCHORED`, `ADAPTIVE_INLINE`, `COLLAPSIBLE_TOP`, `COLLAPSIBLE_BOTTOM`),
  event names (`AD_LOADED`, `AD_FAILED_TO_LOAD`, `AD_OPENED`, `AD_CLOSED`,
  `AD_CLICKED`, `AD_IMPRESSION`, `AD_REWARDED`, `AD_FAILED_TO_SHOW`,
  `AD_SHOWED_FULLSCREEN_CONTENT`, `AD_DESTROYED`), consent status, debug geography,
  max ad content rating, error codes, and test ad unit IDs.
- 7 module methods for paridad with Android: `isAppLovinAvailable`,
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
  was removed by Google. Method kept for paridad/backwards compatibility.
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

### Added — iOS Adaptive Banner (paridad with Android)

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

### Known issues remaining
- iOS mediation adapters (13 xcframeworks: AppLovin, Meta/FB, InMobi, Unity,
  IronSource, Vungle, etc.) are still on pre-GMA-13 versions. They may fail
  to initialize at runtime against the new GMA 13.4 core. Core SDK (Google's
  own ad fill) is unaffected. Deferred to a separate session.
- iOS `createAdaptiveBanner` is still a stub returning `nil`. Android works.
  In the meantime, full-width banners on iOS can be obtained by passing
  `adSize: 'smart_banner'` to `createBanner` (deprecated by Google but still
  functional in GMA 13.4).
- Per-method paridad audit (Android `@Kroll.method`s vs iOS `.h` declarations,
  event names, payload keys) has not been completed. The 46-constant + 7-method
  paridad pass in this release covers the most visible gaps but a full audit
  is in `ROADMAP.md`.

[1.1.0]: https://example.com/compare-link-when-versioned
