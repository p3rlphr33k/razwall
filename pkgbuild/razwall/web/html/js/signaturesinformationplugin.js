function signaturesinformationpluginUpdate(json) {
  // Helper: create a table row with two <td>s.
  function createRow(label, datetime) {
    var tr = document.createElement("tr");
    
    var tdLabel = document.createElement("td");
    tdLabel.innerHTML = label;
    tr.appendChild(tdLabel);

    var tdDatetime = document.createElement("td");
    tdDatetime.innerHTML = datetime;
    tr.appendChild(tdDatetime);

    var container = document.getElementById("signaturesinformationplugin-information");
    if (container) {
      container.appendChild(tr);
    }
  }

  // Get the container element and clear its contents.
  var container = document.getElementById("signaturesinformationplugin-information");
  if (container) {
    container.innerHTML = "";
  }

  // If there are no signatures...
  if (!(json && json.signatures) || Object.keys(json.signatures).length === 0) {
    // Hide headers.
    var headers = document.getElementById("signaturesinformationplugin-headers");
    if (headers) {
      headers.style.display = "none";
    }
    
    // Create a full-size row that contains the no-signatures message.
    var tr = document.createElement("tr");
    tr.setAttribute("width", "100%");
    tr.setAttribute("height", "100%");
    
    var td = document.createElement("td");
    td.setAttribute("colspan", "2");
    td.style.verticalAlign = "middle";
    td.style.textAlign = "center";
    td.innerHTML = json.no_signatures_msg;
    
    tr.appendChild(td);
    
    if (container) {
      container.appendChild(tr);
    }
    return;
  }

  // Else, show headers.
  var headers = document.getElementById("signaturesinformationplugin-headers");
  if (headers) {
    headers.style.display = "";
  }

  // Sort the signature keys alphabetically.
  var keys = [];
  for (var key in json.signatures) {
    if (json.signatures.hasOwnProperty(key)) {
      keys.push(key);
    }
  }
  keys.sort();

  // Create a row for each signature.
  for (var i = 0; i < keys.length; i++) {
    var signature = keys[i];
    createRow(signature, json.signatures[signature]);
  }
}


/* ORIGINAL CODE
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

*/