# ti.admob.unified.mediation

The optional AdMob mediation adapter pack for [`ti.admob.unified`](../README.md). It carries the adapters and network SDKs for Meta Audience Network, InMobi, Unity Ads, AppLovin, Liftoff Monetize (Vungle), and ironSource: fourteen XCFrameworks on iOS, six Maven coordinates on Android.

## What it is

A carrier module. It exposes no JavaScript API and nothing in an application ever calls it. Declaring it in `tiapp.xml` puts the adapters inside the build; Google Mobile Ads discovers them at runtime, and `ti.admob.unified` reports them through `getMediationStatus()`.

```xml
<modules>
  <module version="2.0.0">ti.admob.unified</module>
  <module version="2.0.0">ti.admob.unified.mediation</module>
</modules>
```

Both artifacts ship at the same version and are released together. Install the pack only if the application actually mediates.

## What it is not

**Installing it does not raise fill by itself.** A network participates in a request only when its publisher account is approved, it is added as an ad source to an AdMob mediation group, and its credentials are mapped to the ad unit. Without that configuration the adapter is inert weight — and it is not free weight: it adds roughly 75 MB to the iOS module and brings six third-party SDKs into the Android build, each with its own Data Safety and App Privacy disclosures and its own initialization cost at startup.

That is the reason the adapters no longer ship inside the core module. An application that serves AdMob demand only installs `ti.admob.unified` alone, ~14 MB on iOS, and inherits nothing on Android.

## Documentation

[AdMob mediation](../documentation/mediation.md) covers installation, publisher setup, the `getMediationStatus()` diagnostic, and release validation.
