# Mediation parity

Version `1.0.0` distributes six AdMob mediation networks on both platforms:

| Ad source | iOS | Android | Shared JavaScript API |
|---|---|---|---|
| Meta Audience Network | Included | Included | Yes |
| InMobi | Included | Included | Yes |
| Unity Ads | Included | Included | Yes |
| AppLovin | Included | Included | Yes |
| Liftoff Monetize (Vungle) | Included | Included | Yes |
| ironSource | Included | Included | Yes |

Applications use the normal `createBanner()`, `createAdaptiveBanner()`, `createInterstitial()`, `createRewarded()`, and `createAppOpen()` factories. AdMob discovers the native adapters; no iOS/Android condition is needed to select a mediated network.

`getMediationStatus()` provides the same six diagnostic keys on both platforms. It verifies installation only. Fill behavior still depends on the publisher's AdMob mediation groups, provider accounts, placement mappings, format support, geography, consent, and inventory.

The module does not promise a revenue uplift or fill rate. Those results are application- and market-specific. See [AdMob mediation](documentation/mediation.md) for setup and validation.
