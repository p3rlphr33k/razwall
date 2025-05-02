# Password editor 

## Functionality
The password editor component lets the user edit and verify passwords. Password could be validated against length. 

## Usage
`<password-editor>` supports the following custom component attributes:

| attribute | type | description |
| --------|---------|-------|
| `id` | String | This is the id of the password input field. It will also corresponds to the name attribute of the input. |
| `value` | String | Password value (leave it empty, just used to exploit v-model) |
| `columns` | Number *Optional* | Indicates how many columns input parent `field-container` must have. Default is `2`. |
| `min-length` | Number *optional* | Minimum length of the password. Default is `8`. |
| `required` | Boolean *optional* | Whether the password is required or not. Default is `false`. |
| `strings` | Object *optional*| Strings used by the component. |

## Methods

`<password-editor>` supports the following methods:
| methods | description |
| ------|-------|
| `validate()` | return `true` if the password is valid otherwise `false`. |

## Events
`<password-editor>` emits the following custom events:

| event name | description |
| -----------|-------------|
| `valid-password` | Emitted when the password length is grater or equal the minimum value and password confirm matches. |
| `invalid-password` | Emitted when password length is invalid or password confirm does not match. |

## Usage
See `demo.html` file.

