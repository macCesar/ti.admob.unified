const test = require('node:test')
const assert = require('node:assert/strict')
const vm = require('node:vm')
const fs = require('node:fs')
const path = require('node:path')

// Execute the actual sample with bridge doubles. This checks interaction and
// lifecycle contracts; native rendering is verified separately in a simulator.
function openExample() {
  const views = []
  const ads = []
  function proxy(properties = {}) {
    const listeners = {}
    return Object.assign({
      children: [], size: { width: 390 },
      add(child) { this.children.push(child) },
      remove(child) { this.children = this.children.filter(item => item !== child) },
      applyProperties(values) { Object.assign(this, values) },
      addEventListener(name, fn) { (listeners[name] ||= new Set()).add(fn) },
      removeEventListener(name, fn) { listeners[name]?.delete(fn) },
      emit(name, event = {}) { listeners[name]?.forEach(fn => fn(event)) },
      open() {}, load() { this.loads = (this.loads || 0) + 1 },
      show() { this.shows = (this.shows || 0) + 1 },
      destroy() { this.destroyed = true }, pause() {}, resume() {}
    }, properties)
  }
  const Admob = proxy({
    allowed: false, canRequestAds() { return this.allowed },
    initialize() {}, requestConsent() {}, requestTrackingAuthorization() {},
    presentPrivacyOptions() { this.privacyOpened = true }, getMediationStatus() { return {} }
  })
  for (const event of ['AD_LOADED', 'AD_FAILED_TO_LOAD', 'AD_FAILED_TO_SHOW', 'AD_CLOSED', 'AD_DESTROYED', 'AD_REWARDED']) Admob[event] = event
  for (const type of ['Banner', 'AdaptiveBanner', 'Interstitial', 'Rewarded', 'AppOpen']) {
    Admob[`create${type}`] = properties => {
      const ad = proxy({ ...properties, type }); ads.push(ad); return ad
    }
  }
  const UI = { SIZE: 'SIZE', FILL: 'FILL', UNIT_DIP: 'dp', convertUnits: value => Number(value) }
  for (const type of ['Window', 'View', 'Button', 'Label', 'ScrollView']) {
    UI[`create${type}`] = properties => {
      const view = proxy({ ...properties, type }); views.push(view); return view
    }
  }
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../example/app.js'), 'utf8'), {
    require: () => Admob,
    Ti: { UI, API: { info() {}, warn() {}, debug() {} }, Platform: { osname: 'iphone', displayCaps: { platformWidth: 390 } } }
  })
  return {
    Admob, ads, views,
    button: title => views.find(view => view.type === 'Button' && view.title === title),
    ready() { Admob.allowed = true; Admob.emit('module_initialized', { success: true }) }
  }
}

test('preloads after initialization, shows on one tap, and retries errors explicitly', () => {
  const app = openExample()
  const button = app.button('Show interstitial')
  assert.equal(button.enabled, false)
  button.emit('click')
  assert.equal(app.ads.length, 0)
  app.ready()
  app.ready()
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
  assert.equal(scroll.bottom, '0dp')
  app.ads[5].emit('AD_LOADED', { height: 64, heightUnit: 'dp' })
  assert.equal(scroll.bottom, '64dp')
  app.button('Remove banner').emit('click')
  assert.equal(scroll.bottom, '0dp')
  assert.equal(app.ads[5].destroyed, true)
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
