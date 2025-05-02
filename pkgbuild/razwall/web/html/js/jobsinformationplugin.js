function jobsinformationpluginInit(json) {
  // Verify "jobs" exists in json. (Correcting "undefinded" to "undefined".)
  if (typeof json['jobs'] !== 'undefined') {
    // Clear the container.
    var container = document.getElementById("jobsinformationplugin-information");
    if (container) {
      container.innerHTML = "";
    }
    
    var now = parseFloat(json['time']);
    var keys = [];
    // Build an array of job names.
    for (var jobName in json['jobs']) {
      if (json['jobs'].hasOwnProperty(jobName)) {
        keys.push(jobName);
      }
    }
    keys.sort();
    
    // Helper: Format a number into at least two digits.
    function pad2(number) {
      return (number < 10 ? "0" : "") + number;
    }

    // Loop through the sorted job names.
    for (var i = 0; i < keys.length; i++) {
      var jobName = keys[i];
      var job = json['jobs'][jobName];

      // Create a new table row.
      var tr = document.createElement("tr");

      // First cell: Job name.
      var tdName = document.createElement("td");
      tdName.textContent = job['name'];
      tr.appendChild(tdName);

      // Determine statusClass based on job status and sub.
      var statusClass = '';
      if (job['sub'] === 'ok') {
        if (job['status'] === 'stop') {
          statusClass = 'red';
        } else if (job['status'] === 'start') {
          statusClass = 'green';
        }
      }
      // Second cell: Status.
      var tdStatus = document.createElement("td");
      if (statusClass) {
        tdStatus.className = statusClass;
      }
      tdStatus.textContent = job['status'];
      tr.appendChild(tdStatus);

      // Third cell: Substatus.
      var tdSub = document.createElement("td");
      tdSub.textContent = job['sub'];
      tr.appendChild(tdSub);

      // Fourth cell: Schedule.
      var running_action = job['running_action'];
      var schedule = job['schedule'];
      if (schedule === 'executing') {
        schedule = "exec " + running_action;
      } else if (schedule === 'waiting_depends') {
        schedule = "wait depends";
      }
      var tdSchedule = document.createElement("td");
      tdSchedule.textContent = schedule;
      tr.appendChild(tdSchedule);

      // Fifth cell: Running time.
      var t0 = parseFloat(job['t0']);
      var t1 = parseFloat(job['t1']);
      var seconds;
      if (t0 > t1) {
        seconds = parseInt(now - t0, 10);
      } else {
        seconds = parseInt(t1 - t0, 10);
      }
      if (seconds < 0) seconds = 0;
      var running_time;
      if (seconds > 60) {
        var minutes = parseInt(seconds / 60, 10);
        seconds = seconds % 60;
        running_time = minutes + "m " + seconds + "s";
      } else {
        running_time = seconds + "s";
      }
      var tdRunTime = document.createElement("td");
      tdRunTime.textContent = running_time;
      tr.appendChild(tdRunTime);

      // Sixth cell: Start time.
      var start_time = '';
      if (t0) {
        var date = new Date(t0 * 1000);
        start_time = date.getFullYear() + "-" +
          pad2(date.getMonth() + 1) + "-" +
          pad2(date.getDate() + 1) + " " +
          pad2(date.getHours()) + ":" +
          pad2(date.getMinutes());
      }
      var tdStartTime = document.createElement("td");
      tdStartTime.textContent = start_time;
      tr.appendChild(tdStartTime);

      // Append the row to the container.
      if (container) {
        container.appendChild(tr);
      }
    }
  }
}

function jobsinformationpluginUpdate(json) {
  jobsinformationpluginInit(json);
}


/* ORIGINAL CODE 

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
*/