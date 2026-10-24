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
  const app = emitter()
  const native = emitter()
  const created = []
  Object.assign(native, {
    AD_CLOSED: 'closed', AD_LOADED: 'loaded', AD_FAILED_TO_LOAD: 'failed', AD_DESTROYED: 'destroyed', AD_REWARDED: 'rewarded',
    canRequestAds: () => true,
    ADAPTIVE_ANCHORED: 'anchored',
    getAnchoredAdaptiveBannerSize: () => ({ height: 90 }),
    initialize: () => native.emit('module_initialized', { success }),
    requestConsent: () => native.emit('consent_complete', { success: true }),
    presentPrivacyOptions() { this.privacyCalls = (this.privacyCalls || 0) + 1 },
    openAdInspector() { this.inspectorCalls = (this.inspectorCalls || 0) + 1 }
  })
  native.createBanner = native.createAdaptiveBanner = native.createInterstitial = native.createRewarded = native.createRewardedInterstitial = native.createAppOpen = () => {
    const proxy = emitter()
    Object.assign(proxy, {
      rect: { width: 0, height: 0 },
      load() { this.loads = (this.loads || 0) + 1 },
      destroy() { this.destroyed = true; this.emit('destroyed', {}) },
      show() { this.shows = (this.shows || 0) + 1 },
      pause() {}, resume() {}, isLoaded() { return !this.destroyed }
    })
    created.push(proxy)
    return proxy
  }
  const module = { exports: {} }
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../example/lib/ads.js'), 'utf8'), {
    module, require: () => native,
    Ti: { App: app, Platform: { osname }, API: { error() {}, warn() {}, debug() {} }, UI: { FILL: 'FILL' } }
  })
  return { ads: module.exports, app, native, created, host: { height: 0, add() {}, remove() {} } }
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


test('fullscreen managers reload on Show only and retain the request size through in-flight rotation', async () => {
  for (const format of ['createInterstitial', 'createRewarded', 'createRewardedInterstitial', 'createAppOpen']) {
    const f = fixture(); await f.ads.start()
    const window = { size: { width: 810, height: 1080 } }
    const manager = f.ads[format]({ window, adUnitId: 'test', autoLoad: true })
    const original = f.created[0]
    window.size = { width: 1080, height: 810 }
    assert.equal(f.created.length, 1)
    assert.equal(manager.load(), false, 'duplicate in-flight load must not overwrite request dimensions')
    assert.equal(manager.show(), false)
    original.emit('loaded')
    assert.equal(manager.show(), false)
    assert.equal(original.destroyed, true)
    assert.equal(original.shows, undefined)
    assert.equal(f.created.length, 2)
    assert.equal(manager.show(), false)
    assert.equal(f.created.length, 2)
    const replacement = f.created[1]
    replacement.emit('loaded')
    assert.equal(manager.show(), true)
    assert.equal(replacement.shows, 1)
    manager.destroy()
    assert.equal(manager.show(), false)
    assert.equal(f.created.length, 2)
  }
})

test('native autoReload updates fullscreen request dimensions after dismissal', async () => {
  const f = fixture(); await f.ads.start()
  const window = { size: { width: 810, height: 1080 } }
  const manager = f.ads.createInterstitial({ window, adUnitId: 'test', autoLoad: true, autoReload: true })
  const ad = f.created[0]
  ad.emit('loaded')
  assert.equal(manager.show(), true)
  window.size = { width: 1080, height: 810 }
  ad.emit('closed')
  ad.emit('loaded')
  assert.equal(manager.show(), true)
  assert.equal(f.created.length, 1)
})

test('rewarded interstitial waits for startup, never shows on load, and forwards only earned rewards', async () => {
  const f = fixture()
  const rewards = []
  assert.equal(typeof f.ads.createRewardedInterstitial, 'function')
  const manager = f.ads.createRewardedInterstitial({ adUnitId: 'test', autoLoad: true,
    onRewarded: event => rewards.push(event) })
  assert.equal(f.created.length, 0)
  await f.ads.start()
  assert.equal(f.created.length, 1)
  const ad = f.created[0]
  ad.emit('loaded')
  assert.equal(ad.shows, undefined)
  assert.equal(rewards.length, 0)
  assert.equal(manager.show(), true)
  ad.emit('rewarded', { rewardType: 'bonus', rewardAmount: 7 })
  assert.deepEqual(rewards, [{ rewardType: 'bonus', rewardAmount: 7 }])
  ad.emit('closed')
  assert.equal(rewards.length, 1)
  manager.destroy()
  ad.emit('rewarded', { rewardType: 'bonus', rewardAmount: 7 })
  assert.equal(rewards.length, 1)
})


for (const status of [0, 1, 2, 3]) {
  test(`ATT startup waits for status ${status} before eligibility, initialization and loading`, async () => {
    const f = fixture(true, 'iphone')
    const order = []
    f.native.requestConsent = () => order.push('ump')
    f.native.requestTrackingAuthorization = () => order.push('att')
    f.native.canRequestAds = () => { order.push('eligibility'); return true }
    f.native.initialize = () => { order.push('initialize'); f.native.emit('module_initialized', { success: true }) }
    f.ads.createInterstitial({ adUnitId: 'test', autoLoad: true })
    const pending = f.ads.start({ requestTrackingAuthorization: true })
    assert.deepEqual(order, ['ump'])
    assert.equal(f.created.length, 0)
    f.native.emit('consent_complete', { success: true })
    await Promise.resolve()
    assert.deepEqual(order, ['ump', 'att'])
    assert.equal(f.created.length, 0)
    f.native.emit('tracking_authorization_completed', { status, authorized: status === 3, applicable: true })
    const result = await pending
    assert.equal(result.tracking.status, status)
    assert.equal(result.initialized, true, 'ATT denial does not replace the UMP eligibility gate')
    assert.deepEqual(order, ['ump', 'att', 'eligibility', 'initialize'])
    assert.equal(f.created[0].loads, 1)
    assert.equal(f.native.listenerCount('tracking_authorization_completed'), 0)
  })
}

test('ATT disabled skips its request and UMP ineligibility prevents initialization and loads', async () => {
  for (const allowed of [false, true]) {
    const f = fixture()
    f.native.requestTrackingAuthorization = () => assert.fail('ATT must be explicit')
    f.native.canRequestAds = () => allowed
    f.ads.createInterstitial({ adUnitId: 'test', autoLoad: true })
    const result = await f.ads.start()
    assert.equal(result.tracking, null)
    assert.equal(result.initialized, allowed)
    assert.equal(f.created.length, allowed ? 1 : 0)
  }
})


test('ATT startup defers the prompt when UMP finishes while iOS is inactive', async () => {
  const f = fixture(true, 'iphone')
  f.native.requestConsent = () => {}
  let requests = 0
  f.native.requestTrackingAuthorization = () => {
    requests++
    f.native.emit('tracking_authorization_completed', { status: 2, authorized: false, applicable: true })
  }
  const pending = f.ads.start({ requestTrackingAuthorization: true })
  f.app.emit('pause')
  f.native.emit('consent_complete', { success: true })
  await Promise.resolve()
  assert.equal(requests, 0)
  assert.equal(f.ads.isReady(), false)
  f.app.emit('resumed')
  const result = await pending
  assert.equal(requests, 1)
  assert.equal(result.initialized, true)
  assert.equal(f.app.listenerCount('pause'), 0)
  assert.equal(f.app.listenerCount('resumed'), 0)
  f.app.emit('resumed')
  assert.equal(requests, 1)
})

test('fullscreen managers preserve preloads across client-area changes but reload for outer-window changes', async () => {
  for (const format of ['createInterstitial', 'createRewarded', 'createRewardedInterstitial', 'createAppOpen']) {
    const f = fixture(); await f.ads.start()
    const window = { rect: { width: 360, height: 802 }, size: { width: 360, height: 705 } }
    const manager = f.ads[format]({ window, adUnitId: 'test', autoLoad: true })
    const ad = f.created[0]; ad.emit('loaded')
    window.size = { width: 360, height: 689 }
    assert.equal(manager.show(), true, format)
    assert.equal(f.created.length, 1)
    assert.notEqual(ad.destroyed, true)
    manager.load(); ad.emit('loaded')
    window.rect = { width: 802, height: 360 }
    assert.equal(manager.show(), false, 'a real outer-window change still invalidates the ad')
    assert.equal(ad.destroyed, true)
    assert.equal(f.created.length, 2)
  }
})
