# ti.admob.unified

`ti.admob.unified` provides one Titanium JavaScript API for Google Mobile Ads
and the User Messaging Platform (UMP) on iOS and Android.

Version `1.2.0` focuses on a safe privacy flow, idempotent SDK operations, and a
shared lifecycle for standard and adaptive banners. The core distribution
contains only Google Mobile Ads and UMP; third-party mediation adapters are not
bundled.

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

## Supported formats

| Format | iOS | Android |
|---|---|---|
| Standard banner | Stable | Stable |
| Anchored adaptive banner | Stable | Stable |
| Inline adaptive banner | Not implemented | Available |
| Collapsible banner | Not implemented | Experimental raw option |
| Interstitial | Preserved API | Preserved API |
| Rewarded | Preserved API | Preserved API |
| App Open | Not implemented | Not implemented |
| Rewarded interstitial | Not implemented | Not implemented |
| Native | Not implemented | Not implemented |

“Preserved API” means that the pre-`1.2.0` proxy remains available, but it has
not received the same cross-platform contract pass as banners. See
[Fullscreen ads](documentation/fullscreen.md) before using it.

## Installation

Install the `1.2.0` ZIP for each target platform and declare the module:

```xml
<modules>
  <module version="1.2.0">ti.admob.unified</module>
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

  if (!event.canRequestAds) {
    return
  }

  if (OS_IOS) {
    const onTrackingComplete = () => {
      Admob.removeEventListener(
        'tracking_authorization_completed',
        onTrackingComplete
      )
      initializeAdsOnce()
    }

    Admob.addEventListener(
      'tracking_authorization_completed',
      onTrackingComplete
    )
    Admob.requestTrackingAuthorization()
    return
  }

  initializeAdsOnce()
})

Admob.requestConsent({
  tagForUnderAgeOfConsent: false
})
```

ATT resolution does not replace UMP and is not an additional ad-request gate.
The app waits for ATT on iOS, then still uses only `canRequestAds()`.

For the publisher-rendered privacy entry point, check
`isPrivacyOptionsRequired()` and call `presentPrivacyOptions({})`.
`canShowAds()` remains a deprecated alias of `canRequestAds()`.

Read [Privacy and initialization](documentation/privacy.md) for production,
debug-geography, privacy-options, error, and event-payload guidance.

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

## Documentation

- [Getting started](documentation/getting-started.md)
- [Privacy and initialization](documentation/privacy.md)
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
