# API reference

This page documents the JavaScript surface exported by
`ti.admob.unified` `1.2.0`.

```js
const Admob = require('ti.admob.unified')
```

## Module methods

| Method | Platforms | Status |
|---|---|---|
| `initialize(config)` | iOS, Android | Supported |
| `requestConsent(config)` | iOS, Android | Supported |
| `canRequestAds()` | iOS, Android | Supported |
| `isPrivacyOptionsRequired()` | iOS, Android | Supported |
| `presentPrivacyOptions(config)` | iOS, Android | Supported |
| `resetConsent()` | iOS, Android | Testing only |
| `requestTrackingAuthorization()` | iOS | Supported |
| `createBanner(config)` | iOS, Android | Supported |
| `createAdaptiveBanner(config)` | iOS, Android | Supported |
| `createInterstitial(config)` | iOS, Android | Preserved |
| `createRewarded(config)` | iOS, Android | Preserved |
| `setTestDevice(deviceId)` | iOS, Android | Compatibility utility |
| `isTestDevice()` | iOS, Android | Platform caveat |
| `setAppVolume(volume)` | iOS, Android | Platform caveat |
| `canShowAds()` | iOS, Android | Deprecated alias |
| `canShowPersonalizedAds()` | iOS, Android | Deprecated; always `false` |
| `isGDPR()` | iOS, Android | Deprecated diagnostic |

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

| Property | Type | Description |
|---|---|---|
| `testDeviceIds` | String[] | Google Mobile Ads test-device identifiers. |
| `ageRestrictedTreatment` | String | `CHILD`, `TEEN`, or `UNSPECIFIED` constant value. |
| `maxAdContentRating` | String | `G`, `PG`, `T`, or `MA` constant value. |
| `tagForChildDirectedTreatment` | Boolean | Deprecated compatibility input. |
| `tagForUnderAgeOfConsent` | Boolean | Deprecated initialization input, separate from the UMP property. |

It emits `module_initialized`. Calls are idempotent and the first accepted
configuration wins. Always pass an object, even when empty.

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

| Property | Type | Description |
|---|---|---|
| `geography` | Number | One `DEBUG_GEOGRAPHY_*` constant. Debug only. |
| `testDeviceIds` | String[] | UMP hashed device IDs. Applied when `geography` is present. |
| `tagForUnderAgeOfConsent` | Boolean | UMP under-age flag. |

It emits the terminal `consent_complete` event. Calls are idempotent within
the module session.

### `canRequestAds()`

Returns a Boolean from the native UMP consent-information object. It returns
`false` until the current app session has requested a consent-information
update.

### `isPrivacyOptionsRequired()`

Returns whether UMP requires a publisher-rendered privacy-options entry point.
Call it after the consent update completes.

### `presentPrivacyOptions(config)`

Presents the UMP privacy-options form and emits
`privacy_options_dismissed`.

```js
Admob.presentPrivacyOptions({})
```

The current native implementations do not consume configuration properties.
Pass an empty object for a consistent call site.

### `resetConsent()`

Resets UMP test state and the module's cached consent operation.

Use only during controlled consent testing. For a production privacy entry
point, call `presentPrivacyOptions()`.

### `requestTrackingAuthorization()`

iOS only. Requests or retrieves App Tracking Transparency authorization and
emits `tracking_authorization_completed`.

The method is not exported on Android. Guard it with `OS_IOS`.

### `createBanner(config)`

Returns a standard banner view proxy.

```js
const banner = Admob.createBanner({
  adUnitId: Admob.TEST_BANNER,
  adSize: Admob.BANNER,
  width: Ti.UI.FILL
})
```

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

Anchored adaptive behavior is portable. Inline is Android-only. Android also
forwards a raw experimental `collapsible: "top" | "bottom"` option; the
exported `COLLAPSIBLE_*` values are not valid native placements in `1.2.0`.
See [Adaptive banner properties](banners.md#creation-properties).

### `createInterstitial(config)`

Returns an interstitial proxy with `load()`, `show()`, `isLoaded()`, and
`destroy()`.

### `createRewarded(config)`

Returns a rewarded proxy with `load()`, `show()`, `isLoaded()`, and
`destroy()`.

See [Fullscreen ads](fullscreen.md) for both factories.

### `setTestDevice(deviceId)`

Replaces the global Google Mobile Ads test-device list with one identifier.

```js
Admob.setTestDevice('GMA_TEST_DEVICE_ID')
```

Prefer `initialize({ testDeviceIds: [...] })` for new integrations because it
supports a list and keeps initialization configuration in one place.

### `isTestDevice()`

On iOS, returns `true` when at least one test-device identifier is configured
in the native request configuration.

On Android `1.2.0`, it is a compatibility stub that always returns `false`.
Do not use this method to decide whether production IDs are safe.

### `setAppVolume(volume)`

On Android, accepts a percentage string such as `"50%"` and forwards a
normalized `0.5` value to Google Mobile Ads.

On iOS with Google Mobile Ads `13.x`, this is a compatibility no-op because
the former native application-volume API was removed.

Do not build portable application behavior around this method.

## Deprecated module methods

### `canShowAds()`

Alias of `canRequestAds()`. Replace it in new code.

### `canShowPersonalizedAds()`

Always returns `false`. UMP does not expose a publisher-facing personalization
Boolean. Do not use it as a gate or convert it into an `npa` extra.

### `isGDPR()`

Reads legacy IAB diagnostic storage. It is not authoritative, can be stale,
and must not control ad requests or UI.

## Banner proxy

The standard and adaptive proxies expose the same methods:

| Method | Return | Behavior |
|---|---|---|
| `load()` | `void` | Starts one request or defers one while paused. |
| `pause()` | `void` | Idempotently pauses/hides the native banner. |
| `resume()` | `void` | Idempotently resumes and runs one deferred load. |
| `isLoaded()` | Boolean | Reports the current native load state. |
| `destroy()` | `void` | Terminal, idempotent native cleanup. |
| `destroyAdViewAndCancelRequest()` | `void` | Compatibility alias of `destroy()`. |
| `destoyAdViewAndCancelRequest()` | `void` | Deprecated misspelled alias. |

Banner events:

| Constant | Event string | Notes |
|---|---|---|
| `AD_LOADED` | `loaded` | Adaptive payload includes real height. |
| `AD_FAILED_TO_LOAD` | `failed_to_load` | Adds `error` and `code`. |
| `AD_CLICKED` | `clicked` | Native click callback. |
| `AD_IMPRESSION` | `impression` | Native impression callback. |
| `AD_OPENED` | `opened` | Ad overlay opened. |
| `AD_CLOSED` | `closed` | Ad overlay closed. |
| `AD_DESTROYED` | `destroyed` | Emitted once per proxy. |

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

Android additionally exposes `width`, `widthUnit`, `widthPx`, `heightPx`, and
`density` on the adaptive `loaded` event. Those diagnostic keys are not a
cross-platform contract.

## Fullscreen proxy

Interstitial and rewarded proxies expose:

| Method | Return | Description |
|---|---|---|
| `load()` | `void` | Loads one native fullscreen ad. |
| `show()` | `void` | Presents it or emits `failed_to_show`. |
| `isLoaded()` | Boolean | Reports whether a native ad is ready. |
| `destroy()` | `void` | Clears the proxy's native ad reference. |

Common fullscreen payloads always include `adUnitId`. Failures include
`error`; native callbacks normally add `code`. Reward payloads add
`rewardType` and `rewardAmount`.

See [Fullscreen event differences](fullscreen.md#events).

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

The payload also retains deprecated compatibility keys for the `1.2.0`
transition. Do not consume them in new code.

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

iOS only:

```js
{
  status: Number
}
```

Status values are `0` not determined, `1` restricted, `2` denied, and `3`
authorized.

## Constants

### Ad types

| Constant | Value | Factory status |
|---|---|---|
| `AD_TYPE_BANNER` | `"banner"` | Implemented |
| `AD_TYPE_INTERSTITIAL` | `"interstitial"` | Preserved |
| `AD_TYPE_REWARDED` | `"rewarded"` | Preserved |
| `AD_TYPE_REWARDED_INTERSTITIAL` | `"rewarded_interstitial"` | No factory |
| `AD_TYPE_APP_OPEN` | `"app_open"` | No factory |
| `AD_TYPE_NATIVE` | `"native"` | No factory |

An exported type constant does not imply that its format has a working proxy.

### Banner sizes and modes

| Constant | Value | Portability |
|---|---|---|
| `BANNER` | `"banner"` | iOS, Android |
| `LARGE_BANNER` | `"large_banner"` | iOS, Android |
| `MEDIUM_RECTANGLE` | `"medium_rectangle"` | iOS, Android |
| `FULLBANNER` | `"fullbanner"` | iOS, Android |
| `LEADERBOARD` | `"leaderboard"` | iOS, Android |
| `ADAPTIVE_ANCHORED` | `"adaptive_anchored"` | iOS factory is always anchored; Android honors value |
| `ADAPTIVE_INLINE` | `"adaptive_inline"` | Android only |
| `COLLAPSIBLE_TOP` | `"collapsible_top"` | Legacy value; not translated to Google's required `"top"` placement |
| `COLLAPSIBLE_BOTTOM` | `"collapsible_bottom"` | Legacy value; not translated to Google's required `"bottom"` placement |

For Android `1.2.0`, the experimental `collapsible` property must receive the
raw native string `"top"` or `"bottom"`. Do not pass the two
`COLLAPSIBLE_*` constants until their implementation is corrected.

### Ad events

| Constant | Value |
|---|---|
| `AD_LOADED` | `"loaded"` |
| `AD_FAILED_TO_LOAD` | `"failed_to_load"` |
| `AD_OPENED` | `"opened"` |
| `AD_CLOSED` | `"closed"` |
| `AD_CLICKED` | `"clicked"` |
| `AD_IMPRESSION` | `"impression"` |
| `AD_REWARDED` | `"rewarded"` |
| `AD_FAILED_TO_SHOW` | `"failed_to_show"` |
| `AD_SHOWED_FULLSCREEN_CONTENT` | `"showed_fullscreen_content"` |
| `AD_DESTROYED` | `"destroyed"` |

`AD_SHOWED_FULLSCREEN_CONTENT` is currently emitted by Android fullscreen
proxies, not iOS. Portable consumers should use `AD_OPENED`.

### Consent status

- `CONSENT_STATUS_UNKNOWN`
- `CONSENT_STATUS_REQUIRED`
- `CONSENT_STATUS_NOT_REQUIRED`
- `CONSENT_STATUS_OBTAINED`

These constants mirror the native UMP enum. The module does not currently
export a method that returns the raw consent-status enum; use
`canRequestAds()` and `isPrivacyOptionsRequired()` for application behavior.

### Debug geography

- `DEBUG_GEOGRAPHY_DISABLED`
- `DEBUG_GEOGRAPHY_EEA`
- `DEBUG_GEOGRAPHY_REGULATED_US_STATE`
- `DEBUG_GEOGRAPHY_OTHER`

Use the constants only in `requestConsent()` on registered UMP test devices.
Do not persist or compare their numeric native values.

### Maximum ad content rating

| Constant | Value |
|---|---|
| `MAX_AD_CONTENT_RATING_GENERAL` | `"G"` |
| `MAX_AD_CONTENT_RATING_PARENTAL_GUIDANCE` | `"PG"` |
| `MAX_AD_CONTENT_RATING_TEEN` | `"T"` |
| `MAX_AD_CONTENT_RATING_MATURE_AUDIENCE` | `"MA"` |

### Age-restricted treatment

| Constant | Value |
|---|---|
| `AGE_RESTRICTED_TREATMENT_CHILD` | `"child"` |
| `AGE_RESTRICTED_TREATMENT_TEEN` | `"teen"` |
| `AGE_RESTRICTED_TREATMENT_UNSPECIFIED` | `"unspecified"` |

Pass these to `initialize({ ageRestrictedTreatment })`.

### Common Google Mobile Ads error codes

| Constant | Value |
|---|---:|
| `ERROR_CODE_SERVER_ERROR` | `0` |
| `ERROR_CODE_INVALID_REQUEST` | `1` |
| `ERROR_CODE_NETWORK_ERROR` | `2` |
| `ERROR_CODE_NO_FILL` | `3` |
| `ERROR_CODE_APP_ID_MISSING` | `8` |
| `ERROR_CODE_MEDIATION_NO_FILL` | `9` |
| `ERROR_CODE_INVALID_AD_SIZE` | `10` |

Native SDKs can return additional codes and domains. Log the complete event
instead of assuming every error maps to this list.

### Official Google demo ad units

The constant names are portable; their string values are platform-specific:

| Constant | iOS | Android | Module format |
|---|---|---|---|
| `TEST_BANNER` | `ca-app-pub-3940256099942544/2934735716` | `ca-app-pub-3940256099942544/6300978111` | Standard banner |
| `TEST_ADAPTIVE_BANNER` | `ca-app-pub-3940256099942544/2435281174` | `ca-app-pub-3940256099942544/9214589741` | Adaptive banner |
| `TEST_INTERSTITIAL` | `ca-app-pub-3940256099942544/4411468910` | `ca-app-pub-3940256099942544/1033173712` | Interstitial |
| `TEST_INTERSTITIAL_VIDEO` | `ca-app-pub-3940256099942544/5135589807` | `ca-app-pub-3940256099942544/8691691433` | Interstitial variant |
| `TEST_REWARDED` | `ca-app-pub-3940256099942544/1712485313` | `ca-app-pub-3940256099942544/5224354917` | Rewarded |
| `TEST_REWARDED_INTERSTITIAL` | `ca-app-pub-3940256099942544/6978759866` | `ca-app-pub-3940256099942544/5354046379` | No module factory |
| `TEST_NATIVE` | `ca-app-pub-3940256099942544/3986624511` | `ca-app-pub-3940256099942544/2247696110` | No module factory |
| `TEST_APP_OPEN` | `ca-app-pub-3940256099942544/5575463023` | `ca-app-pub-3940256099942544/9257395921` | No module factory |

Use the constant rather than copying a platform value into shared code.

## Mediation compatibility surface

The following methods remain to keep older `1.1.x` consumers from failing at
runtime:

| Method | Core artifact behavior |
|---|---|
| `isAppLovinAvailable()` | Returns whether an AppLovin SDK class is present. |
| `isInMobiAvailable()` | Returns whether an InMobi SDK class is present. |
| `isVungleAvailable()` | Returns whether a Vungle/Liftoff SDK class is present. |
| `setAppLovinGDPRConsent({ enabled })` | iOS no-op; Android reflective setter if SDK is supplied separately. |
| `setInMobiGDPRConsent({ enabled })` | iOS no-op; Android reflective setter if SDK is supplied separately. |
| `setVungleGDPRConsent({ enabled })` | iOS no-op; Android reflective setter if SDK is supplied separately. |
| `enableOptionalMediationNetworks(config)` | Does not download or add adapters. |

The three legacy consent setters accept `{ enabled: Boolean }`.
`enableOptionalMediationNetworks()` accepts `{ appLovin: Boolean, vungle:
Boolean }`; on Android it only logs whether the corresponding classes are
present, and on iOS it is a no-op. It does not initialize, install, or alter
the AdMob mediation configuration.

The core ZIPs include no third-party mediation adapters. Availability returns
`false` in a core-only app. These methods are compatibility APIs, not a
recommended consent solution, and they do not replace each network's current
privacy requirements.

## Reserved and unavailable APIs

- iOS declares `createAppOpen(config)` as a compatibility stub returning no
  proxy.
- Android does not export `createAppOpen`.
- There is no `createRewardedInterstitial`.
- There is no `createNative`.
- There is no public Ad Inspector launcher in `1.2.0`; use Google's supported
  device/debug mechanisms from the consuming application.
