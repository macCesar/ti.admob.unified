# Integrating the module

This page is about the code between the module and the application: the small layer every consuming app ends up writing, why it exists, and how much of it is the same everywhere.

The module owns the native SDKs, the privacy plumbing, and one portable proxy contract. It deliberately stops there.

## What the module does not do for you

Four responsibilities stay with the application, because none of them can be decided from inside a module that does not know your screens:

| Responsibility | Why the module cannot own it |
|---|---|
| **Sequence the start-up** | Consent, the `canRequestAds()` gate, `initialize()`, and ad creation must happen in that order, once per session. The module exposes each step and enforces none of the ordering. |
| **Turn events into promises** | `requestConsent()` and `initialize()` answer through module-level events, not callbacks. Awaiting them is the difference between a readable start-up and a pile of nested listeners. |
| **Reserve layout space** | Only the application knows which view the banner sits in and what it must not cover. |
| **Rebuild when the world changes** | A banner cannot be resized and cannot change its ad unit. A rotation, a split-view resize, or a consent change means destroying the proxy and creating a new one. |

Everything below is one way to discharge those four, extracted from a shipping application. Copy it and change the parts the next section marks as yours.

## A starter integration

```js
/**
 * ads.js — the generic half of an AdMob integration.
 */

const Admob = require('ti.admob.unified')

const placements = new Set()

let startup = null
let gateResolved = false
let canRequest = false
let sdkReady = false

// 1. Events as promises.

function waitForEvent(name, invoke) {
  return new Promise(resolve => {
    let settled = false

    function finish(event) {
      if (settled) {
        return
      }

      settled = true
      Admob.removeEventListener(name, finish)
      resolve(event || {})
    }

    try {
      Admob.addEventListener(name, finish)
      invoke()
    } catch (error) {
      finish({ success: false, error: error.message || String(error) })
    }
  })
}

// 2. One start-up sequence, run at most once per session.

function start() {
  if (startup) {
    return startup
  }

  startup = (async () => {
    const consent = await waitForEvent('consent_complete', () => {
      Admob.requestConsent({ tagForUnderAgeOfConsent: false })
    })

    if (consent.success === false) {
      Ti.API.warn(`[ads] UMP failed: ${consent.error}`)
    }

    canRequest = Admob.canRequestAds()

    if (canRequest) {
      const initialized = await waitForEvent('module_initialized', () => {
        Admob.initialize({ disableMediation: true }) // yours to decide
      })

      sdkReady = initialized.success !== false
    }

    gateResolved = true
    placements.forEach(placement => placement.sync())
    return canRequest && sdkReady
  })()

  return startup
}

// 3. A placement that owns its own slot.

function createPlacement(options) {
  const host = options.host
  const content = options.content
  const reservedHeight = options.height
  let banner = null
  let destroyed = false
  let paused = false

  function reserve(value) {
    const dimension = `${Math.max(0, value)}dp`

    if (banner) {
      banner.height = dimension
    }

    host.height = dimension

    if (content) {
      content.bottom = dimension
    }
  }

  function onLoaded(event) {
    // Corrects a slot that already exists; it never creates one.
    reserve(Number(event.height) > 0 ? Number(event.height) : reservedHeight)
  }

  function onFailed(event) {
    Ti.API.warn(`[ads] Banner failed: ${event.error} (${event.code})`)
    detach(true)
    reserve(0)
  }

  function onDestroyedNatively() {
    detach(false)
    reserve(0)
  }

  function detach(destroyNative) {
    if (!banner) {
      return
    }

    const target = banner
    banner = null

    target.removeEventListener(Admob.AD_LOADED, onLoaded)
    target.removeEventListener(Admob.AD_FAILED_TO_LOAD, onFailed)
    target.removeEventListener(Admob.AD_DESTROYED, onDestroyedNatively)

    if (destroyNative) {
      target.destroy()
    }

    try {
      host.remove(target)
    } catch (error) {
      Ti.API.debug(`[ads] Banner was already detached: ${error.message}`)
    }
  }

  const placement = {
    sync() {
      if (destroyed || paused || banner) {
        return
      }

      if (!canRequest || !sdkReady) {
        // Only collapse once the gate has answered. Collapsing while the SDK
        // is still starting leaves the slot at zero, and the ad arriving later
        // gives the layout the exact shove the reservation was meant to avoid.
        if (gateResolved) {
          reserve(0)
        }

        return
      }

      banner = Admob.createBanner({
        adUnitId: options.adUnitId,
        adSize: options.adSize, // yours to decide
        height: reservedHeight,
        width: Ti.UI.FILL
      })

      banner.addEventListener(Admob.AD_LOADED, onLoaded)
      banner.addEventListener(Admob.AD_FAILED_TO_LOAD, onFailed)
      banner.addEventListener(Admob.AD_DESTROYED, onDestroyedNatively)

      host.add(banner)
      banner.load()
    },

    // Neither of these touches the reserved height. See "Reserve at creation".
    pause() {
      if (destroyed || paused) {
        return
      }

      paused = true
      banner?.pause()
    },

    resume() {
      if (destroyed || !paused) {
        return
      }

      paused = false
      banner?.resume()
      placement.sync()
    },

    // Call after a width change or a consent change: a banner cannot be
    // resized, and a new consent state needs a fresh request.
    rebuild() {
      if (destroyed) {
        return
      }

      detach(true)
      placement.sync()
    },

    destroy() {
      if (destroyed) {
        return
      }

      destroyed = true
      placements.delete(placement)
      detach(true)
      reserve(0)
    }
  }

  placements.add(placement)
  reserve(reservedHeight)
  placement.sync()
  return placement
}

// 4. Reopening the privacy form re-runs the gate.

async function showPrivacyOptions() {
  const event = await waitForEvent('privacy_options_dismissed', () => {
    Admob.presentPrivacyOptions({})
  })

  canRequest = Admob.canRequestAds()
  placements.forEach(placement => placement.rebuild())
  return event.success !== false
}

module.exports = { start, createPlacement, showPrivacyOptions }
```

## Using it

The placement needs a host that is already in the view hierarchy, so the native view can measure a real width, and a content view whose bottom inset moves with the slot:

```js
const Admob = require('ti.admob.unified')
const ads = require('ads')

const win = Ti.UI.createWindow({ layout: 'composite' })
const root = Ti.UI.createView({ layout: 'composite' })
const content = Ti.UI.createView({ top: 0, left: 0, right: 0, bottom: 0 })
const bannerHost = Ti.UI.createView({ left: 0, right: 0, bottom: 0, height: 0 })

root.add(content)
root.add(bannerHost)
win.add(root)
win.open()

ads.start()
ads.createPlacement({
  host: bannerHost,
  content,
  adUnitId: Admob.TEST_BANNER,
  adSize: Admob.BANNER,
  height: 50
})
```

`createPlacement()` returns before any ad exists, and `start()` calls `sync()` on every registered placement when the gate resolves. Order does not matter: placements created before the gate opens wait for it, and placements created after it open immediately.

Call `pause()` when the screen that owns the placement stops being shown, `resume()` when it comes back, and `destroy()` when the window closes. You do **not** have to mirror application background/foreground — the module already tracks that as a separate cause. See [Who pauses a banner](banners.md#who-pauses-a-banner).

## What is generic and what every application decides

| Piece | Generic | Yours |
|---|---|---|
| `waitForEvent()` | Yes | — |
| Consent → gate → `initialize()` order | Yes | — |
| `reserve()` moving host, proxy, and content together | Yes | — |
| Named listeners removed before `destroy()` | Yes | — |
| Ad unit IDs per build type | — | Test IDs while developing, production IDs behind an explicit switch |
| `disableMediation` | — | `true` for AdMob-only demand, `false` when the app really mediates. See [mediation](mediation.md) |
| Banner type and size | — | `createBanner()` with a fixed size, or `createAdaptiveBanner()`. See [banners](banners.md#choose-a-banner-type) |
| When a placement is paused | — | Which of your screens counts as "not shown" |
| Platform quirks | — | Anything only your app's layout runs into |

One concrete example of the right-hand column: a personal-finance app shipping this module reads its ad unit IDs from build configuration and refuses to serve production IDs unless every ID is filled in and an explicit flag is set; picks `FULLBANNER` over `BANNER` when the display is at least `468dp` wide, deciding from the display width rather than from the measured host; and collapses the slot while the Android soft keyboard squeezes the container. None of those belong in a starter — they are that application's answers, and yours will differ.

## Reserve at creation, not at load

Two mistakes cost real correction rounds, and both are about *when* the height moves.

**Reserve the slot when you create the placement, not when the ad loads.** Growing the host from zero on `loaded` shoves everything above it upward a second or two after the screen appears, which reads as a glitch rather than as an ad arriving. A fixed `BANNER` is `50dp` and `FULLBANNER` is `60dp`, so a fixed-size placement can reserve its exact height and never move at all. An adaptive banner only reports its real height after loading, so reserve a sensible minimum up front and let `loaded` correct it — a few dp of correction is not the same glitch as growing from zero.

**Do not move the height in `pause()` / `resume()`.** Collapsing the slot when a tab is hidden moves `content.bottom`, the content re-lays out, and a `ScrollView` loses the position the user had scrolled to — then loses it again on the way back. While the placement exists, the slot stays put; only the ad inside it pauses.

[Banner ads](banners.md#reserve-real-layout-space) covers the layout contract in full: keeping the banner clear of navigation, snackbars, and other bottom-aligned UI, and the vertical-layout trap that pushes a host off-screen.

## Next

- [Banner ads](banners.md) — the complete placement contract.
- [Fullscreen ads](fullscreen.md) — interstitial, rewarded, and app open, which need no layout but do need a decision about when to interrupt.
- [Privacy and initialization](privacy.md) — what the gate in `start()` is actually gating.
