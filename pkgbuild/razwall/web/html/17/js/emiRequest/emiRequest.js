(function (root, factory) {
    "use strict";
    if ( typeof exports === 'object' ) {
        // CommonJS
        factory(exports);
    } else if ( typeof define === 'function' && define.amd ) {
        // AMD. Register as an anonymous module.
        define(['exports' ], factory);
    } else {
        // Browser globals
        root.emiRequest = factory({});
    }
}(this, function (exports) {

    emiRequest = exports;

    //EmiREST constructor
    EmiREST = function(apiURI, options){
        this._initialize(apiURI, options);
    };

    EmiREST.prototype = {
        constructor: EmiREST,

        options: {
            requestContentType: 'application/json',
        },

        _initialize: function(apiURI, options){
            if(options){
                $.extend(true, this.options, options);
            }
            this._apiURI = apiURI; 
            this._actionURI = this._apiURI+'actions/';

            this._commonJQueryAjaxOptions = {
                contentType: this.options.requestContentType,
            };
        },

        get: function(parameters){
            return this._sendRequest('GET', parameters); 
        },

        head: function(parameters){
            return this._sendRequest('HEAD', parameters); 
        },

        post: function(parameters){
           return this._sendRequest('POST', parameters); 
        },

        delete: function(parameters){
           return this._sendRequest('DELETE', parameters); 
        },

        put: function(parameters){
           return this._sendRequest('PUT', parameters); 
        },

        execAction: function(actionName, data){
            var parameters = {
                resource: 'actions/'+actionName,
                data: data ? data : {}
            };

            return this._sendRequest('POST', parameters);
        },

        _sendRequest: function(type, parameters){
            var resourceURL = this._apiURI;
            var bodyData = {};
            if(parameters){
                if(parameters.resource){
                    resourceURL+=parameters.resource;
                }
                if(parameters.queryData){
                    resourceURL +='?'+$.param(parameters.queryData);
                }
                if(parameters.data){
                    bodyData = parameters.data;
                }
            }

            var ajaxOptions = {
                method: type,
            };
            if(type != 'GET' && type != 'HEAD'){
                ajaxOptions.data = JSON.stringify(bodyData);
            }
            $.extend(true, ajaxOptions, this._commonJQueryAjaxOptions);

            return this._sendAjaxRequest(resourceURL, ajaxOptions);
        },

        _sendAjaxRequest: function(url, options){

            var promise = $.ajax(url, options); 

            // return an object that wraps the Jquery promise 
            return {
                then: function(callback){
                    promise.done(function(data, textStatus, jqXHR){
                        callback(data);
                    });
                    return this;
                },

                fail: function(callback){
                    promise.fail(function(jqXHR, textStatus, errorThrown){
                        var code = jqXHR.status ? jqXHR.status : ''; 
                        callback(code, errorThrown);
                    });
                    return this;
                },

                always: function(callback){
                    promise.always(function(data, textStatus, jqXHR){
                        callback(data);
                    });
                    return this;
                }
            
            };

        }
        
    };

    emiRequest.EmiREST = EmiREST;
    
    emiRequest.execEmiCommand = function(command, data){
        var emiREST = new EmiREST('/manage/commands/');
        return emiREST.post({resource: command,
                             data: data});
        
    };

    return exports;
}));
