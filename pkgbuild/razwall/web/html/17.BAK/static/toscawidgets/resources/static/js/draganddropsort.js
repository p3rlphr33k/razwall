function draganddropsort_getColumnEntries(id, columnNumber){
    var ret = new Array();
    var itemCount = $( "#draganddropsort-"+id
		       +" .draganddropsort-column:eq("+columnNumber
		       +") .draganddropsort-item" ).length;
    
    for(var i = 0; i < itemCount; ++i){
        ret[i] = $( "#draganddropsort-"+id
		    +" .draganddropsort-column:eq("+columnNumber
		    +") .draganddropsort-item:eq("+i
		    +") input[type='hidden']" )[0].value;
    }
    
    return ret;
}

function draganddropsort_postCallBack(id, callBackURL) {
    
    var columnCount = $( "#draganddropsort-"+id+" .draganddropsort-column" ).length;
    var columnEntries = new Array();
    for(var i = 0; i < columnCount; ++i){
        columnEntries[i] = draganddropsort_getColumnEntries(id, i);
    }
    
    var sort = ""
    for(var i = 0; i < columnCount; ++i){
        for(var j = 0; j < columnEntries[i].length; ++j){
            if(sort != "")
              sort += ",";
	    sort += columnEntries[i][j]+"=("+i+","+j+")";
        }
    }

    var postDict = {id:id,sort:sort};
    
    try{
        $.post(callBackURL, postDict);
    }catch(e){
        econsole.debug("DRAGANDDROPSORT Error occured at callback: "+e);
    }  
};
