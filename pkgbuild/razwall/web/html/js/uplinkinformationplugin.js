// Color definitions
var uplinkinformationplugin_uplink_colors = {
    'offline': '#993333',
    'online': '#339933',
    'pending': '#FF9933',
    'unmanaged': '#666666'
};

// Mapping status to color
var uplinkinformation_status_color = {
    'DEAD': uplinkinformationplugin_uplink_colors['pending'],
    'INACTIVE': uplinkinformationplugin_uplink_colors['offline'],
    'ACTIVE': uplinkinformationplugin_uplink_colors['online'],
    'CONNECTING': uplinkinformationplugin_uplink_colors['pending'],
    'DISCONNECTING': uplinkinformationplugin_uplink_colors['pending'],
    'FAILURE': uplinkinformationplugin_uplink_colors['pending']
};

var UPLINKINFORMATIONPLUGIN_MANAGE_REQUEST = false;
var UPLINKINFORMATIONPLUGIN_UPLINK_HANDLE_REQUEST = false;

//------------------------------------------------------------
// uplinkinformationpluginInit(json)
// Creates a DIV "row" for each uplink and calls updateUplinkStatus()
//------------------------------------------------------------
function uplinkinformationpluginInit(json) {
    if (typeof json['uplinks'] !== 'undefined') {
        // Get the container element (make sure your HTML includes an element with this ID)
        var container = document.getElementById("uplinkinformationplugin-information");
        if (container) {
            container.innerHTML = "";  // Clear any previous content
        }
        // Loop through each uplink in the JSON
        for (var uplinkID in json['uplinks']) {
            if (!json['uplinks'].hasOwnProperty(uplinkID)) continue;
            var uplink = json['uplinks'][uplinkID];

            // Create a DIV to act as a row
            var rowDiv = document.createElement("div");
            rowDiv.className = "uplink-row";
            // Optionally add a class based on level:
            if (uplink['data']['level'] == 0) {
                rowDiv.className += " uplink";
            }
            
            // Build the interface name with indentation
            var nameHTML = "";
            for (var i = 0; i < uplink['data']['level'] - 1; i++) {
                nameHTML += "&nbsp;&nbsp;";
            }
            nameHTML += uplink['data']['name'];
            
            // Create span for the interface name
            var spanInterface = document.createElement("span");
            spanInterface.className = "interface-name";
            spanInterface.innerHTML = nameHTML;
            rowDiv.appendChild(spanInterface);
            
            // Create span for status
            var spanStatus = document.createElement("span");
            spanStatus.className = "uplink-status";
            // We'll assign an ID so it can be updated later
            spanStatus.id = "uplink-" + uplink['name'] + "-status";
            rowDiv.appendChild(spanStatus);
            
            // Create span for uptime
            var spanUptime = document.createElement("span");
            spanUptime.className = "uplink-uptime";
            spanUptime.id = "uplink-" + uplink['name'] + "-uptime";
            rowDiv.appendChild(spanUptime);
            
            // Append the row DIV to the container
            if (container) {
                container.appendChild(rowDiv);
            }
            
            // Update the uplink status and uptime
            updateUplinkStatus(uplink);
        }
    }
}

//------------------------------------------------------------
// uplinkinformationpluginUpdate(json)
// Loops over uplinks and calls updateUplinkStatus() for each.
//------------------------------------------------------------
function uplinkinformationpluginUpdate(json) {
    if (typeof json['uplinks'] !== 'undefined') {
        for (var uplinkID in json['uplinks']) {
            if (json['uplinks'].hasOwnProperty(uplinkID)) {
                var uplink = json['uplinks'][uplinkID];
                updateUplinkStatus(uplink);
            }
        }
    }
}

//------------------------------------------------------------
// updateUplinkStatus(uplink)
// Updates the status and uptime for a given uplink.
//------------------------------------------------------------
function updateUplinkStatus(uplink) {
    var name = uplink['name'];
    // Extract the IP and interface information, if any (not used in display here)
    var ip = "";
    var iface = "";
    try {
        ip = uplink['data']['ip'];
        iface = uplink['data']['interface'];
    } catch (e) {
        if (typeof econsole !== "undefined") {
            econsole.debug("UPLINKINFORMATIONPLUGIN Error occured: " + e);
        } else {
            console.debug("UPLINKINFORMATIONPLUGIN Error occured: " + e);
        }
    }
    
    // Determine the status text; if ACTIVE, display "UP"
    var status = uplink['status'] ? uplink['status'] : "Unknown";
    if (status === "ACTIVE") {
        status = "UP";
    }
    // Retrieve the formatted uptime
    var uptime = uplink['uptime'] ? uplink['uptime'] : "";
    
    // Update the status span text and set the text color
    var elemStatus = document.getElementById("uplink-" + name + "-status");
    if (elemStatus) {
        elemStatus.textContent = status;
        elemStatus.style.color = uplinkinformation_status_color[uplink['status']];
    }
    
    // Update the uptime span text
    var elemUptime = document.getElementById("uplink-" + name + "-uptime");
    if (elemUptime) {
        elemUptime.textContent = uptime;
    }
}

/* 
  The setManaged() and changeUplink() functions (and any image controls)
  have been removed so that this script only displays Interface, Status, and Uptime.
*/
