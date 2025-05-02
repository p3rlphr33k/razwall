// Global variables – unchanged.
var NETWORKINFORMATIONPLUGIN_MAX_GRAPH_VALUES = 30;
var NETWORKINFORMATIONPLUGIN_MAX_GRAPH_CHECKED = 6; // overwritten in the dashboard template
var NETWORKINFORMATIONPLUGIN_Y_AXIS_TITLE = 'KB/s'; // overwritten in the dashboard template
var networkinformationplugin_interfaces = {};
var networkinformationplugin_green_colors = ['#00C618','#39E24D','#66E275','#008110','#259433'];
var networkinformationplugin_red_colors = ['#A60800','#BF3730','#FF0D00','#FF4940','#FF7A73'];
var networkinformationplugin_orange_colors = ['#FFC773','#A66300','#BF8630','#FF9900','#FFB240'];
var networkinformationplugin_blue_colors = ['#0C5DA5','#408DD2','#679FD2','#043A6B','#26537C'];
var networkinformationplugin_purple_colors = ['#660BAB','#9440D5','#A668D5','#41046F','#592680'];
var networkinformationplugin_unknown_colors = ['#222222','#555555','#888888','#AAAAAA','#CCCCCC'];
var networkinformationplugin_unknown_count = 0;
var networkinformationplugin_green_count = 0;
var networkinformationplugin_red_count = 0;
var networkinformationplugin_orange_count = 0;
var networkinformationplugin_blue_count = 0;
var networkinformationplugin_purple_count = 0;
var networkinformationplugin_currently_checked = 0;

// New HTML snippet definitions (without checkboxes)
// For both bridge and device rows we create the same structure.
//var NETWORKINFORMATION_ROW_BEGIN = '<tr class="';
//var NETWORKINFORMATION_ROW_END = '</tr>';
// The following cells map to the header order:
// 1. Device cell: display name with its color class.
// 2. Type cell: for example, the device type (e.g. "ethernet").
// 3. Link cell: the link status (e.g. "Up" or "Down").
// 4. "In" cell: fixed width, with a span whose ID is "in-<display>".
// 5. "Out" cell: fixed width, with a span whose ID is "out-<display>".

function networkinformationpluginInit(json) {
  if (typeof json["names"] !== 'undefined' && typeof json["interfaces"] !== 'undefined') {
    var collectd = json["interfaces"]["collectd"];
    var devices = json["interfaces"]["devices"];
    // Assume container is a div with id "networkinformationplugin-information"
    var container = document.getElementById("networkinformationplugin-information");
    if (container) {
      container.innerHTML = "";  // Clear existing content
    }

    var keys = [];
    
    // Loop over devices
    for (var key in devices) {
      if (!devices.hasOwnProperty(key)) continue;
      var interf = devices[key];
      // Skip if no "BRIDGE" information; adjust condition if needed.
      if (typeof interf['BRIDGE'] === 'undefined') continue;
      
      var display = interf['DISPLAY'];
      
      // Create a new div for the primary interface.
      var ifaceDiv = document.createElement("div");
      ifaceDiv.className = "interface";
      
      // Create span for interface name.
      var nameSpan = document.createElement("span");
      nameSpan.className = "interface-name";
      nameSpan.textContent = display;
      ifaceDiv.appendChild(nameSpan);
      
      // Create a span for traffic info with separate spans for In and Out.
      var trafficSpan = document.createElement("span");
      trafficSpan.className = "traffic";
      
      // Create the "In" span with its unique ID.
      var inSpan = document.createElement("span");
      inSpan.id = "in-" + display;
      inSpan.textContent = interf['IN'];  // initial value; could be an empty string if not available
      
      // Create the "Out" span with its unique ID.
      var outSpan = document.createElement("span");
      outSpan.id = "out-" + display;
      outSpan.textContent = interf['OUT'];
      
      // Build traffic text by concatenating: "In: " + <inSpan> + " / Out: " + <outSpan>.
      trafficSpan.appendChild(document.createTextNode("In: "));
      trafficSpan.appendChild(inSpan);
      trafficSpan.appendChild(document.createTextNode(" / Out: "));
      trafficSpan.appendChild(outSpan);
      
      ifaceDiv.appendChild(trafficSpan);
      
      // Create a status span.
      var statusSpan = document.createElement("span");
      // Assume that if interf.STATUS is "Up" (case insensitive) the interface is connected.
      var isConnected = (interf['STATUS'] && interf['STATUS'].toLowerCase() === "up");
      statusSpan.className = "status " + (isConnected ? "connected" : "disconnected");
      statusSpan.textContent = isConnected ? "Connected" : "Disconnected";
      ifaceDiv.appendChild(statusSpan);
      
      // Append the interface div to the container.
      if (container) {
        container.appendChild(ifaceDiv);
      }
      
      // Prepare keys and interface data for graphing.
      keys.push("netlink-" + interf['DEVICE'] + "/if_octets");
      var classCountName = "networkinformationplugin_" + interf['CLASS'] + "_count";
      var classColorsName = "networkinformationplugin_" + interf['CLASS'] + "_colors";
      if (window[classCountName] === window[classColorsName].length) {
        window[classCountName] = 0;
      }
      networkinformationplugin_interfaces[display] = {
        'name': interf['DEVICE'],
        'color': window[classColorsName][ window[classCountName] ],
        'data': { 'rx': [], 'tx': [] },
        'xaxis': { 'ticks': null }
      };
      for (var i = 0; i < NETWORKINFORMATIONPLUGIN_MAX_GRAPH_VALUES; i++) {
        networkinformationplugin_interfaces[display]['data']['rx'].push(0);
        networkinformationplugin_interfaces[display]['data']['tx'].push(0);
      }
      if (interf['CHECKED'] === "checked") {
        if (networkinformationplugin_currently_checked < NETWORKINFORMATIONPLUGIN_MAX_GRAPH_CHECKED) {
          networkinformationplugin_currently_checked++;
        }
      }
      window[classCountName]++;

      // Process physical interfaces if this is a bridge.
      if (interf['BRIDGE'] && typeof interf['PHYSICAL'] !== 'undefined' && interf['PHYSICAL']) {
        for (var devID in interf['PHYSICAL']) {
          if (!interf['PHYSICAL'].hasOwnProperty(devID)) continue;
          var dev = interf['PHYSICAL'][devID];
          var displayDev = dev['DISPLAY'];
          
          var devDiv = document.createElement("div");
          devDiv.className = "interface";
          
          var devNameSpan = document.createElement("span");
          devNameSpan.className = "interface-name";
          devNameSpan.textContent = displayDev;
          devDiv.appendChild(devNameSpan);
          
          var devTrafficSpan = document.createElement("span");
          devTrafficSpan.className = "traffic";
          
          var devInSpan = document.createElement("span");
          devInSpan.id = "in-" + displayDev;
          devInSpan.textContent = dev['IN'];
          
          var devOutSpan = document.createElement("span");
          devOutSpan.id = "out-" + displayDev;
          devOutSpan.textContent = dev['OUT'];
          
          devTrafficSpan.appendChild(document.createTextNode("In: "));
          devTrafficSpan.appendChild(devInSpan);
          devTrafficSpan.appendChild(document.createTextNode(" / Out: "));
          devTrafficSpan.appendChild(devOutSpan);
          devDiv.appendChild(devTrafficSpan);
          
          var devStatusSpan = document.createElement("span");
          var devConnected = (dev['STATUS'] && dev['STATUS'].toLowerCase() === "up");
          devStatusSpan.className = "status " + (devConnected ? "connected" : "disconnected");
          devStatusSpan.textContent = devConnected ? "Connected" : "Disconnected";
          devDiv.appendChild(devStatusSpan);
          
          if (container) {
            container.appendChild(devDiv);
          }
          
          keys.push("netlink-" + dev['DEVICE'] + "/if_octets");
          networkinformationplugin_interfaces[displayDev] = {
            'name': dev['DEVICE'],
            'color': interf['CLASS'],
            'data': { 'rx': [], 'tx': [] },
            'xaxis': { 'ticks': null }
          };
          for (var i = 0; i < NETWORKINFORMATIONPLUGIN_MAX_GRAPH_VALUES; i++) {
            networkinformationplugin_interfaces[displayDev]['data']['rx'].push(0);
            networkinformationplugin_interfaces[displayDev]['data']['tx'].push(0);
          }
          if (dev['CHECKED'] === "checked") {
            if (networkinformationplugin_currently_checked < NETWORKINFORMATIONPLUGIN_MAX_GRAPH_CHECKED) {
              networkinformationplugin_currently_checked++;
            }
          }
        }
      }
    }
    
    // Update autorefresh parameters.
    if (!autorefreshwrapper_updateCallbacks["networkinformationpluginUpdate"]) {
      autorefreshwrapper_updateCallbacks["networkinformationpluginUpdate"] = {};
    }
    autorefreshwrapper_updateCallbacks["networkinformationpluginUpdate"]["updateParams"] = {"keys": keys};
    // Call the update function (for graphing) with the collectd data.
    networkinformationpluginUpdate(collectd);
  }
}

//–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// networkinformationpluginUpdate(json)
//–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
function networkinformationpluginUpdate(json) {
    for (var j in json) {
        if (!json.hasOwnProperty(j)) continue;
        var nic_regex = /netlink\-([\.a-z0-9]+)\/if_octets/;
        if (j.match(nic_regex)) { 
            var nic = RegExp.$1;
            // Replace any dot with underscore.
            nic = nic.replace('.', '_');
            if (nic !== 'lo') {
                try {
                    var rx = parseFloat(json[j]['rx']) / 1000;
                    var rxkb = rx;
                    var rxunit = "KB";
                    if (rx >= 1000) {
                        rx = rx / 1000;
                        rxunit = "MB";
                    }
                    if (rx >= 1000) {
                        rx = rx / 1000;
                        rxunit = "GB";
                    }
                    var tx = parseFloat(json[j]['tx']) / 1000;
                    var txkb = tx;
                    var txunit = "KB";
                    if (tx >= 1000) {
                        tx = tx / 1000;
                        txunit = "MB";
                    }
                    if (tx >= 1000) {
                        tx = tx / 1000;
                        txunit = "GB";
                    }
                    var inElem = document.getElementById('in-' + nic);
                    if (inElem) {
                        inElem.textContent = rx.toFixed(1) + ' ' + rxunit;
                    }
                    var outElem = document.getElementById('out-' + nic);
                    if (outElem) {
                        outElem.textContent = tx.toFixed(1) + ' ' + txunit;
                    }
                    // Maintain a fixed-length array.
                    if (networkinformationplugin_interfaces[nic]['data']['rx'].length >= NETWORKINFORMATIONPLUGIN_MAX_GRAPH_VALUES) {
                        networkinformationplugin_interfaces[nic]['data']['rx'].shift();
                    }
                    networkinformationplugin_interfaces[nic]['data']['rx'].push(rxkb); 
                    if (networkinformationplugin_interfaces[nic]['data']['tx'].length >= NETWORKINFORMATIONPLUGIN_MAX_GRAPH_VALUES) {
                        networkinformationplugin_interfaces[nic]['data']['tx'].shift();
                    }
                    networkinformationplugin_interfaces[nic]['data']['tx'].push(txkb);
                } catch (e) { // Unknown NIC zone; ignore.
                    econsole.debug("NETWORKINFORMATIONPLUGIN Error occured, ignore: " + e);
                }
            }
        }
    }
    networkinformationplugin_updateGraph();
}

//–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// networkinformationplugin_cloneObject()
// Creates a shallow clone of an object.
function networkinformationplugin_cloneObject(what) {
    var clone = [];
    for (var i in what) {
        if (what.hasOwnProperty(i)) {
            clone[i] = what[i];
        }
    }
    return clone;
}

//–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// networkinformationplugin_updateGraph()
// Refreshes the charts with new data.
//–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
function networkinformationplugin_updateGraph() {
    var rxlist = [];
    var txlist = [];
    var options = {
        'yaxis': { 'showLabels': true, 'label': NETWORKINFORMATIONPLUGIN_Y_AXIS_TITLE },
        'xaxis': { 'ticks': [] }
    };
    
    for (var nic in networkinformationplugin_interfaces) {
        if (!networkinformationplugin_interfaces.hasOwnProperty(nic)) continue;
        // Since there are no checkboxes anymore, we assume all interfaces should be graphed.
        if (networkinformationplugin_interfaces[nic]['data']['rx'].length > 0) {
            var dataRx = networkinformationplugin_cloneObject(networkinformationplugin_interfaces[nic]['data']['rx']);
            rxlist.push({
                'label': nic,
                'color': networkinformationplugin_interfaces[nic]['color'],
                'data': dataRx
            });
        }
        if (networkinformationplugin_interfaces[nic]['data']['tx'].length > 0) {
            var dataTx = networkinformationplugin_cloneObject(networkinformationplugin_interfaces[nic]['data']['tx']);
            txlist.push({
                'label': nic,
                'color': networkinformationplugin_interfaces[nic]['color'],
                'data': dataTx
            });
        }
    }
    if (rxlist.length > 0) {
        for (var rx = 0; rx < rxlist.length; rx++) {
            try {
                for (var i = 0; i < rxlist[rx]['data'].length; i++) {
                    rxlist[rx]['data'][i] = [i, rxlist[rx]['data'][i]];
                }
            } catch(e) { 
                econsole.debug("NETWORKINFORMATIONPLUGIN Error occured: " + e);
            }
        }
    }
    if (txlist.length > 0) {
        for (var tx = 0; tx < txlist.length; tx++) {
            try {
                for (var i = 0; i < txlist[tx]['data'].length; i++) {
                    txlist[tx]['data'][i] = [i, txlist[tx]['data'][i]];
                }
            } catch(e) { 
                econsole.debug("NETWORKINFORMATIONPLUGIN Error occured: " + e);
            }
        }
    }
    
    try {
        var rxGraphElem = document.getElementById("live-traffic-graph-rx");
        var txGraphElem = document.getElementById("live-traffic-graph-tx");
        // Assuming $.plot is available from an external library.
        $.plot(rxGraphElem, rxlist, options);
        $.plot(txGraphElem, txlist, options);
    } catch(e) {
        econsole.debug("NETWORKINFORMATIONPLUGIN Error occured: " + e);
    }
}
