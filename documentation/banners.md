# Banner ads

Standard and adaptive banners share one public lifecycle and event contract on
iOS and Android.

Both factories return a Titanium `TiViewProxy`, so their creation dictionaries
also accept normal Titanium view/layout properties such as `width`, `height`,
`top`, `bottom`, `left`, and `right`. The tables below list the
AdMob-specific properties.

## Choose a banner type

Use `createAdaptiveBanner()` for a banner anchored outside scrolling content.
Its height is calculated from the available width, orientation, and device.

Use `createBanner()` when the placement explicitly requires a fixed Google ad
size such as `BANNER`, `MEDIUM_RECTANGLE`, or `LEADERBOARD`.

| Capability | iOS | Android |
|---|---|---|
| Standard fixed-size banner | Yes | Yes |
| Large anchored adaptive banner | Yes | Yes |
| Inline adaptive banner | No | Yes |
| Collapsible anchored banner | No | Experimental raw option |
| Dynamic loaded height | Yes | Yes |

## Adaptive banner

```js
const banner = Admob.createAdaptiveBanner({
  adUnitId: Admob.TEST_ADAPTIVE_BANNER,
  adaptiveType: Admob.ADAPTIVE_ANCHORED,
  width: Ti.UI.FILL
})

bannerHost.add(banner)
banner.load()
```

The proxy must be in the Titanium view hierarchy before `load()` so its native
view can measure the real container width.

### Creation properties

| Property | Type | iOS | Android | Notes |
|---|---|---:|---:|---|
| `adUnitId` | String | Yes | Yes | Required. |
| `adaptiveType` | String | Anchored only | Yes | Defaults to anchored. Use `ADAPTIVE_ANCHORED` for portable code. |
| `maxHeight` | Number | No | Inline only | Maximum inline height in dp; Android defaults to `50`. |
| `collapsible` | String | No | Experimental | Native placement string: `"top"` or `"bottom"`. |
| `keywords` | String[] | Accepted, not applied | Yes | Prefer contextual configuration in AdMob. |
| `contentUrl` | String | No | Yes | URL describing surrounding content. |
| `extras` | Object | Accepted, not applied | Yes | Google adapter request extras. |

On iOS, the native implementation always creates a large anchored adaptive
banner. It reports `adaptiveType: "anchored"` in events. Portable consumers
must not branch on the exact `adaptiveType` string; use `isAdaptive`.

On Android, `ADAPTIVE_INLINE` and `maxHeight` are exposed. The `collapsible`
property is also forwarded to Google's request extras, but it currently
requires the native value `"top"` or `"bottom"`.

The exported `COLLAPSIBLE_TOP` and `COLLAPSIBLE_BOTTOM` constants contain the
legacy values `"collapsible_top"` and `"collapsible_bottom"`. Version `1.2.0`
does not translate them to Google's required placement values, so do not pass
those constants to `collapsible`. This option remains experimental until the
constants and cross-platform behavior are corrected and tested.

Google's current requirements are described in the
[collapsible banner guide](https://developers.google.com/admob/android/banner/collapsible).

## Reserve real layout space

The loaded height uses density-independent units on both platforms:

```js
banner.addEventListener(Admob.AD_LOADED, event => {
  bannerHost.height = `${event.height}dp`
})
```

Do not hardcode a height. Adaptive banners can change height across devices,
densities, widths, and orientations.

A safe composite layout reserves the same bottom inset for content:

```js
const root = Ti.UI.createView({
  layout: 'composite'
})

const content = Ti.UI.createView({
  top: 0,
  left: 0,
  right: 0,
  bottom: 0
})

const bannerHost = Ti.UI.createView({
  left: 0,
  right: 0,
  bottom: 0,
  height: 0
})

root.add(content)
root.add(bannerHost)

function setBannerHeight(value) {
  const height = Math.max(0, Number(value) || 0)
  const dimension = `${height}dp`

  bannerHost.height = dimension
  content.bottom = dimension
}
```

This keeps the banner inside the visible layout and prevents it from
overlapping lists, navigation, snackbars, or other bottom-aligned UI. Place
`root` inside the app's safe-area-aware content region.

Do not use a vertical layout where a preceding `Ti.UI.FILL` child consumes the
entire height and pushes the banner host below the window.

### Full lifecycle example

Use named listeners so they can be removed:

```js
let banner = null

function createBanner() {
  if (banner || !Admob.canRequestAds()) {
    return
  }

  banner = Admob.createAdaptiveBanner({
    adUnitId: Admob.TEST_ADAPTIVE_BANNER,
    adaptiveType: Admob.ADAPTIVE_ANCHORED,
    width: Ti.UI.FILL
  })

  banner.addEventListener(Admob.AD_LOADED, onLoaded)
  banner.addEventListener(Admob.AD_FAILED_TO_LOAD, onFailed)
  banner.addEventListener(Admob.AD_DESTROYED, onDestroyed)

  bannerHost.add(banner)
  banner.load()
}

function onLoaded(event) {
  setBannerHeight(event.height)
}

function onFailed(event) {
  Ti.API.warn(`Banner failed: ${event.error} (${event.code})`)
  setBannerHeight(0)
}

function onDestroyed() {
  setBannerHeight(0)
}

function pauseBanner() {
  banner?.pause()
}

function resumeBanner() {
  banner?.resume()
}

function destroyBanner() {
  if (!banner) {
    setBannerHeight(0)
    return
  }

  banner.removeEventListener(Admob.AD_LOADED, onLoaded)
  banner.removeEventListener(Admob.AD_FAILED_TO_LOAD, onFailed)
  banner.removeEventListener(Admob.AD_DESTROYED, onDestroyed)
  banner.destroy()

  if (banner.parent) {
    banner.parent.remove(banner)
  }

  banner = null
  setBannerHeight(0)
}
```

Call `pauseBanner()` when the screen that owns the placement stops being shown,
`resumeBanner()` when it comes back, and `destroyBanner()` when the placement or
window closes.

### Who pauses a banner

Two independent causes can hold a banner paused, and the module tracks them
separately:

| Cause | Trigger | Platform |
|---|---|---|
| Application | your `pause()` / `resume()` calls | Both |
| Lifecycle | activity `onPause`/`onResume`, app background/foreground | Both, automatic |

**Neither cause resumes the other's pause.** A banner you paused because its tab
is hidden stays paused when the app returns from the background, and a banner
the lifecycle paused stays paused until the app is visible again — even if you
called `resume()` meanwhile. A load deferred while paused waits for *every*
cause to clear, so it never fires into a placement nobody is looking at.

This means you only have to own the reason you know about — which screen is
showing — and never have to mirror the app's background state to keep the two
from fighting.

The lifecycle cause is automatic on both platforms: Android follows the hosting
activity, and iOS observes application background/foreground. iOS deliberately
uses background/foreground rather than resign/become-active, because a Control
Center pull or a call banner resigns active while the ad is still on screen and
still viewable.

## Shared methods

### `load()`

Starts an ad request.

- A second call is ignored while a request is active.
- A call while paused defers at most one request until `resume()`.
- A call after `destroy()` cannot recreate the proxy and emits
  `failed_to_load`.

### `pause()`

Idempotently pauses the banner: it hides the native view and suspends the ad
view's processing on both platforms.

One effect is **not** symmetric, and the difference is in Google's SDKs, not in
this module:

| | iOS | Android |
|---|---|---|
| Hides the native view | Yes | Yes |
| Suspends ad-view processing | Yes | Yes |
| Stops the automatic refresh | Yes, via `autoloadEnabled` | **No** |

`GADBannerView` exposes `autoloadEnabled`, so pausing stops the refresh
explicitly on iOS. `BaseAdView` on Android exposes no refresh control at all —
`pause()` is documented only as pausing "extra processing".

In practice the gap is smaller than that table suggests, because the SDK gates
refresh on visibility by itself. An off-screen banner logs:

```text
I/Ads: Ad is not visible. Not refreshing ad.
```

Since `pause()` now hides the native view on both platforms, that gate is what
stops the refresh on Android. The mechanism differs — an explicit flag on iOS,
a visibility check on Android — but a paused banner should not be refreshing on
either. Confirm it with that log line rather than assuming it.

Do not try to close the remaining gap by destroying and recreating the banner.
That discards the loaded creative, issues a fresh request, and costs a full
load cycle on return. Configure the refresh rate on the ad unit in AdMob.

**Never hide a banner that has not loaded yet.** On Android the visibility gate
cuts both ways: an `AdView` that is already hidden does not load either, so a
placement hidden before its first fill stays empty. The module handles this by
deferring `load()` while paused and running it on resume, once the view is
visible again — which is why you should call `load()` normally and let the
module decide when it runs, rather than gating the call yourself.

On iOS there is no visibility gate at all. A hidden `GADBannerView` keeps
loading and refreshing, and those loads count as impressions nobody saw. That
is why `pause()` sets `autoloadEnabled = NO` there instead of relying on the
SDK: on iOS it is the only defence, not an optimisation.

### `resume()`

Idempotently resumes the banner and runs one deferred load, if present — but
only once every pause cause has cleared. See
[Who pauses a banner](#who-pauses-a-banner).

### `isLoaded()`

Returns `true` only while the current proxy owns a successfully loaded ad.

### `destroy()`

Terminal and safe to repeat. It releases the native ad, detaches native
delegates/listeners and lifecycle registrations, and emits `destroyed` once.

Never reuse a destroyed banner. Create a new proxy for a new placement or a
new width/orientation request.

### Compatibility aliases

`destroyAdViewAndCancelRequest()` delegates to `destroy()`.

`destoyAdViewAndCancelRequest()` is the deprecated, misspelled alias retained
for older consumers. New code must call `destroy()`.

## Events and payloads

Both banner types emit:

- `AD_LOADED` / `loaded`
- `AD_FAILED_TO_LOAD` / `failed_to_load`
- `AD_CLICKED` / `clicked`
- `AD_IMPRESSION` / `impression`
- `AD_OPENED` / `opened`
- `AD_CLOSED` / `closed`
- `AD_DESTROYED` / `destroyed`

Every payload includes:

```js
{
  adUnitId: 'ca-app-pub-…/…',
  adType: 'banner',
  isAdaptive: true
}
```

Adaptive payloads also include `adaptiveType`.

A failure adds:

```js
{
  error: 'Native error message',
  code: 3
}
```

An adaptive `loaded` event guarantees:

```js
{
  height: 90,
  heightUnit: 'dp'
}
```

Android additionally reports diagnostic size fields:

```js
{
  width: 392,
  widthUnit: 'dp',
  widthPx: 1080,
  heightPx: 253,
  density: 2.75
}
```

Only `height` and `heightUnit` are cross-platform contract fields. Do not
assume Android's pixel fields exist on iOS.

## Standard banner

```js
const banner = Admob.createBanner({
  adUnitId: Admob.TEST_BANNER,
  adSize: Admob.BANNER,
  width: Ti.UI.FILL
})

bannerHost.add(banner)
banner.load()
```

### Creation properties

| Property | Type | iOS | Android | Notes |
|---|---|---:|---:|---|
| `adUnitId` | String | Yes | Yes | Required. |
| `adSize` | String | Yes | Yes | Defaults to `BANNER`. |
| `customAdSize` | Object | No | Yes | `{ width, height }` in dp. |
| `keywords` | String[] | Accepted, not applied | Yes | Request keywords. |
| `contentUrl` | String | No | Yes | Surrounding content URL. |
| `extras` | Object | Accepted, not applied | Yes | Google adapter extras. |

Portable fixed sizes:

- `BANNER`
- `LARGE_BANNER`
- `MEDIUM_RECTANGLE`
- `FULLBANNER`
- `LEADERBOARD`

Unknown values fall back to `BANNER`. Legacy `smart_banner` also falls back to
`BANNER`; use `createAdaptiveBanner()` instead.

Changing `adSize` on an existing iOS native banner is not supported. Destroy
and recreate the proxy.

## Refresh behavior

Do not add a JavaScript renewal timer. Google Mobile Ads respects the banner
refresh rate configured for the ad unit in AdMob. The application should load
when creating the placement and let the SDK/ad-unit configuration own refresh.
