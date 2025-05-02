/*
 *
 * +--------------------------------------------------------------------------+
 * | Endian Firewall                                                          |
 * +--------------------------------------------------------------------------+
 * | Copyright (c) 2004-2016 S.p.A. <info@endian.com>                         |
 * |         Endian S.p.A.                                                    |
 * |         via Pillhof 47                                                   |
 * |         39057 Appiano (BZ)                                               |
 * |         Italy                                                            |
 * |                                                                          |
 * | This program is free software; you can redistribute it and/or modify     |
 * | it under the terms of the GNU General Public License as published by     |
 * | the Free Software Foundation; either version 2 of the License, or        |
 * | (at your option) any later version.                                      |
 * |                                                                          |
 * | This program is distributed in the hope that it will be useful,          |
 * | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
 * | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            |
 * | GNU General Public License for more details.                             |
 * |                                                                          |
 * | You should have received a copy of the GNU General Public License along  |
 * | with this program; if not, write to the Free Software Foundation, Inc.,  |
 * | 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.              |
 * +--------------------------------------------------------------------------+
 *
 * Basic tooltip library.
 *
 * To use it, define a div with the content of the tooltip, class="endian-tooltip"
 * and a 'for' attribute with the ID of the opener.  For example:
 *     <div for="option_help" class="endian-tooltip">The tooltip text</a><br>
 *     Option <sup><a id="option_help" class="tooltip-link" href="javascript:void(0);">?</a></sup>
 *
 * It's enough to include tooltip.endian.js and tooltip.endian.css: everything
 * is initialized once the page is loaded.
 *
 */

var tooltipsTimeout = {};

var initTooltips = function(selector, timeout_ms) {
    if (!selector) {
        selector = ".endian-tooltip";
    }
    if (!timeout_ms) {
        timeout_ms = 1000;
    }
    var tooltips = $(selector);

    tooltips.each(function() {
        var tooltip = $(this);
        var refID = tooltip.attr('for');
        if (!refID) {
            return;
        }
        refID = '#' + refID;
        var ref = $(refID);
        if (!ref.length) {
            return;
        }

        var _setTimeout = function() {
            tooltipsTimeout[refID] = setTimeout(function () {
                tooltip.hide();
            }, timeout_ms);
        };

        ref.bind('mouseover', function(e) {
            clearInterval(tooltipsTimeout[refID]);
            var x = e.pageX;
            var y = e.pageY;
            var rel_x = e.clientX;
            var rel_y = e.clientY;
            var h = tooltip.height();
            var w = tooltip.width();
            var window_h = $(window.top).height();
            var window_w = $(window.top).width();
            var tooltip_y = y + 4;
            if (rel_y + 4 + h > window_h) {
                tooltip_y = y - 4 - h;
            }
            var tooltip_x = x + 4;
            if (rel_x + 4 + w > window_w) {
                tooltip_x = x - 4 - w;
            }
            tooltip.css({'top': tooltip_y, 'left': tooltip_x});
            tooltip.show();
        });

        ref.bind('mouseleave', _setTimeout);

        tooltip.bind('mouseover', function(e) {
            clearInterval(tooltipsTimeout[refID]);
        });

        tooltip.bind('mouseleave', _setTimeout);
    });
};


$(document).ready(function() {
    initTooltips();
});
