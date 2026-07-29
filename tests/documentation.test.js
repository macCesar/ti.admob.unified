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
  'documentation/privacy.md',
  'documentation/mediation.md',
  'documentation/third-party-notices.md',
  'documentation/banners.md',
  'documentation/fullscreen.md',
  'documentation/api-reference.md',
  'documentation/migration-1.2.0.md'
]

const auxiliaryDocumentation = [
  'CHANGELOG.md',
  'CONTRIBUTING.md',
  'DEPENDENCIES.md',
  'MEDIATION_COMPARISON.md',
  'ROADMAP.md',
  'ios/README.md'
]

const allDocumentation = [
  ...documentationPages,
  ...auxiliaryDocumentation
]

const apiReference = read('documentation/api-reference.md')
const example = read('example/app.js')

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
  const methods = [
    'initialize',
    'requestConsent',
    'canRequestAds',
    'canShowAds',
    'canShowPersonalizedAds',
    'isGDPR',
    'isPrivacyOptionsRequired',
    'presentPrivacyOptions',
    'resetConsent',
    'requestTrackingAuthorization',
    'createRewarded',
    'createInterstitial',
    'createBanner',
    'createAdaptiveBanner',
    'createAppOpen',
    'setAppVolume',
    'setTestDevice',
    'isTestDevice',
    'isAppLovinAvailable',
    'isMetaAvailable',
    'isInMobiAvailable',
    'isVungleAvailable',
    'isUnityAvailable',
    'isIronSourceAvailable',
    'getMediationStatus',
    'setAppLovinGDPRConsent',
    'setInMobiGDPRConsent',
    'setVungleGDPRConsent',
    'enableOptionalMediationNetworks'
  ]

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
  assert.match(example, /getMediationStatus\(\)/)
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
  assert.doesNotMatch(example, /applicationId|debugGeography/)
  assert.doesNotMatch(example, /ca-app-pub-\d+\/\d+/)
  assert.doesNotMatch(example, /height:\s*(50|90|123)\b/)
})

test('states portable banner and fullscreen contracts', () => {
  const banners = read('documentation/banners.md')
  const fullscreen = read('documentation/fullscreen.md')

  assert.match(banners, /heightUnit: 'dp'/)
  assert.match(banners, /Do not hardcode a height/)
  assert.match(banners, /Inline adaptive banner \| No \| Yes/)
  assert.match(banners, /requires the native value `"top"` or `"bottom"`/)
  assert.match(
    banners,
    /do not pass\s+those constants to `collapsible`/
  )
  assert.match(banners, /content\.bottom = dimension/)
  assert.match(banners, /removeEventListener/)
  assert.match(banners, /Do not add a JavaScript renewal timer/)

  assert.match(fullscreen, /showed_fullscreen_content/)
  assert.match(fullscreen, /Terminal, idempotent cleanup/)
  assert.match(fullscreen, /`adUnitId`, `adType`, `error`, `message`, `code`/)
  assert.doesNotMatch(fullscreen, /iOS emits `opened` but does not currently emit/)
})

test('documents bundled mediation without revenue promises', () => {
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
