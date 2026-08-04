/**
 * ti.admob.unified 1.2.0 example
 *
 * This app uses only Google's official demo ad unit IDs. It demonstrates:
 * - UMP -> canRequestAds -> ATT (iOS) -> initialization
 * - a real, collapsible adaptive-banner host
 * - explicit listener and proxy cleanup
 * - preserved interstitial and rewarded proxies
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

const win = Ti.UI.createWindow({
  backgroundColor: '#f5f5f5',
  title: 'ti.admob.unified 1.2.0',
  layout: 'composite'
})

const content = Ti.UI.createScrollView({
  top: 0,
  left: 0,
  right: 0,
  bottom: 0,
  layout: 'vertical',
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
  top: 24,
  left: 20,
  right: 20,
  height: Ti.UI.SIZE,
  color: '#222222',
  textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
  text: 'Requesting privacy information…'
})

const detailLabel = Ti.UI.createLabel({
  top: 12,
  left: 20,
  right: 20,
  height: Ti.UI.SIZE,
  color: '#666666',
  textAlign: Ti.UI.TEXT_ALIGNMENT_CENTER,
  text: 'Core Google Mobile Ads + UMP. No mediation adapters are bundled.'
})

function createButton(title, onClick) {
  const button = Ti.UI.createButton({
    title,
    top: 12,
    left: 20,
    right: 20,
    height: 48
  })

  button.addEventListener('click', onClick)
  content.add(button)
  return button
}

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
  setStatus('Google Mobile Ads initialized with official test units')
  loadAdaptiveBanner()
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

function onConsentComplete(event) {
  privacyButton.visible = event.privacyOptionsRequired
  privacyButton.touchEnabled = event.privacyOptionsRequired

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
  privacyButton.visible = event.privacyOptionsRequired
  privacyButton.touchEnabled = event.privacyOptionsRequired

  if (!event.success) {
    setStatus(`Privacy options failed: ${event.error}`)
    return
  }

  setStatus(`Privacy options closed; canRequestAds=${event.canRequestAds}`)
  continueAfterPrivacyGate(event.canRequestAds)
}

function onBannerLoaded(event) {
  setBannerHeight(event.height)
  setStatus(`Adaptive banner loaded at ${event.height}${event.heightUnit}`)
}

function onBannerFailed(event) {
  setBannerHeight(0)
  setStatus(`Banner failed: ${event.error} (${event.code})`)
}

function onBannerDestroyed() {
  setBannerHeight(0)
}

function loadAdaptiveBanner() {
  if (
    banner ||
    !initializationComplete ||
    !Admob.canRequestAds()
  ) {
    return
  }

  banner = Admob.createAdaptiveBanner({
    adUnitId: Admob.TEST_ADAPTIVE_BANNER,
    adaptiveType: Admob.ADAPTIVE_ANCHORED,
    width: Ti.UI.FILL
  })

  banner.addEventListener(Admob.AD_LOADED, onBannerLoaded)
  banner.addEventListener(Admob.AD_FAILED_TO_LOAD, onBannerFailed)
  banner.addEventListener(Admob.AD_DESTROYED, onBannerDestroyed)

  bannerHost.add(banner)
  banner.load()
}

function destroyBanner() {
  if (!banner) {
    setBannerHeight(0)
    return
  }

  banner.removeEventListener(Admob.AD_LOADED, onBannerLoaded)
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

function destroyInterstitial() {
  if (!interstitial) {
    return
  }

  interstitial.removeEventListener(Admob.AD_LOADED, onInterstitialLoaded)
  interstitial.removeEventListener(
    Admob.AD_FAILED_TO_LOAD,
    onInterstitialFailed
  )
  interstitial.removeEventListener(Admob.AD_CLOSED, onInterstitialClosed)
  interstitial.destroy()
  interstitial = null
}

function destroyRewarded() {
  if (!rewarded) {
    return
  }

  rewarded.removeEventListener(Admob.AD_LOADED, onRewardedLoaded)
  rewarded.removeEventListener(Admob.AD_FAILED_TO_LOAD, onRewardedFailed)
  rewarded.removeEventListener(Admob.AD_REWARDED, onRewardEarned)
  rewarded.removeEventListener(Admob.AD_CLOSED, onRewardedClosed)
  rewarded.destroy()
  rewarded = null
}

function onInterstitialLoaded() {
  setStatus('Interstitial loaded; tap Show interstitial')
}

function onInterstitialFailed(event) {
  setStatus(`Interstitial failed: ${event.error} (${event.code})`)
}

function onInterstitialClosed() {
  setStatus('Interstitial closed')
}

function onRewardedLoaded() {
  setStatus('Rewarded ad loaded; tap Show rewarded')
}

function onRewardedFailed(event) {
  setStatus(`Rewarded ad failed: ${event.error} (${event.code})`)
}

function onRewardEarned(event) {
  setStatus(`Reward earned: ${event.rewardAmount} ${event.rewardType}`)
}

function onRewardedClosed() {
  setStatus('Rewarded ad closed')
}

// The module already pauses banners when the host goes away: the Android
// activity, and the iOS application entering the background. These handlers are
// therefore redundant for backgrounding, and are kept only to exercise the
// public methods.
//
// What an application does have to own is its own screens — a tab it stopped
// showing, a window it covered — because the module cannot see that. Those call
// the same pause()/resume(), and the two causes never resume each other.
function onAppPause() {
  if (banner) {
    banner.pause()
  }
}

function onAppResume() {
  if (banner) {
    banner.resume()
  }
}

content.add(statusLabel)
content.add(detailLabel)

const privacyButton = createButton('Advertising privacy options', () => {
  Admob.presentPrivacyOptions({})
})
privacyButton.visible = false
privacyButton.touchEnabled = false

createButton('Load adaptive test banner', () => {
  loadAdaptiveBanner()
})

createButton('Destroy banner', () => {
  destroyBanner()
  setStatus('Banner destroyed and host collapsed')
})

createButton('Load interstitial test ad', () => {
  if (!initializationComplete || !Admob.canRequestAds()) {
    setStatus('Interstitial blocked until privacy and initialization complete')
    return
  }

  destroyInterstitial()
  interstitial = Admob.createInterstitial({
    adUnitId: Admob.TEST_INTERSTITIAL,
    autoReload: false
  })

  interstitial.addEventListener(Admob.AD_LOADED, onInterstitialLoaded)
  interstitial.addEventListener(
    Admob.AD_FAILED_TO_LOAD,
    onInterstitialFailed
  )
  interstitial.addEventListener(Admob.AD_CLOSED, onInterstitialClosed)
  interstitial.load()
})

createButton('Show interstitial', () => {
  if (interstitial && interstitial.isLoaded()) {
    interstitial.show()
  } else {
    setStatus('Interstitial is not loaded')
  }
})

createButton('Load rewarded test ad', () => {
  if (!initializationComplete || !Admob.canRequestAds()) {
    setStatus('Rewarded ad blocked until privacy and initialization complete')
    return
  }

  destroyRewarded()
  rewarded = Admob.createRewarded({
    adUnitId: Admob.TEST_REWARDED,
    autoReload: false
  })

  rewarded.addEventListener(Admob.AD_LOADED, onRewardedLoaded)
  rewarded.addEventListener(Admob.AD_FAILED_TO_LOAD, onRewardedFailed)
  rewarded.addEventListener(Admob.AD_REWARDED, onRewardEarned)
  rewarded.addEventListener(Admob.AD_CLOSED, onRewardedClosed)
  rewarded.load()
})

createButton('Show rewarded', () => {
  if (rewarded && rewarded.isLoaded()) {
    rewarded.show()
  } else {
    setStatus('Rewarded ad is not loaded')
  }
})

Admob.addEventListener('module_initialized', onModuleInitialized)
Admob.addEventListener('consent_complete', onConsentComplete)
Admob.addEventListener(
  'privacy_options_dismissed',
  onPrivacyOptionsDismissed
)

win.add(content)
win.add(bannerHost)

Ti.App.addEventListener('pause', onAppPause)
Ti.App.addEventListener('resume', onAppResume)

win.addEventListener('close', () => {
  windowClosed = true

  Ti.App.removeEventListener('pause', onAppPause)
  Ti.App.removeEventListener('resume', onAppResume)
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
})

win.open()
Admob.requestConsent({})
