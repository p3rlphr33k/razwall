/*
* +--------------------------------------------------------------------------+
* | Endian Firewall                                                          |
* +--------------------------------------------------------------------------+
* | Copyright (c) 2005-2010 Endian                                           |
* |         Endian GmbH/Srl                                                  |
* |         Bergweg 41 Via Monte                                             |
* |         39057 Eppan/Appiano                                              |
* |         ITALIEN/ITALIA                                                   |
* |         info@endian.com                                                  |
* |                                                                          |
* | emi is free software: you can redistribute it and/or modify           |
* | it under the terms of the GNU Lesser General Public License as published |
* | by the Free Software Foundation, either version 2.1 of the License, or     |
* | (at your option) any later version.                                      |
* |                                                                          |
* | emi is distributed in the hope that it will be useful,                |
* | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
* | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            |
* | GNU Lesser General Public License for more details.                      |
* |                                                                          |
* | You should have received a copy of the GNU Lesser General Public License |
* | along with emi.  If not, see <http://www.gnu.org/licenses/>.          |
* +--------------------------------------------------------------------------+
*/

function selectService(protoField, serviceField, portField) {
    var values;
    var service = document.getElementsByName(serviceField)[0];
    var port = document.getElementsByName(portField)[0];
    var proto = document.getElementsByName(protoField)[0];

    values = service.value.split('/');
    proto.value = values[1];

    if (values[0] == "any" || values[1] == "any") {
        port.disabled = true;
        port.value = "";
    } else {
        port.disabled = false;
        port.value = values[0];
    }
}

function updateService(protoField, serviceField, portField) {
    var found = 0;
    var service = document.getElementsByName(serviceField)[0];
    var port = document.getElementsByName(portField)[0];
    var proto = document.getElementsByName(protoField)[0];

    for (var i = 0; i < service.options.length; i++) {
        curvalue = service.options[i].value;
        values = curvalue.split('/');

        if (port.value == values[0] && proto.value == values[1]) {
            found = 1;
            service.value = curvalue;
            break;
        }
    }

    if (!found) {
        service.value = service.options[1].value;
    }

    if (proto.value == "any") {
        port.disabled = true;
        port.value = "";
    } else {
        port.disabled = false;
    }
}
