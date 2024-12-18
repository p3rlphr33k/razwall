/*
* +--------------------------------------------------------------------------+
* | Endian Firewall                                                          |
* +--------------------------------------------------------------------------+
* | Copyright (c) 2005-2012 Endian                                           |
* |         Endian GmbH/Srl                                                  |
* |         Bergweg 41 Via Monte                                             |
* |         39057 Eppan/Appiano                                              |
* |         ITALIEN/ITALIA                                                   |
* |         info@endian.com                                                  |
* |                                                                          |
* | emi is free software: you can redistribute it and/or modify              |
* | it under the terms of the GNU Lesser General Public License as published |
* | by the Free Software Foundation, either version 2.1 of the License, or   |
* | (at your option) any later version.                                      |
* |                                                                          |
* | emi is distributed in the hope that it will be useful,                   |
* | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
* | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            |
* | GNU Lesser General Public License for more details.                      |
* |                                                                          |
* | You should have received a copy of the GNU Lesser General Public License |
* | along with emi.  If not, see <http://www.gnu.org/licenses/>.             |
* +--------------------------------------------------------------------------+
*/

/**
 * Return true if ipaddr is a valid IPv4 address
 */
function checkIPv4Address(ipaddr) {
	if (ipaddr == null)
		return false;
    ipaddr = ipaddr.trim().split(".");
    if (ipaddr.length != 4)
    	return false;
    for (var i=0; i<ipaddr.length; i++) {
    	var p = parseInt(ipaddr[i]);
    	if (isNaN(p) || p < 0 || p > 255)
            return false;
    }
    return true;
}

/**
 * Return true if ipaddr is a valid IPv6 address
 * IPv6 Validator courtesy of Dartware, LLC (http://intermapper.com)
 * For full details see http://intermapper.com/ipv6validator
 */
function checkIPv6Address(ipaddr)
{
	if (ipaddr == null)
		return false;
	ipaddr = ipaddr.trim();
	return /^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/.test(ipaddr);
}
