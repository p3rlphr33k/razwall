var prevCPUStat = null;

function hardwareinformationpluginUpdate(json) {
  // Helper function to create a "row" using divs and spans.
  function createRow(label, usage, total) {
    // Create a row container
    var rowDiv = document.createElement("div");
    rowDiv.className = "hardware-row";

    // 1. Create a span for the label
    var labelSpan = document.createElement("span");
    labelSpan.className = "hardware-label";
    labelSpan.textContent = label;
    rowDiv.appendChild(labelSpan);

    // 2. Create a container for the percentage bar
    var barDiv = document.createElement("div");
    barDiv.className = "hardware-bar";
    
    // Create a span for the used portion
    var usedSpan = document.createElement("span");
    usedSpan.className = "used";
    // Set the width by inline style (e.g. "60%" for 60% usage)
    usedSpan.style.width = usage + "%";
    barDiv.appendChild(usedSpan);
    
    // Create a span for the unused portion
    var unusedSpan = document.createElement("span");
    unusedSpan.className = "unused";
    unusedSpan.style.width = (100 - usage) + "%";
    barDiv.appendChild(unusedSpan);
    
    rowDiv.appendChild(barDiv);
    
    // 3. Create a span for the usage percentage text
    var usageSpan = document.createElement("span");
    usageSpan.className = "hardware-usage";
    usageSpan.textContent = usage + "%";
    rowDiv.appendChild(usageSpan);
    
    // 4. Create a span for the total value.
    var totalSpan = document.createElement("span");
    totalSpan.className = "hardware-total";
    totalSpan.textContent = total;
    rowDiv.appendChild(totalSpan);
    
    // Append the row to the container.
    var container = document.getElementById("hardwareinformationplugin");
    if (container) {
      container.appendChild(rowDiv);
    }
  }

  // Clear the container.
  var container = document.getElementById("hardwareinformationplugin");
  if (container) {
    container.innerHTML = "";
  }

  // Process CPU statistics.
  if (typeof json["cpustat"] !== "undefined") {
    var cpuStat = json["cpustat"];
    if (prevCPUStat != null) {
      for (var id in cpuStat) {
        if (cpuStat.hasOwnProperty(id) && id !== "global") {
          var deltaTotal = cpuStat[id]["total"] - prevCPUStat[id]["total"];
          var deltaIdle = cpuStat[id]["idle"] - prevCPUStat[id]["idle"];
          var usagePercent = 0;
          if (deltaTotal !== 0) {
            usagePercent = parseInt(100 - (100 * deltaIdle / deltaTotal), 10);
          }
          createRow("CPU " + (parseInt(id, 10) + 1), usagePercent, "");
        }
      }
    }
    prevCPUStat = cpuStat;
  }

  // Process storage (memory/disks) information.
  if (typeof json["storage"] !== "undefined") {
    for (var store in json["storage"]) {
      if (json["storage"].hasOwnProperty(store)) {
        createRow(
          json["storage"][store]["NAME"],
          json["storage"][store]["USAGE"],
          json["storage"][store]["TOTAL"]
        );
      }
    }
  }
}


/*

var prevCPUStat = null;

function hardwareinformationpluginUpdate(json) {
  // Helper function to create a table row.
  function createRow(label, usage, total) {
    var tr = document.createElement("tr");

    // Create the <th> with a <span> for the label.
    var th = document.createElement("th");
    var spanLabel = document.createElement("span");
    spanLabel.textContent = label;
    th.appendChild(spanLabel);
    tr.appendChild(th);

    // Create the first <td> that holds an inner table for percentages.
    var tdPercentage = document.createElement("td");
    tdPercentage.setAttribute("align", "right");

    var innerTable = document.createElement("table");
    innerTable.className = "hardwareinformation_percentage";

    var tdUsed = document.createElement("td");
    tdUsed.className = "used";
    tdUsed.setAttribute("width", usage + "%");
    innerTable.appendChild(tdUsed);

    var tdUnused = document.createElement("td");
    tdUnused.className = "unused";
    tdUnused.setAttribute("width", (100 - usage) + "%");
    innerTable.appendChild(tdUnused);

    tdPercentage.appendChild(innerTable);
    tr.appendChild(tdPercentage);

    // Create the <td> that displays the usage percentage.
    var tdUsage = document.createElement("td");
    tdUsage.setAttribute("align", "right");
    var spanUsage = document.createElement("span");
    spanUsage.textContent = usage + "%";
    tdUsage.appendChild(spanUsage);
    tr.appendChild(tdUsage);

    // Create the <td> for the total value.
    var tdTotal = document.createElement("td");
    tdTotal.setAttribute("align", "right");
    var spanTotal = document.createElement("span");
    spanTotal.textContent = total;
    tdTotal.appendChild(spanTotal);
    tr.appendChild(tdTotal);

    // Append the new row to the container.
    var container = document.getElementById("hardwareinformationplugin");
    if (container) {
      container.appendChild(tr);
    }
  }

  // Clear the container.
  var container = document.getElementById("hardwareinformationplugin");
  if (container) {
    container.innerHTML = "";
  }

  // Process CPU statistics.
  if (typeof json["cpustat"] !== "undefined") {
    var cpuStat = json["cpustat"];
    if (prevCPUStat != null) {
      for (var id in cpuStat) {
        if (cpuStat.hasOwnProperty(id) && id !== "global") {
          var deltaTotal = cpuStat[id]["total"] - prevCPUStat[id]["total"];
          var deltaIdle = cpuStat[id]["idle"] - prevCPUStat[id]["idle"];
          var usagePercent = 0;
          if (deltaTotal !== 0) {
            usagePercent = parseInt(100 - 100 * deltaIdle / deltaTotal, 10);
          }
          createRow("CPU " + (parseInt(id, 10) + 1), usagePercent, "");
        }
      }
    }
    prevCPUStat = cpuStat;
  }

  // Process storage (memory/disks) information.
  if (typeof json["storage"] !== "undefined") {
    for (var store in json["storage"]) {
      if (json["storage"].hasOwnProperty(store)) {
        createRow(
          json["storage"][store]["NAME"],
          json["storage"][store]["USAGE"],
          json["storage"][store]["TOTAL"]
        );
      }
    }
  }
}
*/


/* ORGINAL CODE
var prevCPUStat = null;

function hardwareinformationpluginUpdate(json) {
    function createRow(label, usage, total) {
        var tr = $("<tr>");
        tr.append($('<th>').append($('<span>').append(label)));
        tr.append($('<td align="right">').append($('<table class="hardwareinformation_percentage">')
                                .append($('<td class="used" width="' + usage + '%">'))
                                .append($('<td class="unused" width="' + (100-usage) + '%">'))
                            ));
        tr.append($('<td align="right">').append($("<span>").append(usage + '%')));
        tr.append($('<td align="right">').append($("<span>").append(total)));
        $("#hardwareinformationplugin").append(tr);
    }
    
    $("#hardwareinformationplugin").empty();
    
    // CPUs
    if (typeof json["cpustat"] !== 'undefined') {
        var cpuStat = json["cpustat"];
        if (prevCPUStat != null) {
            for (var id in cpuStat) {
                if (id != 'global') {
                    var deltaTotal = cpuStat[id]['total'] - prevCPUStat[id]['total'];
                    var deltaIdle = cpuStat[id]['idle'] - prevCPUStat[id]['idle'];
                    var usagePercent = 0;
                    if (deltaTotal != 0)
                        usagePercent = parseInt(100-100*deltaIdle/deltaTotal);
                    createRow("CPU " + (parseInt(id)+1), usagePercent, '');
                }
            }
        }
        prevCPUStat = cpuStat; 
    }
    
    // Memory and disks
    if (typeof json["storage"] !== 'undefined') {
        for (store in json["storage"]) {
            createRow(json["storage"][store]['NAME'], json["storage"][store]['USAGE'], json["storage"][store]['TOTAL']);
        }
    }
}
*/