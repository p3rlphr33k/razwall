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
        root.toggleButtonBar = factory({});
    }
}(this, function (exports) {

    exports.registerVueComponent = function(){
        Vue.component('toggle-button-bar', {
            props: {
                buttons: { 
                    type: Array,
                    required: true
                },
            },
            template: '<div class="btn-group" style="box-sizing: border-box">\
                            <button v-for="(button, index) in buttons" type="button" class="btn" style="margin-left: -1px"\
                            :class="{\'bg-teal\': index == selectedIndex, \'bg-slate-700\': index != selectedIndex}"\
                            @click="handleClick(index)">{{button.label}}</button>\
                      </div>',

            data: function(){
                return {
                    selectedIndex: this.getSelectedIndex()
                };
            },

            watch: {
                buttons: function(){
                    this.selectedIndex = this.getSelectedIndex();
                }
            },
            
            methods: {
                handleClick: function(index){
                    this.selectedIndex = index;
                    this.$emit('toggle', this.buttons[index].value);
                },
                getSelectedIndex: function(){
                    var selectedIndex = 0;
                    for(var i=0;i<this.buttons.length;i++){
                        if(this.buttons[i].selected){
                            selectedIndex = i;
                            break;
                        }
                    }
                    return selectedIndex;
                }
            }
        });
    };
    return exports;
}));


