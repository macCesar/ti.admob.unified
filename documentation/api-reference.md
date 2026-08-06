# API reference

This page documents the JavaScript surface exported by `ti.admob.unified` `1.0.0`.

```js
const Admob = require('ti.admob.unified')
```

## Module methods

| Method                                    | Platforms    | Status                     |
| ----------------------------------------- | ------------ | -------------------------- |
| `initialize(config)`                      | iOS, Android | Supported                  |
| `requestConsent(config)`                  | iOS, Android | Supported                  |
| `canRequestAds()`                         | iOS, Android | Supported                  |
| `isPrivacyOptionsRequired()`              | iOS, Android | Supported                  |
| `presentPrivacyOptions(config)`           | iOS, Android | Supported                  |
| `resetConsent()`                          | iOS, Android | Testing only               |
| `requestTrackingAuthorization()`          | iOS, Android | Portable                   |
| `openAdInspector()`                       | iOS, Android | Development diagnostic     |
| `createBanner(config)`                    | iOS, Android | Supported                  |
| `createAdaptiveBanner(config)`            | iOS, Android | Supported                  |
| `createInterstitial(config)`              | iOS, Android | Supported                  |
| `createRewarded(config)`                  | iOS, Android | Supported                  |
| `createAppOpen(config)`                   | iOS, Android | Supported                  |
| `setTestDevice(deviceId)`                 | iOS, Android | Compatibility utility      |
| `isTestDevice()`                          | iOS, Android | Supported                  |
| `setAppVolume(volume)`                    | iOS, Android | Platform caveat            |
| `getMediationStatus()`                    | iOS, Android | Supported diagnostic       |
| `isMetaAvailable()`                       | iOS, Android | Supported diagnostic       |
| `isInMobiAvailable()`                     | iOS, Android | Supported diagnostic       |
| `isUnityAvailable()`                      | iOS, Android | Supported diagnostic       |
| `isAppLovinAvailable()`                   | iOS, Android | Supported diagnostic       |
| `isVungleAvailable()`                     | iOS, Android | Supported diagnostic       |
| `isIronSourceAvailable()`                 | iOS, Android | Supported diagnostic       |
| `enableOptionalMediationNetworks(config)` | iOS, Android | Legacy; logs availability  |
| `setAppLovinGDPRConsent(config)`          | iOS, Android | Deprecated no-op           |
| `setInMobiGDPRConsent(config)`            | iOS, Android | Deprecated no-op           |
| `setVungleGDPRConsent(config)`            | iOS, Android | Deprecated no-op           |
| `canShowAds()`                            | iOS, Android | Deprecated alias           |
| `canShowPersonalizedAds()`                | iOS, Android | Deprecated; always `false` |
| `isGDPR()`                                | iOS, Android | Deprecated diagnostic      |

The four legacy mediation entries are described under [Mediation diagnostics and compatibility](#mediation-diagnostics-and-compatibility).

### `initialize(config)`

Configures global request settings and initializes Google Mobile Ads.

```js
Admob.initialize({
  testDeviceIds: ['GMA_TEST_DEVICE_ID'],
  ageRestrictedTreatment: Admob.AGE_RESTRICTED_TREATMENT_UNSPECIFIED,
  maxAdContentRating: Admob.MAX_AD_CONTENT_RATING_PARENTAL_GUIDANCE
})
```

Accepted properties:

| Property                       | Type     | Description                                                      |
| ------------------------------ | -------- | ---------------------------------------------------------------- |
| `testDeviceIds`                | String[] | Google Mobile Ads test-device identifiers.                       |
| `ageRestrictedTreatment`       | String   | `CHILD`, `TEEN`, or `UNSPECIFIED` constant value.                |
| `maxAdContentRating`           | String   | `G`, `PG`, `T`, or `MA` constant value.                          |
| `tagForChildDirectedTreatment` | Boolean  | Deprecated compatibility input.                                  |
| `tagForUnderAgeOfConsent`      | Boolean  | Deprecated initialization input, separate from the UMP property. |
| `disableMediation`             | Boolean  | Skips mediation adapter initialization for this session.         |

It emits `module_initialized`. Calls are idempotent and the first accepted configuration wins. Always pass an object, even when empty.

#### `disableMediation`

`initialize()` does not complete until every bundled adapter reports back, and an adapter with no credentials configured can take its full timeout to answer. An application that does not use mediation pays that wait for nothing: on one measured Android launch it was `30,755 ms`, of which the Liftoff Monetize adapter alone accounted for the timeout.

Set `disableMediation: true` and the SDK starts without initializing the adapters. They remain bundled and available; they are simply not started, so a network that never answers cannot hold back the first ad request.

```js
Admob.initialize({ disableMediation: true })
```

It maps to `disableMediationAdapterInitialization()` on Android and `disableMediationInitialization` on iOS, and both run before the SDK starts, which is the only point where either call has any effect.

Do not set it in an application that serves mediated ads: with adapters left uninitialized, the mediation waterfall cannot fill.

`applicationId` and `debugGeography` are not accepted here.

### `requestConsent(config)`

Updates UMP consent information and presents a required form.

```js
Admob.requestConsent({
  geography: Admob.DEBUG_GEOGRAPHY_EEA,
  testDeviceIds: ['HASHED_UMP_TEST_DEVICE_ID'],
  tagForUnderAgeOfConsent: false
})
```

Accepted properties:

| Property                  | Type     | Description                                                 |
| ------------------------- | -------- | ----------------------------------------------------------- |
| `geography`               | Number   | One `DEBUG_GEOGRAPHY_*` constant. Debug only.               |
| `testDeviceIds`           | String[] | UMP hashed device IDs. Applied when `geography` is present. |
| `tagForUnderAgeOfConsent` | Boolean  | UMP under-age flag.                                         |

It emits the terminal `consent_complete` event. Calls are idempotent within the module session.

### `canRequestAds()`

Returns a Boolean from the native UMP consent-information object. It returns `false` until the current app session has requested a consent-information update.

### `isPrivacyOptionsRequired()`

Returns whether UMP requires a publisher-rendered privacy-options entry point. Call it after the consent update completes.

### `presentPrivacyOptions(config)`

Presents the UMP privacy-options form and emits `privacy_options_dismissed`.

```js
Admob.presentPrivacyOptions({})
```

The current native implementations do not consume configuration properties. Pass an empty object for a consistent call site.

### `resetConsent()`

Resets UMP test state and the module's cached consent operation.

Use only during controlled consent testing. For a production privacy entry point, call `presentPrivacyOptions()`.

### `requestTrackingAuthorization()`

Completes the portable tracking-authorization step and emits `tracking_authorization_completed`. On iOS it requests or retrieves App Tracking Transparency authorization. On Android it completes immediately with `applicable: false`, so consumers do not need a platform condition.

### `openAdInspector()`

Presents Google Mobile Ads Ad Inspector and emits `ad_inspector_closed` when the inspector closes or fails to open.

```js
Admob.addEventListener('ad_inspector_closed', event => {
  if (!event.success) {
    Ti.API.warn(`Ad Inspector failed: ${event.error} (${event.code})`)
  }
})

Admob.openAdInspector()
```

Call this only from a visible development screen after Google Mobile Ads has initialized. Google requires the device to be registered as a test device. The method does not enable test mode, change consent, or substitute production ad units.

### `createBanner(config)`

Returns a standard banner view proxy.

```js
const banner = Admob.createBanner({
  adUnitId: Admob.TEST_BANNER,
  adSize: Admob.BANNER,
  width: Ti.UI.FILL
})
```

`customAdSize: { width, height }` in dp requests a non-standard slot on both platforms and takes precedence over `adSize`. It is how a fixed full-width strip is requested — the adaptive banner picks its own height.

See [Standard banner properties](banners.md#creation-properties-1).

### `createAdaptiveBanner(config)`

Returns an adaptive banner view proxy.

```js
const banner = Admob.createAdaptiveBanner({
  adUnitId: Admob.TEST_ADAPTIVE_BANNER,
  adaptiveType: Admob.ADAPTIVE_ANCHORED,
  width: Ti.UI.FILL
})
```

Anchored and inline are both portable, and `keywords`, `contentUrl`, `requestAgent`, `extras` and the raw experimental `collapsible: "top" | "bottom"` option reach the request on both platforms. `maxHeight` applies to inline only. See [Adaptive banner properties](banners.md#creation-properties).

### `createInterstitial(config)`

Returns an interstitial proxy with `load()`, `show()`, `isLoaded()`, and terminal `destroy()`.

### `createRewarded(config)`

Returns a rewarded proxy with `load()`, `show()`, `isLoaded()`, and terminal `destroy()`. Grant rewards only from the `rewarded` event.

### `createAppOpen(config)`

Returns an app open proxy with `load()`, `show()`, `isLoaded()`, and terminal `destroy()`. An app open ad expires four hours after the request: past that point `isLoaded()` reports `false` and `show()` emits `failed_to_show` with code `1`. See [The four hour window](fullscreen.md#the-four-hour-window).

See [Fullscreen ads](fullscreen.md) for the three factories.

### `setTestDevice(deviceId)`

Replaces the global Google Mobile Ads test-device list with one identifier.

```js
Admob.setTestDevice('GMA_TEST_DEVICE_ID')
```

Prefer `initialize({ testDeviceIds: [...] })` for new integrations because it supports a list and keeps initialization configuration in one place.

### `isTestDevice()`

Returns whether the current device will receive test ads according to the native Google Mobile Ads request configuration. Android delegates to `AdRequest.isTestDevice(context)`; iOS reports whether test identifiers are configured.

### `setAppVolume(volume)`

On Android, accepts a percentage string such as `"50%"` and forwards a normalized `0.5` value to Google Mobile Ads.

On iOS with Google Mobile Ads `13.x`, this is a compatibility no-op because the former native application-volume API was removed.

Do not build portable application behavior around this method.

## Deprecated module methods

### `canShowAds()`

Alias of `canRequestAds()`. Replace it in new code.

### `canShowPersonalizedAds()`

Always returns `false`. UMP does not expose a publisher-facing personalization Boolean. Do not use it as a gate or convert it into an `npa` extra.

### `isGDPR()`

Reads legacy IAB diagnostic storage. It is not authoritative, can be stale, and must not control ad requests or UI.

## Banner proxy

The standard and adaptive proxies expose the same methods:

| Method                            | Return  | Behavior                                                                                                 |
| --------------------------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| `load()`                          | `void`  | Starts one request or defers one while paused.                                                           |
| `pause()`                         | `void`  | Idempotently pauses and hides the native banner.                                                         |
| `resume()`                        | `void`  | Clears the application's pause. Resumes and runs one deferred load only once every pause cause is clear. |
| `isLoaded()`                      | Boolean | Reports the current native load state.                                                                   |
| `destroy()`                       | `void`  | Terminal, idempotent native cleanup.                                                                     |
| `destroyAdViewAndCancelRequest()` | `void`  | Compatibility alias of `destroy()`.                                                                      |
| `destoyAdViewAndCancelRequest()`  | `void`  | Deprecated misspelled alias.                                                                             |

The host lifecycle, meaning the Android activity and the iOS application entering the background, pauses banners on its own as a cause independent from these calls. Neither cause resumes the other's pause. See [Who pauses a banner](banners.md#who-pauses-a-banner).

### Banner creation properties

Both factories return a `TiViewProxy`, so the creation dictionary also accepts the usual Titanium layout properties. The AdMob-specific ones are:

| Property       | Type     | `createBanner()` | `createAdaptiveBanner()` | Notes                                                               |
| -------------- | -------- | ---------------- | ------------------------ | ------------------------------------------------------------------- |
| `adUnitId`     | String   | Yes              | Yes                      | Required.                                                           |
| `adSize`       | String   | Yes              | —                        | One banner-size constant. Defaults to `BANNER`.                     |
| `customAdSize` | Object   | Yes              | —                        | `{ width, height }` in dp. Wins over `adSize`.                      |
| `adaptiveType` | String   | —                | Yes                      | `ADAPTIVE_ANCHORED` or `ADAPTIVE_INLINE`. Defaults to anchored.     |
| `maxHeight`    | Number   | —                | Yes                      | Inline only, in dp. Defaults to `50` on both platforms.             |
| `collapsible`  | String   | —                | Yes                      | Google's raw placement string, `"top"` or `"bottom"`. Experimental. |
| `keywords`     | String[] | Yes              | Yes                      | Request keywords.                                                   |
| `contentUrl`   | String   | Yes              | Yes                      | URL describing the surrounding content.                             |
| `requestAgent` | String   | Yes              | Yes                      | Identifies what issued the request.                                 |
| `extras`       | Object   | Yes              | Yes                      | Google ad-network extras.                                           |

Do not resize a banner after creation. The two platforms do different things: on Android `adSize` and `customAdSize` destroy and rebuild the native `AdView`, discarding the loaded creative; on iOS the assignment does not re-request the ad at all. Destroy the placement and create a new one instead. See [Banner ads](banners.md#creation-properties).

Banner events:

| Constant            | Event string     | Notes                                  |
| ------------------- | ---------------- | -------------------------------------- |
| `AD_LOADED`         | `loaded`         | Adaptive payload includes real height. |
| `AD_FAILED_TO_LOAD` | `failed_to_load` | Adds `error` and `code`.               |
| `AD_CLICKED`        | `clicked`        | Native click callback.                 |
| `AD_IMPRESSION`     | `impression`     | Native impression callback.            |
| `AD_OPENED`         | `opened`         | Ad overlay opened.                     |
| `AD_CLOSED`         | `closed`         | Ad overlay closed.                     |
| `AD_DESTROYED`      | `destroyed`      | Emitted once per proxy.                |

Common payload:

```js
{
  adUnitId: String,
  adType: 'banner',
  isAdaptive: Boolean
}
```

Adaptive payloads add `adaptiveType`. Adaptive `loaded` adds:

```js
{
  height: Number,
  heightUnit: 'dp'
}
```

Android additionally exposes `width`, `widthUnit`, `widthPx`, `heightPx`, and `density` on the adaptive `loaded` event. Those diagnostic keys are not a cross-platform contract.

## Fullscreen proxy

Interstitial, rewarded and app open proxies expose:

| Method       | Return  | Description                                                                              |
| ------------ | ------- | ---------------------------------------------------------------------------------------- |
| `load()`     | `void`  | Loads one native fullscreen ad.                                                          |
| `show()`     | `void`  | Presents it or emits `failed_to_show`.                                                   |
| `isLoaded()` | Boolean | Reports whether a native ad is ready. An app open ad older than four hours is not ready. |
| `destroy()`  | `void`  | Terminal, idempotent cleanup; emits `destroyed` once.                                    |

Loads are serialized: calls while loading, loaded, or showing are ignored. Common fullscreen payloads always include `adUnitId` and `adType`. Failures include `error`, `message`, and `code`. Reward payloads add `rewardType` and `rewardAmount`.

### Fullscreen creation properties

All three factories accept:

| Property       | Type     | Default | Notes                                                                                          |
| -------------- | -------- | ------- | ---------------------------------------------------------------------------------------------- |
| `adUnitId`     | String   | `""`    | Required before `load()`.                                                                      |
| `autoReload`   | Boolean  | `false` | Reloads after `closed`, and after nothing else.                                                |
| `keywords`     | String[] | None    | Request keywords.                                                                              |
| `requestAgent` | String   | None    | Android only for these three types. The iOS proxies drop it; see [the roadmap](../ROADMAP.md). |
| `extras`       | Object   | None    | Google ad-network extras.                                                                      |

`autoReload` covers exactly one case. It does not reload after `failed_to_load` or after `failed_to_show`, because both deserve backoff rather than an immediate retry, and that decision belongs to the application.

See [Fullscreen events](fullscreen.md#events).

## Module events

### `module_initialized`

```js
{
  success: true,
  status: String
}
```

Failure adds `error` and `code`.

### `consent_complete`

```js
{
  success: Boolean,
  canRequestAds: Boolean,
  privacyOptionsRequired: Boolean,
  error: String, // failure only
  code: Number   // failure only
}
```

The payload also retains deprecated compatibility keys for applications coming from an older AdMob module. Do not consume them in new code.

### `consent_ready`

Deprecated success-only compatibility event. Use `consent_complete`.

### `consent_error`

Deprecated failure-only compatibility event. Use `consent_complete`.

### `privacy_options_dismissed`

```js
{
  success: Boolean,
  canRequestAds: Boolean,
  privacyOptionsRequired: Boolean,
  error: String, // failure only
  code: Number   // failure only
}
```

### `tracking_authorization_completed`

```js
{
  status: Number,
  authorized: Boolean,
  applicable: Boolean
}
```

On iOS, status values are `0` not determined, `1` restricted, `2` denied, and `3` authorized. Android reports `3`, `authorized: true`, and `applicable: false` because ATT is not an Android API.

### `ad_inspector_closed`

```js
{
  success: Boolean,
  error: String, // failure only
  code: Number   // failure only
}
```

`success: true` means Ad Inspector was displayed and then closed. A failure usually indicates that the SDK is not initialized, the device is not registered for testing, or there is no visible activity/controller.

## Constants

### Ad types

| Constant                        | Value                     | Factory status |
| ------------------------------- | ------------------------- | -------------- |
| `AD_TYPE_BANNER`                | `"banner"`                | Implemented    |
| `AD_TYPE_INTERSTITIAL`          | `"interstitial"`          | Implemented    |
| `AD_TYPE_REWARDED`              | `"rewarded"`              | Implemented    |
| `AD_TYPE_REWARDED_INTERSTITIAL` | `"rewarded_interstitial"` | No factory     |
| `AD_TYPE_APP_OPEN`              | `"app_open"`              | Implemented    |
| `AD_TYPE_NATIVE`                | `"native"`                | No factory     |

An exported type constant does not imply that its format has a working proxy.

### Banner sizes and modes

| Constant            | Value                 | Portability  |
| ------------------- | --------------------- | ------------ |
| `BANNER`            | `"banner"`            | iOS, Android |
| `LARGE_BANNER`      | `"large_banner"`      | iOS, Android |
| `MEDIUM_RECTANGLE`  | `"medium_rectangle"`  | iOS, Android |
| `FULLBANNER`        | `"fullbanner"`        | iOS, Android |
| `LEADERBOARD`       | `"leaderboard"`       | iOS, Android |
| `ADAPTIVE_ANCHORED` | `"adaptive_anchored"` | iOS, Android |
| `ADAPTIVE_INLINE`   | `"adaptive_inline"`   | iOS, Android |

There is no `COLLAPSIBLE_TOP` or `COLLAPSIBLE_BOTTOM` constant. Google's SDK accepts only `"top"` and `"bottom"` as placement strings, so a constant holding anything else could not be passed anywhere. The `collapsible` property takes the native string directly, on both platforms.

### Ad events

| Constant                       | Value                         |
| ------------------------------ | ----------------------------- |
| `AD_LOADED`                    | `"loaded"`                    |
| `AD_FAILED_TO_LOAD`            | `"failed_to_load"`            |
| `AD_OPENED`                    | `"opened"`                    |
| `AD_CLOSED`                    | `"closed"`                    |
| `AD_CLICKED`                   | `"clicked"`                   |
| `AD_IMPRESSION`                | `"impression"`                |
| `AD_REWARDED`                  | `"rewarded"`                  |
| `AD_FAILED_TO_SHOW`            | `"failed_to_show"`            |
| `AD_SHOWED_FULLSCREEN_CONTENT` | `"showed_fullscreen_content"` |
| `AD_DESTROYED`                 | `"destroyed"`                 |

`AD_SHOWED_FULLSCREEN_CONTENT` and `AD_OPENED` are emitted by all three fullscreen proxy types — interstitial, rewarded and app open — on iOS and Android.

### Consent status

- `CONSENT_STATUS_UNKNOWN`
- `CONSENT_STATUS_REQUIRED`
- `CONSENT_STATUS_NOT_REQUIRED`
- `CONSENT_STATUS_OBTAINED`

These constants mirror the native UMP enum. The module does not currently export a method that returns the raw consent-status enum; use `canRequestAds()` and `isPrivacyOptionsRequired()` for application behavior.

### Debug geography

- `DEBUG_GEOGRAPHY_DISABLED`
- `DEBUG_GEOGRAPHY_EEA`
- `DEBUG_GEOGRAPHY_REGULATED_US_STATE`
- `DEBUG_GEOGRAPHY_OTHER`

Use the constants only in `requestConsent()` on registered UMP test devices. Do not persist or compare their numeric native values.

### Maximum ad content rating

| Constant                                  | Value  |
| ----------------------------------------- | ------ |
| `MAX_AD_CONTENT_RATING_GENERAL`           | `"G"`  |
| `MAX_AD_CONTENT_RATING_PARENTAL_GUIDANCE` | `"PG"` |
| `MAX_AD_CONTENT_RATING_TEEN`              | `"T"`  |
| `MAX_AD_CONTENT_RATING_MATURE_AUDIENCE`   | `"MA"` |

### Age-restricted treatment

| Constant                               | Value           |
| -------------------------------------- | --------------- |
| `AGE_RESTRICTED_TREATMENT_CHILD`       | `"child"`       |
| `AGE_RESTRICTED_TREATMENT_TEEN`        | `"teen"`        |
| `AGE_RESTRICTED_TREATMENT_UNSPECIFIED` | `"unspecified"` |

Pass these to `initialize({ ageRestrictedTreatment })`.

### Common Google Mobile Ads error codes

| Constant                       | Value |
| ------------------------------ | ----: |
| `ERROR_CODE_SERVER_ERROR`      |   `0` |
| `ERROR_CODE_INVALID_REQUEST`   |   `1` |
| `ERROR_CODE_NETWORK_ERROR`     |   `2` |
| `ERROR_CODE_NO_FILL`           |   `3` |
| `ERROR_CODE_APP_ID_MISSING`    |   `8` |
| `ERROR_CODE_MEDIATION_NO_FILL` |   `9` |
| `ERROR_CODE_INVALID_AD_SIZE`   |  `10` |

Native SDKs can return additional codes and domains. Log the complete event instead of assuming every error maps to this list.

### Official Google demo ad units

The constant names are portable; their string values are platform-specific:

| Constant                     | iOS                                      | Android                                  | Module format                | Factory                  |
| ---------------------------- | ---------------------------------------- | ---------------------------------------- | ---------------------------- | ------------------------ |
| `TEST_BANNER`                | `ca-app-pub-3940256099942544/2934735716` | `ca-app-pub-3940256099942544/6300978111` | Standard banner              | `createBanner()`         |
| `TEST_ADAPTIVE_BANNER`       | `ca-app-pub-3940256099942544/2435281174` | `ca-app-pub-3940256099942544/9214589741` | Adaptive banner              | `createAdaptiveBanner()` |
| `TEST_INTERSTITIAL`          | `ca-app-pub-3940256099942544/4411468910` | `ca-app-pub-3940256099942544/1033173712` | Interstitial                 | `createInterstitial()`   |
| `TEST_INTERSTITIAL_VIDEO`    | `ca-app-pub-3940256099942544/5135589807` | `ca-app-pub-3940256099942544/8691691433` | Interstitial, video creative | `createInterstitial()`   |
| `TEST_REWARDED`              | `ca-app-pub-3940256099942544/1712485313` | `ca-app-pub-3940256099942544/5224354917` | Rewarded                     | `createRewarded()`       |
| `TEST_REWARDED_INTERSTITIAL` | `ca-app-pub-3940256099942544/6978759866` | `ca-app-pub-3940256099942544/5354046379` | Rewarded interstitial        | None. Reserved           |
| `TEST_NATIVE`                | `ca-app-pub-3940256099942544/3986624511` | `ca-app-pub-3940256099942544/2247696110` | Native                       | None. Reserved           |
| `TEST_APP_OPEN`              | `ca-app-pub-3940256099942544/5575463023` | `ca-app-pub-3940256099942544/9257395921` | App open                     | `createAppOpen()`        |

Use the constant rather than copying a platform value into shared code.

The reserved constants exist so that code written against a future release still compiles today. There is nothing to pass them to yet; see [Reserved and unavailable APIs](#reserved-and-unavailable-apis).

## Mediation diagnostics and compatibility

The module bundles Meta, InMobi, Unity Ads, AppLovin, Liftoff Monetize (Vungle), and ironSource on iOS and Android.

`getMediationStatus()` returns the same object shape on both platforms:

```js
{
  appLovin: Boolean,
  meta: Boolean,
  inMobi: Boolean,
  unity: Boolean,
  liftoffMonetize: Boolean,
  ironSource: Boolean
}
```

Individual methods return the corresponding value:

| Method                    | Network                 |
| ------------------------- | ----------------------- |
| `isAppLovinAvailable()`   | AppLovin                |
| `isMetaAvailable()`       | Meta Audience Network   |
| `isInMobiAvailable()`     | InMobi                  |
| `isUnityAvailable()`      | Unity Ads               |
| `isVungleAvailable()`     | Liftoff Monetize/Vungle |
| `isIronSourceAvailable()` | ironSource              |

Availability confirms that the native adapter is installed. It does not prove that the provider account, AdMob mapping, consent, or inventory can serve an ad.

The following legacy methods remain callable so that code written against an older AdMob module keeps compiling:

| Method                                    | Behavior                                                 |
| ----------------------------------------- | -------------------------------------------------------- |
| `setAppLovinGDPRConsent({ enabled })`     | Deprecated compatibility no-op.                          |
| `setInMobiGDPRConsent({ enabled })`       | Deprecated compatibility no-op.                          |
| `setVungleGDPRConsent({ enabled })`       | Deprecated compatibility no-op.                          |
| `enableOptionalMediationNetworks(config)` | Logs adapter availability; adapters are auto-discovered. |

New integrations should use UMP, `canRequestAds()`, and each enabled provider's current privacy requirements. They should not manually initialize mediation networks. See [AdMob mediation](mediation.md).

The legacy setters intentionally do not translate one Boolean into both GDPR consent and US-state sale/sharing choices. Those are different legal signals.

## Reserved and unavailable APIs

- There is no `createRewardedInterstitial`.
- There is no `createNative`.
