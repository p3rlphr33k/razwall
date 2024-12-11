/*
 * +--------------------------------------------------------------------------+
 * | Endian Firewall                                                          |
 * +--------------------------------------------------------------------------+
 * | Copyright (c) 2004-2017 Endian S.p.A. <info@endian.com>                  |
 * |         Endian S.p.A.                                                    |
 * |         via Pillhof 47                                                   |
 * |         39057 Appiano (BZ)                                               |
 * |         Italy                                                            |
 * |                                                                          |
 * | This program is proprietary software; you are not allowed to             |
 * | redistribute and/or modify it.                                           |
 * | This program is distributed in the hope that it will be useful,          |
 * | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
 * | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     |
 * +--------------------------------------------------------------------------+
 */

(function () {

L.Control.NewWindow = L.Control.extend({
	options: {
		position: 'topleft',
		title: 'Open in a new window',
		forceSeparateButton: false,
	},
	
	onAdd: function (map) {
		var className = 'leaflet-control-zoom-newwindow', container, content = '';
		
		if (map.zoomControl && !this.options.forceSeparateButton) {
			container = map.zoomControl._container;
		} else {
			container = L.DomUtil.create('div', 'leaflet-bar');
		}
		
		if (this.options.content) {
			content = this.options.content;
		} else {
			className += ' newwindow-icon';
		}

		this._createButton(this.options.title, className, content, container, this.openNewWindow, this);

		return container;
	},
	
	_createButton: function (title, className, content, container, fn, context) {
		this.link = L.DomUtil.create('a', className, container);
		this.link.href = '#';
		this.link.title = title;
		this.link.innerHTML = content;

		L.DomEvent
			.addListener(this.link, 'click', L.DomEvent.stopPropagation)
			.addListener(this.link, 'click', L.DomEvent.preventDefault)
			.addListener(this.link, 'click', fn, context);
		
		return this.link;
	},
	
	openNewWindow: function () {
    //open the map in a new window
    window.open(window.location.href, "_blank");
	},
	
});

L.Map.addInitHook(function () {
	if (this.options.newWindowControl) {
		this.newWindowControl = L.control.newwindow(this.options.newWindowControlOptions);
		this.addControl(this.newWindowControl);
	}
});

L.control.newwindow = function (options) {
	return new L.Control.NewWindow(options);
};

})();
