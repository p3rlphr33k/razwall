function show_simple() {
    $(".simple").show();
    $(".advanced").hide();
    $("#simple").hide();
    $("#advanced").show();
    $("#target_type").val("ip");
    toggleTypes('target');
    $("#src_type").val("any");
    toggleTypes('src');
    $("#filter_policy option[value='ALLOW']").attr('selected', 'selected');
}

function show_advanced() {
    $(".simple").hide();
    $(".advanced").show();
    $("#advanced").hide();
    $("#simple").show();
}

function toggle_filter_policy(value) {
    if (value == "RETURN") {
        $(".filter_policy").hide();
    }
    else {
        $(".filter_policy").show();
    }
}

function policy_change() {
    toggle_filter_policy($(this).val());
}

function target_type_change() {
    target_type = $(this).val();
    if (target_type == "ip") {
        toggle_filter_policy($("#policy_ip").val());
    }
    else if (target_type == "user") {
        toggle_filter_policy($("#policy_user").val());
    }
    else if (target_type == "lb") {
        toggle_filter_policy($("#policy_lb").val());
    }
    else if (target_type == "map") {
        toggle_filter_policy("RETURN");
    }
}


function toggle_target_ports(protoField) {
    var proto = document.getElementsByName(protoField)[0];
    if (!proto) {
        return;
    }
    var el_names = ['target_port_ip', 'target_port_user',
	     'target_port_lb', 'target_port_l2tp'];
    for (var idx = 0; idx < el_names.length; idx++) {
        var el = document.getElementsByName(el_names[idx])[0];
	if (!el) {
            continue;
	}
	if (proto.value === 'any' || proto.value === "") {
	    el.value = "";
            el.disabled = true;
	} else {
            el.disabled = false;
	}
    }
}


$('document').ready(function() {
    $("#simple").click(show_simple);
    $("#advanced").click(show_advanced);
    $(".policy").change(policy_change);
    $("#target_type").change(target_type_change);
    toggle_target_ports('protocol');
});
