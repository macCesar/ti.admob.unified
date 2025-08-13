/**
 * Titanium SDK
 * Copyright TiDev, Inc. 04/07/2022-Present
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 *
 * Warning: This file is GENERATED, and should not be modified
 */
package mx.codigomovil.tiadmobunified;

import org.appcelerator.kroll.common.KrollSourceCodeProvider;
import org.appcelerator.kroll.util.KrollAssetHelper;

public class CommonJsSourceProvider implements KrollSourceCodeProvider
{
	public String getSourceCode()
	{
		return getSourceCode("mx.codigomovil.tiadmobunified");
	}

	public String getSourceCode(String module)
	{
		if (module.equals("${moduleid}/mx.codigomovil.tiadmobunified")) {
			module = "mx.codigomovil.tiadmobunified";
		}

		return KrollAssetHelper.readAsset("Resources/mx.codigomovil.tiadmobunified/" + module + ".js");
	}
}
