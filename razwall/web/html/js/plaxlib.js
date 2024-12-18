/*
PLAX Javascript Library
Written by Bryan Donarski
Website: http://supervene.com/

PLAX javascript library originated from the miniajax script found here: https://github.com/seven1m/mini
I added many changes to improve performance and add functionality.
PLAX is a javascript library built to make ajax requests to perl/CGI scripts and returning the results while handling embedded javascript.
PLAX library is a great alternative to jquery for small offline projects
You can find source and documentation here: http://sourceforge.net/p/plax
*/

if(!window.plax)plax={};
$=function(e){if(e){if(typeof e=='string')e=document.getElementById(e);}else{e=document.body;}return e}
$t=function(e,t){if(typeof t=='string')r=[];if(!e){e=document}else{e=$(e);};if(!t)t='*';var r=e.getElementsByTagName(t);return r}
$c=function(c){var r=[];mc=new RegExp('\\b'+c+'\\b');e=$t('','*');for(i=0;i<e.length;i++){cs=e[i].className;if(mc.test(cs))r.push(e[i]);}return r}
$.id=function(i){return $(i)};
$.class=function(c){return $t(c)};
$.tag=function(t){return $t(t)};
$.listen=function(E,f){return plax.listen(E,f)};
plax.x=function(){try{return new ActiveXObject('Msxml2.XMLHTTP')}catch(e){try{return new ActiveXObject('Microsoft.XMLHTTP')}catch(e){return new XMLHttpRequest()}}};
plax.serialize=function(data){theForm=$(data) || document.data || document.getElementsByTagName('form')[0];var retVal='';var els=$t(theForm,'');for(var idx=0;idx<els.length;idx++){var el=els[idx];if(!el.disabled && el.name && el.name.length>0){switch(el.tagName.toLowerCase()){case 'input':switch(el.type){case 'checkbox':case 'radio':if(el.checked){if(retVal.length>0){retVal+='&';}retVal+=el.name+'='+encodeURIComponent(el.value);}break;case 'hidden':case 'password':case 'text':if(retVal.length>0){retVal+='&';}retVal+=el.name+'='+encodeURIComponent(el.value);break;}break;case 'select':case 'textarea':if(retVal.length>0){retVal+='&';}retVal+=el.name+'='+encodeURIComponent(el.value);break;}}}return retVal;}
plax.noCache=function(u){u=u+(u.indexOf('?')<0?'?':'&')+'nocache='+new Date().getTime();return u}
plax.send=function(u,f,m,a){var x=plax.x();x.open(m,u,true);x.onreadystatechange=function(){if(x.readyState==4)eval(f)((x.responseText))};if(m=='POST')x.setRequestHeader('Content-type','application/x-www-form-urlencoded');x.setRequestHeader("Pragma", "no-cache");x.setRequestHeader("Cache-Control", "must-revalidate");x.setRequestHeader("Cache-Control", "no-cache");x.setRequestHeader("Cache-Control", "no-store");x.setRequestHeader("If-Modified-Since", "Sat, 1 Jan 2005 00:00:00 GMT");x.send(a)};
plax.get=function(url,func){plax.send(url,func,'GET')};
plax.gets=function(url){url=plax.noCache(url);var x=plax.x();x.open('GET',url,false);x.setRequestHeader('Content-type','application/x-www-form-urlencoded');x.setRequestHeader("Pragma", "no-cache");x.setRequestHeader("Cache-Control", "must-revalidate");x.setRequestHeader("Cache-Control", "no-cache");x.setRequestHeader("Cache-Control", "no-store");x.setRequestHeader("If-Modified-Since", "Sat, 1 Jan 2005 00:00:00 GMT");x.send(null);return x.responseText};
plax.sync=function(url){url=plax.noCache(url);var x=plax.x();x.open('GET',url,false);x.setRequestHeader('Content-type','application/x-www-form-urlencoded');x.setRequestHeader("Pragma", "no-cache");x.setRequestHeader("Cache-Control", "must-revalidate");x.setRequestHeader("Cache-Control", "no-cache");x.setRequestHeader("Cache-Control", "no-store");x.setRequestHeader("If-Modified-Since", "Sat, 1 Jan 2005 00:00:00 GMT");x.send(null);return x.responseText};
plax.asyn=function(url){url=plax.noCache(url);var x=plax.x();x.open('GET',url,true);x.setRequestHeader('Content-type','application/x-www-form-urlencoded');x.setRequestHeader("Pragma", "no-cache");x.setRequestHeader("Cache-Control", "must-revalidate");x.setRequestHeader("Cache-Control", "no-cache");x.setRequestHeader("Cache-Control", "no-store");x.setRequestHeader("If-Modified-Since", "Sat, 1 Jan 2005 00:00:00 GMT");x.onload=function(e){if (x.readyState === 4) {if(x.status===200){return x.responseText;}else{console.error(x.statusText);}}};x.onerror=function(e){console.error(xhr.statusText);};x.send(null);};
plax.post=function(url,func,args){plax.send(url,func,'POST',args)};
plax.add=function(url,elm,frm){var e=$(elm);var f=function(r){if(r==1){return false;}else{alert('failed to send, please retry.')}};plax.post(url,f,frm)};
plax.hideshow=function(id){e=$(id);e.style.display=((e.style.display=="none")?"block":"none")};
plax.handleInputFieldKeyPress=function(event,f){if(event.keyCode==13&&!event.shiftKey){eval(f);return false};return true};
plax.update=function(url,elm){var e=$(elm);var f=function(r){e.innerHTML=r;plax.script($(elm))};plax.get(url,f)};
plax.append=function(url,elm){var e=$(elm);var f=function(r){e.innerHTML=e.innerHTML+r;plax.script($(elm))};plax.get(url,f)};
plax.submit=function(url,elm,frm){var e=$(elm);var f=function(r){e.innerHTML=r;plax.script($(elm))};plax.post(url,f,plax.serialize(frm))};
plax.submitAdd=function(url,elm,frm){var e=$(elm);var f=function(r){e.innerHTML += r;plax.script($(elm))};plax.post(url,f,plax.serialize(frm))};
plax.starttimer=function(f,s){return setInterval(f,s)};
plax.cleartimer=function(e){return clearInterval(e);}
plax.timeout=function(f,s){return setTimeout(f,s)};
plax.cleartimeout=function(e){return clearTimeout(e)};
plax.getCookie=function(c_n){var j=document.cookie;if(j.length>0){var c_s=j.indexOf(c_n+"=");if(c_s!=-1){c_s=c_s + c_n.length+1;c_e=j.indexOf(";",c_s);if(c_e==-1){c_e=j.length;}return unescape(j.substring(c_s,c_e));}}return "";}
plax.setCookie=function(c_name,value,exdays){var exdate=new Date();exdate.setDate(exdate.getDate() + exdays);var c_value=escape(value) + ((exdays==null) ? "" : "; expires="+exdate.toUTCString());document.cookie=c_name + "=" + c_value;}
plax.checkCookie = function(c_n){var j=document.cookie;var plaxCookie=plax.getCookie(c_n);if(plaxCookie.length>0){return 1;}else{return 0;}}
plax.clearCookie = function(c_n){document.cookie = encodeURIComponent(c_n) + "=deleted; expires=" + new Date(0).toUTCString();}
plax.xssjs=function(u){try{var djs=$('djs');if(djs!=null)djs.parentNode.removeChild(djs);var fileref = document.createElement('script');fileref.id = "djs";fileref.setAttribute("type","text/javascript");fileref.setAttribute("src",u);if(typeof fileref !='undefined'){document.getElementsByTagName('head')[0].appendChild(fileref);return;}}catch(err){}}
plax.fadeIn = function(objId,toOp,fromOp){obj=$(objId);if(toOp>fromOp){plax.setOpacity(obj,fromOp);fromOp+=11;window.setTimeout("plax.fadeIn('"+objId+"',"+toOp+","+fromOp+")",10);}}
plax.fadeOut = function(objId,toOp,fromOp){obj=$(objId);if(toOp<fromOp){plax.setOpacity(obj,fromOp);fromOp-=11;window.setTimeout("plax.fadeOut('"+objId+"',"+toOp+","+fromOp+")",10);}}
plax.setOpacity = function(objId,opacity){obj=$(objId);opacity=(opacity==100)?99.999:opacity;obj.style.filter="alpha(opacity:"+opacity+")";obj.style.KHTMLOpacity=opacity/100;obj.style.MozOpacity=opacity/100;obj.style.opacity=opacity/100;}
plax.create=function(e){return document.createElement(e);}
plax.remove=function(e){while($(e)){$(e).parentNode.removeChild($(e))};}
plax.hideModal=function(divID){$(divID).style.display = "none";plax.remove(divID);}
plax.linker=function(tg,typ,src){var csc=document.createElement('script');csc.type='text/javascript';csc.src=src;document.getElementsByTagName('head').item(0).appendChild(csc);}
plax.script=function(t){var sc=t.getElementsByTagName('script');if(sc.length>0){for(var i=0;i<sc.length;i++){eval(sc.item(i).innerHTML);if(sc.item(i).src)plax.linker('script','text/javascript',sc.item(i).src);};};}
plax.html=function(elm,h){var e=$(elm);e.innerHTML=h;};
plax.now=function(d){return new Date().getTime();};
plax.loader=function(f,t){var handle=null;function show(){if(handle !== null){clearTimeout(handle);}handle = setTimeout(f,t);}return{show: show,clear:function(){clearTimeout(handle);handle=null;}};}
plax.listen=function(E,f){return $().addEventListener(E,f);};
plax.mousemove=function(f){$().onMouseMove=eval(f);};


//Need to add multipart form functions for file uploads using ajax:

//URL,STATUS ELEMENT(DIV),FORM,FILE SELECT ELEMENT

/* CONVERTED TO PLAXLIB (UNTESTED)

plax.upload=function(url,elem,form,file,limit,func){
	var form=$(form);
    var fileSelect=$(file);
	var statusDiv=$(elem);
	statusDiv.innerHTML = 'Uploading . . . ';
	var files = fileSelect.files;
    var formData = new FormData();
    var file = files[0]; 
    if (file.size>=limit){ statusDiv.innerHTML = 'File size exceeds limit of '+limit+'.'; return; }
        formData.append('usersfile', file, file.name);
        var xhr = new XMLHttpRequest();
        xhr.open('POST', url, true);

        xhr.onload = function () {
          if (xhr.readyState == 4 && xhr.status === 200) {
            statusDiv.innerHTML = 'Your upload is successful..';
			statusDiv.innerHTML = this.responseText;
          } else {
            statusDiv.innerHTML = 'An error occurred during the upload. Try again.';
          }
        };
        xhr.send(formData);
};

*/

/* ORIGINAL:
function doSubmit(){
	// These variables are used to store the form data
	var form = $('importForm');
    var fileSelect = $('usersfile');
	var uploadDo = $("uploadDo");
	var uploadTask = $("uploadTask");
    var uploadSession = $("uploadSession");
	var statusDiv = document.getElementById('uploadStatus');

        statusDiv.innerHTML = 'Uploading . . . ';

        // Get the files from the input
        var files = fileSelect.files;

        // Create a FormData object.
        var formData = new FormData();

        //Grab only one file since this script disallows multiple file uploads.
        var file = files[0]; 

        if (file.size >= 2000000 ) {
            statusDiv.innerHTML = 'You cannot upload this file because its size exceeds the maximum limit of 2 MB.';
            return;
        }

        // Add the file to the AJAX request.
		//formData.append('do', uploadDo.value);
		//formData.append('task', uploadTask.value);
		//formData.append('session', uploadSession.value);
        formData.append('usersfile', file, file.name);
		
        // Set up the request.
        var xhr = new XMLHttpRequest();

        // Open the connection.
        xhr.open('POST', '/cgi-bin/core.pl?session=' + uploadSession.value + '&do=' + uploadDo.value + '&task=' + uploadTask.value, true);

        // Set up a handler for when the task for the request is complete.
        xhr.onload = function () {
          if (xhr.readyState == 4 && xhr.status === 200) {
            statusDiv.innerHTML = 'Your upload is successful..';
			$("importUsersBlock").innerHTML = this.responseText;
          } else {
            statusDiv.innerHTML = 'An error occurred during the upload. Try again.';
          }
        };

        // Send the data.
        xhr.send(formData);
}
*/