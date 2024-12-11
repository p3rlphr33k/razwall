(function( $ ) {
    var that = null;
    var baseLocation = "/manage/status/status.notifications.services/";
    var statusLocation = baseLocation + "?type=status&service=";
    var historyLocation = baseLocation + "?type=status&service=";
    var errorLocation = baseLocation + "?type=status&service=";
    var defaultSettings = {
        service: [],
        timeout: 2000,
        startMessage: "Notification listener is started",
        endMessage: "Notification listener is stopped"
    };
    var methods = {
        init: function(options) {
            if (options) {
                settings = $.extend({}, defaultSettings, options);
            }
            that = $(this);
            methods.start();
        },
        start: function() {
            var overlay = null;
            var container = null;
            var active = [];
            var timestamp = null;
            var errors = {};
            
            var createNotificationView = function() {
                var viewport_width = $(window).width();
                var viewport_height = $(window).height();
                var document_width = $(document).width();
                var document_height = $(document).height();
                overlay = $('<div></div>').attr('id', 'notification-overlay')
                             .css('width', document_width + 'px')
                             .css('height', document_height + 'px')
                             .css('opacity','0.0')
                container = $('<div></div>').attr('id', 'notification-container')
                var left = Math.round((viewport_width - 516) / 2);
                var top = Math.round((viewport_height - 86) / 2);
                /* Centering the container */
                container.css('top', top).css('left', left)
                content = $('<div></div>').addClass("content");
                /* Inserting the content view into the container */
                container.append(content)
                /* Inserting the container view into the body */
                $('body').append(overlay)
                $(that).append(container);
            }
            
            var createStatusView = function(type) {
                var status_view = $('<div style="display:none"></div>');
                status_view.attr('class', type + '-fancy');
                
                var content = $('<div></div>').attr('class', 'content');
                var layout = $('<table><tbody><tr></td></tbody></table>')
                layout.attr('cellpadding', '0')
                       .attr('cellspacing', '0')
                       .attr('border', '0')
                var sign_img = type == 'error' ? '/images/bubble_red_sign.png' : 
                                                 '/images/bubble_yellow_sign.png';
                var sign_img = $('<img alt="" src="' + sign_img + '"/>');
                var sign = $('<td></td>').attr('valign', 'middle')
                                          .attr('class','sign');
                sign.append($sign_img);
                var $text = $('<td></td>').attr('valign','middle')
                                          .attr('class','text')
                layout.find('tr').append(sign);
                layout.find('tr').append(text);
                var bottom_img = $('<img width="1" height="1" border="0" alt="" '+
                                    'src="/images/clear.gif"/>');
                var bottom = $('<div></div>').attr('class','bottom')
                bottom.append(bottom_img);
                
                content.append(layout);
                status_view.append(content);
                status_view.append(bottom);
                
                return $status_view;
            }
            
            var serviceInit = function(i, name) {
                console.log("init server: "+name);
                var status = {
                    location: statusLocation + name,
                    poll: function() {
                        $.ajax({
                            url: status.location,
                            type: 'GET',
                            cache: false,
                            success: status.success,
                            error: status.error
                        });
                    },
                    success: function(notification) {
                        if (notification.error) {
                            var found = jQuery.inArray(name, active);
                            if (found >= 0) {
                                active.splice(found, 1);
                            }
                            if (active.length == 0 && 
                                    overlay != null &&
                                    container != null &&
                                    overlay.is(":visible") &&
                                    container.is(":visible")) {
                                $(that).fadeTo(500, 0.0, function() {
                                    container.hide();
                                    overlay.fadeTo(500, 0.0, function() {
                                        overlay.hide();
                                    });
                                    
                                });
                            }
                        } else {
                            var found = jQuery.inArray(name, active);
                            if (found < 0) {
                                active.push(name);
                            }
                            if (container == null) {
                                createNotificationView();
                            }
                            var message = null;
                            $.each(notification.data, function(i, data) {
                                if (data.type == "debug") {
                                    return;
                                }
                                if (data.type == "error") {
                                    errors[data.time] = data.msg;
                                }
                                if (timestamp == null || data.time > timestamp) {
                                    message = data.msg;
                                    timestamp = data.time;
                                }
                            });
                            if (message == null && timestamp == null) {
                                message = settings.startMessage;
                            }
                            if (message != null) {
                                container.find('.content').html(message);
                                if (!overlay.is(":visible") &&
                                    !container.is(":visible")) {
                                    overlay.show().fadeTo(500, 0.66, function() {
                                        container.show();
                                        that.show();
                                    });
                                    container.show();
                                    overlay.show();
                                }
                            }
                        }
                        setTimeout(status.poll, settings.timeout);
                    },
                    error: function(id, error_type, xhr, ajaxOptions, thrownError) {
                        setTimeout(status.poll, settings.timeout);
                    }
                }
                status.poll();
            }
            
            $.each(settings.service, serviceInit);
        }
    };
    $.fn.notification = function( method ) {
        if ( methods[method] ) {
            return methods[method].apply( this, Array.prototype.slice.call( arguments, 1 ));
        } else if ( typeof method === 'object' || ! method ) {
            return methods.init.apply( this, arguments );
        } else {
            $.error( 'Method ' +  method + ' does not exist on jQuery.notification' );
        }
    };
})( jQuery );

function display_notifications(service, options) {
    settings = options || {};
    settings['service'] = []
    if(typeof service == 'string')
        settings['service'].push(service)
    else
        settings['service'] = service;
    $('#notification-view').notification(settings);
}
