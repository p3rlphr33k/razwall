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

L.Control.IconLayers = L.Control.Layers.extend({
	options: {
    classNameSuffix: ''
	},

	_initLayout: function () {
		var className = 'leaflet-control-layers',
		    container = this._container = L.DomUtil.create('div', className),
		    collapsed = this.options.collapsed;

		// makes this work on IE touch devices by stopping it from firing a mouseout event when the touch is released
		container.setAttribute('aria-haspopup', true);

		L.DomEvent.disableClickPropagation(container);
		if (!L.Browser.touch) {
			L.DomEvent.disableScrollPropagation(container);
		}

		var form = this._form = L.DomUtil.create('form', className + '-list');

        // Make sure we don't drag the map when we interact with the content
        var stop = L.DomEvent.stopPropagation;
        L.DomEvent
            .on(form, 'mousewheel', stop)
            .on(form, 'MozMousePixelScroll', stop);

		if (collapsed) {
			this._map.on('click', this.collapse, this);

			if (!L.Browser.android) {
				L.DomEvent.on(container, {
					mouseenter: this.expand,
					mouseleave: this.collapse
				}, this);
			}
		}
    
        this.options.classNameSuffix = ' '+this.options.classNameSuffix;

		var link = this._layersLink = L.DomUtil.create('a', className + '-toggle'+this.options.classNameSuffix, container);
		link.href = '#';
		link.title = 'Layers';

		if (L.Browser.touch) {
			L.DomEvent
			    .on(link, 'click', L.DomEvent.stop)
			    .on(link, 'click', this.expand, this);
		} else {
			L.DomEvent.on(link, 'focus', this.expand, this);
		}

		// work around for Firefox Android issue https://github.com/Leaflet/Leaflet/issues/2033
		//L.DomEvent.on(form, 'click', function () {
		//	setTimeout(L.bind(this._onInputClick, this), 0);
		//}, this);

		// TODO keyboard accessibility

		if (!collapsed) {
			this.expand();
		}

		this._baseLayersList = L.DomUtil.create('div', className + '-base', form);
		this._separator = L.DomUtil.create('div', className + '-separator', form);
		this._overlaysList = L.DomUtil.create('div', className + '-overlays', form);

		container.appendChild(form);
	}

});

L.control.IconLayers = function (baseLayers, overlays, options) {
  return new L.Control.IconLayers(baseLayers, overlays, options);
};
