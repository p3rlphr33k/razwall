
var systeminformationplugin_config = {
    deactivation:[["deactivation", "deactivation b"]],
    appliance:[["appliance", "appliance td"]],
    version:[["version", "version td"]],
    deployset:[["deployset", "deployset td"]],
    kernel:[["kernel-0", "kernel-0 td"], ["kernel-1"]],
    uptime:[["uptime", "uptime td"]],
    update:[["update-0"],
            ["update-1"],
            ["update-2"],
            ["update-3"]],
    maintenance:[["maintenance-0"],
                 ["maintenance-1"],
                 ["maintenance-2"],
                 ["maintenance-3", "maintenance-3 td span"],
                 ["maintenance-4", "maintenance-4 td span"]],
    sophos:[["sophos-0"],
            ["sophos-1"],
            ["sophos-2", "sophos-2 td span"],
            ["sophos-3", "sophos-3 td span"]],
    commtouch:[["commtouch-0"],
               ["commtouch-1"],
               ["commtouch-2", "commtouch-2 td span"],
               ["commtouch-3", "commtouch-3 td span"]],
    support:[["support-0"], ["support-1", "support-1 td b"]],
    register:[["register-0"], ["register-1", "register-1 td"]]
};

function systeminformationplugin_display(id, index){
    index = index || 0;
    $("#systeminformationplugin-"+systeminformationplugin_config[id][index][0])
    .removeClass("systeminformationplugin-disabled");
}

function systeminformationplugin_hide(id, index){
    index = index || 0;
    $("#systeminformationplugin-"+systeminformationplugin_config[id][index][0])
    .addClass("systeminformationplugin-disabled");
}

function systeminformationplugin_set(id, value, index){
    index = index || 0;
    $("#systeminformationplugin-"+systeminformationplugin_config[id][index][1])
    .html(value);
}

function systeminformationpluginUpdate(json){
    if(typeof json["deactivation"] !== 'undefined'){
        systeminformationplugin_set("deactivation", json["deactivation"]);
        systeminformationplugin_display("deactivation");
    }
    if(typeof json["appliance"] !== 'undefined'){
        systeminformationplugin_set("appliance", json["appliance"]);
        systeminformationplugin_display("appliance");
    }
    if(typeof json["version"] !== 'undefined'){
        systeminformationplugin_set("version", json["version"]);
        systeminformationplugin_display("version");
    }
    if(typeof json["deployset"] !== 'undefined'){
  if(typeof json["kernel"] !== 'undefined'){
        if(json["kernel"] == 0){
            systeminformationplugin_set("kernel", json["kernel_value"], 0);
            systeminformationplugin_display("kernel", 0);
            systeminformationplugin_hide("kernel", 1);
        }else{
            systeminformationplugin_display("kernel", 1);
            systeminformationplugin_hide("kernel", 0);
        }
    }      systeminformationplugin_set("deployset", json["deployset"]);
        systeminformationplugin_display("deployset");
    }
    
    if(typeof json["uptime"] !== 'undefined'){
        systeminformationplugin_set("uptime", json["uptime"]);
        systeminformationplugin_display("uptime");
    }
    if(typeof json["update"] !== 'undefined'){
        if(json["update"] == 0){
            systeminformationplugin_display("update", 0);
            systeminformationplugin_hide("update", 1);
            systeminformationplugin_hide("update", 2);
            systeminformationplugin_hide("update", 3);
        }
        if(json["update"] == 1){
            systeminformationplugin_display("update", 1);
            systeminformationplugin_hide("update", 0);
            systeminformationplugin_hide("update", 2);
            systeminformationplugin_hide("update", 3);
        }
        if(json["update"] == 2){
            systeminformationplugin_display("update", 2);
            systeminformationplugin_hide("update", 0);
            systeminformationplugin_hide("update", 1);
            systeminformationplugin_hide("update", 3);
        }
        if(json["update"] == 3){
            systeminformationplugin_display("update", 3);
            systeminformationplugin_hide("update", 0);
            systeminformationplugin_hide("update", 1);
            systeminformationplugin_hide("update", 2);
        }
    }

    if(typeof json["maintenance"] !== 'undefined'){
        if(json["maintenance"] == 0){
            systeminformationplugin_display("maintenance", 0);
            systeminformationplugin_hide("maintenance", 1);
            systeminformationplugin_hide("maintenance", 2);
            systeminformationplugin_hide("maintenance", 3);
            systeminformationplugin_hide("maintenance", 4);
        }
        if(json["maintenance"] == 1){
            systeminformationplugin_display("maintenance", 1);
            systeminformationplugin_hide("maintenance", 0);
            systeminformationplugin_hide("maintenance", 2);
            systeminformationplugin_hide("maintenance", 3);
            systeminformationplugin_hide("maintenance", 4);
        }
        if(json["maintenance"] == 2){
            systeminformationplugin_display("maintenance", 2);
            systeminformationplugin_hide("maintenance", 0);
            systeminformationplugin_hide("maintenance", 1);
            systeminformationplugin_hide("maintenance", 3);
            systeminformationplugin_hide("maintenance", 4);
        }
        if(json["maintenance"] == 3){
            systeminformationplugin_set("maintenance", json["maintenance_value"], 3);
            systeminformationplugin_display("maintenance", 3);
            systeminformationplugin_hide("maintenance", 0);
            systeminformationplugin_hide("maintenance", 1);
            systeminformationplugin_hide("maintenance", 2);
            systeminformationplugin_hide("maintenance", 4);
        }
        if(json["maintenance"] == 4){
            systeminformationplugin_set("maintenance", json["maintenance_value"], 4);
            systeminformationplugin_display("maintenance", 4);
            systeminformationplugin_hide("maintenance", 0);
            systeminformationplugin_hide("maintenance", 1);
            systeminformationplugin_hide("maintenance", 2);
            systeminformationplugin_hide("maintenance", 3);
        }
    }

    if(typeof json["sophos"] !== 'undefined'){
        if(json["sophos"] == 0){
            systeminformationplugin_display("sophos", 0);
            systeminformationplugin_hide("sophos", 1);
            systeminformationplugin_hide("sophos", 2);
            systeminformationplugin_hide("sophos", 3);
        }
        if(json["sophos"] == 1){
            systeminformationplugin_display("sophos", 1);
            systeminformationplugin_hide("sophos", 0);
            systeminformationplugin_hide("sophos", 2);
            systeminformationplugin_hide("sophos", 3);
        }
        if(json["sophos"] == 2){
            systeminformationplugin_display("sophos", 2);
            systeminformationplugin_hide("sophos", 0);
            systeminformationplugin_hide("sophos", 1);
            systeminformationplugin_hide("sophos", 3);
        }
        if(json["sophos"] == 3){
            systeminformationplugin_set("sophos", json["sophos_value"], 3);
            systeminformationplugin_display("sophos", 3);
            systeminformationplugin_hide("sophos", 0);
            systeminformationplugin_hide("sophos", 1);
            systeminformationplugin_hide("sophos", 2);
        }
    }

    if(typeof json["commtouch"] !== 'undefined'){
        if(json["commtouch"] == 0){
            systeminformationplugin_display("commtouch", 0);
            systeminformationplugin_hide("commtouch", 1);
            systeminformationplugin_hide("commtouch", 2);
            systeminformationplugin_hide("commtouch", 3);
        }
        if(json["commtouch"] == 1){
            systeminformationplugin_display("commtouch", 1);
            systeminformationplugin_hide("commtouch", 0);
            systeminformationplugin_hide("commtouch", 2);
            systeminformationplugin_hide("commtouch", 3);
        }
        if(json["commtouch"] == 2){
            systeminformationplugin_display("commtouch", 2);
            systeminformationplugin_hide("commtouch", 0);
            systeminformationplugin_hide("commtouch", 1);
            systeminformationplugin_hide("commtouch", 3);
        }
        if(json["commtouch"] == 3){
            systeminformationplugin_set("commtouch", json["commtouch_value"], 3);
            systeminformationplugin_display("commtouch", 3);
            systeminformationplugin_hide("commtouch", 0);
            systeminformationplugin_hide("commtouch", 1);
            systeminformationplugin_hide("commtouch", 2);
        }
    }

    if(typeof json["support"] !== 'undefined'){
        if(json["support"] == 0){
            systeminformationplugin_display("support", 0);
            systeminformationplugin_hide("support", 1);
        }else{
            systeminformationplugin_set("support", json["support_value"], 1);
            systeminformationplugin_display("support", 1);
            systeminformationplugin_hide("support", 0);
        }
    }

    if(typeof json["register"] !== 'undefined'){
        if(json["register"] == 0){
            systeminformationplugin_display("register", 0);
            systeminformationplugin_hide("register", 1);
        }
        else {
            systeminformationplugin_set("register", json["register"], 1);
            systeminformationplugin_display("register", 1);
            systeminformationplugin_hide("register", 0);
        }
    }
}