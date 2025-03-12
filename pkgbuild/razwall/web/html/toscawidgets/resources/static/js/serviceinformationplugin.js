var serviceinformationplugin_cache_timestamp = 0;

var SERVICEINFORMATION_11 = '<div id="';
var SERVICEINFORMATION_12 = '-information" class="service-messages" style="display:';
var SERVICEINFORMATION_13 = '">';
var SERVICEINFORMATION_21 = '<div class="service-desc"><span class="task-count" id="task-';
var SERVICEINFORMATION_22 = '">0</span>&nbsp;';
var SERVICEINFORMATION_23 = '</div>';
var SERVICEINFORMATION_31 = '<table width="100%" cellspacing="0">'+
    '<tr><td width="60%">&nbsp;</td><th width="20%" align="right">';
var SERVICEINFORMATION_32 = '</th><th width="20%" align="right">';
var SERVICEINFORMATION_33 = '</th></tr>';
var SERVICEINFORMATION_41 = '<tr>'+
    '<td>';
var SERVICEINFORMATION_42 = '</td>'+
    '<td id="task-';
var SERVICEINFORMATION_43 = '-hour" align="right">0</td>'+
    '<td id="task-';
var SERVICEINFORMATION_44 = '-day" align="right">0</td>'+
    '</tr>';
var SERVICEINFORMATION_34 = '</table>';
var SERVICEINFORMATION_14 = '</div>';

function serviceinformationpluginInit(json){
    if(typeof json['services'] !== 'undefinded'){
        for(serviceID in json['services']){
            var service = json['services'][serviceID];
            if(typeof service['ID'] === 'undefined') {
                continue;
            }
            var html = SERVICEINFORMATION_11+service['ID']+SERVICEINFORMATION_12;
            if(service['ON']) {
                html += "block";
            } else {
                html += "none";
            }
            html += SERVICEINFORMATION_13;
            if(typeof service['TASKS']['STATIC'] !== 'undefined'){
                for(taskID in service['TASKS']['STATIC']){
                    if(service['TASKS']['STATIC'][taskID] && typeof service['TASKS']['STATIC'][taskID]['ID'] !== 'undefined'){
                        html += SERVICEINFORMATION_21+service['ID']+"-"+service['TASKS']['STATIC'][taskID]['ID']+
                        SERVICEINFORMATION_22+service['TASKS']['STATIC'][taskID]['DESC']+SERVICEINFORMATION_23;
                    }
                }
            }
            if(typeof service['TASKS']['DYNAMIC'] !== 'undefined'){
                html += SERVICEINFORMATION_31+json['HOUR']+SERVICEINFORMATION_32+json['DAY']+SERVICEINFORMATION_33;
                for(taskID in service['TASKS']['DYNAMIC']){
                    if(service['TASKS']['DYNAMIC'][taskID] && typeof service['TASKS']['DYNAMIC'][taskID]['ID'] !== 'undefined'){
                        var task = service['TASKS']['DYNAMIC'][taskID];
                        html += SERVICEINFORMATION_41+task['DESC'];
                        html += SERVICEINFORMATION_42+service['ID']+"-"+task['ID'];
                        /* Update values with the ones found in COUNT */
                        hour_info = SERVICEINFORMATION_43;
                        if (task.COUNT && task.COUNT[0]) {
                            hour_info = hour_info.replace('>0<', '>' + task.COUNT[0] + '<');
                        }
                        html += hour_info;
                        html += service['ID']+"-"+task['ID'];
                        day_info = SERVICEINFORMATION_44;
                        if (task.COUNT && task.COUNT[1]) {
                            day_info = day_info.replace('>0<', '>' + task.COUNT[1] + '<');
                        }
                        html += day_info;
                    }
                }
                html += SERVICEINFORMATION_34;
            }
            html += SERVICEINFORMATION_14;
            $("#serviceinformationplugin-"+service['ID']+"-information").html(html);
            if(service['ON']) {
                $(".serviceInformation-"+service['ID']+"-on-show").removeClass("serviceInformation-on-show");
            }
            if(!service['ON']){
                var ret = $(".serviceInformation-"+service['ID']+"-on-hide").removeClass("serviceInformation-on-hide");
                ret  = 1;
            }
        }
    }
}

function serviceinformationplugin_openLogs(){
    window.open('/cgi-bin/logs_live.cgi?show=single&nosave=on&showfields=dansguardian,openvpn,smtp,snort,squid',
        '_blank',
        'height=700,width=1000,location=no,menubar=no,scrollbars=yes');
}

function serviceinformationplugin_openLog(field){
    window.open('/cgi-bin/logs_live.cgi?show=single&nosave=on&showfields='+field,
        '_blank',
        'height=700,width=1000,location=no,menubar=no,scrollbars=yes');
}

function serviceinformationplugin_swapVisibility(id) {
    el = document.getElementById(id);
    if(el.style.display != 'block'){
        el.style.display = 'block';
    } else {
        el.style.display = 'none';
    }
} 

function serviceinformationpluginUpdate(json) {
    var oldvalues = false;
    
    try {
        var ts = json['memory/memory-used']['timestamp'];
        if (serviceinformationplugin_cache_timestamp == ts) {
            // cache is unchanged from last request
            // so ignore this call in order not to count
            // things twice
            oldvalues = true;
        }
        serviceinformationplugin_cache_timestamp = ts;
    } catch (e) {// value not cached, ignore it
        econsole.debug("SERVICEINFORMATIONPLUGIN Error occured, ignore: "+e);
    } 
    
    for (var j in json) {
        if (oldvalues) {
            // don't touch counters if these are old cached values
            continue;
        }
        
        var smtp_regex = /tail\-smtp\/connections\-([a-z]+)/;
        var pop_regex = /tail\-pop\/connections\-([a-z]+)/;
        var http_regex = /tail\-http\/connections\-([a-z]+)/;
        if (j == "filecount-postfix_queue/files") {
            try {
                var value = Math.round(json[j]['value']);
                $('#task-postfix-queue').text(value);
            } catch (e) {// ignore it
                econsole.debug("SERVICEINFORMATIONPLUGIN Error occured, ignore: "+e);
            } 
        } else if (j.match(smtp_regex)) {
            var type = RegExp.$1;
            try {
                if (!isNaN(json[j]['value'])) {
                    var value = Math.round(json[j]['value']*5);
                    $('#task-postfix-'+type+'-hour').text(
                      Math.round($('#task-postfix-'+type+'-hour').text())+value);
                    $('#task-postfix-'+type+'-day').text(
                      Math.round($('#task-postfix-'+type+'-day').text())+value);
                  }
            } catch (e) { // ignore it
                econsole.debug("SERVICEINFORMATIONPLUGIN Error occured, ignore: "+e);
            }
        } else if (j.match(pop_regex)) {
            var type = RegExp.$1;
            try {
                if (!isNaN(json[j]['value'])) {
                    var value = Math.round(json[j]['value']*5);
                    $('#task-p3scan-'+type+'-hour').text(
                      Math.round($('#task-p3scan-'+type+'-hour').text())+value);
                    $('#task-p3scan-'+type+'-day').text(
                      Math.round($('#task-p3scan-'+type+'-day').text())+value);
                }
            } catch (e) {// ignore it
                econsole.debug("SERVICEINFORMATIONPLUGIN Error occured, ignore: "+e);
            } 
        } else if (j.match(http_regex)) {
            var type = RegExp.$1;
            try {
                if (!isNaN(json[j]['value'])) {
                    var value = Math.round(json[j]['value']*5);
                    $('#task-squid-'+type+'-hour').text(
                      Math.round($('#task-squid-'+type+'-hour').text())+value);
                    $('#task-squid-'+type+'-day').text(
                      Math.round($('#task-squid-'+type+'-day').text())+value);
                }
            } catch (e) {// ignore it
                econsole.debug("SERVICEINFORMATIONPLUGIN Error occured, ignore: "+e);
            } 
        }
    }
    if (! oldvalues) {
        var date = new Date();
        date.setTime(serviceinformationplugin_cache_timestamp * 1000);
    }
}
