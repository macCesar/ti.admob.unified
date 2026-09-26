#!/usr/bin/env python3
"""Execute current Java wrapper method bodies with deterministic SDK stand-ins."""
from pathlib import Path
import subprocess, tempfile
root = Path(__file__).resolve().parents[2]
src = (root/'android/src/ti/admob/unified/TiAdmobUnifiedModule.java').read_text()
def method(signature):
    start = src.index(signature); opening = src.index('{',start); end = opening+1; depth=1
    while depth:
        depth += (src[end]=='{')-(src[end]=='}'); end+=1
    return src[start:end]
code = '''import java.util.*;
public class Harness {
 enum OperationState { NOT_STARTED, IN_FLIGHT, COMPLETE, FAILED }
 OperationState initializationState=OperationState.NOT_STARTED, consentState=OperationState.NOT_STARTED;
 Float pendingAppVolume;
 boolean consentResetPending, privacyInFlight;
 KrollDict queuedConsent;
 Map<String,Object> consentResult;
 Object consentLock=new Object(), initializationLock=new Object();
 List<Map<String,Object>> events=new ArrayList<>();
 int requests;
 static String LCAT="test";
 static class KrollDict extends HashMap<String,Object> {}
 static class Log { static void d(String a,String b) {} static void e(String a,String b) {} static void w(String a,String b) {} }
 static class AdapterStatus {
 enum State { READY, NOT_READY }
 State state; AdapterStatus(State value) {state=value;}
 State getInitializationState() {return state;} String getDescription() {return "SDK detail";} int getLatency() {return 125;}
 }
 static class InitializationStatus { Map<String,AdapterStatus> adapters=new HashMap<>(); Map<String,AdapterStatus> getAdapterStatusMap() {return adapters;} }
 static class MobileAds { static InitializationStatus status; static int reads; static InitializationStatus getInitializationStatus() {reads++;return status;} static float volume=1; static void setAppVolume(float v) { volume=v; } }
 static class Activity {
   String selected;
   String getPackageName() {return "audit.app";}
   SharedPreferences getSharedPreferences(String name,int mode) {selected=name;return new SharedPreferences();}
 }
 static class SharedPreferences { int getInt(String name,int def) {return name.equals("IABTCF_gdprApplies")?1:def;} }
 static class TiApplication {
   static TiApplication instance=new TiApplication(); Activity activity=new Activity();
   static TiApplication getInstance() {return instance;}
   Activity getCurrentActivity() {return activity;}
 }
 static class ConsentInformation {
   static class PrivacyOptionsRequirementStatus {static final int REQUIRED=1;}
   boolean allowed=true; int resets;
   boolean canRequestAds() {return allowed;} int getPrivacyOptionsRequirementStatus() {return 1;}
   void reset() {resets++;allowed=false;}
 }
 static class UserMessagingPlatform {static ConsentInformation state=new ConsentInformation();static ConsentInformation getConsentInformation(Activity a) {return state;} }
 void requestConsent(KrollDict config) {requests++;consentState=OperationState.IN_FLIGHT;}
 void fireEvent(String name,Map<String,Object> event) {events.add(event);}
'''
for sig in ['public KrollDict getMediationStatus(', 'public void setAppVolume(', 'public boolean isGDPR(', 'private void completeConsent(', 'private boolean finishPendingConsentReset(', 'public void resetConsent(']: code+=method(sig)+'\n'
code+='''
 static int checks;
 static void check(boolean value,String name) {checks++;if(!value)throw new AssertionError(name);}
 public static void main(String[] args) {
  Harness h=new Harness();
  check(h.getMediationStatus().get("initializationState").equals("not_started"),"diagnostic pre-init");
  check(((Object[])h.getMediationStatus().get("adapters")).length==0 && MobileAds.reads==0,"no SDK access before init");
  h.initializationState=OperationState.IN_FLIGHT;
  check(h.getMediationStatus().get("initializationState").equals("initializing"),"in flight null SDK status");
  MobileAds.status=new InitializationStatus();
  check(((Object[])h.getMediationStatus().get("adapters")).length==0,"empty map");
  MobileAds.status.adapters.put("z.UnknownAdapter",new AdapterStatus(AdapterStatus.State.NOT_READY));
  MobileAds.status.adapters.put("a.GoogleAdapter",new AdapterStatus(AdapterStatus.State.READY));
  h.initializationState=OperationState.COMPLETE;
  KrollDict diagnostic=h.getMediationStatus(); Object[] adapters=(Object[])diagnostic.get("adapters");
  check(diagnostic.get("initializationState").equals("completed"),"completed despite not ready adapter");
  Map first=(Map)adapters[0], second=(Map)adapters[1];
  check(first.get("adapterClass").equals("a.GoogleAdapter") && second.get("adapterClass").equals("z.UnknownAdapter"),"all adapters sorted");
  check(first.get("state").equals("ready") && second.get("state").equals("not_ready"),"states normalized");
  check(first.get("latencyMs").equals(125) && first.get("description").equals("SDK detail"),"latency and description");
  h.initializationState=OperationState.FAILED; check(h.getMediationStatus().get("initializationState").equals("failed"),"failure");
  h.initializationState=OperationState.NOT_STARTED;
  h.setAppVolume("50%");
  check(h.pendingAppVolume==.5f && MobileAds.volume==1,"pre-init stores without calling SDK");
  h.initializationState=OperationState.COMPLETE;
  for(String value:new String[]{"0","25%"," 50 % ","100"}) {h.setAppVolume(value);check(MobileAds.volume==Float.parseFloat(value.replace("%","").trim())/100,"volume applies");}
  for(String value:new String[]{null,"","NaN","Infinity","-1","101","50oops"}) {h.setAppVolume(value);check(MobileAds.volume==1,"invalid ignored");}
  check(h.isGDPR(),"TCF read");
  check(TiApplication.instance.activity.selected.equals("audit.app_preferences"),"uses default preferences");
  Activity activity=TiApplication.instance.activity;
  h.consentState=OperationState.IN_FLIGHT; h.completeConsent(activity,"offline",2);
  check(h.consentState==OperationState.NOT_STARTED,"failure permits retry");
  h.completeConsent(activity,null,0);check(h.consentState==OperationState.COMPLETE,"success cached");
  h.consentState=OperationState.IN_FLIGHT;h.resetConsent();
  check(h.consentResetPending && UserMessagingPlatform.state.resets==0,"wait before reset");
  h.queuedConsent=new KrollDict();h.completeConsent(activity,null,0);
  check(UserMessagingPlatform.state.resets==1 && h.requests==1 && h.consentState==OperationState.IN_FLIGHT,"reset then retry");
  check(!h.consentResetPending && h.queuedConsent==null,"reset consumed");
  h.resetConsent();h.completeConsent(activity,null,0);
  check(h.consentState==OperationState.NOT_STARTED && Boolean.FALSE.equals(h.events.get(h.events.size()-1).get("success")),"reset cancellation");
  h.privacyInFlight=true;h.resetConsent();
  check(h.consentResetPending && UserMessagingPlatform.state.resets==2,"privacy reset waits");
  h.privacyInFlight=false;h.finishPendingConsentReset(activity);
  check(UserMessagingPlatform.state.resets==3,"privacy reset completes");
  System.out.println("PASS "+checks+" Java wrapper behavior assertions");
 }
}
'''
with tempfile.TemporaryDirectory(prefix='admob-java-tests-') as directory:
 p=Path(directory);(p/'Harness.java').write_text(code)
 subprocess.run(['javac',str(p/'Harness.java')],check=True)
 subprocess.run(['java','-cp',str(p),'Harness'],check=True)
