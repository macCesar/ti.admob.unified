const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { execFileSync } = require('node:child_process')
const test = require('node:test')

const root = path.resolve(__dirname, '..')

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8')
}

function frameworkVersion(relativePlistPath) {
  return execFileSync(
    '/usr/libexec/PlistBuddy',
    ['-c', 'Print :CFBundleShortVersionString', path.join(root, relativePlistPath)],
    { encoding: 'utf8' }
  ).trim()
}

const iosModule = read('ios/Classes/TiAdmobUnifiedModule.m')
const iosHeader = read('ios/Classes/TiAdmobUnifiedModule.h')
const androidModule = read('android/src/ti/admob/unified/TiAdmobUnifiedModule.java')
const iosBannerHeader = read('ios/Classes/TiAdmobUnifiedBannerAdProxy.h')
const iosBanner = read('ios/Classes/TiAdmobUnifiedBannerAdProxy.m')
const iosAdaptiveBannerHeader = read('ios/Classes/TiAdmobUnifiedAdaptiveBannerAdProxy.h')
const iosAdaptiveBanner = read('ios/Classes/TiAdmobUnifiedAdaptiveBannerAdProxy.m')
const androidBannerProxy = read('android/src/ti/admob/unified/TiAdmobUnifiedBannerAdProxy.java')
const androidBannerView = read('android/src/ti/admob/unified/TiAdmobUnifiedBannerAdView.java')
const androidAdaptiveBannerProxy = read(
  'android/src/ti/admob/unified/TiAdmobUnifiedAdaptiveBannerAdProxy.java'
)
const androidAdaptiveBannerView = read(
  'android/src/ti/admob/unified/TiAdmobUnifiedAdaptiveBannerAdView.java'
)

test('pins the phase 0/1 dependency baseline', () => {
  assert.match(read('ios/manifest'), /version: 1\.2\.0/)
  assert.match(read('android/manifest'), /version: 1\.2\.0/)

  const androidGradle = read('android/build.gradle')
  assert.match(androidGradle, /play-services-ads:25\.4\.0/)
  assert.match(androidGradle, /user-messaging-platform:4\.0\.0/)
  assert.doesNotMatch(androidGradle, /com\.google\.ads\.mediation:/)

  const platformEntries = fs.readdirSync(path.join(root, 'ios/platform'))
    .filter(name => name.endsWith('.xcframework'))
    .sort()
  assert.deepEqual(platformEntries, [
    'GoogleMobileAds.xcframework',
    'UserMessagingPlatform.xcframework'
  ])

  assert.equal(
    frameworkVersion(
      'ios/platform/GoogleMobileAds.xcframework/ios-arm64/GoogleMobileAds.framework/Info.plist'
    ),
    '13.7.0'
  )
  assert.equal(
    frameworkVersion(
      'ios/platform/UserMessagingPlatform.xcframework/ios-arm64/UserMessagingPlatform.framework/Info.plist'
    ),
    '3.1.0'
  )
})

test('aligns Titanium and iOS deployment requirements', () => {
  assert.match(read('ios/manifest'), /minsdk: 13\.4\.0\.GA/)
  assert.match(read('android/manifest'), /minsdk: 13\.4\.0\.GA/)
  assert.match(read('ios/titanium.xcconfig'), /TITANIUM_SDK_VERSION = 13\.4\.0\.GA/)
  assert.match(read('ios/timodule.xml'), /<min-ios-ver>15\.0<\/min-ios-ver>/)

  const xcodeProject = read('ios/ti.admob.unified.xcodeproj/project.pbxproj')
  assert.equal(
    [...xcodeProject.matchAll(/IPHONEOS_DEPLOYMENT_TARGET = 15\.0;/g)].length,
    4
  )
  assert.doesNotMatch(xcodeProject, /IPHONEOS_DEPLOYMENT_TARGET = (12|13)\.0;/)
})

test('uses idempotent native initialization state', () => {
  assert.match(iosModule, /initializationState/)
  assert.match(iosModule, /TiAdmobUnifiedOperationStateInFlight/)
  assert.match(iosModule, /@synchronized\(self\)/)

  assert.match(androidModule, /initializationState/)
  assert.match(androidModule, /OperationState\.IN_FLIGHT/)
  assert.match(androidModule, /synchronized \(initializationLock\)/)
})

test('guarantees the modern consent terminal contract', () => {
  for (const source of [iosModule, androidModule]) {
    assert.match(source, /consent_complete/)
    assert.match(source, /canRequestAds/)
    assert.match(source, /privacyOptionsRequired/)
    assert.match(source, /consent_ready/)
    assert.match(source, /consent_error/)
  }

  assert.match(iosModule, /loadAndPresentIfRequiredFromViewController:nil/)
  assert.match(androidModule, /loadAndShowConsentFormIfRequired/)
  assert.match(iosHeader, /canRequestAds/)
  assert.doesNotMatch(iosModule, /loadConsentForm/)
  assert.doesNotMatch(androidModule, /loadConsentForm/)
})

test('does not infer personalization from TCF storage', () => {
  const nativeSources = [
    iosModule,
    androidModule,
    read('ios/Classes/TiAdmobUnifiedBannerAdProxy.m'),
    read('ios/Classes/TiAdmobUnifiedAdaptiveBannerAdProxy.m'),
    read('android/src/ti/admob/unified/TiAdmobUnifiedBannerAdProxy.java'),
    read('android/src/ti/admob/unified/TiAdmobUnifiedAdaptiveBannerAdProxy.java')
  ].join('\n')

  assert.doesNotMatch(nativeSources, /IABTCF_TCString/)
  assert.match(
    iosModule,
    /canShowPersonalizedAds:[\s\S]*?return @NO;/
  )
  assert.match(
    androidModule,
    /boolean canShowPersonalizedAds\(\)[\s\S]*?return false;/
  )
})

test('avoids keyWindow and preserves compatibility APIs', () => {
  const iosSources = fs.readdirSync(path.join(root, 'ios/Classes'))
    .filter(name => name.endsWith('.m'))
    .map(name => read(path.join('ios/Classes', name)))
    .join('\n')
  assert.doesNotMatch(iosSources, /keyWindow/)

  const compatibilityMethods = [
    'isAppLovinAvailable',
    'isInMobiAvailable',
    'isVungleAvailable',
    'setAppLovinGDPRConsent',
    'setInMobiGDPRConsent',
    'setVungleGDPRConsent',
    'enableOptionalMediationNetworks'
  ]
  for (const method of compatibilityMethods) {
    assert.match(iosModule, new RegExp(method))
    assert.match(androidModule, new RegExp(method))
  }

  const androidBannerSources = [
    read('android/src/ti/admob/unified/TiAdmobUnifiedBannerAdProxy.java'),
    read('android/src/ti/admob/unified/TiAdmobUnifiedAdaptiveBannerAdProxy.java')
  ].join('\n')
  assert.match(androidBannerSources, /destroyAdViewAndCancelRequest/)
  assert.match(androidBannerSources, /destoyAdViewAndCancelRequest/)
})

test('keeps documentation on the implemented API surface', () => {
  const readme = read('README.md')
  for (const method of [
    'initialize',
    'requestConsent',
    'canRequestAds',
    'canShowAds',
    'presentPrivacyOptions',
    'createBanner',
    'createAdaptiveBanner',
    'createInterstitial',
    'createRewarded'
  ]) {
    assert.match(readme, new RegExp(`\\b${method}\\b`))
    assert.match(`${iosHeader}\n${iosModule}`, new RegExp(method))
    assert.match(androidModule, new RegExp(method))
  }

  assert.match(readme, /App Open \| Not implemented/)
  assert.match(readme, /Native \| Not implemented/)
  assert.doesNotMatch(readme, /TypeScript Ready|300.?400%/)
})

test('artifact inventory guard accepts the current tree', () => {
  const output = execFileSync(
    path.join(root, 'scripts/verify-artifacts.sh'),
    { encoding: 'utf8' }
  )
  assert.match(output, /Artifact inventory and checksums verified/)
})

test('keeps one public banner lifecycle contract on both platforms', () => {
  const lifecycleMethods = [
    'load',
    'pause',
    'resume',
    'destroy',
    'isLoaded',
    'destroyAdViewAndCancelRequest',
    'destoyAdViewAndCancelRequest'
  ]

  for (const method of lifecycleMethods) {
    assert.match(iosBannerHeader, new RegExp(`\\b${method}:?`))
    assert.match(iosAdaptiveBannerHeader, new RegExp(`\\b${method}:?`))
    assert.match(androidBannerProxy, new RegExp(`\\b${method}\\s*\\(`))
    assert.match(androidAdaptiveBannerProxy, new RegExp(`\\b${method}\\s*\\(`))
  }
})

test('keeps banner event names and payload keys in parity', () => {
  const bannerSources = [
    iosBanner,
    iosAdaptiveBanner,
    androidBannerView,
    androidAdaptiveBannerView
  ]
  const eventNames = [
    'loaded',
    'failed_to_load',
    'clicked',
    'impression',
    'opened',
    'closed',
    'destroyed'
  ]

  for (const source of bannerSources) {
    for (const eventName of eventNames) {
      assert.match(source, new RegExp(`["']${eventName}["']|AD_${eventName.toUpperCase()}`))
    }
    for (const payloadKey of ['adUnitId', 'adType', 'isAdaptive']) {
      assert.match(source, new RegExp(`["']${payloadKey}["']`))
    }
    assert.match(source, /["']error["']/)
    assert.match(source, /["']code["']/)
  }

  for (const source of [iosAdaptiveBanner, androidAdaptiveBannerView]) {
    assert.match(source, /["']adaptiveType["']/)
  }
})

test('guards banner loading and makes destruction terminal and repeatable', () => {
  for (const source of [
    iosBanner,
    iosAdaptiveBanner,
    androidBannerView,
    androidAdaptiveBannerView
  ]) {
    assert.match(source, /isLoading/)
    assert.match(source, /isDestroyed/)
    assert.match(source, /isPaused/)
    assert.match(source, /pendingLoad/)
  }

  for (const source of [androidBannerView, androidAdaptiveBannerView]) {
    assert.match(source, /setAdListener\(null\)/)
    assert.match(source, /(?:adView|viewToDestroy)\.destroy\(\)/)
    assert.match(source, /void release\(\)/)
  }

  for (const source of [iosBanner, iosAdaptiveBanner]) {
    assert.match(source, /\.delegate = nil/)
    assert.match(source, /\.rootViewController = nil/)
    assert.match(source, /\.paidEventHandler = nil/)
    assert.match(source, /viewWillDetach/)
    assert.match(source, /windowWillClose/)
    assert.match(source, /- \(void\)_destroy/)
  }
})

test('connects Android banners to native activity lifecycle without leaks', () => {
  for (const source of [androidBannerProxy, androidAdaptiveBannerProxy]) {
    assert.match(source, /addOnLifecycleEventListener\(this\)/)
    assert.match(source, /removeOnLifecycleEventListener\(this\)/)
    assert.match(source, /onBannerViewDestroyed/)
  }

  for (const source of [androidBannerView, androidAdaptiveBannerView]) {
    assert.match(source, /adView\.pause\(\)/)
    assert.match(source, /adView\.resume\(\)/)
    assert.match(source, /(?:adView|viewToDestroy)\.destroy\(\)/)
    assert.match(source, /onBannerViewDestroyed\(this\)/)
  }
})

test('does not detach Android native banner views with a null view', () => {
  for (const source of [androidBannerView, androidAdaptiveBannerView]) {
    assert.doesNotMatch(source, /setNativeView\(null\)/)
    assert.match(source, /setAdListener\(null\)/)
    assert.match(source, /viewToDestroy\.destroy\(\)/)
    assert.doesNotMatch(
      source,
      /if \(adView == null && unitId != null\) \{\s*createAdView\(\)/
    )
  }
  assert.match(
    androidBannerView,
    /bannerProxy\.setProperty\(TiC\.PROPERTY_HEIGHT, adSize\.getHeight\(\)\)/
  )
  assert.match(
    androidAdaptiveBannerView,
    /bannerProxy\.setPropertyAndFire\(TiC\.PROPERTY_HEIGHT, heightDp \+ "dp"\)/
  )
  assert.match(androidAdaptiveBannerView, /updateProxyHeight\(loadedAdSize\.getHeight\(\)\)/)
  assert.match(androidAdaptiveBannerView, /addOnLayoutChangeListener\(layoutChangeListener\)/)
  assert.match(androidAdaptiveBannerView, /removeLayoutChangeListener\(viewToDestroy\)/)
})

test('keeps Android banner proxies attached to permanent native containers', () => {
  for (const source of [androidBannerView, androidAdaptiveBannerView]) {
    assert.match(source, /private final FrameLayout nativeContainer/)
    assert.match(source, /setNativeView\(nativeContainer\)/)
    assert.match(source, /nativeContainer\.addView\(/)
    assert.match(source, /nativeContainer\.removeView\(viewToDestroy\)/)
    assert.doesNotMatch(source, /setNativeView\(adView\)/)
  }
})

test('accepts Titanium HashMap values for Android custom banner sizes', () => {
  assert.match(
    androidBannerView,
    /customSizeValue instanceof Map[\s\S]*?new KrollDict\(customSizeMap\)/
  )
  assert.match(
    androidBannerProxy,
    /customSizeValue instanceof Map[\s\S]*?new KrollDict\(customSizeMap\)/
  )
  assert.doesNotMatch(
    androidBannerView,
    /KrollDict customSize = \(KrollDict\) properties\.get\("customAdSize"\)/
  )
  assert.doesNotMatch(
    androidBannerProxy,
    /return \(KrollDict\) getProperty\("customAdSize"\)/
  )
})

test('adaptive loaded events expose the real banner height on both platforms', () => {
  assert.match(
    androidAdaptiveBannerView,
    /event\.put\("height", adSize\.getHeight\(\)\)/
  )
  assert.match(androidAdaptiveBannerView, /event\.put\("heightUnit", "dp"\)/)
  assert.match(androidAdaptiveBannerView, /adSize\.getHeightInPixels\(activity\)/)
  assert.match(androidAdaptiveBannerView, /adSize\.getHeight\(\) \+ "dp"/)
  assert.match(
    iosAdaptiveBanner,
    /@"height": @\(bannerView\.adSize\.size\.height\)/
  )
  assert.match(iosAdaptiveBanner, /@"heightUnit": @"dp"/)
})
