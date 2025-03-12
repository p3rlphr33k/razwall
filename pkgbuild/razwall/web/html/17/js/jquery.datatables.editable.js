/*
 * Based on jquery.dataTables.editable.js
 * 
 * Copyright 2010-2012 Jovan Popovic, all rights reserved.
 *
 * This source file is free software, under either the GPL v2 license or a
 * BSD style license, as supplied with this software.
 * 
 * This source file is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 * or FITNESS FOR A PARTICULAR PURPOSE. 
 */
(function($) {

	$.fn.makeEditable = function(options) {

		var iDisplayStart = 0;

		function fnGetCellID(cell) {
			return properties.fnGetRowID($(cell.parentNode));
		}

		function _fnSetRowIDInAttribute(row, id, overwrite) {
			if (overwrite) {
				row.attr("id", id);
			} else {
				if (row.attr("id") == null || row.attr("id") == "")
					row.attr("id", id);
			}
		}

		function _fnGetRowIDFromAttribute(row) {
			return row.attr("id");
		}

		function _fnSetRowIDInFirstCell(row, id) {
			$("td:first", row).html(id);
		}

		function _fnGetRowIDFromFirstCell(row) {
			return $("td:first", row).html();
		}
    
    function _addTooltip(element, tooltip){
    	$(element).attr('title', tooltip);
      $(element).tooltip();
    }

		// Reference to the DataTable object
		var oTable;
		// Refences to the buttons used for manipulating table data
		var oAddNewRowButton, oDeleteRowButton;
		// Plugin options
		var properties;

		var sOldValue, sNewCellValue, sNewCellDisplayValue;

		function fnApplyEditable(aoNodes) {
			var oDefaultEditableSettings = {
				event : 'dblclick',

				"onsubmit" : function(settings, original) {
					sOldValue = original.revert;
					sNewCellValue = null;
					sNewCellDisplayValue = null;
					iDisplayStart = fnGetDisplayStart();

					if (settings.type == "text" || settings.type == "select" || settings.type == "textarea") {
						var input = $("input,select,textarea", this);
						sNewCellValue = $("input,select,textarea", $(this)).val();
                        if (sNewCellValue) {
                            sNewCellValue = sNewCellValue.replace(/\&amp\;/g, '&');
                        }
						if (input.length == 1) {
							var oEditElement = input[0];
							if (oEditElement.nodeName.toLowerCase() == "select" || oEditElement.tagName.toLowerCase() == "select") {
								sNewCellDisplayValue = $("option:selected", oEditElement).text();
							}
							else {
								sNewCellDisplayValue = sNewCellValue;
							}
						}

						if (!properties.fnOnEditing(input, settings, original.revert, fnGetCellID(original)))
							return false;
						var x = settings;

						// 2.2.2 INLINE VALIDATION
						if (settings.oValidationOptions != null) {
							input.parents("form").validate(settings.oValidationOptions);
						}
                        if (settings.cssclass != null) {
							input.addClass(settings.cssclass);
						}
						if (settings.cssclass == null && settings.oValidationOptions == null) {
							return true;
						} else {
							if (settings.oValidationOptions != null && (!input.valid() || 0 == input.valid()))
								return false;
							else
								return true;
						}

					}
				},

                "callback": function (sValue, settings) {
                    var status = "";
                    var cell = oTable.DataTable().cell(this);
                    var pos = cell.index(); 
                    
                    var bRefreshTable = !oSettings.oFeatures.bServerSide;
                    $("td.last-updated-cell", oTable.fnGetNodes( )).removeClass("last-updated-cell");

                    if (sNewCellDisplayValue == null) {
                        cell.data(sValue).draw();
                    } else {
                        cell.data(sNewCellDisplayValue).draw();
                    }

                    $("td.last-updated-cell", oTable).removeClass("last-updated-cell");
                    $(this).addClass("last-updated-cell");
                    status = "success";
                    
                    properties.fnOnEdited(status, sOldValue, sNewCellDisplayValue, pos.row, pos.column, pos.columnVisible);
                    
                    fnSetDisplayStart();
                    if (properties.bUseKeyTable) {
                        var keys = oTable.keys;
                        setTimeout(function () { keys.block = false; }, 0);
                    }
                },

				"onerror" : function() {
					properties.fnOnEdited("failure");
				},

				"onreset" : function() {
					if (properties.bUseKeyTable) {
						var keys = oTable.keys;
						/*
						 * Unblock KeyTable, but only after this 'esc' key event
						 * has finished. Otherwise it will 'esc' KeyTable as
						 * well
						 */
						setTimeout(function() {
							keys.block = false;
						}, 0);
					}

				},
				"height" : properties.sEditorHeight,
				"width" : properties.sEditorWidth
			};

			var cells = null;

			if (properties.aoColumns != null) {

				for ( var iDTindex = 0, iDTEindex = 0; iDTindex < oSettings.aoColumns.length; iDTindex++) {
					if (oSettings.aoColumns[iDTindex].bVisible) {// if DataTables column is visible
						if (properties.aoColumns[iDTEindex] == null) {
							// If editor for the column is not defined go to the
							// next column
							iDTEindex++;
							continue;
						}
						// Get all cells in the iDTEindex column (nth child is
						// 1-indexed array)
						cells = $("td:nth-child(" + (iDTEindex + 1) + ")", aoNodes);

						var oColumnSettings = oDefaultEditableSettings;
						oColumnSettings = $.extend({}, oDefaultEditableSettings, properties.oEditableSettings, properties.aoColumns[iDTEindex]);
						iDTEindex++;
						var sUpdateURL = properties.sUpdateURL;
						try {
							if (oColumnSettings.sUpdateURL != null)
								sUpdateURL = oColumnSettings.sUpdateURL;
						} catch (ex) {
						}
						// cells.editable(sUpdateURL, oColumnSettings);
						cells.each(function() {
							if (!$(this).hasClass(properties.sReadOnlyCellClass)) {
                                oColumnSettings.cssclass = "editable-form";
								$(this).editable(sUpdateURL, oColumnSettings);
                            if(oColumnSettings.tooltip){
                	            _addTooltip($(this).get(0), oColumnSettings.tooltip);
                            }
							}
						});
					}

				} // end for
			} else {
				cells = $('td:not(.' + properties.sReadOnlyCellClass + ')', aoNodes);
				cells.editable(properties.sUpdateURL, $.extend({}, oDefaultEditableSettings, properties.oEditableSettings));
			}
		}

		function fnDisableDeleteButton() {
			if (properties.bUseKeyTable) {
				return;
			}
			try {
				oDeleteRowButton.button("option", "disabled", true);
			} catch (ex) {
				oDeleteRowButton.attr("disabled", "disabled");
			}
		}

		function fnEnableDeleteButton() {
			try {
				oDeleteRowButton.button("option", "disabled", false);
			} catch (ex) {
				oDeleteRowButton.attr("disabled", null);
			}
		}

		var nSelectedRow, nSelectedCell;
		var oKeyTablePosition;

		function _fnOnRowDeleteInline(e) {
			e.preventDefault();
			e.stopPropagation();

			iDisplayStart = fnGetDisplayStart();

			nSelectedCell = ($(this).parents('td'))[0];
			jSelectedRow = ($(this).parents('tr'));
			nSelectedRow = jSelectedRow[0];

			jSelectedRow.addClass(properties.sSelectedRowClass);
			fnDeleteRow(nSelectedRow);
		}

		function _fnOnRowDelete(event) {
			event.preventDefault();
			event.stopPropagation();

			iDisplayStart = fnGetDisplayStart();

			nSelectedRow = null;
			nSelectedCell = null;

			if (!properties.bUseKeyTable) {
				if ($('tr.' + properties.sSelectedRowClass + ' td', oTable).length == 0) {
					_fnDisableDeleteButton();
					return;
				}
				nSelectedCell = $('tr.' + properties.sSelectedRowClass + ' td', oTable)[0];
			} else {
				nSelectedCell = $('td.focus', oTable)[0];

			}
			if (nSelectedCell == null) {
				fnDisableDeleteButton();
				return;
			}
			if (properties.bUseKeyTable) {
				oKeyTablePosition = oTable.keys.fnGetCurrentPosition();
			}
			var id = fnGetCellID(nSelectedCell);
			var jSelectedRow = $(nSelectedCell).parent("tr");
			nSelectedRow = jSelectedRow[0];
			fnDeleteRow(nSelectedRow);
		}

		function fnDeleteRow(tr) {
			var oTRSelected = nSelectedRow;

			oTable.fnDeleteRow(oTRSelected);
			fnDisableDeleteButton();
			fnSetDisplayStart();
			if (properties.bUseKeyTable) {
				oTable.keys.fnSetPosition(oKeyTablePosition[0], oKeyTablePosition[1]);
			}
			properties.fnOnEdited("delete");
		}

		function _fnOnEditing(input) {
			return true;
		}
		function _fnOnEdited(result, sOldValue, sNewValue, iRowIndex, iColumnIndex, iRealColumnIndex) {
		}

		var oSettings;
		function fnGetDisplayStart() {
			return oSettings._iDisplayStart;
		}

		function fnSetDisplayStart() {
			oSettings._iDisplayStart = iDisplayStart;
			oSettings.oApi._fnCalculateEnd(oSettings);
			oSettings.oApi._fnDraw(oSettings);
		}

		function _sUpdateURL(value, settings) {
			return (value);
		}

		oTable = this;

		var defaults = {
			sUpdateURL : _sUpdateURL,
			sAddNewRowButtonId : "btnAddNewRow",
			sDeleteRowButtonId : "btnDeleteRow",
			sSelectedRowClass : "row_selected",
			sReadOnlyCellClass : "read_only",
			aoColumns : null,
			fnOnEditing : _fnOnEditing,
			fnOnEdited : _fnOnEdited,
			fnGetRowID : _fnGetRowIDFromAttribute,
			fnSetRowID : _fnSetRowIDInAttribute,
			sEditorHeight : "100%",
			sEditorWidth : "100%",
			newRowDefault : [],
			oKeyTable : null
		};

		properties = $.extend(defaults, options);
		oSettings = oTable.fnSettings();
		properties.bUseKeyTable = (properties.oKeyTable != null);

		return this.each(function() {
			var sTableId = oTable.dataTableSettings[0].sTableId;
			// KEYTABLE
			if (properties.bUseKeyTable) {
				var keys = new KeyTable({
					"table" : document.getElementById(sTableId),
					"datatable" : oTable
				});
				oTable.keys = keys;

				/* Apply a return key event to each cell in the table */
				keys.event.action(null, null, function(nCell) {
					if ($(nCell).hasClass(properties.sReadOnlyCellClass))
						return;
					/*
					 * Block KeyTable from performing any events while jEditable
					 * is in edit mode
					 */
					keys.block = true;
					/*
					 * Dispatch click event to go into edit mode - Saf 4 needs a
					 * timeout...
					 */
					setTimeout(function() {
						$(nCell).dblclick();
					}, 0);
				});
			}

			// KEYTABLE

			if (oTable.fnSettings().sAjaxSource != null) {
				oTable.fnSettings().aoDrawCallback.push({
					"fn" : function() {
						// Apply jEditable plugin on the table cells
						fnApplyEditable(oTable.fnGetNodes());
						$(oTable.fnGetNodes()).each(function() {
							var position = oTable.fnGetPosition(this);
							var id = oTable.fnGetData(position)[0];
							properties.fnSetRowID($(this), id);
						});
					},
					"sName" : "fnApplyEditable"
				});

			} else {
				// Apply jEditable plugin on the table cells
				fnApplyEditable(oTable.fnGetNodes());
			}

			oAddNewRowButton = $("#" + properties.sAddNewRowButtonId);
			if (oAddNewRowButton.length != 0) {
				oAddNewRowButton.unbind("click");
				oAddNewRowButton.click(function() {
                    var newRow = properties.newRowDefault.slice(); // copy the array
                    rtn = oTable.DataTable().row.add(newRow);
          
					var oTRAdded = oTable.fnGetNodes(rtn);
					// Apply editable plugin on the cells of the table
					fnApplyEditable(oTRAdded);

					$("tr.last-added-row", oTable).removeClass("last-added-row");
					$(oTRAdded).addClass("last-added-row");
					fnSetDisplayStart();
					properties.fnOnEdited("added");
                    oTable.DataTable().draw();
					return false;
				});
				oAddNewRowButton.data("add-event-attached", "true");
			}

			// Set the click handler on the "Delete selected row" button
			oDeleteRowButton = $('#' + properties.sDeleteRowButtonId);
			if (oDeleteRowButton.length != 0) {
				oDeleteRowButton.unbind("click");
				oDeleteRowButton.click(_fnOnRowDelete);
				oDeleteRowButton.data("delete-event-attached", "true");
				fnDisableDeleteButton();
			} else {
				oDeleteRowButton = null;
			}

			// Add handler to the inline delete buttons
			$(".table-action-deletelink", oTable).on("click", _fnOnRowDeleteInline);

			if (!properties.bUseKeyTable) {
				// Set selected class on row that is clicked
				// Enable delete button if row is selected, disable delete
				// button if selected class is removed
				$("tbody", oTable).unbind("click");
				$("tbody", oTable).click(function(event) {
					if ($(event.target.parentNode).hasClass(properties.sSelectedRowClass)) {
						$(event.target.parentNode).removeClass(properties.sSelectedRowClass);
						if (oDeleteRowButton != null) {
							fnDisableDeleteButton();
						}
					} else {
						$(oTable.fnSettings().aoData).each(function() {
							$(this.nTr).removeClass(properties.sSelectedRowClass);
						});
						$(event.target.parentNode).addClass(properties.sSelectedRowClass);
						if (oDeleteRowButton != null) {
							fnEnableDeleteButton();
						}
					}
				});
			} else {
				oTable.keys.event.focus(null, null, function(nNode, x, y) {
				});
			}

		});
	};
})(jQuery);

