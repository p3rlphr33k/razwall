function endian_input_lock_position_on(target, lock_id, message, align) {

    if(target[0].tagName == "INPUT" && target.attr("type") == "hidden"){//f.e. ips slider
	var new_target = target;
	while(!new_target.hasClass("fieldcol") && new_target[0].tagName != "BODY"){
	    new_target = new_target.parent();
	}
	if(new_target.tagName != "BODY"){
	    target = new_target;
	}
    }

    var element = $("<div class='input_lock_locked'>&nbsp;</div>").appendTo(target.parent());

    var x      = target.position().left-target.parent().position().left; 
    var y      = target.position().top-target.parent().position().top;
    element.width(target.outerWidth());
    element.height(target.outerHeight());

    if(align == 'right') {
	x -= (element.outerWidth() - target.outerWidth());
    } else if(align == 'center') {
	x -= element.outerWidth() / 2 - target.outerWidth() / 2;
    }
    
    target.parent().css({
	    position: 'relative'
	});
    
    element.css({
	    'position': 'absolute',
		'zIndex':   5000,
		'top':      y, 
		'left':     x,
		'margin-top':   target.css('margin-top'),
		'margin-bottom':   target.css('margin-bottom'),
		'margin-left':   target.css('margin-left'),
		'margin-right':   target.css('margin-right')
		});
    element.click(function(event){
	    var overwrite = window.confirm(message);
	    if(overwrite){
		element.remove();
		$(lock_id).attr("value", "");
	    }
	});
};

function endian_input_lock_create(target_id, lock_id, message) {
    
    endian_input_lock_position_on($(target_id),
				  lock_id,
				  message);
    
}