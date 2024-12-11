
var NETWORKINFORMATIONPLUGIN_MAX_GRAPH_VALUES = 30;
var NETWORKINFORMATIONPLUGIN_MAX_GRAPH_CHECKED = 6; // this value is overwritten in the dashboard template
var NETWORKINFORMATIONPLUGIN_Y_AXIS_TITLE = 'KB/s'; // this value is overwritten in the dashboard template
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

var NETWORKINFORMATION_11 = '<tr class="bridge">'+
    '<td>'+
    '<input type="checkbox" class="graph_checkbox"'+ 
    'onclick="networkinformationplugin_checkCheckboxes(\'if-checkbox-';
var NETWORKINFORMATION_12 ='\');"'+
    'id="if-checkbox-';
var NETWORKINFORMATION_13 = '" checked="checked"/>';
var NETWORKINFORMATION_14 = '" />';
var NETWORKINFORMATION_15 = '</td>'+
    '<td class="';
var NETWORKINFORMATION_16 = '">';
var NETWORKINFORMATION_17 = '</td>'+
    '<td>';
var NETWORKINFORMATION_18 = '</td>'+
    '<td>';
var NETWORKINFORMATION_19 = '</td>'+
    '<td>';
var NETWORKINFORMATION_20 = '</td>'+
    '<td width="60px"><span id="in-';
var NETWORKINFORMATION_21 = '">';
var NETWORKINFORMATION_22 = '</span></td>'+
    '<td width="60px"><span id="out-';
var NETWORKINFORMATION_23 = '">';
var NETWORKINFORMATION_24 = '</span></td>'+
    '</tr>';
var NETWORKINFORMATION_31 = '<tr class="device">'+
    '<td>'+
    '<input type="checkbox" class="graph_checkbox"'+ 
    'onclick="networkinformationplugin_checkCheckboxes(\'if-checkbox-';
var NETWORKINFORMATION_41 = '<tr>'+
    '<td>'+
    '<input type="checkbox" class="graph_checkbox"'+ 
    'onclick="networkinformationplugin_checkCheckboxes(\'if-checkbox-';

function networkinformationpluginInit(json) {
    if(typeof json["names"] !== 'undefined' && typeof json["interfaces"] !== 'undefined'){
        collectd = json["interfaces"]["collectd"];
        devices = json["interfaces"]["devices"];
        var html = "";
        var keys = [];
        $.each(devices, function(key, interf){
            if(typeof interf['BRIDGE'] !== 'undefined'){
                // create html for bridge device
                var display = interf['DISPLAY'];
                if(interf['BRIDGE']) {
                    html += NETWORKINFORMATION_11;
                }
                else {
                    html += NETWORKINFORMATION_31;
                }
                html += display+NETWORKINFORMATION_12+display;
                if(interf['CHECKED']){
                    html += NETWORKINFORMATION_13;
                } else {
                    html += NETWORKINFORMATION_14;
                }
                html += NETWORKINFORMATION_15+interf['CLASS'];
                html += NETWORKINFORMATION_16+interf['DEVICE'];
                html += NETWORKINFORMATION_17+interf['TYPE'];
                html += NETWORKINFORMATION_18+interf['LINK'];
                html += NETWORKINFORMATION_19+interf['STATUS'];
                html += NETWORKINFORMATION_20+display;
                html += NETWORKINFORMATION_21+interf['IN'];
                html += NETWORKINFORMATION_22+display;
                html += NETWORKINFORMATION_23+interf['OUT'];
                html += NETWORKINFORMATION_24;
                
                if(interf['BRIDGE'] && typeof interf['PHYSICAL'] !== 'undefined' && interf['PHYSICAL']){
                    // iterate over all bridge devices
                    for(devID in interf['PHYSICAL']){
                        var dev = interf['PHYSICAL'][devID];
                        
                        // create html for physical devices of bridge device
                        var display = dev['DISPLAY'];
                        html += NETWORKINFORMATION_41+display+NETWORKINFORMATION_12+display;
                        if(dev['CHECKED']) {
                            html += NETWORKINFORMATION_13;
                        } else {
                            html += NETWORKINFORMATION_14;
                        }
                        html += NETWORKINFORMATION_15+interf['CLASS'];
                        html += NETWORKINFORMATION_16+dev['DEVICE'];
                        html += NETWORKINFORMATION_17+dev['TYPE'];
                        html += NETWORKINFORMATION_18+dev['LINK'];
                        html += NETWORKINFORMATION_19+dev['STATUS'];
                        html += NETWORKINFORMATION_20+display;
                        html += NETWORKINFORMATION_21+dev['IN'];
                        html += NETWORKINFORMATION_22+display;
                        html += NETWORKINFORMATION_23+dev['OUT'];
                        html += NETWORKINFORMATION_24;
                    }
                }
            }
        });
        
        $("#networkinformationplugin-information").html(html);
        
        $.each(devices, function(key, interf){
            keys.push("netlink-" + interf['DEVICE'] + "/if_octets");
            if(eval("networkinformationplugin_"+interf['CLASS']+"_count == networkinformationplugin_"+interf['CLASS']+"_colors.length")) {
                eval("networkinformationplugin_"+interf['CLASS']+"_count = 0");
            }
            networkinformationplugin_interfaces[interf['DISPLAY']] = {
                'name':interf['DEVICE'],
                'color':eval("networkinformationplugin_"+interf['CLASS']+"_colors[networkinformationplugin_"+interf['CLASS']+"_count]"),
                'data':{'rx':[],'tx':[]},
                'xaxis':{'ticks':null}
            };
            for (var i = 0; i  < NETWORKINFORMATIONPLUGIN_MAX_GRAPH_VALUES; i++) {
                networkinformationplugin_interfaces[interf['DISPLAY']]['data']['rx'].push(0);
                networkinformationplugin_interfaces[interf['DISPLAY']]['data']['tx'].push(0);
            }
            if (interf['CHECKED'] != "checked") {
                networkinformationplugin_currently_checked = networkinformationplugin_currently_checked;
            }
            else if (networkinformationplugin_currently_checked < NETWORKINFORMATIONPLUGIN_MAX_GRAPH_CHECKED) {
                networkinformationplugin_currently_checked++;
            } else {
                $('#if-checkbox-'+interf['DISPLAY']).attr('checked',false);
                $('.graph_checkbox').each(function() {
                    if (! $(this).attr('checked')) {
                        $(this).attr('disabled','disabled');
                    }
                });
            }
            eval("networkinformationplugin_"+interf['CLASS']+"_count++");
            
            if(typeof interf['BRIDGE'] !== 'undefined' && interf['BRIDGE'] && 
                typeof interf['PHYSICAL'] !== 'undefined' && interf['PHYSICAL']){
                
                for(devID in interf['PHYSICAL']){
                    var dev = interf['PHYSICAL'][devID];
                    keys.push("netlink-" + dev['DEVICE'] + "/if_octets");
                    networkinformationplugin_interfaces[dev['DISPLAY']] = {
                       'name':dev['DEVICE'],
                       'color':interf['CLASS'],
                       'data':{'rx':[],'tx':[]},
                       'xaxis':{'ticks':null}
                    };
                    for (var i = 0; i  < NETWORKINFORMATIONPLUGIN_MAX_GRAPH_VALUES; i++) {
                       networkinformationplugin_interfaces[dev['DISPLAY']]['data']['rx'][i] = 0;
                       networkinformationplugin_interfaces[dev['DISPLAY']]['data']['tx'][i] = 0;
                    }
                    if (dev['CHECKED'] != "checked") {
                        networkinformationplugin_currently_checked = networkinformationplugin_currently_checked;
                    } else if (networkinformationplugin_currently_checked < NETWORKINFORMATIONPLUGIN_MAX_GRAPH_CHECKED) {
                        networkinformationplugin_currently_checked++;
                    } else {
                        $('#if-checkbox-'+dev['DISPLAY']).attr('checked',false);
                        $('.graph_checkbox').each(function() {
                            if (! $(this).attr('checked')) {
                                $(this).attr('disabled','disabled');
                            }
                        });
                    }
                }
            }
        });
        if(!autorefreshwrapper_updateCallbacks["networkinformationpluginUpdate"]) {
            autorefreshwrapper_updateCallbacks["networkinformationpluginUpdate"] = {};
        }
        autorefreshwrapper_updateCallbacks["networkinformationpluginUpdate"]["updateParams"] = {"keys" : keys};
        networkinformationpluginUpdate(collectd);
    }
}

/**
 * Function checkCheckboxes
 * Makes sure that not more than NETWORKINFORMATIONPLUGIN_MAX_GRAPH_CHECKED checkboxes are checked.
 * If NETWORKINFORMATIONPLUGIN_MAX_GRAPH_CHECKED checkboxes have been checked the others will be disabled
 * until one is unchecked.
 * 
 * @param id
 * 
 * @return void
 */
function networkinformationplugin_checkCheckboxes(id) {
    try {
        var el = document.getElementById(id);
        if (el.checked && !el.disabled) {
            networkinformationplugin_currently_checked++;
            if (networkinformationplugin_currently_checked >= NETWORKINFORMATIONPLUGIN_MAX_GRAPH_CHECKED) { 
                var boxes = $('input.graph_checkbox').get();
                for (var box in boxes) {
                    if (!boxes[box].checked) {
                        boxes[box].disabled = true;
                    }
                }
            }
        } else if (!el.checked) {
            networkinformationplugin_currently_checked--;
            networkinformationplugin_currently_checked = Math.max(0,networkinformationplugin_currently_checked);
            if (networkinformationplugin_currently_checked < NETWORKINFORMATIONPLUGIN_MAX_GRAPH_CHECKED) { 
                var boxes = $('input.graph_checkbox').get();
                for (var box in boxes) {
                    if (boxes[box].disabled) {
                        boxes[box].disabled = false;
                    }
                }
            }
        }
    } catch(e) {
        econsole.debug("NETWORKINFORMATIONPLUGIN Error occured: "+e);
    }
}

function networkinformationpluginUpdate(json) {
    for (var j in json) {
        var nic_regex = /netlink\-([\.a-z0-9]+)\/if_octets/;
        if (j.match(nic_regex)) { 
            var nic = RegExp.$1;
            nic = nic.replace('.','_');
            if (nic != 'lo') {
                try {
                    rx = (parseFloat(json[j]['rx']) / 1000);
                    var rxkb = rx;
                    rxunit = "KB/s";
                    if (rx >= 1000) {
                        rx = rx / 1000;
                        rxunit = "MB/s";
                    }
                    if (rx >= 1000) {
                        rx = rx / 1000;
                        rxunit = "GB/s";
                    }
                    tx = (parseFloat(json[j]['tx']) / 1000);
                    var txkb = tx;
                    txunit = "KB/s";
                    if (tx >= 1000) {
                        tx = tx / 1000;
                        txunit = "MB/s";
                    }
                    if (tx >= 1000) {
                        tx = tx / 1000;
                        txunit = "GB/s";
                    }
                    $('#in-'+nic).text(rx.toFixed(1) + ' ' + rxunit);
                    $('#out-'+nic).text(tx.toFixed(1) + ' ' + txunit);
                    if (networkinformationplugin_interfaces[nic]['data']['rx'].length >= NETWORKINFORMATIONPLUGIN_MAX_GRAPH_VALUES) {
                        networkinformationplugin_interfaces[nic]['data']['rx'].shift();
                    }
                    networkinformationplugin_interfaces[nic]['data']['rx'].push(rxkb); 
                    if (networkinformationplugin_interfaces[nic]['data']['tx'].length >= NETWORKINFORMATIONPLUGIN_MAX_GRAPH_VALUES) {
                        networkinformationplugin_interfaces[nic]['data']['tx'].shift();
                    }
                    networkinformationplugin_interfaces[nic]['data']['tx'].push(txkb);
                } catch (e) { // going here means the nic-zone is unkown, ignore
                    econsole.debug("NETWORKINFORMATIONPLUGIN Error occured, ignore: "+e);
                }
            }
        }
    }
    networkinformationplugin_updateGraph();
}

/**
 * Function cloneObject
 * Makes a copy of an object instead of referencing it.
 * 
 * @param what
 * 
 * @return clone
 */
function networkinformationplugin_cloneObject(what) {
    var clone = [];
    for (i in what) {
        clone[i] = what[i];
    }
    return clone;
}

/**
 * Function updateGraph
 * Is called by updateGUI and refreshes the charts with the new data. 
 * 
 * @return void
 */
function networkinformationplugin_updateGraph() {
    var rxlist = [];
    var txlist = [];
    var options = {
        'yaxis': {'showLabels': true, 'label': NETWORKINFORMATIONPLUGIN_Y_AXIS_TITLE},
        'xaxis': {'ticks': new Array()}
    };
    
    for (nic in networkinformationplugin_interfaces) {
        if ($('#if-checkbox-'+nic).attr('checked')) {
            if (networkinformationplugin_interfaces[nic]['data']['rx'].length > 0) {
                data = networkinformationplugin_cloneObject(networkinformationplugin_interfaces[nic]['data']['rx']);
                rxlist.push({'label':nic,
                             'color':networkinformationplugin_interfaces[nic]['color'],
                             'data':data});
            }
            if (networkinformationplugin_interfaces[nic]['data']['tx'].length > 0) {
                data = networkinformationplugin_cloneObject(networkinformationplugin_interfaces[nic]['data']['tx']);
                txlist.push({'label':nic,
                             'color':networkinformationplugin_interfaces[nic]['color'],
                             'data':data});
            }
        }
    }
    if (rxlist.length > 0) {
        for (rx = 0; rx < rxlist.length; rx++) {
            try {
                for (i = 0; i < rxlist[rx]['data'].length; i++) {
                    rxlist[rx]['data'][i] = [i,rxlist[rx]['data'][i]]; 
                }
            }
            catch(e) { 
                econsole.debug("NETWORKINFORMATIONPLUGIN Error occured: "+e);
            }
        }
    }
    if (txlist.length > 0) {
        for (tx = 0; tx < txlist.length; tx++) {
            try {
                for (i = 0; i < txlist[tx]['data'].length; i++) {
                    txlist[tx]['data'][i] = [i,txlist[tx]['data'][i]]; 
                }
            }
            catch(e) { 
                econsole.debug("NETWORKINFORMATIONPLUGIN Error occured: "+e);
            }
        }
    }
    
    try {
        $.plot($("#live-traffic-graph-rx"), rxlist, options);
        $.plot($("#live-traffic-graph-tx"), txlist, options);
    } catch(e) {
        econsole.debug("NETWORKINFORMATIONPLUGIN Error occured: "+e);
    }
}
