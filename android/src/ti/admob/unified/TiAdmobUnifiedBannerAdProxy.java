/**
 * ti.admob.unified - Unified AdMob Banner Proxy for Android
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 */

package ti.admob.unified;

import android.util.Log;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.titanium.TiC;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.view.TiUIView;

@Kroll.proxy(creatableInModule = TiAdmobUnifiedModule.class)
public class TiAdmobUnifiedBannerAdProxy extends TiViewProxy
{
	private static final String LCAT = "TiAdmobUnifiedBannerAdProxy";

	public TiAdmobUnifiedBannerAdProxy()
	{
		super();
		Log.d(LCAT, "Banner proxy created");
	}

	@Override
	public TiUIView createView(android.app.Activity activity)
	{
		TiAdmobUnifiedBannerAdView bannerView = new TiAdmobUnifiedBannerAdView(this);
		
		// Apply properties from creation
		if (hasProperty("adUnitId")) {
			bannerView.setAdUnitId(TiConvert.toString(getProperty("adUnitId")));
		}
		if (hasProperty("adSize")) {
			bannerView.setAdSize(TiConvert.toString(getProperty("adSize")));
		}
		
		return bannerView;
	}

	@Kroll.method
	public void load()
	{
		Log.d(LCAT, "Loading banner ad");
		TiUIView view = getOrCreateView();
		if (view instanceof TiAdmobUnifiedBannerAdView) {
			((TiAdmobUnifiedBannerAdView) view).loadAd();
		}
	}

	@Kroll.method
	public void destroy()
	{
		Log.d(LCAT, "Destroying banner ad");
		TiUIView view = peekView();
		if (view instanceof TiAdmobUnifiedBannerAdView) {
			((TiAdmobUnifiedBannerAdView) view).destroy();
		}
	}

	@Kroll.method
	public boolean isLoaded()
	{
		TiUIView view = peekView();
		if (view instanceof TiAdmobUnifiedBannerAdView) {
			return ((TiAdmobUnifiedBannerAdView) view).isLoaded();
		}
		return false;
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
		
		TiUIView view = peekView();
		if (view instanceof TiAdmobUnifiedBannerAdView) {
			((TiAdmobUnifiedBannerAdView) view).setAdUnitId(adUnitId);
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
		
		TiUIView view = peekView();
		if (view instanceof TiAdmobUnifiedBannerAdView) {
			((TiAdmobUnifiedBannerAdView) view).setAdSize(adSize);
		}
	}

	@Override
	public String getApiName()
	{
		return "ti.admob.unified.BannerAd";
	}
}