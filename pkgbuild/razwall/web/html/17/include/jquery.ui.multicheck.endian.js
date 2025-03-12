(function($) {

$.widget('ui.multicheck_endian', {
    options: {
        hideLabel: true,
        collapse: "ui-icon-triangle-1-s",
        expand: "ui-icon-triangle-1-e",
        notSelected: "ui-icon-radio-on",
        selected: "ui-icon-bullet",
        partial: "ui-icon-radio-off",
        groups: [],
        text: {
            uncategorized: "Uncategorized",
            empty: 'There are no items to select from.'
        }
    },
    _create: function() {
        var that = this;
        
        this.ID = this.element.attr('id');
        this.LOCK = false;
        
        this.useImage = true;
        if (this.options.notSelected.indexOf("ui-icon-") == 0 &&
                this.options.selected.indexOf("ui-icon-") == 0 &&
                this.options.partial.indexOf("ui-icon-") == 0) {
            this.useImage = false;
        }
        this.expand = false;
        if (this.element.parent().parent().parent().hasClass("expands")) {
            this.expand = true;
        }
        
        this.element.parent().parent().parent().hide();
        if (this.options.hideLabel) {
            this.element.parent().parent().parent().find('label').hide();
        }
        this.label = this.element.parent().parent().parent().find('label').text();
                
        var nogroup = [];
        var options = $('#'+this.ID).find('option');
        $(options.each(function() {
            var option = $(this);
            
            // create item node
            var item = that._getOptionNode(option);
            that._applyItemState(item, this.selected);
            
            var inGroup = false;
            // add item to groups based on value
            $.each(that.options.groups, function(i) {
                $.each(that.options.groups[i][1], function() {
                    var itemValue = this;
                    if (itemValue == option.val()) {
                        inGroup = true;
                        // add item list key if not already present
                        if (that.options.groups[i].length == 2) {
                            that.options.groups[i].push([]);
                        }
                        that.options.groups[i][2].push(item[0]);
                        return;
                    }
                });
            });
            // add to uncatogrised group if item is in no other group
            if (! inGroup) {
                nogroup.push(item[0]);
            }
        }));
        
        this.groups = [];
        // creat group nodes
        $.each(this.options.groups, function(i) {
            if (that.options.groups[i].length > 2) {
                if (that.options.groups[i][2].length > 0) {
                    that.groups.push(that._getGroupNode(that.options.groups[i][0], that.options.groups[i][2]));
                }
            }
        });
        // create group node for uncategorised items
        if (nogroup.length > 0) {
            var groupTitle = this.label; // use label as title
            if (this.groups.length > 0) { // use custom text as title if there is more then 1 group
                groupTitle = this.options.text.uncategorized;
            }
            this.groups.push(this._getGroupNode(groupTitle, nogroup));
        }
        
        var breakOn = that.groups.length % 2 == 0
                        ? that.groups.length / 2
                        : (that.groups.length + 1) / 2,
            container = $('<div class="container"></div>');
        
        if (this.groups.length == 0) {
            $('#'+this.ID).parent().parent().parent().hide();
            $('<span>'+this.options.text.empty+'</span>').appendTo($('#'+this.ID).parent().parent().parent().parent());
        } else {
            var subcontainer = $('<div class="field columns2"></div>');
            $(this.groups).each(function(i) {
                that._applyGroupState(this);
                this.appendTo(subcontainer);
                if (i+1 == breakOn) {
                    subcontainer.appendTo(container);
                    subcontainer = $('<div class="field columns2 last"></div>');
                }
            });
            subcontainer.appendTo(container);
            container.appendTo($('#'+this.ID).parent().parent().parent().parent());
        }
    },
    _hoverIn: function(event) {
        $(this).addClass('ui-state-hover');
    },
    _hoverOut: function(event) {
        $(this).removeClass('ui-state-hover');
    },
    _getOptionNode: function(option) {
        var node = $('<li class="item ui-widget-content ui-state-default ui-helper-clearfix"></li>').hide();
        $('<span class="text">'+option.text()+'</span>').appendTo(node); // title
        if (this.useImage) { // use image or ui-icon class
            $('<img class="status" />').appendTo(node);
        } else {
            $('<span class="status ui-icon"></span>').appendTo(node);
        }
        $('<input type="hidden" value="'+option.val()+'" />').appendTo(node); // value
        return node;
    },
    _getGroupNode: function(title, items) {
        var that = this;
        
        var node = $('<ul class="ui-multicheck ui-widget ui-helper-reset"></ul>');
        var info = $('<li class="info ui-widget-header ui-state-default ui-corner-all ui-helper-clearfix"></li>').appendTo(node);
        var toggle = $('<span class="toggle ui-icon"></span>').appendTo(info);
        var text = $('<span class="text">'+title+'</span>').appendTo(info);
        var status = null;
        
        if (this.useImage) { // use image or ui-icon class
             status = $('<img class="status" />').appendTo(info);
        } else {
            status = $('<span class="status ui-icon"></span>').appendTo(info);
        }
        
        info.mouseenter(this._hoverIn).mouseleave(this._hoverOut);
        
        toggle.addClass(this.options.expand);
        toggle.click(this, this._toggleGroup);
        
        text.click(this, this._toggleGroup);
        
        status.click(this, this._changeGroupState);
        
        // add clones of the items to group
        var clone = null;
        $(items).each(function() {
            clone = $(this).clone();
            clone.appendTo(node);
            
            clone.mouseenter(that._hoverIn).mouseleave(that._hoverOut);
            clone.click(that, that._changeItemState);
        });
        clone.addClass('ui-corner-bottom'); // last one gets round corners on the bottom
        
        return node;
    },
    _toggleGroup: function(event) {
        var that = event.data;
        
        var toggle = $(this).parent().find('span.toggle');
        var items = $(this).parent().parent().find('li.item');
        if (toggle.hasClass(that.options.expand)) {
            $(this).parent().addClass('ui-state-active').removeClass('ui-corner-all').addClass('ui-corner-top');
            toggle.removeClass(that.options.expand).addClass(that.options.collapse);
            items.show();
        } else {
            $(this).parent().removeClass('ui-state-active').addClass('ui-corner-all').removeClass('ui-corner-top');
            toggle.removeClass(that.options.collapse).addClass(that.options.expand);
            items.hide();
        }
    },
    _applyItemState: function(item, selected) {
        var that = this;
        
        var status = item.find('.status');
        var value = item.find('input').val();
        var option = $('#'+that.ID+' option[value="'+value+'"]');
        
        var statusImage = "";
        if (that.useImage) { // use image or ui-icon class
            if (! selected) {
                statusImage = that.options.notSelected;
                option.removeAttr('selected');
            } else {
                statusImage = that.options.selected;
                option.attr('selected', "selected");
            }
            status.attr('src', statusImage);
        } else {
            if (! selected) {
                statusImage = that.options.notSelected;
                option.removeAttr('selected');
            } else {
                statusImage = that.options.selected;
                option.attr('selected', "selected");
            }
            status.removeClass(that.options.notSelected)
                  .removeClass(that.options.selected)
                  .addClass(statusImage)
        }
    },
    _applyGroupState: function(group) {
        var that = this;
        
        var selected = 0;
        var notSelected = 0;
        var partial = 0;
        
        // get count of selected not selected
        group.find('li.item').find('.status').each(function() {
            if (that.useImage) { // use image or ui-icon class
                var statusImage = $(this).attr('src');
                if (statusImage == that.options.selected) {
                    selected++;
                } else if (statusImage == that.options.notSelected) {
                    notSelected++;
                } else {
                    partial++;
                }
            } else {
                if ($(this).hasClass(that.options.selected)) {
                    selected++;
                } else if ($(this).hasClass(that.options.notSelected)) {
                    notSelected++;
                } else {
                    partial++;
                }
            }
        });
        
        var status = group.find('li.info').find('.status');
        
        var statusImage = this.options.partial;
        if (partial > 0) {
            statusImage = this.options.partial;
        } else if (selected == 0) {
            statusImage = this.options.notSelected;
        } else if (notSelected == 0) {
            statusImage = this.options.selected;
        }
                
        if (this.useImage) { // use image or ui-icon class
            status.attr('src', statusImage);
        } else {
            status.removeClass(that.options.partial)
                  .removeClass(that.options.notSelected)
                  .removeClass(that.options.selected)
                  .addClass(statusImage)
        }
    },
    _changeItemState: function(event) {
        var that = event.data;
        
        var status = $(this).find('.status');
        var value = $(this).find('input').val();
        var option = $('#'+that.ID+' option[value="'+value+'"]');
        
        var statusImage = "";
        if (that.useImage) { // use image or ui-icon class
            if (status.attr('src') == that.options.selected) {
                statusImage = that.options.notSelected;
                option.removeAttr('selected');
            } else {
                statusImage = that.options.selected;
                option.attr('selected', "selected");
            }
            status.attr('src', statusImage);
        } else {
            if (status.hasClass(that.options.selected)) {
                statusImage = that.options.notSelected;
                option.removeAttr('selected');
            } else {
                statusImage = that.options.selected;
                option.attr('selected', "selected");
            }
            status.removeClass(that.options.notSelected)
                  .removeClass(that.options.selected)
                  .addClass(statusImage)
        }
        
        var group = $(this).parent();
        that._applyGroupState(group); // change icon of group
        
        if (that.LOCK == true) { // make sure we do not get an infinite loop
            return;
        }
        that.LOCK = true;
        $(that.groups).each(function() {
            $(this).find('li input[value="'+value+'"]').each(function() {
                var status = $(this).parent().find('.status');
                if (that.useImage) { // use image or ui-icon class                
                    if (status.attr('src') != statusImage) { // check if status is already correct
                        $(this).parent().find('.status').click();
                    }
                } else {
                    if (! status.hasClass(statusImage)) { // check if status is already correct
                        $(this).parent().find('.status').click();
                    }
                }
            });
        });
        that.LOCK = false;
    },
    _changeGroupState: function(event) {
        var that = event.data;
        var status = $(this);
        
        var select = true;
        var statusImage = "";
        if (that.useImage) { // use image or ui-icon class
            if (status.attr('src') == that.options.selected) {
                select = false;
                statusImage = that.options.notSelected;
            }
            else {
                select = true;
                statusImage = that.options.selected;
            }
            status.attr('src', statusImage);
        } else {
            if (status.hasClass(that.options.selected)) {
                select = false;
                statusImage = that.options.notSelected;
            }
            else {
                select = true;
                statusImage = that.options.selected;
            }
            status.removeClass(that.options.partial)
                  .removeClass(that.options.notSelected)
                  .removeClass(that.options.selected)
                  .addClass(statusImage)
        }
        
        status.parent().parent().find('li.item').each(function() {
            that._applyItemState($(this), select);
            that.LOCK = true;
            var value = $(this).find('input').val();
            $(that.groups).each(function() {
                $(this).find('li input[value="'+value+'"]').each(function() {
                    var status = $(this).parent().find('.status');
                    if (that.useImage) { // use image or ui-icon class                
                        if (status.attr('src') != statusImage) { // check if status is already correct
                            $(this).parent().find('.status').click();
                        }
                    } else {
                        if (! status.hasClass(statusImage)) { // check if status is already correct
                            $(this).parent().find('.status').click();
                        }
                    }
                });
            });
            that.LOCK = false;
        });
    }
});

})(jQuery);