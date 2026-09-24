const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const vm = require('node:vm')
const path = require('node:path')
const { EventEmitter } = require('node:events')

function fixture(success = true, osname = 'android') {
  function emitter() {
    const object = new EventEmitter()
    object.addEventListener = object.on.bind(object)
    object.removeEventListener = object.off.bind(object)
    return object
  }
  const native = emitter()
  const created = []
  Object.assign(native, {
    AD_LOADED: 'loaded', AD_FAILED_TO_LOAD: 'failed', AD_DESTROYED: 'destroyed',
    canRequestAds: () => true,
    ADAPTIVE_ANCHORED: 'anchored',
    getAnchoredAdaptiveBannerSize: () => ({ height: 90 }),
    initialize: () => native.emit('module_initialized', { success }),
    requestConsent: () => native.emit('consent_complete', { success: true }),
    presentPrivacyOptions() { this.privacyCalls = (this.privacyCalls || 0) + 1 },
    openAdInspector() { this.inspectorCalls = (this.inspectorCalls || 0) + 1 }
  })
  native.createBanner = native.createAdaptiveBanner = native.createInterstitial = () => {
    const proxy = emitter()
    Object.assign(proxy, {
      rect: { width: 0, height: 0 },
      load() { this.loads = (this.loads || 0) + 1 },
      destroy() { this.destroyed = true; this.emit('destroyed', {}) },
      pause() {}, resume() {}, isLoaded() { return !this.destroyed }
    })
    created.push(proxy)
    return proxy
  }
  const module = { exports: {} }
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../example/lib/ads.js'), 'utf8'), {
    module, require: () => native,
    Ti: { Platform: { osname }, API: { error() {}, warn() {}, debug() {} }, UI: { FILL: 'FILL' } }
  })
  return { ads: module.exports, native, created, host: { height: 0, add() {}, remove() {} } }
}

test('banner retry inside failure callback keeps the replacement alive and its space reserved', async () => {
  const f = fixture(); await f.ads.start()
  let placement
  placement = f.ads.createBanner({ host: f.host, adUnitId: 'test', reservedHeight: 50,
    onFailedToLoad() { placement.retry() } })
  f.created[0].emit('failed', {})
  assert.equal(f.created[0].destroyed, true)
  assert.equal(f.created.length, 2)
  assert.notEqual(f.created[1].destroyed, true)
  assert.equal(f.created[1].listenerCount('loaded'), 1)
  assert.equal(f.host.height, '50dp')
})

test('destroyed callbacks may rebuild a placement without destroying the new proxy', async () => {
  for (const format of ['createBanner', 'createInterstitial']) {
    const f = fixture(); await f.ads.start()
    let placement
    placement = f.ads[format]({ host: f.host, adUnitId: 'test', reservedHeight: 50, autoLoad: true,
      onDestroyed() { placement.retry() } })
    f.created[0].emit('destroyed', {})
    assert.equal(f.created.length, 2)
    assert.equal(f.created[1].listenerCount('loaded'), 1)
    assert.notEqual(f.created[1].destroyed, true)
    if (format === 'createBanner') assert.equal(f.host.height, '50dp')
  }
})

test('privacy and inspector calls share one operation and remove their terminal listeners', async () => {
  for (const [method, calls, event] of [
    ['showPrivacyOptions', 'privacyCalls', 'privacy_options_dismissed'],
    ['openAdInspector', 'inspectorCalls', 'ad_inspector_closed']
  ]) {
    const f = fixture(); await f.ads.start()
    const first = f.ads[method](); const second = f.ads[method]()
    assert.equal(f.native[calls], 1)
    assert.equal(first, second)
    f.native.emit(event, { success: true })
    assert.equal(await first, await second)
    assert.equal(f.native.listenerCount(event), 0)
    const third = f.ads[method]()
    assert.equal(f.native[calls], 2)
    f.native.emit(event, { success: false })
    assert.equal((await third).success, false)
    assert.equal(f.native.listenerCount(event), 0)
  }
})

test('synchronous presentation exceptions settle and permit a later retry without listeners', async () => {
  const f = fixture()
  f.native.openAdInspector = () => { throw new Error('No controller') }
  for (let i = 0; i < 2; i++) {
    assert.equal((await f.ads.openAdInspector()).success, false)
    assert.equal(f.native.listenerCount('ad_inspector_closed'), 0)
  }
})

test('legacy numeric false from initialization does not make the library ready', async () => {
  const f = fixture(0)
  const result = await f.ads.start()
  assert.equal(result.initialized, false)
  assert.equal(f.ads.isReady(), false)
})


test('iOS adaptive placements reserve native height and cancel pending layout on destroy', async () => {
  const f = fixture(true, 'iphone'); await f.ads.start()
  f.host.rect = { width: 390, height: 0 }
  const placement = f.ads.createAdaptiveBanner({ host: f.host, adUnitId: 'test', reservedHeight: 50 })
  const ad = f.created[0]
  assert.equal(f.host.height, '90dp')
  assert.equal(ad.loads, undefined)
  ad.emit('postlayout')
  assert.equal(ad.loads, undefined)
  ad.rect = { width: 390, height: 90 }
  ad.emit('postlayout')
  ad.emit('postlayout')
  assert.equal(ad.loads, 1)
  placement.rebuild()
  const pending = f.created[1]
  placement.destroy()
  pending.rect = { width: 390, height: 90 }
  pending.emit('postlayout')
  assert.equal(pending.loads, undefined)
  assert.equal(pending.listenerCount('postlayout'), 0)
})
