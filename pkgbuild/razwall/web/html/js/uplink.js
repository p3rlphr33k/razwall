// Create a stub for console if not available
if (typeof console === 'undefined') {
  var console = { log: function() {} };
}

// colors and mappings
var uplink_colors = {
  'offline': '#993333',
  'online': '#339933',
  'pending': '#FF9933',
  'unmanaged': '#666666'
};

var status_color = {
  'DEAD': uplink_colors['pending'],
  'INACTIVE': uplink_colors['offline'],
  'ACTIVE': uplink_colors['online'],
  'CONNECTING': uplink_colors['pending'],
  'DISCONNECTING': uplink_colors['pending'],
  'FAILURE': uplink_colors['pending']
};

var RUNNING_STATUS_REQUEST = false;
var UPLINKS_SCRIPT = '/cgi-bin/uplinks-status.cgi';

// helper: perform a POST (form-urlencoded) using Fetch
function post(url, data, callback) {
  var formData = new URLSearchParams();
  for (var key in data) {
    if (data.hasOwnProperty(key)) {
      formData.append(key, data[key]);
    }
  }
  fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: formData.toString(),
    cache: 'no-cache'
  })
    .then(function(response) { return response.text(); })
    .then(function(text) { callback(text); })
    .catch(function(error) {
      console.error('Error during POST:', error);
    });
}

// returns online color if status is truthy; otherwise offline
function statusToColor(status) {
  return status ? uplink_colors['online'] : uplink_colors['offline'];
}

// Install uplink actions:
function installUplinksActions() {
  // For each uplink switch
  document.querySelectorAll('.uplink-switch').forEach(function(o) {
    o.addEventListener('click', function() {
      // Set spinner image
      o.setAttribute('src', '/images/indicator.gif');
      // Assume the DOM structure is such that o.parentElement.parentElement is the row.
      var row = o.parentElement.parentElement;
      var status_col = row.querySelector('.uplink-color');
      var action_col = row.querySelector('.uplink-action');
      var statusElem = action_col ? action_col.querySelector('.uplink-status') : null;
      var uplinkElem = action_col ? action_col.querySelector('.uplink') : null;
      if (!uplinkElem) {
        return;
      }
      // The matched uplinks are selected by a class name that includes the uplink value.
      var matched_uplinks = document.querySelectorAll('.uplink-name-' + uplinkElem.value);

      // Set color to pending in all matched uplinks
      matched_uplinks.forEach(function(item) {
        var sc = item.querySelector('.uplink-color');
        if (sc) {
          sc.style.backgroundColor = uplink_colors['pending'];
        }
        var backup = item.querySelector('.link-type');
        if (backup) {
          backup.style.backgroundColor = uplink_colors['pending'];
        }
      });
      
      var actionVal = (statusElem && statusElem.value === "Disconnect") ? "stop" : "start";
      // Update status text to pending
      changeStatusText(status_col, "pending", actionVal);
      
      RUNNING_STATUS_REQUEST = true;
      
      // Hide managed switches in each matched uplink
      matched_uplinks.forEach(function(item) {
        item.querySelectorAll('.uplink-switch-managed').forEach(function(el) {
          el.style.display = 'none';
        });
      });
      
      // Send POST request
      post(UPLINKS_SCRIPT, { 'action': actionVal, 'uplink': uplinkElem.value }, function(response) {
        var obj = responseToObject(response);
        changeImage(o, obj, function() {
          return isAlive(obj);
        });
        var color = status_color[obj.status];
        matched_uplinks.forEach(function(item) {
          var sc = item.querySelector('.uplink-color');
          if (sc) {
            sc.style.backgroundColor = color;
          }
          var backup = item.querySelector('.link-type');
          if (backup) {
            backup.style.backgroundColor = color;
          }
        });
        var newAction = isAlive(obj) ? "on" : "off";
        if (newAction === "off" && obj.managed === "off") {
          newAction = "stopped";
        }
        newAction = (obj.status === 'FAILURE') ? 'failure' :
                    (obj.status === 'DEAD') ? 'dead' :
                    (obj.status === 'INACTIVE' && isBackupLink(obj, row) ? 'hold' : newAction);
        changeStatusText(status_col, newAction, null, obj);
        if (statusElem) {
          setAction(statusElem, isAlive(obj) ? "on" : "off");
        }
        updateUptime(matched_uplinks, obj);
        setUplinkData(matched_uplinks, obj);
        RUNNING_STATUS_REQUEST = false;
        matched_uplinks.forEach(function(item) {
          item.querySelectorAll('.uplink-switch-managed').forEach(function(el) {
            el.style.display = ''; // restore default display
          });
        });
        // Fade out abort message (simple display toggle)
        var abortMsg = document.getElementById('abort-message');
        if (abortMsg) {
          abortMsg.style.display = 'none';
        }
      });
      
      // Immediately show the abort message
      var abortMsg = document.getElementById('abort-message');
      if (abortMsg) {
        abortMsg.style.display = 'block';
      }
      
    });
  });
  
  // For each uplink-switch-managed button
  document.querySelectorAll('.uplink-switch-managed').forEach(function(o) {
    o.addEventListener('click', function() {
      var row = o.parentElement.parentElement;
      var status_col = row.querySelector('.uplink-color');
      var action_col = row.querySelector('.uplink-action');
      var managed = action_col ? action_col.querySelector('.uplink-managed') : null;
      var uplinkElem = action_col ? action_col.querySelector('.uplink') : null;
      if (!uplinkElem) {
        return;
      }
      var matched_uplinks = document.querySelectorAll('.uplink-name-' + uplinkElem.value);
      var managed_icon, managed_text, switch_image;
      // For simplicity, use the first matched uplink for these elements
      if (matched_uplinks.length > 0) {
        var first = matched_uplinks[0];
        managed_icon = first.querySelector('.uplink-switch-managed');
        managed_text = first.querySelector('.uplink-managed');
        switch_image = first.querySelector('.uplink-switch');
      }
      var actionVal = (managed && managed.value === "off") ? "unmanage" : "manage";
      if (managed_icon) {
        managed_icon.setAttribute('src', '/images/indicator.gif');
      }
      post(UPLINKS_SCRIPT, { 'action': actionVal, 'uplink': uplinkElem.value }, function(response) {
        var obj = responseToObject(response);
        changeImage(managed_icon, obj, function() {
          return isManaged(obj);
        });
        if (managed_text) {
          managed_text.value = (obj.managed === "on") ? "off" : "on";
        }
        if (switch_image) {
          if (obj.managed === "on") {
            switch_image.style.display = 'none';
          } else {
            switch_image.style.display = '';
          }
        }
      });
    });
  });
}

// Simple utility functions

function isManaged(uplink) {
  return (uplink.managed === "on");
}

function isAlive(uplink) {
  return (uplink.status === "ACTIVE" || uplink.status === "DEAD");
}

function isBackupLink(obj, row) {
  return (obj.managed === 'on' && row.classList.contains("backup-link"));
}

function setAction(statusElem, action) {
  statusElem.value = (action === "on") ? 'Disconnect' : 'Connect';
}

function changeImage(container, response, status_func) {
  var tmp_stat = status_func();
  container.setAttribute('src', tmp_stat ? "/images/on.png" : "/images/off.png");
}

function changeStatusText(status, stat, c_stat, obj) {
  // Hide any elements with class "uplink-status-text" inside status
  status.querySelectorAll('.uplink-status-text').forEach(function(elem) {
    elem.style.display = 'none';
  });
  
  if (stat === "pending") {
    if (c_stat === "start") {
      status.querySelectorAll('.uplink-status-connect').forEach(function(elem) {
        elem.style.display = '';
      });
    } else {
      status.querySelectorAll('.uplink-status-disconnect').forEach(function(elem) {
        elem.style.display = '';
      });
    }
  } else if (stat === "on") {
    status.querySelectorAll('.uplink-status-on').forEach(function(elem) {
      elem.style.display = '';
    });
  } else if (stat === "off") {
    status.querySelectorAll('.uplink-status-off').forEach(function(elem) {
      elem.style.display = '';
    });
  } else if (stat === "stopped") {
    status.querySelectorAll('.uplink-status-stopped').forEach(function(elem) {
      elem.style.display = '';
    });
  } else if (stat === "failure") {
    status.querySelectorAll('.uplink-status-off').forEach(function(elem) {
      var statusText = elem.querySelector('.status-text');
      var failureElem = document.getElementById('failure');
      if (statusText && failureElem) {
        statusText.innerHTML = failureElem.innerHTML;
      }
      if (obj && obj.data && obj.data.last_retry !== '') {
        var lastRetry = elem.querySelector('.uplink-last-retry');
        if (lastRetry) {
          lastRetry.innerHTML = obj.data.last_retry;
          lastRetry.style.display = '';
        }
      }
      elem.style.display = '';
    });
  } else if (stat === "dead") {
    status.querySelectorAll('.uplink-status-off').forEach(function(elem) {
      var statusText = elem.querySelector('.status-text');
      var deadElem = document.getElementById('dead');
      if (statusText && deadElem) {
        statusText.innerHTML = deadElem.innerHTML;
      }
      elem.style.display = '';
    });
  } else if (stat === "hold") {
    status.querySelectorAll('.uplink-status-off').forEach(function(elem) {
      var statusText = elem.querySelector('.status-text');
      var onholdElem = document.getElementById('onhold');
      if (statusText && onholdElem) {
        statusText.innerHTML = onholdElem.innerHTML;
      }
      elem.style.display = '';
    });
  }
}

function updateUptime(uplinkRows, uplink) {
  if (isAlive(uplink)) {
    // uplinkRows may be a NodeList of matched uplink elements
    uplinkRows.forEach(function(item) {
      var uptimeElem = item.querySelector('.uplink-uptime');
      if (uptimeElem) {
        uptimeElem.innerHTML = " - " + uplink.uptime;
        uptimeElem.style.display = '';
      }
    });
  }
}

function inA(status, status_list) {
  for (var i = 0; i < status_list.length; i++) {
    if (status_list[i] === status) return true;
  }
  return false;
}

var uplinks = null;
function statusCheck() {
  post('/cgi-bin/uplinks-status.cgi', { 'action': 'list' }, function(response) {
    if (RUNNING_STATUS_REQUEST) {
      setTimeout(statusCheck, 10000);
      return false;
    }
    uplinks = responseToObject(response);
    document.querySelectorAll('.uplink-item').forEach(function(o) {
      var uplinkInput = o.querySelector('.uplink');
      if (uplinkInput) {
        var name = uplinkInput.value;
        var uplinkData = uplinkByName(name);
        if (uplinkData) {
          var color = status_color[uplinkData.status];
          o.querySelectorAll('.uplink-color').forEach(function(elem) {
            elem.style.backgroundColor = color;
          });
          o.querySelectorAll('.link-type').forEach(function(elem) {
            elem.style.backgroundColor = color;
          });
          var stat = isAlive(uplinkData) ? "on" : "off";
          var image = o.querySelector('.uplink-switch');
          if (uplinkData.managed === "off") {
            if (image) image.style.display = '';
          } else {
            if (image) image.style.display = 'none';
          }
          changeImage(image, uplinkData, function() { return isAlive(uplinkData); });
          if (inA(uplinkData.status, ["CONNECTING", "DISCONNECTING"])) {
            changeStatusText(o.querySelector('.uplink-color'), "pending", (uplinkData.status === "CONNECTING" ? "start" : "stop"));
            if (image) image.setAttribute('src', '/images/indicator.gif');
          } else {
            stat = (uplinkData.status === 'FAILURE') ? 'failure' : (uplinkData.status === 'DEAD' ? 'dead' :
                  (uplinkData.status === 'INACTIVE' && isBackupLink(uplinkData, o) ? 'hold' : stat));
            changeStatusText(o.querySelector('.uplink-color'), stat, null, uplinkData);
          }
          var statusElem = o.querySelector('.uplink-status');
          if (statusElem) {
            setAction(statusElem, isAlive(uplinkData) ? "on" : "off");
          }
          updateUptime(o, uplinkData);
          setUplinkData(o, uplinkData);
        }
      }
    });
    setTimeout(statusCheck, 5000);
  });
}

function get(data, optional) {
  if (typeof data === 'undefined' || data === null) return optional;
  return data;
}

function setUplinkData(obj, uplink) {
  var naText = document.getElementById('NA') ? document.getElementById('NA').textContent : 'NA';
  var typeElem = obj.querySelector('.type');
  if (typeElem) {
    typeElem.innerHTML = get(uplink.data.type, naText);
  }
  var interfaceElem = obj.querySelector('.interface');
  if (interfaceElem) {
    interfaceElem.innerHTML = get(uplink.data.interface, naText);
  }
  var ipElem = obj.querySelector('.ip');
  if (ipElem) {
    ipElem.innerHTML = get(uplink.data.ip, naText);
  }
  var gatewayElem = obj.querySelector('.gateway');
  if (gatewayElem) {
    gatewayElem.innerHTML = get(uplink.data.gateway, naText);
  }
}

function uplinkByName(name) {
  for (var i = 0; uplinks && i < uplinks.length; i++) {
    if (uplinks[i].name === name) return uplinks[i];
  }
  return null;
}

function initStatusCheck() {
  try {
    statusCheck();
  } catch (e) {
    // console.log(e);
  }
}

function responseToObject(response) {
  var obj = null;
  try {
    obj = eval("(" + response + ")");  // Note: using eval can be unsafe.  
  } catch (e) {
    // Handle error as needed.
  }
  return obj;
}

function initUp() {
  var abortMsg = document.getElementById('abort-message');
  if (abortMsg) {
    abortMsg.style.display = 'none';
  }
  installUplinksActions();
  initStatusCheck();
}

// When DOM is loaded, initialize the uplink status and actions.
document.addEventListener('DOMContentLoaded', function() {
  initUp();
});


/* ORIGINAL CODE

if(typeof console == 'undefined') {
    var console = { 'log': function() {}}
}

var uplink_colors = {'offline' : '#993333',
                     'online' : '#339933',
                     'pending' : '#FF9933',
                     'unmanaged' : '#666666'}
// mapping status to color 
var status_color = {'DEAD' : uplink_colors['pending'],
                    'INACTIVE' : uplink_colors['offline'],
                    'ACTIVE' : uplink_colors['online'],
                    'CONNECTING' : uplink_colors['pending'],
                    'DISCONNECTING' : uplink_colors['pending'],
                    'FAILURE' : uplink_colors['pending']    
}
//defines whether a current status request is running or not, if
// so, no further status request is fired

var RUNNING_STATUS_REQUEST = false;
var UPLINKS_SCRIPT = '/cgi-bin/uplinks-status.cgi'

function statusToColor(status) {
    if(status) return uplink_colors['online'];
    return uplink_colors['offline']
}

function installUplinksActions() {
    $('.uplink-switch').each(function(i, o) {
        $(o).click(function() {
             //OUTDATED: If the uplink is in connecting state, a click should be prevented.
             // A click is allowed, since the user should be able to stop the connection
             // at any point 
             
            $(o).attr('src', '/images/indicator.gif');
            var row = $(o).parent().parent();
            var status_col = $('.uplink-color', row);
            var action_col = $('.uplink-action', row);
            var status = $('.uplink-status', action_col);
            var uplink = $('.uplink', action_col);
            var matched_uplinks = $('.uplink-name-' + uplink.val());
            var status_col = $('.uplink-color', matched_uplinks);
            var backup_col = $('.link-type', matched_uplinks);
            // setting status color and description 
            status_col.css('background-color', uplink_colors['pending']);
            backup_col.css('background-color', uplink_colors['pending']);
            var action = status.val() == "Disconnect" ? "stop" : "start";
            changeStatusText(status_col, "pending", action);
            
            RUNNING_STATUS_REQUEST = true;
            // If the uplink is being activated or deactivated, changing the managed
            // status causes the manage status to be dismissed, since the activating
            // process may return at a latter point, which revokes the previous change
            // of the manage status.
            // Hence the manage button is hidden if the de/activating button is running.
            
            $('.uplink-switch-managed', matched_uplinks).hide();
            $.post(UPLINKS_SCRIPT, 
                   {'action' : action, 'uplink' : uplink.val()},
                   function(response) {
                       var obj = responseToObject(response);
                       // Changing the image 
                       changeImage($(o), obj, function () {
                           return isAlive(obj);
                       });
                       
                       color = status_color[obj.status];
                       status_col.css('background-color', color);
                       backup_col.css('background-color', color);
                       
                       var action = isAlive(obj) ? "on" : "off";
                       if(action == "off" && obj.managed == "off") action="stopped";
                       action = obj.status == 'FAILURE' ? 'failure' : (obj.status == 'DEAD' ? 'dead' : (obj.status == 'INACTIVE' && isBackupLink(obj, row) ? 'hold' : action))
                       changeStatusText(status_col, action, null, obj);
                       setAction(status, isAlive(obj) ? "on" : "off");
                       updateUptime(matched_uplinks, obj)
                       setUplinkData(matched_uplinks, obj);
                       RUNNING_STATUS_REQUEST = false;
                       $('.uplink-switch-managed', matched_uplinks).show();
                       $('#abort-message').fadeOut(500);
                   });
                   // Displaying the notification that the connection can be stopped by clicking
                   // on the spinner image
                    
                  $('#abort-message').fadeIn(500);
            });

    })
    $('.uplink-switch-managed').each(function(i, o) {
        $(o).click(function() {
            
            var row = $(o).parent().parent();
            var status_col = $('.uplink-color', row);
            var action_col = $('.uplink-action', row);
            var managed = $('.uplink-managed', action_col);
            var uplink = $('.uplink', action_col);
            var matched_uplinks = $('.uplink-name-' + uplink.val());
            var managed_icon = $('.uplink-switch-managed', matched_uplinks);
            var managed_text = $('.uplink-managed', matched_uplinks);
            var switch_image = $('.uplink-switch', matched_uplinks);
            
            var action = managed.val() == "off" ? "unmanage" : "manage"
            // Starting the spinner
            managed_icon.attr('src', '/images/indicator.gif');
            $.post(UPLINKS_SCRIPT,
                   {'action' : action, uplink : uplink.val()},
                   function(response) {
                       var obj = responseToObject(response);
                       // Switching image 
                       changeImage(managed_icon, obj, function() {
                           return isManaged(obj);
                       });
                       // Switching status
                       managed_text.val(obj.managed == "on" ? "off" : "on");
                       if(obj.managed == "on") switch_image.hide();
                       else
                            switch_image.show();
                   });
            
        })
    });
}

function isManaged(uplink) {
    return (uplink.managed == "on");
}

function isAlive(uplink) {
    return (uplink.status == "ACTIVE" || uplink.status == "DEAD"); 
}

function isBackupLink(obj, row) {
    return obj.managed == 'on' && row.hasClass("backup-link")
}

function setAction(status, action) {
    if(action == "on") status.val('Disconnect');
    else status.val('Connect');
}

function changeImage(container, response, status_func) {
    var tmp_stat = status_func();
    if(tmp_stat) {
        container.attr('src', "/images/on.png");
    }
    else {
        container.attr('src', "/images/off.png");
    }
}

function changeStatusText(status, stat, c_stat, obj) {
    var c_stat = typeof c_stat == "undefined" ? null : c_stat;
    var obj = typeof obj == "undefined" ? null : obj;
    // hiding the descriptions
    $('.uplink-status-text', status).hide();
    
    if(stat == "pending") {
        if(c_stat == "start") 
            $('.uplink-status-connect', status).show()
        else
            $('.uplink-status-disconnect', status).show()
    }
    else if(stat == "on") {
        $('.uplink-status-on', status).show()
    }
    else if(stat == "off") {
        $('.uplink-status-off', status).show();
    }
    else if(stat == "stopped") {
        $('.uplink-status-stopped', status).show();
    }
    else if(stat == "failure") {
        $('.status-text', $('.uplink-status-off', status)).html($('#failure').html());
        if(obj.data.last_retry != '') {
            $('.uplink-last-retry', $('.uplink-status-off', status)).html(obj.data.last_retry);
            $('.uplink-last-retry', $('.uplink-status-off', status)).show();
        }
        $('.uplink-status-off', status).show();
    }
    else if(stat == "dead") {
        $('.status-text', $('.uplink-status-off', status)).html($('#dead').html());
        $('.uplink-status-off', status).show();
    }
    else if(stat == "hold") {
        $('.status-text', $('.uplink-status-off', status)).html($('#onhold').html());
        $('.uplink-status-off', status).show();
    }
}

function updateUptime(uplink_row, uplink) {
    if(isAlive(uplink)) {
        $('.uplink-uptime', uplink_row).html(" - " + uplink.uptime).show();
    }
        
}

function inA(status, status_list) {
    var i = 0;
    for(i = 0; i < status_list.length; i++) {
        if(status_list[i] == status) return true;
    }
    return false;
}

var uplinks = null;
function statusCheck() {
    // Retrieving uplinks statuses
    $.post('/cgi-bin/uplinks-status.cgi', {'action' : 'list'}, function(response) {
        if(RUNNING_STATUS_REQUEST) {
            setTimeout("statusCheck()", 10000);
            return false;
        }
        uplinks = responseToObject(response);
        $('.uplink-item').each(function(i, o) {
            var name = $('.uplink', $(o)).val();
            var uplink = uplinkByName(name);
            if(uplink) {
                color = status_color[uplink.status];
                $('.uplink-color', $(o)).css('background-color', color);
                $('.link-type', $(o)).css('background-color', color);
                
                var stat = isAlive(uplink) ? "on" : "off"
                var image = $('.uplink-switch', $(o));
                if(uplink.managed == "off") {
                    image.show();
                }
                else {
                    image.hide();
                }
                
                changeImage(image, uplink, function() {
                    return isAlive(uplink);
                });
                
                if(inA(uplink.status, ["CONNECTING", "DISCONNECTING"])) {
                    changeStatusText($('.uplink-color', $(o)), "pending", (uplink.status == "CONNECTING" ? "start" : "stop"))
                    image.attr('src', '/images/indicator.gif');
                }
                else {
                    var row = $(o);
                    stat = uplink.status == 'FAILURE' ? 'failure' : (uplink.status == 'DEAD' ? 'dead' : (uplink.status == 'INACTIVE' && isBackupLink(uplink, row) ? 'hold' : stat))
                    changeStatusText($('.uplink-color', $(o)), stat, null, uplink);
                }
                setAction($('.uplink-status', $(o)), isAlive(uplink) ? "on" : "off");
                updateUptime($(o), uplink);
                setUplinkData($(o), uplink);
            }
        });
        setTimeout("statusCheck()", 5000);
    });
}

function get(data, optional) {
    if(typeof data == 'undefined' || data == null) return optional;
    return data;
}

function setUplinkData(obj, uplink) {
    $('.type', $(obj)).html(get(uplink.data.type, $('#NA').text()));
    $('.interface', $(obj)).html(get(uplink.data.interface, $('#NA').text()));
    $('.ip', $(obj)).html(get(uplink.data.ip, $('#NA').text()));
    $('.gateway', $(obj)).html(get(uplink.data.gateway, $('#NA').text()));
}

function uplinkByName(name) {
    var chain = uplinks
    for(i = 0; i < chain.length; i++) {
        if(chain[i].name == name) return chain[i];
    }
    return null;
}

function initStatusCheck() {
    try {
        statusCheck();
    }
    catch(e) {
        //console.log(e);
    }

}

function responseToObject(response) {
    try {
        var obj = eval("(" + response + ")")
    }
    catch(e) {
    }
    return obj;
}

function initUp() {
    $('#abort-message').hide();
    installUplinksActions();
    initStatusCheck();
}
$(document).ready(function() {
    initUp();
})

*/