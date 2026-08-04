# ti.admob.unified

`ti.admob.unified` provides one Titanium JavaScript API for Google Mobile Ads
and the User Messaging Platform (UMP) on iOS and Android.

Version `1.2.1` provides a safe privacy flow, idempotent SDK operations, and
shared lifecycle/event contracts for banners, interstitials, and rewarded ads.
The same distribution also bundles current AdMob mediation adapters and native
SDKs for Meta, InMobi, Unity Ads, AppLovin, Liftoff Monetize, and ironSource on
both platforms. Applications keep one JavaScript ad API; AdMob selects the
configured ad source.

## Requirements

| Component | Baseline |
|---|---|
| Titanium SDK | `13.4.0.GA` |
| iOS | `15.0+` |
| Android | API `23+` |
| Google Mobile Ads iOS | `13.7.0` |
| UMP iOS | `3.1.0` |
| Google Mobile Ads Android | `25.4.0` |
| UMP Android | `4.0.0` |

## Mediation

| Ad source | iOS adapter | Android adapter |
|---|---:|---:|
| Meta Audience Network | `6.21.1.1.1` | `6.21.0.4` |
| InMobi | `11.4.0.0` | `11.4.0.0` |
| Unity Ads | `4.19.0.0` | `4.19.0.0` |
| AppLovin | `13.6.3.0` | `13.6.3.0` |
| Liftoff Monetize (Vungle) | `7.7.5.0` | `7.7.6.0` |
| ironSource | `9.5.0.0.0` | `9.5.0.0` |

The adapters are discovered automatically by Google Mobile Ads. Do not add
platform checks or call a different ad factory for a mediated request.
Publisher accounts, ad-source mappings, privacy declarations, and provider
credentials are still configured outside the module.

Because the adapters are present, Google Mobile Ads can inspect or initialize
them when the SDK starts. Development builds with incomplete provider mappings
can therefore log setup warnings such as a missing AppLovin SDK key or multiple
Liftoff Monetize app IDs. The module does not inject provider IDs or keys; those
values come from the AdMob mediation mapping. Treat these warnings as
configuration diagnostics and verify the intended source with Ad Inspector
before enabling production.

An application that serves AdMob demand only passes
`initialize({ disableMediation: true })`. Auto-discovery waits for every
bundled adapter to answer or time out, so an unmapped provider can delay the
first ad by tens of seconds. The adapters stay bundled and remain available to
every other application.

Use `getMediationStatus()` for diagnostics and Ad Inspector for request-level
validation. See [AdMob mediation](documentation/mediation.md).

## Supported formats

| Format | iOS | Android |
|---|---|---|
| Standard banner | Stable | Stable |
| Anchored adaptive banner | Stable | Stable |
| Inline adaptive banner | Not implemented | Available |
| Collapsible banner | Not implemented | Experimental raw option |
| Interstitial | Stable | Stable |
| Rewarded | Stable | Stable |
| App Open | Not implemented | Not implemented |
| Rewarded interstitial | Not implemented | Not implemented |
| Native | Not implemented | Not implemented |

Standard, adaptive, interstitial, and rewarded proxies use portable lifecycle
and event payload contracts. See [Fullscreen ads](documentation/fullscreen.md)
for the single-use and reward rules.

## Installation

Install the `1.2.1` ZIP for each target platform and declare the module:

```xml
<modules>
  <module version="1.2.1">ti.admob.unified</module>
</modules>
```

The consuming app must also set its AdMob application ID in `tiapp.xml`.
Application IDs are not passed to `initialize()`.

See [Getting started](documentation/getting-started.md) for the complete iOS
and Android configuration.

## Safe initialization

Register listeners before starting UMP. Request consent at every app launch,
use `canRequestAds` as the only ad-request gate, and initialize Google Mobile
Ads only after that gate opens.

```js
const Admob = require('ti.admob.unified')

let initializationStarted = false

function initializeAdsOnce() {
  if (initializationStarted || !Admob.canRequestAds()) {
    return
  }

  initializationStarted = true
  Admob.initialize({
    ageRestrictedTreatment: Admob.AGE_RESTRICTED_TREATMENT_UNSPECIFIED,
    maxAdContentRating: Admob.MAX_AD_CONTENT_RATING_GENERAL
  })
}

Admob.addEventListener('module_initialized', event => {
  if (!event.success) {
    Ti.API.warn(`AdMob initialization failed: ${event.error}`)
  }
})

Admob.addEventListener('consent_complete', event => {
  if (!event.success) {
    Ti.API.warn(`UMP completed with an error: ${event.error}`)
  }

  if (event.canRequestAds) {
    initializeAdsOnce()
  }
})

Admob.requestConsent({
  tagForUnderAgeOfConsent: false
})
```

App Tracking Transparency is optional and is **not** part of this flow. It does
not replace UMP and is not an additional ad-request gate; the app still uses
only `canRequestAds()`. An application with a real tracking case resolves ATT
before initializing — see
[Getting started](documentation/getting-started.md#optional-if-the-application-requests-att).
The same call site works on both platforms: iOS resolves ATT and Android
completes immediately with `applicable: false`.

For the publisher-rendered privacy entry point, check
`isPrivacyOptionsRequired()` and call `presentPrivacyOptions({})`.
`canShowAds()` remains a deprecated alias of `canRequestAds()`.

Read [Privacy and initialization](documentation/privacy.md) for production,
debug-geography, privacy-options, error, and event-payload guidance.

For development diagnostics, `openAdInspector()` presents Google's native Ad
Inspector on a registered test device and emits `ad_inspector_closed`. Invoke
it only from visible development UI after SDK initialization.

## Adaptive banner

The module reports the real adaptive height after load. Reserve that space in
your layout; do not hardcode `50`, `90`, `123`, or any device-specific value.

```js
const banner = Admob.createAdaptiveBanner({
  adUnitId: Admob.TEST_ADAPTIVE_BANNER,
  adaptiveType: Admob.ADAPTIVE_ANCHORED,
  width: Ti.UI.FILL
})

banner.addEventListener(Admob.AD_LOADED, event => {
  Ti.API.info(`Adaptive banner height: ${event.height}${event.heightUnit}`)
})

banner.addEventListener(Admob.AD_FAILED_TO_LOAD, event => {
  Ti.API.warn(`Banner failed: ${event.error} (${event.code})`)
})

bannerHost.add(banner)
banner.load()
```

Standard and adaptive banners expose the same methods:

- `load()`
- `pause()`
- `resume()`
- `isLoaded()`
- `destroy()`
- `destroyAdViewAndCancelRequest()`
- `destoyAdViewAndCancelRequest()` (deprecated misspelling)

Both types emit `loaded`, `failed_to_load`, `clicked`, `impression`, `opened`,
`closed`, and `destroyed`. Destruction is terminal and safe to repeat.

The public factories are `createBanner()`, `createAdaptiveBanner()`,
`createInterstitial()`, and `createRewarded()`.

See [Banner ads](documentation/banners.md) for layout patterns, payloads,
lifecycle cleanup, adaptive sizing, and platform-specific options.

## Fullscreen ads

Interstitial and rewarded proxies expose the same API on iOS and Android:

- `load()` serializes requests and ignores duplicate calls while loading,
  loaded, or showing.
- `show()` presents the unused native ad or emits `failed_to_show`.
- `isLoaded()` reports whether an unused ad is ready.
- `destroy()` is terminal, idempotent, and emits `destroyed` once.

Every fullscreen event includes `adUnitId` and `adType`. Failures consistently
add `error`, `message`, and `code`. Both platforms emit `opened` and
`showed_fullscreen_content`; rewarded ads additionally emit `rewarded` with
`rewardType` and `rewardAmount`.

Native fullscreen ads are single-use. Grant value only from `rewarded`, never
from `closed`, and remove named JavaScript listeners before destroying the
proxy. Request `extras` are forwarded through Google's ad-network extras on
both platforms.

See [Fullscreen ads](documentation/fullscreen.md) for examples, cleanup, and
the complete event table.

## Documentation

- [Getting started](documentation/getting-started.md)
- [Integrating the module](documentation/integration.md)
- [Privacy and initialization](documentation/privacy.md)
- [AdMob mediation](documentation/mediation.md)
- [Third-party SDK notices](documentation/third-party-notices.md)
- [Banner ads](documentation/banners.md)
- [Fullscreen ads](documentation/fullscreen.md)
- [Complete API reference](documentation/api-reference.md)
- [Migration to 1.2.0](documentation/migration-1.2.0.md)
- [Dependencies and checksums](DEPENDENCIES.md)
- [Changelog](CHANGELOG.md)
- [Roadmap](ROADMAP.md)
- [Contributing](CONTRIBUTING.md)

## Development safety

Use the exported `TEST_*` constants while developing. Their values are
platform-specific official Google demo ad unit IDs.

```js
const bannerId = Admob.TEST_ADAPTIVE_BANNER
const interstitialId = Admob.TEST_INTERSTITIAL
const rewardedId = Admob.TEST_REWARDED
```

Never click production ads during development. Do not derive ad eligibility
from `canShowPersonalizedAds()`, `isGDPR()`, TCF storage, or local cached
consent. `canRequestAds()` is the authoritative gate.

## Verification

```sh
npm test
./scripts/verify-artifacts.sh
ti build -p ios --build-only --project-dir ios --no-prompt
ti build -p android --build-only --project-dir android --no-prompt
```

Physical-device validation and Ad Inspector checks are still required before a
consumer app enables production ad unit IDs.

## License

MIT. See [LICENSE](LICENSE).
