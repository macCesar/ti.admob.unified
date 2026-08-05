/**
 * ti.admob.unified - Unified AdMob Banner View for Android
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 */

package ti.admob.unified;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.google.ads.mediation.admob.AdMobAdapter;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.LoadAdError;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.titanium.TiC;
import org.appcelerator.titanium.TiApplication;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.view.TiUIView;

import java.util.HashMap;
import java.util.Map;

public class TiAdmobUnifiedBannerAdView extends TiUIView
{
	private static final String LCAT = "TiAdmobUnifiedBannerAdView";
	
	private final TiAdmobUnifiedBannerAdProxy bannerProxy;
	private final FrameLayout nativeContainer;
	private AdView adView;
	private boolean isAdLoaded = false;
	private boolean isLoading;
	private boolean isPaused;
	private boolean isDestroyed;
	private boolean pendingLoad;
	private String adUnitId;
	private AdSize adSize = AdSize.BANNER;
	
	// Advanced properties
	private String[] keywords;
	private String contentUrl;
	// Identifies what issued the request. Google reserves it for libraries that
	// wrap the SDK, which is exactly what this module is.
	private String requestAgent;
	private Bundle extras;
	private KrollDict customAdSize;
	
	// Positioning properties
	private int propTop;
	private int propLeft;
	private int propRight;

	@SuppressWarnings("this-escape")
	public TiAdmobUnifiedBannerAdView(TiAdmobUnifiedBannerAdProxy proxy)
	{
		super(proxy);
		bannerProxy = proxy;
		nativeContainer = new FrameLayout(proxy.getActivity());
		setNativeView(nativeContainer);
		Log.d(LCAT, "Banner view created");
		// Don't create AdView immediately - wait for properties
	}

	private void createAdView()
	{
		if (isDestroyed || adView != null) {
			return;
		}
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot create banner - no current activity");
			return;
		}

		if (adUnitId == null) {
			Log.d(LCAT, "AdView creation deferred - no ad unit ID yet");
			return;
		}

		adView = new AdView(activity);
		adView.setAdSize(adSize);
		bannerProxy.setProperty(TiC.PROPERTY_HEIGHT, adSize.getHeight());
		adView.setAdUnitId(adUnitId);
		
		adView.setAdListener(new com.google.android.gms.ads.AdListener() {
			@Override
			public void onAdLoaded() {
				if (isDestroyed) {
					return;
				}
				Log.d(LCAT, "Banner ad loaded successfully");
				isLoading = false;
				isAdLoaded = true;
				fireAdEvent(TiAdmobUnifiedModule.AD_LOADED, null);
			}

			@Override
			public void onAdFailedToLoad(LoadAdError loadAdError) {
				if (isDestroyed) {
					return;
				}
				Log.e(LCAT, "Banner ad failed to load: " + loadAdError.getMessage());
				isLoading = false;
				isAdLoaded = false;
				
				Map<String, Object> event = new HashMap<>();
				event.put("error", loadAdError.getMessage());
				event.put("code", loadAdError.getCode());
				fireAdEvent(TiAdmobUnifiedModule.AD_FAILED_TO_LOAD, event);
			}

			@Override
			public void onAdClicked() {
				Log.d(LCAT, "Banner ad clicked");
				fireAdEvent(TiAdmobUnifiedModule.AD_CLICKED, null);
			}

			@Override
			public void onAdImpression() {
				Log.d(LCAT, "Banner ad impression recorded");
				fireAdEvent(TiAdmobUnifiedModule.AD_IMPRESSION, null);
			}

			@Override
			public void onAdOpened() {
				Log.d(LCAT, "Banner ad opened");
				fireAdEvent(TiAdmobUnifiedModule.AD_OPENED, null);
			}

			@Override
			public void onAdClosed() {
				Log.d(LCAT, "Banner ad closed");
				fireAdEvent(TiAdmobUnifiedModule.AD_CLOSED, null);
			}
		});

		// Set positioning properties
		adView.setPadding(propLeft, propTop, propRight, 0);
		nativeContainer.addView(
			adView,
			new FrameLayout.LayoutParams(
				ViewGroup.LayoutParams.MATCH_PARENT,
				ViewGroup.LayoutParams.WRAP_CONTENT));
		Log.d(LCAT, "AdView created with unit ID: " + adUnitId);
	}

	public void loadAd()
	{
		if (isDestroyed) {
			fireFailure("Banner has been destroyed", 1);
			return;
		}
		if (isPaused) {
			pendingLoad = true;
			return;
		}
		if (isLoading) {
			Log.d(LCAT, "Ignoring duplicate banner load while a request is active");
			return;
		}
		if (adView == null) {
			Log.d(LCAT, "AdView not created yet, creating now");
			createAdView();
		}
		
		if (adView == null) {
			Log.e(LCAT, "Cannot load ad - AdView creation failed");
			fireFailure("Banner view could not be created", 2);
			return;
		}

		// Build AdRequest with advanced properties
		AdRequest.Builder adRequestBuilder = new AdRequest.Builder();
		
		// Add keywords
		if (keywords != null) {
			for (String keyword : keywords) {
				adRequestBuilder.addKeyword(keyword);
			}
			Log.d(LCAT, "Added keywords: " + java.util.Arrays.toString(keywords));
		}
		
		// Set content URL
		if (contentUrl != null) {
			adRequestBuilder.setContentUrl(contentUrl);
			Log.d(LCAT, "Set content URL: " + contentUrl);
		}

		if (requestAgent != null && !requestAgent.isEmpty()) {
			adRequestBuilder.setRequestAgent(requestAgent);
			Log.d(LCAT, "Set request agent: " + requestAgent);
		}
		
		// Add network extras
		if (extras != null && !extras.isEmpty()) {
			adRequestBuilder.addNetworkExtrasBundle(AdMobAdapter.class, extras);
			Log.d(LCAT, "Added network extras");
		}
		
		AdRequest adRequest = adRequestBuilder.build();
		Log.d(LCAT, "Loading banner ad with unit ID: " + adUnitId);
		isLoading = true;
		isAdLoaded = false;
		adView.loadAd(adRequest);
	}

	public void setAdUnitId(String unitId)
	{
		this.adUnitId = unitId;
		Log.d(LCAT, "Ad unit ID set to: " + unitId);
		
		if (adView != null) {
			adView.setAdUnitId(unitId);
		}
	}

	public void setAdSize(String sizeString)
	{
		this.adSize = getAdSizeFromString(sizeString);
		Log.d(LCAT, "Ad size set to: " + sizeString);
		
		// If AdView exists, recreate it with new size
		if (adView != null) {
			recreateAdView();
		}
	}
	
	public void setCustomAdSize(KrollDict customSize)
	{
		this.customAdSize = customSize;
		
		if (customSize != null) {
			int width = TiConvert.toInt(customSize.get("width"));
			int height = TiConvert.toInt(customSize.get("height"));
			this.adSize = new AdSize(width, height);
			Log.d(LCAT, "Custom ad size set to: " + width + "x" + height);
			
			// If AdView exists, recreate it with new size
			if (adView != null) {
				recreateAdView();
			}
		}
	}
	
	public void setKeywords(String[] keywordArray)
	{
		this.keywords = keywordArray;
		Log.d(LCAT, "Keywords set: " + (keywordArray != null ? java.util.Arrays.toString(keywordArray) : "null"));
	}
	
	public void setContentUrl(String url)
	{
		this.contentUrl = url;
		Log.d(LCAT, "Content URL set: " + url);
	}

	public void setRequestAgent(String agent)
	{
		this.requestAgent = agent;
	}
	
	public void setExtras(Bundle bundleExtras)
	{
		this.extras = bundleExtras;
		Log.d(LCAT, "Network extras set");
	}

	public boolean isLoaded()
	{
		return !isDestroyed && isAdLoaded;
	}

	public void pause()
	{
		if (isDestroyed || isPaused) {
			return;
		}
		isPaused = true;
		if (adView != null) {
			// INVISIBLE, not GONE: it matches the iOS `hidden` behaviour and
			// keeps the measured slot, so returning does not reflow the layout.
			adView.setVisibility(View.INVISIBLE);
			adView.pause();
			Log.d(LCAT, "Banner ad paused");
		}
	}

	public void resume()
	{
		if (isDestroyed || !isPaused) {
			return;
		}
		isPaused = false;
		if (adView != null) {
			adView.setVisibility(View.VISIBLE);
			adView.resume();
			Log.d(LCAT, "Banner ad resumed");
		}
		if (pendingLoad) {
			pendingLoad = false;
			loadAd();
		}
	}
	
	public void destroy()
	{
		if (isDestroyed) {
			return;
		}
		isDestroyed = true;
		isLoading = false;
		isAdLoaded = false;
		pendingLoad = false;
		AdView viewToDestroy = adView;
		adView = null;
		if (viewToDestroy != null) {
			viewToDestroy.setAdListener(null);
			nativeContainer.removeView(viewToDestroy);
			viewToDestroy.destroy();
		}
		Log.d(LCAT, "Banner ad destroyed");
		fireAdEvent(TiAdmobUnifiedModule.AD_DESTROYED, null);
		bannerProxy.onBannerViewDestroyed(this);
	}

	@Override
	public void release()
	{
		destroy();
		super.release();
	}
	
	private void recreateAdView()
	{
		if (adView != null) {
			AdView viewToDestroy = adView;
			adView = null;
			viewToDestroy.setAdListener(null);
			nativeContainer.removeView(viewToDestroy);
			viewToDestroy.destroy();
			isLoading = false;
			isAdLoaded = false;
		}
		
		// Create new view with updated properties
		createAdView();
	}

	private void fireFailure(String message, int code)
	{
		Map<String, Object> event = new HashMap<>();
		event.put("error", message);
		event.put("code", code);
		fireAdEvent(TiAdmobUnifiedModule.AD_FAILED_TO_LOAD, event);
	}

	private void fireAdEvent(String eventName, Map<String, Object> data)
	{
		if (data == null) {
			data = new HashMap<>();
		}
		data.put("adUnitId", adUnitId != null ? adUnitId : "");
		data.put("adType", TiAdmobUnifiedModule.AD_TYPE_BANNER);
		data.put("isAdaptive", false);
		Log.d(LCAT, "Firing event: " + eventName);
		proxy.fireEvent(eventName, data);
	}

	// Process properties from Titanium proxy
	public void processProperties(KrollDict properties)
	{
		if (properties == null) return;
		
		Log.d(LCAT, "Processing banner properties");
		
		// Handle adUnitId
		if (properties.containsKeyAndNotNull("adUnitId")) {
			setAdUnitId(TiConvert.toString(properties.get("adUnitId")));
		}
		
		// Handle adSize
		if (properties.containsKeyAndNotNull("adSize")) {
			setAdSize(TiConvert.toString(properties.get("adSize")));
		}
		
		// Handle customAdSize
		if (properties.containsKeyAndNotNull("customAdSize")) {
			Object customSizeValue = properties.get("customAdSize");
			if (customSizeValue instanceof KrollDict) {
				setCustomAdSize((KrollDict) customSizeValue);
			} else if (customSizeValue instanceof Map) {
				@SuppressWarnings("unchecked")
				Map<String, Object> customSizeMap = (Map<String, Object>) customSizeValue;
				setCustomAdSize(new KrollDict(customSizeMap));
			} else {
				Log.w(LCAT, "Ignoring invalid customAdSize value");
			}
		}
		
		// Handle keywords
		if (properties.containsKeyAndNotNull("keywords")) {
			Object keywordsObj = properties.get("keywords");
			if (keywordsObj instanceof String[]) {
				setKeywords((String[]) keywordsObj);
			} else if (keywordsObj instanceof String) {
				setKeywords(new String[]{(String) keywordsObj});
			}
		}
		
		// Handle contentUrl
		if (properties.containsKeyAndNotNull("contentUrl")) {
			setContentUrl(TiConvert.toString(properties.get("contentUrl")));
		}

		// Handle requestAgent
		if (properties.containsKeyAndNotNull("requestAgent")) {
			setRequestAgent(TiConvert.toString(properties.get("requestAgent")));
		}
		
		// Handle extras bundle
		if (properties.containsKeyAndNotNull("extras")) {
			KrollDict extrasDict = (KrollDict) properties.get("extras");
			Bundle extrasBundle = new Bundle();
			
			for (String key : extrasDict.keySet()) {
				Object value = extrasDict.get(key);
				if (value instanceof String) {
					extrasBundle.putString(key, (String) value);
				} else if (value instanceof Integer) {
					extrasBundle.putInt(key, (Integer) value);
				} else if (value instanceof Boolean) {
					extrasBundle.putBoolean(key, (Boolean) value);
				} else {
					extrasBundle.putString(key, value.toString());
				}
			}
			
			setExtras(extrasBundle);
		}
		
		// Handle positioning properties
		if (properties.containsKey("top")) {
			propTop = TiConvert.toInt(properties.get("top"));
		}
		if (properties.containsKey("left")) {
			propLeft = TiConvert.toInt(properties.get("left"));
		}
		if (properties.containsKey("right")) {
			propRight = TiConvert.toInt(properties.get("right"));
		}
	}
	
	private static AdSize getAdSizeFromString(String sizeString)
	{
		if (sizeString == null) {
			return AdSize.BANNER;
		}

		switch (sizeString.toLowerCase()) {
			case "banner":
				return AdSize.BANNER;
			case "large_banner":
				return AdSize.LARGE_BANNER;
			case "medium_rectangle":
				return AdSize.MEDIUM_RECTANGLE;
			case "full_banner":
			case "fullbanner": // Support both variants
				return AdSize.FULL_BANNER;
			case "leaderboard":
				return AdSize.LEADERBOARD;
			// smart_banner is intentionally not special-cased. Google removed the
			// size from this SDK and deprecated it on iOS, and the module used to
			// resolve it differently on each platform: a fixed 320x50 here against
			// a full-width strip on iOS. Translating one value into two different
			// ads is the module deciding, not bridging. It now falls through to
			// BANNER on both. For a full-width strip use customAdSize.
			default:
				Log.w(LCAT, "Unknown ad size: " + sizeString + ", using BANNER");
				return AdSize.BANNER;
		}
	}
}
