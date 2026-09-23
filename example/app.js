/**
 * ti.admob.unified example
 *
 * This app uses only Google's official demo ad unit IDs. It demonstrates:
 * - UMP -> canRequestAds -> ATT (iOS) -> initialization
 * - every ad format the module exposes, one button each
 * - a banner host that reserves its own space
 * - explicit listener and proxy cleanup
 *
 * Fullscreen ads preload after privacy and initialization, then reload on close.
 * Showing an ad always requires an explicit tap. The adaptive banner starts automatically.
 * The native layout adapts to the available window width, including split view.
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
let activeBannerButton = null
let interstitial = null
let rewarded = null
let appOpen = null

// A small, shared palette keeps the sample easy to restyle.
const colors = {
  canvas: '#F4F6F5', surface: '#FFFFFF', ink: '#182D2B', muted: '#586D68',
  accent: '#176B58', pressed: '#104F42', tint: '#E5F1EC', line: '#DCE5E0',
  quiet: '#EDF1EF', error: '#A33030'
}
const isAndroid = Ti.Platform.osname === 'android'
const win = Ti.UI.createWindow({
  backgroundColor: colors.canvas,
  title: 'AdMob Playground',
  layout: 'composite',
  extendSafeArea: false
})

const content = Ti.UI.createScrollView({
  top: 0, left: 0, right: 0, bottom: 0,
  layout: 'vertical', contentHeight: Ti.UI.SIZE,
  scrollType: 'vertical', showVerticalScrollIndicator: true
})
const page = Ti.UI.createView({
  width: Ti.UI.FILL, height: Ti.UI.SIZE, layout: 'vertical', bottom: '32dp'
})
content.add(page)

const bannerHost = Ti.UI.createView({
  left: 0, right: 0, bottom: 0, height: 0, backgroundColor: colors.surface
})

const masthead = Ti.UI.createView({
  top: '24dp', left: '24dp', right: '24dp', height: Ti.UI.SIZE, layout: 'vertical'
})
masthead.add(Ti.UI.createLabel({
  text: 'TITANIUM / ADMOB', left: 0, height: Ti.UI.SIZE,
  color: colors.accent, font: { fontSize: '12dp', fontWeight: 'bold' }
}))
masthead.add(Ti.UI.createLabel({
  text: 'Ad playground.', top: '8dp', left: 0, right: 0, height: Ti.UI.SIZE,
  color: colors.ink, font: { fontSize: '36dp', fontWeight: 'bold' }
}))
masthead.add(Ti.UI.createLabel({
  text: 'Explore the formats. See the experience.',
  top: '8dp', left: 0, right: 0, height: Ti.UI.SIZE,
  color: colors.muted, font: { fontSize: '16dp' }
}))
page.add(masthead)

const session = Ti.UI.createView({
  top: '24dp', left: '24dp', right: '24dp', height: Ti.UI.SIZE,
  layout: 'vertical', backgroundColor: colors.tint, borderRadius: '12dp'
})
const sessionLabel = Ti.UI.createLabel({
  text: 'SETUP / PRIVACY', top: '16dp', left: '16dp', right: '16dp',
  height: Ti.UI.SIZE, color: colors.accent,
  font: { fontSize: '12dp', fontWeight: 'bold' }
})
const statusLabel = Ti.UI.createLabel({
  text: 'Requesting privacy information…',
  top: '8dp', left: '16dp', right: '16dp', bottom: '16dp',
  height: Ti.UI.SIZE, color: colors.ink,
  font: { fontSize: '16dp', fontWeight: 'semibold' }
})
session.add(sessionLabel)
session.add(statusLabel)
page.add(session)

const activity = Ti.UI.createLabel({
  text: 'Session events will appear here.', left: '16dp', right: '16dp',
  top: '16dp', bottom: '16dp', height: Ti.UI.SIZE,
  color: colors.muted, font: { fontSize: '12dp', fontFamily: isAndroid ? 'monospace' : 'Menlo' }
})
const events = []
function setStatus(message) {
  statusLabel.text = message
  const now = new Date()
  const time = [now.getHours(), now.getMinutes(), now.getSeconds()]
    .map(value => String(value).padStart(2, '0')).join(':')
  events.unshift(`${time}  ${message}`)
  events.length = Math.min(events.length, 8)
  activity.text = events.join('\n\n')
  Ti.API.info(`[ti.admob.unified example] ${message}`)
}

function setBannerHeight(value) {
  const height = Math.max(0, Number(value) || 0)
  const dimension = `${height}dp`
  bannerHost.height = dimension
  content.bottom = dimension
}

let currentSection
const formatCards = []
function createSection(title, description, grid) {
  page.add(Ti.UI.createLabel({
    text: title, top: '32dp', left: '24dp', right: '24dp', height: Ti.UI.SIZE,
    color: colors.ink, font: { fontSize: '24dp', fontWeight: 'bold' }
  }))
  page.add(Ti.UI.createLabel({
    text: description, top: '6dp', left: '24dp', right: '24dp', height: Ti.UI.SIZE,
    color: colors.muted, font: { fontSize: '14dp' }
  }))
  currentSection = Ti.UI.createView({
    left: '16dp', right: '16dp', height: Ti.UI.SIZE,
    layout: grid ? 'horizontal' : 'vertical', horizontalWrap: true
  })
  page.add(currentSection)
}

// Fullscreen controls only present ready ads; loading starts automatically.
// Banner controls select the placement in the single shared slot.
function createAdButton(title, handlers) {
  const isFormat = Boolean(handlers.description)
  const fullscreen = Boolean(handlers.onShow)
  const idleTitle = fullscreen ? `Show ${title.toLowerCase()}` : isFormat ? `Use ${title.toLowerCase()}` : title
  const card = isFormat ? Ti.UI.createView({
    left: '8dp', right: '8dp', top: '16dp', width: '280dp',
    height: Ti.UI.SIZE, layout: 'vertical', backgroundColor: colors.surface,
    borderRadius: '12dp', borderColor: colors.line, borderWidth: 1
  }) : null
  let stateLabel
  if (card) {
    card.add(Ti.UI.createLabel({
      text: title, top: '20dp', left: '20dp', right: '20dp', height: Ti.UI.SIZE,
      color: colors.ink, font: { fontSize: '20dp', fontWeight: 'bold' }
    }))
    card.add(Ti.UI.createLabel({
      text: handlers.description, top: '8dp', left: '20dp', right: '20dp',
      height: Ti.UI.SIZE, color: colors.muted, font: { fontSize: '14dp' }
    }))
    stateLabel = Ti.UI.createLabel({
      text: fullscreen ? 'Waiting for initialization…' : 'Not selected', top: '20dp', left: '20dp', right: '20dp',
      height: Ti.UI.SIZE, color: colors.muted, font: { fontSize: '12dp', fontWeight: 'semibold' }
    })
    card.add(stateLabel)
    currentSection.add(card)
    formatCards.push(card)
  }
  const button = Ti.UI.createButton({
    title: idleTitle,
    enabled: !fullscreen,
    top: isFormat ? '12dp' : '8dp', left: isFormat ? '20dp' : '8dp',
    right: isFormat ? '20dp' : '8dp', bottom: isFormat ? '20dp' : 0,
    height: '48dp', color: colors.accent, backgroundColor: colors.tint,
    backgroundSelectedColor: colors.line, borderRadius: '8dp',
    font: { fontSize: '14dp', fontWeight: 'semibold' },
    accessibilityHint: handlers.description || ''
  })
  let state = 'idle'
  button.creating = function () {
    state = 'creating'
    if (stateLabel) stateLabel.applyProperties({ text: 'Loading…', color: colors.muted })
    button.applyProperties({ title: 'Loading…', backgroundColor: colors.quiet, color: colors.muted, enabled: false })
  }
  button.ready = function () {
    state = 'ready'
    if (stateLabel) stateLabel.applyProperties({ text: 'Ready to show', color: colors.accent })
    button.applyProperties({
      title: `Show ${title.toLowerCase()}`, backgroundColor: colors.accent,
      backgroundSelectedColor: colors.pressed, color: colors.surface, enabled: true
    })
  }
  button.reset = function () {
    state = 'idle'
    if (stateLabel) stateLabel.applyProperties({ text: fullscreen ? 'Waiting to load…' : 'Not selected', color: colors.muted })
    button.applyProperties({
      title: idleTitle,
      backgroundColor: colors.tint, backgroundSelectedColor: colors.line,
      color: colors.accent, enabled: !fullscreen
    })
  }
  button.failed = function () {
    button.reset()
    state = 'failed'
    button.applyProperties({ title: `Retry ${title.toLowerCase()}`, enabled: true })
    if (stateLabel) stateLabel.applyProperties({ text: 'Could not load or show. Tap to retry.', color: colors.error })
  }
  button.loaded = function (message = 'Loaded in the banner slot') {
    button.reset()
    if (stateLabel) stateLabel.applyProperties({ text: message, color: colors.accent })
  }
  button.load = function () {
    if (windowClosed || state === 'creating' || state === 'showing') return
    if (!handlers.privacy && (!initializationComplete || !Admob.canRequestAds())) {
      setStatus(`${title} blocked until privacy and initialization complete`)
      return
    }
    button.creating()
    handlers.onLoad(button)
  }
  button.addEventListener('click', () => {
    if (state === 'creating' || state === 'showing') return
    if (state === 'ready') {
      if (windowClosed || !Admob.canRequestAds()) {
        setStatus(`${title} blocked by privacy settings`)
        return
      }
      state = 'showing'
      if (stateLabel) stateLabel.text = 'Showing…'
      button.applyProperties({ title: 'Showing…', enabled: false, backgroundColor: colors.quiet, color: colors.muted })
      handlers.onShow(button)
      return
    }
    if (!fullscreen || state === 'failed') button.load()
  })
  const parent = card || currentSection
  parent.add(button)
  return button
}

// Classic Titanium has no TSS breakpoints. Measure the available viewport,
// not the physical display, so rotation and iPad split view use the same layout.
let previousWidth = 0
function layoutPage() {
  const width = Ti.UI.convertUnits(content.size.width, Ti.UI.UNIT_DIP)
  if (!width || width === previousWidth) return
  previousWidth = width
  const pageWidth = Math.min(width, 960)
  page.width = `${pageWidth}dp`
  const columns = pageWidth >= 700 ? 2 : 1
  const cardWidth = Math.floor((pageWidth - 32) / columns) - 16
  formatCards.forEach(card => { card.width = `${cardWidth}dp` })
}
content.addEventListener('postlayout', layoutPage)

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
  if (windowClosed || initializationComplete) return
  if (!event.success) {
    setStatus(`Initialization failed: ${event.error}`)
    return
  }

  initializationComplete = true
  sessionLabel.text = 'TEST ADS / SDK READY'
  Ti.API.info(`Mediation adapters: ${JSON.stringify(Admob.getMediationStatus())}`)
  setStatus('Preparing ads automatically…')
  interstitialButton.load()
  rewardedButton.load()
  appOpenButton.load()
  adaptiveButton.load()
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
  privacyNote.text = 'No privacy form is required for this session.'
  privacyButton.applyProperties({
    visible: available,
    touchEnabled: available,
    height: available ? '48dp' : 0,
    top: available ? '8dp' : 0
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
// Banners: one container, reused. Selecting a banner throws away whatever
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
  let message = 'Loaded in the banner slot'
  if (activeBannerButton === collapsibleButton) {
    message = event.isCollapsible === true
      ? 'Collapsible ad received. Its arrow controls collapse.'
      : event.isCollapsible === false
        ? 'Google returned a standard banner. No collapse arrow.'
        : 'Banner loaded. Collapse capability was not reported.'
  }
  setStatus(`Adaptive banner loaded at ${event.height}${event.heightUnit}; isCollapsible=${event.isCollapsible}`)
  activeBannerButton.loaded(message)
}

function onFixedBannerLoaded() {
  setStatus(`Fixed banner loaded at ${screenWidthInDp()}x50dp`)
  fixedButton.loaded()
}

function onBannerFailed(event) {
  setBannerHeight(0)
  setStatus(`Banner failed: ${event.error} (${event.code})`)
  if (activeBannerButton) activeBannerButton.failed()
}

function onBannerDestroyed() {
  if (activeBannerButton) activeBannerButton.reset()
  setBannerHeight(0)
}

function destroyBanner() {
  fixedButton.reset()
  adaptiveButton.reset()
  collapsibleButton.reset()
  activeBannerButton = null
  if (!banner) {
    setBannerHeight(0)
    return
  }

  banner.removeEventListener('postlayout', onAdaptiveLayout)
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
  activeBannerButton = fixedButton
  fixedButton.creating()

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
// Size the iOS placement using Google before loading, then wait for layout.
// The expanded creative overlays the app; its height is not reserved here.
function onAdaptiveLayout() {
  if (!banner || banner.rect.width <= 0 || banner.rect.height <= 0) return
  banner.removeEventListener('postlayout', onAdaptiveLayout)
  banner.load()
}

function loadAdaptiveBanner(collapsible = false) {
  destroyBanner()
  activeBannerButton = collapsible ? collapsibleButton : adaptiveButton
  activeBannerButton.creating()

  banner = Admob.createAdaptiveBanner({
    adUnitId: Admob.TEST_ADAPTIVE_BANNER,
    adaptiveType: Admob.ADAPTIVE_ANCHORED,
    ...(collapsible ? { collapsible: 'bottom' } : {}),
    ...(!isAndroid ? { height: Ti.UI.FILL } : {}),
    requestAgent: 'ti.admob.unified example',
    width: Ti.UI.FILL
  })

  banner.addEventListener(Admob.AD_LOADED, onBannerLoaded)
  banner.addEventListener(Admob.AD_FAILED_TO_LOAD, onBannerFailed)
  banner.addEventListener(Admob.AD_DESTROYED, onBannerDestroyed)

  if (isAndroid) {
    bannerHost.add(banner)
    banner.load()
  } else {
    setBannerHeight(Admob.getAnchoredAdaptiveBannerSize(bannerHost.rect.width || screenWidthInDp()).height)
    banner.addEventListener('postlayout', onAdaptiveLayout)
    bannerHost.add(banner)
  }
}

// ---------------------------------------------------------------------------
// Fullscreen formats preload automatically. Only presentation needs a tap.
// A consumed ad is replaced after close, without automatically showing it.
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
  setStatus('Interstitial ready to show')
  interstitialButton.ready()
}

function onInterstitialFailed(event) {
  setStatus(`Interstitial failed: ${event.error} (${event.code})`)
  interstitialButton.failed()
}

function onInterstitialClosed() {
  setStatus('Interstitial closed')
  interstitialButton.reset()
  interstitialButton.load()
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
  setStatus('Rewarded ad ready to show')
  rewardedButton.ready()
}

function onRewardedFailed(event) {
  setStatus(`Rewarded ad failed: ${event.error} (${event.code})`)
  rewardedButton.failed()
}

// Closing a rewarded ad is not proof the reward was earned. Only this event is.
function onRewardEarned(event) {
  setStatus(`Reward earned: ${event.rewardAmount} ${event.rewardType}`)
}

function onRewardedClosed() {
  rewardedButton.reset()
  rewardedButton.load()
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
  setStatus('App open ad ready to show')
  appOpenButton.ready()
}

function onAppOpenFailed(event) {
  setStatus(`App open ad failed: ${event.error} (${event.code})`)
  appOpenButton.failed()
}

// An app open ad expires four hours after the request. Past that point the
// proxy answers show() with this event instead of presenting an ad that would
// no longer earn revenue.
function onAppOpenFailedToShow(event) {
  setStatus(`App open ad could not show: ${event.error} (${event.code})`)
  appOpenButton.failed()
}

function onAppOpenClosed() {
  setStatus('App open ad closed')
  appOpenButton.reset()
  appOpenButton.load()
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

createSection('Fullscreen ads', 'Ads load automatically. Tap Show when you’re ready.', true)

const interstitialButton = createAdButton('Interstitial', {
  description: 'A full-screen break between moments in your app.',
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
  description: 'An opt-in experience that earns an in-app reward.',
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
  description: 'A full-screen placement for an app’s opening moment.',
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

createSection('Banner ads', 'Adaptive starts automatically. Choose a format for the banner slot.', true)

const fixedButton = createAdButton('Fixed banner', {
  description: 'A full-width placement with a fixed 50 dp height.',
  onLoad: () => loadFixedFullWidthBanner()
})

const adaptiveButton = createAdButton('Adaptive banner', {
  description: 'Fits the available width. Google selects the height.',
  onLoad: () => loadAdaptiveBanner()
})

const collapsibleButton = createAdButton('Collapsible banner', {
  description: 'Loads a new ad requesting expansion. Google may return a standard banner.',
  onLoad: () => loadAdaptiveBanner(true)
})

createSection('Banner controls', 'Manage the current placement without creating a new ad.', false)

createAdButton('Remove banner', {
  onLoad: button => {
    destroyBanner()
    setStatus('Banner destroyed and host collapsed')
    button.reset()
  }
})

createAdButton('Pause banner', {
  onLoad: button => {
    pauseBannerForCoveredScreen()
    setStatus(banner ? 'Banner paused without hiding or changing its slot' : 'Load a banner first to pause it')
    button.reset()
  }
})

createAdButton('Resume banner', {
  onLoad: button => {
    resumeBannerForVisibleScreen()
    setStatus(banner ? 'The same banner instance resumed' : 'Load a banner first to resume it')
    button.reset()
  }
})

createSection('Privacy & consent', 'Your choices are managed by Google’s consent form.', false)

const privacyButton = createAdButton('Advertising privacy options', {
  privacy: true,
  onLoad: button => {
    Admob.presentPrivacyOptions({})
    button.reset()
  }
})

const privacyNote = Ti.UI.createLabel({
  top: '8dp',
  left: '8dp',
  right: '8dp',
  height: Ti.UI.SIZE,
  color: colors.muted,
  font: { fontSize: 13 },
  text: 'UMP reports no privacy form for this session. It appears in the EEA, '
    + 'and wherever a message is configured for the app in AdMob.'
})
currentSection.add(privacyNote)

setPrivacyOptionsAvailable(false)
privacyNote.text = 'Checking whether privacy options are required…'

createSection('Session activity', 'Latest events first. Only Google demo ad units are used.', false)
const activityPanel = Ti.UI.createView({
  top: '16dp', left: '8dp', right: '8dp', height: Ti.UI.SIZE,
  layout: 'vertical', backgroundColor: colors.surface, borderRadius: '12dp'
})
activityPanel.add(activity)
currentSection.add(activityPanel)
page.add(Ti.UI.createLabel({
  text: 'ti.admob.unified 1.0.0  /  Google Mobile Ads + UMP',
  top: '24dp', left: '24dp', right: '24dp', height: Ti.UI.SIZE,
  color: colors.muted, font: { fontSize: '12dp' }
}))

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
  content.removeEventListener('postlayout', layoutPage)

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
