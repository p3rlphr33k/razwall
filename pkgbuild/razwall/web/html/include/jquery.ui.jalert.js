(function($) {

    $.jPopup = function(message, errorLevel, callback, options, buttons) {
        var defaults = {
            message: message,
            errorLevel: errorLevel,
            wrapperClass: "jpopup",
            minHeight: 5
        };
        options = $.extend(defaults, options);

        var dialogCSS = "ui-state-error";
        var iconCSS = " ui-icon-alert";

        switch (options.errorLevel) {
            case "highlight":
                dialogCSS = " ui-state-highlight";
                iconCSS = "  ui-icon-notice";
                break;

            case "error":
                dialogCSS = ""; // " ui-state-error";
                iconCSS = " ui-icon-alert";
                break;

            default:
                dialogCSS = "";
                iconCSS = ""; // "ui-icon-info";
                break;
        }

//    	dialog = $("<table><tr><th valign=\"middle\"></th><td class=\"" + dialogCSS + "\" style=\"border: none; background: transparent;\" valign=\"middle\">" + options.message + "</td></tr></table>");

        var dialog = "";
        if (iconCSS != "")
        	dialog = $("<table><tr><th valign=\"middle\"><span class=\"ui-icon" + iconCSS + "\"></span></th><td style=\"border: none; \" valign=\"middle\">" + options.message + "</td></tr></table>");
        else
        	dialog = $("<table><tr><th valign=\"middle\"></th><td style=\"border: none; \" valign=\"middle\">" + options.message + "</td></tr></table>");

        var dialogOptions = {
            bgiframe: true,
            dialogClass: options.wrapperClass + dialogCSS,
            resizable: false,
            minHeight: options.minHeight,
            modal: true,
            buttons: buttons,
            close: function(event, ui) {
                dialog.remove();
            }
        }
        options = $.extend(dialogOptions, options);

        dialog.dialog(options);
    };

    $.jConfirm = function(message, errorLevel, callback, options) {
        var buttons = {
            'Ok': function() {
                $(this).dialog('close');
                if (callback) {
                    callback(true);
                }
            },
            Cancel: function() {
                $(this).dialog('close');
                if (callback) {
                    callback(false);
                }
            }
        };

        $.jPopup(message, errorLevel, callback, options, buttons);
    };

    $.jAlert = function(message, errorLevel, callback, options) {
        var buttons = {
            'Ok': function() {
                $(this).dialog('close');
                if (callback) {
                    callback(true);
                }
            }
        };

        $.jPopup(message, errorLevel, callback, options, buttons);
    };
})(jQuery);