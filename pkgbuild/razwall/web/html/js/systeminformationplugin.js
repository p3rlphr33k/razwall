
var systeminformationplugin_config = {
    appliance:[["appliance"]],
    version:[["version"]],
    kernel:[["kernel"]],
    uptime:[["uptime"]]
};

function systeminformationplugin_display(id, index) {
  index = index || 0;
  var elem = document.getElementById("systeminformationplugin-" + systeminformationplugin_config[id][index][0]);	
  if (elem) {
    elem.classList.remove("systeminformationplugin-disabled");
  }
}

function systeminformationplugin_set(id, value, index) {
  index = index || 0;
  var elem = document.getElementById("systeminformationplugin-" + systeminformationplugin_config[id][index][0]);
  if (elem) {
    elem.innerHTML = value;
  }
}

function systeminformationpluginUpdate(json){
    if(typeof json["appliance"] !== 'undefined'){
        systeminformationplugin_set("appliance", json["appliance"]);
        systeminformationplugin_display("appliance");
    }
    if(typeof json["version"] !== 'undefined'){
        systeminformationplugin_set("version", json["version"]);
        systeminformationplugin_display("version");
    }
	if(typeof json["kernel"] !== 'undefined'){
        systeminformationplugin_set("kernel", json["kernel_value"], 0);
        systeminformationplugin_display("kernel", 0);
    }
    
    if(typeof json["uptime"] !== 'undefined'){
        systeminformationplugin_set("uptime", json["uptime"]);
        systeminformationplugin_display("uptime");
    }
}