(function( $ ) {
    $.fn.emiapply = function(options) {
        var that = $(this);
        
        var settings = {
            action: "apply",
            controllername: ""
        };
        if (options) {
            $.extend(settings, options);
        }
        
        var running = null;
        
        var button = that.find("input[type=button]");
        var spinner = that.find(".wait");
        
        var init = function() {
            button.bind('click', function() {
                button.hide();
                spinner.show();
                $.ajax({
                    type: 'POST',
                    url: 'json?ACTION='+settings['action']+'&CONTROLLERNAME='+settings['controllername']+'&_nodata=true',
                    success: methods.success,
                    error: methods.error
                });
            });
        }
        
        var methods = {
            poll: function() {
                $.ajax({
                    type: 'GET',
                    url: "?",
                    success: methods.success
                });
            },
            success: function(data) {
                that.hide();
                button.show();
                spinner.hide();
                if(running != null) {
                    clearInterval(running);
                    running = null;
                }
            },
            error: function(id, error_type, xhr, ajaxOptions, thrownError) {
                if((running == null && error_type == 'timeout') || (typeof xhr.status == 'undefined')) {
                    running = setInterval(methods.poll, 4000);
                } else{
                    //error occured, reload in order to show that error!
                    window.location = 'json?CONTROLLERNAME='+settings['controllername']+'&_nodata=true';
                }
            }
        }
        
        init();
    };
})( jQuery );
