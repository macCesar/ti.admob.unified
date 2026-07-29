# Fullscreen ads

Version `1.2.0` preserves the existing interstitial and rewarded proxies. Their
factories and basic methods work on both platforms, but these proxies have not
received the strict payload/lifecycle parity pass applied to banners.

Use them only after validating the required behavior on both target platforms.

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
| `extras` | Object | None | iOS registers `GADExtras`. Android accepts the object but does not currently add it to the ad request. |

Do not use `extras` to bypass UMP or synthesize personalization state.

## Shared methods

| Method | Description |
|---|---|
| `load()` | Starts loading an ad. Duplicate Android loads are ignored while active. |
| `show()` | Presents the loaded ad or emits `failed_to_show`. |
| `isLoaded()` | Returns whether an ad instance is ready. |
| `destroy()` | Clears the held ad reference. |

Google fullscreen ads are single-use. After presentation or a show failure,
load a fresh instance. `autoReload: true` reloads after `closed`; it does not
reload after every load/show error.

## Events

### Common events

| Event | Interstitial | Rewarded | Common payload |
|---|---:|---:|---|
| `loaded` | Yes | Yes | `adUnitId` |
| `failed_to_load` | Yes | Yes | `adUnitId`, `error`, `code` |
| `opened` | Yes | Yes | `adUnitId` |
| `closed` | Yes | Yes | `adUnitId` |
| `clicked` | Yes | Yes | `adUnitId` |
| `impression` | Yes | Yes | `adUnitId` |
| `failed_to_show` | Yes | Yes | `adUnitId`, `error`; `code` when native SDK supplies it |
| `rewarded` | No | Yes | `adUnitId`, `rewardType`, `rewardAmount` |

Android `failed_to_load` also includes `message`, duplicating `error`. Do not
depend on `message` in shared code.

### Known platform difference

Android emits both `opened` and `showed_fullscreen_content` when fullscreen
content appears. iOS emits `opened` but does not currently emit
`showed_fullscreen_content`.

Subscribe to `opened` for portable behavior.

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

## Not implemented

The module exports format-name and test-ID constants for future compatibility,
but it does not expose working factories for:

- App open
- Rewarded interstitial
- Native

The iOS `createAppOpen()` symbol is a reserved compatibility stub that returns
no proxy. Android does not export it. Do not call it.
