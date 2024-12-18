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
        root.passwordEditor = factory({});
    }
}(this, function (exports) {

    exports.passwordEditor = {
        props: {
            id: {
                type: String,
                required: true
            }, 
            value: {
                type: String,
                required: false,
            },
            columns: {
                type: Number,
                default: 2
            },
            strings: {
                type: Object,
                default: function(){
                    return {
                        password: "Password",
                        confirmPassword: "Confirm password",
                        noMatchError: "Password do not match",
                        minLengthError: "Passwords must be at least 8 characters in length",
                        show: "show",
                        hide: "hide",

                    };
                }
            },

            minLength: {
                type: Number,
                default: 8
            },

            required: {
                type: Boolean,
                default: false
            }
        },

        data: function(){
            return {
                passwordValue: this.value,
                passwordConfirmValue: "",
                showPassword: false,
                showPasswordConfirm: false,
                matchError: false,
                minLengthError: false,
                emptyPasswordError: false,
                tooltip: this.strings.show+' / '+this.strings.hide,    
            };
        },

        template:'<div>\
                    <field-container\
                    :field-id="id"\
                    :columns="columns">\
                        <label :class="[\'fieldlabel\', {required: required}]" :for="id">{{strings.password+(required ? "&nbsp;*" : "")}}</label>\
                        <input v-if="showPassword" :name="id" :class="[\'passwordfield\', {has_error: minLengthError || emptyPasswordError}]" :id="id" autocomplete="off" size="30" maxlength="1024" type="text" v-model="passwordValue">\
                        <input v-else :name="id" :class="[\'passwordfield\', {has_error: minLengthError || emptyPasswordError}]" :id="id" autocomplete="off" size="30" maxlength="1024" type="password" v-model="passwordValue">\
                        <input :id="id+\'_checkbox\'" :title="tooltip" type="checkbox" v-model="showPassword"><br>\
                        <span v-if="minLengthError" class="fielderror">{{strings.minLengthError}}</span>\
                        <span v-if="emptyPasswordError" class="fielderror">{{strings.invalidPassword}}</span>\
                    </field-container>\
                    <field-container\
                    :field-id="\'verify_\'+id"\
                    :columns="columns"\
                    :last=true>\
                        <label class="fieldlabel" :for="\'verify_\'+id">{{strings.confirmPassword}}</label>\
                        <input v-if="showPasswordConfirm" :name="\'verify_\'+id" :class="[\'passwordfield\', {has_error: matchError}]" :id="\'verify_\'+id" autocomplete="off" size="30" maxlength="1024" type="text" v-model="passwordConfirmValue">\
                        <input v-else :name="\'verify_\'+id" :class="[\'passwordfield\', {has_error: matchError}]" :id="\'verify_\'+id" autocomplete="off" size="30" maxlength="1024" type="password" v-model="passwordConfirmValue">\
                        <input :id="\'verify_\'+id+\'_checkbox\'" :title="tooltip" type="checkbox" v-model="showPasswordConfirm">\
                        <span v-if="matchError" class="fielderror">{{strings.noMatchError}}</span>\
                    </field-container>\
                </div>',

        watch: {
            "passwordValue": function() {
                this.emptyPasswordError = false;
                this.$emit('input', this.passwordValue);
                if(this.minLength && (this.passwordValue.length > 0 && this.passwordValue.length < this.minLength)){
                    this.minLengthError = true;
                    this.$emit('invalid-password');
                }else{
                    this.minLengthError = false;
                    if(!this.matchError && !this.minLengthError){
                        this.$emit('valid-password');
                    }
                }
            },

            "passwordConfirmValue": function() {
                if(this.passwordConfirmValue != "" && this.passwordValue != this.passwordConfirmValue){
                    this.matchError = true; 
                    this.$emit('invalid-password');
                }else{
                    this.matchError = false;
                    if(!this.matchError && !this.minLengthError){
                            this.$emit('valid-password');
                    }
                }
            }
        },

        methods: {
            validate: function(){
                if(this.required && this.passwordValue.length == 0){
                    this.emptyPasswordError = true;
                    return false;
                }
                if(this.passwordValue.length && this.passwordValue != this.passwordConfirmValue){
                    this.matchError = true;
                    return false;
                }
                return true;
            }
        }

    };
    return exports;
}));
