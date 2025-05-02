function customShowForm() {
    $(".redtype").hide();
    $("div.uplinktypes").hide();
    var network_type = $("select[name=NETWORK_TYPE]").val();
    var type = "";
    var dns = $("input[name=DNS]").get(0).checked;
    var protocol = $("select[name=PROTOCOL]").attr("value");
    var method = $("select[name=METHOD]").attr("value");
    var mac = $("input[name=MACACTIVE]").get(0).checked;
    var checkhosts = $("input[name=LINKCHECK]").get(0).checked;
    var ips = $("input[name=RED_IPS_ACTIVE]").get(0).checked;
    
    if (network_type == "ROUTED") {
        $(".redtype").show();
        type = $("select[name=RED_TYPE]").val();
    } else if (network_type == "BRIDGED") {
        type = "STEALTH";
    } else {
        type = "NONE";
    }
    if (type == "") {
        type = "NONE";
    }
    
    if (checkhosts == true) {
        $("#uplinkcheckhosts").show();
    } else {
        $("#uplinkcheckhosts").hide();
    }
    
    if (type == "NONE") {
        $("#uplinkgateway").show();
        $("#uplinkmanualdns").show();
    } else if (type == "STEALTH") {
        $("#uplinkstealthdevice").show();
        $("#uplinkgateway").show();
        $("#uplinkmanualdns").show();
    } else if (type == "STATIC") {
        $("#uplinkdevice").show();
        $("#uplinkaddress").show();
        $("#uplinkipsactive").show();
        if (ips == true) {
            $("#uplinkips").show();
        }
        $("#uplinkgateway").show();
        $("#uplinkmanualdns").show();
        $("#uplinkmacactive").show();
        if (mac == true) {
            $("#uplinkmac").show();
        }
    } else if (type == "DHCP") {
        $("#uplinkdevice").show();
        $("#uplinkdns").show();
        if (dns == true) {
            $("#uplinkmanualdns").show();
        }
        $("#uplinkmacactive").show();
        if (mac == true) {
            $("#uplinkmac").show();
        }
    } else if (type == "PPPOE") {
        $("#uplinkipsactive").show();
        if (ips == true) {
            $("#uplinkips").show();
        }
        $("#uplinkdevice").show();
        $("#uplinkuserpass").show();
        $("#uplinkauth").show();
        $("#uplinkdns").show();
        if (dns == true) {
            $("#uplinkmanualdns").show();
        }
        $("#uplinkconcentrator").show();
        $("#uplinkmacactive").show();
        if (mac == true) {
            $("#uplinkmac").show();
        }
    } else if (type == "PPTP") {
        $("#uplinkdevice").show();
        $("#uplinkmethod").show();
        $("#uplinkphonenumber").show();
        $("#uplinkuserpass").show();
        $("#uplinkauth").show();
        if (method == "STATIC") {
            $("#uplinkaddress").show();
            $("#uplinkipsactive").show();
            if (ips == true) {
                $("#uplinkips").show();
            }
            $("#uplinkgateway").show();
        } else {
            $("#uplinkdns").show();
        }
        if (dns == true) {
            $("#uplinkmanualdns").show();
        }
        $("#uplinkmacactive").show();
        if (mac == true) {
            $("#uplinkmac").show();
        }
    } else if (type == "ADSL") {
        $("#uplinkipsactive").show();
        if (ips == true) {
            $("#uplinkips").show();
        }
        $("#uplinkprotocol").show();
        $("#uplinkvcivpi").show();
        $("#uplinkencap").show();
        if (protocol == "STATIC") {
            $("#uplinkaddress").show();
            $("#uplinkgateway").show();
            $("#uplinkmanualdns").show();
        } else {
            $("#uplinkdns").show();
            if (dns == true) {
                $("#uplinkmanualdns").show();
            }
            if (protocol == "RFC2364" || protocol == "RFC1483") {
                $("#uplinkadsltype").show();
                $("#uplinkuserpass").show();
                $("#uplinkauth").show();
            }
        }
    } else if (type == "ISDN") {
        $("#uplinkipsactive").show();
        if (ips == true) {
            $("#uplinkips").show();
        }
        $("#uplinkisdntype").show();
        $("#uplinkphonenumber").show();
        $("#uplinkuserpass").show();
        $("#uplinkmsn").show();
        $("#uplinkauth").show();
        $("#uplinkdns").show();
        if (dns == true) {
            $("#uplinkmanualdns").show();
        }
    } else if (type == "ANALOG") {
        $("#uplinkipsactive").show();
        if (ips == true) {
            $("#uplinkips").show();
        }
        $("#uplinkcomport").show();
        $("#uplinkmodemtype").show();
        $("#uplinkuserpass").show();
        $("#uplinkauth").show();
        $("#uplinkspeeds").show();
        $("#uplinkdns").show();
        if ($("select[name=MODEMTYPE]").get(0).selectedIndex == 0) {
            // if it is an analog modem we need the phonenumber
            $("#uplinkphonenumber").show();
        } else if ($("select[name=MODEMTYPE]").get(0).selectedIndex == 1) {
            // if it is an umts modem we need the apn
            $("#uplinkapn").show();
        }
        if (dns == true) {
            $("#uplinkmanualdns").show();
        }
    } else if (type == "MODEM") {
        $("#uplink_mm_modems").show();
        refresh_mm_modems();
    }
}

function customResetForm() {
    var name =  $("input[name=createbutton]").attr("value");
    $("input[name=uplinkbutton]").attr("value", name);
    $("input[name=ENABLED]").attr("checked", "checked");
    $("input[name=MANAGED]").attr("checked", "checked");
    $("input[name=ONBOOT]").attr("checked", "checked");
    $("input[value=Automatic]").attr("checked", "checked");
    $("input[value=default]").attr("checked", "checked");
    
    var value = $("input[name=default_checkhosts]").attr("value");
    
    if (typeof value == "undefined") {
        return
    }
    while(value.indexOf(',') != -1) {
        value = value.replace(',', '\n');
    }
     
    $("textarea.form[name=CHECKHOSTS]").text(value);
}

function customLoadForm() {
    var redips = $("textarea.form[name=RED_IPS]").attr("value");
    
    if (redips == "" || typeof redips == "undefined") {
        $("input.form[name=RED_IPS_ACTIVE]").get(0).checked = false;
    } else {
        $("input.form[name=RED_IPS_ACTIVE]").attr("checked", "checked");
    }
}

function cancelForm() {
    var id = $("input[name=ID]").attr("value");
    var oldname = $("input." + id + "[name=NAME]").attr("value");
    var color = $("input." + id + "[name=rowcolor]").attr("value");
    var backupselect = $("select[name=BACKUPPROFILE]");
    
    $("#row_" + id).attr("class", color);                       // reset row color
        
    if (typeof id != "undefined" && id != "" && backupselect.containsOption(id) == false) { // check if the uplink selected before is contained in backuplist
        backupselect.addOption(id, oldname + " (" + id + ")", false);             // it it is not conained it is added
        backupselect.sortOptions();
    }
}

$(document).ready(function() {
    $("input[name=edituplink]").click( function() {
        var value = $(this).attr("value");
        
        var buttonname = $("input[name=updatebutton]").attr("value");
        $("input[name=uplinkbutton]").attr("value", buttonname);       // set buttonname to update
        
        var backupselect = $("select[name=BACKUPPROFILE]");
        
        var oldid = $("input[name=ID]").attr("value");
        if (typeof oldid != "undefined" && oldid != "") {
            var oldname = $("input." + oldid + "[name=NAME]").attr("value");
            var oldcolor = $("input." + oldid + "[name=rowcolor]").attr("value");
            $("#ro w_" + oldid).attr("class", oldcolor);                     // reset color of row which was edited before
            
            if (backupselect.containsOption(oldid) == false) { // check if the uplink selected before is contained in backuplist
                backupselect.addOption(oldid, oldname + " (" + oldid + ")", false);             // it it is not contained it is added
                backupselect.sortOptions();
            }
        }
        loadForm(value);
        
        var backup = $("input." + value + "[name=BACKUPPROFILE]");
        if (typeof backup.attr("value") != "undefined" && backup.attr("value") != "") {
            $("input[name=BACKUPPROFILEACTIVE]").attr("checked", "checked");
        }
        
        backupselect.removeOption(value);
        
        showForm("createuplink");
        
        $("#row_" + value).attr("class", "selected");          // set color of current edited row to selected
    });
    $("input[name=RED_IPS_ACTIVE]").click( function() {
        if ($(this).attr("checked")) {
            $("#uplinkips").show();
        } else {
            $("#uplinkips").hide();
        }
    });
    $("input[name=DNS]").click( function() {
        if ($(this).attr("checked")) {
            $("#uplinkmanualdns").show();
        } else {
            $("#uplinkmanualdns").hide();
        }
    });
    $("input[name=MACACTIVE]").click( function() {
        if ($(this).attr("checked")) {
            $("#uplinkmac").show();
        } else {
            $("#uplinkmac").hide();
        }
    });
    $("input[name=LINKCHECK]").click( function() {
        if ($(this).attr("checked")) {
            $("#uplinkcheckhosts").show();
        } else {
            $("#uplinkcheckhosts").hide();
        }
    });
    $("select[name=NETWORK_TYPE]").change( function() {
        customShowForm();
    });
    $("select[name=RED_TYPE]").change( function() {
        customShowForm();
    });
    $("select[name=PROTOCOL]").change( function() {
        customShowForm();
    });
    $("select[name=METHOD]").change( function() {
        customShowForm();
    });
    $("select[name=MODEMTYPE]").change( function() {
        if ($(this).get(0).selectedIndex == 0) {
            // if its an analog modem we need phonenumber but no apn
            $("#uplinkapn").hide(); 
            $("#uplinkphonenumber").show();
        } else if ($(this).get(0).selectedIndex == 1) {
            // if its an umts modem we need apn but no phonenumber
            $("#uplinkapn").show();
            $("#uplinkphonenumber").hide();
            $("select[name=SPEED]").selectOptions("460800");
        } else {
            // if ist none of both apn and phonenumber are not needed
            $("#uplinkapn").hide();
            $("#uplinkphonenumber").hide();
            $("select[name=SPEED]").selectOptions("460800");
        }
    });
    customShowForm();
});
