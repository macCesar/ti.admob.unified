# Banner ads

Standard and adaptive banners share one public lifecycle and event contract on iOS and Android.

Both factories return a Titanium `TiViewProxy`, so their creation dictionaries also accept normal Titanium view/layout properties such as `width`, `height`, `top`, `bottom`, `left`, and `right`. The tables below list the AdMob-specific properties.

## Choose a banner type

Use `createAdaptiveBanner()` for a banner anchored outside scrolling content. Its height is calculated from the available width, orientation, and device.

Use `createBanner()` when the placement explicitly requires a fixed Google ad size such as `BANNER`, `MEDIUM_RECTANGLE`, or `LEADERBOARD`.

| Capability                     | iOS | Android                 |
| ------------------------------ | --- | ----------------------- |
| Standard fixed-size banner     | Yes | Yes                     |
| Large anchored adaptive banner | Yes | Yes                     |
| Inline adaptive banner         | Yes | Yes                     |
| Collapsible anchored banner    | No  | Experimental raw option |
| Dynamic loaded height          | Yes | Yes                     |

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

The proxy must be in the Titanium view hierarchy before `load()` so its native view can measure the real container width.

### Creation properties

| Property       | Type     |         iOS |      Android | Notes                                                        |
| -------------- | -------- | ----------: | -----------: | ------------------------------------------------------------ |
| `adUnitId`     | String   |         Yes |          Yes | Required.                                                    |
| `adaptiveType` | String   |         Yes |          Yes | Defaults to `ADAPTIVE_ANCHORED`.                             |
| `maxHeight`    | Number   | Inline only |  Inline only | Maximum inline height in dp; both platforms default to `50`. |
| `collapsible`  | String   | Experimental | Experimental | Native placement string: `"top"` or `"bottom"`.             |
| `keywords`     | String[] |         Yes |          Yes | Prefer contextual configuration in AdMob.                    |
| `contentUrl`   | String   |         Yes |          Yes | URL describing surrounding content.                          |
| `requestAgent` | String   |         Yes |          Yes | Identifies what issued the request.                          |
| `extras`       | Object   |         Yes |          Yes | Google adapter request extras.                               |

On iOS, the native implementation always creates a **large** anchored adaptive banner, and that is not a shortcut: Google deprecated the plain anchored functions in favour of the large ones. The large size is between 50 and 150 points tall and never exceeds 20% of the screen; the deprecated one capped at 90 points and 15%. If a shorter fixed strip is what you want, use `createBanner()` with `customAdSize`.

Events echo back the constant you passed, so `event.adaptiveType` can be compared against `ADAPTIVE_ANCHORED` or `ADAPTIVE_INLINE` on either platform.

`ADAPTIVE_INLINE` and `maxHeight` work on both platforms. Inline scrolls with your content and you cap its height; anchored sits at a screen edge and Google fixes the height, which is why `maxHeight` only applies to inline.

`collapsible` works on both platforms and takes Google's native placement string, `"top"` or `"bottom"`. There is no `COLLAPSIBLE_TOP` or `COLLAPSIBLE_BOTTOM` constant to pass here, and that is deliberate: such a constant would have to carry a value the SDK accepts, and Google accepts only those two words.

It travels as an ad-network extra on both sides — a Bundle on Android, a `GADExtras` on iOS — under the same key, so the same JavaScript produces the same request. Whether the ad actually collapses is decided by the ad unit and the creative, not by the module: an ad unit that is not configured as collapsible in AdMob ignores the option.

Google's current requirements are described in the collapsible banner guide, published per platform: [Android](https://developers.google.com/admob/android/banner/collapsible), [iOS](https://developers.google.com/admob/ios/banner/collapsible).

## Reserve real layout space

The loaded height uses density-independent units on both platforms:

```js
banner.addEventListener(Admob.AD_LOADED, event => {
  bannerHost.height = `${event.height}dp`
})
```

Do not hardcode a height. Adaptive banners can change height across devices, densities, widths, and orientations.

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

This keeps the banner inside the visible layout and prevents it from overlapping lists, navigation, snackbars, or other bottom-aligned UI. Place `root` inside the app's safe-area-aware content region.

Do not use a vertical layout where a preceding `Ti.UI.FILL` child consumes the entire height and pushes the banner host below the window.

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

Call `pauseBanner()` when the screen that owns the placement stops being shown, `resumeBanner()` when it comes back, and `destroyBanner()` when the placement or window closes.

### Who pauses a banner

Two independent causes can hold a banner paused, and the module tracks them separately:

| Cause       | Trigger                                                  | Platform        |
| ----------- | -------------------------------------------------------- | --------------- |
| Application | your `pause()` / `resume()` calls                        | Both            |
| Lifecycle   | activity `onPause`/`onResume`, app background/foreground | Both, automatic |

**Neither cause resumes the other's pause.** A banner you paused because its tab is hidden stays paused when the app returns from the background, and a banner the lifecycle paused stays paused until the app is visible again — even if you called `resume()` meanwhile. A load deferred while paused waits for *every* cause to clear, so it never fires into a placement nobody is looking at.

This means you only have to own the reason you know about — which screen is showing — and never have to mirror the app's background state to keep the two from fighting.

The lifecycle cause is automatic on both platforms: Android follows the hosting activity, and iOS observes application background/foreground. An Android secondary window backed by another activity therefore needs no manual pause/resume wiring. Use the public methods only for navigation that hides a placement while its host lifecycle remains active, such as a custom same-activity overlay. iOS deliberately uses background/foreground rather than resign/become-active, because a Control Center pull or a call banner resigns active while the ad is still on screen and still viewable.

Android may recreate its activity for a configuration change such as light/dark appearance. That is not terminal destruction: the module releases the stale native `AdView`, keeps the JavaScript proxy alive, and requests a replacement banner after Titanium creates the new native view. It does not emit `destroyed` for this transition. The creative itself cannot be carried between activities because an Android `View` belongs to the activity that created it.

## Runtime properties

Banner proxies are not write-once. Both platforms expose their creation properties for reading and writing after the proxy exists, and they fall into three groups with different timing.

**Applied on the next `load()`.** `keywords`, `contentUrl`, `requestAgent`, `extras` and `collapsible` only reach AdMob through a new ad request, so assigning them does nothing to the creative currently on screen:

```js
banner.extras = { collapsible: 'bottom' }
banner.requestAgent = 'my-app/2.1'
banner.load()  // now they travel
```

**Applied immediately, and not recommended.** `adSize` and `customAdSize` rebuild the native `AdView` on Android, discarding the loaded creative, and do nothing on iOS. Destroy the proxy and create a new one instead — that is the only path that behaves the same on both platforms.

**Never assign after creation.** `adUnitId` is propagated to the live native view on Android, and Google's SDK throws there: *"The ad unit ID can only be set once on AdView."* A banner that has already loaded once will crash the application rather than switch units. Create a second proxy for a second placement.

### What Android writes back

Android overwrites the proxy's own `height` when the ad size is known, and the two banner types write different types into it:

| Banner   | What Android assigns   | Example  |
| -------- | ---------------------- | -------- |
| Standard | A number, in dp        | `50`     |
| Adaptive | A string, in dp        | `"64dp"` |

iOS assigns neither. If you read `banner.height` back, handle both a number and a `"…dp"` string, or read `event.height` from the `loaded` payload instead — that one is a number on both platforms.

Android also treats `top`, `left` and `right` as native padding on the `AdView`, on top of the Titanium layout meaning. iOS applies only the Titanium layout.

## Shared methods

### `load()`

Starts an ad request.

- A second call is ignored while a request is active.
- A call while paused defers at most one request until `resume()`.
- A call after `destroy()` cannot recreate the proxy and emits `failed_to_load`.

### `pause()`

Idempotently records an application-owned pause. It does not change `visible`, `opacity`, height, or its host, and it does not replace the native proxy or loaded creative.

The native mechanisms are not symmetric because Google's SDKs are not symmetric:

| Behavior | iOS | Android |
| --- | --- | --- |
| Changes visual state or layout | No | No |
| Suspends ad-view processing | No equivalent API | Yes, via `AdView.pause()` |
| Stops native autoload directly | Yes, via `autoloadEnabled = NO` | No direct refresh switch |

On Android, `AdView.pause()` is documented as pausing extra processing; it is not a public refresh-control API. Google Mobile Ads separately refreshes only a banner it considers visible on screen. Therefore call `pause()` when the owning tab is deselected or another opaque window covers it — states in which it is genuinely not on screen — and keep the proxy visually unchanged. If custom navigation leaves the banner actually visible to the user, do not pause it merely because a controller flag changed.

On iOS, the module stores the banner's existing `autoloadEnabled` value and sets it to `NO`. This prevents native autoload while leaving the same view and creative intact.

A `load()` requested during either pause cause is deferred. This prevents the first request from being issued into a placement the application is not showing, without relying on a visibility mutation.

Do not destroy/recreate to simulate a pause. That discards the creative, creates a new request on return, and makes ordinary navigation visibly slower.

### `resume()`

Idempotently resumes the banner and runs one deferred load, if present, but only once every pause cause has cleared. See [Who pauses a banner](#who-pauses-a-banner).

It reverses only the native pause: Android resumes ad-view processing and iOS restores the `autoloadEnabled` value the banner had before pausing. There is no visibility or layout transition to undo. Because application lifecycle is tracked separately, `resume()` cannot accidentally clear a background pause.

### `isLoaded()`

Returns `true` only while the current proxy owns a successfully loaded ad.

### `destroy()`

Terminal and safe to repeat. It releases the native ad, detaches native delegates/listeners and lifecycle registrations, and emits `destroyed` once.

Never reuse a destroyed banner. Create a new proxy for a new placement or a new width/orientation request.

### Compatibility aliases

`destroyAdViewAndCancelRequest()` delegates to `destroy()`.

`destoyAdViewAndCancelRequest()` is the deprecated, misspelled alias retained for older consumers. New code must call `destroy()`.

## Events and payloads

Both banner types emit:

- `AD_LOADED` / `loaded`
- `AD_FAILED_TO_LOAD` / `failed_to_load`
- `AD_CLICKED` / `clicked`
- `AD_IMPRESSION` / `impression`
- `AD_OPENED` / `opened`
- `AD_CLOSED` / `closed`
- `AD_DESTROYED` / `destroyed`

Every payload includes `adUnitId`, `adType: 'banner'`, and `isAdaptive`, which reports which factory created the proxy: `true` from `createAdaptiveBanner()`, `false` from `createBanner()`.

```js
{
  adUnitId: 'ca-app-pub-…/…',
  adType: 'banner',
  isAdaptive: false
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

Only `height` and `heightUnit` are cross-platform contract fields. Do not assume Android's pixel fields exist on iOS.

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

| Property       | Type     |  iOS | Android | Notes                                                                            |
| -------------- | -------- | ---: | ------: | -------------------------------------------------------------------------------- |
| `adUnitId`     | String   |  Yes |     Yes | Required.                                                                        |
| `adSize`       | String   |  Yes |     Yes | Defaults to `BANNER`.                                                            |
| `customAdSize` | Object   |  Yes |     Yes | `{ width, height }` in dp. Wins over `adSize`. Ignored unless both are positive. |
| `keywords`     | String[] |  Yes |     Yes | Request keywords.                                                                |
| `contentUrl`   | String   |  Yes |     Yes | Surrounding content URL.                                                         |
| `requestAgent` | String   |  Yes |     Yes | Identifies what issued the request.                                              |
| `extras`       | Object   |  Yes |     Yes | Google adapter extras.                                                           |

`customAdSize` builds `new AdSize(width, height)` on Android and `GADAdSizeFromCGSize` on iOS, so one object produces the same request on both.

Both numbers are in density-independent units, and computing the screen width is where portable code usually breaks: `Ti.Platform.displayCaps.platformWidth` returns **pixels on Android** but **points on iOS**, and points are already the unit this property expects. Dividing by `logicalDensityFactor` on both platforms is the mistake that looks correct — on a 3x iPhone it asks for a third of the screen and you get a small banner floating in a full-width slot.

```js
function screenWidthInDp() {
  const caps = Ti.Platform.displayCaps

  if (Ti.Platform.osname === 'android') {
    return Math.round(caps.platformWidth / caps.logicalDensityFactor)
  }

  return Math.round(caps.platformWidth)
}
```

This conversion belongs to Titanium, not to this module: the module passes the two numbers through untouched, which is also why it cannot correct a wrong one for you. It is applied when the native view is created; changing it afterwards does not resize a live banner on iOS, exactly as `adSize` already behaved. Destroy the placement and create it again to change size.

An oversized custom slot does not invent inventory: AdMob fills the sizes it sells. Ask for a size your ad units actually serve.

Portable fixed sizes, with the device each one was designed for and the height its host view must reserve:

| Constant           | Size    | Intended device |
| ------------------ | ------- | --------------- |
| `BANNER`           | 320×50  | Phone           |
| `LARGE_BANNER`     | 320×100 | Phone           |
| `MEDIUM_RECTANGLE` | 300×250 | Tablet          |
| `FULLBANNER`       | 468×60  | Tablet          |
| `LEADERBOARD`      | 728×90  | Tablet          |

Those are Google's own descriptions in `GADAdSize.h`, and the widths are the part that bites. A phone is 360–430 dp wide, so a `FULLBANNER` asks for 468 dp that the screen does not have: it cannot render at full size no matter what height you give its container. `BANNER` is not an outdated size — it is the phone size. For a full-width strip on a phone use `customAdSize` with the screen width, or an adaptive banner.

Give the host view the exact height of the size you asked for. A `FULLBANNER` in a 50 dp box is not a smaller full banner; it is a clipped one.

Unknown values fall back to `BANNER`, and `smart_banner` is one of them. Google removed the size from the Android SDK and deprecated it on iOS, so this module gives it no special case: one value that resolved to a fixed 320×50 on one platform and a full-width strip on the other would be the module deciding for you. For a full-width strip use `customAdSize`, or `createAdaptiveBanner()` if you want Google to choose the height.

Changing `adSize` on an existing iOS native banner is not supported. Destroy and recreate the proxy.

## Refresh behavior

Do not add a JavaScript renewal timer. Google Mobile Ads respects the banner refresh rate configured for the ad unit in AdMob. The application should load when creating the placement and let the SDK/ad-unit configuration own refresh.
