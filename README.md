# ti.admob.unified

`ti.admob.unified` provides one Titanium JavaScript API for Google Mobile Ads and the User Messaging Platform (UMP) on iOS and Android.

Version `2.0.0` provides a safe privacy flow, idempotent SDK operations, and shared lifecycle and event contracts for banners, interstitials, rewarded ads, and app open ads. Mediation is a separate, optional module — `ti.admob.unified.mediation` — carrying current AdMob adapters and native SDKs for Meta, InMobi, Unity Ads, AppLovin, Liftoff Monetize, and ironSource on both platforms. Applications keep one JavaScript ad API either way; AdMob selects the configured ad source.

Upgrading from `1.x`, or replacing `ti.admob`, `ti.android.admob`, or an internal pre-release build? See [Migrating to ti.admob.unified](documentation/migration.md). **An application that mediates today must install the mediation pack when it moves to `2.0.0`, or it stops mediating without an error.**

Want the application-side integration ready-made? Copy [`example/lib/ads.js`](example/lib/ads.js) into your project's `lib/`. It sequences privacy and initialization, manages standard/adaptive banners plus interstitial, rewarded and app-open ads, and performs deterministic cleanup without refresh timers. See [Copy-ready JavaScript library](documentation/library.md).

## Why one module instead of two

Titanium has had AdMob modules for years, one per platform, each with its own names, its own events and its own payloads. The cost of that is not the install: it is every branch it forces into your application.

**One declaration.** One module in `tiapp.xml` covers both platforms:

```xml
<modules>
  <module version="2.0.0">ti.admob.unified</module>
</modules>
```

**No platform branches in ad code.** With one module per platform, each one brings its own factory names, property names and constants, so every placement starts with a fork — and both halves have to be kept working. Here there is one call:

```js
const ad = Admob.createBanner({ adUnitId: unitId, adSize: Admob.BANNER })
```

The same holds for the reusability rule that differs between the platform modules: fullscreen ads are single-use here on both platforms, and `autoReload: true` reloads the next one for you.

**One event contract.** Event names, payload keys and value types are identical on iOS and Android, so a handler written once works on both:

```js
ad.addEventListener(Admob.AD_LOADED, event => {
  // adUnitId, adType, isAdaptive — same keys, same types, both platforms
})
```

Where the two SDKs genuinely differ, the difference is named rather than hidden. [The roadmap](ROADMAP.md#differences-that-stay) lists every one of them and why it stays.

**One privacy flow.** UMP consent, the `canRequestAds()` gate and initialization are the same sequence on both platforms. The iOS-only step, App Tracking Transparency, is a portable call that completes immediately on Android with `applicable: false`, so even that needs no branch.

**Mediation parity.** The same six ad sources are available on both platforms through one optional pack, and the adapters are discovered by AdMob. Adding a mediated network changes your AdMob configuration, not your code. See [Mediation parity](MEDIATION_COMPARISON.md).

## Requirements

| Component                 | Baseline    |
| ------------------------- | ----------- |
| Titanium SDK              | `13.4.0.GA` |
| iOS                       | `15.0+`     |
| Android                   | API `24+`   |
| Google Mobile Ads iOS     | `13.7.0`    |
| UMP iOS                   | `3.1.0`     |
| Google Mobile Ads Android | `25.4.0`    |
| UMP Android               | `4.0.0`     |

## Mediation

Mediation lives in a separate, optional module: `ti.admob.unified.mediation`. It has no JavaScript API — it exists to carry the adapters and their network SDKs.

| Ad source                 |  iOS adapter | Android adapter |
| ------------------------- | -----------: | --------------: |
| Meta Audience Network     | `6.21.1.1.1` |      `6.22.0.0` |
| InMobi                    |   `11.4.0.0` |      `11.4.0.0` |
| Unity Ads                 |   `4.19.0.0` |      `4.19.0.0` |
| AppLovin                  |   `13.6.3.0` |      `13.6.3.0` |
| Liftoff Monetize (Vungle) |    `7.7.5.0` |       `7.7.7.0` |
| ironSource                |  `9.5.0.0.0` |       `9.5.0.0` |

Those are **adapter** versions, not the versions of each network's own SDK. An adapter is versioned as `<network SDK version>.<adapter revision>`, so `13.6.3.0` means AppLovin SDK `13.6.3` with adapter revision `0`. The network SDK each adapter pulls in is listed in [Dependencies and checksums](DEPENDENCIES.md).

### Why it is a separate module

Through `1.x` the adapters shipped inside the core module, on the assumption that having them there would raise fill. It does not. A network participates in a request only once its publisher account is approved, it is added as an ad source to an AdMob mediation group, and its credentials are mapped to the ad unit. Without that, an adapter is weight and nothing else — and the weight is not small:

| Artifact                                | iOS ZIP  |   Android ZIP |
| --------------------------------------- | -------: | ------------: |
| `ti.admob.unified` `1.0.0` (everything)  |  `89 MB` | ≈ unchanged   |
| `ti.admob.unified` `2.0.0`               |  `14 MB` |      `325 KB` |
| `ti.admob.unified.mediation` `2.0.0`     |  `75 MB` |      `102 KB` |

The Android ZIP was never the cost there; the module POM was. Through `1.x` it declared the six adapter coordinates as transitive dependencies, so every consuming application inherited six third-party SDKs in its APK with no way to opt out. In `2.0.0` those coordinates live in the pack's POM, so an application that does not declare the pack inherits none of them — along with six fewer Data Safety and App Privacy declarations, and no adapter startup to wait on before the first ad.

### Installing it

```xml
<modules>
  <module version="2.0.0">ti.admob.unified</module>
  <module version="2.0.0">ti.admob.unified.mediation</module>
</modules>
```

Both artifacts ship at the same version and are released together. The adapters are then discovered automatically by Google Mobile Ads. Do not add platform checks or call a different ad factory for a mediated request. Publisher accounts, ad-source mappings, privacy declarations, and provider credentials are still configured outside the module.

Because the adapters are present, Google Mobile Ads can inspect or initialize them when the SDK starts. Development builds with incomplete provider mappings can therefore log setup warnings such as a missing AppLovin SDK key or multiple Liftoff Monetize app IDs. The module does not inject provider IDs or keys; those values come from the AdMob mediation mapping. Treat these warnings as configuration diagnostics and verify the intended source with Ad Inspector before enabling production.

An application that has the pack installed but wants to skip adapter startup in a given session passes `initialize({ disableMediation: true })`. Auto-discovery waits for every installed adapter to answer or time out, so an unmapped provider can delay the first ad by tens of seconds. An application that never mediates simply leaves the pack out.

`getMediationStatus()` stays in the core module and answers with the same six keys either way — all `true` with the pack installed, all `false` without it. Run it before publishing an application that is supposed to mediate. Use Ad Inspector for request-level validation. See [AdMob mediation](documentation/mediation.md).

## Supported formats

| Format                   | iOS             | Android                 |
| ------------------------ | --------------- | ----------------------- |
| Standard banner          | Stable          | Stable                  |
| Anchored adaptive banner | Stable          | Stable                  |
| Inline adaptive banner   | Stable          | Stable                  |
| Collapsible banner       | Experimental    | Experimental            |
| Interstitial             | Stable          | Stable                  |
| Rewarded                 | Stable          | Stable                  |
| App Open                 | Stable          | Stable                  |
| Rewarded interstitial    | Not implemented | Not implemented         |
| Native                   | Not implemented | Not implemented         |

Standard, adaptive, interstitial, rewarded, and app open proxies use portable lifecycle and event payload contracts. See [Fullscreen ads](documentation/fullscreen.md) for the single-use, reward, and four-hour-expiry rules.

## Installation

Install the `2.0.0` ZIP for each target platform and declare the module:

```xml
<modules>
  <module version="2.0.0">ti.admob.unified</module>
</modules>
```

Add `ti.admob.unified.mediation` at the same version only if the application mediates.

The consuming app must also set its AdMob application ID in `tiapp.xml`. Application IDs are not passed to `initialize()`.

See [Getting started](documentation/getting-started.md) for the complete iOS and Android configuration.

## Safe initialization

Register listeners before starting UMP. Request consent at every app launch, use `canRequestAds` as the only ad-request gate, and initialize Google Mobile Ads only after that gate opens.

```js
const Admob = require('ti.admob.unified')

let initializationStarted = false

function initializeAdsOnce() {
  if (initializationStarted || !Admob.canRequestAds()) {
    return
  }

  initializationStarted = true
  Admob.initialize({
    ageRestrictedTreatment: Admob.AGE_RESTRICTED_TREATMENT_UNSPECIFIED,
    maxAdContentRating: Admob.MAX_AD_CONTENT_RATING_GENERAL
  })
}

Admob.addEventListener('module_initialized', event => {
  if (!event.success) {
    Ti.API.warn(`AdMob initialization failed: ${event.error}`)
  }
})

Admob.addEventListener('consent_complete', event => {
  if (!event.success) {
    Ti.API.warn(`UMP completed with an error: ${event.error}`)
  }

  if (event.canRequestAds) {
    initializeAdsOnce()
  }
})

Admob.requestConsent({
  tagForUnderAgeOfConsent: false
})
```

App Tracking Transparency is optional and is **not** part of this flow. It does not replace UMP and is not an additional ad-request gate; the app still uses only `canRequestAds()`. An application with a real tracking case resolves ATT before initializing — see [Getting started](documentation/getting-started.md#optional-if-the-application-requests-att). The same call site works on both platforms: iOS resolves ATT and Android completes immediately with `applicable: false`.

For the publisher-rendered privacy entry point, check `isPrivacyOptionsRequired()` and call `presentPrivacyOptions({})`. `canShowAds()` remains a deprecated alias of `canRequestAds()`.

Read [Privacy and initialization](documentation/privacy.md) for production, debug-geography, privacy-options, error, and event-payload guidance.

For development diagnostics, `openAdInspector()` presents Google's native Ad Inspector on a registered test device and emits `ad_inspector_closed`. Invoke it only from visible development UI after SDK initialization.

## Adaptive banner

The module reports the real adaptive height after load. Reserve that space in your layout; do not hardcode `50`, `90`, `123`, or any device-specific value.

```js
const banner = Admob.createAdaptiveBanner({
  adUnitId: Admob.TEST_ADAPTIVE_BANNER,
  adaptiveType: Admob.ADAPTIVE_ANCHORED,
  width: Ti.UI.FILL
})

banner.addEventListener(Admob.AD_LOADED, event => {
  Ti.API.info(`Adaptive banner height: ${event.height}${event.heightUnit}`)
})

banner.addEventListener(Admob.AD_FAILED_TO_LOAD, event => {
  Ti.API.warn(`Banner failed: ${event.error} (${event.code})`)
})

bannerHost.add(banner)
banner.load()
```

## Standard banner

A fixed AdMob size. The widths are set by Google's spec, so `BANNER` is 320×50 regardless of the device; use `customAdSize` when you need to fill the width.

```js
const banner = Admob.createBanner({
  adUnitId: Admob.TEST_BANNER,
  adSize: Admob.BANNER
})

banner.addEventListener(Admob.AD_LOADED, () => Ti.API.info('Banner loaded'))

bannerHost.add(banner)
banner.load()
```

Standard and adaptive banners expose the same methods:

- `load()`
- `pause()`
- `resume()`
- `isLoaded()`
- `destroy()`
- `destroyAdViewAndCancelRequest()`
- `destoyAdViewAndCancelRequest()` (deprecated misspelling)

Both types emit `loaded`, `failed_to_load`, `clicked`, `impression`, `opened`, `closed`, and `destroyed`. Destruction is terminal and safe to repeat.

`pause()` and `resume()` preserve the same proxy, creative, visual state and layout slot. The module owns host background/foreground; the app uses those calls only when its own tab or same-activity navigation stops showing the placement.

On Android, a configuration change such as light/dark appearance recreates the hosting activity. The module preserves the JavaScript proxy across that recreation and requests a replacement native banner after Titanium rebuilds its view; `destroyed` remains reserved for a real terminal cleanup.

The public factories are `createBanner()`, `createAdaptiveBanner()`, `createInterstitial()`, `createRewarded()`, and `createAppOpen()`.

See [Banner ads](documentation/banners.md) for layout patterns, payloads, lifecycle cleanup, adaptive sizing, and platform-specific options.

## Fullscreen ads

Interstitial, rewarded, and app open proxies expose the same API on iOS and Android:

- `load()` serializes requests and ignores duplicate calls while loading, loaded, or showing.
- `show()` presents the unused native ad or emits `failed_to_show`.
- `isLoaded()` reports whether an unused ad is ready.
- `destroy()` is terminal, idempotent, and emits `destroyed` once.

```js
const interstitial = Admob.createInterstitial({
  adUnitId: Admob.TEST_INTERSTITIAL,
  autoReload: true
})

interstitial.addEventListener(Admob.AD_LOADED, () => interstitial.show())
interstitial.load()
```

Rewarded ads add one event, and it is the only place a reward may be granted:

```js
const rewarded = Admob.createRewarded({
  adUnitId: Admob.TEST_REWARDED,
  autoReload: true
})

rewarded.addEventListener(Admob.AD_REWARDED, event => {
  grantReward(event.rewardType, event.rewardAmount)
})

rewarded.addEventListener(Admob.AD_LOADED, () => rewarded.show())
rewarded.load()
```

App open ads are shown when the user returns to a running app, never on a cold start behind your own splash:

```js
const appOpen = Admob.createAppOpen({
  adUnitId: Admob.TEST_APP_OPEN,
  autoReload: true
})

appOpen.load()

Ti.App.addEventListener('resumed', () => {
  if (appOpen.isLoaded()) {
    appOpen.show()
  }
})
```

App open ads expire four hours after the request, as Google documents. Past that point `isLoaded()` reports `false` and `show()` emits `failed_to_show`.

Every fullscreen event includes `adUnitId` and `adType`. Failures consistently add `error`, `message`, and `code`. Both platforms emit `opened` and `showed_fullscreen_content`; rewarded ads additionally emit `rewarded` with `rewardType` and `rewardAmount`.

Native fullscreen ads are single-use. Grant value only from `rewarded`, never from `closed`, and remove named JavaScript listeners before destroying the proxy. Request `extras` are forwarded through Google's ad-network extras on both platforms.

See [Fullscreen ads](documentation/fullscreen.md) for examples, cleanup, and the complete event table.

## Documentation

- [Documentation index](documentation/index.md)
- [Getting started](documentation/getting-started.md)
- [Integrating the module](documentation/integration.md)
- [Privacy and initialization](documentation/privacy.md)
- [AdMob mediation](documentation/mediation.md)
- [Mediation parity across platforms](MEDIATION_COMPARISON.md)
- [Third-party SDK notices](documentation/third-party-notices.md)
- [Banner ads](documentation/banners.md)
- [Fullscreen ads](documentation/fullscreen.md)
- [Complete API reference](documentation/api-reference.md)
- [Migrating to ti.admob.unified](documentation/migration.md)
- [Dependencies and checksums](DEPENDENCIES.md)
- [Changelog](CHANGELOG.md)
- [Roadmap](ROADMAP.md)
- [Contributing](CONTRIBUTING.md)

## Development safety

Use the exported `TEST_*` constants while developing. Their values are platform-specific official Google demo ad unit IDs.

```js
const bannerId = Admob.TEST_ADAPTIVE_BANNER
const interstitialId = Admob.TEST_INTERSTITIAL
const rewardedId = Admob.TEST_REWARDED
```

Never click production ads during development. Do not derive ad eligibility from `canShowPersonalizedAds()`, `isGDPR()`, TCF storage, or local cached consent. `canRequestAds()` is the authoritative gate.

## Verification

```sh
npm test
./scripts/verify-artifacts.sh
./scripts/verify-artifacts.sh mediation
ti build -p ios --build-only --project-dir ios --no-prompt
ti build -p android --build-only --project-dir android --no-prompt
ti build -p ios --build-only --project-dir mediation/ios --no-prompt
ti build -p android --build-only --project-dir mediation/android --no-prompt
```

Physical-device validation and Ad Inspector checks are still required before a consumer app enables production ad unit IDs.

## License

MIT. See [LICENSE](LICENSE).
