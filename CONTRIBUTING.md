# Contributing to ti.admob.unified

Contributions are welcome. This module is a cross-platform native bridge, so a
change is complete only when its JavaScript contract, native behavior,
cleanup, tests, and documentation agree.

## Before opening an issue

Include enough information to reproduce the problem:

- Titanium SDK version
- module version
- platform and OS version
- device or simulator/emulator model
- minimal JavaScript example
- expected and actual behavior
- complete module and native ad error payloads
- relevant Xcode or logcat output with secrets removed

For layout issues, include the Titanium proxy, host, and parent dimensions plus
device density/orientation.

## Development baseline

- Titanium SDK `13.4.0.GA`
- iOS `15.0+`
- Android API `23+`
- Node.js with the built-in `node:test` runner

Dependency versions are pinned in [DEPENDENCIES.md](DEPENDENCIES.md).

## Workflow

Create a focused branch and keep unrelated local changes intact. Before
editing a native dependency, establish a recoverable Git baseline and record
the upstream source and checksum.

Run the static checks from the module root:

```sh
npm test
./scripts/verify-artifacts.sh
node --check example/app.js
```

Build both native modules for API or native changes:

```sh
./scripts/prepare-build.sh
ti build -p ios --build-only --project-dir ios --no-prompt
ti build -p android --build-only --project-dir android --no-prompt
```

The `example/app.js` file is the module test-harness entry point. It is not a
standalone Titanium project.

## Public API changes

For a new or changed method, property, event, payload key, or constant:

1. Define the portable JavaScript contract first.
2. Implement it on iOS and Android, or document the platform limitation
   explicitly.
3. Preserve existing supported use cases.
4. Make cleanup and repeated lifecycle calls deterministic.
5. Add contract tests for both native sources.
6. Update the API reference and the relevant task guide.
7. Update `CHANGELOG.md`.

Do not export a format constant as evidence that a format is implemented. A
new ad format needs a working factory and proxy on both platforms before it is
listed as supported.

## Privacy changes

Privacy changes require extra care:

- `canRequestAds()` remains the only ad-request gate.
- Do not parse TCF storage or infer a personalization Boolean.
- Do not replace UMP with ATT; the iOS order is UMP, gate, ATT, initialize.
- Every accepted asynchronous operation must emit one modern terminal event.
- Errors must remain non-blocking to the host application.
- Debug geography and consent reset belong only in controlled testing.

Review [Privacy and initialization](documentation/privacy.md) before changing
this surface.

## Banner changes

Standard and adaptive banners must preserve:

- `load()`, `pause()`, `resume()`, `isLoaded()`, and terminal `destroy()`;
- one active request and at most one deferred request;
- repeatable destruction and one `destroyed` event;
- removal of native delegates, listeners, controllers, views, and activity
  lifecycle registrations;
- common event names and payload keys;
- real adaptive height in density-independent units;
- no hardcoded device height and no `setNativeView(null)`.

Review [Banner ads](documentation/banners.md).

## Testing

Static tests are necessary but not sufficient for native UI and SDK behavior.
For relevant changes, validate physical devices on both platforms:

- consent required/not required, accepted/rejected, and previous-session state;
- ATT authorized, denied, and previously resolved;
- privacy-options reopening;
- load, failure, click, impression, show, close, and reward events;
- background/resume and repeated window lifecycle;
- orientation, density, safe areas, keyboard, lists, navigation, and snackbars;
- absence of duplicate ads and retained listeners;
- official test IDs and Ad Inspector request evidence.

Never click production ads while developing.

## Documentation

Documentation is part of the API. Keep it in English and:

- describe only behavior implemented by the referenced version;
- include argument types, return values, events, and payloads;
- separate portable behavior from platform-specific behavior;
- mark deprecated aliases and non-working reserved APIs;
- use official test constants in executable examples;
- link to primary Google or Apple documentation for upstream requirements.

`tests/documentation.test.js` checks method/constant coverage, internal links,
and unsafe example regressions.

## Pull requests

A pull request should state:

- the problem and intended contract;
- iOS and Android implementation impact;
- compatibility or migration impact;
- tests and builds executed;
- devices and scenarios validated;
- documentation updated.

Do not publish artifacts or create a release tag from a contribution branch.
Release signing, tags, and distribution remain maintainer actions.

Contributions are licensed under the [MIT License](LICENSE).
