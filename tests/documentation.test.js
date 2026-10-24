const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')

const root = path.resolve(__dirname, '..')

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8')
}

const documentationPages = [
  'README.md',
  'documentation/index.md',
  'documentation/getting-started.md',
  'documentation/integration.md',
  'documentation/production.md',
  'documentation/library.md',
  'documentation/privacy.md',
  'documentation/mediation.md',
  'documentation/third-party-notices.md',
  'documentation/banners.md',
  'documentation/fullscreen.md',
  'documentation/rewarded-interstitial.md',
  'documentation/api-reference.md',
  'documentation/migration.md'
]

const auxiliaryDocumentation = [
  'CHANGELOG.md',
  'CONTRIBUTING.md',
  'DEPENDENCIES.md',
  'MEDIATION_COMPARISON.md',
  'ROADMAP.md',
  'mediation/README.md'
]

const allDocumentation = [
  ...documentationPages,
  ...auxiliaryDocumentation
]

const apiReference = read('documentation/api-reference.md')
const example = read('example/app.js')
const reusableLibrary = read('example/lib/ads.js')
const libraryExample = read('example/library-usage.js')

test('ships a complete English documentation set', () => {
  for (const relativePath of allDocumentation) {
    assert.ok(
      fs.statSync(path.join(root, relativePath)).size > 0,
      `${relativePath} must not be empty`
    )
  }

  const index = read('documentation/index.md')
  for (const relativePath of documentationPages.slice(2)) {
    assert.match(
      index,
      new RegExp(path.basename(relativePath).replaceAll('.', '\\.')),
      `${relativePath} must be linked from the documentation index`
    )
  }
})

test('documents every public module method and compatibility method', () => {
  const source = read('android/src/ti/admob/unified/TiAdmobUnifiedModule.java')
  const methods = [...source.matchAll(/@Kroll\.method(?:\([^\n]*\))?\s+public\s+[\w<>]+\s+(\w+)\(/g)].map(match => match[1])
  assert.ok(methods.length >= 20, 'derive the complete current module surface')

  for (const method of methods) {
    assert.match(
      apiReference,
      new RegExp(`\\b${method}\\b`),
      `API reference is missing ${method}`
    )
  }
})

test('documents every exported constant by name', () => {
  const androidModule = read(
    'android/src/ti/admob/unified/TiAdmobUnifiedModule.java'
  )
  const constants = [
    ...androidModule.matchAll(
      /@Kroll\.constant public static final \w+ ([A-Z][A-Z0-9_]*)\s*=/g
    )
  ].map(match => match[1])

  assert.ok(constants.length > 50, 'expected the complete constant surface')
  for (const constant of constants) {
    assert.match(
      apiReference,
      new RegExp(`\\b${constant}\\b`),
      `API reference is missing ${constant}`
    )
  }
})

test('keeps every relative Markdown link resolvable', () => {
  const markdownLink = /(?<!!)\[[^\]]+\]\(([^)]+)\)/g

  for (const relativePath of allDocumentation) {
    const source = read(relativePath)
    const containingDirectory = path.dirname(path.join(root, relativePath))

    for (const match of source.matchAll(markdownLink)) {
      const target = match[1].split('#')[0]
      if (
        target.length === 0 ||
        target.startsWith('http://') ||
        target.startsWith('https://') ||
        target.startsWith('mailto:')
      ) {
        continue
      }

      assert.ok(
        fs.existsSync(path.resolve(containingDirectory, target)),
        `${relativePath} links to missing target ${target}`
      )
    }
  }
})

test('provides a modern, safe executable example', () => {
  assert.match(example, /require\('ti\.admob\.unified'\)/)
  assert.match(example, /addEventListener\('consent_complete'/)
  assert.match(example, /canRequestAds\(\)/)
  assert.match(example, /requestTrackingAuthorization\(\)/)
  assert.doesNotMatch(example, /disableMediation|enableMediation/)
  assert.doesNotMatch(example, /OS_IOS/)
  assert.match(example, /createAdaptiveBanner/)
  assert.match(example, /event\.height/)
  assert.match(example, /removeEventListener/)
  assert.match(example, /\.pause\(\)/)
  assert.match(example, /\.resume\(\)/)
  assert.match(example, /\.destroy\(\)/)

  assert.doesNotMatch(example, /consent_ready|consent_error/)
  assert.doesNotMatch(example, /canShowPersonalizedAds|isGDPR|canShowAds/)
  assert.doesNotMatch(example, /setTimeout|setInterval/)
  // App lifecycle listeners may defer ATT, but banner lifecycle stays native.
  for (const name of ['onApplicationPause', 'onApplicationResumed']) {
    const handler = example.match(new RegExp(`function ${name}\\(\\) \\{([^}]+)\\}`))
    assert.ok(handler)
    assert.doesNotMatch(handler[1], /banner|loadExampleAds|\.pause\(|\.resume\(/i)
  }
  assert.doesNotMatch(example, /applicationId|debugGeography/)
  assert.doesNotMatch(example, /ca-app-pub-\d+\/\d+/)

  // A hardcoded height is only wrong when it guesses what the ad will be. The
  // height inside customAdSize is the opposite: it is the size being requested,
  // and the slot can be reserved before the ad arrives precisely because of it.
  const guessedHeights = example.replace(/customAdSize:\s*\{[^}]*\}/g, '')
  assert.doesNotMatch(guessedHeights, /height:\s*(50|90|123)\b/)

  // The example must exercise the fixed full-width slot, which is the shape
  // most applications actually want and the one iOS could not request before.
  assert.match(example, /customAdSize: \{ width: screenWidthInDp\(\), height: 50 \}/)
  assert.match(example, /platformWidth \/ caps\.logicalDensityFactor/)

  // platformWidth is pixels on Android and points on iOS. Dividing on both is
  // the mistake that looks right, so the example must branch.
  assert.match(example, /Ti\.Platform\.osname === 'android'/)
})

test('ships a copy-ready integration library for every implemented ad format', () => {
  for (const factory of [
    'createBanner',
    'createAdaptiveBanner',
    'createInterstitial',
    'createRewarded',
    'createRewardedInterstitial',
    'createAppOpen'
  ]) {
    assert.match(reusableLibrary, new RegExp(`\\b${factory}\\b`))
    assert.match(libraryExample, new RegExp(`\\b${factory}\\b`))
  }

  assert.match(reusableLibrary, /requestConsent/)
  assert.match(reusableLibrary, /canRequestAds/)
  assert.match(reusableLibrary, /module_initialized/)
  assert.match(reusableLibrary, /presentPrivacyOptions/)
  assert.match(reusableLibrary, /openAdInspector/)
  assert.match(reusableLibrary, /pause\(\)/)
  assert.match(reusableLibrary, /resume\(\)/)
  assert.match(reusableLibrary, /destroyAll/)
  assert.doesNotMatch(reusableLibrary, /setTimeout|setInterval/)
  assert.doesNotMatch(reusableLibrary, /\.visible\s*=|\.opacity\s*=|\.height\s*=\s*0/)
  assert.doesNotMatch(reusableLibrary, /ca-app-pub-\d+\/\d+/)
})

test('states portable banner and fullscreen contracts', () => {
  const banners = read('documentation/banners.md')
  const fullscreen = read('documentation/fullscreen.md')

  assert.match(banners, /heightUnit: 'dp'/)
  assert.match(banners, /Do not hardcode the final height/)
  // Inline and collapsible are portable; collapsible takes
  // Google's own placement string. There is no constant for it, because a
  // constant would have to carry a value the SDK accepts.
  assert.match(banners, /`ADAPTIVE_INLINE` and `maxHeight` work on both platforms/)
  assert.match(banners, /takes Google's native placement string/)
  assert.match(banners, /no `COLLAPSIBLE_TOP` or `COLLAPSIBLE_BOTTOM` constant/)
  assert.match(banners, /content\.bottom = dimension/)
  assert.match(banners, /removeEventListener/)
  assert.match(banners, /Do not add a JavaScript renewal timer/)
  assert.match(banners, /does not change `visible`, `opacity`, height, or its host/)

  assert.match(fullscreen, /showed_fullscreen_content/)
  assert.match(fullscreen, /Terminal, idempotent cleanup/)
  assert.match(fullscreen, /`adUnitId`, `adType`, `error`, `message`, `code`/)
  assert.doesNotMatch(fullscreen, /iOS emits `opened` but does not currently emit/)
})

test('separates loading a fullscreen ad from presenting it', () => {
  const fullscreen = read('documentation/fullscreen.md')

  // `show()` reached without the `loaded` listener having closed first.
  assert.doesNotMatch(
    fullscreen,
    /AD_LOADED[^}]*\.show\(\)/,
    'fullscreen.md must not present an interstitial from inside its loaded listener'
  )

  assert.match(fullscreen, /## When to show a fullscreen ad/)
  assert.match(fullscreen, /Load early, show later/)
  assert.match(fullscreen, /natural break/)
  assert.match(fullscreen, /## Keeping the next ad ready/)
})

test('marks the test constants that have no factory as reserved', () => {
  const gettingStarted = read('documentation/getting-started.md')

  for (const constant of [
    'TEST_NATIVE'
  ]) {
    const reserved = new RegExp(`\`${constant}\`[^\\n]*None\\. Reserved`)

    assert.match(
      apiReference,
      reserved,
      `${constant} must be documented as reserved in the API reference`
    )
    assert.match(
      gettingStarted,
      reserved,
      `${constant} must be documented as reserved in getting started`
    )
  }

  // Not reserved: it is an ordinary interstitial unit with a video creative.
  const video = /`TEST_INTERSTITIAL_VIDEO`[^\n]*createInterstitial\(\)/
  assert.match(apiReference, video)
  assert.match(gettingStarted, video)
  const rewardedInterstitial = /`TEST_REWARDED_INTERSTITIAL`[^\n]*createRewardedInterstitial\(\)/
  assert.match(apiReference, rewardedInterstitial)
  assert.match(gettingStarted, rewardedInterstitial)
})

test('documents mediation without revenue promises', () => {
  const mediation = read('documentation/mediation.md')
  const readme = read('README.md')

  for (const network of [
    'Meta',
    'InMobi',
    'Unity',
    'AppLovin',
    'Liftoff',
    'ironSource'
  ]) {
    assert.match(mediation, new RegExp(network, 'i'))
    assert.match(readme, new RegExp(network, 'i'))
  }

  assert.match(mediation, /getMediationStatus/)
  assert.match(mediation, /Ad Inspector/)
  assert.doesNotMatch(
    `${mediation}\n${readme}`,
    /300.?400%|guaranteed revenue|guaranteed fill/i
  )
})

test('documents how to install optional network modules', () => {
  const mediation = read('documentation/mediation.md')
  const gettingStarted = read('documentation/getting-started.md')
  const migration = read('documentation/migration.md')

  // The pack is a second <module> line and nothing else. A page that names it
  // without showing that line leaves the reader to guess.
  for (const page of [mediation, gettingStarted, migration]) {
    assert.match(page, /<module version="1\.0\.0">ti\.admob\.unified\.mediation\.applovin<\/module>/)
  }

  // The premise this whole split corrects: an adapter is not a network.
  assert.match(
    mediation,
    /Installing an adapter is not the same as enabling a network/
  )

  // Upgrading from 1.x without the pack is silent, so migration.md has to say
  // both how to install it and how to check the build actually has it.
  assert.match(migration, /getMediationStatus/)

  // The diagnostics stay in the core module: a page that documents them as
  // belonging to the pack sends applications to require() something with no
  // JavaScript API.
  const apiSurface = read('documentation/api-reference.md')
  for (const method of [
    'getMediationStatus'
  ]) {
    assert.match(apiSurface, new RegExp(`\\b${method}\\b`))
  }
  assert.doesNotMatch(mediation, /require\('ti\.admob\.unified\.mediation'\)/)
})

test('describes the first release and five optional networks consistently', () => {
  for (const file of allDocumentation) {
    const page = read(file)
    assert.doesNotMatch(page, /version="2\.0\.0"|Version `2\.0\.0`|Through `1\.x`|From 1\.x/)
    assert.doesNotMatch(page, /<module[^>]*>ti\.admob\.unified\.mediation<\/module>/)
  }
  const mediation = read('documentation/mediation.md')
  for (const network of ['applovin', 'meta', 'inmobi', 'unity', 'liftoff']) {
    assert.ok(mediation.includes(`ti.admob.unified.mediation.${network}`))
  }
  assert.match(mediation, /IronSourceAdQualitySDK/)
  assert.match(mediation, /ironSource mediation is deferred/)
})


test('documents native proxy methods and properties derived from Android exports', () => {
  const directory = path.join(root, 'android/src/ti/admob/unified')
  for (const file of fs.readdirSync(directory).filter(name => name.endsWith('Proxy.java'))) {
    const source = fs.readFileSync(path.join(directory, file), 'utf8')
    for (const match of source.matchAll(/@Kroll\.(method|getProperty|setProperty)(?:\([^\n]*\))?\s+public\s+[\w<>\[\]]+\s+(\w+)\(/g)) {
      const name = match[1] === 'method' ? match[2] : match[2][3].toLowerCase() + match[2].slice(4)
      assert.match(apiReference, new RegExp(`\\b${name}\\b`), `${file}: missing ${name}`)
    }
  }
})
