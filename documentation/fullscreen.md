# Fullscreen ads

Version `1.2.0` gives interstitial and rewarded proxies the same public
lifecycle and event contract on iOS and Android.

## Privacy gate

Fullscreen proxies do not call UMP and do not enforce ad eligibility:

```js
if (!Admob.canRequestAds()) {
  return
}
```

Create and load fullscreen ads only after `module_initialized` succeeds.

## Interstitial

```js
const interstitial = Admob.createInterstitial({
  adUnitId: Admob.TEST_INTERSTITIAL,
  autoReload: false
})

interstitial.addEventListener(Admob.AD_LOADED, () => {
  if (interstitial.isLoaded()) {
    interstitial.show()
  }
})

interstitial.addEventListener(Admob.AD_FAILED_TO_LOAD, event => {
  Ti.API.warn(`Interstitial failed: ${event.error} (${event.code})`)
})

interstitial.load()
```

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

## Creation properties

Both factories accept:

| Property | Type | Default | Notes |
|---|---|---|---|
| `adUnitId` | String | `""` | Required before `load()`. |
| `autoReload` | Boolean | `false` | Loads a fresh ad after a successful close. |
| `keywords` | String[] | None | Android adds request keywords. iOS encodes them as `GADExtras` parameters. |
| `extras` | Object | None | Forwarded through Google ad-network extras on both platforms. |

Do not use `extras` to bypass UMP or synthesize personalization state.

## Shared methods

| Method | Description |
|---|---|
| `load()` | Starts one request. Calls while loading, loaded, or showing are ignored. |
| `show()` | Presents the loaded ad or emits `failed_to_show`. |
| `isLoaded()` | Returns `true` only while an unused ad is ready. |
| `destroy()` | Terminal, idempotent cleanup; emits `destroyed` once. |

Google fullscreen ads are single-use. After presentation or a show failure,
load a fresh instance. `autoReload: true` reloads after `closed`; it does not
reload after every load/show error.

Late native callbacks are ignored after `destroy()`. A dismissed or
failed-to-show ad reference is cleared before the terminal event is emitted.

## Events

### Common events

| Event | Interstitial | Rewarded | Common payload |
|---|---:|---:|---|
| `loaded` | Yes | Yes | `adUnitId`, `adType` |
| `failed_to_load` | Yes | Yes | `adUnitId`, `adType`, `error`, `message`, `code` |
| `opened` | Yes | Yes | `adUnitId`, `adType` |
| `showed_fullscreen_content` | Yes | Yes | `adUnitId`, `adType` |
| `closed` | Yes | Yes | `adUnitId`, `adType` |
| `clicked` | Yes | Yes | `adUnitId`, `adType` |
| `impression` | Yes | Yes | `adUnitId`, `adType` |
| `failed_to_show` | Yes | Yes | `adUnitId`, `adType`, `error`, `message`, `code` |
| `destroyed` | Yes | Yes | `adUnitId`, `adType` |
| `rewarded` | No | Yes | `adUnitId`, `adType`, `rewardType`, `rewardAmount` |

`message` intentionally duplicates `error` for compatibility. New code may use
`error`; both keys are portable.

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

After disposal, create a new proxy rather than attempting to load the destroyed
one again.

## Not implemented

The module exports format-name and test-ID constants for future compatibility,
but it does not expose working factories for:

- App open
- Rewarded interstitial
- Native

The iOS `createAppOpen()` symbol is a reserved compatibility stub that returns
no proxy. Android does not export it. Do not call it.
