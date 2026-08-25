# Mediation parity

Version `2.0.0` distributes six AdMob mediation networks on both platforms through the optional `ti.admob.unified.mediation` module, which lives in `mediation/` in this repository:

| Ad source                 | iOS      | Android  | Shared JavaScript API |
| ------------------------- | -------- | -------- | --------------------- |
| Meta Audience Network     | Included | Included | Yes                   |
| InMobi                    | Included | Included | Yes                   |
| Unity Ads                 | Included | Included | Yes                   |
| AppLovin                  | Included | Included | Yes                   |
| Liftoff Monetize (Vungle) | Included | Included | Yes                   |
| ironSource                | Included | Included | Yes                   |

Applications use the normal `createBanner()`, `createAdaptiveBanner()`, `createInterstitial()`, `createRewarded()`, and `createAppOpen()` factories from `ti.admob.unified`. AdMob discovers the native adapters; no iOS/Android condition is needed to select a mediated network, and nothing in an application ever calls the pack.

`getMediationStatus()` stays in `ti.admob.unified` and provides the same six diagnostic keys on both platforms whether or not the pack is installed — `true` for each network with it, `false` for each without. It verifies installation only. Fill behavior still depends on the publisher's AdMob mediation groups, provider accounts, placement mappings, format support, geography, consent, and inventory.

The module does not promise a revenue uplift or fill rate. Those results are application- and market-specific, and installing an adapter for a network that is not configured as an ad source changes nothing except the size of the build. See [AdMob mediation](documentation/mediation.md) for setup and validation.
