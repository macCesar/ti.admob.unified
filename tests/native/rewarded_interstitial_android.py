#!/usr/bin/env python3
"""Exercise the actual rewarded-interstitial Java proxy with controlled SDK callbacks.

This checks wrapper behavior, not Titanium bridging or network delivery.
"""
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = root / 'android/src/ti/admob/unified/TiAdmobUnifiedRewardedInterstitialAdProxy.java'
assert source.exists(), 'Rewarded interstitial proxy is not implemented'
java = re.sub(r'^(?:package|import) .*?;\s*', '', source.read_text(), flags=re.M)
java = re.sub(r'@Kroll\.\w+(?:\([^\n]*\))?\s*', '', java)
stubs = r'''
class KrollDict extends HashMap<String,Object> {
 String optString(String k,String d) {return containsKey(k)?(String)get(k):d;}
 boolean optBoolean(String k,boolean d) {return containsKey(k)?(Boolean)get(k):d;}
 String[] getStringArray(String k) {return (String[])get(k);}
 KrollDict getKrollDict(String k) {return (KrollDict)get(k);}
}
class KrollProxy {
 List<String> names=new ArrayList<>(); List<Map<String,Object>> events=new ArrayList<>();
 void fireEvent(String n,Map<String,Object> e) {names.add(n);events.add(e);}
 public void release() {}
 long count(String n) {return names.stream().filter(n::equals).count();}
}
class Activity {}
class TiApplication { static TiApplication instance=new TiApplication(); Activity activity=new Activity(); static TiApplication getInstance(){return instance;} Activity getCurrentActivity(){return activity;} }
class Log { static void d(String a,String b){} static void w(String a,String b){} static void e(String a,String b){} }
class AdMobAdapter {}
class Bundle extends HashMap<String,Object> { void putBoolean(String k,boolean v){put(k,v);} void putInt(String k,int v){put(k,v);} void putLong(String k,long v){put(k,v);} void putDouble(String k,double v){put(k,v);} void putString(String k,String v){put(k,v);} }
class AdRequest { List<String> keywords=new ArrayList<>(); String agent; Bundle extras;
 static class Builder { AdRequest r=new AdRequest(); Builder addKeyword(String k){r.keywords.add(k);return this;} Builder setRequestAgent(String s){r.agent=s;return this;} Builder addNetworkExtrasBundle(Class<?> c,Bundle b){r.extras=b;return this;} AdRequest build(){return r;} }
}
class AdError { int getCode(){return 2;} String getMessage(){return "network";} }
class LoadAdError extends AdError {}
class FullScreenContentCallback { public void onAdShowedFullScreenContent(){} public void onAdDismissedFullScreenContent(){} public void onAdFailedToShowFullScreenContent(AdError e){} public void onAdClicked(){} public void onAdImpression(){} }
class RewardItem { String getType(){return "bonus";} int getAmount(){return 7;} }
interface OnUserEarnedRewardListener { void onUserEarnedReward(RewardItem r); }
class RewardedInterstitialAdLoadCallback { public void onAdLoaded(RewardedInterstitialAd a){} public void onAdFailedToLoad(LoadAdError e){} }
class RewardedInterstitialAd {
 static int loads; static String unit; static AdRequest request; static RewardedInterstitialAdLoadCallback pending;
 FullScreenContentCallback callbacks; OnUserEarnedRewardListener reward;
 static void load(Activity a,String u,AdRequest r,RewardedInterstitialAdLoadCallback cb){loads++;unit=u;request=r;pending=cb;}
 void setFullScreenContentCallback(FullScreenContentCallback c){callbacks=c;}
 void show(Activity a,OnUserEarnedRewardListener l){reward=l;}
}
class TiAdmobUnifiedModule {
 static final String AD_LOADED="loaded",AD_FAILED_TO_LOAD="failed_to_load",AD_FAILED_TO_SHOW="failed_to_show",AD_DESTROYED="destroyed",AD_REWARDED="rewarded",AD_OPENED="opened",AD_SHOWED_FULLSCREEN_CONTENT="showed_fullscreen_content",AD_CLOSED="closed",AD_CLICKED="clicked",AD_IMPRESSION="impression",AD_TYPE_REWARDED_INTERSTITIAL="rewarded_interstitial";
 static final int ERROR_CODE_INVALID_REQUEST=1; static int loadErrorCode(LoadAdError e){return 2;}
}
class Main {
 static int checks;
 static void check(boolean c,String name){checks++;if(!c)throw new AssertionError(name);}
 static TiAdmobUnifiedRewardedInterstitialAdProxy proxy(boolean reload){KrollDict d=new KrollDict();d.put("adUnitId","original");d.put("autoReload",reload);return new TiAdmobUnifiedRewardedInterstitialAdProxy(d);}
 static RewardedInterstitialAd complete(){RewardedInterstitialAd a=new RewardedInterstitialAd();RewardedInterstitialAd.pending.onAdLoaded(a);return a;}
 public static void main(String[] args){
  TiAdmobUnifiedRewardedInterstitialAdProxy p=proxy(false);
  check(!p.isLoaded(),"initially not loaded"); p.show();check(p.count("failed_to_show")==1,"show before load fails");
  KrollDict extras=new KrollDict();extras.put("flag",true);extras.put("count",4);extras.put("label","x");
  p.setExtras(extras);p.setKeywords(new String[]{"games"});p.setRequestAgent("test-agent");
  p.load();p.load();check(RewardedInterstitialAd.loads==1,"one request in flight");
  check(RewardedInterstitialAd.request.keywords.equals(List.of("games")),"keywords forwarded");
  check("test-agent".equals(RewardedInterstitialAd.request.agent),"agent forwarded");
  check(RewardedInterstitialAd.request.extras.get("flag") instanceof Boolean && RewardedInterstitialAd.request.extras.get("count") instanceof Integer,"extra types preserved");
  p.setAdUnitId("replacement");RewardedInterstitialAd ad=complete();
  check(p.isLoaded(),"loaded Boolean");check(p.events.get(p.events.size()-1).get("adUnitId").equals("original"),"request identity snapshot");
  check(p.events.get(p.events.size()-1).get("adType").equals("rewarded_interstitial"),"portable adType");
  p.show();check(!p.isLoaded(),"show consumes readiness");p.show();check(p.count("failed_to_show")==2,"duplicate show fails");
  ad.callbacks.onAdShowedFullScreenContent();check(p.count("opened")==1 && p.count("showed_fullscreen_content")==1,"presentation events");
  ad.callbacks.onAdDismissedFullScreenContent();check(!p.isLoaded() && p.count("rewarded")==0,"closing grants no reward");
  ad.reward.onUserEarnedReward(new RewardItem());ad.reward.onUserEarnedReward(new RewardItem());
  check(p.count("rewarded")==1,"one reward even after dismissal");Map<String,Object> reward=p.events.get(p.events.size()-1);
  check(reward.get("rewardAmount").equals(7) && reward.get("rewardType").equals("bonus") && reward.get("adUnitId").equals("original"),"actual SDK reward and identity");
  p.destroy();p.destroy();check(p.count("destroyed")==1,"terminal destroy once");int count=p.events.size();ad.reward.onUserEarnedReward(new RewardItem());p.load();check(p.events.size()==count,"late reward and load ignored");
  p=proxy(false);p.load();RewardedInterstitialAdLoadCallback pending=RewardedInterstitialAd.pending;p.destroy();count=p.events.size();pending.onAdLoaded(new RewardedInterstitialAd());pending.onAdFailedToLoad(new LoadAdError());check(!p.isLoaded() && p.events.size()==count,"late load callbacks ignored");
  p=proxy(true);p.load();ad=complete();p.show();int loads=RewardedInterstitialAd.loads;ad.callbacks.onAdDismissedFullScreenContent();check(RewardedInterstitialAd.loads==loads+1,"autoReload only on close");
  ad=complete();p.show();loads=RewardedInterstitialAd.loads;ad.callbacks.onAdFailedToShowFullScreenContent(new AdError());check(!p.isLoaded() && RewardedInterstitialAd.loads==loads,"show failure clears without autoreload");
  p=proxy(false);p.load();RewardedInterstitialAd.pending.onAdFailedToLoad(new LoadAdError());check(p.count("failed_to_load")==1,"load error");loads=RewardedInterstitialAd.loads;p.load();check(RewardedInterstitialAd.loads==loads+1,"retry after failure");
  p=new TiAdmobUnifiedRewardedInterstitialAdProxy(null);p.load();check(p.count("failed_to_load")==1 && "".equals(p.getAdUnitId()),"null configuration gives an invalid-request event");
  p=proxy(false);p.setAdUnitId(null);p.load();check(p.count("failed_to_load")==1 && "".equals(p.getAdUnitId()),"null unit property is safely cleared");
  TiApplication.instance.activity=null;p=proxy(false);p.load();p.show();check(p.count("failed_to_load")==1 && p.count("failed_to_show")==1,"missing activity errors");
  System.out.println("PASS "+checks+" rewarded-interstitial Java behavior assertions");
 }
}
'''
with tempfile.TemporaryDirectory(prefix='admob-ri-java-') as directory:
    path = Path(directory)
    file = path / source.name
    file.write_text('import java.util.*;\n' + java + stubs)
    subprocess.run(['javac', '-d', str(path), str(file)], check=True)
    subprocess.run(['java', '-cp', str(path), 'Main'], check=True)
