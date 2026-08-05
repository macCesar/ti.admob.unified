# ti.admob.unified roadmap

## Current baseline

Version `1.0.0` establishes one portable AdMob and mediation distribution:

- Titanium `13.4.0.GA`
- iOS `15.0+`
- Google Mobile Ads iOS `13.7.0`
- User Messaging Platform iOS `3.1.0`
- Android API `24+`, the floor the Titanium module template sets
- Google Mobile Ads Android `25.4.0`
- User Messaging Platform Android `4.0.0`
- six matched mediation networks on iOS and Android
- idempotent initialization and consent
- terminal `consent_complete` events
- one standard/adaptive banner lifecycle on both platforms
- one interstitial/rewarded/app open lifecycle and event contract on both platforms
- portable tracking-authorization completion on both platforms
- no manual TCF personalization inference

## Complete in 1.0.0

### Privacy contract

- `canRequestAds()` is the only supported ad-request gate.
- UMP updates and form presentation use the current native flow.
- `initialize()` and `requestConsent()` serialize concurrent calls.
- Every accepted consent operation reaches `consent_complete`.
- Privacy-options dismissal always emits a terminal event.
- `requestTrackingAuthorization()` is portable after UMP: iOS resolves ATT and Android completes immediately with `applicable: false`.
- Legacy privacy aliases remain documented but are not used by new examples.

### Banner contract

- Standard and adaptive banners expose `load()`, `pause()`, `resume()`, `destroy()`, `isLoaded()`, and both historical destruction aliases.
- Common event names and payload keys are aligned.
- Adaptive `loaded` reports the real height in density-independent units.
- `destroy()` is terminal, repeatable, and emits `destroyed` once.
- Native delegates, listeners, controllers, views, and activity lifecycle registrations are released.
- Each proxy accepts one active load and at most one deferred load while paused.
- Application and host-lifecycle pauses are independent causes; neither resumes the other's pause.
- Inline adaptive banners, `maxHeight`, `customAdSize`, `contentUrl`, and `requestAgent` work on both platforms.
- `smart_banner` resolves to `BANNER` on both platforms, with no special case on either.

### Fullscreen contract

- Interstitial, rewarded, and app open proxies expose the same `load()`, `show()`, `isLoaded()`, and terminal `destroy()` lifecycle.
- Duplicate loads are serialized and native fullscreen references are single-use.
- Common events include `adUnitId` and `adType`; failures add `error`, `message`, and `code`.
- Both platforms emit `opened`, `showed_fullscreen_content`, and `destroyed`.
- Native callbacks/delegates are detached during explicit destruction and Titanium proxy release.
- App open adds Google's four hour validity window, checked on demand rather than by a timer.

### Distribution

- Artifacts contain Google Mobile Ads, UMP, and current adapters/SDKs for Meta, InMobi, Unity Ads, AppLovin, Liftoff Monetize, and ironSource.
- Dependency versions and iOS checksums are reproducible.
- Static contract tests cover privacy, lifecycle, payload, cleanup, artifacts, and documentation.

## Release readiness

Before a final release:

- complete physical-device validation on iPhone, iPad, and Android devices with different screen densities;
- validate consent required/not required, acceptance/rejection, privacy reopening, ATT states, relaunch, and background/resume;
- validate adaptive banner sizing, safe areas, orientation, keyboard, lists, snackbars, tabs, and repeated window lifecycle;
- confirm there are no duplicate banners or retained listeners;
- inspect requests with Ad Inspector;
- confirm all development builds use official test IDs;
- rebuild and inspect both platform ZIPs from the release commit.

## Next contract work

These improvements can be developed without changing the established banner and privacy APIs:

- implement iOS collapsible banners, or formally document `collapsible` as an Android-only escape hatch;
- replace or remove the remaining platform-divergent compatibility utility `setAppVolume()`;
- remove deprecated privacy and destruction aliases in a future major release.

## Declared parity debt

The project's contract is that both platforms expose an identical JavaScript surface. An audit against the native sources on 5 August 2026 found eight places where they do not. These are code defects, not documentation gaps, and each one needs tests and device validation before it can be closed.

| Divergence                                                                                                                                                                                                                                                                                                   | Impact                            |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------- |
| `requestAgent` is dropped by the three iOS fullscreen proxies. They configure themselves from the creation dictionary by hand rather than through `_initWithProperties:`, and that code never reads the key. Both banner types read it on both platforms, and all three fullscreen types read it on Android. | High                              |
| `extras` is a live property on iOS and creation-only on Android. Assigning it after creating a banner does nothing on Android, and reading it back returns `undefined`.                                                                                                                                      | High                              |
| The adaptive `loaded` payload carries seven size keys on Android and two on iOS. Only `height` and `heightUnit` are documented as portable, but the asymmetry invites platform-specific code.                                                                                                                | High                              |
| Fullscreen proxies expose their internal state as readable properties on iOS and none on Android, and the iOS properties also expose the native handle (`GADInterstitialAd`) to JavaScript.                                                                                                                  | High                              |
| `module_initialized` has no error branch on iOS: a failure inside `startWithCompletionHandler` is reported as `success: true`.                                                                                                                                                                               | High                              |
| `collapsible` is Android-only.                                                                                                                                                                                                                                                                               | Known, documented as an exception |
| iOS filters banner events by whether a listener is registered; Android emits them unconditionally.                                                                                                                                                                                                           | Low                               |
| `DEBUG_GEOGRAPHY_REGULATED_US_STATE` is the literal `@(3)` on iOS instead of the SDK's own enum value.                                                                                                                                                                                                       | Low                               |

## Deferred formats

- Rewarded interstitial
- Native

Their constants are already exported, but they do not have working cross-platform factories. Implementing one requires a complete native proxy, shared events and payloads, cleanup semantics, tests, examples, and physical validation.

They are what remains of the gap against the modules this one is meant to replace. Measured on 4 August 2026: `ti.android.admob` `11.1.0` ships proxies for app open, rewarded interstitial and native, and `ti.admob` `8.1.0` on iOS documents an `AD_TYPE_APP_OPEN`. App open ships here on both platforms, which leaves rewarded interstitial and native.

Decided on 4 August 2026:

- Rewarded interstitial is planned next. App open came first because it was the only format present in both replaced modules.
- Native stays deferred, and the gap is accepted knowingly. The decision is about use, not difficulty: a native ad only pays off where the ad has to look like one more item in a content list, and no application in progress has such a list. A content feed in a future app is what would reopen it.

Whichever format comes next has to satisfy the same contract as the ones already shipped: a complete native proxy on both platforms, shared events and payloads, terminal cleanup, contract tests, an example, and physical validation.

## Mediation maintenance

- Keep the six shared adapter/network SDK pairs current on both platforms.
- Preserve one JavaScript ad contract and portable diagnostics.
- Track privacy manifests, resource bundles, SKAdNetwork guidance, and store disclosure changes with every dependency update.
- Require consumer builds, physical-device tests, and Ad Inspector evidence before release.
- Evaluate additional networks only when they can be supported on both platforms without fragmenting the public API.

## Longer-term platform work

- Evaluate Android Google Mobile Ads Next-Gen only after its migration cost and Titanium compatibility are understood.
- Revisit the minimum Titanium, iOS, and Android baselines as upstream SDK requirements change.
