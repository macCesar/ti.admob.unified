# ti.admob.unified

Native Google Mobile Ads and User Messaging Platform bindings for Titanium on
iOS and Android.

## Supported baseline

- Titanium SDK `13.4.0.GA`
- iOS `15.0+`
- Android API `23+`
- Google Mobile Ads iOS `13.7.0`
- User Messaging Platform iOS `3.1.0`
- Google Mobile Ads Android `25.4.0`
- User Messaging Platform Android `4.0.0`

The core artifacts intentionally contain no third-party mediation adapters.
Dependency sources and checksums are recorded in [DEPENDENCIES.md](DEPENDENCIES.md).

## Implemented formats

| Format | iOS | Android |
|---|---|---|
| Banner | Stable | Stable |
| Adaptive banner | Stable | Stable |
| Interstitial | Preserved | Preserved |
| Rewarded | Preserved | Preserved |
| App Open | Not implemented | Not implemented |
| Native | Not implemented | Not implemented |

Banner API and lifecycle parity are implemented and covered by contract tests.
Device lifecycle validation remains part of phase 4. This release does not
integrate the module into Cuentas Claras.

## Installation

Install the iOS and Android ZIPs with the same module version, then declare:

```xml
<modules>
  <module version="1.2.0">ti.admob.unified</module>
</modules>
```

The consuming app must provide its AdMob application ID in its platform
configuration. Application IDs, production flags, ad placement policy, and
real ad unit IDs do not belong in this module.

## Privacy and initialization

The public contract is event-based. Callback properties are not invoked.

```js
const Admob = require('ti.admob.unified')

Admob.addEventListener('consent_complete', event => {
  if (event.canRequestAds) {
    Admob.initialize({
      testDeviceIds: [],
      ageRestrictedTreatment: Admob.AGE_RESTRICTED_TREATMENT_UNSPECIFIED
    })
  }
})

Admob.requestConsent({
  geography: Admob.DEBUG_GEOGRAPHY_DISABLED,
  tagForUnderAgeOfConsent: false
})
```

`initialize()` and `requestConsent()` are idempotent. Concurrent calls share a
single native operation. The first initialization configuration wins.

Every consent attempt emits exactly one `consent_complete` event:

```js
{
  success: true,
  canRequestAds: true,
  privacyOptionsRequired: false
}
```

Failures add `error` and `code`; they do not block the host application.
Legacy `consent_ready` and `consent_error` events remain available for one
transition release.

### Privacy methods

- `requestConsent(config)`
- `canRequestAds()`
- `canShowAds()` — deprecated alias of `canRequestAds()`
- `isPrivacyOptionsRequired()`
- `presentPrivacyOptions()` — emits `privacy_options_dismissed`
- `resetConsent()`
- `requestTrackingAuthorization()` — iOS only; emits
  `tracking_authorization_completed`

`canShowPersonalizedAds()` is deprecated and always returns `false`. UMP does
not expose a reliable publisher-facing personalization boolean. Google Mobile
Ads applies the consent signals automatically; consumers must not parse TCF
storage or derive an `npa` value from this method.

`isGDPR()` remains only as a legacy diagnostic and must not gate ad requests.

### Age treatment

Pass one of:

- `AGE_RESTRICTED_TREATMENT_CHILD`
- `AGE_RESTRICTED_TREATMENT_TEEN`
- `AGE_RESTRICTED_TREATMENT_UNSPECIFIED`

The older `tagForChildDirectedTreatment` and
`tagForUnderAgeOfConsent` initialization properties remain as compatibility
inputs and map to child or unspecified treatment. The UMP consent option
`tagForUnderAgeOfConsent` remains supported separately.

## Ads

```js
const banner = Admob.createAdaptiveBanner({
  adUnitId: Admob.TEST_ADAPTIVE_BANNER,
  adaptiveType: Admob.ADAPTIVE_ANCHORED,
  width: Ti.UI.FILL
})

banner.addEventListener(Admob.AD_LOADED, () => {})
banner.addEventListener(Admob.AD_FAILED_TO_LOAD, event => {
  Ti.API.warn(event.error)
})
banner.load()
```

Standard and adaptive banners expose the same lifecycle on iOS and Android:

- `load()` starts one request; a second call is ignored while it is active.
- `pause()` suspends the native Android banner and hides the iOS banner.
- `resume()` restores it and runs one load deferred while paused.
- `isLoaded()` reports whether the current banner loaded successfully.
- `destroy()` is terminal and safe to repeat.
- `destroyAdViewAndCancelRequest()` is a compatibility alias.
- `destoyAdViewAndCancelRequest()` is the deprecated misspelled alias.

Calling `load()` after `destroy()` does not recreate the native view and emits
`failed_to_load`. Native delegates, listeners, activity lifecycle registrations,
root controllers, and paid-event handlers are detached during destruction.

Every banner event contains:

```js
{
  adUnitId: '...',
  adType: 'banner',
  isAdaptive: true // false for a standard banner
}
```

Adaptive banners also retain `adaptiveType`. A `failed_to_load` payload adds
`error` and `code`. Both banner types emit `loaded`, `failed_to_load`,
`clicked`, `impression`, `opened`, `closed`, and `destroyed`.

Existing standard banner, interstitial, and rewarded constructors remain
available:

- `createBanner(config)`
- `createAdaptiveBanner(config)`
- `createInterstitial(config)`
- `createRewarded(config)`

Full-screen proxies retain their existing `load()`, `show()`, `isLoaded()`,
and `destroy()` APIs.

## Compatibility surface

The following methods remain to avoid breaking 1.1.0 consumers, but the core
artifact does not bundle or configure third-party mediation:

- `isAppLovinAvailable()`
- `isInMobiAvailable()`
- `isVungleAvailable()`
- `setAppLovinGDPRConsent(config)`
- `setInMobiGDPRConsent(config)`
- `setVungleGDPRConsent(config)`
- `enableOptionalMediationNetworks(config)`

With only the core artifact installed, availability methods return `false`.
The iOS setters and the enable method are safe no-ops. Android keeps reflective
setters for compatibility: they act only if the consuming application
separately supplies the corresponding optional SDK; otherwise they are no-ops.
None of these methods downloads or adds an adapter. Mediation can be evaluated
later as an optional distribution without changing the JavaScript ad API.

The correctly spelled `destroyAdViewAndCancelRequest()` and the deprecated
`destoyAdViewAndCancelRequest()` alias remain available on both platforms and
both banner proxies.

## Events

Module events:

- `module_initialized`
- `consent_complete`
- `consent_ready` — deprecated compatibility event
- `consent_error` — deprecated compatibility event
- `privacy_options_dismissed`
- `tracking_authorization_completed` — iOS

Ad events:

- `loaded`
- `failed_to_load`
- `clicked`
- `impression`
- `opened`
- `closed`
- `rewarded`
- `failed_to_show`
- `showed_fullscreen_content`
- `destroyed`

## Verification

```sh
npm test
./scripts/verify-artifacts.sh
ti build -p ios --build-only --project-dir ios --no-prompt
ti build -p android --build-only --project-dir android --no-prompt
```

Device validation and Ad Inspector are still required before enabling
production ads.
