# Migrating to 1.2.0

Version `1.2.0` unifies the supported banner, fullscreen, tracking, and privacy
contracts without requiring a production-ad rollout.

## Module declaration

Replace platform-specific or older AdMob modules with one declaration:

```xml
<modules>
  <module version="1.2.0">ti.admob.unified</module>
</modules>
```

Update JavaScript imports:

```js
const Admob = require('ti.admob.unified')
```

Install both local artifacts when the app targets iOS and Android.

## Move the application ID to `tiapp.xml`

Remove `applicationId` from JavaScript initialization. Configure
`GADApplicationIdentifier` on iOS and
`com.google.android.gms.ads.APPLICATION_ID` on Android as described in
[Getting started](getting-started.md).

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

## Request UMP before tracking authorization and initialization

The recommended order is:

```text
UMP -> canRequestAds -> requestTrackingAuthorization -> initialize -> load ads
```

Use that same sequence on both platforms. iOS resolves ATT; Android emits
`tracking_authorization_completed` immediately with `applicable: false`.
Do not initialize before UMP has updated the current session.

## Adopt adaptive banner sizing

Replace fixed full-width or smart-banner assumptions:

```js
const banner = Admob.createAdaptiveBanner({
  adUnitId: Admob.TEST_ADAPTIVE_BANNER,
  adaptiveType: Admob.ADAPTIVE_ANCHORED,
  width: Ti.UI.FILL
})
```

On `loaded`, use `event.height` with `event.heightUnit`. Update both the banner
host and the adjacent content inset. Collapse both on error and destruction.

Do not keep a fixed `50`, `90`, or device-specific height.

## Adopt the banner lifecycle

Both standard and adaptive banners now support:

```js
banner.load()
banner.pause()
banner.resume()
banner.isLoaded()
banner.destroy()
```

`destroy()` is terminal and idempotent. Remove JavaScript event listeners and
the proxy from its parent when the owning placement closes.

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

Delete `setTimeout`/`setInterval` banner renewal loops. Configure refresh in
AdMob and let the native SDK own it.

## Adopt the fullscreen lifecycle

Interstitial and rewarded proxies now share the same methods and event payloads
on iOS and Android:

```js
fullscreen.load()
fullscreen.show()
fullscreen.isLoaded()
fullscreen.destroy()
```

Calls to `load()` while a request, loaded ad, or presentation is active are
ignored. Each native fullscreen ad is single-use. `destroy()` is terminal and
idempotent, and emits `destroyed` once.

Common events include `adUnitId` and `adType`; failures add `error`, `message`,
and `code`. Both platforms emit `opened` and `showed_fullscreen_content`.
Rewarded value must be granted only from the `rewarded` event.

## Mediation

The `1.2.0` artifacts bundle matching adapters and native SDKs for AppLovin,
InMobi, Liftoff Monetize/Vungle, Meta, ironSource, and Unity on both platforms.
Google Mobile Ads discovers them automatically; applications keep using the
same banner, interstitial, and rewarded factories.

Availability probes remain for portable diagnostics. Legacy provider consent
setters are deprecated no-ops because UMP and each provider's current
requirements must drive privacy configuration. Bundling an adapter does not
create an account or enable a mediation source: configure mappings and
credentials in AdMob, then validate with Ad Inspector.

## Development checklist

- Use the module's `TEST_*` constants.
- Keep production IDs disabled until physical validation is complete.
- Test consent accepted, rejected, not required, and previous-session states.
- Test ATT authorized, denied, and previously resolved on iOS.
- Test banner load, error collapse, rotation, background/resume, and repeated
  window close.
- Test interstitial and rewarded duplicate loads, show failures, close,
  reward delivery, and repeated destruction.
- Confirm no duplicate banners or retained listeners.
- Inspect requests with Ad Inspector.
- Run `npm test` and `./scripts/verify-artifacts.sh`.
