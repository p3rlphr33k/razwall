# emiRequest
emiRequest module provides EmiREST class and execEmiCommand function.

## EmiREST
The EmiREST class provides a simple interface to Emi REST controllers. It provides the basic methods (get, head, put, post, plus executeAction) supported by the REST controller. It wraps the JQuery.ajax function for executing asynchronous requests.

### Creation

| Cunstructor | Description |
| --------|---------|
| `EmiREST(<String> apiURI, <Object> options)` | Instantiates an EmiREST objects given the REST API URI `apiURI` to which send requests and optionally an object literal with EmiREST options. |

### Options

| option | type | default | description |
| --------|---------|---------|-------|
| `requestContentType` | String | `application/json` | Specify the content type of the HTTP requests. |

### Usage example

```javascript
var myEmiREST = new emiRequest.EmiREST('/manage/snmp/settings/api/', {
    requestContentType: 'application/json'
});
```

### Methods
`EmiREST` supports the following methods:

| Method | Return | Description 
| --------|---------|-------|
| `get(<Object> parameters)` | EmiRequestPromise | Sends an HTTP GET request to the REST controller and returns an EmiRequestPromise. It supports an optional object literal with the request parameters. |
| `head(<Object> parameters)` | EmiRequestPromise | Sends an HTTP HEAD request to the REST controller and returns an EmiRequestPromise. It supports an optional object literal with the request parameters. |
| `put(<Object> parameters)` | EmiRequestPromise | Sends an HTTP PUT request to the REST controller and returns an EmiRequestPromise. It supports an optional object literal with the request parameters. |
| `post(<Object> parameters)` | EmiRequestPromise | Sends an HTTP POST request to the REST controller and returns an EmiRequestPromise. It supports an optional object literal with the request parameters. |
| `execAction(<String> actionName, <Object> data)` | EmiRequestPromise | Executes a REST action (e.g: 'apply') and optionally sends data within the request. |

#### (get, head, put, and post) Parameters

| Parameter | Type | Description |
| --------|---------|-------|
| `resource` | String *optional* | The resource URL, for example the object ID (N.B: it is not neccessary to specify the api path, just put the ID). Default resource is empty/root. | 
| `data` | Object *optional* | Data to send through the body of the HTTP request (e.g: POST requests) | 
| `queryData` | Object *optional* | Data to send through the URL query (e.g: for GET requests) |

#### EmiRequestPromise

| Method | Return | Description |
| --------|---------|-------|
| `then(<Function> callback(<Object> response))` | `this` | If the request is successful then executes the callback. |
| `fail(<Function> callback(<String> errorCode, <String> errorMessage))` | `this` | If the request fails then executes the callback. |
| `always(<Function> callback(<Object> response))` | `this` | Always executes the callback. |

#### Usage example
Get an object with the specified ID: 

```javascript
myEmiREST.get({resource: '12847299992'}).then(function(responseData){
    console.log(responseData);
}).fail(function(code, message){
    console.error('[Error '+code+'] '+message);
});
```

Get all the objects:

```javascript
myEmiREST.get().then(function(responseData){
    console.log(responseData);
}).fail(function(code, message){
    console.error('[Error '+code+'] '+message);
});
```
## execEmiCommand
execEmiCommand is a function that helps executing emi commands.
| Function | Return | Description |
| --------|---------|-------|
| `execEmiCommand(<String> emiCommand, <Object> parameters)` | `EmiRequestPromise` | Executes a given emi command |
### Usage example
```javascript
emiRequest.execEmiCommand('commands.firewall.outgoingfw.getApplications').then(function(responseData){
    console.log(responseData);
}).fail(function(code, message){
    console.error('[Error '+code+'] '+message);
});
```
