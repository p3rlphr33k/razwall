

function EndianWizard(id, plugin_data, sequential_access_until, has_menu, leave_wizard_forward, commit_at_leave_wizard, lazy_loading, first_plugin){
    /**
       The EndianWizard provides a js controll for the wizard widget.
       Basically it creates out of the skeletton a wizard like 
       behavior using jquery scrollable. There during the switch between
       plugins maybe popups are triggered using jquery overlay.

       The flow of the wizard is more or less controlled by jquery scrollable
       which takes care of the menu and the go back and continue buttons. To 
       controll those seeks the jquery hooks are used. In the hooks f.e.
       the popups are triggerd, but of much more interest is the store/validation/apply
       behavior. The wizard stores the different forms and if they are modified
       and the user wants to switch/leave the plugin, the wizard triggers
       a store command(and if wished an apply) to validate the data. If the validation
       fails the switch will be blocked. This is not really obvious in the code
       because of the asynchron behavior of ajax, so the wizard has a status for the
       switch and increments on each success the status until the last is reached
       and the page switch will be allowed.

       To reduce the amounts of ajax calls the wizard chains them. So f.e. 
       the wizard can send the request do store and then apply a plugin. The backend
       will try to do that actions but if one fails, he will break and return
       action data gained so far. Then here js will trigger the js callbacks defined
       by the response, in whose it will see if the actions were successful or not
       and perform as wished.
     */
    this.SWITCH_WITH_TAB = true;
    this.LEAVE_WIZARD_INDEX = -1;//attention seekt target is at init -2!! Shouldnt be the same!
    this.DEFAULT_TIMEOUT = 10000;//10sec
    this.EAGER_LOAD_DELAY = 1000;//2sec

    this.scrollable_settings = {
	'items':'plugins',
	'vertical':false
    };
    // updated afterwards...
    this.access_popup_settings = {
	"target":"popup",
	"closeOnClick": false,
	"closeOnEsc": false,
	"onClose": null,
	"oneInstance":false,
	"top": "center",
	"mask": {
	    color: '#ffffff',
	    loadSpeed: 200,
	    opacity: 0.8
	}
    };
    // updated afterwards...
    this.leaving_popup_settings = {
	"target":"popup",
	"closeOnClick": false,
	"closeOnEsc": false,
	"onClose": null,
	"oneInstance":false,
	"top": "center",
	"mask": {
	    color: '#ffffff',
	    loadSpeed: 200,
	    opacity: 0.8
	}
    };

    this.id = id;
    this.plugin_data = plugin_data;
    this.root = null;
    this.api = null;
    this.popup = null;
    this.sequential_access_until = typeof(sequential_access_until) != 'undefined' ? sequential_access_until : 0;
    this.has_menu = typeof(has_menu) != 'undefined' ? has_menu : false;
    this.leave_wizard_forward = typeof(leave_wizard_forward) != 'undefined' ? leave_wizard_forward : "";
    this.commit_at_leave_wizard = typeof(commit_at_leave_wizard) != 'undefined' ? commit_at_leave_wizard : "";
    this.lazy_loading = typeof(lazy_loading) != 'undefined' ? lazy_loading : false;
    this.first_plugin = typeof(first_plugin) != 'undefined' ? first_plugin : null;
    this.accessed = 0;
    this.before_seek_step = 0;
    this.after_seek_step = 0;
    this.loaded_plugins = [];
    // only used by a before seek control function
    this.seek_target = -1;
    this.should_close_leaving_popup = false;
}

EndianWizard.prototype = {
    setup: function(){
	econsole.on();
	econsole.debug("Setup wizard.");

	this.root = $(this.id).scrollable(this.scrollable_settings);
	this.api = this.root.scrollable();
	this.setup_popups();

	this.setup_control_flow();

	if(this.SWITCH_WITH_TAB){
	    this.enable_switch_with_tab();
	}

	if(this.first_plugin){
	    econsole.debug("Update first plugin content.");
	    this.ajax_callback(this.first_plugin);
	}
	this.plugin_show(0);

	if(!this.lazy_loading)
	    this.plugin_eager_load();
    },

   setup_popups: function(){
	econsole.debug("Setup popups.");
	$(this.id).append("<div class='popup-anchor'></div>");
	$(this.id+" .popup-anchor").append("<div class='access'></div>");
	$(this.id+" .popup-anchor").append("<div class='leaving'></div>");
	var access_anchor = $(this.id+" .popup-anchor .access");
	var leaving_anchor = $(this.id+" .popup-anchor .leaving"); 

	this.access_popup_settings["target"] = this.id+"-popup";
	var fake = this;
	this.access_popup_settings["onBeforeClose"] = function(){
	    return fake.plugin_close_access_popup();
	};
	this.leaving_popup_settings["target"] = this.id+"-popup";
	var fake = this;
	this.leaving_popup_settings["onBeforeClose"] = function(){
	    return fake.plugin_close_leaving_popup();
	};

	$(access_anchor).overlay(this.access_popup_settings)
	this.access_popup = $(access_anchor).overlay();
	$(leaving_anchor).overlay(this.leaving_popup_settings)
	this.leaving_popup = $(leaving_anchor).overlay();
    },

    setup_control_flow: function(){
	econsole.debug("Setup control flow.");
	// validation logic is done inside the callbacks
	var fake = this;
	this.api.onBeforeSeek(function(event, i){
		return fake.control_before_seek(event, i);
		    });
	this.api.onSeek(function(event, i){
		return fake.control_after_seek(event, i);
		    });
    },

    control_before_seek: function(event, i){
	econsole.debug("Control before seek."+this.before_seek_step);
	var current_index = this.api.getIndex();
	this.seek_target = i;
	switch(this.before_seek_step){
	case 0:
	    this.before_seek_step = 0;
	    // until sequential_access_until we want a sequential
	    // access
	    if(this.accessed < this.sequential_access_until &&
	       i > this.accessed+1)
		return false;
	case 1:
	    this.before_seek_step = 1;
	    if((i == -1 || current_index < i) && this.plugin_data[current_index]["leaving_popup"]){
		this.plugin_show_leaving_popup(current_index);
		return false;
	    }
	case 2:
	    this.enable_control_spinners()
	    this.before_seek_step = 2;
	    if((i == -1 || current_index < i) && this.plugin_data[current_index]["successful_apply"]){
		if(this.seek_target == this.LEAVE_WIZARD_INDEX && this.commit_at_leave_wizard){
		    this.plugin_store_apply_commit_leave(current_index);
		    return false;
		}else{
		    this.plugin_store_apply_and_show(current_index);
		    return false;
		}
	    }else if(this.plugin_form_modified(current_index)){
		if(this.seek_target == this.LEAVE_WIZARD_INDEX && this.commit_at_leave_wizard){
		    this.plugin_store_wizard_commit_leave(current_index);
		    return false;
		}else{
		    this.plugin_store_and_show(current_index);
		    return false;
		}
	    }else if(this.seek_target == this.LEAVE_WIZARD_INDEX && this.commit_at_leave_wizard){
		    this.wizard_commit_leave(current_index);
		    return false;
	    }
	    
	default:
	    this.restore_before_seek_status();
	    if(this.seek_target == this.LEAVE_WIZARD_INDEX)
		this.leaving_wizard();
	    else{
		this.plugin_show(i);
		this.before_seek_step = 0;
	    }
	}
    },

    control_after_seek: function(event, i){
	econsole.debug("Control after seek.");
	if(i > this.accessed)
	    this.accessed = i;

	switch(this.after_seek_step){
	case 0:
	    this.after_seek_step = 0;
	    if(this.plugin_data[i]["access_popup"]){
		this.plugin_show_access_popup(i);    
		return false;
	    }
	default:
	    this.after_seek_step = 0;
	}
    },

    restore_before_seek_status: function(event, i){
	econsole.debug("Control after seek.");
	this.disable_control_spinners();
	if(this.leaving_popup.isOpened()){
	    this.should_close_leaving_popup = true;
	    this.leaving_popup.close();
	}
    },

    plugin_eager_load: function(index){
	econsole.debug("Plugin eager load.");
	var fake = this;
	var index = 0;
	function load_plugins(){
	    fake.plugin_load(index);
	    ++index;
	    if(index < fake.plugin_data.length)
		setTimeout(load_plugins, fake.EAGER_LOAD_DELAY);
	}

	setTimeout(load_plugins, this.EAGER_LOAD_DELAY);
    },


    plugin_load: function(index){
	if(!this.plugin_is_loaded(index)){
	    econsole.debug("Plugin load for "+index+".");
	    var data_string = "plugin_id="+this.api.getIndex()+"&wizard_actions=(show,"+index+",this.callback_show)";
	    this.ajax(data_string);
	}
    },

    plugin_show: function(index){
	econsole.debug("Plugin show for "+index+".");
	this.plugin_load(index);
	if(this.has_menu){
	    $(this.id+"-menu .menu-item").removeClass("active");
	    $(this.id+"-menu .menu-item:eq("+index+")").addClass("active");
	}
    },

    plugin_show_access_popup: function(index){
	econsole.debug("Plugin show access popup for "+index+".");
	var data_string = "plugin_id="+index+"&wizard_actions=(show_access_popup,"+index+",this.callback_show_access_popup)";
	this.ajax(data_string);
    },

    plugin_show_leaving_popup: function(index){
	econsole.debug("Plugin show leaving popup for "+index+".");
	var form_string = this.plugin_get_form_string(index);
	var data_string = "plugin_id="+index+"&wizard_actions=(show_leaving_popup,"+index+",this.callback_show_leaving_popup)&"+form_string;
	this.ajax(data_string);
    },

    plugin_store: function(index, form_string){
	econsole.debug("Plugin store for "+index+".");
	form_string = typeof(form_string) === "undefined" ? this.plugin_get_form_string(index) : form_string;
	var data_string = "plugin_id="+index+"&wizard_actions=(store,"+index+",this.callback_store)&"+form_string;
	econsole.debug(data_string);
	this.ajax(data_string);
    },

    plugin_store_and_apply: function(index){
	econsole.debug("Plugin store and apply for "+index+".");
	var form_string = this.plugin_get_form_string(index);
	var data_string = "plugin_id="+index+"&wizard_actions=(store,"+index+",this.callback_store),(apply,"+index+",this.callback_apply)&"+form_string;
	econsole.debug(data_string);
	this.ajax(data_string);
    },

    plugin_store_apply_and_show: function(index){
	econsole.debug("Plugin store, apply and show for "+index+".");
	var form_string = this.plugin_get_form_string(index);
	var data_string = "plugin_id="+index+"&wizard_actions=(store,"+index+",this.callback_store),(apply,"+index+",this.callback_apply),(show,"+this.seek_target+",this.callback_show),(js_callback,"+index+",this.callback_seek_target)&"+form_string;
	econsole.debug(data_string);
	this.ajax(data_string);
    },

    plugin_store_and_show: function(index){
	econsole.debug("Plugin store and show for "+index+".");
	var form_string = this.plugin_get_form_string(index);
	var data_string = "plugin_id="+index+"&wizard_actions=(store,"+index+",this.callback_store),(show,"+this.seek_target+",this.callback_show),(js_callback,"+index+",this.callback_seek_target)&"+form_string;
	econsole.debug(data_string);
	this.ajax(data_string);
    },

    plugin_store_apply_commit_leave: function(index){
	econsole.debug("Plugin store, apply, commit and leave for "+index+".");
	var form_string = this.plugin_get_form_string(index);
	var data_string = "plugin_id="+index+"&wizard_actions=(store,"+index+",this.callback_store),(apply,"+index+",this.callback_apply),(commit_transaction,"+index+",this.callback_seek_target)&"+form_string;
	econsole.debug(data_string);
	this.ajax(data_string);
    },

    plugin_store_wizard_commit_leave: function(index){
	econsole.debug("Plugin store, wizard commit and leave.");
	var form_string = this.plugin_get_form_string(index);
	var data_string = "plugin_id="+index+"&wizard_actions=(store,"+index+",this.callback_store),(commit_transaction,"+index+",this.callback_seek_target)"+form_string;
	econsole.debug(data_string);
	this.ajax(data_string);
    },

    wizard_commit_leave: function(index){
	econsole.debug("Wizard commit and leave.");
	var data_string = "plugin_id="+index+"&wizard_actions=(commit_transaction,"+index+",this.callback_seek_target)";
	econsole.debug(data_string);
	this.ajax(data_string);
    },

    ajax: function(data_string, timeout, polling){
	data_string = (typeof(data_string) == "undefined") ? "" : data_string;
        timeout = (typeof(timeout) == "undefined") ? this.DEFAULT_TIMEOUT : timeout;
	polling = (typeof(polling) == "undefined") ? true : polling;
	econsole.debug("Ajax request with data "+data_string);
	var fake = this;
	$.ajax({
		type: "POST",
		    url: "./ajax/",
		    data: data_string,
		    timeout: timeout,
		    complete: function(xhr, status){
		    if(status != "success" && polling){
			fake.ajax(data_string, timeout, polling);
		    }			
  		    },
		    success: function(data){
		    fake.ajax_callback(data);
			}
		    });
	/*$.ajax({
		type: "POST",
		    url: "./ajax/",
		    data: data_string,
		    success: function(data){
		    fake[callback](data);
			},
		    dataType:"jsonp"
		    });
	*/
    },

    ajax_callback: function(data){
	econsole.debug("Ajax callback.");
	econsole.debug(data);
	if(typeof(data["translation"]) !== 'undefined')
	    this.update_labels(data["translation"]);
	if(typeof(data["flags"]["need_emi_reload"]) !== 'undefined' &&
	   data["flags"]["need_emi_language_reload"] == true){
	    econsole.debug("Reload emi.");
	    $.ajax({url:"/manage/commands/commands.emi.reloadLanguage/"});
	}
	if(typeof(data["flags"]["need_emi_reload"]) !== 'undefined' &&
	   data["flags"]["need_emi_reload"] == true){
	    econsole.debug("Reload emi.");
	    $.ajax({url:"/manage/commands/commands.emi.reload/"});
	}
	if(typeof(data["flags"]["flush_plugins"]) !== 'undefined' &&
	   data["flush_plugins"] == true)
	    this.plugin_flush_all();
	if(typeof(data["flush_plugin"]) !== 'undefined')
	    this.plugin_flush(data["flush_plugin"]);
	for(var i = 0; i < data["actions"].length; ++i){
	    econsole.debug(data["actions"][i]["callback"]+"(data['actions']["+i+"])");
	    eval(data["actions"][i]["callback"]+"(data['actions']["+i+"])");
	}
    },

    callback_show: function(data){
	var current_index = this.api.getIndex();
	econsole.debug("Plugin callback show for "+current_index+".");
	if(data["plugin_id"] == current_index){
	    econsole.debug("Show successful");
	    this.update_plugin_content(data["show_id"],
				       data["plugin_content"]);
	}else{
	    econsole.debug("Show failed");
	}
    },

    callback_show_access_popup: function(data){
	var current_index = this.api.getIndex();
	econsole.debug("Plugin show_access_popup_callback for "+current_index+".");
	econsole.debug(data);
	if(data["plugin_id"] == current_index){
	    econsole.debug("Show access popup successful");
	    this.disable_control_buttons();
	    this.show_access_popup(data["popup_content"]);
	}else{
	    econsole.debug("Show access popup failed");
	}
    },

    callback_show_leaving_popup: function(data){
	var current_index = this.api.getIndex();
	econsole.debug("Plugin show_leaving_popup_callback for "+current_index+".");
	econsole.debug(data);
	if(data["plugin_id"] == current_index){
	    econsole.debug("Show leaving popup successful");
	    this.disable_control_buttons();
	    this.show_leaving_popup(data["popup_content"]);
	}else{
	    econsole.debug("Show leaving popup failed");
	}
    },

    callback_store: function(data){
	var current_index = this.api.getIndex();
	econsole.debug("Plugin store_callback for "+current_index+".");
	econsole.debug(data);
	if(data["flags"]["stored"] == true && data["plugin_id"] == current_index){
	    econsole.debug("Store successful");
	    this.update_plugin_content(current_index,
				       data["plugin_content"]);
	}else{
	    econsole.debug("Store failed");
	    this.update_plugin_content(current_index,
				       data["plugin_content"],
				       false);
	    this.before_seek_step = 0;
	    this.seek_target = -1;
	    this.restore_before_seek_status();
	}
    },

    callback_apply: function(data){
	var current_index = this.api.getIndex();
	econsole.debug("Plugin apply_callback for "+current_index+".");
	econsole.debug(data);
	if(data["flags"]["applied"] == true && data["plugin_id"] == current_index){
	    econsole.debug("Apply successful");
	}else{
	    econsole.debug("Apply failed");
	    this.update_plugin_content(current_index,
				       data["plugin_content"]);
	    this.before_seek_step = 0;
	    this.seek_target = -1;
	    this.restore_before_seek_status();
	}
    },

    callback_seek_target: function(data){
	var current_index = this.api.getIndex();
	econsole.debug("Plugin seek target for "+current_index+".");
	econsole.debug(data);
	if(data["plugin_id"] == current_index){
	    econsole.debug("Seek successful");
	    this.before_seek_step += 1;
	    this.seek_to(this.seek_target);
	}else{
	    econsole.debug("Seek failed");
	}
    },

    plugin_close_access_popup: function(){
	econsole.debug("Close access popup");
	this.enable_control_buttons();
	this.after_seek_step += 1;
	this.control_after_seek(null, this.api.getIndex());
    },

    plugin_close_leaving_popup: function(){
	if(!this.should_close_leaving_popup){
	    this.before_seek_step += 1;
	    this.seek_to(this.seek_target);
	    return false;
	}else{
	    econsole.debug("Close leaving popup");
	    this.should_close_leaving_popup = false;
	    this.enable_control_buttons();
	}
    },
   
    plugin_get_form_string: function(index){
	var form_strings = [];
	for(var i = 0; i < $(this.id+" .plugins .page:eq("+index+") .plugin-content form.to_submit").length; ++i){
	    form_strings.push($(this.id+" .plugins .page:eq("+index+") .plugin-content form.to_submit:eq("+i+")").serialize());
	}
	if(form_strings.length == 0){
	    form_strings = [];
	    for(var i = 0; i < $(this.id+" .plugins .page:eq("+index+") .plugin-content form").length; ++i){
		form_strings.push($(this.id+" .plugins .page:eq("+index+") .plugin-content form:eq("+i+")").serialize());
	    }
	}
	return this.plugin_create_params_string(form_strings);
    },

    plugin_create_params_string: function(form_strings){
	var params_string = "";

	for(var i = 0; i < form_strings.length; ++i){
	    if(i > 0)
		params_string += "&";
	    params_string += "wizard_params="+escape(form_strings[i]);
	}
	return params_string;
    },

    plugin_is_loaded: function(index){
	if(!this.plugin_data[index]["cacheable"])
	    return false;
	return typeof(this.loaded_plugins[index]) != 'undefined' ? true : false;
    },

    plugin_form_modified: function(index){
	return !(this.plugin_is_loaded(index) &&
		 this.loaded_plugins[index] == this.plugin_get_form_string(index));
    },

    plugin_loaded: function(index){
	this.loaded_plugins[index] = this.plugin_get_form_string(index);
    },

    plugin_flush: function(index){
	econsole.debug("Flush plugin "+index);
	delete this.loaded_plugins[index];
	if(!this.lazy_loading)
	    this.plugin_load(index);
    },

    plugin_flush_all: function(){
	econsole.debug("Flush all plugins");
	this.loaded_plugins = [];
	if(!this.lazy_loading)
	    this.plugin_eager_load();
    },

    update_plugin_content: function(index, html, update_loaded){
	econsole.debug("Update plugin content: "+index);
	$(this.id+" .plugins .page:eq("+index+") .plugin-content").html(html);
	this.plugin_catch_submit(index);
        if(typeof(update_loaded) === "undefined" ? true : update_loaded)
	    this.plugin_loaded(index);
    },

    plugin_catch_submit: function(index){
	var fake_this = this;
	$(this.id+" .plugins .page:eq("+index+") .plugin-content form").each(function(each_index, element){
		$(element).submit(function(obj){
			econsole.debug("Catch submit!");
			fake_this.plugin_store(index, fake_this.plugin_create_params_string([$(obj.target).serialize()]));
			return false;
		    });
	    });
    },

    update_labels: function(labels){
	econsole.debug("Update labels.");
	var plugin_count = labels["plugins"].length;
	$(this.id+" .plugins .page:eq("+(plugin_count-1)+") .plugin-control button.leave_wizard").html(labels["leave_button"]);
	for(var i = 0; i < plugin_count; ++i){
	    if(i > 0)
		$(this.id+" .plugins .page:eq("+i+") .plugin-control button.prev").html(labels["plugins"][i]["go_back_button"]);
	    if(i != plugin_count-1)
		$(this.id+" .plugins .page:eq("+i+") .plugin-control button.next").html(labels["plugins"][i]["continue_button"]);
	    if(this.has_menu)
		$(this.id+"-menu .menu-item:eq("+i+")").html(labels["plugins"][i]["menu_title"]);
	}
    },

    show_access_popup: function(popup){
	econsole.debug("Show access popup.");
	$(this.id+"-popup .popup-content").html(popup["content"]);
	$(this.id+"-popup .popup-control .close").html(popup["control"]["button"]);
	$(this.id+"-popup .popup-control .save_spinner").html(popup["control"]["status"]);
	this.access_popup.load();
    },

    show_leaving_popup: function(popup){
	econsole.debug("Show leaving popup.");
	$(this.id+"-popup .popup-content").html(popup["content"]);
	$(this.id+"-popup .popup-control .close").html(popup["control"]["button"]);
	$(this.id+"-popup .popup-control .save_spinner").html(popup["control"]["status"]);
	this.leaving_popup.load();
    },

    enable_control_buttons: function(){
	econsole.debug("Enable control buttons");
	$(this.id+" .plugins .page .plugin-control button.prev").removeAttr('disabled');
	$(this.id+" .plugins .page .plugin-control button.next").removeAttr('disabled');
	$(this.id+" .plugins .page .plugin-control button.leave_wizard").removeAttr('disabled');
    },

    disable_control_buttons: function(){
	econsole.debug("Disable control buttons");
	$(this.id+" .plugins .page .plugin-control button.prev").attr('disabled', 'disabled');
	$(this.id+" .plugins .page .plugin-control button.next").attr('disabled', 'disabled');
	$(this.id+" .plugins .page .plugin-control button.leave_wizard").attr('disabled', 'disabled');
    },

    enable_control_spinners: function(){
	econsole.debug("Enable control spinners");
	$(this.id+" .save_spinner").css("display", "block");
    },

    disable_control_spinners: function(){
	econsole.debug("Disable control spinners");
	$(this.id+" .save_spinner").css("display", "none");
    },

    seek_to: function(index){
	if(index == this.LEAVE_WIZARD_INDEX)//want to leave wizard --> has to be before seek
	    this.control_before_seek(null, index);
	else
	    return this.api.seekTo(index);//use api to get whole seek action
    },

    leave_wizard: function(){
	this.seek_to(this.LEAVE_WIZARD_INDEX);
    },
    
    leaving_wizard: function(){
	$(window.location).attr('href', this.leave_wizard_forward);
    },

    enable_switch_with_tab: function(){
	econsole.debug("Enable switch_with_tab.");
	// if tab is pressed on the next button seek to next page
	this.root.find("button.next").keydown(function(e) {
		if (e.keyCode == 9) {
		    // seeks to next tab by executing our validation routine
		    api.next();
		    e.preventDefault();
		}
	    });
    }
}