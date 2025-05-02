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
        root.container = factory({});
    }
}(this, function (exports) {
    
    exports.container = {
        props: {
            expands: {
                type: Boolean,
                default: true
            }
        },

        template: '<div :class="[\'container\', {expands: expands}]">\
                        <slot></slot>\
                        <div class="cb"></div>\
                </div>'
    };

    exports.fieldContainer = {
        props: {
            fieldId: {
                type: String,
                required: true, 
            },
            columns: {
                type: Number,
                default: 2
            },
            last: {
                type: Boolean,
                default: false,
            },
        },

        data: function(){
            return {
                fieldClass: "field",
                columnClass: "columns"+this.columns,
            };
        },

        template: '<div id="fieldId" :class="[fieldClass, columnClass, {last: last}]">\
                        <slot></slot>\
                </div>' 
    };

    return exports;
}));
