/*
#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2012 Endian                                                   |
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


type = 'commtouchweb';
if (!checkRenderer(type, logFactories)) {
    logFactories[logFactories.length] = type;

    function commtouchwebRenderer(text) {
    this.getEntry = g_Entry;
    this.getExtra = function (text) { return new Array(document.createTextNode('')) };

    function g_Entry(text) {
    var regexpstring = /C-ICAP\[-1\]: .+?, (.+?) .+? [0-9]+? (.+?) (.*)/;
    result = regexpstring.exec(text);
    if (result) {
	var icaptr = document.createElement('div');
	var ip = 'client ip: ' + result[1] + ' ; ';
	var url = 'request url: ' + result[2] + ' ; ';
	var rest = 'result: ' + result[3];
	iptd = document.createElement('span');
	iptd.appendChild(document.createTextNode(ip));
	urltd = document.createElement('span');
	urltd.appendChild(document.createTextNode(url));
	resttd = document.createElement('span');
	resttd.appendChild(document.createTextNode(rest));
	icaptr.appendChild(iptd);
	icaptr.appendChild(urltd);
	icaptr.appendChild(resttd);
	return icaptr;
    } else {
	return document.createTextNode(text);
    }
    } // end function
    }
}

