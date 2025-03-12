
function EndianNetworkSelector(id, zoom_factor, values, interfaces){
    this.id = id;
    this.zoom_factor = zoom_factor;
    this.zoom_factor_percentage = 0;
    this.zoom_factor_pos_percentage = 0;
    this.zoom_time = 10;
    this.values = values;
    this.current_value_index = 0;
    this.interfaces = interfaces;
}

EndianNetworkSelector.prototype = {
    setup: function(){
	econsole.on();
	econsole.debug("Setup network selector.");

	this.zoom_factor_percentage = 100 * this.zoom_factor;
	this.zoom_factor_pos_percentage = -(this.zoom_factor_percentage-100)/2;

	this.setup_mouse_events();
    },

    setup_mouse_events: function(){
	econsole.on();
	econsole.debug("Setup mouse events.");
	var fake_this = this;
	$(this.id+" .network_selector_content").mouseenter(function() {
		econsole.debug("Zoom in.");
		$(fake_this.id+" .network_selector_background").add(fake_this.id+" .network_selector_content").animate({width:fake_this.zoom_factor_percentage+"%", height: fake_this.zoom_factor_percentage+"%", top: fake_this.zoom_factor_pos_percentage+"%", left: fake_this.zoom_factor_pos_percentage+"%"}, fake_this.zoom_time);
	    });
	$(this.id+" .network_selector_content").mouseleave(function() {
		econsole.debug("Zoom out.");
		$(fake_this.id+" .network_selector_background").add(fake_this.id+" .network_selector_content").animate({width:"100%", height: "100%", top:"0", left:"0"}, fake_this.zoom_time);
	    });
	
	for(var i = 0; i < this.interfaces.length; ++i){
	    function copy_value_function(id, x){
		$(id+"_network_selector_interface_"+x+" img").click(function() {
			fake_this.set_interface(x); 
		    });
		$(id+"_network_selector_interface_"+x+" img").mouseenter(function() {
			fake_this.set_focus_title(x);
		    });
		$(id+"_network_selector_interface_"+x+" img").mouseleave(function() {
			fake_this.set_default_title(x);
		    });
	    };
	
	    copy_value_function(this.id, i);
	}
	
    },

    get_value_index_by_value: function(value){
	var index = -1;
	for(var i = 0; i < this.values.length; ++i){
	    if(this.values[i]["id"].toLowerCase() == value.toLowerCase()){
		index = i;
		break;
	    }
	}
	return index;
    },

    get_interface_index_by_interface: function(interface){
	var index = -1;
	for(var i = 0; i < this.interfaces.length; ++i){
	    if(this.interfaces[i]["id"].toLowerCase() == interface.toLowerCase()){
		index = i;
		break;
	    }
	}
	return index;
    },

    set_current_value: function(value){
	econsole.debug("Set current value: "+value);
	var index = this.get_value_index_by_value(value);
	if(index != -1)
	    this.current_value_index = index;
    },

    set_current_value_by_index: function(index){
	econsole.debug("Set current value by index: "+index);
     
	if(index >= 0 && index < this.values.length)
	    this.current_value_index = index;
    },

    set_interface_by_interface: function(interface){
	this.set_interface(this.get_interface_index_by_interface(interface));
    },

    set_interface: function(index){
	econsole.debug("Set interface: "+index+" current value: "+this.values[this.current_value_index]["id"]);
	if(index >= 0 && index < this.interfaces.length){
	    var value = this.values[this.current_value_index]["id"];
	    var background = this.values[this.current_value_index]["color"];
	    var focus_title = this.values[this.current_value_index]["focus_title"];
	    var interface_value = $(this.id+"_network_selector_interface_"+index).attr("value");
	    var occurences = $(this.id+" .network_selector_interface_outer[value='"+value+"']").length;
	    if(interface_value.indexOf("BLOCKED") != -1)
		return;// interface is blocked
	    if(interface_value == value || (
					    this.values[this.current_value_index]["max_selections"] != -1 &&
					    occurences >= this.values[this.current_value_index]["max_selections"])){
		//setdefault
		econsole.debug("Set default.");
		value = this.values[0]["id"];
		background = this.values[0]["color"];
		focus_title = this.values[0]["focus_title"];
	    }
	    $(this.id+"_network_selector_interface_"+index).attr("value",value);
	    $(this.id+"_network_selector_interface_"+index).attr("focus_title",focus_title);
	    $(this.id+"_network_selector_interface_"+index+" .network_selector_interface_background").css("background-color", background);
	    $(this.id+"_network_selector_interface_"+index+" .network_selector_interface_title").css("color", background);
	    this.set_focus_title(index);
	    this.update_input();
	}
    },

    update_input: function(){
	econsole.debug("Update input");

	var input = "";
	for(var i = 0; i < this.interfaces.length; ++i){
	    value = $(this.id+"_network_selector_interface_"+i).attr("value");
	    if(typeof(value) === "undefined" || !value)// set default
		value = this.values[0]["id"];
	    if(i)
		input += ",";
	    input += this.interfaces[i]["id"]+":"+value;
	}
	econsole.debug(input);
	$(this.id+"_network_selector_input").val(input);
    },

    update_interfaces: function(){
	econsole.debug("Update interfaces.");
	var inputs = $(this.id+"_network_selector_input").val().split(",");
	for(var index = 0; index < this.interfaces.length; ++index){
	    var interface_index = this.get_interface_index_by_interface(inputs[index].split(":")[0]);
	    var value_index = this.get_value_index_by_value(inputs[index].split(":")[1]);
	    var value = inputs[index].split(":")[1]+(inputs[index].split(":").length > 2 ? ":BLOCKED":"");
	    var background = this.values[value_index]["color"];
	    var focus_title = this.values[value_index]["focus_title"];
	    $(this.id+"_network_selector_interface_"+interface_index).attr("value",value);
	    $(this.id+"_network_selector_interface_"+interface_index).attr("focus_title",focus_title);
	    $(this.id+"_network_selector_interface_"+interface_index+" .network_selector_interface_background").css("background-color", background);
	    $(this.id+"_network_selector_interface_"+interface_index+" .network_selector_interface_title").css("color", background);
	}
    },

    set_focus_title: function(index){
	econsole.debug("Set focus title "+index);
	var focus_title = $(this.id+"_network_selector_interface_"+index).attr("focus_title");
	$(this.id+"_network_selector_interface_"+index+" .network_selector_interface_title").html(focus_title);
    },

    set_default_title: function(index){
	econsole.debug("Set default title "+index);
	$(this.id+"_network_selector_interface_"+index+" .network_selector_interface_title").html(index);
    }

}