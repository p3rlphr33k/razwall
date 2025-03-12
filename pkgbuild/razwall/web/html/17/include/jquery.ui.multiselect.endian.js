/*
 * Endian UI Multiselect
 *
 * Derived from the jQuery UI Multiselect
 * Original Authors:
 *  Michael Aufreiter (quasipartikel.at)
 *  Yanick Rochon (yanick.rochon[at]gmail[dot]com)
 *
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 *
 * http://www.quasipartikel.at/multiselect/
 *
 * Depends:
 *    ui.core.js
 *    ui.sortable.js
 *
 * Warning: this widget damned
 */

(function($) {
$.widget("ui.multiselect_endian", {
  options: {
        title: "",
        searchable: true,
        sortable: false,
        draggable: true,
        onchange: null,
        url: '',
        data: {},
        data_fields: [],
        connectWith: [],
        locales: {
            searchHelp:'Filter available items',
            addTo:'Add to',
            addToHelp:'Items will be added to this selectbox',
            selectedInHelp:'Item is selected in this selectbox',
            addHelp:'Add',
            removeHelp:'Remove',
            addAll:'Add all',
            addAllHelp:'Add filtered items',
            removeAll:'Remove all',
            removeAllHelp:'Remove all filtered items',
        },
        filter: null // ACCESS-503 - filter function for filtering the available (and selected) options
    },
    _create: function() {
        var that = this;
        this.sources = [];
        this.title = this.options.title;
        if (this.title == "") {
            this.title = "&nbsp;";
        }
        this.label = {};
        this.count = {}; // number of currently selected options

        this.ID = this.element.attr("id");
        this.sources.push(this.ID);
        $.each(this.options.connectWith, function() {
            if ($("#"+this).length != 0) {
                that.sources.push(this);
            }
        });

        this.element.hide();
        this.labelField = this.element.parent().parent().parent().find("label");
        this.errorField = $('<span class="fielderror hidden" style="float: left; margin-top: 5px; margin-bottom: 10px;"></span>')
        this.errorField.appendTo(this.element.parent().parent().parent());

        $.each(this.options.connectWith, function(event, id) {
            $("#"+id).parent().parent().parent().hide();
            $("#"+id).parent().parent().parent().find("label").hide();
            that.options.sortable = false; // sortable is not possible with multiple select boxes
        });
        $.each(this.sources, function(event, sourceID) {
            that.label[sourceID] = $("#"+sourceID).parent().parent().parent().find("label").text();
            that.count[sourceID] = 0;
        });

        this.container = $('<div id="'+this.ID+'_container" class="ui-multiselect-endian ui-helper-clearfix ui-widget"></div>').insertAfter(this.element);

        this.availableActions = $('<div class="available actions ui-widget-header ui-corner-tl"></div>').appendTo(this.container);
        this.selectedActions = $('<div class="selected actions ui-widget-header ui-corner-tr ui-helper-clearfix"></div>').appendTo(this.container);

        this.availableList = $('<ul id="'+this.ID+'_available" class="available connected-list ui-widget-content ui-helper-reset">'+
                               '</ul>').bind('selectstart', function(){return false;})
                                       .appendTo(this.container);
        this.selectedList = $('<ul id="'+this.ID+'_selected" class="selected connected-list ui-widget-content ui-helper-clearfix ui-helper-reset">'+
                              '</ul>').bind('selectstart', function(){return false;})
                                      .appendTo(this.container);

        this.addAll = $('<div class="addall ui-widget-header ui-corner-bl">'+
                        '    <a href="#">'+this.options.locale.addAll+'</a>'+
                        '</div>').appendTo(this.container);
        this.removeAll = $('<div class="removeall ui-widget-header ui-corner-br ui-helper-clearfix">'+
                           '    <a href="#">'+this.options.locale.removeAll+'</a>'+
                           '</div>').appendTo(this.container);

        this.searchIcon = $('<span class="searchicon ui-corner-all ui-icon ui-icon-search"></span>').appendTo(this.availableActions);
        this.searchInput = $('<input type="text" class="search empty ui-widget-content ui-corner-all"/>').appendTo(this.availableActions);
        if (this.options.locale.searchHelp != '') {
            this.searchInput.attr('title', this.options.locale.searchHelp);
        }
        if (this.sources.length > 1) {
            this.availableActions.addClass('multisource');
            this.container.addClass('selfservice'); //fixes ACCESS-233 adapting to css rules designed for hotspot
            this.targetLabel = $('<span class="addto">'+this.options.locale.addTo+'</span>');
            this.targetLabel.appendTo(this.availableActions);
            this.target = $('<select class="addto ui-widget-content"></select>').appendTo(this.availableActions);

            if (this.options.locale.addToHelp != '') {
                this.target.attr('title', this.options.locale.addToHelp);
            }
            $.each(this.sources, function(event, sourceID) {
                $('<option value="'+sourceID+'">'+that.label[sourceID]+'</option>').appendTo(that.target);
            });
        }

        if (this.options.locale.addAllHelp != '') {
            this.addAll.attr('title', this.options.locale.addAllHelp);
        }

        if (this.sources.length > 1 || this.title != '') {
            this.labelField.html($('<span class="title">'+this.title+'</span>'));
        }
        var countlabel = "";
        $.each(this.sources, function(event, sourceID) {
            countlabel = countlabel+that.label[sourceID]+" ("+that.count[sourceID]+")&nbsp;&nbsp;";
        });
        $('<span class="count">'+countlabel+'</span>').appendTo(this.selectedActions);

        if (this.options.url != '') {
            this.refreshIcon = $('<span class=" ui-icon ui-icon-refresh" style="cursor: pointer; margin: 5px; float: right" />');
            this.refreshIcon.appendTo(this.selectedActions);
            this.refreshIcon.click(function() {
                that._updateOptions()
            });
            that.element.closest('form').find(':input').each(function() {
                if ($.inArray($(this).attr('name'), that.options.data_fields) > -1) {
                    $(this).change(function() {
                        that._updateOptions()
                    });
                }
            });

        }

        if (this.options.locale.removeAllHelp != '') {
            this.removeAll.attr('title', this.options.locale.removeAllHelp);
        }

        // set dimensions
        this.container.find('div.available').css('width', '40%'); // search box div
        this.container.find('input.search').css('width', '80%'); // search field

        this.availableList.css('width', '40%'); // left column
        this.addAll.css('width', '40%');

        this.selectedList.css('width', '59.5%'); // right column
        this.removeAll.css('width', '59.5%');
        this.container.find('div.selected').css('width','59.5%')

        var availableHeight = Math.max(this.element.height()-this.availableActions.height(),1);

        var searchiconWidth = this.container.find("span.searchicon").width();
        if (this.sources.length > 1) {
            var calc = '<span class="addto" style="display:none">' + this.options.locale.addTo + '</span>';
            $('body').append(calc);
            var addtoWidth = $('body').find('span:last').outerWidth();
            $('body').find('span:last').remove();
            this.container.find("select.addto").width('auto');
            this.availableList.height(110);
            this.selectedList.height(110);
        }
        else {
            this.availableList.height(availableHeight+45);
            this.selectedList.height(availableHeight+45);
        }

        // init lists
        if (this.options.url != '') {
            this._updateOptions();
        } else {
            this._populateLists();
        }

        var al = this.availableList;
        var sl = this.selectedList;

        if(this.options.sortable || this.options.draggable) {
            this.selectedList.sortable({
                connectWith: "#"+this.ID+"_available",
                placeholder: "ui-state-highlight",
                forceHelperSize: true,
                forcePlaceholderSize: true,
                scroll: true,
                zIndex: 9999,
                start: function( event, ui ) {
                    ui.placeholder.css('width', '100%');
                },
                remove: function(event, ui) {
                    that._removeSelected(that, ui.item, false);
                },
                receive: function(event, ui) {
                    that._addSelected(that, ui.item, false);
                    al.scrollLeft(0);
                },
                stop: function(event, ui) {
                    sl.scrollLeft(0);
                }
            }).disableSelection();
            this.availableList.sortable({
                connectWith: "#"+this.ID+"_selected",
                placeholder: "ui-state-highlight",
                forceHelperSize: true,
                forcePlaceholderSize: true,
                zIndex: 9999,
                start: function( event, ui ) {
                    ui.placeholder.css('width', '100%');
                },
                stop: function(event, ui) {
                    that._orderAvailable();
                    al.scrollLeft(0);
                },
                receive: function(event, ui) {
                    sl.scrollLeft(0);
                }
            }).disableSelection();
        }

        // set up livesearch
        if (this.options.searchable) {
            this._registerSearchEvents(this.searchInput);
        } else {
            this.searchInput.hide();
            this.searchIcon.hide();
        }

        // batch actions
        this.removeAll.click(function() {
            $.each(that.sources, function(event, sourceID) {
                $("#"+sourceID).find('option').attr('selected', false);
            });
            that._populateLists();
            return false;
        });

        this.addAll.click(function() {
            var _start = new Date().getTime();
            var id = that.ID;
            if (that.sources.length > 1) {
                id = that.target.val();
            }
            that.availableList.children('li:visible').each(function() {
                var id = that.ID;
                if (that.sources.length > 1) {
                    id = that.target.val();
                }
                that._setSelected(id, $(this), true, true);
            });
            that._updateCount();
            return false;
        });
    },
    _setOptions: function(options) {
        var that = this;
        this._superApply( arguments );
        if (options.filter) {
            that.options.filter = options.filter;
        }
        // init lists
        if (this.options.url != '') {
            this._updateOptions();
        } else {
            this._populateLists();
        }
    },
    destroy: function() {
        this.element.show();
        this.container.remove();

        $.Widget.prototype.destroy.apply(this, arguments);
    },
    /* Update the options from a remote url */
    _updateOptions: function() {
        var that = this;
        if (that.options.url == '') return false;
        that.errorField.text('').hide();
        var data = that.options.data;
        var form_data = that.element.closest('form').serializeArray();
        var field_data = {};
        $.each(form_data, function(i, field) {
            if ($.inArray(field.name, that.options.data_fields) > -1 && field.value != "") {
                field_data[field.name] = field.value;
            }
        });
        $.ajax({
            type: "POST",
            url: that.options.url,
            data: field_data,
            dataType: "json",
            cache: false}).success(function(data, textStatus, jqXHR) {
                var selected = [];
                that.element.children("option:selected").each(function() {
                    selected.push($(this).val());
                });
                that.element.empty();
                $.each(data, function(i, value) {
                    var option = $('<option></option>').attr("value", value).text(value);
                    $.each(selected, function(j, selected_value) {
                        if (selected_value == value) {
                            option.attr("selected", true);
                            return true;
                        }
                    })
                    option.appendTo(that.element);
                });
                that._populateLists();
            }).error(function(jqXHR, textStatus, errorThrown) {
                var data = $.parseJSON(jqXHR['responseText']);
                if (data != null && typeof data['error'] != 'undefined' && data['error'] !== "") {
                    that.errorField.text(data['error']).show();
                }
            });
    },
    /* Populate from <select> options */
    _populateLists: function() {
        var that = this;
        var notselected = [];
        var selected = [];
        var selectedValues = {};
        that.availableList.children('.ui-element').remove();
        that.selectedList.children('.ui-element').remove();
        $.each(this.sources, function(event, sourceID) {
            that.count[sourceID] = 0;
            var options = $("#"+sourceID).find('option');
            var items = $(options.map(function(i) {
                if (that.options.filter != null && !that.options.filter(this)) {
                    return;
                }
                if (this.selected) {
                    selected.push(this);
                    selectedValues[$(this).val()] = true;
                    var item = that._getOptionNode(this).appendTo(that.selectedList).show();
                    item.removeClass("available").addClass("selected");
                    if (that.sources.length > 1) {
                        item.find("select").show().find("option").each(function() {
                            if ($(this).val() == sourceID) {
                                $(this).attr('selected', true);
                            }
                        });
                    }
                    that.count[sourceID] += 1;
                    that._applyItemState(sourceID, item, this.selected);
                    return item[0];
                } else {
                    notselected.push(this);
                }
            }));
            that._updateCount();
        });

        var added = {};
        $.each(notselected, function() {
            var val = $(this).val();
            if (!added.hasOwnProperty(val) && !selectedValues.hasOwnProperty(val)) {
                var item = that._getOptionNode(this).appendTo(that.availableList).show();
                added[val] = true;
                item.addClass("available").removeClass("selected");
                item.find("select").hide();
                that._applyItemState(-1, item, false);
            }
        });

        // update count
        that._filter.apply(that.searchInput, [that.availableList]);
        /* that._orderAvailable(); */
    },
    _updateCount: function() {
        var that = this;
        var countlabel = "";
        $.each(that.sources, function(event, sourceID) {
            countlabel = countlabel+that.label[sourceID]+" ("+that.count[sourceID]+")&nbsp;&nbsp;";
        });
        that.selectedActions.find('span.count').html(countlabel);
    },
    _getOptionNode: function(option) {
        option = $(option);
        var that = this;
        var node = '<li class="ui-element ui-state-default ui-corner-all ui-helper-reset" style="width: 100%; display: none; clear: both;">';
        if(that.options.sortable) {
            node += '<span class="sortable ui-icon ui-icon-arrow-4" />';
            node += '<span class="moveable ui-icon ui-icon-arrow-2-e-w" />';
        }
        node += '<span class="target" style="white-space: nowrap; max-width: 90%; overflow: hidden;">'+option.text()+'</span>';
        node += '<a href="#" class="action"><span class="ui-corner-all ui-icon ui-icon-plus" title="' + that.options.locale.addHelp.replace(/"/g, "&quot;") +  '"/></a>';
        node += '<input type="hidden" value="'+option.val()+'" />';
        node = $(node);
        if (that.sources.length > 1) {
            var target = '<select class="selectedin ui-widget-content" title="' + that.options.locale.selectedInHelp.replace(/"/g, "&quot;") + '" style="position: absolute; right: 20px; z-index: 10;">';
            $.each(that.sources, function(event, sourceID) {
                target += '<option value="'+sourceID+'">'+that.label[sourceID]+'</option>';
            });
            target += '</select>';
            that._registerChangeEvents($(target).appendTo(node));
        }
        // that._registerHoverEvents(node);
        return node;
    },
    _setSelected: function(id, item, selected, move) {
        var value = $(item).find("input").val();
        $("#"+id).find("option").filter(function(){return this.value==value}).attr('selected', selected);
        var ret = null;
        if (selected) {
            var selectedItem = $(item);
            if (move) {
                selectedItem.appendTo(this.selectedList);
            }
            if (this.sources.length > 1) {
                selectedItem.find("select").val(id).show();
            }
            this.count[id] += 1;
            this._applyItemState(id, selectedItem, true);
            ret = selectedItem;
        } else {
            var availableItem = $(item);
            if (this.sources.length > 1) {
                availableItem.find("select").hide();
            }
            if (move) {
                availableItem.appendTo(this.availableList);
            }
            this.count[id] -= 1;
            this._applyItemState(id, availableItem, false);
            // this._orderAvailable(); // slow
            ret = availableItem;
        }
        if (this.options.onchange) {
            this.options.onchange(ret);
        }
        return ret;
    },
    _addSelected: function(that, node, move) {
        var id = that.ID;
        if (that.sources.length > 1) {
            id = that.target.val();
        }
        var item = that._setSelected(id, node, true, move);
        that._updateCount();
        that._orderSelected();
    },
    _removeSelected: function(that, node, move) {
        var id = that.ID;
        if (that.sources.length > 1) {
            id = node.find("select").val();
        }
        that._setSelected(id, node, false, move);
        that._updateCount();
        // that._orderAvailable();
    },
    _order: function(list) {
        // order available item list ascending
        var that = this;
        var items = list.children("li");
        items.sort(function(a, b) {
            return $(a).find("span.target").text().toUpperCase().localeCompare($(b).find("span.target").text().toUpperCase());
        })
        // add all not selected options
        items.each(function() {
            $(this).appendTo(list);
        });
    },
    _orderSelected: function() {
        if (this.options.sortable) return false;
        this._order(this.selectedList);
    },
    _orderAvailable: function() {
        this._order(this.availableList);
    },
    _applyItemState: function(id, item, selected) {
        if (selected) {
            var action = item.find('a.action span.ui-icon').addClass('ui-icon-minus')
                .removeClass('ui-icon-plus');
            if(this.options.sortable) {
                item.find('span.sortable').show();
                item.find('span.moveable').hide();
            } else if (this.options.draggable) {
                item.find('span.moveable').show();
            }
            if (this.options.locale.removeHelp != '') {
                action.attr('title', this.options.locale.removeHelp);
            }
            this._registerRemoveEvents(item);
        } else {
            var action = item.find('a.action span.ui-icon').addClass('ui-icon-plus')
                .removeClass('ui-icon-minus');
            if(this.options.sortable) {
                item.find('span.sortable').hide();
                item.find('span.moveable').show();
            } else if (this.options.draggable) {
                item.find('span.moveable').show();
            }
            if (this.options.locale.addHelp != '') {
                action.attr('title', this.options.locale.addHelp);
            }
            this._registerAddEvents(item);
        }
        this._registerHoverEvents(item);
    },
    // taken from John Resig's liveUpdate script
    _filter: function(list) {
        var input = this;
        var rows = list.children('li'),
            cache = rows.map(function(){
                return $(this).text().toLowerCase();
            });

        var term = $.trim(input.val().toLowerCase()), scores = [];

        if (!term) {
            rows.show();
        } else {
            rows.hide();
            cache.each(function(i) {
                if (this.indexOf(term)>-1) { scores.push(i); }
            });
            $.each(scores, function() {
                $(rows[this]).show();
            });
        }
    },
    _registerHoverEvents: function(node) {
        node.removeClass('ui-state-hover');
        node.mouseover(function() {
            $(this).addClass('ui-state-hover');
        });
        node.mouseout(function() {
            $(this).removeClass('ui-state-hover');
        });
    },
    _registerAddEvents: function(node) {
        var that = this;
        node.unbind("click");
        node.click(function() {
            that._addSelected(that, node, true);
            return false;
        });
    },
    _registerRemoveEvents: function(node) {
        var that = this;
        node.unbind("click");
        node.click(function(eventObject) {
            if (eventObject.target.tagName == 'SELECT') {
                return true;
            }
            that._removeSelected(that, node, true);
            return false;
        });
    },
    _registerChangeEvents: function(node) {
        var that = this;
        node.unbind("change");
        node.change(function() {
            var value = $(this).parent().find('input').val();
            $.each(that.sources, function(event, sourceID) {
                $("#"+sourceID+" option:selected").each(function() {
                    if ($(this).val() == value) {
                        $(this).attr('selected', false);
                        that.count[sourceID] -= 1;
                    }
                });
            });
            var id = $(this).val();
            $("#"+id+" option").each(function() {
                if ($(this).val() == value) {
                    $(this).attr('selected', true);
                    that.count[id] = 1;
                }
            });
            that._updateCount();
            return false;
        });
    },
    _registerSearchEvents: function(input) {
        var that = this;

        input.focus(function() {
            $(this).addClass('ui-state-active');
        })
        .blur(function() {
            $(this).removeClass('ui-state-active');
        })
        .keypress(function(e) {
            if (e.keyCode == 13)
                return false;
        })
        .keyup(function() {
            that._filter.apply(that.searchInput, [that.availableList]);
        });
    }
});

})(jQuery);
