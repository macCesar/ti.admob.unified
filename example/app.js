/**
 * ti.admob.unified 1.0.0 example
 *
 * This app uses only Google's official demo ad unit IDs. It demonstrates:
 * - UMP -> canRequestAds -> ATT (iOS) -> initialization
 * - every ad format the module exposes, one button each
 * - a banner host that reserves its own space
 * - explicit listener and proxy cleanup
 *
 * One button per format, and the button's title is its state:
 *
 *     Interstitial  ->  Interstitial · creating…  ->  Interstitial · tap to show
 *
 * and back to `Interstitial` once the ad closes. A single control, but still
 * two decisions: loading is a network request, showing is an interruption you
 * choose. That separation is the contract in documentation/fullscreen.md, and
 * it survives here — the button simply carries both steps instead of splitting
 * them across two controls that read as unrelated.
 *
 * It intentionally contains no production ad unit IDs, mediation, or manual
 * banner refresh timers.
 */

const Admob = require('ti.admob.unified')

let initializationStarted = false
let initializationComplete = false
let trackingRequestStarted = false
let windowClosed = false
let banner = null
let interstitial = null
let rewarded = null
let appOpen = null

const win = Ti.UI.createWindow({
  backgroundColor: '#f2f2f7',
  title: 'ti.admob.unified 1.0.0',
  layout: 'composite',
  // Keep content clear of the Dynamic Island, the notch and the home
  // indicator. It matters for ads: a banner anchored to the bottom would sit
  // under the home indicator, where part of it is not reliably tappable.
  extendSafeArea: false
})

const content = Ti.UI.createScrollView({
  top: 0,
  left: 0,
  right: 0,
  bottom: 0,
  layout: 'vertical',
  // Android scrolls in one direction only and warns when it has to guess.
  scrollType: 'vertical',
  showVerticalScrollIndicator: true
})

const bannerHost = Ti.UI.createView({
  left: 0,
  right: 0,
  bottom: 0,
  height: 0,
  backgroundColor: '#ffffff'
})

const statusLabel = Ti.UI.createLabel({
  top: 20,
  left: 20,
  right: 20,
  height: Ti.UI.SIZE,
  color: '#1c1c1e',
  textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
  font: { fontSize: 16, fontWeight: 'semibold' },
  text: 'Requesting privacy information…'
})

const detailLabel = Ti.UI.createLabel({
  top: 6,
  left: 20,
  right: 20,
  bottom: 4,
  height: Ti.UI.SIZE,
  color: '#8e8e93',
  textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
  font: { fontSize: 13 },
  text: 'Core Google Mobile Ads + UMP. No mediation adapters are bundled.'
})

function setStatus(message) {
  statusLabel.text = message
  Ti.API.info(`[ti.admob.unified example] ${message}`)
}

function setBannerHeight(value) {
  const height = Math.max(0, Number(value) || 0)
  const dimension = `${height}dp`

  bannerHost.height = dimension
  content.bottom = dimension
}

function createSection(title) {
  content.add(Ti.UI.createLabel({
    text: title.toUpperCase(),
    top: 22,
    left: 24,
    right: 24,
    height: Ti.UI.SIZE,
    color: '#8e8e93',
    font: { fontSize: 12, fontWeight: 'bold' }
  }))
}

// One button owns one format through its whole cycle, and its title is the
// state: idle -> creating -> ready to show -> back to idle when the ad closes.
//
// Collapsing it into a single control does not collapse the two decisions:
// loading is still a network request and showing is still an interruption you
// choose. The button just refuses to be tapped while the request is in flight,
// then waits for a second tap to present. Formats with no `onShow` — banners —
// simply return to idle once they are on screen.
function createAdButton(title, handlers) {
  const onLoad = handlers.onLoad
  const onShow = handlers.onShow

  const button = Ti.UI.createButton({
    title,
    top: 10,
    left: 24,
    right: 24,
    height: 46,
    color: '#ffffff',
    backgroundColor: '#0a84ff',
    borderRadius: 10,
    font: { fontSize: 16, fontWeight: 'semibold' }
  })

  let state = 'idle'

  button.creating = function () {
    state = 'creating'
    button.applyProperties({
      title: `${title} · creating…`,
      backgroundColor: '#b0b0b5',
      touchEnabled: false
    })
  }

  button.ready = function () {
    state = 'ready'
    button.applyProperties({
      title: `${title} · tap to show`,
      backgroundColor: '#30d158',
      touchEnabled: true
    })
  }

  button.reset = function () {
    state = 'idle'
    button.applyProperties({
      title,
      backgroundColor: '#0a84ff',
      touchEnabled: true
    })
  }

  button.addEventListener('click', () => {
    if (state === 'creating') {
      return
    }

    if (state === 'ready') {
      state = 'showing'
      button.applyProperties({ touchEnabled: false, backgroundColor: '#b0b0b5' })
      onShow(button)
      return
    }

    if (!initializationComplete || !Admob.canRequestAds()) {
      setStatus(`${title} blocked until privacy and initialization complete`)
      return
    }

    button.creating()
    onLoad(button)
  })

  content.add(button)
  return button
}

function initializeAdsOnce() {
  if (
    windowClosed ||
    initializationStarted ||
    !Admob.canRequestAds()
  ) {
    return
  }

  initializationStarted = true
  setStatus('Initializing Google Mobile Ads…')

  Admob.initialize({
    ageRestrictedTreatment: Admob.AGE_RESTRICTED_TREATMENT_UNSPECIFIED,
    maxAdContentRating: Admob.MAX_AD_CONTENT_RATING_GENERAL
  })
}

function onModuleInitialized(event) {
  if (!event.success) {
    setStatus(`Initialization failed: ${event.error}`)
    return
  }

  initializationComplete = true
  Ti.API.info(`Mediation adapters: ${JSON.stringify(Admob.getMediationStatus())}`)
  setStatus('Initialized. Tap any format below.')
}

function onTrackingAuthorizationCompleted(event) {
  trackingRequestStarted = false
  Admob.removeEventListener(
    'tracking_authorization_completed',
    onTrackingAuthorizationCompleted
  )
  Ti.API.info(`ATT status: ${event.status}`)
  initializeAdsOnce()
}

function continueAfterPrivacyGate(canRequestAds) {
  if (!canRequestAds || initializationStarted || windowClosed) {
    return
  }

  if (trackingRequestStarted) {
    return
  }

  trackingRequestStarted = true
  Admob.addEventListener(
    'tracking_authorization_completed',
    onTrackingAuthorizationCompleted
  )
  Admob.requestTrackingAuthorization()
}

// UMP decides whether this user gets a privacy form at all: it is required in
// the EEA and where a message is configured in the AdMob console, and not
// elsewhere. Hiding the button alone would leave the section empty, and a
// hidden view still occupies its slot in a vertical layout, so the space is
// collapsed too and the reason is written where the button would have been.
function setPrivacyOptionsAvailable(available) {
  privacyButton.applyProperties({
    visible: available,
    touchEnabled: available,
    height: available ? 46 : 0,
    top: available ? 10 : 0
  })

  privacyNote.applyProperties({
    visible: !available,
    height: available ? 0 : Ti.UI.SIZE,
    top: available ? 0 : 10
  })
}

function onConsentComplete(event) {
  setPrivacyOptionsAvailable(event.privacyOptionsRequired)

  if (!event.success) {
    Ti.API.warn(`UMP completed with an error: ${event.error} (${event.code})`)
  }

  if (!event.canRequestAds) {
    setStatus('UMP does not currently allow ad requests')
    return
  }

  continueAfterPrivacyGate(event.canRequestAds)
}

function onPrivacyOptionsDismissed(event) {
  setPrivacyOptionsAvailable(event.privacyOptionsRequired)

  if (!event.success) {
    setStatus(`Privacy options failed: ${event.error}`)
    return
  }

  setStatus(`Privacy options closed; canRequestAds=${event.canRequestAds}`)
  continueAfterPrivacyGate(event.canRequestAds)
}

// ---------------------------------------------------------------------------
// Banners: one container, reused. Tapping either button throws away whatever
// is in the host and builds the requested type in its place.
// ---------------------------------------------------------------------------

// platformWidth is in pixels on Android and in points on iOS, and points are
// already the unit customAdSize expects. Dividing on both platforms is the
// mistake that looks right: on a 3x iPhone it asks for a third of the screen.
function screenWidthInDp() {
  const caps = Ti.Platform.displayCaps

  if (Ti.Platform.osname === 'android') {
    return Math.round(caps.platformWidth / caps.logicalDensityFactor)
  }

  return Math.round(caps.platformWidth)
}

function onBannerLoaded(event) {
  setBannerHeight(event.height)
  setStatus(`Adaptive banner loaded at ${event.height}${event.heightUnit}`)
  adaptiveButton.reset()
}

function onFixedBannerLoaded() {
  setStatus(`Fixed banner loaded at ${screenWidthInDp()}x50dp`)
  fixedButton.reset()
}

function onBannerFailed(event) {
  setBannerHeight(0)
  setStatus(`Banner failed: ${event.error} (${event.code})`)
  fixedButton.reset()
  adaptiveButton.reset()
}

function onBannerDestroyed() {
  setBannerHeight(0)
}

function destroyBanner() {
  if (!banner) {
    setBannerHeight(0)
    return
  }

  banner.removeEventListener(Admob.AD_LOADED, onBannerLoaded)
  banner.removeEventListener(Admob.AD_LOADED, onFixedBannerLoaded)
  banner.removeEventListener(Admob.AD_FAILED_TO_LOAD, onBannerFailed)
  banner.removeEventListener(Admob.AD_DESTROYED, onBannerDestroyed)
  banner.destroy()

  try {
    bannerHost.remove(banner)
  } catch (error) {
    Ti.API.debug(`Banner was already detached: ${error.message}`)
  }

  banner = null
  setBannerHeight(0)
}

// A fixed slot as wide as the screen and 50dp tall. Both numbers come from the
// application: the module passes them to AdSize(width, height) on Android and
// GADAdSizeFromCGSize on iOS, and neither platform adjusts them. Because the
// height is known up front, the slot is reserved before the ad arrives and
// nothing on screen moves when it loads.
function loadFixedFullWidthBanner() {
  destroyBanner()

  banner = Admob.createBanner({
    adUnitId: Admob.TEST_BANNER,
    customAdSize: { width: screenWidthInDp(), height: 50 },
    requestAgent: 'ti.admob.unified example',
    width: Ti.UI.FILL
  })

  banner.addEventListener(Admob.AD_LOADED, onFixedBannerLoaded)
  banner.addEventListener(Admob.AD_FAILED_TO_LOAD, onBannerFailed)
  banner.addEventListener(Admob.AD_DESTROYED, onBannerDestroyed)

  bannerHost.add(banner)
  setBannerHeight(50)
  banner.load()
}

// Anchored adaptive: the application gives the width, Google picks the height.
// The host cannot be sized until the `loaded` event reports it.
function loadAdaptiveBanner() {
  destroyBanner()

  banner = Admob.createAdaptiveBanner({
    adUnitId: Admob.TEST_ADAPTIVE_BANNER,
    adaptiveType: Admob.ADAPTIVE_ANCHORED,
    requestAgent: 'ti.admob.unified example',
    width: Ti.UI.FILL
  })

  banner.addEventListener(Admob.AD_LOADED, onBannerLoaded)
  banner.addEventListener(Admob.AD_FAILED_TO_LOAD, onBannerFailed)
  banner.addEventListener(Admob.AD_DESTROYED, onBannerDestroyed)

  bannerHost.add(banner)
  banner.load()
}

// ---------------------------------------------------------------------------
// Fullscreen formats. Loading and presenting stay separate: the first tap
// prepares the ad and the next tap presents it at a moment chosen by the app.
// ---------------------------------------------------------------------------

function destroyInterstitial() {
  if (!interstitial) {
    return
  }

  interstitial.removeEventListener(Admob.AD_LOADED, onInterstitialLoaded)
  interstitial.removeEventListener(Admob.AD_FAILED_TO_LOAD, onInterstitialFailed)
  interstitial.removeEventListener(Admob.AD_FAILED_TO_SHOW, onInterstitialFailed)
  interstitial.removeEventListener(Admob.AD_CLOSED, onInterstitialClosed)
  interstitial.destroy()
  interstitial = null
}

function onInterstitialLoaded() {
  setStatus('Interstitial loaded - tap again to show')
  interstitialButton.ready()
}

function onInterstitialFailed(event) {
  setStatus(`Interstitial failed: ${event.error} (${event.code})`)
  interstitialButton.reset()
}

function onInterstitialClosed() {
  setStatus('Interstitial closed')
  interstitialButton.reset()
}

function destroyRewarded() {
  if (!rewarded) {
    return
  }

  rewarded.removeEventListener(Admob.AD_LOADED, onRewardedLoaded)
  rewarded.removeEventListener(Admob.AD_FAILED_TO_LOAD, onRewardedFailed)
  rewarded.removeEventListener(Admob.AD_FAILED_TO_SHOW, onRewardedFailed)
  rewarded.removeEventListener(Admob.AD_REWARDED, onRewardEarned)
  rewarded.removeEventListener(Admob.AD_CLOSED, onRewardedClosed)
  rewarded.destroy()
  rewarded = null
}

function onRewardedLoaded() {
  setStatus('Rewarded ad loaded - tap again to show')
  rewardedButton.ready()
}

function onRewardedFailed(event) {
  setStatus(`Rewarded ad failed: ${event.error} (${event.code})`)
  rewardedButton.reset()
}

// Closing a rewarded ad is not proof the reward was earned. Only this event is.
function onRewardEarned(event) {
  setStatus(`Reward earned: ${event.rewardAmount} ${event.rewardType}`)
}

function onRewardedClosed() {
  rewardedButton.reset()
}

function destroyAppOpen() {
  if (!appOpen) {
    return
  }

  appOpen.removeEventListener(Admob.AD_LOADED, onAppOpenLoaded)
  appOpen.removeEventListener(Admob.AD_FAILED_TO_LOAD, onAppOpenFailed)
  appOpen.removeEventListener(Admob.AD_FAILED_TO_SHOW, onAppOpenFailedToShow)
  appOpen.removeEventListener(Admob.AD_CLOSED, onAppOpenClosed)
  appOpen.destroy()
  appOpen = null
}

function onAppOpenLoaded() {
  setStatus('App open ad loaded - tap again to show')
  appOpenButton.ready()
}

function onAppOpenFailed(event) {
  setStatus(`App open ad failed: ${event.error} (${event.code})`)
  appOpenButton.reset()
}

// An app open ad expires four hours after the request. Past that point the
// proxy answers show() with this event instead of presenting an ad that would
// no longer earn revenue.
function onAppOpenFailedToShow(event) {
  setStatus(`App open ad could not show: ${event.error} (${event.code})`)
  appOpenButton.reset()
}

function onAppOpenClosed() {
  setStatus('App open ad closed')
  appOpenButton.reset()
}

// The module owns application/activity backgrounding. The app calls these only
// when its own navigation stops showing this placement, such as an inactive tab
// or a child window covering it. Neither call changes visibility or layout.
function pauseBannerForCoveredScreen() {
  if (banner) {
    banner.pause()
  }
}

function resumeBannerForVisibleScreen() {
  if (banner) {
    banner.resume()
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

content.add(statusLabel)
content.add(detailLabel)

createSection('Banners')

const fixedButton = createAdButton('Fixed full-width', {
  onLoad: () => loadFixedFullWidthBanner()
})

const adaptiveButton = createAdButton('Adaptive', {
  onLoad: () => loadAdaptiveBanner()
})

createAdButton('Destroy banner', {
  onLoad: button => {
    destroyBanner()
    setStatus('Banner destroyed and host collapsed')
    button.reset()
  }
})

createAdButton('Pause banner for covered screen', {
  onLoad: button => {
    pauseBannerForCoveredScreen()
    setStatus('Banner paused without hiding or changing its slot')
    button.reset()
  }
})

createAdButton('Resume banner for visible screen', {
  onLoad: button => {
    resumeBannerForVisibleScreen()
    setStatus('The same banner instance resumed')
    button.reset()
  }
})

createSection('Fullscreen')

const interstitialButton = createAdButton('Interstitial', {
  onLoad: () => {
  destroyInterstitial()
  interstitial = Admob.createInterstitial({
    adUnitId: Admob.TEST_INTERSTITIAL,
    requestAgent: 'ti.admob.unified example',
    autoReload: false
  })

  interstitial.addEventListener(Admob.AD_LOADED, onInterstitialLoaded)
  interstitial.addEventListener(Admob.AD_FAILED_TO_LOAD, onInterstitialFailed)
  interstitial.addEventListener(Admob.AD_FAILED_TO_SHOW, onInterstitialFailed)
  interstitial.addEventListener(Admob.AD_CLOSED, onInterstitialClosed)
    interstitial.load()
  },
  onShow: () => interstitial.show()
})

const rewardedButton = createAdButton('Rewarded', {
  onLoad: () => {
  destroyRewarded()
  rewarded = Admob.createRewarded({
    adUnitId: Admob.TEST_REWARDED,
    requestAgent: 'ti.admob.unified example',
    autoReload: false
  })

  rewarded.addEventListener(Admob.AD_LOADED, onRewardedLoaded)
  rewarded.addEventListener(Admob.AD_FAILED_TO_LOAD, onRewardedFailed)
  rewarded.addEventListener(Admob.AD_FAILED_TO_SHOW, onRewardedFailed)
  rewarded.addEventListener(Admob.AD_REWARDED, onRewardEarned)
  rewarded.addEventListener(Admob.AD_CLOSED, onRewardedClosed)
    rewarded.load()
  },
  onShow: () => rewarded.show()
})

const appOpenButton = createAdButton('App open', {
  onLoad: () => {
  destroyAppOpen()
  appOpen = Admob.createAppOpen({
    adUnitId: Admob.TEST_APP_OPEN,
    requestAgent: 'ti.admob.unified example',
    autoReload: false
  })

  appOpen.addEventListener(Admob.AD_LOADED, onAppOpenLoaded)
  appOpen.addEventListener(Admob.AD_FAILED_TO_LOAD, onAppOpenFailed)
  appOpen.addEventListener(Admob.AD_FAILED_TO_SHOW, onAppOpenFailedToShow)
  appOpen.addEventListener(Admob.AD_CLOSED, onAppOpenClosed)
    appOpen.load()
  },
  onShow: () => appOpen.show()
})

createSection('Privacy')

const privacyButton = createAdButton('Advertising privacy options', {
  onLoad: button => {
    Admob.presentPrivacyOptions({})
    button.reset()
  }
})

const privacyNote = Ti.UI.createLabel({
  top: 10,
  left: 24,
  right: 24,
  height: Ti.UI.SIZE,
  color: '#8e8e93',
  font: { fontSize: 13 },
  text: 'UMP reports no privacy form for this session. It appears in the EEA, '
    + 'and wherever a message is configured for the app in AdMob.'
})
content.add(privacyNote)

setPrivacyOptionsAvailable(false)

Admob.addEventListener('module_initialized', onModuleInitialized)
Admob.addEventListener('consent_complete', onConsentComplete)
Admob.addEventListener(
  'privacy_options_dismissed',
  onPrivacyOptionsDismissed
)

win.add(content)
win.add(bannerHost)

win.addEventListener('close', () => {
  windowClosed = true

  Admob.removeEventListener('module_initialized', onModuleInitialized)
  Admob.removeEventListener('consent_complete', onConsentComplete)
  Admob.removeEventListener(
    'privacy_options_dismissed',
    onPrivacyOptionsDismissed
  )
  Admob.removeEventListener(
    'tracking_authorization_completed',
    onTrackingAuthorizationCompleted
  )
  trackingRequestStarted = false

  destroyBanner()
  destroyInterstitial()
  destroyRewarded()
  destroyAppOpen()
})

win.open()
Admob.requestConsent({})
