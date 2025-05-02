(function (root, factory) {
    "use strict";
    if ( typeof exports === 'object' ) {
        // CommonJS
        factory(exports);
    } else if ( typeof define === 'function' && define.amd ) {
        // AMD. Register as an anonymous module.
        define(['exports'], factory);
    } else {
        // Browser globals
        root.labelledSwitchButton = factory({});
    }
}(this, function (exports) {

    exports.registerVueComponent = function(){
        Vue.component('labelled-switch-button', {
            model: {
                prop: 'checked',
                event: 'change'
            },
            props: {
                name: {
                    type: String,
                    required: false,
                    default: '',
                },
                checked: { 
                    type: Boolean,
                    required: false, 
                    default: false,
                },
                'on-label': {
                    type: String,
                    required: false,
                    default: 'On',
                },
                'off-label': {
                    type: String,
                    required: false,
                    default: 'Off',
                },
                description: {
                    type: String,
                    required: false,
                    default: '',
                },
                'color-class-on': {
                    type: String,
                    required: false,
                    default: 'bootstrap-switch-primary',
                },
                'color-class-off': {
                    type: String,
                    required: false,
                    default: 'bootstrap-switch-default',
                },
                'size-class': {
                    type: String,
                    required: false,
                    default: '',
                },
                disabled: {
                    type:Boolean,
                    required: false,
                    default: false
                },
                readonly: {
                    type:Boolean,
                    required: false,
                    default: false
                }
            },

            template: '<div class="checkbox">\
                          <label>\
                            <div class="bootstrap-switch bootstrap-switch-animate" :style="switchStyle" :class="[sizeClass, {\'bootstrap-switch-off\': toggleValue==false, \'bootstrap-switch-on\': toggleValue==true, \'bootstrap-switch-disabled\': disabled==true, \'bootstrap-switch-readonly\': readonly}]">\
                                <div class="bootstrap-switch-container" :style="containerStyle" >\
                                    <span class="bootstrap-switch-handle-on" :class="colorClassOn" :style="labelStyle">{{onLabel}}</span><span class="bootstrap-switch-label" :style="labelStyle">&nbsp;</span><span class="bootstrap-switch-handle-off" :class="colorClassOff" :style="labelStyle">{{offLabel}}</span>\
                                    <input :name="name" type="checkbox" v-model="toggleValue" :disabled="disabled==true && !readonly" :readonly="readonly==true && !disabled">\
                                </div>\
                            </div>\
                            {{description}}\
                          </label>\
                       </div>',

            data: function(){
                return {
                    width: 0,
                    toggleValue: this.checked,
                    labelStyle:{},
                    containerStyle: {},
                    switchStyle: {},
                };
            },

            watch: {
                checked: function(){
                    this.toggleValue = this.checked;
                },
                toggleValue: function(){
                    this.toggleButton();
                    this.$emit('change', this.toggleValue ? true : false);
                }
            },
            
            mounted: function(){
                this.width = this.computeLabelWidth();
                this.switchStyle = {width: this.width*2+2+'px'};
                this.labelStyle = {width: this.width+'px'};                
                this.containerStyle = {width: this.width*3+'px'};
                this.toggleButton();
            },
            
            methods: {
                computeLabelWidth: function(){
                    var spanOnEl = this.$el.childNodes[0].childNodes[0].childNodes[0].childNodes[0];
                    var spanOffEl = this.$el.childNodes[0].childNodes[0].childNodes[0].childNodes[2];
                    var width = 0;
                    if(spanOnEl && spanOffEl){
                        width = spanOffEl.clientWidth;
                        if (spanOnEl.clientWidth > width)
                            width = spanOnEl.clientWidth;
                    }
                    return width;
                },

                toggleButton: function(){
                    if(this.toggleValue){
                        this.containerStyle['margin-left'] = '0px';
                    }else{
                        this.containerStyle['margin-left'] = -this.width+'px';
                    }
                }
            }
        });
    };
    return exports;
}));
