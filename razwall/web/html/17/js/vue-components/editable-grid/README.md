# Editable grid

## Functionality
The editable grid component lets the user to edit table data and validate the input also through a CSV editor. It uses JQuery DataTables and a customization of jquery-datatables-editable. 

## Usage
`<editable-grid>` supports the following custom component attributes:

| attribute | type | description |
| --------|---------|-------|
| `id` | String | This is the id of the table/csv editor. It will also corresponds to the name attribute of the CSV textarea. |
| `columns` | Object[] | Array of objects containing the grid columns . See below the column format. |
| `data-source` | Object *optional* | Object containing the grid data. See below the data source format. |
| `validator` | Function *optional* | Function for validating the grid input data. Grid data are passed as an array to the function.  See below how to write validators. |
| `options` | Object *optional*| Component custom options. See below the option format. |
| `table-class-name` | String *optional* | table class name |
| `csv-class-name` | String *optional* | CSV editor class name |

### Column
A column supports the following attributes:
| attribute | type | description |
| --------|---------|-------|
| `name` | String | The name of the column. |
| `csvDescription` | String *optional* | Column description shown in the CSV editor (if enabled). |
| `type` | String *optional* | type of the editable field: choose `text` for a text input or `select` for a select box. Default to `text` |
| `options` | String[] *optional* | Array of select box options (if the column has `select` as type). |
| `defaultValue` | String *optional* | When a new row is added the specified value is inserted into the field.  |
| `validator` | Function *optional*| field validator. The (trimmed) value is passed to the function when user edits the field. See below how to write validators. |
| `required` | Boolean *optional | indicates if the field is required and will be checked by calling the function `checkRequiredFields()` |
| `dataTableOptions` | Object *optional* | Object that contains custom DataTable column options.|


### Data source
`<editable-grid>` data source supports the following attributes and sources:
| attribute | type | description |
| --------|---------|-------|
| `arrayData` | Array[ Array[] ] *optional* | Bidimensional array containing table data |
| `csvData` | Array[ Array[] ] *optional* | String containing table data in CSV format (comma separated) |

### Grid options
`<editable-grid>` supports the following options:
| attribute | type | description |
| --------|---------|-------|
| `showCSVEditor` | Boolean *optional* | Allows user to switch to the CSV editor. Default to `true`.|
| `text` | Object | Object containing component strings. |
| `dataTableOptions` | Object *optional* | Object that contains custom DataTable options. |
Default text strings are : `{
					AddRow: "Add row",
					DeleteRow: "Delete row",
					ShowCSV: "Show CSV",
					ShowTable: "Show table",
					ErrorInLine: "Error in line"
				}`
				
### Validators

#### Grid validator
A grid validator takes as parameter a bidimensional array of grid data and returns an array of error objects or an empty array if grid data are successfully validated. 
An error object contain the following attributes:
| attribute | type | description |
| --------|---------|-------|
| `line` | Number | Line number of error. If error has no line it can be set to `null`. |
| `message` | String | Error message. |

#### Field validator
A field validator takes the field value as input parameter and returns an error string or an empty string if the value is correct.

## Events
`<editable-grid>` emits the following events:

| event name | description |
| -----------|-------------|
| `grid-edit` | Emitted when user edits the grid data. It sends grid data as parameter. |
| `grid-validation-error` | Emitted when a validation error occurs. |
| `grid-validation-success` | Emitted when data are successfully validated. |


