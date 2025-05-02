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

function fieldTogglerChange(name) {
    var field = $("select[name=" + name + "]");
    if(!field.is("select"))
        return;
    var value = field.val();
    
    if (!value) {
        value = $("select[name=" + name + "] option:first").val();
    }
    
    $("select[name=" + name + "] option").each(function() {
        var v = $(this).val();
        $("." + name + "_" + v).hide();
    });
    
    $("." + name + "_" + value).show();
}

function fieldTogglerClick(name, value) {
	var field = null;   
	if (typeof(value) != "undefined") {
		field = $("input[name=" + name + "][value=" + value + "]");
		name = name + "_" + value;
    } else {
    	field = $("input[name=" + name + "]");
    }
    
    if(!field.is("input") || field.attr("type") != "checkbox")
        return;
    if(field.is(":checked")) {
        $("." + name + "_on").show();
        $("." + name + "_off").hide();
    }
    else {
        $("." + name + "_on").hide();
        $("." + name + "_off").show();        
    }
}