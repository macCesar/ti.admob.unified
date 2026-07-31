# AdMob mediation

`ti.admob.unified` bundles the same six AdMob mediation networks on iOS and
Android: Meta Audience Network, InMobi, Unity Ads, AppLovin, Liftoff Monetize
(Vungle), and ironSource.

Mediation does not change the JavaScript ad API. Create banners,
interstitials, and rewarded ads with the normal module factories. Google
Mobile Ads discovers the adapters and selects an eligible source from the
mediation configuration in AdMob.

## Publisher setup

For each network that an application will use:

1. Create or connect the publisher account for that network.
2. Add the network as an ad source in the AdMob mediation group.
3. Enter the provider credentials and map the provider placement to the AdMob
   ad unit.
4. Complete the provider's privacy and store-disclosure requirements.
5. Validate the integration with test ads and Ad Inspector before enabling
   production traffic.

Bundling an adapter does not create an account, placement, mapping, or bidding
relationship. An unconfigured network simply does not participate in the
request.

Google Mobile Ads can still inspect or initialize every bundled adapter during
SDK startup. In development, incomplete or conflicting server mappings can
produce provider warnings even when Google serves the requested test banner.
Examples include a missing AppLovin SDK key and multiple Liftoff Monetize app
IDs. The module does not add provider credentials to either native manifest;
AdMob supplies those server parameters from the mediation mapping.

Do not silence these messages with placeholder credentials. Complete the
provider mapping, use that provider's test mode, and verify it through
single-source testing in Ad Inspector. If the application does not intend to
use a bundled provider, leave it out of the AdMob mediation group.

Google maintains the current setup instructions and format caveats in its
[Android mediation network guide](https://developers.google.com/admob/android/choose-networks)
and [iOS mediation network guide](https://developers.google.com/admob/ios/choose-networks).
For example, Meta does not currently support anchored or inline adaptive
banners through AdMob mediation; use the formats supported by the selected
network.

## Portable diagnostics

`getMediationStatus()` reports whether each bundled adapter is visible to the
native runtime:

```js
const Admob = require('ti.admob.unified')

Ti.API.info(JSON.stringify(Admob.getMediationStatus()))
```

The result has the same keys on both platforms:

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

This is an installation diagnostic, not evidence that a network filled a
request. Use Ad Inspector and the ad response information for request-level
diagnostics.

The module exposes the native inspector on both platforms:

```js
Admob.addEventListener('ad_inspector_closed', event => {
  Ti.API.info(JSON.stringify(event))
})
Admob.openAdInspector()
```

Use it only in development UI, after initialization, on a registered Google
Mobile Ads test device.

The legacy `enableOptionalMediationNetworks(config)` method remains callable
for existing applications, but it does not enable or initialize a network.
Adapters are auto-discovered. It now logs the same availability information.

## Applications that do not use mediation

Auto-discovery has a cost: `initialize()` starts every bundled adapter and does
not report back until all of them answer or time out. An adapter with no
credentials configured can consume its entire timeout, which delays the first
ad of an application that never intended to mediate.

Such an application passes `disableMediation: true` to `initialize()`. The
adapters stay bundled and the six networks remain available to every other
application; the SDK simply does not start them in that session. See
[`initialize(config)`](api-reference.md#initializeconfig).

## Privacy and store declarations

UMP determines when the application may request ads; continue using
`canRequestAds()` as the only request gate. UMP does not replace the
publisher's responsibility to configure every selected provider correctly or
to keep App Store and Play Data safety declarations accurate.

The vendored iOS SDKs include their distributed privacy manifests and resource
bundles. The consuming application must still provide:

- an accurate `NSUserTrackingUsageDescription` if it requests ATT;
- the current `SKAdNetworkItems` required by Google and the enabled networks;
- App Store privacy answers that reflect the application's actual mediation
  configuration;
- a public privacy policy identifying the advertising providers in use.

On Android, the Maven adapter coordinates bring their matching network SDKs
into the application. Review the merged manifest and Play Data safety form for
the exact providers enabled in AdMob.

Never initialize a provider manually unless its current Google mediation guide
explicitly requires it. Duplicate initialization can interfere with adapter
lifecycle and consent propagation.

## Release validation

Before release, verify both platforms with official test ads, inspect adapter
versions and initialization status in Ad Inspector, and confirm that only the
intended networks are active in the AdMob mediation group. A development build
must not use or click production ads.
