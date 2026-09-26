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
const iosInterstitial = read('ios/Classes/TiAdmobUnifiedInterstitialAdProxy.m')
const iosRewarded = read('ios/Classes/TiAdmobUnifiedRewardedAdProxy.m')
const androidInterstitial = read(
  'android/src/ti/admob/unified/TiAdmobUnifiedInterstitialAdProxy.java'
)
const androidRewarded = read(
  'android/src/ti/admob/unified/TiAdmobUnifiedRewardedAdProxy.java'
)
const iosAppOpen = read('ios/Classes/TiAdmobUnifiedAppOpenAdProxy.m')
const androidAppOpen = read(
  'android/src/ti/admob/unified/TiAdmobUnifiedAppOpenAdProxy.java'
)

const MEDIATION_NETWORKS = [
  {
    directory: 'applovin',
    frameworks: ['AppLovinAdapter', 'AppLovinSDK'],
    name: 'AppLovin',
    adapter: 'AppLovinAdapter',
    maven: 'applovin',
    iosNetworkSdk: '13.6.4',
    androidNetworkSdk: '13.6.4'
  },
  {
    directory: 'meta',
    frameworks: ['FBAudienceNetwork', 'MetaAdapter'],
    name: 'Meta Audience Network',
    adapter: 'MetaAdapter',
    maven: 'facebook',
    iosNetworkSdk: '6.22.0',
    androidNetworkSdk: '6.22.0'
  },
  {
    directory: 'inmobi',
    frameworks: ['InMobiAdapter', 'InMobiSDK'],
    name: 'InMobi',
    adapter: 'InMobiAdapter',
    maven: 'inmobi',
    iosNetworkSdk: '11.4.1',
    androidNetworkSdk: '11.4.1'
  },
  {
    directory: 'unity',
    frameworks: ['UnityAdapter', 'UnityAds', 'UnityCoherenceLib'],
    name: 'Unity Ads',
    adapter: 'UnityAdapter',
    maven: 'unity',
    iosNetworkSdk: '4.20.1',
    androidNetworkSdk: '4.20.1'
  },
  {
    directory: 'liftoff',
    frameworks: ['LiftoffMonetizeAdapter', 'VungleAdsSDK'],
    name: 'Liftoff Monetize',
    adapter: 'LiftoffMonetizeAdapter',
    maven: 'vungle',
    iosNetworkSdk: '7.7.7',
    androidNetworkSdk: '7.7.8',
    knownLag: true
  }
]

const NETWORK_NAMES = [
  'applovin',
  'facebook',
  'fbaudiencenetwork',
  'inmobi',
  'ironsource',
  'liftoff',
  'meta',
  'unity',
  'vungle'
]

test('pins the unified ads dependency baseline', () => {
  assert.match(read('ios/manifest'), /version: 1\.0\.0/)
  assert.match(read('android/manifest'), /version: 1\.0\.0/)

  const androidGradle = read('android/build.gradle')
  assert.match(androidGradle, /play-services-ads:25\.5\.0/)
  assert.match(androidGradle, /user-messaging-platform:4\.0\.0/)
  assert.match(androidGradle, /com\.google\.guava:guava:33\.7\.1-android/)

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
    '13.10.0'
  )
  assert.equal(
    frameworkVersion(
      'ios/platform/UserMessagingPlatform.xcframework/ios-arm64/UserMessagingPlatform.framework/Info.plist'
    ),
    '3.1.0'
  )

  assert.equal(
    read('ios/framework-checksums.sha256').trim().split('\n').length,
    platformEntries.length
  )
})

test('isolates five dependency-only mediation modules on both platforms', () => {
  const guids = new Set()
  for (const network of MEDIATION_NETWORKS) {
    const base = `mediation/${network.directory}`
    const id = `ti.admob.unified.mediation.${network.directory}`
    for (const platform of ['ios', 'android']) {
      assert.ok(fs.existsSync(path.join(root, base, platform, 'manifest')), `${id} ${platform} missing`)
      const manifest = read(`${base}/${platform}/manifest`)
      assert.match(manifest, /version: 1\.0\.0/)
      assert.ok(manifest.includes(`moduleid: ${id}\n`))
      const guid = /^guid: (.+)$/m.exec(manifest)[1]
      if (platform === 'ios') {
        assert.ok(!guids.has(guid), 'module GUIDs must be unique')
        guids.add(guid)
      } else assert.ok(guids.has(guid), 'platform GUIDs must match')
    }
    const gradle = read(`${base}/android/build.gradle`)
    const coordinates = [...gradle.matchAll(/implementation '([^']+)'/g)].map(match => match[1])
    const utilities = ['inmobi', 'liftoff'].includes(network.directory) ? ['com.squareup.okhttp3:okhttp:4.12.0'] : []
    assert.deepEqual(coordinates.slice(1), utilities, `${id} must include only its adapter and declared security fixes`)
    assert.ok(coordinates[0].startsWith(`com.google.ads.mediation:${network.maven}:`))
    const entries = fs.readdirSync(path.join(root, base, 'ios/platform')).sort()
    assert.deepEqual(entries, network.frameworks.map(name => `${name}.xcframework`).sort())
    const inventory = read(`${base}/ios/framework-checksums.sha256`).trim().split('\n').map(line => line.split(/\s+/)[1]).sort()
    assert.deepEqual(inventory, entries)
    const nativeName = `TiAdmobUnifiedMediation${network.directory[0].toUpperCase()}${network.directory.slice(1)}`
    const androidCarrier = read(`${base}/android/src/ti/admob/unified/mediation/${network.directory}/${nativeName}Module.java`)
    assert.doesNotMatch(androidCarrier, /@Kroll\.(method|constant|getProperty|setProperty)/)
    const iosCarrier = read(`${base}/ios/Classes/${nativeName}Module.m`)
    assert.doesNotMatch(iosCarrier, /initialize|startWith|fireEvent/)
    const project = read(`${base}/ios/${id}.xcodeproj/project.pbxproj`)
    assert.ok(project.includes(`${nativeName}Module.m in Sources`))
    assert.ok(project.includes(`${nativeName}ModuleAssets.m in Sources`))
    const flags = read(`${base}/ios/module.xcconfig`)
    assert.match(flags, /OTHER_LDFLAGS=\$\(inherited\).* -ObjC/)
  }
})

test('keeps every mediation network out of the core module', () => {
  // The whole separation is an inventory that can silently regress: one
  // -framework line or one Maven coordinate added back to the core, and every
  // application pays for six networks again without being asked.
  const coreArtifacts = {
    'ios/module.xcconfig': read('ios/module.xcconfig'),
    'android/build.gradle': read('android/build.gradle'),
    'ios/ti.admob.unified.xcodeproj/project.pbxproj': read(
      'ios/ti.admob.unified.xcodeproj/project.pbxproj'
    ),
    'ios/framework-checksums.sha256': read('ios/framework-checksums.sha256')
  }

  for (const [name, source] of Object.entries(coreArtifacts)) {
    for (const network of NETWORK_NAMES) {
      assert.doesNotMatch(
        source,
        new RegExp(network, 'i'),
        `${name} must not name ${network}: it belongs to the mediation pack`
      )
    }
  }

  // The linker flags are split, not duplicated: $(inherited) on both sides is
  // what lets Titanium concatenate them when both modules are installed.
  assert.match(read('ios/module.xcconfig'), /OTHER_LDFLAGS=\$\(inherited\)/)


  // -ObjC is what makes the adapters' Objective-C categories survive the link.

})

test('keeps the mediation network SDK versions aligned across platforms', () => {
  // Each adapter's Info.plist reports the network SDK it wraps, and the Maven
  // coordinate is `<network SDK version>.<adapter revision>`. Comparing those
  // two is what catches a one-sided bump.
  for (const network of MEDIATION_NETWORKS) {
    const mediationGradle = read(`mediation/${network.directory}/android/build.gradle`)
    const iosVersion = frameworkVersion(
      `mediation/${network.directory}/ios/platform/${network.adapter}.xcframework/` +
        `ios-arm64_x86_64-simulator/${network.adapter}.framework/Info.plist`
    )
    assert.equal(
      iosVersion,
      network.iosNetworkSdk,
      `${network.name}: the vendored iOS adapter no longer wraps ${network.iosNetworkSdk}`
    )

    const coordinate = new RegExp(
      `com\\.google\\.ads\\.mediation:${network.maven}:(\\S+)'`
    ).exec(mediationGradle)
    assert.ok(coordinate, `${network.name}: missing Maven coordinate`)

    const androidNetworkSdk = coordinate[1].split('.').slice(0, -1).join('.')
    assert.equal(
      androidNetworkSdk,
      network.androidNetworkSdk,
      `${network.name}: the Maven coordinate no longer wraps ${network.androidNetworkSdk}`
    )

    if (network.knownLag) {
      // Google publishes this network’s adapters on different schedules
      // per platform; the remaining Liftoff SDK difference is documented in
      // DEPENDENCIES.md. Pinning it is what makes it visible when it closes.
      assert.notEqual(iosVersion, androidNetworkSdk)
    } else {
      assert.equal(
        iosVersion,
        androidNetworkSdk,
        `${network.name}: iOS ships ${iosVersion} and Android ${androidNetworkSdk}`
      )
    }
  }
})

test('aligns Titanium and iOS deployment requirements', () => {
  for (const manifest of ['ios/manifest', 'android/manifest', ...MEDIATION_NETWORKS.flatMap(n => [`mediation/${n.directory}/ios/manifest`, `mediation/${n.directory}/android/manifest`])]) {
    assert.match(read(manifest), /minsdk: 13\.2\.0\.GA/)
  }
  for (const config of ['ios/titanium.xcconfig', ...MEDIATION_NETWORKS.map(n => `mediation/${n.directory}/ios/titanium.xcconfig`)]) {
    assert.match(read(config), /TITANIUM_SDK_VERSION = 13\.4\.1\.GA/)
  }
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

test('keeps tracking authorization portable across platforms', () => {
  const eventName = /tracking_authorization_completed/
  for (const source of [iosModule, androidModule]) {
    assert.match(source, /requestTrackingAuthorization/)
    assert.match(source, eventName)
    for (const payloadKey of ['status', 'authorized', 'applicable']) {
      assert.match(source, new RegExp(`["']${payloadKey}["']`))
    }
  }

  assert.match(iosHeader, /requestTrackingAuthorization/)
  assert.match(
    androidModule,
    /requestTrackingAuthorization\(\)[\s\S]*?applicable", false/
  )
})

test('exposes one portable Ad Inspector launcher and terminal event', () => {
  for (const source of [iosModule, androidModule]) {
    assert.match(source, /openAdInspector/)
    assert.match(source, /ad_inspector_closed/)
    for (const payloadKey of ['success', 'error', 'code']) {
      assert.match(source, new RegExp(`[\"']${payloadKey}[\"']`))
    }
  }

  assert.match(iosHeader, /openAdInspector/)
  assert.match(
    iosModule,
    /presentAdInspectorFromViewController:nil[\s\S]*?completionHandler/
  )
  assert.match(
    androidModule,
    /MobileAds\.openAdInspector\(activity,[\s\S]*?OnAdInspectorClosedListener/
  )
})

test('preserves global Android request configuration and reports test devices', () => {
  assert.match(
    androidModule,
    /MobileAds\.getRequestConfiguration\(\)\.toBuilder\(\)/
  )
  assert.match(
    androidModule,
    /isTestDevice\(\)[\s\S]*?new AdRequest\.Builder\(\)[\s\S]*?\.isTestDevice\(TiApplication\.getInstance\(\)\)/
  )
  assert.doesNotMatch(
    androidModule,
    /isTestDevice\(\)[\s\S]*?For now, return false/
  )
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

test('avoids keyWindow and preserves banner compatibility APIs', () => {
  const iosSources = fs.readdirSync(path.join(root, 'ios/Classes'))
    .filter(name => name.endsWith('.m'))
    .map(name => read(path.join('ios/Classes', name)))
    .join('\n')
  assert.doesNotMatch(iosSources, /keyWindow/)

  for (const source of [iosModule, androidModule]) {
    assert.match(source, /getMediationStatus/)
    assert.doesNotMatch(source, /is(?:AppLovin|Meta|InMobi|Vungle|Unity|IronSource)Available|set(?:AppLovin|InMobi|Vungle)GDPRConsent|enableOptionalMediationNetworks/)
  }

  const androidBannerSources = [
    read('android/src/ti/admob/unified/TiAdmobUnifiedBannerAdProxy.java'),
    read('android/src/ti/admob/unified/TiAdmobUnifiedAdaptiveBannerAdProxy.java')
  ].join('\n')
  assert.match(androidBannerSources, /destroyAdViewAndCancelRequest/)
  assert.match(androidBannerSources, /destoyAdViewAndCancelRequest/)
})

test('exposes a generic Google adapter diagnostic contract', () => {
  for (const source of [iosModule, androidModule]) {
    for (const key of ['initializationState', 'adapters', 'adapterClass', 'state', 'description', 'latencyMs', 'not_started', 'initializing', 'completed', 'failed', 'ready', 'not_ready']) {
      assert.ok(source.includes('"' + key + '"'), key)
    }
    assert.doesNotMatch(source, /FacebookMediationAdapter|AppLovinMediationAdapter|NSClassFromString|Class.forName/)
  }
  assert.match(androidModule, /getAdapterStatusMap/)
  assert.match(iosModule, /adapterStatusesByClassName/)
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
    'createRewarded',
    'createAppOpen'
  ]) {
    assert.match(readme, new RegExp(`\\b${method}\\b`))
    assert.match(`${iosHeader}\n${iosModule}`, new RegExp(method))
    assert.match(androidModule, new RegExp(method))
  }

  // Tolerate the cell padding a Markdown formatter adds: the claim is which
  // row says what, not how the table happens to be aligned.
  assert.match(readme, /App Open\s*\|\s*Implemented\s*\|\s*Implemented/)
  assert.match(readme, /Native\s*\|\s*Not implemented/)
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
  // iOS reports the same seven keys Android's buildSizeEvent does. A payload
  // with fewer keys forces the application to branch by platform, which is the
  // one thing this module exists to avoid.
  assert.match(iosAdaptiveBanner, /- \(NSDictionary \*\)sizeEventForBannerView:/)
  for (const key of [
    'width',
    'height',
    'widthUnit',
    'heightUnit',
    'widthPx',
    'heightPx',
    'density'
  ]) {
    assert.match(iosAdaptiveBanner, new RegExp(`@"${key}":`))
  }
  assert.match(iosAdaptiveBanner, /@"heightUnit": @"dp"/)
  assert.match(iosAdaptiveBanner, /@"widthUnit": @"dp"/)
  // The pixel counts derive from the screen the banner is on, falling back to
  // the main screen while the view has no window yet.
  assert.match(
    iosAdaptiveBanner,
    /bannerView\.window\.screen \?: \[UIScreen mainScreen\]/
  )
})

test('keeps fullscreen lifecycle terminal and serialized on both platforms', () => {
  for (const source of [
    iosInterstitial,
    iosRewarded,
    iosAppOpen,
    androidInterstitial,
    androidRewarded,
    androidAppOpen
  ]) {
    assert.match(source, /isLoading/)
    assert.match(source, /isShowing/)
    assert.match(source, /isDestroyed/)
    assert.match(source, /destroyedEventFired/)
    assert.match(source, /Ignoring duplicate/)
    assert.match(source, /showed_fullscreen_content|AD_SHOWED_FULLSCREEN_CONTENT/)
  }

  // The cleanup has to be the terminal one. Matching the call anywhere in the
  // file would also accept it from an ordinary discard path and report a leak
  // in destroy() as clean.
  for (const source of [iosInterstitial, iosRewarded, iosAppOpen]) {
    assert.match(source, /isDestroyed = YES;\s*self->\w+\.fullScreenContentDelegate = nil;/)
    assert.match(source, /- \(void\)_destroy/)
    assert.match(source, /\[self destroy:nil\];\s*\[super _destroy\];/)
  }
  for (const source of [androidInterstitial, androidRewarded, androidAppOpen]) {
    assert.match(
      source,
      /isDestroyed = true;\s*if \(\w+ != null\) \{\s*\w+\.setFullScreenContentCallback\(null\);/
    )
    assert.match(source, /public void release\(\)/)
    assert.match(source, /destroy\(\);\s*super\.release\(\);/)
  }
})

test('keeps fullscreen event payloads portable', () => {
  for (const source of [
    iosInterstitial,
    iosRewarded,
    iosAppOpen,
    androidInterstitial,
    androidRewarded,
    androidAppOpen
  ]) {
    for (const payloadKey of ['adUnitId', 'adType', 'error', 'message', 'code']) {
      assert.match(source, new RegExp(`["']${payloadKey}["']`))
    }
  }

  for (const source of [iosRewarded, androidRewarded]) {
    assert.match(source, /["']rewardType["']/)
    assert.match(source, /["']rewardAmount["']/)
  }
})

test('identifies the request origin on every placement', () => {
  // GADRequest.requestAgent and AbstractAdRequestBuilder.setRequestAgent both
  // exist in the bundled SDKs. Placing it on some placements and not others is
  // how contentUrl ended up half-implemented, so this covers all five.
  const iosPlacements = [iosBanner, iosAdaptiveBanner, iosInterstitial, iosRewarded, iosAppOpen]
  const androidPlacements = [
    androidBannerView,
    androidAdaptiveBannerView,
    androidInterstitial,
    androidRewarded,
    androidAppOpen
  ]

  for (const source of iosPlacements) {
    assert.match(source, /request\.requestAgent = self(\.proxy)?\.requestAgent/)
  }
  for (const source of androidPlacements) {
    assert.match(source, /adRequestBuilder\.setRequestAgent\(requestAgent\)/)
  }

  // Declared on both sides of the bridge, not just used internally.
  for (const header of [
    iosBannerHeader,
    iosAdaptiveBannerHeader,
    read('ios/Classes/TiAdmobUnifiedInterstitialAdProxy.h'),
    read('ios/Classes/TiAdmobUnifiedRewardedAdProxy.h'),
    read('ios/Classes/TiAdmobUnifiedAppOpenAdProxy.h')
  ]) {
    assert.match(header, /NSString \*requestAgent/)
  }
  for (const source of [androidBannerProxy, androidAdaptiveBannerProxy]) {
    assert.match(source, /@Kroll\.setProperty\s*\n\s*public void setRequestAgent/)
  }

  // An empty string is not an origin; it must not reach the request.
  for (const source of iosPlacements) {
    assert.match(source, /\[self(\.proxy)?\.requestAgent length\] > 0/)
  }
  for (const source of androidPlacements) {
    assert.match(source, /!requestAgent\.isEmpty\(\)/)
  }
})

test('exports no constant that the native SDK would reject', () => {
  // COLLAPSIBLE_TOP/BOTTOM carried "collapsible_top"/"collapsible_bottom" and
  // both platforms passed the value straight to Google, which takes only "top"
  // and "bottom". The constants could not be used for the one thing they named.
  for (const source of [iosModule, androidModule]) {
    assert.doesNotMatch(source, /COLLAPSIBLE_TOP\s*(\{|=)/)
    assert.doesNotMatch(source, /COLLAPSIBLE_BOTTOM\s*(\{|=)/)
    assert.doesNotMatch(source, /["']collapsible_(top|bottom)["']/)
  }

  // The property itself stays on Android and still takes the native string.
  assert.match(androidAdaptiveBannerView, /requestExtras\.putString\("collapsible", collapsible\)/)

  for (const doc of ['documentation/api-reference.md', 'documentation/banners.md']) {
    assert.doesNotMatch(read(doc), /\| `COLLAPSIBLE_(TOP|BOTTOM)` \|/)
  }

  // smart_banner is gone from the size resolvers for the same reason: Google
  // removed it on Android and deprecated it on iOS, and the module used to turn
  // one value into two different ads.
  assert.doesNotMatch(iosBanner, /isEqualToString:@"smart_banner"/)
  assert.doesNotMatch(iosBanner, /kGADAdSizeSmartBanner/)
  assert.doesNotMatch(androidBannerView, /case "smart_banner":/)
  assert.doesNotMatch(androidBannerView, /AdSize\.SMART_BANNER/)
})

test('makes inline adaptive banners portable', () => {
  // ADAPTIVE_INLINE was exported on both platforms but only Android acted on it.
  assert.match(iosAdaptiveBannerHeader, /adaptiveType/)
  assert.match(iosAdaptiveBannerHeader, /maxHeight/)
  assert.match(
    iosAdaptiveBanner,
    /GADInlineAdaptiveBannerAdSizeWithWidthAndMaxHeight\(width, maxHeight\)/
  )
  assert.match(androidAdaptiveBannerView, /AdSize\.getInlineAdaptiveBannerAdSize\(adWidth, maxHeight\)/)

  // Anchored has to keep the large variant: Google deprecated the plain one.
  assert.match(iosAdaptiveBanner, /GADLargeAnchoredAdaptiveBannerAdSizeWithWidth\(width\)/)

  // Same default on both, so one placement definition behaves alike.
  assert.match(iosAdaptiveBanner, /_maxHeight = 50/)
  assert.match(androidAdaptiveBannerView, /maxHeight = 50/)

  // maxHeight is meaningless for anchored, where Google fixes the height.
  assert.match(iosAdaptiveBanner, /isInlineAdaptive:nil internal:nil\][\s\S]*?maxHeight/)

  // The reported type follows the requested one, and both platforms echo back
  // the constant the caller passed. iOS used to emit a shortened "anchored"
  // while Android emitted "adaptive_anchored", so the same comparison in shared
  // JavaScript succeeded on one platform and failed on the other.
  assert.match(
    iosAdaptiveBanner,
    /isInlineAdaptive:nil internal:nil\] \? @"adaptive_inline" : @"adaptive_anchored"/
  )
  assert.match(androidAdaptiveBannerView, /data\.put\("adaptiveType", adaptiveType\)/)
  assert.doesNotMatch(iosAdaptiveBanner, /@"adaptiveType": @"anchored"/)
})

test('accepts a custom banner size on both platforms', () => {
  // Android builds `new AdSize(width, height)` from { width, height } in dp.
  // GADAdSizeFromCGSize is the documented iOS counterpart, so the same
  // JavaScript object has to reach the same request.
  assert.match(androidBannerProxy, /customAdSize/)
  assert.match(androidBannerView, /new AdSize\(width, height\)/)

  assert.match(iosBannerHeader, /customAdSize/)
  assert.match(
    iosBanner,
    /adSizeForString:[\s\S]*?customSize[\s\S]*?GADAdSizeFromCGSize\(CGSizeMake\(width, height\)\)/
  )
  // A custom size that never reaches the GADBannerView is decoration.
  assert.match(
    iosBanner,
    /adSizeForString:self\.proxy\.adSize\s*\n?\s*customSize:self\.proxy\.customAdSize/
  )
  // Both platforms reject a size that is not two positive numbers.
  assert.match(iosBanner, /width > 0 && height > 0/)
  assert.match(androidBannerView, /Ignoring invalid customAdSize value/)
  assert.match(iosBanner, /Ignoring invalid customAdSize value/)
})

test('applies targeting on every iOS placement, not just some', () => {
  const iosPlacements = [iosBanner, iosAdaptiveBanner, iosInterstitial, iosRewarded, iosAppOpen]

  // GADRequest.keywords is declared in the bundled GoogleMobileAds 13.10.0 and
  // is the counterpart of Android's addKeyword. Every placement must use it.
  for (const source of iosPlacements) {
    assert.match(source, /request\.keywords = self(\.proxy)?\.keywords/)
  }

  // Keywords inside GADExtras go to mediation adapters, not to targeting. That
  // is what these proxies used to do, so the ads went out untargeted.
  for (const source of iosPlacements) {
    assert.doesNotMatch(source, /forKey:@"keywords"/)
  }

  // And the banner must stop claiming the SDK dropped the API.
  assert.doesNotMatch(iosBanner, /not supported in current GAD version/)

  // contentUrl reaches the request on both banner types, matching Android.
  for (const source of [iosBanner, iosAdaptiveBanner]) {
    assert.match(source, /request\.contentURL = self\.proxy\.contentUrl/)
  }
  for (const source of [iosBannerHeader, iosAdaptiveBannerHeader]) {
    assert.match(source, /contentUrl/)
  }
  for (const source of [androidBannerView, androidAdaptiveBannerView]) {
    assert.match(source, /adRequestBuilder\.setContentUrl\(contentUrl\)/)
  }

  // The adaptive banner used to send a bare GADRequest.
  assert.match(iosAdaptiveBanner, /registerAdNetworkExtras/)
})

test('enforces the app open four hour window on both platforms', () => {
  // Google documents that an app open ad expires four hours after the request
  // and may not earn revenue afterwards, so the proxy — not the consumer — has
  // to know when the ad arrived.
  assert.match(iosAppOpen, /4 \* 60 \* 60/)
  assert.match(androidAppOpen, /4 \* 60 \* 60 \* 1000L/)

  // The load time is stamped on arrival and cleared with the ad.
  assert.match(iosAppOpen, /self->loadTime = \[NSDate date\]/)
  assert.match(androidAppOpen, /loadTime = System\.currentTimeMillis\(\)/)

  // `isLoaded()` consults it: an expired ad is not ready.
  assert.match(iosAppOpen, /- \(NSNumber \*\)isLoaded:[\s\S]*?!\[self isAdExpired:nil internal:nil\]/)
  assert.match(androidAppOpen, /public boolean isLoaded\(\)[\s\S]*?!isAdExpired\(\)/)

  // `show()` on an expired ad clears the native reference and reports it
  // through the event the contract already defines for a failed presentation.
  assert.match(
    iosAppOpen,
    /- \(void\)show:[\s\S]*?\[self isAdExpired:nil internal:nil\][\s\S]*?\[self discardAd:nil internal:nil\][\s\S]*?App open ad expired after four hours/
  )
  assert.match(
    androidAppOpen,
    /public void show\(\)[\s\S]*?isAdExpired\(\)[\s\S]*?discardAd\(\)[\s\S]*?App open ad expired after four hours/
  )

  // No timer and no background work: the check is a subtraction on demand.
  for (const source of [iosAppOpen, androidAppOpen]) {
    assert.doesNotMatch(source, /NSTimer|scheduledTimer|Handler\(|postDelayed|dispatch_after/)
  }

  // An expired ad must not block the next request through the duplicate guard.
  assert.match(
    iosAppOpen,
    /- \(void\)load:[\s\S]*?\[self isAdExpired:nil internal:nil\][\s\S]*?\[self discardAd:nil internal:nil\][\s\S]*?Ignoring duplicate/
  )
  assert.match(
    androidAppOpen,
    /public void load\(\)[\s\S]*?isAdExpired\(\)[\s\S]*?discardAd\(\)[\s\S]*?Ignoring duplicate/
  )

  // autoReload keeps its documented scope: it reloads after `closed` only.
  for (const source of [iosAppOpen, androidAppOpen]) {
    assert.doesNotMatch(source, /expired[\s\S]{0,200}autoReload/)
  }
})

test('keeps the app open factory and ad type portable', () => {
  assert.match(iosModule, /TiAdmobUnifiedAppOpenAdProxy alloc/)
  assert.match(iosHeader, /createAppOpen/)
  assert.doesNotMatch(iosModule, /TODO: Implement app open ad proxy/)
  assert.match(
    androidModule,
    /public TiAdmobUnifiedAppOpenAdProxy createAppOpen\(KrollDict config\)/
  )

  assert.match(iosAppOpen, /@"adType": @"app_open"/)
  assert.match(androidAppOpen, /TiAdmobUnifiedModule\.AD_TYPE_APP_OPEN/)

  // The iOS archive only compiles what the build phases register, and a green
  // `ti build` does not prove it: the compile passes, the ZIP packages, and the
  // consumer fails to link. Declaring the file is not enough — it has to be in
  // the phase, so the assertion reads the phase and not the whole project.
  const xcodeProject = read('ios/ti.admob.unified.xcodeproj/project.pbxproj')
  const phase = (name) =>
    xcodeProject
      .split(`/* Begin PBX${name}BuildPhase section */`)[1]
      .split(`/* End PBX${name}BuildPhase section */`)[0]

  assert.match(phase('Sources'), /TiAdmobUnifiedAppOpenAdProxy\.m in Sources/)
  assert.match(phase('Headers'), /TiAdmobUnifiedAppOpenAdProxy\.h in Headers/)
})

test('forwards fullscreen extras through the Google adapter on Android', () => {
  for (const source of [androidInterstitial, androidRewarded, androidAppOpen]) {
    assert.match(source, /addNetworkExtrasBundle\(AdMobAdapter\.class, extrasBundle\)/)
  }
})

test('lets an application skip mediation initialization on both platforms', () => {
  for (const source of [iosModule, androidModule]) {
    assert.match(source, /["']?disableMediation["']?/)
  }

  // The native call only takes effect before the SDK starts, so the order is
  // part of the contract, not a detail of the implementation.
  assert.match(
    androidModule,
    /disableMediation[\s\S]*?MobileAds\.disableMediationAdapterInitialization\(activity\)[\s\S]*?MobileAds\.initialize\(/
  )
  assert.match(
    iosModule,
    /disableMediation[\s\S]*?disableMediationInitialization\][\s\S]*?startWithCompletionHandler/
  )

  // Skipping initialization must never mean dropping a network.
  assert.match(
    read('mediation/liftoff/android/build.gradle'),
    /com\.google\.ads\.mediation:vungle/
  )
})

test('tracks application and lifecycle pauses as independent causes', () => {
  const banners = [
    iosBanner,
    iosAdaptiveBanner,
    androidBannerProxy,
    androidAdaptiveBannerProxy
  ]

  // One flag cannot express two causes: the lifecycle would resume a banner the
  // application deliberately paused, and a load deferred while paused would
  // fire into a placement nobody is looking at.
  for (const source of banners) {
    assert.match(source, /pausedByApp/)
    assert.match(source, /pausedByLifecycle/)
  }

  // The proxy owns the combined state and must not assign it directly. The
  // view classes keep their own `isPaused` — on iOS they share this file — and
  // that one is legitimate, so the assertion is scoped to proxy assignments.
  for (const source of [iosBanner, iosAdaptiveBanner]) {
    assert.doesNotMatch(source, /self\.isPaused\s*=/)
  }
  for (const source of [androidBannerProxy, androidAdaptiveBannerProxy]) {
    assert.doesNotMatch(source, /\bisPaused\s*=\s*(true|false)/)
  }

  // The public methods own only the application cause.
  for (const source of [androidBannerProxy, androidAdaptiveBannerProxy]) {
    assert.match(source, /public void pause\(\)[\s\S]*?pausedByApp = true/)
    assert.match(source, /public void resume\(\)[\s\S]*?pausedByApp = false/)
    assert.match(source, /public void onPause\(Activity[\s\S]*?pausedByLifecycle = true/)
    assert.match(source, /public void onResume\(Activity[\s\S]*?pausedByLifecycle = false/)
  }

  for (const source of [iosBanner, iosAdaptiveBanner]) {
    assert.match(source, /- \(void\)pause:\(id\)args[\s\S]*?pausedByApp = YES/)
    assert.match(source, /- \(void\)resume:\(id\)args[\s\S]*?pausedByApp = NO/)
  }

  // Resuming is gated on every cause being clear, on both platforms.
  for (const source of [androidBannerProxy, androidAdaptiveBannerProxy]) {
    assert.match(source, /private void applyResume\(\)\s*\{\s*if \(isDestroyed \|\| isPaused\(\)\)/)
  }
  for (const source of [iosBanner, iosAdaptiveBanner]) {
    assert.match(source, /- \(void\)applyResume:\(id\)unused internal:\(id\)context\s*\{\s*if \(self->_isDestroyed \|\| \[self isPaused:nil internal:nil\]\)/)
  }
})

test('follows the host lifecycle on both platforms', () => {
  // Android already followed its activity. iOS observed nothing, so a
  // backgrounded app kept a banner running behind the home screen.
  for (const source of [iosBanner, iosAdaptiveBanner]) {
    assert.match(source, /UIApplicationDidEnterBackgroundNotification/)
    assert.match(source, /UIApplicationWillEnterForegroundNotification/)
    assert.match(source, /removeObserver:_nativeDelegate/)

    // Resign-active fires for transient interruptions that leave the ad on
    // screen and viewable; pausing there would blank a visible banner.
    assert.doesNotMatch(source, /UIApplicationWillResignActiveNotification/)
  }

  for (const source of [androidBannerProxy, androidAdaptiveBannerProxy]) {
    assert.match(source, /implements TiLifecycle\.OnLifecycleEvent/)
  }
})

test('preserves Android banner proxies across Activity configuration recreation', () => {
  const pairs = [
    [androidBannerProxy, androidBannerView],
    [androidAdaptiveBannerProxy, androidAdaptiveBannerView]
  ]

  for (const [proxy, view] of pairs) {
    assert.match(proxy, /activity\.isChangingConfigurations\(\)/)
    assert.match(proxy, /reloadAfterActivityRecreation = loadRequested/)
    assert.match(proxy, /pausedByLifecycle = true/)
    assert.match(proxy, /releaseForActivityRecreation\(\)/)
    assert.match(proxy, /void onBannerViewReady\([\s\S]*?readyView\.loadAd\(\)/)

    // Releasing the stale native view must neither fire AD_DESTROYED nor mark
    // the JavaScript proxy as permanently destroyed.
    const temporaryRelease = view.match(
      /void releaseForActivityRecreation\(\)([\s\S]*?)\n\t\}/
    )
    assert.ok(temporaryRelease)
    assert.match(temporaryRelease[1], /viewToDestroy\.destroy\(\)/)
    assert.doesNotMatch(temporaryRelease[1], /AD_DESTROYED/)
    assert.doesNotMatch(temporaryRelease[1], /onBannerViewDestroyed/)

    // A real close still follows the public permanent-destruction path.
    assert.match(proxy, /Activity destroyed, cleaning up[\s\S]*?destroy\(\)/)
  }
})

test('pauses banners without mutating their visual state', () => {
  for (const source of [iosBanner, iosAdaptiveBanner]) {
    assert.doesNotMatch(source, /bannerView\.hidden\s*=/)
    assert.match(source, /bannerView\.autoloadEnabled = NO/)
    assert.match(source, /bannerView\.autoloadEnabled = autoloadEnabledBeforePause/)
  }

  // Visibility and layout belong to the Titanium application. The native
  // lifecycle methods must preserve the same creative, host and measured slot.
  for (const source of [androidBannerView, androidAdaptiveBannerView]) {
    assert.doesNotMatch(source, /adView\.setVisibility/)
    assert.match(source, /public void pause\(\)[\s\S]*?adView\.pause\(\)/)
    assert.match(source, /public void resume\(\)[\s\S]*?adView\.resume\(\)/)
  }
})

test('maps debug geography to the SDK enum rather than a literal', () => {
  // OTHER used to return the deprecated NotEEA (2) while Android sent 4, so the
  // same public constant produced two different requests.
  assert.match(iosModule, /DEBUG_GEOGRAPHY_OTHER \{ return @\(UMPDebugGeographyOther\); \}/)
  assert.match(
    iosModule,
    /DEBUG_GEOGRAPHY_REGULATED_US_STATE \{ return @\(UMPDebugGeographyRegulatedUSState\); \}/
  )
  assert.doesNotMatch(iosModule, /UMPDebugGeographyNotEEA/)
  assert.doesNotMatch(iosModule, /DEBUG_GEOGRAPHY_REGULATED_US_STATE \{ return @\(3\)/)

  for (const constant of [
    'DEBUG_GEOGRAPHY_DISABLED',
    'DEBUG_GEOGRAPHY_EEA',
    'DEBUG_GEOGRAPHY_REGULATED_US_STATE',
    'DEBUG_GEOGRAPHY_OTHER'
  ]) {
    assert.match(
      androidModule,
      new RegExp(`${constant} = ConsentDebugSettings\\.DebugGeography\\.${constant}`)
    )
  }
})

test('restores banner autoloading when every pause cause is gone', () => {
  // pause() turned autoloading off and resume() never turned it back on, so a
  // single trip to the background left the banner opted out for the rest of the
  // session. The value is remembered rather than forced, so resuming restores
  // what the banner actually had.
  for (const source of [iosBanner, iosAdaptiveBanner]) {
    assert.match(
      source,
      /autoloadEnabledBeforePause = bannerView\.autoloadEnabled;\s*bannerView\.autoloadEnabled = NO;/
    )
    assert.match(
      source,
      /- \(void\)resumeAd[\s\S]*?bannerView\.autoloadEnabled = autoloadEnabledBeforePause;/
    )
  }
})

test('reads requestAgent from the creation dictionary on iOS fullscreen ads', () => {
  // The property existed and the request used it, but configureWithDict never
  // read the key, so a value set from JavaScript was silently discarded on iOS
  // while Android honoured it.
  for (const source of [iosInterstitial, iosRewarded, iosAppOpen]) {
    assert.match(
      source,
      /if \(\[config objectForKey:@"requestAgent"\]\) \{\s*self\.requestAgent = \[TiUtils stringValue:\[config objectForKey:@"requestAgent"\]\];/
    )
  }
  assert.match(androidInterstitial, /config\.optString\("requestAgent"/)
})

test('reports the reward the SDK granted and nothing else', () => {
  // iOS substituted "coins"/1 when the SDK gave no values, so an application
  // could credit a reward on iOS that Android never granted.
  assert.doesNotMatch(iosRewarded, /@"coins"/)
  assert.match(iosRewarded, /rewardEvent\[@"rewardType"\] = reward\.type \?: \[NSNull null\]/)
  assert.match(iosRewarded, /rewardEvent\[@"rewardAmount"\] = reward\.amount \?: \[NSNull null\]/)
  assert.match(androidRewarded, /rewardEvent\.put\("rewardType", rewardItem\.getType\(\)\)/)
  assert.match(androidRewarded, /rewardEvent\.put\("rewardAmount", rewardItem\.getAmount\(\)\)/)
})

test('exposes network extras as a readable property on Android banners', () => {
  // iOS carried extras as a live property; on Android it was write-only at
  // creation and reading it returned undefined.
  for (const source of [androidBannerProxy, androidAdaptiveBannerProxy]) {
    assert.match(source, /@Kroll\.getProperty\s*\n\s*public KrollDict getExtras/)
    assert.match(source, /@Kroll\.setProperty\s*\n\s*public void setExtras\(KrollDict extras\)/)
    assert.match(source, /bannerView\.setExtras\(TiAdmobUnifiedModule\.toExtrasBundle\(extras\)\)/)
  }

  // One conversion, shared: a value must not change type depending on which
  // banner received it.
  assert.match(androidModule, /static Bundle toExtrasBundle\(KrollDict extrasDict\)/)
  for (const source of [androidBannerView, androidAdaptiveBannerView]) {
    assert.match(
      source,
      /setExtras\(TiAdmobUnifiedModule\.toExtrasBundle\(\(KrollDict\) properties\.get\("extras"\)\)\)/
    )
    assert.doesNotMatch(source, /Bundle extrasBundle = new Bundle\(\)/)
  }
})

test('lets iOS banner events bubble to the container', () => {
  // Banner proxies descend from TiViewProxy, whose events bubble to the parent.
  // A _hasListeners guard drops the event before it can rise, so a listener on
  // the containing window never sees it. Android has no such guard.
  for (const source of [iosBanner, iosAdaptiveBanner]) {
    assert.doesNotMatch(source, /if \(\[self _hasListeners:/)
  }
})

test('carries adaptiveType on every adaptive event Android fires', () => {
  // The view included it; the events the proxy fires on its own — destroyed
  // with no view, failed_to_load after destruction — did not, so the payload
  // shape depended on which object happened to fire it.
  assert.match(
    androidAdaptiveBannerProxy,
    /private void fireBannerEvent[\s\S]*?event\.put\("adaptiveType"/
  )
  assert.match(androidAdaptiveBannerView, /data\.put\("adaptiveType", adaptiveType\)/)
})

test('keeps iOS fullscreen internals off the JavaScript surface', () => {
  // Android exposes neither the native ad object nor the loading state. A
  // synthesised getter — even from a class extension — is reachable through
  // Kroll's key lookup, so these are plain ivars with direct key-value access
  // turned off.
  const headers = {
    'ios/Classes/TiAdmobUnifiedInterstitialAdProxy.h': 'GADInterstitialAd',
    'ios/Classes/TiAdmobUnifiedRewardedAdProxy.h': 'GADRewardedAd',
    'ios/Classes/TiAdmobUnifiedAppOpenAdProxy.h': 'GADAppOpenAd'
  }
  for (const [file, nativeClass] of Object.entries(headers)) {
    const header = read(file)
    assert.doesNotMatch(header, new RegExp(`${nativeClass} \\*`))
    for (const state of [
      'isLoading',
      'isShowing',
      'isDestroyed',
      'destroyedEventFired',
      'loadTime'
    ]) {
      assert.doesNotMatch(header, new RegExp(`@property[^\\n]*\\b${state}\\b`))
    }
  }

  for (const source of [iosInterstitial, iosRewarded, iosAppOpen]) {
    assert.match(
      source,
      /\+ \(BOOL\)accessInstanceVariablesDirectly\s*\{\s*return NO;\s*\}/
    )
  }
})

test('supports collapsible adaptive banners on both platforms', () => {
  // GADBannerView documents isCollapsible, and the vehicle is a network extra
  // with the same key and values Android puts in its Bundle.
  assert.match(iosAdaptiveBannerHeader, /NSString \*collapsible/)
  assert.match(iosAdaptiveBanner, /additionalParameters\[@"collapsible"\] = self\.proxy\.collapsible/)
  assert.match(androidAdaptiveBannerView, /requestExtras\.putString\("collapsible", collapsible\)/)
  assert.match(
    androidAdaptiveBannerProxy,
    /@Kroll\.setProperty\s*\n\s*public void setCollapsible/
  )

  // One GADExtras carries extras and collapsible together: registering a second
  // one for the same network replaces the first instead of adding to it.
  assert.equal(iosAdaptiveBanner.match(/\[\[GADExtras alloc\] init\]/g).length, 1)
  assert.match(
    iosAdaptiveBanner,
    /extras\.additionalParameters = additionalParameters;\s*\[request registerAdNetworkExtras:extras\]/
  )
})

test('does not distribute an aggregate or ironSource advertising module', () => {
  for (const directory of ['mediation/ios', 'mediation/android', 'mediation/ironsource']) {
    assert.equal(fs.existsSync(path.join(root, directory)), false, directory)
  }
})
