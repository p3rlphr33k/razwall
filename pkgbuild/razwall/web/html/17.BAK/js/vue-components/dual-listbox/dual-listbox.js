Vue.component('dual-listbox', {
    props: {
        items: {
            type: Array,
            required: false,
            default: function(){
                return [];
            } 
        },
        groups: {
            type: Array,
            required: false,
            default: function(){
                return [];
            }
        },
        options: {
            type: Object,
            required: false,
            default: function(){
                return {
                    showAvailableFilter: true,
                    showSelectedFilter: true,
                    fontSize: "13px",
                    height: 200,
                    locale: {
                        selectedCounterLabel: 'Selected items',
                        availableListLabel: 'Available',
                        selectedListLabel: 'Selected',
                        availableFilterPlaceholder: 'Filter available items',
                        selectedFilterPlaceholder: 'Filter selected items',
                        addAs:  'Add as',
                        moveAll: 'Move all',
                        removeAll: 'Move all',
                        filtered: 'Filtered',
                        from: 'from',
                    } 
                };
            }
        }
    },

    template: '<div class="bootstrap-duallistbox-container row moveonselect">\
                   <div class="box1" :class="{\'col-md-6\': !groups.length, \'col-md-5\': groups.length}">\
                      <input v-if="options.showAvailableFilter" class="filter form-control" :style="filterStyle" :placeholder="options.locale.availableFilterPlaceholder" type="text" v-model="filteringAvailable">\
                      <div v-if="groups.length" class="groupselect">\
                          <label>{{options.locale.addAs}}&nbsp;</label>\
                          <select class="form-control" :style="selectStyle" v-model="selectedGroup">\
                              <option v-for="group in groups" :value="group.id" >\
                                  {{group.name}}\
                              </option>\
                          </select>\
                      </div>\
                      <label>{{options.locale.availableListLabel}}</label>\
                      <div class="btn-group buttons">\
                          <button type="button" class="btn moveall btn-default" :title="options.locale.moveAll" @click="moveAllToSelected()">\
                              <i class="icon-arrow-right22"></i> <i class="icon-arrow-right22"></i>\
                          </button>\
                          <ul class="form-control" :style="boxStyle">\
                              <li v-for="(item, index) in items" v-show="!isItemSelected(item) && isItemFiltered(item)" :class="{grouped: groups.length}" @click="moveToSelected(index)">{{item.name}}</li>\
                          </ul>\
                          <span class="info-container">\
                              <span v-if="!filteringAvailable" class="filter-info">\
                                 {{options.locale.showingAll}} {{availableItemCounter}}\
                              </span>\
                              <span v-else class="filter-info">\
                                 <span class="label label-warning">\
                                    {{options.locale.filtered}}\
                                 </span>\
                                 {{availableFilteredItemCounter}} {{options.locale.from}} {{availableItemCounter}}\
                              </span>\
                          </span>\
                      </div>\
                   </div>\
                   <div class="box2" :class="{\'col-md-6\': !groups.length, \'col-md-7\': groups.length}" :style="box2Style">\
                      <input v-if="options.showSelectedFilter" class="filter form-control" :style="filterStyle" :placeholder="options.locale.selectedFilterPlaceholder" type="text" v-model="filteringSelected">\
                      <label :style="box2SelectedStyle">{{options.locale.selectedListLabel}}</label>\
                      <div class="btn-group buttons">\
                         <button type="button" class="btn moveall btn-default" :title="options.locale.removeAll" @click="moveAllToAvailable()">\
                            <i class="icon-arrow-left22"></i> <i class="icon-arrow-left22"></i>\
                         </button>\
                         <ul class="form-control" :style="boxStyle">\
                            <li v-for="(item, index) in items" v-show="isItemSelected(item) && isItemFiltered(item)" :class="{grouped: groups.length}" @click="moveToAvailable(index)">{{item.name}}\
                                <select v-if="item.group" class="form-control" :style="inlineSelectStyle" v-model="item.group" @change="emitChangeEvent" @click.stop>\
                                    <option v-for="group in groups" :value="group.id" >\
                                        {{group.name}}\
                                    </option>\
                                </select>\
                            </li>\
                         </ul>\
                         <span class="info-container">\
                             <span v-if="!filteringSelected" class="filter-info">\
                                <span v-if="!groups.length">\
                                    {{options.locale.selectedCounterLabel}} ({{selectedItemCounter}})\
                                </span>\
                                <span v-else v-for="group in groups">\
                                    {{group.name}} ({{countGroupItems(group.id)}})&nbsp;&nbsp;\
                                </span>\
                             </span>\
                             <span v-else class="filter-info">\
                                <span class="label label-warning">\
                                    {{options.locale.filtered}}\
                                </span>\
                                {{selectedFilteredItemCounter}} {{options.locale.from}} {{selectedItemCounter}}\
                             </span>\
                         </span>\
                      </div>\
                   </div>\
                </div>',

    data:function(){
        return {
            filteringAvailable: '',
            filteringSelected: '',
            selectedGroup: this.getSelectedGroup(),
            selectedItemIndexes: this.getSelectedItemIndexes(),
            filterStyle: {'font-size': this.options.fontSize},
            boxStyle: {
                height: this.options.height+'px', 
                'font-size': this.options.fontSize},
            box2Style: {
                'margin-top': !this.options.showSelectedFilter ? '46px' : 0,
            },
            box2SelectedStyle: {
                'margin-top': this.groups.length ? '46px' : 0,
            },
            selectStyle: {
                display: 'inline', 
                width: 'auto', 
                'font-size': this.options.fontSize},
            inlineSelectStyle: {
                display: 'inline', 
                padding: '0px 3px',
                width: 'auto', 
                float: 'right',  
                'font-size': this.options.fontSize},
        };
    },

    watch: {
        items: function(){
            this.selectedItemIndexes= this.getSelectedItemIndexes();
            this.emitChangeEvent();
        },

        groups: function(){
            this.selectedGroup = this.getSelectedGroup();
            this.emitChangeEvent();
        },

        filteringAvailable: function(){
            this.filter(this.filteringAvailable, false);
        },

        filteringSelected: function(){
            this.filter(this.filteringSelected, true);
        },
        
    },

    computed: {

        selectedItemCounter: function(){
            return this.selectedItemIndexes.length;
        },

        availableItemCounter: function(){
            return this.items.length - this.selectedItemCounter;
        },

        availableFilteredItemCounter: function(){
            var self = this;            
            var counter = 0;
            this.items.forEach(function(item){
               if(!item.selected && item.filtered)
                   counter++;
            });
            return counter;
        },

        selectedFilteredItemCounter: function(){
            var self = this;            
            var counter = 0;
            this.items.forEach(function(item){
               if(item.selected && item.filtered)
                   counter++;
            });
            return counter;
        },

    }, 

    methods: {
        getSelectedItemIndexes: function(){
            var selectedItemIndexes = [];
            for(var i=0;i<this.items.length;i++){
                if(this.items[i].selected)
                    selectedItemIndexes.push(i);
            }
            return selectedItemIndexes;
        },

        getSelectedGroup: function(){
            selectedGroup = null;
            if(this.groups){
                for(var i=0;i<this.groups.length;i++){
                    if(this.groups[i].selected){
                        selectedGroup = this.groups[i].id;
                        break;
                    }
                }
            }
            return selectedGroup;
        },

        filter: function(text, isSelected){
            var self = this;
            var sanitizedText = self.sanitizeInput(text);
            var regSearch = new RegExp(sanitizedText, 'i');
            self.items.forEach(function(item){
               if((isSelected == false && (item.selected === undefined)) || item.selected == isSelected){
                  if(regSearch.test(item.name)){
                      Vue.set(item, 'filtered', true);
                  } else {
                      Vue.set(item, 'filtered', false);
                  }
               } 
            });
        },

        filterSingleItem: function(text, item){
            var sanitizedTex = this.sanitizeInput(text);
            var regSearch = new RegExp(sanitizedText, 'i');
            if(regSearch.test(item.name)){
                Vue.set(item, 'filtered', true);
            } else {
                Vue.set(item, 'filtered', false);
            }
        },

        sanitizeInput: function(input){
            return input.replace(/[.*+?^${}()|[\]\\]/g, '');  //sanitize remove all special characters
        },

        isItemFiltered: function(item){
            var isFiltered = true;
            if(item.filtered !== undefined){
                return item.filtered;
            }
            return isFiltered;
        },

        isItemSelected: function(item){
            var isSelected = false;
            if(item.selected !== undefined && item.selected)
                isSelected = true;
            return isSelected;
        },

        moveToSelected: function(itemIndex, prevent){
            Vue.set(this.items[itemIndex], 'selected', true);
            this.selectedItemIndexes.push(itemIndex);
            if(this.selectedGroup){
                Vue.set(this.items[itemIndex], 'group', this.selectedGroup);
            }
            if(this.filteringSelected)
                this.filterSingleItem(this.filteringSelected, this.items[itemIndex]);
            if(!prevent)
                this.emitChangeEvent();

        },

        moveToAvailable: function(itemIndex, prevent){
            Vue.set(this.items[itemIndex], 'selected', false);
            //remove from selectedItemIndexes
            index = this.selectedItemIndexes.indexOf(itemIndex);            
            if(index > -1)
                this.selectedItemIndexes.splice(index, 1);
            if(this.filteringAvailable)
                this.filterSingleItem(this.filteringAvailable, this.items[itemIndex]);
            if(!prevent)
                this.emitChangeEvent();
        },

        moveAllToSelected: function(){
            this.selectedItemIndexes = [];
            for(var i=0;i<this.items.length;i++)
            {
                if(this.filteringAvailable){
                   if(this.items[i].filtered === undefined || this.items[i].filtered) 
                     this.moveToSelected(i, true);
                }else{
                    this.moveToSelected(i, true);
                }
            }
            this.emitChangeEvent();
        },

        moveAllToAvailable: function(){
            for(var i=0;i<this.items.length;i++)
            {
                if(this.filteringSelected){
                   if(this.items[i].filtered === undefined || this.items[i].filtered) 
                     this.moveToAvailable(i, true);
                }else{
                    this.moveToAvailable(i, true);
                }
            }
            this.emitChangeEvent();
        },

        countGroupItems: function(groupId){
            var self = this;
            var counter = 0;
            self.items.forEach(function(item){
               if(item.selected && item.group == groupId) 
                   counter++;
            });
            return counter;
                
        },

        emitChangeEvent: function(){
            var self = this;
            var selectedItems = [];
            var groups = {};
            self.groups.forEach(function(group){
                groups[group.id] = [];
            });
            self.selectedItemIndexes.forEach(function(itemIndex){
               var item = self.items[itemIndex];
               var groupId = item.group;
               if(groupId){
                  groups[groupId].push(item.id);
               }else{
                  selectedItems.push(item.id);
               }
            });
            var ret = selectedItems;
            if(this.groups.length)
                ret = groups;
            this.$emit('change', ret);
        },
    }
});
