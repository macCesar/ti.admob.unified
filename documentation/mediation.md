# AdMob mediation

Mediation ships as a separate module, `ti.admob.unified.mediation`. It carries the same six AdMob mediation networks on iOS and Android — Meta Audience Network, InMobi, Unity Ads, AppLovin, Liftoff Monetize (Vungle), and ironSource — and nothing else: it has no JavaScript API, and no application ever calls it.

Install it only if the application actually mediates. Since `2.0.0` the core module carries Google Mobile Ads and UMP alone, so an application that serves AdMob demand only installs 14 MB on iOS instead of 89 MB and inherits no network SDK in its Android build.

## Installing the pack

Install both ZIPs for every platform you build and declare both modules:

```xml
<modules>
  <module version="2.0.0">ti.admob.unified</module>
  <module version="2.0.0">ti.admob.unified.mediation</module>
</modules>
```

The two artifacts ship at the same version and are released together. Do not mix versions: the adapters are built against the Google Mobile Ads version the core module vendors.

Nothing else changes. Mediation does not change the JavaScript ad API — create banners, interstitials, rewarded ads, and app open ads with the normal `ti.admob.unified` factories. Google Mobile Ads discovers the adapters and selects an eligible source from the mediation configuration in AdMob.

To stop mediating, remove the second `<module>` line and rebuild. `getMediationStatus()` then reports every network as `false`, and every ad call keeps working.

## Installing an adapter is not the same as enabling a network

This is the part that is easy to get backwards, so it is worth stating plainly: **bundling an adapter does not raise fill by itself, and it does not make the network participate in a single request.** A network participates only when all of this is true:

1. Its publisher account exists and is approved.
2. It is added as an ad source to the AdMob mediation group serving that ad unit.
3. Its provider credentials are entered in AdMob and the provider placement is mapped to the AdMob ad unit.
4. Its privacy and store-disclosure requirements are complete.

Until then the adapter is inert weight — and it is not free weight. On iOS it is roughly 75 MB of vendored frameworks. On Android it pulls six third-party SDKs into the application. On both it adds six Data Safety and App Privacy declarations the application has to answer for, six adapter/SDK pairs to review on every Google Mobile Ads major upgrade, and six adapters that `initialize()` waits on before the first ad.

That is why the pack is opt-in. An application without a configured mediation group gains nothing from installing it.

## Publisher setup

For each network that an application will use:

1. Create or connect the publisher account for that network.
2. Add the network as an ad source in the AdMob mediation group.
3. Enter the provider credentials and map the provider placement to the AdMob ad unit.
4. Complete the provider's privacy and store-disclosure requirements.
5. Validate the integration with test ads and Ad Inspector before enabling production traffic.

Google Mobile Ads can still inspect or initialize every installed adapter during SDK startup. In development, incomplete or conflicting server mappings can produce provider warnings even when Google serves the requested test banner. Examples include a missing AppLovin SDK key and multiple Liftoff Monetize app IDs. The module does not add provider credentials to either native manifest; AdMob supplies those server parameters from the mediation mapping.

Do not silence these messages with placeholder credentials. Complete the provider mapping, use that provider's test mode, and verify it through single-source testing in Ad Inspector. If the application does not intend to use a network, leave it out of the AdMob mediation group.

Google maintains the current setup instructions and format caveats in its [Android mediation network guide](https://developers.google.com/admob/android/choose-networks) and [iOS mediation network guide](https://developers.google.com/admob/ios/choose-networks). For example, Meta does not currently support anchored or inline adaptive banners through AdMob mediation; use the formats supported by the selected network.

## Portable diagnostics

`getMediationStatus()` lives in `ti.admob.unified` and reports whether each adapter is visible to the native runtime. It answers on both platforms whether or not the pack is installed:

```js
const Admob = require('ti.admob.unified')

Ti.API.info(JSON.stringify(Admob.getMediationStatus()))
```

The result has the same keys on both platforms. With the pack installed:

```js
{
  appLovin: true,
  meta: true,
  inMobi: true,
  unity: true,
  liftoffMonetize: true,
  ironSource: true
}
```

Without it, the same six keys report `false`. That is the check to run before publishing an application that is supposed to mediate: six `false` values mean the pack is missing from the build, not that a network failed to fill.

Detection is by native class lookup, so nothing throws and no ad call changes behaviour when the pack is absent. The per-network `isAppLovinAvailable()`, `isMetaAvailable()`, `isInMobiAvailable()`, `isVungleAvailable()`, `isUnityAvailable()`, and `isIronSourceAvailable()` methods answer the same question one network at a time.

This is an installation diagnostic, not evidence that a network filled a request. Use Ad Inspector and the ad response information for request-level diagnostics.

The module exposes the native inspector on both platforms:

```js
Admob.addEventListener('ad_inspector_closed', event => {
  Ti.API.info(JSON.stringify(event))
})
Admob.openAdInspector()
```

Use it only in development UI, after initialization, on a registered Google Mobile Ads test device.

The legacy `enableOptionalMediationNetworks(config)` method remains callable for existing applications, but it does not enable or initialize a network. Adapters are auto-discovered. It now logs the same availability information.

## Applications that install the pack but sometimes skip it

Auto-discovery has a cost: `initialize()` starts every installed adapter and does not report back until all of them answer or time out. An adapter with no credentials configured can consume its entire timeout, which delays the first ad.

An application that installs the pack for one build flavour and not another, or that wants to skip adapter startup in a given session, passes `disableMediation: true` to `initialize()`. The adapters stay installed; the SDK simply does not start them in that session. See [`initialize(config)`](api-reference.md#initializeconfig).

An application that never mediates does not need that flag. It just leaves the pack out.

## Privacy and store declarations

UMP determines when the application may request ads; continue using `canRequestAds()` as the only request gate. UMP does not replace the publisher's responsibility to configure every selected provider correctly or to keep App Store and Play Data safety declarations accurate.

The vendored iOS frameworks include their distributed privacy manifests and resource bundles. The consuming application must still provide:

- an accurate `NSUserTrackingUsageDescription` if it requests ATT;
- the current `SKAdNetworkItems` required by Google and the enabled networks;
- App Store privacy answers that reflect the application's actual mediation configuration;
- a public privacy policy identifying the advertising providers in use.

On Android, the pack's Maven adapter coordinates bring their matching network SDKs into the application through the module POM. Review the merged manifest and Play Data safety form for the exact providers enabled in AdMob. An application that does not install the pack inherits none of them, and its declarations shrink accordingly.

Never initialize a provider manually unless its current Google mediation guide explicitly requires it. Duplicate initialization can interfere with adapter lifecycle and consent propagation.

## Release validation

Before release, verify both platforms with official test ads, inspect adapter versions and initialization status in Ad Inspector, and confirm that only the intended networks are active in the AdMob mediation group. Confirm `getMediationStatus()` reports what the build is supposed to contain. A development build must not use or click production ads.
