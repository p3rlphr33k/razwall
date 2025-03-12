
function signaturesinformationpluginUpdate(json) {
    function createRow(label, datetime) {
        var tr = $("<tr>");
	tr.append($('<td>' + label + '</td>'));
	tr.append($('<td>' + datetime + '</td>'));
        $("#signaturesinformationplugin-information").append(tr);
    }
    
    $("#signaturesinformationplugin-information").empty();

    if (!(json && json.signatures) || $.isEmptyObject(json.signatures)) {
        $("#signaturesinformationplugin-headers").hide();
	var tr = $('<tr width="100%" height="100%">');
        tr.append($('<td colspan="2" style="vertical-align:middle;text-align:center;">' + json.no_signatures_msg + '</td>'));
        $("#signaturesinformationplugin-information").append(tr);
        return;
    }

    $("#signaturesinformationplugin-headers").show();

    // Sort the keys alphabetically.
    var keys = [];
    for(var key in json.signatures) {
        if (!json.signatures.hasOwnProperty(key)) { continue; }
        keys.push(key);
    }
    keys.sort();

    for (var i = 0; i < keys.length; i++) {
        signature = keys[i];
        createRow(signature, json.signatures[signature]);
    }
};

