# Integrating the module

The native module owns Google Mobile Ads, UMP, portable proxy behavior, and host lifecycle. The consuming application owns navigation and layout because only it knows which screen is actually being shown.

## Recommended path

Copy the maintained [`example/lib/ads.js`](../example/lib/ads.js) into the consuming application's `lib/` directory. It covers every format implemented by version `1.0.0` and prevents each app from rebuilding the same startup, cleanup, and placement machinery.

The complete API and examples are in [Copy-ready JavaScript library](library.md). A compact runnable wiring is in [`example/library-usage.js`](../example/library-usage.js).

## Division of responsibility

| Responsibility | Owner |
| --- | --- |
| UMP, Google Mobile Ads initialization and native callbacks | Module |
| Application/activity background and foreground | Module |
| Automatic banner refresh | Google Mobile Ads SDK, using the ad-unit policy configured in AdMob |
| Consent → `canRequestAds()` → initialization sequence | Copy-ready library, or the application when using the raw API |
| Tab/window coverage | Application |
| Permanent banner host and content inset | Application |
| Production/test ad-unit selection | Application build configuration |
| Frequency and natural presentation points for fullscreen ads | Application |

## Screen lifecycle

Application backgrounding and application navigation are different causes.

The module automatically follows the Android activity and iOS application lifecycle. Do not add duplicate `Ti.App` pause/resume handlers for banners.

An Android secondary window backed by another activity is already covered by the automatic lifecycle handling. The application calls `pause()` only when its own navigation hides a placement while the same host lifecycle remains active, such as a custom same-activity overlay:

```js
banner.pause()

const child = Alloy.createController('child').getView()
child.addEventListener('close', () => banner.resume())
child.open()
```

Pausing does not change `visible`, opacity, height, the host, or the loaded creative. Do not destroy/recreate on tab changes, focus/blur, or light/dark appearance changes. Rebuild only for a real configuration or authorization boundary, or after a recoverable failure.

On Android, the module handles activity recreation caused by a configuration change. It releases the stale native `AdView`, preserves the JavaScript proxy without emitting `destroyed`, and reloads after Titanium creates the replacement view.

## Refresh ownership

Call `load()` once when creating a banner. Do not add `setInterval`, `setTimeout`, or a periodic destroy/create loop. Google Mobile Ads reads the refresh policy configured for that ad unit in AdMob and owns subsequent banner requests.

The application still pauses a placement that is no longer shown. On iOS the module disables native autoload until every pause cause clears. On Android it pauses native ad-view processing; Google's refresh eligibility also requires the banner to be actually visible on screen. The application should therefore call the screen-level pause only when the screen really has been covered or deselected, not while a banner remains visible to the user.

## Banner layout

Reserve the slot when the placement is created, not when the first creative arrives. A late expansion moves content and reads as a rendering bug.

Keep these three values aligned:

```js
bannerHost.height = dimension
content.bottom = dimension
```

Do not collapse either value during `pause()` or restore it during `resume()`. That would reflow lists and scroll views twice even though the same placement still exists.

Adaptive banners report their real `event.height` in dp. Fixed banners should reserve the exact height of the requested size. See [Banner ads](banners.md#reserve-real-layout-space).

## Raw API

Applications that do not want the copy-ready library can use the module directly. [`example/app.js`](../example/app.js) exercises the low-level API, including:

- consent and optional ATT;
- initialization and mediation diagnostics;
- standard and adaptive banners;
- explicit screen-level banner pause/resume;
- interstitial, rewarded and app-open load/show separation;
- privacy options and deterministic cleanup.

When using the raw API, keep named event callbacks so every listener can be removed before `destroy()`.

## Next

- [Copy-ready JavaScript library](library.md)
- [Banner ads](banners.md)
- [Fullscreen ads](fullscreen.md)
- [Privacy and initialization](privacy.md)
