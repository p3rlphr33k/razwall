(function( $ ) {
    $.fn.emitoast = function(options) {
        var that = $(this);

        var settings = {
            type: "",
            title: "",
            message: "",
            message_key: "",
            confirmation_button: false,
            confirmation_button_label: 'OK',
            confirmation_callback: null,
            close_callback: null,
            toastr_options: null
        };

        if (options) {
            $.extend(settings, options);
        }

        var showToast = function() {
            var default_opts = {
                "closeButton": false,
                "debug": false,
                "newestOnTop": false,
                "progressBar": false,
                "positionClass": "toast-top-right",
                "preventDuplicates": false,
                "onclick": null,
                "showDuration": "300",
                "hideDuration": "1000",
                "timeOut": "5000",
                "extendedTimeOut": "1000",
                "showEasing": "swing",
                "hideEasing": "linear",
                "showMethod": "fadeIn",
                "hideMethod": "fadeOut"
            };

            if (settings.toastr_options != null)
                $.extend(default_opts, settings.toastr_options);
            toastr.options = default_opts;
            var confirmation_button = "";
            if (settings.confirmation_button) {
                toastr.options['timeOut'] = 0;
                toastr.options['extendedTimeOut'] = 0;
                toastr.options['tapToDismiss'] = false;
                var callback="";
                if (settings.confirmation_callback != null) {
                    if (settings.message_key != '')
                        callback = "execCallback('" + escape(settings.confirmation_callback) + "','" + settings.message_key + "');";
                    else
                        callback = "execCallback('" + escape(settings.confirmation_callback) + "', null);";

                }
                confirmation_button = '<br /><br /><button type="button" class="clear" onclick="' + callback + '">' + settings.confirmation_button_label + '</button>';
            }

            if (settings.close_callback != null) {
                toastr.options["onCloseClick"] = settings.close_callback;
            }

            var $toast = toastr[settings.type](settings.message + confirmation_button, settings.title);

            //close the toast on button click
            if ($toast.find('.clear').length) {
                $toast.delegate('.clear', 'click', function () {
                    toastr.clear($toast, { force: true });
                });
            }
        };

        showToast();
    };
})( jQuery );

function execCallback(callback, parameter){
    if (parameter != null)
        eval('var func = ' + unescape(callback) + ';func("'+parameter+'")');
    else
        eval('var func = ' + unescape(callback) + ';func()');
}


