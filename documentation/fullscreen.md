# Fullscreen ads

Interstitial, rewarded and app open proxies share one public lifecycle and event contract on iOS and Android. All three were unified in `2.0.0`.

## When to show a fullscreen ad

A banner is a slot the user learns to look past. A fullscreen ad takes the whole screen, and takes it away from whatever the user was doing, so the hard part is not loading one. It is choosing the moment.

**Load early, show later.** `load()` is a network request and can take seconds. Start it well before the moment you intend to interrupt — when the level opens, when the article starts, when the form is first shown — and call `show()` only when that moment arrives. Presenting from inside the `loaded` listener collapses the two decisions into one and interrupts at whatever second the network happened to answer, which is never a moment you chose.

**Interrupt only at a natural break**: between levels, after a task completes, when a flow ends. Never in the middle of one.

Google's guidance rules out the cases that annoy users most:

- Do not show an interstitial as the app opens. That moment belongs to the App Open format, documented below.
- Do not show one on the way out, when the user is already leaving.
- Do not interrupt an action in progress, or place the ad where a button or a control the user was about to touch used to be.
- Do not reward the user for watching an interstitial. That is what `createRewarded()` is for.
- Do not show them back to back, or so often that the app feels like a delivery mechanism for ads. Frequency capping is configured on the ad unit in the AdMob console, not in JavaScript.

The full lists are in Google's [Android interstitial guide](https://developers.google.com/admob/android/interstitial) and [iOS interstitial guide](https://developers.google.com/admob/ios/interstitial).

## Privacy gate

Fullscreen proxies do not call UMP and do not enforce ad eligibility:

```js
if (!Admob.canRequestAds()) {
  return
}
```

Create and load fullscreen ads only after `module_initialized` succeeds.

## Interstitial

Loading and presenting are two separate decisions. Prepare the ad ahead of time:

```js
const interstitial = Admob.createInterstitial({
  adUnitId: Admob.TEST_INTERSTITIAL,
  autoReload: false
})

interstitial.addEventListener(Admob.AD_LOADED, () => {
  Ti.API.info('Interstitial is ready for the next break')
})

interstitial.addEventListener(Admob.AD_FAILED_TO_LOAD, event => {
  Ti.API.warn(`Interstitial failed: ${event.error} (${event.code})`)
})

interstitial.load()
```

Then present it when the application reaches the break it chose:

```js
function onLevelCompleted() {
  if (interstitial && interstitial.isLoaded()) {
    interstitial.show()
  }

  goToNextLevel()
}
```

An ad that is not ready is not a reason to hold up the application. Continue without it and let the next break use the next load.

The executable [example app](../example/app.js) wires exactly this shape to two buttons, Load and Show, so the separation is visible while testing.

## Rewarded

Reward the user only from the `rewarded` event:

```js
const rewarded = Admob.createRewarded({
  adUnitId: Admob.TEST_REWARDED,
  autoReload: false
})

rewarded.addEventListener(Admob.AD_REWARDED, event => {
  grantReward(event.rewardAmount, event.rewardType)
})

rewarded.addEventListener(Admob.AD_FAILED_TO_SHOW, event => {
  Ti.API.warn(`Rewarded ad could not show: ${event.error}`)
})

rewarded.load()
```

Closing a rewarded ad is not proof that the reward was earned.

## App open

An app open ad is the one format meant for the moment the application comes to the foreground — a cold start, or a return from the background. Load it before that moment arrives, and present it while the application is showing its own loading state rather than on top of a screen the user is already using:

```js
const appOpen = Admob.createAppOpen({
  adUnitId: Admob.TEST_APP_OPEN,
  autoReload: false
})

appOpen.addEventListener(Admob.AD_LOADED, () => {
  Ti.API.info('App open ad is ready for the next foreground')
})

appOpen.load()
```

```js
function onApplicationResumed() {
  if (appOpen && appOpen.isLoaded()) {
    appOpen.show()
  }
}
```

### The four hour window

Google documents that an app open ad expires four hours after it was requested. An ad rendered later is no longer valid and may not earn revenue, so the proxy enforces the window itself, with no timer and no extra event:

- The load time is recorded when the ad arrives.
- `isLoaded()` returns `false` once four hours have passed. An expired ad is not ready, which is what that method has always reported.
- `show()` on an expired ad clears the native reference and emits `failed_to_show` with code `1` and the message `App open ad expired after four hours`.
- `load()` discards an expired ad before requesting a new one, so a reload after expiry is not swallowed by the duplicate-load guard.

`autoReload` is unchanged: it reloads after `closed` and after nothing else, so reloading an expired ad is the application's decision, not the proxy's. The check is a subtraction performed when someone asks — nothing polls in the background.

## Creation properties

All three factories accept:

| Property | Type | Default | Notes |
|---|---|---|---|
| `adUnitId` | String | `""` | Required before `load()`. |
| `autoReload` | Boolean | `false` | Loads a fresh ad after a successful close, and after nothing else. |
| `keywords` | String[] | None | Request keywords, applied as targeting on both platforms. |
| `requestAgent` | String | None | Identifies what issued the request. Android only for these three types; see the note below. |
| `extras` | Object | None | Forwarded through Google ad-network extras on both platforms. |

Do not use `extras` to bypass UMP or synthesize personalization state.

`requestAgent` reaches the request from both banner types on both platforms, but the three iOS fullscreen proxies drop it. Setting it here is harmless and portable, and it currently takes effect on Android only. The defect is recorded in [the roadmap](../ROADMAP.md) as declared parity debt.

## Shared methods

| Method | Description |
|---|---|
| `load()` | Starts one request. Calls while loading, loaded, or showing are ignored. App open discards an expired ad first. |
| `show()` | Presents the loaded ad or emits `failed_to_show`. |
| `isLoaded()` | Returns `true` only while an unused ad is ready. For app open, an ad older than four hours is not ready. |
| `destroy()` | Terminal, idempotent cleanup; emits `destroyed` once. |

Google fullscreen ads are single-use. After a presentation or a show failure the proxy holds no ad: its native reference is cleared and `isLoaded()` turns `false`. Call `load()` again before the next `show()`.

Late native callbacks are ignored after `destroy()`. A dismissed or failed-to-show ad reference is cleared before the terminal event is emitted.

## Keeping the next ad ready

Because each ad is single-use, an application that interrupts more than once per session reloads as soon as the previous ad is gone, so the next break finds an ad already loaded instead of waiting on the network:

```js
interstitial.addEventListener(Admob.AD_CLOSED, () => {
  interstitial.load()
})
```

`autoReload: true` does that for you, and only that: it reloads after `closed`. It does not reload after `failed_to_load`, and it does not reload after `failed_to_show`. Those two cases stay the application's job, and both deserve backoff rather than an immediate retry — a `NO_FILL` answered instantly is usually still `NO_FILL` a second later.

Reloading is not the same as recreating. Reuse the same proxy across loads, and create a new one only after `destroy()`.

## Events

### Common events

| Event | Interstitial | Rewarded | App open | Common payload |
|---|---:|---:|---:|---|
| `loaded` | Yes | Yes | Yes | `adUnitId`, `adType` |
| `failed_to_load` | Yes | Yes | Yes | `adUnitId`, `adType`, `error`, `message`, `code` |
| `opened` | Yes | Yes | Yes | `adUnitId`, `adType` |
| `showed_fullscreen_content` | Yes | Yes | Yes | `adUnitId`, `adType` |
| `closed` | Yes | Yes | Yes | `adUnitId`, `adType` |
| `clicked` | Yes | Yes | Yes | `adUnitId`, `adType` |
| `impression` | Yes | Yes | Yes | `adUnitId`, `adType` |
| `failed_to_show` | Yes | Yes | Yes | `adUnitId`, `adType`, `error`, `message`, `code` |
| `destroyed` | Yes | Yes | Yes | `adUnitId`, `adType` |
| `rewarded` | No | Yes | No | `adUnitId`, `adType`, `rewardType`, `rewardAmount` |

`message` intentionally duplicates `error` for compatibility. New code may use `error`; both keys are portable.

## Cleanup

Use named callbacks and remove them before disposing the proxy:

```js
function disposeInterstitial() {
  interstitial.removeEventListener(Admob.AD_LOADED, onLoaded)
  interstitial.removeEventListener(Admob.AD_FAILED_TO_LOAD, onFailed)
  interstitial.removeEventListener(Admob.AD_CLOSED, onClosed)
  interstitial.destroy()
}
```

After disposal, create a new proxy rather than attempting to load the destroyed one again.

## Not implemented

The module exports format-name and test-ID constants for future compatibility, but it does not expose working factories for:

- Rewarded interstitial
- Native

`TEST_REWARDED_INTERSTITIAL` and `TEST_NATIVE` name units no factory accepts.
