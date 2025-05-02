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
 *
 * Usage example:
 *	$( "#search" ).searchWidget({
 *		searchUrl: "/manage/commands/commands.core.search/",
 *      select: function(event, ui) { alert(ui.item.label); }
 * });
 * 
 * Depends:
 *  jquery.effects.core
 *  jquery.ui.core.js
 *	jquery.ui.widget.js
 *	jquery.ui.position.js
 *  jquery.ui.autocomplete.js
 *  
 */

$.widget("custom.searchWidget", $.ui.autocomplete, {
	_create : function() {
		var self = this;
		this.cache = {};
		this.lastXhr;
		$.ui.autocomplete.prototype._create.call(this);
		this.element.focus(function() {
			self.element.switchClass("searchField", "focusedSarchField");
		});
		this.element.blur(function() {
			self.element.switchClass("focusedSarchField", "searchField");
		});
	},

	_renderMenu : function(ul, items) {
		ul.addClass("searchMenu");
		var self = this, currentCategory = "";
		$.each(items, function(index, item) {
			if (item.category != currentCategory) {
				ul.append("<li class='searchCategory ui-menu-item'>"
						+ item.category + "&nbsp;</li>");
				currentCategory = item.category;
			}
			self._renderItemData(ul, item);
		});
	},
	_renderItem : function(ul, item) {
		return $("<li></li>").addClass("searchItem").data("item.autocomplete",
				item).append($("<a></a>").text(item.label)).appendTo(ul);
	},
	_initSource : function() {
		var self = this;
		this.source = function(request, response) {
			var term = request.term;
			if (term in self.cache) {
				response(self.cache[term]);
				return;
			}
			self.lastXhr = $.getJSON(self.options.searchUrl, {
				'keyword' : request.term
			}, function(data, status, xhr) {
				var pdata = [];
				for (category in data) {
					for (i in data[category]) {
						var row = data[category][i];
						pdata.push({
							'id' : row.id,
							'label' : row.title,
							'category' : category
						});
					}
				}
				self.cache[term] = pdata;
				if (xhr === self.lastXhr) {
					response(pdata);
				}
			});
		};
	}
});
