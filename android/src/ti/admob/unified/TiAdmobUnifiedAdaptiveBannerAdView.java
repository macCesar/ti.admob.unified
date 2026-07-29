/**
 * ti.admob.unified - Unified AdMob Adaptive Banner View for Android
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 */

package ti.admob.unified;

import android.app.Activity;
import android.graphics.Rect;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.WindowMetrics;

import com.google.ads.mediation.admob.AdMobAdapter;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.LoadAdError;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.titanium.TiApplication;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.view.TiUIView;

import java.util.HashMap;
import java.util.Map;

public class TiAdmobUnifiedAdaptiveBannerAdView extends TiUIView
{
	private static final String LCAT = "TiAdmobUnifiedAdaptiveBannerAdView";
	
	private AdView adView;
	private boolean isAdLoaded = false;
	private String adUnitId;
	
	// Adaptive banner specific properties
	private String adaptiveType = TiAdmobUnifiedModule.ADAPTIVE_ANCHORED; // Default
	private int maxHeight = 50; // Default for inline ads
	private String collapsible; // Optional collapsible setting
	
	// Advanced properties
	private String[] keywords;
	private String contentUrl;
	private Bundle extras;
	
	// Positioning properties
	private int propTop;
	private int propLeft;
	private int propRight;

	public TiAdmobUnifiedAdaptiveBannerAdView(TiViewProxy proxy)
	{
		super(proxy);
		Log.d(LCAT, "Adaptive banner view created");
		// Don't create AdView immediately - wait for properties
	}

	private void createAdView()
	{
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot create adaptive banner - no current activity");
			return;
		}

		if (adUnitId == null) {
			Log.d(LCAT, "AdView creation deferred - no ad unit ID yet");
			return;
		}

		adView = new AdView(activity);
		adView.setAdUnitId(adUnitId);
		
		// Calculate adaptive banner size
		AdSize adSize = getAdaptiveAdSize(activity);
		adView.setAdSize(adSize);
		Log.d(LCAT, "Adaptive ad size: " + adSize.getWidth() + "x" + adSize.getHeight());
		
		adView.setAdListener(new com.google.android.gms.ads.AdListener() {
			@Override
			public void onAdLoaded() {
				Log.d(LCAT, "Adaptive banner ad loaded successfully");
				isAdLoaded = true;
				fireAdEvent(TiAdmobUnifiedModule.AD_LOADED, null);
			}

			@Override
			public void onAdFailedToLoad(LoadAdError loadAdError) {
				Log.e(LCAT, "Adaptive banner ad failed to load: " + loadAdError.getMessage());
				isAdLoaded = false;
				
				Map<String, Object> event = new HashMap<>();
				event.put("error", loadAdError.getMessage());
				event.put("code", loadAdError.getCode());
				fireAdEvent(TiAdmobUnifiedModule.AD_FAILED_TO_LOAD, event);
			}

			@Override
			public void onAdClicked() {
				Log.d(LCAT, "Adaptive banner ad clicked");
				fireAdEvent(TiAdmobUnifiedModule.AD_CLICKED, null);
			}

			@Override
			public void onAdImpression() {
				Log.d(LCAT, "Adaptive banner ad impression recorded");
				fireAdEvent(TiAdmobUnifiedModule.AD_IMPRESSION, null);
			}

			@Override
			public void onAdOpened() {
				Log.d(LCAT, "Adaptive banner ad opened");
				fireAdEvent(TiAdmobUnifiedModule.AD_OPENED, null);
			}

			@Override
			public void onAdClosed() {
				Log.d(LCAT, "Adaptive banner ad closed");
				fireAdEvent(TiAdmobUnifiedModule.AD_CLOSED, null);
			}
		});

		// Set positioning properties
		adView.setPadding(propLeft, propTop, propRight, 0);
		setNativeView(adView);
		Log.d(LCAT, "Adaptive AdView created with unit ID: " + adUnitId);
	}
	
	private AdSize getAdaptiveAdSize(Activity activity)
	{
		int adWidth = getAdWidth(activity);
		
		if (TiAdmobUnifiedModule.ADAPTIVE_INLINE.equals(adaptiveType)) {
			// Inline adaptive banner with maxHeight constraint
			Log.d(LCAT, "Creating inline adaptive banner with max height: " + maxHeight);
			return AdSize.getInlineAdaptiveBannerAdSize(adWidth, maxHeight);
		} else {
			// Anchored adaptive banner (default)
			Log.d(LCAT, "Creating anchored adaptive banner");
			AdSize adSize = AdSize.getLargeAnchoredAdaptiveBannerAdSize(activity, adWidth);
			
			// Handle collapsible if specified
			if (collapsible != null) {
				Log.d(LCAT, "Setting collapsible: " + collapsible);
				// Note: Collapsible is handled via AdRequest extras, not AdSize
			}
			
			return adSize;
		}
	}
	
	@SuppressWarnings("deprecation") // legacy branch uses pre-API-30 APIs intentionally
	private int getAdWidth(Activity activity)
	{
		// Get display width in density-independent pixels
		int adWidth = 0;

		if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
			// For API 30+
			WindowMetrics windowMetrics = activity.getWindowManager().getCurrentWindowMetrics();
			Rect bounds = windowMetrics.getBounds();
			DisplayMetrics metrics = activity.getResources().getDisplayMetrics();
			adWidth = (int) (bounds.width() / metrics.density);
			Log.d(LCAT, "Window width (API 30+): " + adWidth);
		} else {
			// For older versions
			DisplayMetrics displayMetrics = new DisplayMetrics();
			activity.getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
			adWidth = (int) (displayMetrics.widthPixels / displayMetrics.density);
			Log.d(LCAT, "Window width (legacy): " + adWidth);
		}

		return adWidth;
	}

	public void loadAd()
	{
		if (adView == null) {
			Log.d(LCAT, "AdView not created yet, creating now");
			createAdView();
		}
		
		if (adView == null) {
			Log.e(LCAT, "Cannot load ad - AdView creation failed");
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
		
		// Add network extras (including collapsible if specified)
		Bundle requestExtras = new Bundle();
		if (extras != null && !extras.isEmpty()) {
			requestExtras.putAll(extras);
		}
		
		// Add collapsible setting if specified
		if (collapsible != null) {
			requestExtras.putString("collapsible", collapsible);
			Log.d(LCAT, "Added collapsible setting: " + collapsible);
		}
		
		if (!requestExtras.isEmpty()) {
			adRequestBuilder.addNetworkExtrasBundle(AdMobAdapter.class, requestExtras);
			Log.d(LCAT, "Added network extras");
		}
		
		AdRequest adRequest = adRequestBuilder.build();
		Log.d(LCAT, "Loading adaptive banner ad with unit ID: " + adUnitId);
		adView.loadAd(adRequest);
	}

	public void setAdUnitId(String unitId)
	{
		this.adUnitId = unitId;
		Log.d(LCAT, "Ad unit ID set to: " + unitId);
		
		if (adView == null && unitId != null) {
			createAdView();
		} else if (adView != null) {
			adView.setAdUnitId(unitId);
		}
	}
	
	public void setAdaptiveType(String type)
	{
		this.adaptiveType = type;
		Log.d(LCAT, "Adaptive type set to: " + type);
		
		// If AdView exists, recreate it with new type
		if (adView != null) {
			recreateAdView();
		}
	}
	
	public void setMaxHeight(int height)
	{
		this.maxHeight = height;
		Log.d(LCAT, "Max height set to: " + height);
		
		// If AdView exists and it's inline type, recreate it
		if (adView != null && TiAdmobUnifiedModule.ADAPTIVE_INLINE.equals(adaptiveType)) {
			recreateAdView();
		}
	}
	
	public void setCollapsible(String collapsibleSetting)
	{
		this.collapsible = collapsibleSetting;
		Log.d(LCAT, "Collapsible setting set to: " + collapsibleSetting);
		// Collapsible is applied during ad load, no need to recreate view
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
	
	public void setExtras(Bundle bundleExtras)
	{
		this.extras = bundleExtras;
		Log.d(LCAT, "Network extras set");
	}

	public boolean isLoaded()
	{
		return isAdLoaded;
	}
	
	public void pause()
	{
		if (adView != null) {
			adView.pause();
			Log.d(LCAT, "Adaptive banner ad paused");
		}
	}
	
	public void resume()
	{
		if (adView != null) {
			adView.resume();
			Log.d(LCAT, "Adaptive banner ad resumed");
		}
	}
	
	public void destroy()
	{
		if (adView != null) {
			adView.destroy();
			adView = null;
			isAdLoaded = false;
			Log.d(LCAT, "Adaptive banner ad destroyed");
			fireAdEvent(TiAdmobUnifiedModule.AD_DESTROYED, null);
		}
	}
	
	private void recreateAdView()
	{
		if (adView != null) {
			// Destroy existing view
			adView.destroy();
			adView = null;
			isAdLoaded = false;
		}
		
		// Create new view with updated properties
		createAdView();
	}

	// Process properties from Titanium proxy
	public void processProperties(KrollDict properties)
	{
		if (properties == null) return;
		
		Log.d(LCAT, "Processing adaptive banner properties");
		
		// Handle adUnitId
		if (properties.containsKeyAndNotNull("adUnitId")) {
			setAdUnitId(TiConvert.toString(properties.get("adUnitId")));
		}
		
		// Handle adaptiveType
		if (properties.containsKeyAndNotNull("adaptiveType")) {
			setAdaptiveType(TiConvert.toString(properties.get("adaptiveType")));
		}
		
		// Handle maxHeight (for inline adaptive banners)
		if (properties.containsKeyAndNotNull("maxHeight")) {
			setMaxHeight(TiConvert.toInt(properties.get("maxHeight")));
		}
		
		// Handle collapsible
		if (properties.containsKeyAndNotNull("collapsible")) {
			setCollapsible(TiConvert.toString(properties.get("collapsible")));
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

	private void fireAdEvent(String eventName, Map<String, Object> data)
	{
		if (data == null) {
			data = new HashMap<>();
		}
		data.put("adUnitId", adUnitId);
		data.put("adaptiveType", adaptiveType);
		Log.d(LCAT, "Firing event: " + eventName);
		proxy.fireEvent(eventName, data);
	}
}