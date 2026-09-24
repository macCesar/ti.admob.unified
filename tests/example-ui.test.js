const test = require('node:test')
const assert = require('node:assert/strict')
const vm = require('node:vm')
const fs = require('node:fs')
const path = require('node:path')

// Execute the actual sample with bridge doubles. This checks interaction and
// lifecycle contracts; native rendering is verified separately in a simulator.
function openExample(osname = 'iphone', properties = {}, deployType = 'development') {
  const views = []
  const ads = []
  function proxy(properties = {}) {
    const listeners = {}
    return Object.assign({
      children: [], size: { width: 390 }, rect: { width: 0, height: 0 },
      add(child) { this.children.push(child) },
      remove(child) { this.children = this.children.filter(item => item !== child) },
      applyProperties(values) { Object.assign(this, values) },
      addEventListener(name, fn) { (listeners[name] ||= new Set()).add(fn) },
      removeEventListener(name, fn) { listeners[name]?.delete(fn) },
      emit(name, event = {}) { listeners[name]?.forEach(fn => fn(event)) },
      open() { this.emit('open') }, blur() {}, load() { this.loads = (this.loads || 0) + 1 },
      show() { this.shows = (this.shows || 0) + 1 },
      destroy() { this.destroyed = true }, pause() {}, resume() {}
    }, properties)
  }
  const Admob = proxy({
    allowed: false, canRequestAds() { return this.allowed },
    getAnchoredAdaptiveBannerSize(width) { assert.ok(width > 0); return { width, height: 64, heightUnit: 'dp' } },
    initialize(config) { (this.initializations ||= []).push(config) }, requestConsent(config) { (this.consentRequests ||= []).push(config) },
    resetConsent() { this.resets = (this.resets || 0) + 1; this.allowed = false }, requestTrackingAuthorization() {},
    presentPrivacyOptions() { this.privacyOpened = true }, getMediationStatus() { return {} }
  })
  Object.assign(Admob, { DEBUG_GEOGRAPHY_EEA: 1, DEBUG_GEOGRAPHY_REGULATED_US_STATE: 3, DEBUG_GEOGRAPHY_OTHER: 4 })
  for (const event of ['AD_LOADED', 'AD_FAILED_TO_LOAD', 'AD_FAILED_TO_SHOW', 'AD_CLOSED', 'AD_DESTROYED', 'AD_REWARDED']) Admob[event] = event
  for (const type of ['Banner', 'AdaptiveBanner', 'Interstitial', 'Rewarded', 'AppOpen']) {
    Admob[`create${type}`] = properties => {
      const ad = proxy({ ...properties, type }); ads.push(ad); return ad
    }
  }
  const UI = { SIZE: 'SIZE', FILL: 'FILL', UNIT_DIP: 'dp', convertUnits: value => Number(value) }
  for (const type of ['Window', 'View', 'Button', 'Label', 'ScrollView', 'TextField', 'OptionDialog']) {
    UI[`create${type}`] = properties => {
      const view = proxy({ ...properties, type }); views.push(view); return view
    }
  }
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../example/app.js'), 'utf8'), {
    require: () => Admob,
    Ti: { UI, App: { deployType, Properties: { getString: (key, fallback) => properties[key] ?? fallback, setString: (key, value) => { properties[key] = value } } }, API: { info() {}, warn() {}, debug() {} }, Platform: { osname, displayCaps: { platformWidth: 390 } } }
  })
  return {
    Admob, ads, views,
    scenario(name) {
      const run = views.find(view => view.type === 'Button' && view.title?.startsWith('Run test'))
      if (!run) return undefined
      const selector = views.find(view => view.type === 'Button' && view.title?.endsWith(' ▾'))
      if (selector.enabled) {
        selector.emit('click')
        views.filter(view => view.type === 'OptionDialog').at(-1).emit('click', { index: ['eea', 'us', 'other', 'normal'].indexOf(name) })
      }
      return run
    },
    button: title => views.find(view => view.type === 'Button' && view.title === title),
    ready() { Admob.allowed = true; Admob.emit('consent_complete', { success: true, canRequestAds: true, privacyOptionsRequired: false }); Admob.emit('tracking_authorization_completed', { status: 3 }); Admob.emit('module_initialized', { success: true }) }
  }
}

test('preloads after initialization, shows on one tap, and retries errors explicitly', () => {
  const app = openExample()
  const button = app.views.find(view => view.type === 'Button' && view.accessibilityHint?.startsWith('A full-screen break'))
  assert.equal(button.enabled, false)
  assert.equal(button.title, 'Waiting for initialization…')
  assert.equal(app.views.some(view => view.type === 'Label' && view.text === 'Waiting for initialization…'), false)
  button.emit('click')
  assert.equal(app.ads.length, 0)
  app.ready()
  app.ready()
  assert.equal(app.Admob.initializations.length, 1)
  assert.equal(Object.hasOwn(app.Admob.initializations[0], 'disableMediation'), false)
  assert.equal(Object.hasOwn(app.Admob.initializations[0], 'enableMediation'), false)
  assert.equal(button.title, 'Loading…')
  assert.deepEqual(app.ads.map(ad => ad.type), ['Interstitial', 'Rewarded', 'AppOpen', 'AdaptiveBanner'])
  button.emit('click')
  assert.equal(app.ads.length, 4)
  assert.equal(button.enabled, false)
  const ad = app.ads[0]
  assert.equal(ad.shows, undefined)
  ad.emit('AD_LOADED')
  assert.equal(button.title, 'Show interstitial')
  button.emit('click')
  button.emit('click')
  assert.equal(ad.shows, 1)
  ad.emit('AD_FAILED_TO_SHOW', { error: 'Test error', code: 1 })
  assert.equal(button.enabled, true)
  assert.equal(button.title, 'Retry interstitial')
  button.emit('click')
  assert.equal(ad.destroyed, true)
  assert.equal(app.ads.length, 5)
})

test('closing each fullscreen format automatically prepares its next ad without showing it', () => {
  for (const [index, title] of [[0, 'interstitial'], [1, 'rewarded'], [2, 'app open']]) {
    const app = openExample(); app.ready()
    const ad = app.ads[index]
    ad.emit('AD_LOADED')
    const button = app.button(`Show ${title}`)
    button.emit('click')
    ad.emit('AD_CLOSED')
    assert.equal(ad.destroyed, true)
    assert.equal(app.ads.length, 5)
    assert.equal(app.ads[4].loads, 1)
    assert.equal(app.ads[4].shows, undefined)
    assert.equal(button.enabled, false)
    app.ads[4].emit('AD_LOADED')
    assert.equal(button.title, `Show ${title}`)
    assert.equal(button.enabled, true)
  }
})

test('privacy blocks automatic requests and presentation of an already loaded ad', () => {
  const app = openExample()
  app.Admob.emit('module_initialized', { success: true })
  assert.equal(app.ads.length, 0)
  const ready = openExample(); ready.ready()
  ready.ads[0].emit('AD_LOADED')
  ready.Admob.allowed = false
  ready.button('Show interstitial').emit('click')
  assert.equal(ready.ads[0].shows, undefined)
})

test('adaptive banner starts automatically and can be replaced in the shared slot', () => {
  const app = openExample(); app.ready()
  const scroll = app.views.find(view => view.type === 'ScrollView')
  const initial = app.ads[3]
  initial.emit('AD_LOADED', { height: 64, heightUnit: 'dp' })
  assert.equal(scroll.bottom, '64dp')
  const fixed = app.button('Use fixed banner')
  fixed.emit('click')
  assert.equal(initial.destroyed, true)
  assert.equal(fixed.enabled, false)
  assert.equal(scroll.bottom, '50dp')
  app.ads[4].emit('AD_LOADED')
  const adaptive = app.button('Use adaptive banner')
  adaptive.emit('click')
  assert.equal(app.ads[4].destroyed, true)
  assert.equal(adaptive.enabled, false)
  assert.equal(scroll.bottom, '64dp')
  app.ads[5].emit('AD_LOADED', { height: 64, heightUnit: 'dp' })
  assert.equal(scroll.bottom, '64dp')
  app.button('Remove banner').emit('click')
  assert.equal(scroll.bottom, '0dp')
  assert.equal(app.ads[5].destroyed, true)
})

test('collapsible selection replaces the banner and detaches stale load callbacks', () => {
  const app = openExample(); app.ready()
  const scroll = app.views.find(view => view.type === 'ScrollView')
  const initial = app.ads[3]
  initial.emit('AD_LOADED', { height: 64, heightUnit: 'dp' })
  app.button('Use collapsible banner').emit('click')
  const collapsible = app.ads[4]
  assert.equal(initial.destroyed, true)
  assert.equal(collapsible.collapsible, 'bottom')
  initial.emit('AD_LOADED', { height: 999, heightUnit: 'dp' })
  assert.equal(scroll.bottom, '64dp')
  collapsible.emit('AD_LOADED', { height: 150, heightUnit: 'dp' })
  assert.equal(scroll.bottom, '150dp')
  assert.equal(app.button('Reload collapsible banner').enabled, true)
  app.button('Use adaptive banner').emit('click')
  assert.equal(collapsible.destroyed, true)
  assert.equal(app.ads[5].collapsible, undefined)
  collapsible.emit('AD_LOADED', { height: 999, heightUnit: 'dp' })
  assert.equal(scroll.bottom, '64dp')
})

test('iOS reserves the SDK height, waits for layout, loads once, and cancels a removed placement', () => {
  const app = openExample(); app.ready()
  const initial = app.ads[3]
  assert.equal(app.views.find(view => view.type === 'ScrollView').bottom, '64dp')
  assert.equal(initial.loads, undefined)
  initial.emit('postlayout')
  assert.equal(initial.loads, undefined)
  initial.rect = { width: 820, height: 150 }
  initial.emit('postlayout')
  initial.emit('postlayout')
  assert.equal(initial.loads, 1)
  app.button('Use collapsible banner').emit('click')
  const pending = app.ads[4]
  assert.equal(pending.loads, undefined)
  app.button('Remove banner').emit('click')
  pending.rect = { width: 820, height: 150 }
  pending.emit('postlayout')
  assert.equal(pending.loads, undefined)
  assert.equal(pending.destroyed, true)
})

test('Android keeps loading adaptive and collapsible banners immediately', () => {
  const app = openExample('android'); app.ready()
  assert.equal(app.ads[3].loads, 1)
  app.button('Use collapsible banner').emit('click')
  assert.equal(app.ads[4].loads, 1)
  assert.equal(app.ads[4].collapsible, 'bottom')
})

test('collapsible requests distinguish the returned ad type without claiming expansion', () => {
  for (const [isCollapsible, message] of [
    [true, 'Collapsible ad received. Its arrow controls collapse.'],
    [false, 'Google returned a standard banner. No collapse arrow.'],
    [undefined, 'Banner loaded. Collapse capability was not reported.']
  ]) {
    const app = openExample(); app.ready()
    app.button('Use collapsible banner').emit('click')
    app.ads[4].emit('AD_LOADED', { height: 150, heightUnit: 'dp', isCollapsible })
    assert.ok(app.views.some(view => view.type === 'Label' && view.text?.includes(message)))
    assert.equal(app.views.some(view => view.type === 'Label' && view.text === message), false)
    assert.equal(app.button('Reload collapsible banner').enabled, true)
  }
})

test('privacy options remain accessible even when consent blocks ad requests', () => {
  const app = openExample()
  app.Admob.emit('consent_complete', { success: true, canRequestAds: false, privacyOptionsRequired: true })
  const button = app.button('Advertising privacy options')
  assert.equal(button.visible, true)
  button.emit('click')
  assert.equal(app.Admob.privacyOpened, true)
})

test('layout adapts to the viewport and closing releases ads and module listeners', () => {
  const app = openExample(); app.ready()
  const scroll = app.views.find(view => view.type === 'ScrollView')
  const card = app.views.find(view => view.borderColor)
  for (const [width, expected] of [[390, '342dp'], [834, '385dp'], [1194, '448dp'], [320, '272dp']]) {
    scroll.size.width = width; scroll.emit('postlayout')
    assert.equal(card.width, expected)
  }
  const button = app.button('Loading…')
  app.views.find(view => view.type === 'Window').emit('close')
  assert.ok(app.ads.every(ad => ad.destroyed))
  app.ads[0].emit('AD_CLOSED')
  assert.equal(app.ads.length, 4)
  app.ads[0].emit('AD_LOADED')
  assert.equal(button.title, 'Loading…')
})


test('consent demo resets only on explicit selection, serializes requests, and replaces old ads', () => {
  const saved = {}
  const app = openExample('iphone', saved); app.ready()
  const oldAds = [...app.ads]
  const button = app.scenario('eea')
  button.emit('click')
  assert.equal(app.Admob.resets, 1)
  assert.equal(app.Admob.consentRequests.at(-1).geography, 1)
  assert.equal(saved['demo.consentMode'], 'eea')
  assert.ok(oldAds.every(ad => ad.destroyed))
  button.emit('click')
  app.views.find(view => view.type === 'Button' && view.accessibilityHint?.startsWith('A full-screen break')).emit('click')
  assert.equal(app.Admob.resets, 1)
  assert.equal(app.ads.length, 4)
  app.Admob.allowed = true
  app.Admob.emit('consent_complete', { success: true, canRequestAds: true, privacyOptionsRequired: true })
  assert.equal(app.ads.length, 8)
  assert.equal(app.button('Advertising privacy options').visible, true)
  const relaunched = openExample('iphone', saved)
  assert.equal(relaunched.Admob.consentRequests[0].geography, 1)
  assert.equal(relaunched.Admob.resets, undefined)
})

test('physical Android requires a hash and production ignores saved demo settings', () => {
  const app = openExample('android'); app.ready()
  app.scenario('eea').emit('click')
  assert.equal(app.Admob.resets, undefined)
  const field = app.views.find(view => view.type === 'TextField')
  field.value = 'not-a-hash'
  app.scenario('eea').emit('click')
  assert.equal(app.Admob.resets, undefined)
  field.value = '0123456789abcdef0123456789abcdef'
  app.scenario('eea').emit('click')
  assert.equal(app.Admob.consentRequests.at(-1).testDeviceIds[0], field.value)
  const production = openExample('iphone', { 'demo.consentMode': 'eea' }, 'production')
  assert.equal(production.scenario('eea'), undefined)
  assert.equal(Object.keys(production.Admob.consentRequests[0]).length, 0)
})

test('consent errors do not claim that no form is required or load ads', () => {
  const app = openExample()
  app.Admob.emit('consent_complete', { success: false, error: 'Offline', canRequestAds: false })
  assert.ok(app.views.some(view => view.text === 'Privacy update failed. See Session activity for details.'))
  assert.equal(app.ads.length, 0)
  assert.equal(app.scenario('eea').enabled, true)
})


test('demo can switch US/Other and restore normal without forcing geography', () => {
  const app = openExample(); app.ready()
  for (const [title, geography] of [['us', 3], ['other', 4], ['normal', undefined]]) {
    app.scenario(title).emit('click')
    assert.equal(app.Admob.consentRequests.at(-1).geography, geography)
    app.Admob.allowed = true
    app.Admob.emit('consent_complete', { success: true, canRequestAds: true, privacyOptionsRequired: false })
  }
  assert.equal(app.Admob.resets, 3)
})


test('privacy reopening stays visible for numeric iOS bridge booleans', () => {
  const app = openExample(); app.ready()
  app.Admob.emit('privacy_options_dismissed', { success: true, canRequestAds: true, privacyOptionsRequired: 1 })
  assert.equal(app.button('Advertising privacy options').visible, true)
  app.Admob.emit('privacy_options_dismissed', { success: true, canRequestAds: true, privacyOptionsRequired: 0 })
  assert.equal(app.button('Advertising privacy options').visible, false)
  assert.ok(app.views.some(view => view.text?.startsWith('No privacy form is required')))
})

test('US demo opens privacy options before reloading ads and preserves the banner slot', () => {
  const app = openExample(); app.ready()
  const host = app.views.find(view => view.children.includes(app.ads.find(ad => ad.type === 'AdaptiveBanner')))
  const previousHeight = host.height
  app.scenario('us').emit('click')
  assert.equal(host.height, previousHeight)
  app.Admob.allowed = true
  app.Admob.emit('consent_complete', { success: true, canRequestAds: true, privacyOptionsRequired: 1 })
  assert.equal(app.Admob.privacyOpened, true)
  assert.equal(app.ads.length, 4)
  assert.equal(app.scenario('us').enabled, false)
  app.Admob.emit('privacy_options_dismissed', { success: true, canRequestAds: true, privacyOptionsRequired: 1 })
  assert.equal(app.ads.length, 8)
  assert.equal(app.scenario('us').enabled, true)
  assert.ok(app.views.some(view => view.text?.includes('Privacy form closed.')))
})

test('compact consent selector changes only the preview until Run test is tapped', () => {
  const app = openExample(); app.ready()
  const requests = app.Admob.consentRequests.length
  const field = app.views.find(view => view.type === 'TextField')
  assert.ok(field)
  assert.equal(app.button('Test settings'), undefined)
  app.scenario('us')
  assert.equal(app.Admob.consentRequests.length, requests)
  assert.equal(app.Admob.resets, undefined)
  app.button('Run test').emit('click')
  assert.equal(app.Admob.consentRequests.at(-1).geography, 3)
})

test('scenario selector works during startup without starting a consent request', () => {
  const app = openExample('android')
  const requests = app.Admob.consentRequests.length
  const run = app.scenario('us')
  assert.equal(run.enabled, false)
  assert.match(run.title, /please wait/)
  assert.ok(app.views.some(view => view.title === 'US — privacy options ▾'))
  assert.equal(app.Admob.consentRequests.length, requests)
  app.ready()
  assert.equal(run.enabled, true)
  assert.equal(run.title, 'Run test')
})

test('privacy controls keep their reserved height across required, checking and not required', () => {
  const app = openExample(); app.ready()
  const privacy = app.button('Advertising privacy options')
  const slot = app.views.find(view => view.children.includes(privacy))
  const originalHeight = slot.height
  assert.notEqual(originalHeight, 'SIZE')
  app.Admob.emit('consent_complete', { success: true, canRequestAds: true, privacyOptionsRequired: true })
  assert.equal(slot.height, originalHeight)
  assert.equal(privacy.visible, true)
  app.scenario('other').emit('click')
  assert.equal(slot.height, originalHeight)
  assert.equal(privacy.visible, false)
  app.Admob.emit('consent_complete', { success: true, canRequestAds: true, privacyOptionsRequired: false })
  assert.equal(slot.height, originalHeight)
})


test('all banner cards keep waiting, loading, loaded and retry states in their buttons', () => {
  for (const platform of ['iphone', 'android']) {
    const app = openExample(platform)
    const cards = ['Fixed banner', 'Adaptive banner', 'Collapsible banner'].map(title =>
      app.views.find(view => view.children?.some(child => child.type === 'Label' && child.text === title)))
    const buttons = cards.map(card => card.children.find(child => child.type === 'Button'))
    for (const [index, card] of cards.entries()) {
      assert.equal(card.children.filter(child => child.type === 'Label').length, 2)
      assert.equal(buttons[index].title, 'Waiting for initialization…')
      assert.equal(buttons[index].enabled, false)
    }
    app.ready()
    assert.equal(buttons[1].title, 'Loading…')
    for (const [index, name] of [[0, 'fixed banner'], [1, 'adaptive banner'], [2, 'collapsible banner']]) {
      const button = buttons[index]
      button.emit('click')
      const ad = app.ads.at(-1)
      assert.equal(button.title, 'Loading…')
      assert.equal(button.enabled, false)
      button.emit('click')
      assert.equal(app.ads.at(-1), ad)
      ad.emit('AD_FAILED_TO_LOAD', { error: 'Offline', code: 2 })
      assert.equal(button.title, `Retry ${name}`)
      assert.equal(button.enabled, true)
      button.emit('click')
      const retry = app.ads.at(-1)
      retry.emit('AD_LOADED', { height: 64, heightUnit: 'dp', isCollapsible: false })
      assert.equal(button.title, `Reload ${name}`)
      assert.equal(button.enabled, true)
      assert.equal(button.backgroundColor, buttons[(index + 1) % 3].backgroundColor)
      button.emit('click')
      assert.notEqual(retry.destroyed, true)
      assert.equal(app.ads.at(-1), retry)
      assert.equal(button.title, 'Loading…')
      assert.equal(app.ads.at(-1).shows, undefined)
    }
    app.button('Remove banner').emit('click')
    assert.deepEqual(buttons.map(button => button.title), ['Use fixed banner', 'Use adaptive banner', 'Use collapsible banner'])
  }
})


test('banner reloads reuse the current view and never resize the scroll viewport', () => {
  for (const platform of ['iphone', 'android']) {
    const app = openExample(platform); app.ready()
    const scroll = app.views.find(view => view.type === 'ScrollView')
    let bottom = scroll.bottom
    const changes = []
    Object.defineProperty(scroll, 'bottom', { get: () => bottom, set: value => { changes.push(value); bottom = value } })
    for (const name of ['fixed banner', 'adaptive banner', 'collapsible banner']) {
      app.button(`Use ${name}`).emit('click')
      const ad = app.ads.at(-1)
      ad.rect = { width: 390, height: 64 }
      ad.emit('postlayout')
      ad.emit('AD_LOADED', { height: name === 'fixed banner' ? 50 : 64, heightUnit: 'dp' })
      const count = app.ads.length
      const loads = ad.loads
      changes.length = 0
      app.button(`Reload ${name}`).emit('click')
      assert.equal(app.ads.length, count)
      assert.notEqual(ad.destroyed, true)
      assert.equal(ad.loads, loads + 1)
      ad.emit('AD_LOADED', { height: name === 'fixed banner' ? 50 : 64, heightUnit: 'dp' })
      assert.deepEqual(changes, [])
    }
  }
})
