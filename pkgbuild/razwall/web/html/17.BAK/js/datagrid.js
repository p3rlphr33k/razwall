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

function checkboxChanged(checkbox) {
    var me = $(checkbox);
    var name = me.attr("name");
    var hidden = $("input:hidden." + name);
    if (me.attr('checked')) {
	hidden.val(me.val());
    } else {
	hidden.val('');
    }
}

/* Selects all items */
function selectAll(checkbox, name) {
    var me = checkbox;
    /* Ignore disabled checkboxes. */
    $(checkbox).parents('table').find("input:checkbox[name='" + name + "']").each(function(i,o) {
        /* Skip myself! */
        if(o == me || o.disabled) return;
        o.checked = me.checked ? true : false;
    });
}


function replaceElement(element_id, url, period) {
    var el = $('#' + element_id);
    if (!el) {
        return;
    }
    var cb = function(data) {
        var checked = $("#" + element_id + " input:checked[type=checkbox]");
	// Save information about the selected checkboxes.
	var storeValues = {};
	checked.each( function(index, value) {
		var id_ = value['value'];
		storeValues[id_] = true;
	});
        var parent_ = el.parent();
	el.remove();
	parent_.append(data);
	var new_checked = $("#" + element_id + " input:[type=checkbox]");
	new_checked.each( function(index, value) {
		var id_ = value['value'];
		if (storeValues[id_]) {
			$(value).attr('checked', true);
		}
	});
	if (period) {
        	setTimeout('replaceElement("' + element_id + '", "' + url + '", ' + period + ');', period);
	}
	var all_devices = $('#all_devices');
	var table = $('#' + element_id + '_table').dataTable({bRetrieve: true});
	if (table && all_devices) {
		if (all_devices.attr('checked')) {
			table.fnFilter('', 2, false);
		} else {
			table.fnFilter("[^\ ]+", 2, 1);
		}
	}
    }
    var rand = Math.floor(Math.random()*100000);
    $.get(url, {_cache: rand}, cb);
}


function getSelected(form) {
    var res = [];
    $(form).find("input:checkbox[name='ID']").each(function(i,o) {
        var obj = $(o);
        if (obj.attr('checked')) { res.push(obj.attr('value')); }
    });
    return {'ids': res};
}

/* Run a multi items actions */
function doMultiItemsAction(form, action, exec_in_overlayer, naked_to_standalone, gridid) {
    if (action == 'multiStore') {
        $(form).find("input:checkbox[name='ID']").each(function(i,o) {
            if(o.disabled) return;
            o.checked = true;
        });
    }
    if (naked_to_standalone) {
        var formObj = $(form);
        var act = formObj.attr('action') || '';
        act = act.replace('/naked/', '/standalone/');
        if (act.search('/standalone/') == -1) {
            act = act.replace('/naked_grid', '/');
        }
        formObj.attr('action', act);
    }
    if (exec_in_overlayer) {
        $("#overlay_with_frame").overlay();
        var api = $("#overlay_with_frame").overlay();
        var oldTarget = form.target;
        form.target = 'overlay_frame';
        form.ACTION.value = action;
        form.submit();
        api.load();
        form.target = oldTarget;
    } else {
        form.ACTION.value = action;
        form.submit();
    }
}

function jqGridReload(gridid, searchKey) {
    var searchString = jQuery("input[name='"+searchKey+"']").val();
    $.cookie(searchKey, searchString);
    jQuery("#"+gridid).jqGrid('setGridParam', {
        postData: {
            search_string: searchString
        }
    }).trigger("reloadGrid");
}
