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

// Global variables (using objects instead of arrays for keyed access)
var autorefreshwrapper_initCallbacks = {};
var autorefreshwrapper_updateCallbacks = {};
var autorefreshwrapper_initialised = {};
var autorefreshwrapper_started = 0;

// Register (must be done before pageload)
function autorefreshwrapper_register(containerID,      // e.g. "autorefreshwrapper-UpLinkInformationPlugin"
                                    jsInitFunction,   // e.g. "uplinkinformationpluginInit"
                                    initURL,          // e.g. "/cgi-bin/dash.pl?plugin=uplinks"
                                    initParams,       // e.g. null (or an object)
                                    jsUpdateFunction, // e.g. "uplinkinformationpluginUpdate"
                                    updateURL,        // e.g. "/cgi-bin/dash.pl?plugin=uplinks"
                                    updateParams,     // e.g. null (or an object)
                                    loadOnPageLoad,   // e.g. ''
                                    showLoadIndicator,// e.g. "True"
                                    interval) {       // e.g. 5000
    if (autorefreshwrapper_started) {
        return;
    }
    
    // Process init callback
    if (jsInitFunction && initURL) {
        econsole.debug("AUTOREFRESHWRAPPER register init callback: jsInitFunction='" +
                         jsInitFunction + "', initURL='" + initURL);
        
        if (!autorefreshwrapper_initCallbacks[jsInitFunction]) {
            autorefreshwrapper_initCallbacks[jsInitFunction] = {
                "initURL": initURL,
                "initParams": initParams || {},
                "requesting": false,
                "container": containerID,
                "showedLoadIndicator": (showLoadIndicator !== "True")
            };
        } else {
            // Merge the initParams objects
            var existing = autorefreshwrapper_initCallbacks[jsInitFunction]["initParams"];
            if (initParams) {
                Object.keys(initParams).forEach(function(key) {
                    var value = initParams[key];
                    if (!existing[key]) {
                        existing[key] = value;
                    } else {
                        if (typeof existing[key] === 'string') {
                            if (!Array.isArray(value)) {
                                existing[key] = [existing[key], value];
                            } else {
                                value.push(existing[key]);
                                existing[key] = value;
                            }
                        } else { // existing value is assumed to be an array
                            if (typeof value === 'string') {
                                existing[key].push(value);
                            } else {
                                existing[key] = existing[key].concat(value);
                            }
                        }
                    }
                });
            }
            autorefreshwrapper_initCallbacks[jsInitFunction]["initURL"] = initURL;
            autorefreshwrapper_initCallbacks[jsInitFunction]["container"] = containerID;
            autorefreshwrapper_initCallbacks[jsInitFunction]["showedLoadIndicator"] = (showLoadIndicator !== "True");
        }
    }
    
    // Process update callback
    if (jsUpdateFunction && updateURL && interval > 0) {
        econsole.debug("AUTOREFRESHWRAPPER register update callback: jsUpdateFunction='" +
                         jsUpdateFunction + "', updateURL='" + updateURL + "', interval=" + interval);
        if (!autorefreshwrapper_updateCallbacks[jsUpdateFunction]) {
            autorefreshwrapper_updateCallbacks[jsUpdateFunction] = {
                "updateURL": updateURL,
                "updateParams": updateParams || {},
                "interval": interval,
                "requesting": false,
                "loadOnPageLoad": (loadOnPageLoad === "True"),
                "container": containerID,
                "showedLoadIndicator": (showLoadIndicator !== "True")
            };
        } else {
            var existing = autorefreshwrapper_updateCallbacks[jsUpdateFunction]["updateParams"];
            if (updateParams) {
                Object.keys(updateParams).forEach(function(key) {
                    var value = updateParams[key];
                    if (!existing[key]) {
                        existing[key] = value;
                    } else {
                        if (typeof existing[key] === 'string') {
                            if (!Array.isArray(value)) {
                                existing[key] = [existing[key], value];
                            } else {
                                value.push(existing[key]);
                                existing[key] = value;
                            }
                        } else {
                            if (typeof value === 'string') {
                                existing[key].push(value);
                            } else {
                                existing[key] = existing[key].concat(value);
                            }
                        }
                    }
                });
            }
            autorefreshwrapper_updateCallbacks[jsUpdateFunction]["container"] = containerID;
            autorefreshwrapper_updateCallbacks[jsUpdateFunction]["showedLoadIndicator"] = (showLoadIndicator !== "True");
            autorefreshwrapper_updateCallbacks[jsUpdateFunction]["interval"] = interval;
            autorefreshwrapper_updateCallbacks[jsUpdateFunction]["loadOnPageLoad"] = true;
        }
    }
}

// AJAX GET helper using fetch; attaches query parameters to URL.
function ajaxGet(url, params, successCallback) {
    var query = new URLSearchParams(params).toString();
    var fullUrl = url + (url.indexOf('?') === -1 ? '?' : '&') + query;
    fetch(fullUrl, { cache: "no-cache" })
        .then(function(response) {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(function(json) {
            successCallback(json);
			
        })
        .catch(function(error) {
            console.error('Fetch operation problem:', error);
        });
}

function autorefreshwrapper_deliverInit(callback, json) {
    econsole.debug("AUTOREFRESHWRAPPER deliver init for " + callback);
    if (!autorefreshwrapper_initCallbacks[callback]["showedLoadIndicator"]) {
        autorefreshwrapper_initCallbacks[callback]["showedLoadIndicator"] = true;
        var containerElem = document.getElementById(autorefreshwrapper_initCallbacks[callback]["container"]);
        if (containerElem) {
            // Hide loading indicator and show content
            var loadingElems = containerElem.querySelectorAll(".autorefreshwrapper-loading");
            loadingElems.forEach(function(elem) {
                elem.classList.add("autorefreshwrapper-loading-hidden");
            });
            var contentElems = containerElem.querySelectorAll(".autorefreshwrapper-content");
            contentElems.forEach(function(elem) {
                elem.classList.remove("autorefreshwrapper-content-hidden");
            });
        }
    }
    // Call the callback function (assumes it is defined globally)
    window[callback](json);
    autorefreshwrapper_initialised[callback] = true;
}

function autorefreshwrapper_startInit(callback) {
    econsole.debug("AUTOREFRESHWRAPPER start init for " + callback);
    var initCallback = autorefreshwrapper_initCallbacks[callback];
    if (!initCallback["requesting"]) {
        initCallback["requesting"] = true;
        var initData = initCallback["initParams"] || {};
        initData["autorefreshwrapper_callback"] = callback;
        ajaxGet(initCallback["initURL"], initData, function(json) {
            autorefreshwrapper_deliverInit(callback, json);
        });
        initCallback["requesting"] = false;
    }
}

function autorefreshwrapper_deliverUpdate(callback, json) {
    econsole.debug("AUTOREFRESHWRAPPER deliver update for " + callback);
    var updateCallback = autorefreshwrapper_updateCallbacks[callback];
    if (!autorefreshwrapper_initialised[updateCallback["container"]]) {
        econsole.debug("AUTOREFRESHWRAPPER deliver update skip: " + callback + "(json)");
    } else {
        econsole.debug("AUTOREFRESHWRAPPER deliver update eval: " + callback + "(json)");
        window[callback](json);
        if (!updateCallback["showedLoadIndicator"]) {
            updateCallback["showedLoadIndicator"] = true;
            var containerElem = document.getElementById(updateCallback["container"]);
            if (containerElem) {
                var loadingElems = containerElem.querySelectorAll(".autorefreshwrapper-loading");
                loadingElems.forEach(function(elem) {
                    elem.classList.add("autorefreshwrapper-loading-hidden");
                });
                var contentElems = containerElem.querySelectorAll(".autorefreshwrapper-content");
                contentElems.forEach(function(elem) {
                    elem.classList.remove("autorefreshwrapper-content-hidden");
                });
            }
        }
    }
}

function autorefreshwrapper_startUpdate(callback) {
    econsole.debug("AUTOREFRESHWRAPPER start update for " + callback);
    var updateCallback = autorefreshwrapper_updateCallbacks[callback];
    if (!updateCallback["requesting"]) {
        updateCallback["requesting"] = true;
        var updateData = updateCallback["updateParams"] || {};
        updateData["autorefreshwrapper_callback"] = callback;
        ajaxGet(updateCallback["updateURL"], updateData, function(json) {
            autorefreshwrapper_deliverUpdate(callback, json);
        });
        updateCallback["requesting"] = false;
    }
}

function autorefreshwrapper_start() {
    econsole.debug("AUTOREFRESHWRAPPER start");
    autorefreshwrapper_started = 1;
    
    // Start initialization calls
    for (var callback in autorefreshwrapper_initCallbacks) {
        autorefreshwrapper_initialised[ autorefreshwrapper_initCallbacks[callback]["container"] ] = true;
        autorefreshwrapper_startInit(callback);
    }
    
    // Start update loops
    for (var callback in autorefreshwrapper_updateCallbacks) {
        (function(cb) {
            autorefreshwrapper_updateCallbacks[cb].intervalJob = setInterval(function() {
                autorefreshwrapper_startUpdate(cb);
            }, autorefreshwrapper_updateCallbacks[cb]["interval"]);
            if (autorefreshwrapper_updateCallbacks[cb]["loadOnPageLoad"]) {
                autorefreshwrapper_startUpdate(cb);
            }
        })(callback);
    }
}

// Start after DOM load (similar to $(document).ready)
document.addEventListener("DOMContentLoaded", function() {
    setTimeout(autorefreshwrapper_start, 50);
});
