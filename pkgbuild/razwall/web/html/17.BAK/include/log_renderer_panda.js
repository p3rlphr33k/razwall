/*
#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2006 Endian                                                   |
#        |         Endian GmbH/Srl                                                     |
#        |         Bergweg 41 Via Monte                                                |
#        |         39057 Eppan/Appiano                                                 |
#        |         ITALIEN/ITALIA                                                      |
#        |         info@endian.it                                                      |
#        |                                                                             |
#        | This program is free software; you can redistribute it and/or               |
#        | modify it under the terms of the GNU General Public License                 |
#        | as published by the Free Software Foundation; either version 2              |
#        | of the License, or (at your option) any later version.                      |
#        |                                                                             |
#        | This program is distributed in the hope that it will be useful,             |
#        | but WITHOUT ANY WARRANTY; without even the implied warranty of              |
#        | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               |
#        | GNU General Public License for more details.                                |
#        |                                                                             |
#        | You should have received a copy of the GNU General Public License           |
#        | along with this program; if not, write to the Free Software                 |
#        | Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. |
#        | http://www.fsf.org/                                                         |
#        +-----------------------------------------------------------------------------+
#
*/

// Clamav tells us about updates, PID files, .cvd files errors and warnings...
type = 'panda';
if (!checkRenderer(type, logFactories)) {
    logFactories[logFactories.length] = type;
    function pandaRenderer(text) {
        this.getEntry = g_Entry;
        this.getExtra = g_Extra;
        function g_Extra(text) {
            return new Array(document.createTextNode(''));
        }
        function g_Entry(text) {
            function processMessage(proc, pid, rest) {
                pandatr = document.createElement('div');
                proctd = document.createElement('span');
                proctd.style.fontWeight = 'bold';
                proctd.style.color = logColors['proc'];
                proctd.appendChild(document.createTextNode(proc));
                if (pid) {
                    pidtd = document.createElement('span');
                    pidtd.style.fontWeight = 'bold';
                    pidtd.style.color = logColors['pid'];
                    pidtd.appendChild(document.createTextNode('('+pid+') '));
                }
                pandatr.appendChild(proctd);
                if (pid)
                    pandatr.appendChild(pidtd);
                regexpstring = /(PAVSIG is up to date|Update-applying finished.)/;
                result = regexpstring.exec(rest);
                if (result) {
                    file = RegExp.$1+' ';
                    update = RegExp.$2+' ';
                    rest = RegExp.$3+' ';
                    filetd = document.createElement('span');
                    filetd.style.color = logColors['file'];
                    filetd.appendChild(document.createTextNode(file));
                    updatetd = document.createElement('span');
                    updatetd.style.color = logColors['good'];
                    updatetd.appendChild(document.createTextNode(update));
                    resttd = document.createElement('span');
                    resttd.appendChild(document.createTextNode(rest));
                    pandatr.appendChild(filetd);
                    pandatr.appendChild(updatetd);
                } else {
                    regexpstring = /(ERROR|WARNING):(.*)/;
                    result = regexpstring.exec(rest);
                    if (result) {
                        msgtype = RegExp.$1+' ';
                        msg = RegExp.$2+' ';
                        if (msgtype == 'ERROR ') {
                            color = logColors['error'];
                        } else {
                            color = logColors['warning'];
                        }
                        errtd = document.createElement('span');
                        errtd.style.fontWeight = 'bold';
                        errtd.style.color = color;
                        errtd.appendChild(document.createTextNode(msgtype));
                        msgtd = document.createElement('span');
                        msgtd.style.color = color;
                        msgtd.appendChild(document.createTextNode(msg));
                        pandatr.appendChild(errtd);
                        pandatr.appendChild(msgtd);
                    } else {
                        resttd = document.createElement('span');
                        resttd.style.color = logColors['msg'];
                        resttd.appendChild(document.createTextNode(rest));
                        pandatr.appendChild(resttd);
                    }
                }
                pandatr.style.display='inline';
                return pandatr;
            }
            
	    regexpstring_pandascan = /.*(event:virus detected; service:.+?; virus:.*?);/;
	    result_pandascan = regexpstring_pandascan.exec(text);
            regexpstring = /([a-zA-Z\-]+)\:\s\[([0-9]{1,5})\]\:[a-zA-Z0-9\._\-]+\:[0-9]+\:[a-zA-Z0-9_\-]+\:(.*)/;
            result = regexpstring.exec(text);
	    var regexpstring_new = /C-ICAP\[-1\]: .+?, (.+?) .+? [0-9]+? (.+?) (.*)/;
	    result_new = regexpstring_new.exec(text);
            regexpstring = /([a-zA-Z\-]+)\:\s\[([0-9]{1,5})\]\:[a-zA-Z0-9_\-]+\:(.*)/;
            result2 = regexpstring.exec(text);
            regexpstring = /([a-zA-Z\-]+)\:\s[a-zA-Z0-9\._\-]+\:[0-9]+\:[a-zA-Z0-9_\-]+\:(.*)/;
            result3 = regexpstring.exec(text);
	    regexpstring = /(.+?):* ([0-9]+?)\/[0-9]+?, (.*)/;
	    result4 = regexpstring.exec(text);
            regexpstring = /([a-zA-Z\-]+)\:\s[a-zA-Z0-9_\-]+\:(.*)/;
            result5 = regexpstring.exec(text);
            
	    if (result_pandascan) {
		return processMessage('', 0, result_pandascan[1])
	    } else if (result_new) {
		var pandatr = document.createElement('div');
		var ip = 'client ip: ' + result_new[1] + ' ; ';
		var url = 'request url: ' + result_new[2] + ' ; ';
		var rest = 'result_new: ' + result_new[3];
		iptd = document.createElement('span');
		iptd.appendChild(document.createTextNode(ip));
		urltd = document.createElement('span');
		urltd.appendChild(document.createTextNode(url));
		resttd = document.createElement('span');
		resttd.appendChild(document.createTextNode(rest));
		pandatr.appendChild(iptd);
		pandatr.appendChild(urltd);
		pandatr.appendChild(resttd);
		return pandatr;
	    } else if (result) {
                proc = result[1]+' ';
                pid = result[2];
                rest = result[3]+' ';
                return processMessage(proc, pid, rest);
            } else if (result2) {
                proc = result2[1]+' ';
                pid = result2[2];
                rest = result2[3]+' ';
                return processMessage(proc, pid, rest);
            } else if (result3) {
                proc = result3[1]+' ';
                pid = null;
                rest = result3[2]+' ';
                return processMessage(proc, pid, rest);
            } else if (result4) {
                proc = result4[1]+' ';
                pid = result4[2]+' ';
                rest = result4[3]+' ';
                return processMessage(proc, pid, rest);
	    } else if (result5) {
                proc = result5[1]+' ';
                pid = null;
                rest = result5[2]+' ';
                return processMessage(proc, pid, rest);
            } else {
                return document.createTextNode(text);
            }
        }
    }
}
