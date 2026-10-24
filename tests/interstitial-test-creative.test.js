const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const vm = require('node:vm')
const test = require('node:test')

const source = fs.readFileSync(path.join(__dirname, '../ios/Classes/TiAdmobUnifiedInterstitialAdProxy.m'), 'utf8')

function repair(options = {}) {
  const match = source.match(/static NSString \*TiAdmobUnifiedTestCreativeScript\(void\)\s*\{([\s\S]*?)\n\}/)
  assert.ok(match, 'native test-creative repair must be present')
  const script = [...match[1].matchAll(/@("(?:[^"\\]|\\.)*")/g)].map(m => JSON.parse(m[1])).join('')
  const parent = { style: { aspectRatio: '' } }
  const svg = {
    parentElement: options.parent === false ? null : parent,
    viewBox: { baseVal: { width: options.boxWidth ?? 1024, height: options.boxHeight ?? 768 } },
    getBoundingClientRect: () => ({ width: options.width ?? 0, height: options.height ?? 804 })
  }
  const changed = vm.runInNewContext(script, {
    location: { hostname: options.host ?? 'googleads.g.doubleclick.net' },
    document: { querySelectorAll: () => [svg] },
    getComputedStyle: element => element === parent ? { display: options.display ?? 'flex', flexDirection: options.direction ?? 'column', opacity: options.parentOpacity ?? '1', visibility: options.parentVisibility ?? 'visible' } : ({ visibility: options.visibility ?? 'visible', opacity: options.opacity ?? '1', backgroundImage: options.background ?? 'url("https://tpc.googlesyndication.com/simgad/15041366023668330227")' })
  })
  return { changed, ratio: parent.style.aspectRatio }
}

test('repairs the collapsed Google SVG using its intrinsic proportions', () => {
  assert.deepEqual(repair(), { changed: true, ratio: '1024 / 768' })
  assert.deepEqual(repair({ boxWidth: 320, boxHeight: 480, background: 'url("https://tpc.googlesyndication.com/simgad/another-creative")' }), { changed: true, ratio: '320 / 480' })
})

test('leaves visible images, unrelated content and invalid geometry untouched', () => {
  for (const options of [
    { width: 536 }, { height: 0 }, { boxWidth: 0 }, { parent: false },
    { display: 'block' }, { direction: 'row' }, { width: -1 },
    { visibility: 'hidden' }, { visibility: 'collapse' }, { opacity: '0' },
    { parentOpacity: '0' }, { parentVisibility: 'hidden' },
    { background: 'url("https://example.com/image.png")' },
    { host: 'example.com' }, { host: 'doubleclick.net.example.com' }
  ]) assert.deepEqual(repair(options), { changed: false, ratio: '' })
})
