function selectService(protoField, serviceField, portField) {
    var values;
    var service = document.getElementsByName(serviceField)[0];
    var port = document.getElementsByName(portField)[0];
    var proto = document.getElementsByName(protoField)[0];

    values = service.value.split('/');
    proto.value = values[1];

    if (values[0] === "" && (values[1] === "any" || values[1] === undefined)) {
        proto.value = values[1] = "tcp&udp";
    }

    if (values[0] == "any" || values[1] == "any" ||
		    (values[1] === undefined && values[0] !== "")) {
        port.disabled = true;
        port.value = "";
    } else {
        port.disabled = false;
        port.value = values[0];
    }
}

function updateService(protoField, serviceField, portField) {
    var found = 0;
    var service = document.getElementsByName(serviceField)[0];
    var port = document.getElementsByName(portField)[0];
    var proto = document.getElementsByName(protoField)[0];

    for (var i = 0; i < service.options.length; i++) {
        curvalue = service.options[i].value;
        values = curvalue.split('/');

        if (port.value == values[0] && proto.value == values[1]) {
            found = 1;
            service.value = curvalue;
            break;
        }
    }

    if (!found) {
        service.value = service.options[1].value;
    }

    if (proto.value == "any") {
        port.disabled = true;
        service.value = "any/any";
        port.value = "";
    } else {
        port.disabled = false;
    }
}
