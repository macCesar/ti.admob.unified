/**
 * ti.admob.unified - Unified AdMob App Open Ad Proxy for Android
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */
package ti.admob.unified;

import android.app.Activity;
import android.os.Bundle;

import com.google.ads.mediation.admob.AdMobAdapter;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.appopen.AppOpenAd;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.titanium.TiApplication;

import java.util.HashMap;
import java.util.Map;

@Kroll.proxy(creatableInModule = TiAdmobUnifiedModule.class)
public class TiAdmobUnifiedAppOpenAdProxy extends KrollProxy
{
	private static final String LCAT = "TiAdmobUnifiedAppOpenAdProxy";

	// Google documents that an app open ad expires four hours after the request.
	// An ad rendered later is no longer valid and may not earn revenue.
	private static final long VALIDITY_WINDOW_MS = 4 * 60 * 60 * 1000L;

	// Ad configuration
	private String adUnitId;
    private String requestAdUnitId;
	private boolean autoReload;
	private String[] keywords;
	// Identifies what issued the request. Google reserves it for libraries that
	// wrap the SDK, which is exactly what this module is.
	private String requestAgent;
	private KrollDict extras;

	// Ad instance (Android requires fresh ads)
	private AppOpenAd appOpenAd;
	private boolean isLoading = false;
	private boolean isShowing = false;
	private boolean isDestroyed = false;
	private boolean destroyedEventFired = false;

	// Timestamp of the last successful load, used to enforce the four hour window
	private long loadTime = 0;

	public TiAdmobUnifiedAppOpenAdProxy(KrollDict config)
	{
		super();

		// Extract configuration
		if (config != null) {
			this.adUnitId = config.optString("adUnitId", "");
			this.autoReload = config.optBoolean("autoReload", false);
			this.requestAgent = config.optString("requestAgent", null);

			// Extract keywords
			if (config.containsKey("keywords")) {
				this.keywords = config.getStringArray("keywords");
			}

            if (config.containsKey("extras")) this.extras = config.getKrollDict("extras");
		}

		Log.d(LCAT, "AppOpenAdProxy created with adUnitId: " + this.adUnitId);
	}

    @Kroll.getProperty
    public String getAdUnitId() { return adUnitId; }

    @Kroll.setProperty
    public void setAdUnitId(String value) { adUnitId = value; }

    @Kroll.getProperty
    public boolean getAutoReload() { return autoReload; }

    @Kroll.setProperty
    public void setAutoReload(boolean value) { autoReload = value; }

    @Kroll.getProperty
    public String[] getKeywords() { return keywords; }

    @Kroll.setProperty
    public void setKeywords(String[] value) { keywords = value; }

    @Kroll.getProperty
    public KrollDict getExtras() { return extras; }

    @Kroll.setProperty
    public void setExtras(KrollDict value) { extras = value; }

    @Kroll.getProperty
    public String getRequestAgent() { return requestAgent; }

    @Kroll.setProperty
    public void setRequestAgent(String value) { requestAgent = value; }


	// ===================================================================
	// PUBLIC METHODS
	// ===================================================================
	@Kroll.method(runOnUiThread = true)
	public void load()
	{
		Log.d(LCAT, "Loading app open ad");

		if (isDestroyed) {
			Log.w(LCAT, "Ignoring load after app open destruction");
			return;
		}

		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot load ad - no current activity");
			fireErrorEvent("No current activity available", -1);
			return;
		}

		// An expired ad is no longer showable, so it must not block a new request.
		if (!isShowing && isAdExpired()) {
			Log.d(LCAT, "Discarding expired app open ad before reloading");
			discardAd();
		}

		if (isLoading || isShowing || appOpenAd != null) {
			Log.w(LCAT, "Ignoring duplicate app open load");
			return;
		}

		if (adUnitId.isEmpty()) {
			Log.e(LCAT, "Cannot load ad - no ad unit ID provided");
			fireErrorEvent("Ad unit ID is required", TiAdmobUnifiedModule.ERROR_CODE_INVALID_REQUEST);
			return;
		}

		requestAdUnitId = adUnitId;
        isLoading = true;

		// Build ad request
		AdRequest.Builder adRequestBuilder = new AdRequest.Builder();

		// Add keywords if provided
		if (keywords != null && keywords.length > 0) {
			for (String keyword : keywords) {
				adRequestBuilder.addKeyword(keyword);
			}
		}

		if (extras != null && !extras.isEmpty()) {
			Bundle extrasBundle = new Bundle();
			for (Map.Entry<String, Object> entry : extras.entrySet()) {
                Object value = entry.getValue();
                if (value instanceof Boolean) extrasBundle.putBoolean(entry.getKey(), (Boolean) value);
                else if (value instanceof Integer) extrasBundle.putInt(entry.getKey(), (Integer) value);
                else if (value instanceof Long) extrasBundle.putLong(entry.getKey(), (Long) value);
                else if (value instanceof Number) extrasBundle.putDouble(entry.getKey(), ((Number) value).doubleValue());
                else if (value instanceof String) extrasBundle.putString(entry.getKey(), (String) value);
            }
			adRequestBuilder.addNetworkExtrasBundle(AdMobAdapter.class, extrasBundle);
		}

		if (requestAgent != null && !requestAgent.isEmpty()) {
			adRequestBuilder.setRequestAgent(requestAgent);
		}

		AdRequest adRequest = adRequestBuilder.build();

		// Load app open ad
		AppOpenAd.load(
			activity,
			adUnitId,
			adRequest,
			new AppOpenAd.AppOpenAdLoadCallback() {
				@Override
				public void onAdLoaded(AppOpenAd ad) {
					if (isDestroyed) {
						return;
					}
					Log.d(LCAT, "App open ad loaded successfully");

					appOpenAd = ad;
					isLoading = false;
					loadTime = System.currentTimeMillis();

					// Set up ad callbacks
					setupAdCallbacks();

					// Fire loaded event
					fireEvent(TiAdmobUnifiedModule.AD_LOADED, baseEvent());
				}

				@Override
				public void onAdFailedToLoad(LoadAdError error) {
					if (isDestroyed) {
						return;
					}
					Log.e(LCAT, "App open ad failed to load: " + error.getMessage());

					isLoading = false;

					// Fire failed to load event
					fireErrorEvent(error.getMessage(), TiAdmobUnifiedModule.loadErrorCode(error));
				}
			}
		);
	}

	@Kroll.method(runOnUiThread = true)
	public void show()
	{
		Log.d(LCAT, "Showing app open ad");

		if (isDestroyed) {
			fireFailedToShowEvent(
				"App open has been destroyed",
				TiAdmobUnifiedModule.ERROR_CODE_INVALID_REQUEST);
			return;
		}

		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot show ad - no current activity");
			fireFailedToShowEvent("No current activity available", -1);
			return;
		}

		if (appOpenAd == null) {
			Log.e(LCAT, "Cannot show ad - ad not loaded");
			fireFailedToShowEvent("Ad not loaded", TiAdmobUnifiedModule.ERROR_CODE_INVALID_REQUEST);
			return;
		}

		if (isShowing) {
			fireFailedToShowEvent(
				"Ad is already showing",
				TiAdmobUnifiedModule.ERROR_CODE_INVALID_REQUEST);
			return;
		}

		if (isAdExpired()) {
			Log.e(LCAT, "Cannot show ad - the four hour window elapsed");
			discardAd();
			fireFailedToShowEvent(
				"App open ad expired after four hours",
				TiAdmobUnifiedModule.ERROR_CODE_INVALID_REQUEST);
			return;
		}

		// Show app open ad
		isShowing = true;
		appOpenAd.show(activity);
	}

	@Kroll.method(runOnUiThread = true)
	public boolean isLoaded()
	{
		return !isDestroyed && appOpenAd != null && !isLoading && !isShowing && !isAdExpired();
	}

	@Kroll.method(runOnUiThread = true)
	public void destroy()
	{
		if (isDestroyed) {
			return;
		}
		Log.d(LCAT, "Destroying app open ad");

		isDestroyed = true;
		if (appOpenAd != null) {
			appOpenAd.setFullScreenContentCallback(null);
		}
		appOpenAd = null;
		loadTime = 0;
		isLoading = false;
		isShowing = false;

		if (!destroyedEventFired) {
			destroyedEventFired = true;
			fireEvent(TiAdmobUnifiedModule.AD_DESTROYED, baseEvent());
		}
	}

	@Override
	public void release()
	{
		destroy();
		super.release();
	}

	// ===================================================================
	// PRIVATE HELPER METHODS
	// ===================================================================
	private boolean isAdExpired()
	{
		if (appOpenAd == null || loadTime == 0) {
			return false;
		}
		return System.currentTimeMillis() - loadTime >= VALIDITY_WINDOW_MS;
	}

	private void discardAd()
	{
		if (appOpenAd != null) {
			appOpenAd.setFullScreenContentCallback(null);
		}
		appOpenAd = null;
		loadTime = 0;
	}

	private void setupAdCallbacks()
	{
		if (appOpenAd == null) {
			return;
		}

		appOpenAd.setFullScreenContentCallback(new FullScreenContentCallback() {
			@Override
			public void onAdShowedFullScreenContent() {
				if (isDestroyed) {
					return;
				}
				Log.d(LCAT, "App open ad showed full screen content");

				Map<String, Object> event = baseEvent();
				fireEvent(TiAdmobUnifiedModule.AD_OPENED, event);
				fireEvent(TiAdmobUnifiedModule.AD_SHOWED_FULLSCREEN_CONTENT, event);
			}

			@Override
			public void onAdDismissedFullScreenContent() {
				if (isDestroyed) {
					return;
				}
				Log.d(LCAT, "App open ad dismissed full screen content");

				appOpenAd = null;
				loadTime = 0;
				isShowing = false;
				fireEvent(TiAdmobUnifiedModule.AD_CLOSED, baseEvent());

				if (autoReload) {
					Log.d(LCAT, "Auto-reloading app open ad");
					load();
				}
			}

			@Override
			public void onAdFailedToShowFullScreenContent(AdError error) {
				if (isDestroyed) {
					return;
				}
				Log.e(LCAT, "App open ad failed to show: " + error.getMessage());

				appOpenAd = null;
				loadTime = 0;
				isShowing = false;
				fireFailedToShowEvent(error.getMessage(), error.getCode());
			}

			@Override
			public void onAdClicked() {
				if (isDestroyed) {
					return;
				}
				Log.d(LCAT, "App open ad clicked");
				fireEvent(TiAdmobUnifiedModule.AD_CLICKED, baseEvent());
			}

			@Override
			public void onAdImpression() {
				if (isDestroyed) {
					return;
				}
				Log.d(LCAT, "App open ad impression recorded");
				fireEvent(TiAdmobUnifiedModule.AD_IMPRESSION, baseEvent());
			}
		});
	}

	private Map<String, Object> baseEvent()
	{
		Map<String, Object> event = new HashMap<>();
		event.put("adUnitId", requestAdUnitId != null ? requestAdUnitId : adUnitId);
		event.put("adType", TiAdmobUnifiedModule.AD_TYPE_APP_OPEN);
		return event;
	}

	private void fireErrorEvent(String errorMessage, int errorCode)
	{
		Map<String, Object> errorEvent = baseEvent();
		errorEvent.put("error", errorMessage);
		errorEvent.put("message", errorMessage);
		errorEvent.put("code", errorCode);
		fireEvent(TiAdmobUnifiedModule.AD_FAILED_TO_LOAD, errorEvent);
	}

	private void fireFailedToShowEvent(String errorMessage, int errorCode)
	{
		Map<String, Object> errorEvent = baseEvent();
		errorEvent.put("error", errorMessage);
		errorEvent.put("message", errorMessage);
		errorEvent.put("code", errorCode);
		fireEvent(TiAdmobUnifiedModule.AD_FAILED_TO_SHOW, errorEvent);
	}
}
