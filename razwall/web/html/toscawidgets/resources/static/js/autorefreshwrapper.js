var autorefreshwrapper_initCallbacks = new Array();
var autorefreshwrapper_updateCallbacks = new Array();
var autorefreshwrapper_initialised = new Array()
var autorefreshwrapper_started = 0;

// uncomment to enable debug
//econsole.on();

/*
autorefreshwrapper_register('autorefreshwrapper-UpLinkInformationPlugin',
                                'uplinkinformationpluginInit',
                                '/cgi-bin/dash.pl?plugin=uplinks', 
                                null,
                                'uplinkinformationpluginUpdate',
                                '/cgi-bin/dash.pl?plugin=uplinks',
                                null,
                                '',
                                'True',
                                5000);
*/								
// functions must be registered before pageload!!!
function autorefreshwrapper_register(containerID, 		// autorefreshwrapper-UpLinkInformationPlugin
                                     jsInitFunction,	// uplinkinformationpluginInit
                                     initURL, 			// cgi-bin/dash.pl?plugin=uplinks
                                     initParams, 		// null
                                     jsUpdateFunction, 	// uplinkinformationpluginUpdate
                                     updateURL, 		// cgi-bin/dash.pl?plugin=uplinks
                                     updateParams, 		// null
                                     loadOnPageLoad, 	// ''
                                     showLoadIndicator, // True
                                     interval){ 		// 5000
    
    if(autorefreshwrapper_started) {
        return;
		//console.log('wrapper started');
    }
    
    if(jsInitFunction && initURL) {
        econsole.debug("AUTOREFRESHWRAPPER register init callback: jsInitFunction='" +
                    jsInitFunction + "', initURL='" + initURL);
        
        if(!autorefreshwrapper_initCallbacks[jsInitFunction]) {
            autorefreshwrapper_initCallbacks[jsInitFunction] = {
                "initURL" : initURL,
                "initParams" : initParams,
                "requesting" : false,
                "container" : containerID,
                "showedLoadIndicator" : showLoadIndicator != "True"
            }
        } else {
            $.each(initParams, function(key, value) {
                if (!autorefreshwrapper_initCallbacks[jsInitFunction]["initParams"][key]) {
                    autorefreshwrapper_initCallbacks[jsInitFunction]["initParams"][key] = value;
                } else {
                    if($.isString(autorefreshwrapper_initCallbacks[jsInitFunction]["initParams"][key])) {
                        if(!$.isArray(value)) {
                            autorefreshwrapper_initCallbacks[jsInitFunction]["initParams"][key] = [autorefreshwrapper_initCallbacks[jsInitFunction]["initParams"][key], value];
                        } else {
                            value.push(autorefreshwrapper_initCallbacks[jsInitFunction]["initParams"][key]);
                            autorefreshwrapper_initCallbacks[jsInitFunction]["initParams"][key] = value;
                        }
                    } else {
                        if($.isString(value)) {
                            autorefreshwrapper_initCallbacks[jsInitFunction]["initParams"][key].push(value);
                        } else {
                            $.merge(autorefreshwrapper_initCallbacks[jsInitFunction]["initParams"][key], value);
                        }
                    }
                }
            });
            autorefreshwrapper_initCallbacks[jsInitFunction]["initURL"] = initURL; // was updateURL???
            autorefreshwrapper_initCallbacks[jsInitFunction]["container"] = containerID;
            autorefreshwrapper_initCallbacks[jsInitFunction]["showedLoadIndicator"] = showLoadIndicator != "True";
        }
    }
    
    if(jsUpdateFunction && updateURL && interval > 0) {
        econsole.debug("AUTOREFRESHWRAPPER register update callback: jsUpdateFunction='" +
                    jsUpdateFunction + "', updateURL='"+updateURL+"', interval="+interval);
        if(!autorefreshwrapper_updateCallbacks[jsUpdateFunction]) {
            autorefreshwrapper_updateCallbacks[jsUpdateFunction] = {
                "updateURL" : updateURL,
                "updateParams" : updateParams,
                "interval" : interval,
                "requesting" : false,
                "loadOnPageLoad" : loadOnPageLoad == "True",
                "container" : containerID,
                "showedLoadIndicator" : showLoadIndicator != "True"
            };
        } else {
            $.each(updateParams, function(key, value) {
                if (!autorefreshwrapper_updateCallbacks[jsUpdateFunction]["updateParams"][key]) {
                    autorefreshwrapper_updateCallbacks[jsUpdateFunction]["updateParams"][key] = value;
                } else {
                    if($.isString(autorefreshwrapper_updateCallbacks[jsUpdateFunction]["updateParams"][key])) {
                        if(!$.isArray(value)) {
                            autorefreshwrapper_updateCallbacks[jsUpdateFunction]["updateParams"][key] = [autorefreshwrapper_updateCallbacks[jsUpdateFunction]["updateParams"][key], value];
                        } else {
                            value.push(autorefreshwrapper_updateCallbacks[jsUpdateFunction]["updateParams"][key]);
                            autorefreshwrapper_updateCallbacks[jsUpdateFunction]["updateParams"][key] = value;
                        }
                    } else {
                        if($.isString(value)) {
                            autorefreshwrapper_updateCallbacks[jsUpdateFunction]["updateParams"][key].push(value);
                        } else {
                            $.merge(autorefreshwrapper_updateCallbacks[jsUpdateFunction]["updateParams"][key], value);
                        }
                    }
                }
            });
            autorefreshwrapper_updateCallbacks[jsUpdateFunction]["container"] = containerID;
            autorefreshwrapper_updateCallbacks[jsUpdateFunction]["showedLoadIndicator"] = showLoadIndicator != "True";
            autorefreshwrapper_updateCallbacks[jsUpdateFunction]["interval"] = interval;
            autorefreshwrapper_updateCallbacks[jsUpdateFunction]["loadOnPageLoad"] = true;
        }
    }
}

function autorefreshwrapper_deliverInit(callback, json){
    econsole.debug("AUTOREFRESHWRAPPER deliver init for " + callback);
    if(!autorefreshwrapper_initCallbacks[callback]["showedLoadIndicator"]) {
        autorefreshwrapper_initCallbacks[callback]["showedLoadIndicator"] = true;
        $("#" + autorefreshwrapper_initCallbacks[callback]["container"] + " .autorefreshwrapper-loading")
            .addClass("autorefreshwrapper-loading-hidden");
        $("#" + autorefreshwrapper_initCallbacks[callback]["container"] + " .autorefreshwrapper-content")
            .removeClass("autorefreshwrapper-content-hidden");
    }
    eval(callback+"(json)");
    autorefreshwrapper_initialised[callback] = true;
}

function autorefreshwrapper_startInit(callback){
    econsole.debug("AUTOREFRESHWRAPPER start init for " + callback);
    if (!autorefreshwrapper_initCallbacks[callback]["requesting"]) {
        autorefreshwrapper_initCallbacks[callback]["requesting"] = true;
        var initData = autorefreshwrapper_initCallbacks[callback]["initParams"];
        if (!initData) {
            initData = {};
        }
        initData["autorefreshwrapper_callback"] = callback;
        $.ajax({
            url: autorefreshwrapper_initCallbacks[callback]["initURL"],
            type: 'GET',
            dataType: 'json',
            cache: false,
            data: initData,
            success: function(json) {
                autorefreshwrapper_deliverInit(callback, json);
            }
        });
        autorefreshwrapper_initCallbacks[callback]["requesting"] = false;
    }
}

function autorefreshwrapper_deliverUpdate(callback, json){
    econsole.debug("AUTOREFRESHWRAPPER deliver update for "+callback);
    if(!autorefreshwrapper_initialised[autorefreshwrapper_updateCallbacks[callback]["container"]]) {
        econsole.debug("AUTOREFRESHWRAPPER deliver update skip: " + callback + "(json)");
    }
    else {
        econsole.debug("AUTOREFRESHWRAPPER deliver update eval: " + callback + "(json)")
        eval(callback + "(json)");
        if(!autorefreshwrapper_updateCallbacks[callback]["showedLoadIndicator"]) {
            autorefreshwrapper_updateCallbacks[callback]["showedLoadIndicator"] = true;
            $("#" + autorefreshwrapper_updateCallbacks[callback]["container"] + " .autorefreshwrapper-loading")
                .addClass("autorefreshwrapper-loading-hidden");
            $("#" + autorefreshwrapper_updateCallbacks[callback]["container"] + " .autorefreshwrapper-content")
                .removeClass("autorefreshwrapper-content-hidden");
        }
    }

}

function autorefreshwrapper_startUpdate(callback){
    econsole.debug("AUTOREFRESHWRAPPER start update for " + callback);
    if (!autorefreshwrapper_updateCallbacks[callback]["requesting"]) {
        autorefreshwrapper_updateCallbacks[callback]["requesting"] = true;
        var updateData = autorefreshwrapper_updateCallbacks[callback]["updateParams"];
        if (!updateData) {
            updateData = {};
        }
        updateData["autorefreshwrapper_callback"] = callback;
        $.ajax({
            url: autorefreshwrapper_updateCallbacks[callback]["updateURL"],
            type: 'GET',
            dataType: 'json',
            cache: false,
            data: updateData,
            success: function(json) {
				//console.log('JSON GOTTEN! ' + json);
                autorefreshwrapper_deliverUpdate(callback, json);
            }
        });
        autorefreshwrapper_updateCallbacks[callback]["requesting"] = false;
    }
}

function autorefreshwrapper_start(){
    econsole.debug("AUTOREFRESHWRAPPER start");
    autorefreshwrapper_started = 1;
    for(callback in autorefreshwrapper_initCallbacks) {
        autorefreshwrapper_initialised[autorefreshwrapper_initCallbacks[callback]["container"]] = true;
        autorefreshwrapper_startInit(callback);
    }
    for(callback in autorefreshwrapper_updateCallbacks) {
        /* Need to use a string.  Not nice, but it's the only solution that
	 * works for every browser. */
	var funct_to_call = 'autorefreshwrapper_startUpdate("' + callback + '")';
        autorefreshwrapper_updateCallbacks[callback].intervalJob = setInterval(funct_to_call,
				autorefreshwrapper_updateCallbacks[callback]["interval"]
	);
        if(autorefreshwrapper_updateCallbacks[callback]["loadOnPageLoad"]) {
            autorefreshwrapper_startUpdate(callback);
        }
    }
}

$(document).ready(function() {
    setTimeout("autorefreshwrapper_start()",50);
});
