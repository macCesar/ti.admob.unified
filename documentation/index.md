# ti.admob.unified documentation

This documentation describes the public JavaScript contract implemented by
`ti.admob.unified` `1.2.1`.

## Start here

1. [Getting started](getting-started.md) — install both platform artifacts,
   configure the AdMob application IDs, and make a first test request.
2. [Integrating the module](integration.md) — the layer between the module and
   the application: start-up sequence, events as promises, layout reservation,
   and what every app decides for itself.
3. [Privacy and initialization](privacy.md) — implement UMP, ATT, the
   `canRequestAds()` gate, and privacy options correctly.
4. [AdMob mediation](mediation.md) — configure and validate the six bundled
   mediation networks without platform-specific JavaScript.
5. [Banner ads](banners.md) — integrate standard or adaptive banners with real
   layout space and deterministic cleanup.
6. [Fullscreen ads](fullscreen.md) — interstitial and rewarded ads on one
   lifecycle, and when it is acceptable to interrupt the user.

## Reference

- [Complete API reference](api-reference.md) — module methods, proxy methods,
  events, payloads, constants, compatibility APIs, and platform notes.
- [Migration to 1.2.0](migration-1.2.0.md) — replace older modules and obsolete
  gates without breaking existing placements.
- [Third-party SDK notices](third-party-notices.md) — licenses and terms for
  the bundled advertising SDKs.

## Project information

- [Dependency inventory](../DEPENDENCIES.md)
- [Changelog](../CHANGELOG.md)
- [Roadmap](../ROADMAP.md)
- [Contributing](../CONTRIBUTING.md)
