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

function fieldSelectorChange(id) {
    value = $("#" + id + " select").val();
    
    if (!value) {
        value = $("#" + id + " option:first").val();
    }
    
    $("#" + id + " > div").hide();
    $("#" + id + "_" + value).show();
    $("#" + id + " > div:hidden textarea").val("");
    if ($.browser.mozilla) {
	    $("#" + id + " > div:hidden select").val(false);
    } else {
	    $("#" + id + " > div:hidden select").val("");
    }
    $("#" + id + " > div:hidden").find("option").attr("selected", false);
    $("#" + id + " > div:hidden input").val("");
}
