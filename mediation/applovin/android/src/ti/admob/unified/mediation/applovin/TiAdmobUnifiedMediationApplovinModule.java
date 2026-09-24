/**
 * ti.admob.unified.mediation.applovin
 *
 * Copyright (c) 2026 by César Estrada. Licensed under the MIT License.
 */
package ti.admob.unified.mediation.applovin;

import org.appcelerator.kroll.KrollModule;
import org.appcelerator.kroll.annotations.Kroll;

/**
 * Carrier module for the AdMob mediation adapters.
 *
 * It exposes no JavaScript API on purpose. Declaring it in tiapp.xml adds the
 * network adapter coordinate to the application; Google Mobile Ads
 * discovers them at runtime and ti.admob.unified reports them through
 * getMediationStatus(). Every ad call still goes through ti.admob.unified.
 */
@Kroll.module(name = "TiAdmobUnifiedMediationApplovin", id = "ti.admob.unified.mediation.applovin")
public class TiAdmobUnifiedMediationApplovinModule extends KrollModule
{
	public TiAdmobUnifiedMediationApplovinModule()
	{
		super();
	}
}
