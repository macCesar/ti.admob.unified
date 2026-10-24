const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')

const root = path.resolve(__dirname, '..')
const read = file => fs.readFileSync(path.join(root, file), 'utf8')

test('rewarded interstitial has matching factories and a registered native proxy', () => {
  const java = read('android/src/ti/admob/unified/TiAdmobUnifiedModule.java')
  const objc = read('ios/Classes/TiAdmobUnifiedModule.m')
  assert.match(java, /public TiAdmobUnifiedRewardedInterstitialAdProxy createRewardedInterstitial\(KrollDict config\)/)
  assert.match(objc, /- \(id\)createRewardedInterstitial:\(id\)args/)
  const project = read('ios/ti.admob.unified.xcodeproj/project.pbxproj')
  assert.match(project, /TiAdmobUnifiedRewardedInterstitialAdProxy\.m in Sources/)
  assert.match(project, /TiAdmobUnifiedRewardedInterstitialAdProxy\.h in Headers/)
  const android = read('android/src/ti/admob/unified/TiAdmobUnifiedRewardedInterstitialAdProxy.java')
  const ios = read('ios/Classes/TiAdmobUnifiedRewardedInterstitialAdProxy.m')
  const header = read('ios/Classes/TiAdmobUnifiedRewardedInterstitialAdProxy.h')
  for (const method of ['load', 'show', 'isLoaded', 'destroy']) {
    assert.match(android, new RegExp(`public (?:void|boolean) ${method}\\(`))
    assert.match(header, new RegExp(`${method}:\\(id\\)args`))
  }
  for (const property of ['adUnitId', 'autoReload', 'keywords', 'extras', 'requestAgent']) {
    assert.match(header, new RegExp(`\\b${property};`))
  }
  assert.match(android, /AD_TYPE_REWARDED_INTERSTITIAL/)
  assert.match(ios, /@"adType": @"rewarded_interstitial"/)
  assert.match(ios, /accessInstanceVariablesDirectly/)
  assert.doesNotMatch(header, /@property[^;]*(?:isLoading|isShowing|isDestroyed|rewardedAd)/)
})
