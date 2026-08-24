# Migrating to ti.admob.unified

This guide covers replacing an existing AdMob integration with `ti.admob.unified` `1.0.0`. Two starting points are common: a platform-specific module such as `ti.admob` on iOS or `ti.android.admob` on Android, and an internal pre-release build of this module.

Most of the work is the same either way. The section below applies only if you are coming from an internal build, since `1.0.0` is the first published release and there is no earlier public version to break.

## If you used an internal pre-release build

Three parts of the surface changed during development and never reached a published release. Code written against an internal ZIP needs these three edits.

### There is no `COLLAPSIBLE_TOP` or `COLLAPSIBLE_BOTTOM`

Neither constant is exported. Reading one returns `undefined`, so code that passes `Admob.COLLAPSIBLE_TOP` sends `undefined` to the native layer instead of failing loudly.

They used to hold `"collapsible_top"` and `"collapsible_bottom"`. Google's SDK accepts only `"top"` and `"bottom"`, and the module forwarded the value unchanged, so every request built from those constants was invalid.

The `collapsible` property itself is unchanged and now works on both platforms. It takes Google's native string:

```js
const banner = Admob.createAdaptiveBanner({
  adUnitId: Admob.TEST_ADAPTIVE_BANNER,
  collapsible: 'bottom'
})
```

### `smart_banner` no longer produces a full-width banner on iOS

Google removed the size from the Android SDK and deprecated it on iOS. Internal builds resolved the same value into two different ads: a fixed 320×50 on Android, a full-width strip on iOS. That special case is gone, and the value falls through to `BANNER` on both platforms like any other unrecognised size.

Android behaviour is unaffected. On iOS, a placement that relied on `adSize: 'smart_banner'` for a full-width strip now renders a 320×50 banner.

The replacement is `customAdSize`, which both platforms accept:

```js
function screenWidthInDp() {
  const caps = Ti.Platform.displayCaps

  if (Ti.Platform.osname === 'android') {
    return Math.round(caps.platformWidth / caps.logicalDensityFactor)
  }

  return Math.round(caps.platformWidth)
}

const banner = Admob.createBanner({
  adUnitId: Admob.TEST_BANNER,
  customAdSize: { width: screenWidthInDp(), height: 50 },
  width: Ti.UI.FILL
})
```

`createAdaptiveBanner()` is the other option when Google should choose the height. See [Standard banner properties](banners.md#creation-properties-1).

### Legacy privacy methods no longer gate ads

`canShowPersonalizedAds()` always returns `false` and `canShowAds()` is an alias of `canRequestAds()`. Code that branched on either one has to move to the single gate described below.

## Module declaration

Replace platform-specific or older AdMob modules with one declaration:

```xml
<modules>
  <module version="1.0.0">ti.admob.unified</module>
</modules>
```

Update JavaScript imports:

```js
const Admob = require('ti.admob.unified')
```

Install both local artifacts when the app targets iOS and Android.

## Move the application ID to `tiapp.xml`

Remove `applicationId` from JavaScript initialization. Configure `GADApplicationIdentifier` on iOS and `com.google.android.gms.ads.APPLICATION_ID` on Android as described in [Getting started](getting-started.md).

## Replace privacy gates

Before:

```js
if (Admob.canShowPersonalizedAds() || !Admob.isGDPR()) {
  loadAds()
}
```

After:

```js
if (Admob.canRequestAds()) {
  loadAds()
}
```

Do not consume:

- `canShowPersonalizedAds()`
- `isGDPR()`
- `canShowAds()`
- `consent_ready`
- `consent_error`
- legacy payload aliases such as `isPrivacyOptionsRequired`

Use `consent_complete`, `canRequestAds`, and `privacyOptionsRequired`.

## Replace callback-style consent code

The supported contract is event-based:

```js
Admob.addEventListener('consent_complete', onConsentComplete)
Admob.requestConsent({})
```

Callback properties passed inside the config object are not invoked.

## Request UMP before initialization

The recommended order is:

```text
UMP -> canRequestAds -> initialize -> load ads
```

Use that same sequence on both platforms. Do not initialize before UMP has updated the current session.

App Tracking Transparency is optional and sits outside this sequence. If your application has its own tracking case, resolve it before `initialize()`; it is not an ad-request gate, and `canRequestAds()` remains the only one. The call is portable: iOS resolves ATT, and Android emits `tracking_authorization_completed` immediately with `applicable: false`.

## Adopt adaptive banner sizing

Replace fixed full-width or smart-banner assumptions:

```js
const banner = Admob.createAdaptiveBanner({
  adUnitId: Admob.TEST_ADAPTIVE_BANNER,
  adaptiveType: Admob.ADAPTIVE_ANCHORED,
  width: Ti.UI.FILL
})
```

On `loaded`, use `event.height` with `event.heightUnit`. Update both the banner host and the adjacent content inset. Collapse both on error and destruction.

Do not keep a fixed `50`, `90`, or device-specific height.

`ADAPTIVE_INLINE` and `maxHeight` work on iOS too. An application that branched on `Ti.Platform.osname` to keep inline banners off iOS can drop the branch.

## Adopt the banner lifecycle

Both standard and adaptive banners support:

```js
banner.load()
banner.pause()
banner.resume()
banner.isLoaded()
banner.destroy()
```

`destroy()` is terminal and idempotent. Remove JavaScript event listeners and the proxy from its parent when the owning placement closes.

The host lifecycle pauses banners on its own: the Android activity, and the iOS application entering the background. An application migrating from a module where it wired those by hand can drop that wiring and keep only the pauses it alone can know about, such as a tab it stopped showing or a window it covered. See [Who pauses a banner](banners.md#who-pauses-a-banner).

Do not carry forward code that changes `visible`, opacity, height, or the banner host during pause/resume. TiAdMobUnified preserves the same visual slot and creative; navigation owns only the application pause cause.

Replace both historical aliases when practical:

```js
banner.destroyAdViewAndCancelRequest()
banner.destoyAdViewAndCancelRequest()
```

with:

```js
banner.destroy()
```

## Remove manual refresh timers

Delete `setTimeout`/`setInterval` banner renewal loops. Configure refresh in AdMob and let the native SDK own it.

## Adopt the fullscreen lifecycle

Interstitial, rewarded, and app open proxies share the same methods and event payloads on iOS and Android:

```js
fullscreen.load()
fullscreen.show()
fullscreen.isLoaded()
fullscreen.destroy()
```

Calls to `load()` while a request, loaded ad, or presentation is active are ignored. Each native fullscreen ad is single-use. `destroy()` is terminal and idempotent, and emits `destroyed` once.

Common events include `adUnitId` and `adType`; failures add `error`, `message`, and `code`. Both platforms emit `opened` and `showed_fullscreen_content`. Rewarded value must be granted only from the `rewarded` event.

### App open

`createAppOpen()` returns a working proxy on both platforms. Neither module this one replaces offers it portably: `ti.admob` documents the type on iOS without a factory, and `ti.android.admob` ships an Android-only proxy. An application that wanted the format on both platforms had to build half of it itself.

It follows the fullscreen contract above, with one addition: an app open ad expires four hours after the request. Past that point `isLoaded()` reports `false` and `show()` emits `failed_to_show` with code `1`. See [The four hour window](fullscreen.md#the-four-hour-window).

## Mediation

The artifacts bundle matching adapters and native SDKs for AppLovin, InMobi, Liftoff Monetize/Vungle, Meta, ironSource, and Unity on both platforms. Google Mobile Ads discovers them automatically; applications keep using the same banner, interstitial, and rewarded factories.

Availability probes remain for portable diagnostics. Legacy provider consent setters are deprecated no-ops because UMP and each provider's current requirements must drive privacy configuration. Bundling an adapter does not create an account or enable a mediation source: configure mappings and credentials in AdMob, then validate with Ad Inspector.

An application that serves AdMob demand only should pass `disableMediation: true` to `initialize()`. Adapter auto-discovery waits for every bundled adapter to answer or time out, which can delay the first ad by tens of seconds.

## Development checklist

- Use the module's `TEST_*` constants.
- Keep production IDs disabled until physical validation is complete.
- Test consent accepted, rejected, not required, and previous-session states.
- Test ATT authorized, denied, and previously resolved on iOS.
- Test banner load, error collapse, rotation, background/resume, and repeated window close.
- Test interstitial, rewarded, and app open duplicate loads, show failures, close, reward delivery, and repeated destruction.
- Confirm no duplicate banners or retained listeners.
- Inspect requests with Ad Inspector.
- Run `npm test` and `./scripts/verify-artifacts.sh`.
