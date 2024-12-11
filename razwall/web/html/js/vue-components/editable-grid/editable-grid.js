/* editable-grid is a VueJS 2 component that lets the user to edit table data and validate the input 
 * also through a CSV editor. It uses JQuery DataTables and a customization of jquery-datatables-editable.  
 *
 * Author: Francesco La Spina <f.laspina@endian.com>
 *
*/

Vue.component("editable-grid", {
    props:{
        id: {
            type: String,
            required: true
        },
        csvClassName: String,
        tableClassName: String,
        columns: Array,
        dataSource: Object,
        options:{ 
            type: Object,
            default: function(){ 
                return {
                    showCSVEditor: true,
                    text: {
					    AddRow: "Add row",
					    DeleteRow: "Delete row",
					    ShowCSV: "Show CSV",
					    ShowTable: "Show table",
					    ErrorInLine: "Error in line",
                        missingRequiredField: "Missing required field"
				    }
                } 
            }
        },
        validator: Function
    },
  
	template: '<div :id="id+\'_table_container\'" style="display: block">\
	               <table v-show="!showCSVview" cellpadding="0" cellspacing="0" style="border: 0px solid #000; padding: 0; margin: 0;" :class="tableClassName" :id="id+\'_table\'">\
                   </table>\
                   <editable-grid-csv-view v-show="showCSVview"\
                   :id="id"\
                   :className="errorMessages.length > 0 ? csvClassName+\' has_error\' : csvClassName"\
                   :columns="csvColumns"\
                   :csv-data="localCsvData"\
                   v-on:csv-edit="updateAndValidateLocalCsvData">\
                   </editable-grid-csv-view>\
                   <span v-show="errorMessages" class="fielderror" style="padding-left: 0px">\
                       <span v-for="error in errorMessages" v-if="error.line">\
                          {{options.text["ErrorInLine"]}} #{{error.line}}: {{error.message}}<br>\
                       </span>\
                       <span v-else>\
                	      {{error.message}}<br>\
                       </span>\
                   </span>\
				   <br/>\
                   <button-bar :buttons="buttons" v-on:button-click="handleButtonClicked"></button-bar>\
			   </div>',
            
    data: function(){
        return {
            localCsvData: this.dataSource.csvData,
            csvColumns: [],
            buttons: [
                {id: this.id+'_add_row', label: this.options.text['AddRow'], enabled: true},
                {id: this.id+'_delete_row', label: this.options.text['DeleteRow'], enabled: true},
            ],
            showCSVview: false,
            errorMessages: [],
        }
    },

    mounted: function(){
        this.$watch('columns', this.redrawTable, {
            deep: true,
        });

        this.initializeData();
        this.createTable();

        this.$watch(
            'dataSource', 
            function(){
                this.initializeData();
                this.redrawTable();
            },
            {deep: true}
        )

        if(this.options.showCSVEditor === undefined || this.options.showCSVEditor){
            this.buttons.push({id: this.id+'_show_csv', label: this.options.text['ShowCSV'], enabled: true});
        }

    },
  
    methods: {

        initializeData: function(){
            if(this.dataSource.arrayData){
                this.localCsvData = $.arrayToCsv(this.dataSource.arrayData);
            }else if(this.dataSource.csvData){
                this.localCsvData = this.dataSource.csvData;
            }
        },
        
        createTable: function(){
            var values = this.getArrayData()
            for(var i = 0; i < values.length; i++) {
                if(values[i] == "" && i == values.length - 1){
                    // Remove the last line if it's empty
                    values.splice(i, 1);
                    i--;
                }else{
                    // Add empty values if the elements in the line are less then column number
                    var l = this.columns.length - values[i].length;
                    for(var j = 0; j < l; j++){
                        values[i].push("");
                    }
                }
            }
            // Rewrite normalized values as csv
            this.localCsvData = $.arrayToCsv(values);
        
            var columns = []
            var editableColumns = []
            var defaultRowData = []
            this.csvColumns = [];
            for(var i=0; i<this.columns.length; i++){
                var column = this.columns[i];
                
                var columnOptions = $.extend({
                    title: column.name,
                    orderable: false,
                }, column.dataTableOptions);
                columns.push(columnOptions);
                this.csvColumns.push(column.csvDescription);
                
                var editableColumn = {
                    // NOTE:
                    // - use onblur 'submit' for plain text fields
                    // - use onblur 'ignore' for select items => form submitted on change(); this avoids
                    // qtwebkit visualisation bug caused by double onblur()
                    onblur: column.type == 'select' ? 'ignore' : 'submit',
                    tooltip: column.tooltip ? column.tooltip : '',
                };
                if(column.type == 'select'){
                    editableColumn['type'] = 'select';
                    editableColumn['data'] = column.options;
                }
                editableColumns.push(editableColumn);
                defaultRowData.push(column.defaultValue ? column.defaultValue : '');
            }
            
            var defaultOptions = {
                ordering: false,
                paging: false,
                searching: false,
                info: false,
            };
            //supports DataTables options for customization
            var options = $.extend(defaultOptions, this.options.dataTableOptions);
            options.data = values;
            options.columns = columns;
            this.table = $('#'+this.id+'_table').dataTable(options);
            
            var that = this;
            this.table.makeEditable({
                aoColumns: editableColumns,
                fnOnEdited: function(status) {
                    that.localCsvData = $.arrayToCsv(that.table.fnGetData());
                },
                sAddNewRowButtonId: this.id+'_add_row',
                sDeleteRowButtonId : this.id+'_delete_row',
                newRowDefault: defaultRowData,
            });
            this.table.css("width", "100%");
            },
            
        handleButtonClicked: function(button){
            if(button.id == this.id+"_show_csv"){
                this.showCSV();
            }
            else if(button.id == this.id+"_show_table"){
                this.showTable();
            }
        },
        
        showCSV: function(){
            this.redrawTable();
            this.showCSVview = true;
            this.buttons[2].id = this.id+"_show_table";
            this.buttons[2].label= this.options.text['ShowTable'];
            // disable add row button
            this.buttons[0].enabled = false;
            // disable delete row button
            this.lastDeleteButtonStatus = $('#'+this.buttons[1].id).is(":disabled") ? false : true;
            this.buttons[1].enabled = false;
        },
        
        showTable: function(){
            this.redrawTable();
            this.showCSVview = false;
            this.buttons[2].id = this.id+"_show_csv";
            this.buttons[2].label= this.options.text['ShowCSV'];
            // enable add row button
            this.buttons[0].enabled = true;
            // restore delete row status
            this.buttons[1].enabled = this.lastDeleteButtonStatus;
        },
        
        redrawTable: function(){
            this.table.DataTable().destroy();
            $('#'+this.id+'_add_row').unbind("click");
            this.createTable();
        },
        
        updateAndValidateLocalCsvData: function(csvData){
            this.localCsvData = csvData;
            this.validateGrid();
            this.$emit("grid-edit", this.getArrayData());
        },
        
        validateGrid: function(){
            this.errorMessages = [];
            this.errorMessages = this.errorMessages.concat(this.columnsValidator());
            var data = this.getArrayData();
            if(this.validator && data){
                var errors= this.validator(data);
                if(errors){
                    this.errorMessages = this.errorMessages.concat(errors);
                }
            }        
            if(this.errorMessages.length > 0){
                this.$emit("grid-validation-error");
            }else{
                this.$emit("grid-validation-success");
            }
        },
        
        columnsValidator: function(){
            var that = this;
            var errors = [];
            this.gridIterator(function(cellValue, columnIndex, rowIndex){
                if(that.columns[columnIndex].validator){
                    var error = that.columns[columnIndex].validator(cellValue.trim());
                    if(error){
                        errors.push({line: rowIndex+1, message: error});
                    }
                }
            });
        
            return errors;
        },

        checkRequiredFields: function(){
            var that = this;
            this.gridIterator(function(cellValue, columnIndex, rowIndex){
                if(that.columns[columnIndex].required && cellValue.length == 0){
                    var error = that.options.text['missingRequiredField']+" '"+that.columns[columnIndex].name+"'";
                    that.errorMessages.push({line: rowIndex+1, message: error});
                }
            });
            if(this.errorMessages.length > 0){
                this.$emit("grid-validation-error");
                return false;
            }else{
                this.$emit("grid-validation-success");
                return true;
            }

        },
        
        gridIterator: function(callback){
            var data = this.getArrayData();
            for(var rowIndex=0; rowIndex<data.length; rowIndex++){
                var row = data[rowIndex];
                if (row == "") {
                    // empty row
                    continue;
                }
                for(var columnIndex=0; columnIndex<row.length; columnIndex++){
                    var cellValue = row[columnIndex];
                    if(callback){
                        callback(cellValue, columnIndex, rowIndex);
                    }
                }
            }
        },

        getArrayData: function(){
           return $.csvToArray(this.localCsvData); 
        },

        
    },
   
    
});


Vue.component("editable-grid-csv-view", {
	props: {
        id: {
            type: String,
            required: true
        },
        className: String,
        columns: Array,
        csvData: String,
    },
  
    data: function(){
        return {
            localCsvData: this.csvData,
        }  
    },

	template: '<div>\
  			      <i>{{columns.join(", ")}}</i><br>\
                  <textarea\
                  :id="id"\
                  :name="id"\
                  :class="className"\
                  v-model="localCsvData"\
                  style="width: 98%; height: 250px; font-family: Consolas,Monaco,Lucida Console,Courier New, monospace; font-size: 14px;">\
                  </textarea>\
              </div>',
             
    watch: {
        "csvData": function(){this.localCsvData = this.csvData},
        "localCsvData": function(){
            this.$emit("csv-edit", this.localCsvData);
        },
    },
       
});


Vue.component("button-bar", {
	props: {
    	buttons: Array
    },

	template: '<div>\
  			      <button v-for="b in buttons" v-if="b.enabled"\
                  :id="b.id"\
                  v-on:click.prevent="$emit(\'button-click\', b)"\
                  style="font-size:100%">\
                      {{b.label}}\
                  </button>\
                  <button v-else :id="b.id" disabled="disabled"\
                  style="font-size:100%">\
                      {{b.label}}\
                  </button>\
              </div>',
    
});
