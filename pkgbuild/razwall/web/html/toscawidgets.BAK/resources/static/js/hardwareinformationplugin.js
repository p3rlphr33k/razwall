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
