# ti.admob.unified roadmap

## Current baseline

Version `1.2.0` establishes one portable AdMob and mediation distribution:

- Titanium `13.4.0.GA`
- iOS `15.0+`
- Google Mobile Ads iOS `13.7.0`
- User Messaging Platform iOS `3.1.0`
- Android API `23+`
- Google Mobile Ads Android `25.4.0`
- User Messaging Platform Android `4.0.0`
- six matched mediation networks on iOS and Android
- idempotent initialization and consent
- terminal `consent_complete` events
- one standard/adaptive banner lifecycle on both platforms
- one interstitial/rewarded lifecycle and event contract on both platforms
- portable tracking-authorization completion on both platforms
- no manual TCF personalization inference

## Complete in 1.2.0

### Privacy contract

- `canRequestAds()` is the only supported ad-request gate.
- UMP updates and form presentation use the current native flow.
- `initialize()` and `requestConsent()` serialize concurrent calls.
- Every accepted consent operation reaches `consent_complete`.
- Privacy-options dismissal always emits a terminal event.
- `requestTrackingAuthorization()` is portable after UMP: iOS resolves ATT and
  Android completes immediately with `applicable: false`.
- Legacy privacy aliases remain documented but are not used by new examples.

### Banner contract

- Standard and adaptive banners expose `load()`, `pause()`, `resume()`,
  `destroy()`, `isLoaded()`, and both historical destruction aliases.
- Common event names and payload keys are aligned.
- Adaptive `loaded` reports the real height in density-independent units.
- `destroy()` is terminal, repeatable, and emits `destroyed` once.
- Native delegates, listeners, controllers, views, and activity lifecycle
  registrations are released.
- Each proxy accepts one active load and at most one deferred load while paused.

### Fullscreen contract

- Interstitial and rewarded proxies expose the same `load()`, `show()`,
  `isLoaded()`, and terminal `destroy()` lifecycle.
- Duplicate loads are serialized and native fullscreen references are
  single-use.
- Common events include `adUnitId` and `adType`; failures add `error`,
  `message`, and `code`.
- Both platforms emit `opened`, `showed_fullscreen_content`, and `destroyed`.
- Native callbacks/delegates are detached during explicit destruction and
  Titanium proxy release.

### Distribution

- Artifacts contain Google Mobile Ads, UMP, and current adapters/SDKs for
  Meta, InMobi, Unity Ads, AppLovin, Liftoff Monetize, and ironSource.
- Dependency versions and iOS checksums are reproducible.
- Static contract tests cover privacy, lifecycle, payload, cleanup, artifacts,
  and documentation.

## Release readiness

Before a final release:

- complete physical-device validation on iPhone, iPad, and Android devices with
  different screen densities;
- validate consent required/not required, acceptance/rejection, privacy
  reopening, ATT states, relaunch, and background/resume;
- validate adaptive banner sizing, safe areas, orientation, keyboard, lists,
  snackbars, tabs, and repeated window lifecycle;
- confirm there are no duplicate banners or retained listeners;
- inspect requests with Ad Inspector;
- confirm all development builds use official test IDs;
- rebuild and inspect both platform ZIPs from the release commit.

## Next contract work

These improvements can be developed without changing the established banner
and privacy APIs:

- implement iOS inline adaptive and collapsible banners, or formally narrow
  the portable adaptive surface to anchored banners;
- replace or remove the remaining platform-divergent compatibility utility
  `setAppVolume()`;
- remove deprecated privacy and destruction aliases in a future major release.

## Deferred formats

- App open
- Rewarded interstitial
- Native

Their constants are already exported for compatibility, but they do not have
working cross-platform factories. Implementing one requires a complete native
proxy, shared events and payloads, cleanup semantics, tests, examples, and
physical validation.

## Mediation maintenance

- Keep the six shared adapter/network SDK pairs current on both platforms.
- Preserve one JavaScript ad contract and portable diagnostics.
- Track privacy manifests, resource bundles, SKAdNetwork guidance, and store
  disclosure changes with every dependency update.
- Require consumer builds, physical-device tests, and Ad Inspector evidence
  before release.
- Evaluate additional networks only when they can be supported on both
  platforms without fragmenting the public API.

## Longer-term platform work

- Evaluate Android Google Mobile Ads Next-Gen only after its migration cost and
  Titanium compatibility are understood.
- Revisit the minimum Titanium, iOS, and Android baselines as upstream SDK
  requirements change.
