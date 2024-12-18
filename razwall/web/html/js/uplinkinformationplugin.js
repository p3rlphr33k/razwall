var uplinkinformationplugin_uplink_colors = {
    'offline' : '#993333',
    'online' : '#339933',
    'pending' : '#FF9933',
    'unmanaged' : '#666666'
};

/* mapping status to color */
var uplinkinformation_status_color = {
    'DEAD' : uplinkinformationplugin_uplink_colors['pending'],
    'INACTIVE' : uplinkinformationplugin_uplink_colors['offline'],
    'ACTIVE' : uplinkinformationplugin_uplink_colors['online'],
    'CONNECTING' : uplinkinformationplugin_uplink_colors['pending'],
    'DISCONNECTING' : uplinkinformationplugin_uplink_colors['pending'],
    'FAILURE' : uplinkinformationplugin_uplink_colors['pending']
};

var UPLINKINFORMATIONPLUGIN_MANAGE_REQUEST = false;
var UPLINKINFORMATIONPLUGIN_UPLINK_HANDLE_REQUEST = false;

function uplinkinformationpluginInit(json) {
    if (typeof json['uplinks'] !== 'undefined') {
        for (uplinkID in json['uplinks']) {
            var tr = $("<tr>");
            var uplink = json['uplinks'][uplinkID];
            
            if (uplink['data']['level'] == 0) {
                tr.attr('class', 'uplink');
            }
            
            var name = "";
            for ( var i = 0; i < uplink['data']['level'] - 1; i++) {
                name += "&nbsp;&nbsp;";
            }
            name += uplink['data']['name'];
            tr.append($('<td>').append(name));
            tr.append($('<td>').
                      attr('id', "uplink-" + uplink['name'] + "-ip"));
            tr.append($('<td>').
                      attr('id', "uplink-" + uplink['name'] + "-status"));
            tr.append($('<td>').
                      attr('id', "uplink-" + uplink['name'] + "-uptime"));
            tr.append($('<td>').
                      attr('id', "uplink-" + uplink['name'] + "-active").
                      css('text-align','center'));
            tr.append($('<td>').
                      attr('id', "uplink-" + uplink['name'] + "-managed").
                      css('text-align','center'));
            tr.append($('<td>').
                      attr('id', "uplink-" + uplink['name'] + "-reconnect"));
            $("#uplinkinformationplugin-information").append(tr);
            updateUplinkStatus(uplink);
        }
    }
}


function uplinkinformationpluginUpdate(json) {
    if (typeof json['uplinks'] !== 'undefined') {
        for (uplinkID in json['uplinks']) {
            var uplink = json['uplinks'][uplinkID];
            updateUplinkStatus(uplink);
        }
    }
}

function updateUplinkStatus(uplink) {
    var name = uplink['name'];
    var ip = "";
    var iface = "";
    try {
        ip = uplink['data']['ip'];
        iface = uplink['data']['interface'];
    } catch (e) {
        econsole.debug("UPLINKINFORMATIONPLUGIN Error occured: " + e);
    }
    var managed = uplink['managed'];
    var islinkactive = uplink['isLinkActive'];
    var uptime = uplink['uptime'];
    $('#uplink-' + name + '-uptime').text(uptime);
    var status = uplink['status'];
    if (status == "ACTIVE") {
        $('#uplink-' + name + '-status').text('UP');
    } else {
        $('#uplink-' + name + '-status').text(status);
    }
    $('#uplink-' + name + '-status').css({
        'color' : uplinkinformation_status_color[status]
    });
    $('#uplink-' + name + '-ip').text(ip);
    $('#uplink-' + name + '-interface').text(iface);
    if (managed == 'on') {
        if (!UPLINKINFORMATIONPLUGIN_MANAGE_REQUEST) {
            $('#uplink-' + name + '-managed').html(
                '<a href="javascript: void(0);" ' +
                'onclick="setManaged(\'' + name + '\',false);">' +
                '<img src="/images/on.png" border="0" /></a>');
        }
        if (!UPLINKINFORMATIONPLUGIN_UPLINK_HANDLE_REQUEST) {
            if (islinkactive) {
                $('#uplink-' + name + '-active').html(
                    '<a href="javascript: void(0);" >' +
                    '<img src="/images/on.png" border="0" /></a>');
            } else {
                $('#uplink-' + name + '-active').html(
                    '<a href="javascript: void(0);" >' +
                    '<img src="/images/off.png" border="0" /></a>');
            }
            $('#uplink-' + name + '-reconnect').html(
                '<a href="javascript: void(0);" ' +
                'onclick="changeUplink(\'' + name + '\',\'restart\');">' +
                '<img src="/images/reconnect.png" border="0" alt="' + UPLINK_RECONNECT + '" title="' + UPLINK_RECONNECT + '" /></a>');
        }
    } else {
        if (!UPLINKINFORMATIONPLUGIN_MANAGE_REQUEST) {
            $('#uplink-' + name + '-managed').html(
                '<a href="javascript: void(0);" ' +
                'onclick="setManaged(\'' + name + '\',true);">' +
                '<img src="/images/off.png" border="0" /></a>');
        }
        if (!UPLINKINFORMATIONPLUGIN_UPLINK_HANDLE_REQUEST) {
            if (islinkactive) {
                $('#uplink-' + name + '-active').html(
                    '<a href="javascript: void(0);" ' +
                    'onclick="changeUplink(\'' + name + '\',\'stop\');">' +
                    '<img src="/images/on.png" border="0" /></a>');
            } else {
                $('#uplink-' + name + '-active').html(
                    '<a href="javascript: void(0);" ' +
                    'onclick="changeUplink(\'' + name + '\',\'start\');">' +
                    '<img src="/images/off.png" border="0" /></a>');
            }
            $('#uplink-' + name + '-reconnect').html(
                '<a href="javascript: void(0);" ' +
                'onclick="changeUplink(\'' + name + '\',\'stop\');">' +
                '<img src="/images/reconnect.png" border="0" alt="' + UPLINK_RECONNECT + '" title="' + UPLINK_RECONNECT + '" /></a>');
        }
    }
}

/**
 * Function setManaged Sets a specified uplink to managed or unmanaged and
 * refreshes the uplinks GUI.
 * 
 * @param name
 * @param value
 * 
 * @return void
 */
function setManaged(name, value) {
    var name = name;
    var value = value;
    if (!UPLINKINFORMATIONPLUGIN_MANAGE_REQUEST) {
        UPLINKINFORMATIONPLUGIN_MANAGE_REQUEST = true;
        $('#uplink-' + name + '-managed').html('<img src="/images/indicator.gif" />');
        $.getJSON("/cgi-bin/uplinks-status.cgi?uplink=" + name + "&action=" +
                  (value == true ? 'manage' : 'unmanage'), manageUplink);
    }
    function manageUplink(json) {
        $('#uplink-' + name + '-managed').html(
            '<a href="javascript: void(0);" ' +
            'onclick="setManaged(\'' + name + '\',' + (value == true ? 'false' : 'true') + ');">' +
            '<img src="/images/' + (value == true ? 'on' : 'off') + '.png" border="0" /></a>');
        if (value == true) {
            if (json['isLinkActive']) {
                $('#uplink-' + name + '-active').html(
                    '<a href="javascript: void(0);"><img src="/images/on.png" border="0" /></a>');
            } else {
                $('#uplink-' + name + '-active').html(
                    '<a href="javascript: void(0);"><img src="/images/off.png" border="0" /></a>');
            }
            $('#uplink-' + name + '-reconnect').html(
                $('#uplink-' + name + '-reconnect').html().replace("restart", "stop"));
        } else {
            if (json['isLinkActive']) {
                $('#uplink-' + name + '-active').html(
                    '<a href="javascript: void(0);" ' +
                    'onclick="changeUplink(\'' + name + '\',\'stop\');">' +
                    '<img src="/images/on.png" border="0" /></a>');
            } else {
                $('#uplink-' + name + '-active').html(
                    '<a href="javascript: void(0);" ' +
                    'onclick="changeUplink(\'' + name + '\',\'start\');">' +
                    '<img src="/images/off.png" border="0" /></a>');
            }
            $('#uplink-' + name + '-reconnect').html(
                $('#uplink-' + name + '-reconnect').html().replace("stop", "restart"));
        }
        UPLINKINFORMATIONPLUGIN_MANAGE_REQUEST = false;
    }
}

/**
 * Function changeUplink Activates or deactivates the specified uplink and
 * refreshes the uplinks GUI.
 * 
 * @param name
 * @param action
 * 
 * @return void
 */
function changeUplink(name, action) {
    var name = name;
    // if action is not start or restart set it to stop
    var action = (action == 'start' ? 'start'
            : (action == 'restart' ? 'restart' : 'stop'));
    
    if (!UPLINKINFORMATIONPLUGIN_UPLINK_HANDLE_REQUEST) {
        UPLINKINFORMATIONPLUGIN_UPLINK_HANDLE_REQUEST = true;
        $('#uplink-' + name + '-active').html('<img src="/images/indicator.gif" />');
        $('#uplink-' + name + '-reconnect').html('<img src="/images/indicator.gif" />');
        $.getJSON("/cgi-bin/uplinks-status.cgi?uplink=" + name + "&action=" + action, change);
    }
    
    function change(json) { // will be updated on next update cycle, otherwhise it will show a wront value
        // var status = json['status'];
        // var managed = json['managed'];
        // var pic = (status == 'ACTIVE' ? 'off' : 'on');
        // var act = (status == 'ACTIVE' ? 'stop' : 'start');
        // var stop = (managed == 'on' ? 'restart' : 'stop');
        // $('#uplink-' + name + '-active').html(
        //     '<a href="javascript: void(0);" ' +
        //     'onclick="changeUplink(\'' + name + '\',\'' + act + '\');">' +
        //     '<img src="/images/' + pic + '.png" border="0" /></a>');
        // $('#uplink-' + name + '-reconnect').html(
        //     '<a href="javascript: void(0);" ' +
        //     'onclick="changeUplink(\'' + name + '\',\'' + stop + '\');">' +
        //     '<img src="/images/reconnect.png" border="0" alt="' + UPLINK_RECONNECT + '" title="' + UPLINK_RECONNECT + '" /></a>');
        UPLINKINFORMATIONPLUGIN_UPLINK_HANDLE_REQUEST = false;
    }
}
