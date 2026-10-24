#!/usr/bin/env python3
"""Exercise actual Android initialization bodies with a blocked SDK worker."""
from pathlib import Path
import subprocess
import tempfile

source = (Path(__file__).resolve().parents[2] / 'android/src/ti/admob/unified/TiAdmobUnifiedModule.java').read_text()
def method(signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end].replace('com.google.android.gms.ads.initialization.AdapterStatus', 'AdapterStatus')

code = r'''
import java.util.*;
import java.util.concurrent.*;
public class Harness {
 enum OperationState { NOT_STARTED, IN_FLIGHT, COMPLETE, FAILED }
 final Object initializationLock = new Object();
 OperationState initializationState = OperationState.NOT_STARTED;
 Map<String,Object> initializationResult;
 Float pendingAppVolume;
 static String LCAT = "test";
 List<Map<String,Object>> events = new CopyOnWriteArrayList<>();
 static class KrollDict extends HashMap<String,Object> {
  String getString(String key) { return (String)get(key); }
  String[] getStringArray(String key) { return (String[])get(key); }
  boolean optBoolean(String key, boolean fallback) { return containsKey(key) ? (Boolean)get(key) : fallback; }
 }
 static Queue<Runnable> uiTasks = new ConcurrentLinkedQueue<>();
 static class Activity { void runOnUiThread(Runnable task) { if (Thread.currentThread() == MobileAds.ui) task.run(); else uiTasks.add(task); } }
 static class TiApplication {
  static TiApplication instance = new TiApplication(); Activity activity = new Activity();
  static TiApplication getInstance() { return instance; }
  Activity getCurrentActivity() { return activity; }
 }
 static class Log { static void d(String a,String b) {} static void e(String a,String b) {} }
 static class AdapterStatus { String getDescription() { return "ready"; } }
 static class InitializationStatus { Map<String,AdapterStatus> getAdapterStatusMap() { return Collections.emptyMap(); } }
 interface OnInitializationCompleteListener { void onInitializationComplete(InitializationStatus s); }
 static class RequestConfiguration {
  Builder toBuilder() { return new Builder(); }
  static class Builder {
   Builder setTestDeviceIds(List<String> ids) { return this; }
   Builder setMaxAdContentRating(String value) { MobileAds.rating = value; return this; }
   RequestConfiguration build() { return new RequestConfiguration(); }
  }
 }
 static class MobileAds {
  static Thread ui = Thread.currentThread();
  static CountDownLatch entered = new CountDownLatch(1), release = new CountDownLatch(1);
  static volatile OnInitializationCompleteListener listener;
  static volatile int calls, disabled;
  static volatile boolean fail;
  static String rating; static float volume;
  static RequestConfiguration getRequestConfiguration() {
   if (Thread.currentThread() == ui) throw new AssertionError("SDK configuration ran on UI thread");
   entered.countDown();
   try { if (!release.await(4, TimeUnit.SECONDS)) throw new AssertionError("UI did not release SDK worker"); }
   catch (InterruptedException e) { throw new RuntimeException(e); }
   return new RequestConfiguration();
  }
  static void setRequestConfiguration(RequestConfiguration config) {}
  static void disableMediationAdapterInitialization(Activity a) { disabled++; }
  static void setAppVolume(float v) { volume = v; }
  static void initialize(Activity a, OnInitializationCompleteListener callback) {
   calls++;
   if (fail) throw new IllegalStateException("SDK unavailable");
   listener = callback;
  }
 }
 void setAgeRestrictedTreatment(RequestConfiguration.Builder b, KrollDict config) {}
 void fireEvent(String name, Map<String,Object> event) { if (Thread.currentThread() != MobileAds.ui) throw new AssertionError("event off UI thread"); events.add(event); }
'''
code += method('public void initialize(')
for signature in ['private void initializeSdk(', 'private void failInitialization(']:
    if signature in source:
        code += method(signature)
code += r'''
 static int checks;
 static void check(boolean value, String message) { checks++; if (!value) throw new AssertionError(message); }
 interface Condition { boolean ready(); }
 static void await(Condition condition) throws Exception {
  long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(4);
  while (!condition.ready() && System.nanoTime() < deadline) { Runnable task; while ((task = uiTasks.poll()) != null) task.run(); Thread.sleep(5); }
  check(condition.ready(), "async operation finished");
 }
 public static void main(String[] args) throws Exception {
  MobileAds.ui = Thread.currentThread();
  Harness h = new Harness(); KrollDict config = new KrollDict(); config.put("maxAdContentRating", "PG"); config.put("disableMediation", true); h.pendingAppVolume = 0.5f;
  h.initialize(config);
  check(MobileAds.entered.await(4, TimeUnit.SECONDS), "worker entered SDK");
  check(h.initializationState == OperationState.IN_FLIGHT && h.events.isEmpty(), "caller returns while SDK is blocked");
  config.put("maxAdContentRating", "MA"); h.initialize(config);
  MobileAds.release.countDown(); await(() -> MobileAds.listener != null);
  check(MobileAds.calls == 1, "concurrent calls share one SDK operation");
  check(MobileAds.rating.equals("PG"), "first accepted configuration is snapshotted");
  Thread completion = new Thread(() -> MobileAds.listener.onInitializationComplete(new InitializationStatus()));
  completion.start(); completion.join();
  check(h.events.isEmpty(), "worker callback waits for UI dispatch");
  await(() -> h.events.size() == 1);
  check(MobileAds.disabled == 1 && MobileAds.volume == 0.5f, "mediation switch and pending volume retained");
  check(h.events.size() == 1 && Boolean.TRUE.equals(h.events.get(0).get("success")), "completion emits once");
  h.initialize(config); check(h.events.size() == 2 && MobileAds.calls == 1, "completed call replays cache");
  Harness failing = new Harness(); MobileAds.fail = true; failing.initialize(new KrollDict());
  await(() -> !failing.events.isEmpty());
  check(failing.initializationState == OperationState.FAILED && Boolean.FALSE.equals(failing.events.get(0).get("success")), "worker failure has terminal event");
  check(failing.events.get(0).get("error").equals("SDK unavailable"), "failure detail retained");
  int failedCalls = MobileAds.calls; MobileAds.fail = false; MobileAds.listener = null; failing.initialize(new KrollDict());
  await(() -> MobileAds.calls == failedCalls + 1 && MobileAds.listener != null);
  MobileAds.listener.onInitializationComplete(new InitializationStatus());
  check(failing.initializationState == OperationState.COMPLETE, "failed initialization can retry");
  TiApplication.instance.activity = null; Harness missing = new Harness(); missing.initialize(new KrollDict());
  check(missing.events.size() == 1 && Boolean.FALSE.equals(missing.events.get(0).get("success")), "missing activity fails before SDK work");
  System.out.println("PASS " + checks + " Android initialization assertions");
 }
}
'''
with tempfile.TemporaryDirectory(prefix='admob-init-tests-') as directory:
    path = Path(directory)
    (path / 'Harness.java').write_text(code)
    subprocess.run(['javac', str(path / 'Harness.java')], check=True)
    subprocess.run(['java', '-cp', str(path), 'Harness'], check=True)
