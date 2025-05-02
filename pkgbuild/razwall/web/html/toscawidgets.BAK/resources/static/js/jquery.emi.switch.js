/*
* +--------------------------------------------------------------------------+
* | Endian Firewall                                                          |
* +--------------------------------------------------------------------------+
* | Copyright (c) 2005-2013 Endian                                           |
* |         Endian GmbH/Srl                                                  |
* |         Bergweg 41 Via Monte                                             |
* |         39057 Eppan/Appiano                                              |
* |         ITALIEN/ITALIA                                                   |
* |         info@endian.com                                                  |
* |                                                                          |
* | emi is free software: you can redistribute it and/or modify           |
* | it under the terms of the GNU Lesser General Public License as published |
* | by the Free Software Foundation, either version 2.1 of the License, or     |
* | (at your option) any later version.                                      |
* |                                                                          |
* | emi is distributed in the hope that it will be useful,                |
* | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
* | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            |
* | GNU Lesser General Public License for more details.                      |
* |                                                                          |
* | You should have received a copy of the GNU Lesser General Public License |
* | along with emi.  If not, see <http://www.gnu.org/licenses/>.          |
* +--------------------------------------------------------------------------+
*/

(function( $ ) {
    $.fn.emiswitch = function(options) {
        var that = $(this);
        
        var settings = {
            reloadOnEnable: false,
            reloadOnDisable: false
        };
        if (options) {
            $.extend(settings, options);
        }
        
        var inputField = that.find("input");
        var switchField = that.find(".switch");
        var errorField = that.find(".fielderror");
        
        var key = inputField.attr("name");
        var description = $(".switch-controller > .description_" + key);
        var content = $(".switch-controller > .content_" + key);
        
        var init = function() {
            switchField.click(methods.execute);
        }
        
        var methods = {
            execute: function() {
                methods.disable();
                if (switchField.hasClass("True")) {
                    switchField.removeClass("True");
                }
                else {
                    switchField.removeClass("False");
                }
                switchField.addClass("wait");
                $.ajax({
                    type: 'GET',
                    url: "/manage/commands/commands.switch." + key,
                    success: methods.success,
                    error: methods.error,
                    dataType: "json"
                });
            },
            poll: function() {
                $.ajax({
                    type: 'GET',
                    url: "/manage/status/status.switch." + key,
                    success: methods.success,
                    error: methods.error,
                    dataType: "json"
                });
            },
            success:  function(response) {
                if (response == null) {
                    methods.poll();
                    return
                }
                var status = response['status'];
                var error = "";
                if (typeof(response['error']) != 'undefined') {
                    error = response['error'];
                }
                if (error != "") {
                    errorField.text(error);
                    errorField.removeClass("hidden");
                }
                else {
                    errorField.text("");
                    errorField.addClass("hidden");
                }
                switchField.removeClass("wait");
                if (status == true) {
                    if (settings['reloadOnEnable']){
                        location.reload();
                    }
                    inputField.val("on");
                    switchField.addClass("True");
                    content.show();
                    description.hide();
                }
                else {
                    if (settings['reloadOnDisable']) {
                        location.reload();
                    }
                    inputField.val("");
                    switchField.addClass("False");
                    content.hide();
                    description.show();
                }
                methods.enable();
            },
            error: function(id, error_type, xhr, ajaxOptions, thrownError) {
                setTimeout(methods.poll, 4000);
            },
            enable: function() {
                switchField.click(methods.execute);
            },
            disable: function() {
                switchField.unbind("click");
            }
        }
        
        init();
    };
})( jQuery );