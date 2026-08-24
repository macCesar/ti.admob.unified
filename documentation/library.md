# Copy-ready JavaScript library

The repository ships a complete integration layer at [`example/lib/ads.js`](../example/lib/ads.js). Copy that file unchanged to one of these locations:

- Alloy: `app/lib/ads.js`
- Classic Titanium: `Resources/lib/ads.js`

Then import it with:

```js
const Admob = require('ti.admob.unified')
const ads = require('lib/ads')
```

The library is optional. The native module remains usable directly, as shown by [`example/app.js`](../example/app.js). The library packages the parts that otherwise every application has to repeat correctly: UMP sequencing, the `canRequestAds()` gate, initialization, named-listener cleanup, banner slot ownership, deferred loads, privacy-option reauthorization, and terminal cleanup.

## What it covers

| Format | Library factory | Lifecycle returned |
| --- | --- | --- |
| Standard banner | `createBanner()` | `pause()`, `resume()`, `retry()`, `rebuild()`, `isLoaded()`, `destroy()` |
| Adaptive banner | `createAdaptiveBanner()` | `pause()`, `resume()`, `retry()`, `rebuild()`, `isLoaded()`, `destroy()` |
| Interstitial | `createInterstitial()` | `load()`, `show()`, `retry()`, `isLoaded()`, `destroy()` |
| Rewarded | `createRewarded()` | `load()`, `show()`, `retry()`, `isLoaded()`, `destroy()` |
| App open | `createAppOpen()` | `load()`, `show()`, `retry()`, `isLoaded()`, `destroy()` |

Rewarded interstitial and native ads are not included because version `1.0.0` does not implement those factories.

## Start once

Create placements before or after `start()`. A load requested before initialization waits for the privacy and SDK gates instead of racing them.

```js
ads.start({
  consent: {
    tagForUnderAgeOfConsent: false
  },
  initialization: {
    disableMediation: true,
    testDeviceIds: ['YOUR_TEST_DEVICE_ID']
  }
}).then(result => {
  if (!result.initialized) {
    Ti.API.warn('Ads are unavailable for this session')
  }
})
```

Set `requestTrackingAuthorization: true` only when the application has a real ATT use case and a valid `NSUserTrackingUsageDescription`. ATT is not another ad-request gate.

## Banners

A banner needs a permanent host and a positive reservation in dp. The library changes the host height and the adjacent content inset together; it never overlays the content.

```js
const banner = ads.createAdaptiveBanner({
  host: bannerHost,
  content,
  reservedHeight: 50,
  adUnitId: Admob.TEST_ADAPTIVE_BANNER,
  adaptiveType: Admob.ADAPTIVE_ANCHORED,
  onLoaded: event => Ti.API.info(`Banner: ${event.height}${event.heightUnit}`),
  onFailedToLoad: event => Ti.API.warn(event.error)
})
```

Use `createBanner()` with `adSize` or `customAdSize` for a fixed banner. Use `createAdaptiveBanner()` when Google should choose the height for the available width.

Call `pause()` when that placement stops being shown because the application selected another tab or opened another window over it. Call `resume()` when the same screen is shown again. These methods preserve the same native proxy, creative, visibility, opacity, host, and reserved height:

```js
banner.pause()
openChildWindow()

child.addEventListener('close', () => {
  banner.resume()
})
```

Do not mirror `Ti.App` background and foreground events. The native module already owns activity/application lifecycle as an independent pause cause.

The library creates no refresh timer. The first request comes from `load()`; later banner refreshes belong to Google Mobile Ads and the refresh policy configured for that ad unit in AdMob. A banner that is not actually on screen is ineligible for Android auto-refresh. On iOS the module disables and restores native autoload while paused.

`retry()` is for a recoverable failure. `rebuild()` is for a real configuration boundary such as a width/orientation change. Tab focus, window focus, appearance changes, and ordinary background/foreground transitions are not rebuild reasons.

## Fullscreen ads

Create once, load early, and show only at a moment chosen by the application:

```js
const interstitial = ads.createInterstitial({
  adUnitId: Admob.TEST_INTERSTITIAL,
  autoReload: true,
  onLoaded: () => Ti.API.info('Ready for the next natural break')
})

interstitial.load()

function onNaturalBreak() {
  interstitial.show() // false means no ready ad; continue without blocking
}
```

Rewarded ads grant value only from `onRewarded`:

```js
const rewarded = ads.createRewarded({
  adUnitId: Admob.TEST_REWARDED,
  onRewarded: event => grantReward(event.rewardAmount, event.rewardType)
})
```

App-open ads are prepared the same way and shown only during the application's own foreground loading experience:

```js
const appOpen = ads.createAppOpen({
  adUnitId: Admob.TEST_APP_OPEN
})

appOpen.load()

function onApplicationResumed() {
  appOpen.show()
}
```

`show()` returns `false` when no valid ad is ready. Do not delay navigation or user work waiting for a fullscreen request.

## Privacy and diagnostics

Expose the privacy entry point only when required:

```js
privacyButton.visible = ads.isPrivacyOptionsRequired()

function openPrivacyOptions() {
  ads.showPrivacyOptions().then(event => {
    if (event.success === false) {
      Ti.API.warn(event.error)
    }
  })
}
```

After the form closes, the library reevaluates authorization and rebuilds active ad requests only because consent may have changed.

Ad Inspector also has a promise wrapper:

```js
ads.openAdInspector().then(event => {
  if (!event.success) {
    Ti.API.warn(event.error)
  }
})
```

## Cleanup

Destroy a placement when its owning window closes. For application shutdown or a test harness, dispose every registered placement at once:

```js
win.addEventListener('close', () => banner.destroy())

// Or, when this ads service owns every placement:
ads.destroyAll()
```

Every destroy operation is idempotent. A destroyed manager is terminal; create another manager when the application genuinely needs a new placement.

The complete runnable wiring is in [`example/library-usage.js`](../example/library-usage.js).
