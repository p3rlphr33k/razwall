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

L.Control.MultiLevelLayers = L.Control.IconLayers.extend({

		options: {
      multiLevels: true, //if false it works as an IconLayer, but it stores the checkbox status 
      animateOnOver: true //animate markers when user's mouse is over a level\group filter
    },

	initialize: function (baseLayers, multiLevelOverlays, options) {
		L.setOptions(this, options);

		this._layers = [];
		this._lastZIndex = 0;
		this._handlingClick = false;

        //stores a hash table with the status of inputs (input ID, layer)
        this.checkboxStatus = {}

        // initialize the tree with a root node
        this.multiLevelTree = new Node('root');

        for (var i in baseLayers) {
            this._addLayer(baseLayers[i], i);
        }
	},

	// @method addOverlay(layer: Layer, name: String, path: String): this
	// Adds an overlay (checkbox entry) with the given name and path to the control.
	addOverlay: function (layer, name, path) {
    if(!this.options.multiLevels)
        path = '';
		this._addLayer(layer, name, path, true);
		return (this._map) ? this._update() : this;
	},

  clearLevelTree: function(){
      this.checkboxStatus = {}
      this.multiLevelTree = new Node('root');
  },

	_addLayer: function (layer, name, path, overlay) {
		layer.on('add remove', this._onLayerChange, this);
    var layer_node = {
			layer: layer,
			name: name,
      path: path,
			overlay: overlay
		};
		this._layers.push(layer_node);

    //add to the tree if a path is specified
    if(path!=''){
      levels = path.split('/');
      this._addToMultiLevelTree(this.multiLevelTree, 0, levels, layer_node);
    }

		if (this.options.sortLayers) {
			this._layers.sort(L.bind(function (a, b) {
				return this.options.sortFunction(a.layer, b.layer, a.name, b.name);
			}, this));
		}

		if (this.options.autoZIndex && layer.setZIndex) {
			this._lastZIndex++;
			layer.setZIndex(this._lastZIndex);
		}
	},

  _createCheckboxElement: function(id, accordion){

    var input = document.createElement('input');
		input.type = 'checkbox';
		input.className = 'leaflet-control-layers-selector';
    input.id = id;
    if(accordion)
		  L.DomEvent.on(input, 'click', this._toggleAccordion, this); 
		input.defaultChecked = true;
    L.DomEvent.on(input, 'click', this._onInputClick, this);
    return input;
  },
  
  _createCheckboxTree: function(tree, level){
      var main_level_holder = document.createElement('div');
      var sub_level_holder = document.createElement('div');
      var indentation_level = 1;
      if(tree.name != 'root' || tree.layers.length>0){
          if(tree.name != 'root' && tree.getParentNode().name=='root' && tree.getParentNode().layers.length > 0)
              indentation_level = 0;
          if(level>indentation_level)
              main_level_holder.style = 'padding-left:20px';
          var span = document.createElement('span')
          var input_id = 'level-'+tree.path.replace(new RegExp('/', 'g'),'-');
          input_id = input_id.replace(new RegExp('\\.', 'g'), '_');
          var input = this._createCheckboxElement(input_id, true);
          //create a checkboxStatus item
          this.checkboxStatus[input_id]={checked: true, overlay: null};
          input.path = tree.path;
          span.appendChild(input);
          var name = document.createElement('strong');
          name.innerHTML = tree.name;
          span.appendChild(name);
          main_level_holder.appendChild(span);
          //add the input reference to the tree node
          tree.input = input;
          if(this.options.animateOnOver){
            L.DomEvent.on(span, 'mouseover', this._onInputOver, this);
            L.DomEvent.on(span, 'mouseleave', this._onInputLeave, this);
          }
          if(tree.layers.length>0){
              var layers_div = document.createElement('div');
              layers_div.style = 'padding-left:20px';
              for(var i=0;i<tree.layers.length;i++){
                  var input_id = 'layer-'+tree.path.replace(new RegExp('/', 'g'),'-')+'-'+tree.layers[i].name;
                  input_id = input_id.replace(new RegExp('\\.','g'),'_');
                  if(tree.layers[i].name != tree.name && tree.layers[i].name != ""){
                      var sub_layer_div = document.createElement('div');
                      var layer_input = this._createCheckboxElement(input_id, false);
                      layer_input.layerId = L.stamp(tree.layers[i].layer);
                      sub_layer_div.appendChild(layer_input);
                      var name = document.createElement('span');
                      name.innerHTML = tree.layers[i].name;
                      sub_layer_div.appendChild(name);
                      layers_div.appendChild(sub_layer_div);
                      tree.layers[i].input = layer_input;
                      if(this.options.animateOnOver){
                        L.DomEvent.on(sub_layer_div, 'mouseover', this._onInputOver, this);
                        L.DomEvent.on(sub_layer_div, 'mouseleave', this._onInputLeave, this);
                      }
                  }else{
                      input.layerId = L.stamp(tree.layers[i].layer);
                      tree.layers[i].input = input;
                  }
                  //create a checkboxStatus item
                  this.checkboxStatus[input_id]={checked: true, overlay: tree.layers[i].layer};
              }
              sub_level_holder.appendChild(layers_div);
          }      
      }
      var children = tree.getChildren();
      for(var i=0;i<children.length;i++){
          sub_level_holder.appendChild(this._createCheckboxTree(children[i],level+1));
      }
      main_level_holder.appendChild(sub_level_holder);
      return main_level_holder;
      
  },

    _appendCheckboxTreeToContainer: function(container){
        var checkboxTree = this._createCheckboxTree(this.multiLevelTree, 0);
        if(container.firstElementChild!=null){
          container.removeChild(container.firstElementChild);
        }
        container.appendChild(checkboxTree);
    },

    generateCheckboxTree: function(){
        if(this.multiLevelTree.getChildren().length > 0){
            var container = this._baseLayersList;
            this._appendCheckboxTreeToContainer(container);
        }
    },

	_addItem: function (obj) {	
        var container = obj.overlay ? this._overlaysList : this._baseLayersList;
        //add multi level item
        if (obj.path=='' && this.multiLevelTree.getChildren().length == 0 && obj.name!=""){
            var label = document.createElement('label'),
                checked = this._map.hasLayer(obj.layer),
                input;

            if (obj.overlay) {
              input = document.createElement('input');
              input.type = 'checkbox';
              input.className = 'leaflet-control-layers-selector';
              input.defaultChecked = checked;
            } else {
              input = this._createRadioElement('leaflet-base-layers', checked);
            }
            input.layerId = L.stamp(obj.layer);
            input.id = "layer-"+obj.name;

            L.DomEvent.on(input, 'click', this._onInputClick, this);

            var name = document.createElement('span');
            name.innerHTML = ' ' + obj.name;

            // Helps from preventing layer control flicker when checkboxes are disabled
            // https://github.com/Leaflet/Leaflet/issues/2771
            var holder = document.createElement('div');

            label.appendChild(holder);
            holder.appendChild(input);
            holder.appendChild(name);
            container.appendChild(label);
            // add checkboxStatus element
            this.checkboxStatus[input.id]={checked: true, overlay: obj.layer};


            if(this.options.animateOnOver){
                L.DomEvent.on(holder, 'mouseover', this._onInputOver, this);
                L.DomEvent.on(holder, 'mouseleave', this._onInputLeave, this);
              }
        }
        this._checkDisabledLayers();
	},

  _onInputOver: function(event){
    if(this._animatedMarkers === undefined || this._animatedMarkers.length == 0){
      var input = $(event.currentTarget).children().first()[0];
      var that = this;
      this._animatedMarkers = [];
      if(input && input.checked){
        if(input.layerId !== undefined){
          layer = this._getLayer(input.layerId).layer;
          layer.eachLayer(function(marker){
            that.options.onOverAnimation(marker);
            that._animatedMarkers.push(marker);
          });
        }
        if(input.path !== undefined){
          levels = input.path.split('/');
          var level_layers;
          level_layers = this._getCheckedLayers(this.multiLevelTree, 0, levels);
          for(var i=0;i<level_layers.length;i++){
              level_layers[i].layer.eachLayer(function(marker){
                that.options.onOverAnimation(marker);
                that._animatedMarkers.push(marker);
              });
          }
        }
      }
    }
  },

  _onInputLeave: function(){
    if(this._animatedMarkers !== undefined && this._animatedMarkers.length > 0){
      while(this._animatedMarkers.length > 0){
        this.options.onLeaveAnimation(this._animatedMarkers.pop());
      }
    }
  },

	_onInputClick: function (event) {
        var input = event.target;
            var addedLayers = [],
                removedLayers = [];

            this._handlingClick = true;
        
        //clean animated markers
        if(this.options.animateOnOver)
          this._animatedMarkers = [];
        
        if(input.layerId!==undefined){
          layer = this._getLayer(input.layerId).layer;
          hasLayer = this._map.hasLayer(layer);
          if (input.checked && !hasLayer) {
            addedLayers.push(layer);
            //save the status
            this.checkboxStatus[input.id]={checked: true, overlay: layer};
          } else if (!input.checked && hasLayer) {
            removedLayers.push(layer);
            this.checkboxStatus[input.id]={checked: false, overlay: layer};
          }
        }
        if(input.path !== undefined){
          levels = input.path.split('/');
          var level_layers;
          if(input.checked)
            level_layers = this._getCheckedLayers(this.multiLevelTree, 0, levels);
          else 
            level_layers = this._getLayers(this.multiLevelTree, 0, levels);
          if(input.checked)
            this.checkboxStatus[input.id]={checked: true, overlay: null};
          else
            this.checkboxStatus[input.id]={checked: false, overlay: null};
          var layer_input_id_base = 'layer-'+input.path.replace(new RegExp('/', 'g'),'-')+'-';
          for(var j=0;j<level_layers.length;j++){
            hasLayer = this._map.hasLayer(level_layers[j].layer);
            var layer_input_id = layer_input_id_base+level_layers[j].name;
            //add only those layers which are checked in sub-levels and whose parents are checked
            if (input.checked && level_layers[j].input.checked) {
              addedLayers.push(level_layers[j].layer);
              this.checkboxStatus[layer_input_id]={hidden: false, checked: true, overlay: level_layers[j].layer};
            } else if (!input.checked && hasLayer) {
              removedLayers.push(level_layers[j].layer);
              this.checkboxStatus[layer_input_id]={hidden: true, checked:true, overlay: level_layers[j].layer};
            }  
          }
        }
        
		// Bugfix issue 2318: Should remove all old layers before readding new ones
		for (i = 0; i < removedLayers.length; i++) {
			this._map.removeLayer(removedLayers[i]);
		}
		for (i = 0; i < addedLayers.length; i++) {
			this._map.addLayer(addedLayers[i]);
		}

		//this._handlingClick = false;

		this._refocusOnMap();
	},

	_checkDisabledLayers: function () {
		var inputs = this._form.getElementsByTagName('input'),
		    input,
		    layer,
		    zoom = this._map.getZoom();

		for (var i = inputs.length - 1; i >= 0; i--) {
			input = inputs[i];
      if(input.layerId!==undefined){
			  layer = this._getLayer(input.layerId);
        if(layer!==undefined){
          layer = layer.layer;
          input.disabled = (layer.options.minZoom !== undefined && zoom < layer.options.minZoom) ||
                          (layer.options.maxZoom !== undefined && zoom > layer.options.maxZoom);
        }
      }
		}
	},

  _addToMultiLevelTree: function(tree, level, levels, layers){
    if(level < levels.length){
        var children = tree.getChildren();
        if(level==levels.length-1)
        {
            tree.layers.push(layers);
        }
        else if(children.length == 0){
            tree.addBranch(level+1, levels, layers);
        }        
        else{
            var hasBranch = false;
            for(var i=0; i<children.length && hasBranch == false; i++){
                if(children[i].name==levels[level+1]){
                    hasBranch = true;
                    this._addToMultiLevelTree(children[i], level+1, levels, layers);
                }
            }
            if(!hasBranch){
               tree.addBranch(level+1, levels, layers); 
            }
        }
    }
  },

  _getLayers : function(tree, level, levels){
    var children = tree.getChildren();
    if(children.length == 0){
        return tree.layers;
    }
    else{
        var result = []
        if(tree.layers.length > 0 && level >= levels.length-1){
            result = result.concat(tree.layers);
        }
        for(var i=0; i<children.length; i++){
            if(level+1<levels.length){
              if(children[i].name==levels[level+1]){
                  result = result.concat(this._getLayers(children[i], level+1, levels));
              }
            }
            else {
                result = result.concat(this._getLayers(children[i], level+1, levels));
            }
        }
        return result;
    }
  },

  _getCheckedLayers : function(tree, level, levels){
    var children = tree.getChildren();
    if(children.length == 0 && tree.input.checked == true){
        return tree.layers;
    }
    else{
        var result = [];
        if(tree.layers.length > 0 && level >= levels.length-1 && tree.input.checked==true){
            result = result.concat(tree.layers);
        }
        for(var i=0; i<children.length; i++){
            if(level+1<levels.length){
              if(children[i].name==levels[level+1]){
                  result = result.concat(this._getLayers(children[i], level+1, levels));
              }
            }
            else {
                result = result.concat(this._getLayers(children[i], level+1, levels));
            }
        }
        return result;
    }
  },
  
  _toggleAccordion: function(event){
      $(event.target).parent().next().toggle(".hide-level");
  }

});


L.control.MultiLevelLayers = function (baseLayers, overlays, options) {
  return new L.Control.MultiLevelLayers(baseLayers, overlays, options);
};
