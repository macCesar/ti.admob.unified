/**
 * Titanium SDK
 * Copyright TiDev, Inc. 04/07/2022-Present
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 *
 * Warning: This file is GENERATED, and should not be modified
 */
var bootstrap = kroll.NativeModule.require("bootstrap"),
	invoker = kroll.NativeModule.require("invoker"),
	Titanium = kroll.binding("Titanium").Titanium;

function moduleBootstrap(moduleBinding) {
	function lazyGet(object, binding, name, namespace) {
		return bootstrap.lazyGet(object, binding,
			name, namespace, moduleBinding.getBinding);
	}

	var module = moduleBinding.getBinding("mx.codigomovil.tiadmobunified.TiAdmobUnifiedModule")["TiAdmobUnified"];
	var invocationAPIs = module.invocationAPIs = [];
	module.apiName = "TiAdmobUnified";

	function addInvocationAPI(module, moduleNamespace, namespace, api) {
		invocationAPIs.push({ namespace: namespace, api: api });
	}

	addInvocationAPI(module, "TiAdmobUnified", "TiAdmobUnified", "createExample");
		if (!("__propertiesDefined__" in module)) {Object.defineProperties(module, {
"Example": {
get: function() {
var Example =  lazyGet(this, "mx.codigomovil.tiadmobunified.ExampleProxy", "Example", "Example");
return Example;
},
configurable: true
},

});
module.constructor.prototype.createExample = function() {
return new module["Example"](arguments);
}
}
module.__propertiesDefined__ = true;
return module;

}
exports.bootstrap = moduleBootstrap;
