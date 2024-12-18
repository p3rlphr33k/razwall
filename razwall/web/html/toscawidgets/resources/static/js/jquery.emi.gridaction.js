(function( $ ){
    var that = null;
    var settings = {
        requestType: "GET",
        idfield: 'ID',
        gridid: null,
        controllername: null,
        link: "",
        errormessage: "",
        beforeExecute: null,
        onExecute: null,
        onSuccess: null,
        onError: null,
        onComplete: null,
        multi: false,
        all: false
    };
    var methods = {
        init : function(options, data) {
            settings = $.extend({}, options);
            that = $(this);
            
            var saved_data = that.data('data');
            if ( !saved_data ) {
                that.data('data', data);
            }
            if (settings.beforeExecute) {
                settings.beforeExecute(that);
                return that;
            }
            return methods.execute();
        },
        destroy : function() {
            return this.each(function(){
                $(window).unbind('emigridaction');
            });
        },
        execute : function() {
            if (that.data("executing")) {
                return;
            }
            that.data("executing", true);
            var img = that.find("img");
            if (typeof that.data("imgsrc") == 'undefined') {
                that.data("imgsrc", img.attr("src"));
            }
            img.attr("src", "/toscawidgets/resources/endian.emi/static/images/loading.gif");
            
            var error_field = $("#error_notification_"+settings.controllername);
            var info_field = $("#info_notification_"+settings.controllername);
            var apply_field = $("#apply_notification_"+settings.controllername);
            if (that.data('data') == null) {
                that.data('data', {});
            }
            
            if (settings.all == true) {
                var data = that.data('data');
                data['filter'] = window[settings.gridid+'Datasource'].filter();
                data['all'] = true;
                that.data('data', data);
            } else if (settings.multi == true) {
                var data = that.data('data');
                var selected = $('#'+settings.gridid).find("input[type=checkbox][name='"+settings.idfield+"']:checked");
                var ids = [];
                $.each(selected, function(index, value) {
                    ids.push(value.value);
                });
                data[settings.idfield] = ids;
                that.data('data', data);
            }
            
            if (settings.onExecute != null) {
                settings.onExecute(that);
            }
            
            $.ajax({
                type: settings.requestType,
                url: settings.link,
                data: that.data('data'),
                dataType: "json",
                cache: false})
                .success(function(data, textStatus, jqXHR) {
                    var reload = true;
                    if (data != null && typeof data['info'] != 'undefined' && data['info'] !== "") {
                        error_field.hide();
                        apply_field.hide();
                        info_field.find(".text").html(data['info']);
                        info_field.show();
                    }
                    if (data != null && typeof data['important'] != 'undefined' && data['important'] !== "") {
                        error_field.hide();
                        info_field.hide();
                        apply_field.find(".text").html(data['important']);
                        apply_field.show();
                    }
                    if (data != null && typeof data['error'] != 'undefined' && data['error'] !== "") {
                        info_field.hide();
                        apply_field.hide();
                        error_field.find(".text").html(data['error']);
                        error_field.show();
                    }
                    var success = true;
                    if (settings.onSuccess != null) {
                        success = settings.onSuccess(that, data);
                        if (typeof reload == 'undefined') {
                            reload = true;
                        }
                    }
                    if (success == true && settings.gridid != null) {
                        if (typeof window[settings.gridid+'Datasource'] !== "undefined") {
                            $('#'+settings.gridid).find('.k-grid-header').find("input[type=checkbox]:checked").prop('checked', false);
                            window[settings.gridid+'Datasource'].read();
                        } else if (jQuery("#"+settings.gridid).jqGrid != undefined) {
                            jQuery("#"+settings.gridid).jqGrid().trigger("reloadGrid");
                        }
                    }
                    that.data("executing", false);
                })
                .error(function(jqXHR, textStatus, errorThrown) {
                    var data = $.parseJSON(jqXHR['responseText']);
                    if (data != null && typeof data['error'] != 'undefined' && data['error'] !== "") {
                        error_field.find(".text").html(data['error']);
                    } else if (settings.errormessage != null) {
                        error_field.find(".text").html(settings.errormessage);
                    }
                    info_field.hide();
                    apply_field.hide();
                    error_field.show();
                    if (settings.onError != null) {
                        settings.onError(that);
                    }
                    img.attr("src", that.data("imgsrc"));
                    that.data("executing", false);
                })
                .complete(function(jqXHR, textStatus) {
                    if (settings.onComplete != null) {
                        settings.onComplete(that);
                    }
                });
        }
    };
    
    $.fn.emigridaction = function( method ) {
        if ( methods[method] ) {
            return methods[method].apply( this, Array.prototype.slice.call( arguments, 1 ));
        } else if ( typeof method === 'object' || ! method ) {
            return methods.init.apply( this, arguments );
        } else {
            $.error( 'Method ' +  method + ' does not exist on jQuery.emigridaction' );
        }
    };
})( jQuery );
