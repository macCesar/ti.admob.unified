/**
 * ti.admob.unified - Unified AdMob Banner Proxy for Android
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 */

package ti.admob.unified;

import android.app.Activity;
import android.util.Log;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.titanium.TiBaseActivity;
import org.appcelerator.titanium.TiLifecycle;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.view.TiUIView;

import java.util.Map;

@Kroll.proxy(creatableInModule = TiAdmobUnifiedModule.class)
public class TiAdmobUnifiedBannerAdProxy extends TiViewProxy implements TiLifecycle.OnLifecycleEvent
{
	private static final String LCAT = "TiAdmobUnifiedBannerAdProxy";
	
	private TiAdmobUnifiedBannerAdView bannerView;
	private TiBaseActivity lifecycleActivity;
	private boolean isDestroyed;
	// Two independent pause causes. The application pauses a placement it owns
	// but no longer shows; the activity lifecycle pauses everything it hosts.
	// Either one holds the banner paused, so neither may resume the other's.
	private boolean pausedByApp;
	private boolean pausedByLifecycle;
	private boolean pendingLoad;
	private boolean destroyedEventFired;

	private boolean isPaused()
	{
		return pausedByApp || pausedByLifecycle;
	}

	public TiAdmobUnifiedBannerAdProxy()
	{
		super();
		Log.d(LCAT, "Banner proxy created");
	}

	@Override
	public TiUIView createView(Activity activity)
	{
		TiAdmobUnifiedBannerAdView createdView = new TiAdmobUnifiedBannerAdView(this);
		bannerView = createdView;
		if (activity instanceof TiBaseActivity && lifecycleActivity == null) {
			lifecycleActivity = (TiBaseActivity) activity;
			lifecycleActivity.addOnLifecycleEventListener(this);
		}
		if (isDestroyed) {
			createdView.destroy();
		} else if (isPaused()) {
			createdView.pause();
		}
		return createdView;
	}
	
	// Handle creation options
	@Override
	public void handleCreationDict(KrollDict options)
	{
		super.handleCreationDict(options);
		Log.d(LCAT, "Handling creation dictionary");
		
		// Process all creation properties
		if (options != null && bannerView != null) {
			bannerView.processProperties(options);
		}
	}
	
	public void processProperties(KrollDict d)
	{
		// Forward properties to the view
		if (bannerView != null) {
			bannerView.processProperties(d);
		}
	}

	@Kroll.method(runOnUiThread = true)
	public void load()
	{
		if (isDestroyed) {
			fireBannerEvent(TiAdmobUnifiedModule.AD_FAILED_TO_LOAD, "Banner has been destroyed", 1);
			return;
		}
		if (isPaused()) {
			pendingLoad = true;
			return;
		}
		Log.d(LCAT, "Loading banner ad");
		if (bannerView == null) {
			getOrCreateView(); // This will create the view and assign to bannerView
		}
		if (bannerView != null) {
			bannerView.loadAd();
		}
	}
	
	// Lifecycle methods
	@Kroll.method(runOnUiThread = true)
	public void pause()
	{
		if (isDestroyed || pausedByApp) {
			return;
		}
		pausedByApp = true;
		Log.d(LCAT, "Pausing banner ad");
		applyPause();
	}

	@Kroll.method(runOnUiThread = true)
	public void resume()
	{
		if (isDestroyed || !pausedByApp) {
			return;
		}
		pausedByApp = false;
		Log.d(LCAT, "Resuming banner ad");
		applyResume();
	}

	private void applyPause()
	{
		if (bannerView != null) {
			bannerView.pause();
		}
	}

	// Resumes only once every pause cause is gone. A banner the application
	// paused stays paused while the activity comes back, and vice versa, so a
	// deferred load never fires into a placement nobody is looking at.
	private void applyResume()
	{
		if (isDestroyed || isPaused()) {
			return;
		}
		if (bannerView != null) {
			bannerView.resume();
		}
		if (pendingLoad) {
			pendingLoad = false;
			load();
		}
	}

	@Kroll.method(runOnUiThread = true)
	public void destroy()
	{
		if (isDestroyed) {
			return;
		}
		isDestroyed = true;
		pendingLoad = false;
		Log.d(LCAT, "Destroying banner ad");
		if (bannerView != null) {
			bannerView.destroy();
		} else {
			fireDestroyedEvent();
		}
		detachLifecycleListener();
		releaseViews();
		bannerView = null;
	}
	
	@Kroll.method(runOnUiThread = true)
	public void destroyAdViewAndCancelRequest()
	{
		Log.d(LCAT, "destroyAdViewAndCancelRequest() called, delegating to destroy()");
		destroy();
	}

	// Misspelled legacy name kept as deprecated alias for backwards compatibility
	// with consumer JS that may already call destoyAdViewAndCancelRequest().
	@Kroll.method(runOnUiThread = true)
	public void destoyAdViewAndCancelRequest()
	{
		Log.w(LCAT, "destoyAdViewAndCancelRequest() is misspelled and deprecated; use destroyAdViewAndCancelRequest() or destroy()");
		destroy();
	}

	@Kroll.method
	public boolean isLoaded()
	{
		return !isDestroyed && bannerView != null && bannerView.isLoaded();
	}

	private void fireDestroyedEvent()
	{
		if (!destroyedEventFired) {
			destroyedEventFired = true;
			fireBannerEvent(TiAdmobUnifiedModule.AD_DESTROYED, null, 0);
		}
	}

	private void fireBannerEvent(String eventName, String error, int code)
	{
		KrollDict event = new KrollDict();
		event.put("adUnitId", getAdUnitId() != null ? getAdUnitId() : "");
		event.put("adType", TiAdmobUnifiedModule.AD_TYPE_BANNER);
		event.put("isAdaptive", false);
		if (error != null) {
			event.put("error", error);
			event.put("code", code);
		}
		fireEvent(eventName, event);
	}

	private void detachLifecycleListener()
	{
		if (lifecycleActivity != null) {
			lifecycleActivity.removeOnLifecycleEventListener(this);
			lifecycleActivity = null;
		}
	}

	void onBannerViewDestroyed(TiAdmobUnifiedBannerAdView destroyedView)
	{
		if (bannerView == destroyedView) {
			bannerView = null;
		}
		isDestroyed = true;
		pendingLoad = false;
		destroyedEventFired = true;
		detachLifecycleListener();
	}

	@Kroll.getProperty
	public String getAdUnitId()
	{
		return TiConvert.toString(getProperty("adUnitId"));
	}

	@Kroll.setProperty
	public void setAdUnitId(String adUnitId)
	{
		Log.d(LCAT, "Setting ad unit ID: " + adUnitId);
		setProperty("adUnitId", adUnitId);
		
		if (bannerView != null) {
			bannerView.setAdUnitId(adUnitId);
		}
	}

	@Kroll.getProperty
	public String getAdSize()
	{
		return TiConvert.toString(getProperty("adSize"));
	}

	@Kroll.setProperty
	public void setAdSize(String adSize)
	{
		Log.d(LCAT, "Setting ad size: " + adSize);
		setProperty("adSize", adSize);
		
		if (bannerView != null) {
			bannerView.setAdSize(adSize);
		}
	}
	
	// Additional properties
	@Kroll.getProperty
	public String[] getKeywords()
	{
		return (String[]) getProperty("keywords");
	}

	@Kroll.setProperty
	public void setKeywords(String[] keywords)
	{
		Log.d(LCAT, "Setting keywords: " + (keywords != null ? java.util.Arrays.toString(keywords) : "null"));
		setProperty("keywords", keywords);
		
		if (bannerView != null) {
			bannerView.setKeywords(keywords);
		}
	}
	
	@Kroll.getProperty
	public String getContentUrl()
	{
		return TiConvert.toString(getProperty("contentUrl"));
	}

	@Kroll.setProperty
	public void setContentUrl(String contentUrl)
	{
		Log.d(LCAT, "Setting content URL: " + contentUrl);
		setProperty("contentUrl", contentUrl);
		
		if (bannerView != null) {
			bannerView.setContentUrl(contentUrl);
		}
	}

	@Kroll.getProperty
	public String getRequestAgent()
	{
		return TiConvert.toString(getProperty("requestAgent"));
	}

	@Kroll.setProperty
	public void setRequestAgent(String requestAgent)
	{
		Log.d(LCAT, "Setting request agent: " + requestAgent);
		setProperty("requestAgent", requestAgent);

		if (bannerView != null) {
			bannerView.setRequestAgent(requestAgent);
		}
	}
	
	@Kroll.getProperty
	public KrollDict getCustomAdSize()
	{
		Object customSizeValue = getProperty("customAdSize");
		if (customSizeValue instanceof KrollDict) {
			return (KrollDict) customSizeValue;
		}
		if (customSizeValue instanceof Map) {
			@SuppressWarnings("unchecked")
			Map<String, Object> customSizeMap = (Map<String, Object>) customSizeValue;
			return new KrollDict(customSizeMap);
		}
		return null;
	}

	@Kroll.setProperty
	public void setCustomAdSize(KrollDict customAdSize)
	{
		Log.d(LCAT, "Setting custom ad size");
		setProperty("customAdSize", customAdSize);
		
		if (bannerView != null) {
			bannerView.setCustomAdSize(customAdSize);
		}
	}

	// TiLifecycle.OnLifecycleEvent implementation
	@Override
	public void onDestroy(Activity activity)
	{
		Log.d(LCAT, "Activity destroyed, cleaning up banner ad");
		if (activity instanceof TiBaseActivity) {
			((TiBaseActivity) activity).removeOnLifecycleEventListener(this);
			lifecycleActivity = null;
		}
		destroy();
		super.onDestroy(activity);
	}
	
	@Override
	public void onPause(Activity activity)
	{
		if (isDestroyed || pausedByLifecycle) {
			return;
		}
		pausedByLifecycle = true;
		Log.d(LCAT, "Activity paused, pausing banner ad");
		applyPause();
	}

	@Override
	public void onResume(Activity activity)
	{
		if (isDestroyed || !pausedByLifecycle) {
			return;
		}
		pausedByLifecycle = false;
		Log.d(LCAT, "Activity resumed, resuming banner ad");
		applyResume();
	}
	
	@Override
	public void onStart(Activity activity) {
		// No action needed
	}
	
	@Override
	public void onStop(Activity activity) {
		// No action needed
	}

	@Override
	public String getApiName()
	{
		return "ti.admob.unified.BannerAd";
	}
}
