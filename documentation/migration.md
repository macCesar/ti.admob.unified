# Migrating to ti.admob.unified

This guide covers replacing an existing AdMob integration with `ti.admob.unified` `2.0.0`. Three starting points are common: `1.x` of this module, a platform-specific module such as `ti.admob` on iOS or `ti.android.admob` on Android, and an internal pre-release build of this module.

Most of the work is the same either way. The two sections below apply only to the first and third starting points.

## From 1.x: mediation moved to its own module

`2.0.0` changes one thing, and it is the reason for the major version. The six mediation adapters no longer ship inside `ti.admob.unified`; they ship in a separate `ti.admob.unified.mediation` module.

**No JavaScript changes.** Not one method, constant, event name, or payload key differs from `1.x`. `getMediationStatus()`, the six `isXxxAvailable()` probes, `enableOptionalMediationNetworks()`, and `disableMediation` all still live in `ti.admob.unified` and behave the same way.

**If the application does not mediate**, update the version and you are done. The iOS artifact drops from 89 MB to 14 MB, and the Android build stops inheriting six third-party network SDKs it never used.

**If the application does mediate**, install the pack as well or it will silently stop mediating. Google Mobile Ads keeps serving AdMob demand with no error, no exception, and no failed request — the mediated sources simply never participate, and the revenue difference is the only symptom.

```xml
<modules>
  <module version="2.0.0">ti.admob.unified</module>
  <module version="2.0.0">ti.admob.unified.mediation</module>
</modules>
```

Verify it before publishing, on a build of the real application, on both platforms:

```js
Admob.addEventListener('module_initialized', () => {
  Ti.API.info(JSON.stringify(Admob.getMediationStatus()))
  // Expected with the pack installed:
  // {"appLovin":true,"meta":true,"inMobi":true,"unity":true,
  //  "liftoffMonetize":true,"ironSource":true}
})
```

Six `false` values mean the pack is not in the build. Fix that before shipping; do not read it as a fill problem.

The two modules are released together and must be installed at the same version. See [AdMob mediation](mediation.md).

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
  <module version="2.0.0">ti.admob.unified</module>
</modules>
```

Add `<module version="2.0.0">ti.admob.unified.mediation</module>` only if the application mediates.

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

The application issues the initial `load()`. Google Mobile Ads owns later automatic refresh requests; TiAdMobUnified owns lifecycle, not a competing refresh schedule.

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

The optional `ti.admob.unified.mediation` pack carries matching adapters and native SDKs for AppLovin, InMobi, Liftoff Monetize/Vungle, Meta, ironSource, and Unity on both platforms. Google Mobile Ads discovers them automatically; applications keep using the same banner, interstitial, and rewarded factories and never call the pack.

Availability probes remain in `ti.admob.unified` for portable diagnostics, and report `false` for every network when the pack is not installed. Legacy provider consent setters are deprecated no-ops because UMP and each provider's current requirements must drive privacy configuration. Installing an adapter does not create an account or enable a mediation source: configure mappings and credentials in AdMob, then validate with Ad Inspector.

An application that serves AdMob demand only leaves the pack out. One that has it installed but wants to skip adapter startup in a given session passes `disableMediation: true` to `initialize()`, because auto-discovery waits for every installed adapter to answer or time out, which can delay the first ad by tens of seconds.

## Development checklist

- Use the module's `TEST_*` constants.
- Keep production IDs disabled until physical validation is complete.
- Test consent accepted, rejected, not required, and previous-session states.
- Test ATT authorized, denied, and previously resolved on iOS.
- Test banner load, error collapse, rotation, background/resume, and repeated window close.
- Test interstitial, rewarded, and app open duplicate loads, show failures, close, reward delivery, and repeated destruction.
- Confirm no duplicate banners or retained listeners.
- Inspect requests with Ad Inspector.
- Confirm `getMediationStatus()` matches what the build is supposed to contain.
- Run `npm test` and `./scripts/verify-artifacts.sh`.
