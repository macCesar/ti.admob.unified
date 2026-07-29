# ti.admob.unified roadmap

## Current baseline

Version 1.2.0 stabilizes the Google-only core:

- Titanium `13.4.0.GA`
- iOS 15+
- GMA iOS `13.7.0` and UMP iOS `3.1.0`
- GMA Android `25.4.0` and UMP Android `4.0.0`
- no required third-party mediation
- idempotent initialization and consent
- terminal `consent_complete` events
- no manual TCF personalization inference

Interstitial and rewarded support are preserved, but Cuentas Claras is not
integrated and production ads must remain disabled.

## Phase 2 — Banner parity (complete)

- Standard and adaptive banners expose `load()`, `pause()`, `resume()`,
  `destroy()`, `isLoaded()`, and both destruction aliases on both platforms.
- Event names and common payload keys are aligned.
- `destroy()` is terminal, repeatable, and emits `destroyed` once.
- iOS delegates, root controllers, paid-event handlers, views, and references
  are released.
- Android calls native `pause()`, `resume()`, and `destroy()`, clears ad
  listeners, and unregisters activity lifecycle listeners.
- Each proxy accepts at most one active native load and at most one deferred
  load while paused.
- Shared source-contract tests and clean iOS/Android module builds verify the
  lifecycle contract. Device lifecycle scenarios remain in phase 4.

## Phase 3 — Cuentas Claras integration

- Install both 1.2.0 artifacts with module ID `ti.admob.unified`.
- Replace the two existing module declarations.
- Adapt `app/lib/services/ads.js` once.
- Preserve UMP → ATT → GMA orchestration.
- Keep `productionEnabled: false`.
- Run app unit, lint, Alloy/PurgeTSS, and platform builds.

## Phase 4 — Native validation and release

- Test iPhone and iPad layouts.
- Test minimum and current Android versions.
- Validate first consent, relaunch, privacy changes, ATT, background/foreground,
  rapid navigation, and repeated window lifecycle.
- Use official test ad units and Ad Inspector.
- Confirm no production requests occur in development.

## Deferred

- Optional mediation distributions
- App Open ads
- Native ads
- Rewarded interstitial
- Android Next-Gen SDK migration
- Firebase Analytics

These are separate product decisions and are not requirements for the banner
stabilization path.
