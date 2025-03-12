/**
 * EConsole - Browser safe logging engine
 *
 * EConsole allows you to debug your scripts using ERROR, INFO, or LOG 
 * messages via the console interface of browsers.
 *
 * If a browser doesn't provide the console interface, no log messages will
 * be printed (using console directly would lead to code breachs).
 *
 * Use the .off method to disable logging, and .on to enable logging.
 * By default, logging is ENABLED!
 *
 */
var EConsole = function() {
    this.init();
}
EConsole.prototype = {
    init: function() {
        this.state = 'on';
    },
    _log: function(obj) {
        console.log(obj);
    },
    _error: function(obj) {
        console.log(obj);
    },
    _info: function(obj) {
        console.log(obj)
    },
    log: function(obj) {
        if(!this.enabled()) return;
        this._log(obj);
    },
    debug: function(obj) {
        if(!this.enabled()) return;
        this._log(obj);
    },
    info: function(obj) {
        if(!this.enabled()) return;
        this._info(obj);
    },
    error: function(obj) {
        if(!this.enabled()) return;
        this._error(obj);
    },
    flog: function(obj) {
        this._log(obj);
    },
    fdebug: function(obj) {
        this._log(obj);
    },
    finfo: function(obj) {
        this._info(obj);
    },
    ferror: function(obj) {
        this._error(obj);
    },
    enabled: function() {
        if(this.state == 'off') return false;
        if(typeof console == 'undefined') return false;
        if(typeof console.log == 'undefined' || 
           typeof console.error == 'undefined' ||
           typeof console.info == 'undefined') return false;
        
        return true;
    },
    on: function() {
        this.state = 'on';
    },
    off: function() {
        this.state = 'off';
    }
}

var econsole = new EConsole();

//default is disabled
econsole.off();
