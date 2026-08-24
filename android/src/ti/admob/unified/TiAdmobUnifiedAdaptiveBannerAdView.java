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
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowMetrics;
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

public class TiAdmobUnifiedAdaptiveBannerAdView extends TiUIView
{
	private static final String LCAT = "TiAdmobUnifiedAdaptiveBannerAdView";
	
	private final TiAdmobUnifiedAdaptiveBannerAdProxy bannerProxy;
	private final FrameLayout nativeContainer;
	private AdView adView;
	private boolean isAdLoaded = false;
	private boolean isLoading;
	private boolean isPaused;
	private boolean isDestroyed;
	private boolean pendingLoad;
	private View.OnLayoutChangeListener layoutChangeListener;
	private String adUnitId;
	
	// Adaptive banner specific properties
	private String adaptiveType = TiAdmobUnifiedModule.ADAPTIVE_ANCHORED; // Default
	private int maxHeight = 50; // Default for inline ads
	private String collapsible; // Optional collapsible setting
	
	// Advanced properties
	private String[] keywords;
	private String contentUrl;
	// Identifies what issued the request. Google reserves it for libraries that
	// wrap the SDK, which is exactly what this module is.
	private String requestAgent;
	private Bundle extras;
	
	// Positioning properties
	private int propTop;
	private int propLeft;
	private int propRight;

	@SuppressWarnings("this-escape")
	public TiAdmobUnifiedAdaptiveBannerAdView(TiAdmobUnifiedAdaptiveBannerAdProxy proxy)
	{
		super(proxy);
		bannerProxy = proxy;
		nativeContainer = new FrameLayout(proxy.getActivity());
		setNativeView(nativeContainer);
		Log.d(LCAT, "Adaptive banner view created");
		// Don't create AdView immediately - wait for properties
	}

	private void createAdView()
	{
		if (isDestroyed || adView != null) {
			return;
		}
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
		if (adSize.getHeight() > 0) {
			updateProxyHeight(adSize.getHeight());
		}
		Log.d(LCAT, "Adaptive ad size: " + formatAdSize(activity, adSize));
		
		adView.setAdListener(new com.google.android.gms.ads.AdListener() {
			@Override
			public void onAdLoaded() {
				if (isDestroyed) {
					return;
				}
				Log.d(LCAT, "Adaptive banner ad loaded successfully");
				isLoading = false;
				isAdLoaded = true;
				AdSize loadedAdSize = adView.getAdSize();
				if (loadedAdSize.getHeight() > 0) {
					updateProxyHeight(loadedAdSize.getHeight());
				}
				Map<String, Object> event = buildSizeEvent(activity, loadedAdSize);
				fireAdEvent(TiAdmobUnifiedModule.AD_LOADED, event);
				logAfterLayout(activity, loadedAdSize);
			}

			@Override
			public void onAdFailedToLoad(LoadAdError loadAdError) {
				if (isDestroyed) {
					return;
				}
				Log.e(LCAT, "Adaptive banner ad failed to load: " + loadAdError.getMessage());
				isLoading = false;
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
		nativeContainer.addView(
			adView,
			new FrameLayout.LayoutParams(
				ViewGroup.LayoutParams.MATCH_PARENT,
				ViewGroup.LayoutParams.WRAP_CONTENT));
		Log.d(LCAT, "Adaptive AdView created with unit ID: " + adUnitId);
	}

	private void updateProxyHeight(int heightDp)
	{
		bannerProxy.setPropertyAndFire(TiC.PROPERTY_HEIGHT, heightDp + "dp");
	}

	private void logAfterLayout(Activity activity, AdSize loadedAdSize)
	{
		removeLayoutChangeListener(adView);
		layoutChangeListener = new View.OnLayoutChangeListener() {
			@Override
			public void onLayoutChange(View view, int left, int top, int right, int bottom,
				int oldLeft, int oldTop, int oldRight, int oldBottom)
			{
				if (right <= left || bottom <= top) {
					return;
				}
				removeLayoutChangeListener(view);
				Log.d(
					LCAT,
					"Adaptive dimensions after loaded/postlayout: "
						+ formatAdSize(activity, loadedAdSize)
						+ ", AdView measuredPx=" + view.getMeasuredWidth()
						+ "x" + view.getMeasuredHeight()
						+ ", layoutPx=" + view.getWidth() + "x" + view.getHeight()
						+ ", nativeContainerPx=" + nativeContainer.getWidth()
						+ "x" + nativeContainer.getHeight());
			}
		};
		adView.addOnLayoutChangeListener(layoutChangeListener);
		adView.requestLayout();
	}

	private void removeLayoutChangeListener(View view)
	{
		if (view != null && layoutChangeListener != null) {
			view.removeOnLayoutChangeListener(layoutChangeListener);
		}
		layoutChangeListener = null;
	}

	private Map<String, Object> buildSizeEvent(Activity activity, AdSize adSize)
	{
		DisplayMetrics metrics = activity.getResources().getDisplayMetrics();
		Map<String, Object> event = new HashMap<>();
		event.put("width", adSize.getWidth());
		event.put("height", adSize.getHeight());
		event.put("widthUnit", "dp");
		event.put("heightUnit", "dp");
		event.put("widthPx", adSize.getWidthInPixels(activity));
		event.put("heightPx", adSize.getHeightInPixels(activity));
		event.put("density", metrics.density);
		return event;
	}

	private String formatAdSize(Activity activity, AdSize adSize)
	{
		DisplayMetrics metrics = activity.getResources().getDisplayMetrics();
		return adSize.getWidth() + "x" + adSize.getHeight() + "dp"
			+ ", " + adSize.getWidthInPixels(activity) + "x"
			+ adSize.getHeightInPixels(activity) + "px"
			+ ", density=" + metrics.density;
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
		if (isDestroyed) {
			fireFailure("Banner has been destroyed", 1);
			return;
		}
		if (isPaused) {
			pendingLoad = true;
			return;
		}
		if (isLoading) {
			Log.d(LCAT, "Ignoring duplicate adaptive banner load while a request is active");
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
			adView.pause();
			Log.d(LCAT, "Adaptive banner ad paused");
		}
	}

	public void resume()
	{
		if (isDestroyed || !isPaused) {
			return;
		}
		isPaused = false;
		if (adView != null) {
			adView.resume();
			Log.d(LCAT, "Adaptive banner ad resumed");
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
			removeLayoutChangeListener(viewToDestroy);
			viewToDestroy.setAdListener(null);
			nativeContainer.removeView(viewToDestroy);
			viewToDestroy.destroy();
		}
		Log.d(LCAT, "Adaptive banner ad destroyed");
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
			removeLayoutChangeListener(viewToDestroy);
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

		// Handle requestAgent
		if (properties.containsKeyAndNotNull("requestAgent")) {
			setRequestAgent(TiConvert.toString(properties.get("requestAgent")));
		}
		
		// Handle extras bundle
		if (properties.containsKeyAndNotNull("extras")) {
			setExtras(TiAdmobUnifiedModule.toExtrasBundle((KrollDict) properties.get("extras")));
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
		data.put("adUnitId", adUnitId != null ? adUnitId : "");
		data.put("adType", TiAdmobUnifiedModule.AD_TYPE_BANNER);
		data.put("isAdaptive", true);
		data.put("adaptiveType", adaptiveType);
		Log.d(LCAT, "Firing event: " + eventName);
		proxy.fireEvent(eventName, data);
	}
}
