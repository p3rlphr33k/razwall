function jobsinformationpluginInit(json) {
    if (typeof json['jobs'] !== 'undefinded') {
        $("#jobsinformationplugin-information").empty();
        var now = parseFloat(json['time']);
        
        var keys = [];
        for (jobName in json['jobs']) {
            keys.push(jobName);
        }
        keys.sort();
        
        for (var i = 0; i < keys.length; i++) {
            var jobName = keys[i];
            var tr = $("<tr>");
            var job = json['jobs'][jobName];
            
            tr.append($('<td>').append(job['name']));
            var statusClass = '';
            if (job['sub'] == 'ok') {
                if (job['status'] == 'stop') {
                    statusClass = 'red';
                } else if (job['status'] == 'start') {
                    statusClass = 'green';
                }
            }
            tr.append($('<td class="' + statusClass + '">').append(job['status']));
            tr.append($('<td>').append(job['sub']));
            
            var running_action = job['running_action'];
            var schedule = job['schedule'];
            
            if (schedule == 'executing') {
                schedule = "exec " + running_action;
            } else if (schedule == 'waiting_depends') {
                schedule = "wait depends";
            }
            tr.append($('<td>').append(schedule));
            
            var t0 = parseFloat(job['t0']);
            var t1 = parseFloat(job['t1']);
            var seconds;
            if (t0 > t1) {
                seconds = parseInt(now - t0);
            } else {
                seconds = parseInt(t1 - t0);
            }
            if (seconds < 0)
                seconds = 0;
            var running_time;
            if (seconds > 60) {
                var minutes = parseInt(seconds/60);
                seconds = seconds % 60;
                running_time = "" + minutes + "m " + seconds + "s";
            } else {
                running_time = "" + seconds + "s";
            }                
            tr.append($('<td>').append(running_time));
            
            var start_time = '';
            if (t0) {
                var date = new Date(t0*1000);
                start_time = "" + date.getFullYear() + "-";
                var t = (date.getMonth()+1);
                if (t < 10) t = "0" + t; else t = "" + t;
                start_time = start_time + t + "-";
                var t = (date.getDate()+1);
                if (t < 10) t = "0" + t; else t = "" + t;
                start_time = start_time + t + " ";
                
                var t = (date.getHours());
                if (t < 10) t = "0" + t; else t = "" + t;
                start_time = start_time + t + ":";
                var t = (date.getMinutes());
                if (t < 10) t = "0" + t; else t = "" + t;
                start_time = start_time + t;
            }
            tr.append($('<td>').append(start_time));
            
            $("#jobsinformationplugin-information").append(tr);
        }
    }

}

function jobsinformationpluginUpdate(json) {
    jobsinformationpluginInit(json);
}
