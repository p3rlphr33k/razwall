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

function Map(options){
    this._initialize(options)
}
Map.prototype = {
    constructor: Map,

    /*---------------------------------default options-----------------------------------------------------*/
    
    options: {
      id: "map", //the div id where show the map
      initLat: 0, //initial latitude
      initLong: 0, //initial longitude
      initZoom: 3, //initial map zoom 
      searchField: true, //add search function
      groupFilter: true, //add a box to filter by groups of markers
      tagFilter: true, //add a box to filter markers by tags
      searchFilters: ['groups','tags','path'], //optional list of searchable marker fields
      exclusiveSearch: true, // show only the searched results on the map
      filterResetLabel: "Reset filters (Esc)",
      searchExitLabel: "Exit search (Esc)",
      clusterize: true,
      editorMode: false, //editor mode is used to set marker location 
      tileURL: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors',
      fitBoundPadding: [100,100]
    },

    
    /*---------------------------------private attributes-------------------------------------------------*/

    //common settings of the marker label
    _commonLabelSettings: {
                  permanent: true, 
                  direction: 'right',
                  offset: L.point(0,0),
                  direction: 'bottom',
    },
    _controlGroup: null, // MultiLevel control layer for group filter
    _controlTag: null,// MultiLevel control layer for tag filter
    _controlSearch: null, // Control layer for search plugin

    _markerWithOpenPopup: null,
    _layerGroupsToRemove: [], // temp list of  layer groups that must be removed
    _layerGroups: [],

    /*---------------------------------initialize the map-------------------------------------------------*/
    
    _initialize: function(options){
        $.extend(true, this.options, options);

        this._firstMapLoad = true;
        //default geographical centre of Earth
        this.map = L.map(this.options.id, {maxZoom: 18}).setView([this.options.initLat, this.options.initLong], this.options.initZoom);

        this._markerFilterMap = new MarkerFilterMap(this);
        
        this._markerGroupFilter = new MarkerFilter('groups');
        this._markerFilterMap.add(this._markerGroupFilter);
        
        this._markerTagFilter = new MarkerFilter('tags');
        this._markerFilterMap.add(this._markerTagFilter);
        
        this._mapSnapshot = new MapSnapshot(this);
        this._markerSearch = new MarkerSearch(this);
        //default setting of the search plugin
        this._searchFieldSettings = {
                position:'topright',		
                initial: false,
                zoom: 18,
                marker: false,
                propertyName: 'label',
                collapsed: false,
                filterData: this._markerSearch.filterSearchData,
                buildTip: function(text, val) {
			            var tags = val.layer.options.tags;
                  var groups = val.layer.options.groups;
                  var path = val.layer.options.path;
                  if(path===undefined)
                      path="";
                  var tip = '<a href="#" class="tag-'+tags[0]+'"><b>'+text+'</b>'+path+'<br>';
                  tip+= "Groups: "+groups.join()+'</a>';
                  return tip;
                }
        };

        
        //clusterize
        var that = this;
        if(this.options.clusterize){
            this._mcgLayerSupportGroup = L.markerClusterGroup.layerSupport({
                chunkedLoading: false,
                spiderfyDistanceMultiplier: 3,
                zoomToBoundsOnClick: false
            });
            this._mcgLayerSupportGroup.addTo(this.map);
            this._mcgLayerSupportGroup.on('clusterclick', function (a) {
	            a.layer.zoomToBounds({padding: that.options.fitBoundPadding});
            });
        }

        // set the tile layer
        L.tileLayer(this.options.tileURL, {
              attribution: this.options.attribution
        }).addTo(this.map);

        if(this.options.searchField || this.options.groupFilter || this.options.tagFilter)
            this._createResetFiltersButton();
        
        $(document).keydown(function(e) {
            if (e.originalEvent.keyCode == 27) { // escape key maps to keycode `27`
                var closePopupAction = false;
                if(that._markerWithOpenPopup){
                    var popup = that._markerWithOpenPopup.getPopup();
                    if(popup && popup.isOpen()){
                        that._markerWithOpenPopup.closePopup();
                        closePopupAction = true;
                    }
                }
                if(!closePopupAction)
                    that._resetMapFiltersAndSearch();
            }
        });
        
        $(".leaflet-control-layers-list.leaflet-control-layers-scrollbar").ready(function(){
            if(that._controlGroupScrollbarPosition)
                $(".leaflet-control-layers-list.leaflet-control-layers-scrollbar").scrollTop(that._controlGroupScrollbarPosition);
        });
       
        //workaround for popup automatically closed by leaflet (without user action) 
        this.map.on('layeradd', function(event){
            if(that._addingMarkers && that._markerWithOpenPopup){
                 var popup = that._markerWithOpenPopup.getPopup();
                 if(popup && !popup.isOpen()){
                     that._markerWithOpenPopup.openPopup();
                 }
            }
        });

    },


    /*---------------------------------public methods -------------------------------------------------*/
    
     /**
     * Set common settings for labels. See leaflet options
     * url: http://leafletjs.com/reference-1.0.3.html#icon
     */ 
    setLabelCommonSettings: function(options){
        $.extend(true, this._commonLabelSettings, options);
    },

     /**
     * Set search field settings.
     * @param search plugin options
     */ 
    setSearchFieldSettings: function(options){
        $.extend(true, this._searchFieldSettings, options);
    },
      
    /**
     * Set a list of markers to show on the map 
     * @ markers: a list of markers with the following options:
     *
     * markerID: ID to identify the marker
     * label: label to show under the marker icon
     * latitude,longitude: position of the marker
     * iconPath: path to the marker icon
     * shadowPath: path to the shadow icon of the marker
     * popupContentGenerator: optional callback that set the content of !_!Apopup
     * path: an optional hierarchical position of the marker written as a path, e.g: /org1/org2/
     * groups: an optional list of groups to which the marker appertains
     * tags: an optional tag list to better identify the marker
     * labelClassName: css class name for the label
     * 
     * other options provided by Leaflet are allowed (see http://leafletjs.com/reference-1.0.3.html#marker) 
     */
    setMarkers: function(markers){
        var block_0_start = Date.now();
        if(this.map !== undefined){
            this._mapSnapshot.save('before_update')
            if(this._controlGroup)
                this._controlGroupScrollbarPosition = $(".leaflet-control-layers-list.leaflet-control-layers-scrollbar").scrollTop();
            this._clearMap(); 
            this._layerGroups = [];
        }

        this._markersDict = {};
        
        var that = this;
       
        this._addingMarkers = true;
        for(var i=0;i<markers.length;i++){
            var mapMarker = this._createMarker(markers[i]);
            this._addMarkerToFilters(mapMarker);
            this._markersDict[markers[i].markerID] = mapMarker;
        }
        this._addMarkersToMap();
        this._addingMarkers = false;
        
        if(this.options.searchField)
            this.addSearchField(this._searchFieldSettings);

        //init group\path filter control layer
        if(this._controlGroup == null && this.options.groupFilter){
            if(this._markerGroupFilter.countOptions() > 1){
                if(this.filterAnimation){
                    var options = {classNameSuffix: 'groups',
                      animateOnOver: true, 
                      onOverAnimation: this.filterAnimation.onOverAnimation, 
                      onLeaveAnimation: this.filterAnimation.onLeaveAnimation
                    };
                    this._controlGroup = new L.control.MultiLevelLayers(null, null, options);
                }
                else
                    this._controlGroup = new L.control.MultiLevelLayers(null, null, {classNameSuffix: 'groups'});
                this._controlGroup.addTo(this.map);
            }
        }
        
        //init tag filter control layer
        if(this._controlTag == null && this.options.tagFilter){
            if(this._markerTagFilter.countOptions() > 1){
                if(this.filterAnimation){
                    var options = {multiLevels: false,
                      classNameSuffix: 'tags',
                      animateOnOver: true,
                      onOverAnimation: this.filterAnimation.onOverAnimation,
                      onLeaveAnimation: this.filterAnimation.onLeaveAnimation
                    };
                    this._controlTag = new L.control.MultiLevelLayers(null, null, options);
                }
                else
                    this._controlTag = new L.control.MultiLevelLayers(null, null, {multiLevels: false, classNameSuffix: 'tags'});
                this._controlTag.addTo(this.map);
            }
        }
        if(this.options.groupFilter && this._controlGroup){
            this._markerGroupFilter.addToControlLayer(this._controlGroup);
            this._controlGroup.generateCheckboxTree();
        }
        if(this.options.tagFilter && this._controlTag)
            this._markerTagFilter.addToControlLayer(this._controlTag);

        //add event listeners
        this.map.on('overlayadd', function(event){
            if(that.options.groupFilter && that.options.tagFilter){
                that._markerFilterMap.activeFilterOption(event.name);
            }
            that.fitBounds();
        }).on('overlayremove', function(event){
            if(that.options.groupFilter && that.options.tagFilter){
                that._markerFilterMap.disactiveFilterOption(event.name);
            }
            that.fitBounds();
        });

        this._restoreMap();
    },

    /***
     * Show on the map only a single marker 
     */
    setSingleMarker: function(marker){
       this.setMarkers([marker]); 
    },

    /***
     * Set the map bounds in order to show all the markers 
     */
    fitBounds: function(){
        if(!this._mapSnapshot.resume_started){
            if(this.options.clusterize && (!this._firstMapLoad || this._controlGroup || this._controlTag) ){
                var bounds = this._mcgLayerSupportGroup.getBounds();
                this.map.fitBounds(bounds, {padding: this.options.fitBoundPadding});
                return;
            }
            var markers = this._getVisibleMarkers();
            if(markers !== undefined && markers.length>0){
              var featureGroup = L.featureGroup(markers);
              var bounds = featureGroup.getBounds();
              this.map.fitBounds(bounds, {padding: this.options.fitBoundPadding}); 
            }else{
              this.map.fitWorld();
            }
        }
        this._firstMapLoad = false;
    },

    fitMarkerBounds: function(markers){
        var featureGroup = L.featureGroup(markers);
        this.map.fitBounds(featureGroup.getBounds());
    },

    addSearchField: function addSearchField(options){
        this._searchLayer = new L.layerGroup(this._getAllMarkers())
        options['layer']=this._searchLayer;
        if(this._controlSearch!=null){
            this._controlSearch.options.layer = this._searchLayer;
            this._controlSearch.initialize();
        }else{
            this._controlSearch = new L.Control.Search(options);
            //Fix not accurate auto resize function
            this._controlSearch._handleAutoresize = function(){};
            this.map.addControl(this._controlSearch);
        }
        // Map the search cancel button to the Exit search map button
        var that = this;
        $(".search-cancel").on("click", function(){
            that._resetMapFiltersAndSearch();
        });
        

    },

    addFullscreenToggleButton: function(options){
        L.control.fullscreen(options).addTo(this.map);  
    },

    addNewWindowButton: function(options){
        L.control.newwindow(options).addTo(this.map);
    },

    addFilterAnimation: function(onOverCallback, onLeaveCallback){
        this.filterAnimation = {};
        this.filterAnimation.onOverAnimation = onOverCallback;
        this.filterAnimation.onLeaveAnimation = onLeaveCallback;
    },

    getMarkerByID: function(markerID){
        return this._markersDict[markerID];
    },

    /*---------------------------------private methods-------------------------------------------------*/

    _restoreMap: function(){
            //recover filter state
            this._mapSnapshot.resume('before_update');
            //check if the map is in search mode
            if(this._mapSnapshot.exists('before_search')){
                //disable group filters checkboxes
                $(".leaflet-control-layers-toggle.groups").css("display","none"); 
            }
    },

    _resetMapFiltersAndSearch: function(){ 
        if(this._mapSnapshot.exists('before_search')){
            $(".leaflet-control-layers-toggle.groups").css("display","");
            this._markerSearch.clear();
            this._controlSearch.cancel();
            this._mapSnapshot.resume('before_search');
            this._mapSnapshot.delete('before_search');
        }else{
            //reset the filters (check all the checkboxes)
            if(this._controlGroup!=null){
                for(var key in this._controlGroup.checkboxStatus){
                    var checkboxStatus = this._controlGroup.checkboxStatus[key];
                    if(!checkboxStatus.checked){
                        $('#'+key).trigger('click');
                    }
                }
            }
            if(this._controlTag!=null){
                for(var key in this._controlTag.checkboxStatus){
                    var checkboxStatus = this._controlTag.checkboxStatus[key];
                    if(!checkboxStatus.checked){
                        $('#'+key).trigger('click');
                    }
                }
            }
            $(".leaflet-control-layers-selector").next().next().removeClass('hide-level');
        }
        $("#map-mode-button").html(this.options.filterResetLabel);
        this.fitBounds();
    },

    _getAllMarkers: function(){
        var markers = [];
        for(var marker in this._markersDict){
            markers.push(this._markersDict[marker]);
        }    
        return markers;
    },
    
    _getVisibleMarkers: function(){
        var bounds = [];
        this.map.eachLayer(function (layer) {
          if(layer.options.markerID !== undefined){
              bounds.push(layer);
          }
        });
        return bounds;
    },
    
    _createMarker: function(marker){
         var markerIcon = new L.divIcon(marker.iconSettings);
         marker.icon = markerIcon;

         var leafletMarker = L.marker([marker.latitude, marker.longitude], marker); 
         
         //add to a group
         var groups = marker.groups;
         var path = marker.path
         if(groups === undefined || groups.length == 0){
            //add a default group with no name
            groups = [""];
            //if a path is setted add a group with the same name of the last path level
            if(path){
                var levels = path.split("/");
                var last_level = levels[levels.length-1];
                groups = [last_level];
            }
            leafletMarker.options.groups = groups;
         }
            
         //prepare the marker label class
         this._commonLabelSettings['className'] = marker.labelClassName;

         if(this._markerHasOpenPopup(marker)){
            //update current marker information
            var popupMarker = this._markerWithOpenPopup;
            marker.popupContentGenerator(this._markerWithOpenPopup);
            popupMarker.options = leafletMarker.options;
            popupMarker.setIcon(markerIcon);
            //update the label
            popupMarker.unbindTooltip();
            popupMarker.bindTooltip(marker.label, this._commonLabelSettings);
            //delete residual layerGroups
            var layerGroup = this._layerGroupsToRemove.pop(); 
            while(layerGroup){
                this.map.removeLayer(layerGroup);
                layerGroup = this._layerGroupsToRemove.pop();
            }
            return popupMarker; 
        }else{
             //add the label
             leafletMarker.bindTooltip(marker.label, this._commonLabelSettings);
             var that = this;
             //Bind a popup to the marker. Popup content is generated calling popupContentGenerator 
             if(marker.popupContentGenerator !== undefined)
             {
                var popup = new L.popup().setContent();
                leafletMarker.bindPopup(popup);
                leafletMarker.on('popupopen', function(event){
                    var marker = event.target;
                    that._markerWithOpenPopup = marker;
                    marker.options.popupContentGenerator(marker);
                });
             }
             return leafletMarker;
         }
        
    },

    _addMarkerToFilters: function(marker){
        this._markerGroupFilter.addMarker(marker);
        if(marker.options.tags !== undefined)
            this._markerTagFilter.addMarker(marker);
    },

    _markerHasOpenPopup: function(marker){
        var result = false;
        if(!this.options.editorMode && 
            (this._markerWithOpenPopup && marker.markerID == this._markerWithOpenPopup.options.markerID))
            result = true;
        return result;
    },

    _addMarkersToMap: function(){
        var layerGroups = this._layerGroups;
        if(this.options.clusterize){
            this._mcgLayerSupportGroup.addLayers(layerGroups);
        } else {
            for (var i = 0; i <= layerGroups.length; i++)
                this.map.addLayer(layerGroups[i]);
        }
    },

    _createResetFiltersButton: function(){
        var containerDiv = '<div class="leaflet-bottom leaflet-right" >';
        containerDiv += '<div class="leaflet-control-zoom leaflet-bar leaflet-control" style="margin-bottom: 30px;">';
        containerDiv += '<a id="map-mode-button" class="leaflet-control-zoom" href="#" style="width:auto;height:auto;padding:4px;line-height:unset;"></a></div></div>';
        $(".leaflet-control-container").append(containerDiv);
        var defaultText = this.options.filterResetLabel;
        var button = $("#map-mode-button");
        $("#map-mode-button").html(defaultText);
        var that = this;
        button.click(function(){
            that._resetMapFiltersAndSearch();
        });
    },
    
    _clearLayerGroupMarkers: function(layerGroup){
        var markers = layerGroup.getLayers();
        var that = this;
        var removeGroupLayer = true;
        markers.forEach(function(marker){
            var remove = false;
            var popup = marker.getPopup();
            //we want to maintain the popup open
            if(!that.options.editorMode && popup){
                if(popup.isOpen()){
                  that._markerWithOpenPopup = marker;
                  that._popupIsOpen = true;
                  removeGroupLayer = false;
                }
            }
        });
        if(removeGroupLayer){
            this.map.removeLayer(layerGroup);
        }
        else
            this._layerGroupsToRemove.push(layerGroup);
    },

    _dismissFromClusterGroup: function(layerGroup){
        // Un-stamp layerGroup.
        var that = this;
        layerGroup.getLayers().forEach(function(layer){
		    delete that._mcgLayerSupportGroup._layers[layer._leaflet_id];
        });

        layerGroup.removeLayer = layerGroup._originalRemoveLayer;

        var id = L.stamp(layerGroup);
        delete this._mcgLayerSupportGroup._proxyLayerGroups[id];
        delete this._mcgLayerSupportGroup._proxyLayerGroupsNeedRemoving[id]; 
    },

    _clearMarkerFilterAndControlLayer: function(markerFilter, controlLayer){
        var filterOptions = markerFilter.getOptions();
        for(var option in filterOptions){
            var filterOption = filterOptions[option];
            if(controlLayer)
                controlLayer.removeLayer(filterOption.layerGroup);
            if(this._mcgLayerSupportGroup)
                this._dismissFromClusterGroup(filterOption.layerGroup);
            this._clearLayerGroupMarkers(filterOption.layerGroup);
        }
        markerFilter.clear();
    },

    _clearMap: function(){
        this._popupIsOpen = false;

        this._clearMarkerFilterAndControlLayer(this._markerGroupFilter, this._controlGroup);
        this._clearMarkerFilterAndControlLayer(this._markerTagFilter, this._controlTag);

        if(this._controlGroup != null){
            this._controlGroup.clearLevelTree();
        }

        if(!this._popupIsOpen)
            this._markerWithOpenPopup = null;

        //remove event listeners
        this.map._events.overlayadd = [];
        this.map._events.overlayremove = [];   
    },

    _isMarkerInsideCluster: function(marker){
        var insideCluster = false;
        if(this.options.clusterize){
            var visibleOne = this._mcgLayerSupportGroup.getVisibleParent(marker);
            if(visibleOne)
                insideCluster = true;
        }
        return insideCluster;
    }

}


function MarkerFilterMap(map){
    var _map = map;
    var _markerFilters = {};

    this.add = function(markerFilter){
        markerFilter._map = _map;
        _markerFilters[markerFilter.getFilterBy()] = markerFilter;
    };
    
    this.get = function(filterByFieldName){
        return _markerFilters[filterByFieldName];
    };
     
    this.disactiveFilterOption = function(name){
        var markerFilter = _getMarkerFilterByOptionName(name);
        var markers = markerFilter.getMarkersByOptionName(name);
        if(markers.length > 0){
            markers.forEach(function(marker){
                var anyMarkerGroupActived = _markerFilters['groups'].isAnyActivedFilterOption(marker.options.groups);
                var anyMarkerTagActived = _markerFilters['tags'].isAnyActivedFilterOption(marker.options.tags)
                if(anyMarkerGroupActived && anyMarkerTagActived && !_map._markerSearch.isMarkerHidden(marker.options.markerID)){
                    //show the marker on the map
                    _map.map.addLayer(marker);
                }                
            });
        }
    }; 

    this.activeFilterOption = function(name){
        var markerFilter = _getMarkerFilterByOptionName(name);
        var markers = markerFilter.getMarkersByOptionName(name);
        if(markers.length > 0){
            markers.forEach(function(marker){
                var allMarkerGroupsDisactived = _markerFilters['groups'].areAllDisactivedFilterOptions(marker.options.groups);
                var allMarkerTagsDisactived = _markerFilters['tags'].areAllDisactivedFilterOptions(marker.options.tags);
                if(allMarkerGroupsDisactived || allMarkerTagsDisactived || _map._markerSearch.isMarkerHidden(marker.options.markerID)){
                    //do not show the marker on the map
                    _map.map.removeLayer(marker);
                }
            });
        }

    }; 

    this.getMarkerFilters = function(){
        return _markerFilters;
    }

    function _getMarkerFilterByOptionName(optionName){
        for(var filter in _markerFilters){
            var markerFilter = _markerFilters[filter];
            var markers = markerFilter.getMarkersByOptionName(optionName);
            if(markers.length > 0)
                return markerFilter;
        } 
        return {};
    }

}


function MarkerFilter(filterByFieldName){
    //this attribute is updated by MarkerFilterList instance
    this._map = null;
    
    var _options = {};
    var _filterBy = filterByFieldName;

    this.getFilterBy = function(){
        return _filterBy;
    };

    this.getLayerGroups = function(names){
        var result = [];
        names.forEach(function(name){
            var option = _options[name];
            if(option)
                result.push(option.layerGroup);
        });
        return result;
    };
 
    this.isAnyActivedFilterOption = function(markerGroups){
        var layerGroups = this.getLayerGroups(markerGroups);
        for(var i=0;i<layerGroups.length;i++){
            if(this._map.map.hasLayer(layerGroups[i]))
                return true;
        }
        return false;
    };

    this.areAllDisactivedFilterOptions = function(markerGroups){
        if(markerGroups.length == 0)//the marker has no groups so they cannot be disactived
            return false;
        var layerGroups = this.getLayerGroups(markerGroups);
        for(var i=0;i<layerGroups.length;i++){
            if(this._map.map.hasLayer(layerGroups[i]))
                return false;
        }
        return true;
    };

    this.addToControlLayer = function(controlLayer){
        for(var option in _options ){
            var filterOption = _options[option];
            controlLayer.addOverlay(filterOption.layerGroup, filterOption.name, filterOption.path);
        }
    };

    this.addMarker = function(marker){
        var filterOptions = marker.options[_filterBy];
        for(var i=0;i<filterOptions.length;i++){
            var filterOption = _options[filterOptions[i]];
            var layerGroup;
            if(filterOption){
                filterOption.layerGroup.addLayer(marker);
            }else{
                layerGroup = L.layerGroup();
                layerGroup.addLayer(marker);
                this._map._layerGroups.push(layerGroup);
                layerGroup._name = filterOptions[i]; 
                var path = "root";
                if(marker.options.path!==undefined)
                    path += marker.options.path;
                _options[filterOptions[i]] = {name: filterOptions[i], path: path, layerGroup: layerGroup};
            }
        }
    };

    this.getMarkersByOptionName = function(name){
        var filterOptions = _options[name];
        if(filterOptions)
            return filterOptions.layerGroup.getLayers();
        else
            return [];
    };

    this.getOptions = function(){
        return _options;
    };

    this.countOptions = function(){
        var counter = 0;
        for(option in _options)
            counter++;
        return counter;
    };

    this.clear = function(){
        _options = {};
    };

}


function MapSnapshot(map){

    var _map = map;
    var _leafletMap = map.map;
    var _snapshots = {};

    this.resume_started = false;

    this.save = function(snapshotName){
        _snapshots[snapshotName] = {};
        var mapSnapshot = _snapshots[snapshotName];
        mapSnapshot.removedMarkers = [];
        mapSnapshot.uncheckedInputs = [];
        mapSnapshot.searchCache = {};
        mapSnapshot.controlGroupScrollbarPosition = null;
        
        if(_map._controlGroup!=null){
            for(var key in _map._controlGroup.checkboxStatus){
                var checkboxStatus = _map._controlGroup.checkboxStatus[key];
                if(!checkboxStatus.checked || checkboxStatus.hidden){
                    if(!checkboxStatus.checked)
                        mapSnapshot.uncheckedInputs.push(key);
                }
            }
            mapSnapshot.controlGroupScrollbarPosition = $(".leaflet-control-layers-list.leaflet-control-layers-scrollbar").scrollTop();
        }
        
        if(_map._controlTag!=null){
            for(var key in _map._controlTag.checkboxStatus){
                var checkboxStatus = _map._controlTag.checkboxStatus[key];
                if(!checkboxStatus.checked){
                    mapSnapshot.uncheckedInputs.push(key);
                }
            }
        }
       
        //Fill removed markers
        for(var markerID in _map._markersDict){
            var marker = _map._markersDict[markerID];
            if(_map._markerSearch.isMarkerHidden(markerID)){
                mapSnapshot.removedMarkers.push(markerID);
            }
        }

        //Save search cache
        if(_map._controlSearch){
            var searchCache = _map._controlSearch._recordsCache;
            for(var key in searchCache){
               mapSnapshot.searchCache[key] = {lat: '', lng: '', layer: null}  
            }
        }


    };

    this.resume = function(snapshotName){
        this.resume_started = true;
        if(this.exists(snapshotName)){ 
            var mapSnapshot = _snapshots[snapshotName];

            // resume checkboxes
            mapSnapshot.uncheckedInputs.forEach(function(input_id){
                $input = $("#"+input_id); 
                if($input.is(':checked')){
                    // uncheck it
                    $input.trigger('click');
                    //hide the accordion div
                    $input.parent().next().css('display','none');
                }else{
                    // check and uncheck it
                    $input.trigger('click');
                    $input.trigger('click');
                }
            });

            // resume the visible markers
            mapSnapshot.removedMarkers.forEach(function(marker){
                var mapMarker = _map._markersDict[marker.options.markerID];
                if(mapMarker)
                    _leafletMap.removeLayer(mapMarker);
            });

            // resume search cache
            if(_map._controlSearch){
                for(var key in mapSnapshot.searchCache){
                   var marker = _map._markersDict[key];
                   if(marker){
                       mapSnapshot.searchCache[key].lat = marker.getLatLng().lat; 
                       mapSnapshot.searchCache[key].lng = marker.getLatLng().lng; 
                       mapSnapshot.searchCache[key].layer = marker;
                   } 
                }
                $.extend(true, _map._controlSearch._recordsCache, mapSnapshot.searchCache);
            }
            
        }
      this.resume_started = false;

    };

    this.exists = function(snapshotName){
        var result = false;
        if(_snapshots[snapshotName] !== undefined)
          result = true;
        return result;
    };

    this.delete = function(snapshotName){
        delete _snapshots[snapshotName]; 
    };

}


function MarkerSearch(map, options){
    var _map = map;
    var _leafletMap = map.map;
    var _options = map.options;
    var _hiddenMarkerIDs = [];

    this.clear = function(){
        _restoreAllMarkers();
    }

    this.isMarkerHidden = function(markerID){
        return _hiddenMarkerIDs.indexOf(markerID) > -1;
    }

    this.filterSearchData = function(text, records) {
        _prepareMap();

        var I, icase, regSearch, frecords = {}, markerFound;

        text = text.replace(/[.*+?^${}()|[\]\\]/g, '');  //sanitize remove all special characters
        if(text==='')
          return [];

        I = this.options.initial ? '^' : '';  //search only initial text
        icase = !this.options.casesensitive ? 'i' : undefined;

        regSearch = new RegExp(I + text, icase);

        markerFound = false;

        for(var key in records) {
          var marker = records[key].layer;
          var matched = false;
          //test the marker label
          if( regSearch.test(key) ){
              matched = true;
          }
          else{
              for(var i=0;i<_options.searchFilters.length;i++){
                  var filteredField = marker.options[_options.searchFilters[i]];
                  if(Object.prototype.toString.call( filteredField ) === '[object Array]'){
                      for(var j=0; j<filteredField.length && matched == false;j++){
                          if(regSearch.test(filteredField[j]))
                              matched = true;
                      }
                  }else if (typeof filteredField === 'string'){
                      if(regSearch.test(filteredField))
                          matched = true;
                  }
              }
          }
          //check if marker is already filtered by group or tag filters
          // in that case do not show it in search results
          if(matched && !_isMarkerFiltered(marker)){
              frecords[key] = records[key];
              markerFound = true;
          }
        }
        if(_options.exclusiveSearch && markerFound){
            var frecordsMarkers = [];
            var frecordsMarkerIds = []
            _hiddenMarkerIDs = [];
            for(var key in frecords){
                frecordsMarkers.push(frecords[key].layer);
                frecordsMarkerIds.push(frecords[key].layer._leaflet_id);
            }
            //restore markers deleted by previous search
            _restoreDeletedMarkers(frecordsMarkers);
            for(var markerID in _map._markersDict){
                var marker = _map._markersDict[markerID];
                //if the marker is not in the list of results remove it from the map
                if(frecordsMarkerIds.indexOf(marker._leaflet_id) <= -1){
                    _leafletMap.removeLayer(marker);
                    //store the IDs of the removed markers in a list that is be used by filters
                    if(_hiddenMarkerIDs.indexOf(markerID) <= -1)
                        _hiddenMarkerIDs.push(markerID);
                }
            }
            _map.fitBounds();
        }

        return frecords;
    };

    function _restoreDeletedMarkers(markers){
        for(var i=0;i<markers.length;i++){
            if(!_leafletMap.hasLayer(markers[i]) && !_map._isMarkerInsideCluster(markers[i])){
                _leafletMap.addLayer(markers[i]);
            }
        }
    }

    function _prepareMap(){
        //hide group filters checkboxes controller
        $(".leaflet-control-layers-toggle.groups").css("display","none");
        //Change reset button label 
        $("#map-mode-button").html(_map.options.searchExitLabel);
        
        if(!_map._mapSnapshot.exists('before_search'))
            _map._mapSnapshot.save('before_search'); 
    }

    function _isMarkerFiltered(marker){
        // filtered means that the merker is not visible on the map
        var group_filtered = _areMarkerFilterOptionsFiltered(marker.options.groups, _map._controlGroup);
        var tag_filtered = _areMarkerFilterOptionsFiltered(marker.options.tags, _map._controlTag);
        return group_filtered || tag_filtered;
    };

    function _areMarkerFilterOptionsFiltered(markerFilterOptions, controlLayer){
        if(!controlLayer)
            return false;
        var filtered=true;
        // check whether marker groups\tags are filtered or not 
        if(markerFilterOptions === undefined || markerFilterOptions.length == 0 || markerFilterOptions[0]==""){
            filtered=false;
        }else{
            markerFilterOptions.forEach(function(name){
               for(var key in controlLayer.checkboxStatus){
                    var checkboxStatus = controlLayer.checkboxStatus[key];
                    if(checkboxStatus.overlay != null){
                        if(checkboxStatus.overlay._name==name && (!checkboxStatus.checked || checkboxStatus.hidden)){
                            filtered = filtered && true;
                        }else if (checkboxStatus.overlay._name==name && (checkboxStatus.checked || !checkboxStatus.hidden)){
                            filtered = filtered && false;
                        }
                    }
               }
            }); 
        }

        return filtered;
    };

    function _restoreAllMarkers(){
        //restore the delete markers
        if(_hiddenMarkerIDs.length > 0){
            _hiddenMarkerIDs.forEach(function(marker){
                var mapMarker = _map._markersDict[marker];
                if(!_leafletMap.hasLayer(mapMarker) && !_map._isMarkerInsideCluster(mapMarker))
                    _leafletMap.addLayer(mapMarker); 
            });
            _hiddenMarkerIDs = [];
        }

    }
}
