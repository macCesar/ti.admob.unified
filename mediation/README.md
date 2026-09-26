# Optional mediation modules

The first release, `1.0.0`, provides five optional dependency modules with identical identifiers on iOS and Android. Install only the networks the application intends to use. The core `ti.admob.unified` contains Google Mobile Ads and UMP only. Each complement has no JavaScript API and performs no manual provider initialization.

| Network | Module ID | iOS adapter | Android adapter |
| --- | --- | --- | --- |
| AppLovin | `ti.admob.unified.mediation.applovin` | `13.6.4.0` | `13.6.4.2` |
| Meta Audience Network | `ti.admob.unified.mediation.meta` | `6.22.0.0` | `6.22.0.1` |
| InMobi | `ti.admob.unified.mediation.inmobi` | `11.4.1.0` | `11.4.1.2` |
| Unity Ads | `ti.admob.unified.mediation.unity` | `4.20.1.0` | `4.20.1.0` |
| Liftoff Monetize (Vungle) | `ti.admob.unified.mediation.liftoff` | `7.7.7.0` | `7.7.8.1` |

ironSource mediation is deferred: neither its adapter nor its advertising SDK is distributed. Unity includes UnityCoherenceLib. Unity Ads 4.20.1 no longer depends on IronSourceAdQualitySDK, so it is not distributed.

```xml
<modules>
  <module version="1.0.0">ti.admob.unified</module>
  <module version="1.0.0">ti.admob.unified.mediation.applovin</module>
</modules>
```

Each network lives in `mediation/<network>/`, with Android and iOS projects. Add several declarations to combine networks. Applications call only the core. See [setup and diagnostics](../documentation/mediation.md) and [dependency inventory](../DEPENDENCIES.md).

Build from the platform directory or use `./scripts/build-all.sh` at the repository root. `./scripts/prepare-build.sh --all` verifies permissions and checksums for every module. A single module can be prepared with `./scripts/prepare-build.sh mediation/applovin`.

See [Adding a network](../CONTRIBUTING.md#adding-a-network) to create another complement. Build tooling discovers module folders without a provider list.
