function toggleTheme() {
	var sheets = $('csstheme');
    if(sheets.getAttribute('href')=='/css/dark.css') {
		sheets.setAttribute('href', '/css/light.css');
	}
	else {
		sheets.setAttribute('href', '/css/dark.css');
	}
}
function splash(){
	var splash = $('splashScreen');
	splash.style.display='block';
}
function endSplash(){
	var splash = $('splashScreen');
	splash.style.display='none';
}
function restart() {
var confirm = $('userConfirmRestart').value;
if(confirm == 'RESTART') {
	plax.submit('/cgi-bin/core.pl','restart_form','restart_update_form');
	return false;
	}
	
else {
	alert('Restart aborted!\nConfirmation did not match!\n Code is case sensitive!');
	$('userConfirm').value='';
	$('userConfirm').focus;
	return false;	
	}
}
function shutdown() {
var confirm = $('userConfirmShutdown').value;
if(confirm == 'SHUTDOWN') {
	plax.submit('/cgi-bin/core.pl','shutdown_form','shutdown_update_form');
	return false;
	}
else {
	alert('Shutdown aborted!\nConfirmation did not match!\n Code is case sensitive!');
	$('userConfirm').value='';
	return false;
	}	
}
function factory_reset() {
var confirm = $('userConfirmReset').value;
if(confirm == 'RESET') {
	plax.submit('/cgi-bin/core.pl','reset_form','reset_update_form');
	return false;
	}
else {
	alert('Reset aborted!\nConfirmation did not match!\n Code is case sensitive!');
	$('userConfirm').value='';
	return false;
	}	
}
function krbSend() {
	var krbpass = $('krbpass').value;
	//var krbhash = hex_md5(krbpass);
	plax.update('/cgi-bin/core.pl?do=sub&task=krb5test&krb5hash='+krbpass+'&session='+RazSession,'krb5content');
	return false;
}
function chkp1() {
var p1 = $("PASS1");
var p1len = p1.value.length;
if(p1len < 7) {
	//red
	p1.style.backgroundColor = "#CC9999";
	}
else
	{
	//green
	p1.style.backgroundColor = "#99CC99";
	}
}
function chkp2() {
var p1 = $("PASS1");
var p2 = $("PASS2");
var p2len = p2.value.length;
var p1v = p1.value;
var p2v = p2.value;

if((p2len < 7) || (p2v != p1v))
	{
	//red
	p1.style.backgroundColor = "#CC9999";
	p2.style.backgroundColor = "#CC9999";
	}
else
	{
	//green
	p1.style.backgroundColor = "#99CC99";
	p2.style.backgroundColor = "#99CC99";
	}
}
function toggleMask() {
	var opasswd = $('oldPass'); 
	var npasswd = $('newPass'); 
	var npasswd2 = $('newPass2'); 
	var chkbox =$('pwdMask'); 

	if(chkbox.checked==false) { 
		opasswd.setAttribute('type','text'); 
		npasswd.setAttribute('type','text'); 
		npasswd2.setAttribute('type','text'); 
	} 
	else { 
		opasswd.setAttribute('type','password'); 
		npasswd.setAttribute('type','password'); 
		npasswd2.setAttribute('type','password'); 
	} 
}
function validateLogin() {
	uname = $('usernameField').value;
	pword = $('passwordField').value;
	$('passwordField').value = '';
	$('passwordField').disbled=true;
	$('sendIt').disabled=true;
	hash = hex_md5(pword);
	$('md5hash').value = hash;
	
if(uname && hash)
	{
	return true;
	}
else
	{
	$('usernameField').disabled=false;
	$('passwordField').disabled=false;
	$('sendIt').disabled=false;
	$('usernameField').value='';
	$('passwordField').value='';
	$('usernameField').focus;
	return false;
	}
}
function validateUpdate() {
	
	opword = $('oldPass').value;
	npword = $('newPass').value;
	npword2 = $('newPass2').value;
	
	$('oldPass').value = '';
	$('newPass').value = '';
	$('newPass2').value = '';
	
	$('oldPass').disabled=true;
	$('newPass').disabled=true;
	$('newPass2').disabled=true;
	$('sendIt').disabled=true;

	ohash = hex_md5(opword);
	nhash = hex_md5(npword);
	nhash2 = hex_md5(npword2);
	
	$('omd5hash').value = ohash;
	$('nmd5hash').value = nhash;
	$('nmd5hash2').value = nhash2;
	
if(nhash == nhash2) {
	plax.submit('/cgi-bin/core.pl','pass_form','passwd_update_form');
	return false;
	}
else {
	$('oldPass').value = '';
	$('newPass').value = '';
	$('newPass2').value = '';

	$('oldPass').disabled=false;
	$('newPass').disabled=false;
	$('newPass2').disabled=false;
	$('sendIt').disabled=false;

	$('omd5hash').value = '';
	$('nmd5hash').value = '';
	$('nmd5hash2').value = '';
	
	$('omd5hash').disabled=true;
	$('nmd5hash').disabled=true;
	$('nmd5hash2').disabled=true;
	return false;
	}
}
function initjson() {
		//fetchJSON('Language',true);
		fetchJSON('SEARCH',true);
		fetchJSON('System',true);
		fetchJSON('Server',true);
		fetchJSON('Network',true);
		fetchJSON('Users',true);

		fetchJSON('Logs',true);
}
function rebuildMenu(m){
	var loadingImg = document.createElement('img');
	var hardBreak = document.createElement('br');
	var loadingText = document.createTextNode('Building Menu...');
	loadingImg.setAttribute('src', '/images/loading.gif');
	
	$('results').textContent = '';
	$('results').innerHTML = '';
	$('results').innerHTML = 'TEST';
	$('results').appendChild(loadingImg);
	$('results').appendChild(hardBreak);
	$('results').appendChild(loadingText);
	
	//$('results').innerHTML += str;
	//console.log($('results').innerHTML);
	localStorage.removeItem(m+'JSON');
	fetchJSON(m,true);
	subMenu(m);
}
function fetchMembers(g) {
	$('groupMembers').innerHTML = '<option>Loading..</option>';
	var memberList = plax.gets('/cgi-bin/core.pl?do=sub&task=getMembers&groupName='+g+'&session='+RazSession);
	$('groupMembers').innerHTML = memberList;
}


// NEEDED?
var zones = [];
var R;

// Added temporarily to prevent JS errors until chat code is merged:
var enableNotify = 1; // this is usually a chat code user setting.

function showZone(V) {
	R = V;
	console.log(zones);
	for (var i = 0; i < zones.length; i++)
		{
			$(zones[i]).style.display='none';
		}
	$(V).style.display='block';
}

// NEEDED?	
function setZone(Z) {
	console.log(R+'/'+Z);
	window.open('../cgi-bin/setzone.cgi?region='+R+'&zone='+Z,'dataFrame');
}

// AJAX FOR UPLOADS
function doSubmit(){
	var form = $('importForm');
    var fileSelect = $('usersfile');
	var uploadDo = $("uploadDo");
	var uploadTask = $("uploadTask");
    var uploadSession = $("uploadSession");
	var statusDiv = document.getElementById('uploadStatus');
    statusDiv.innerHTML = 'Uploading . . . ';
    var files = fileSelect.files;
    var formData = new FormData();
    var file = files[0]; 

    if (file.size >= 20000000 ) {
		statusDiv.innerHTML = 'You cannot upload this file because its size exceeds the maximum limit of 2 MB.';
        return;
    }

	formData.append('usersfile', file, file.name);
		
	var xhr = new XMLHttpRequest();
	xhr.open('POST', '/cgi-bin/core.pl?session=' + uploadSession.value + '&do=' + uploadDo.value + '&task=' + uploadTask.value, true);        
	xhr.onload = function () {
	if (xhr.readyState == 4 && xhr.status === 200) {
		statusDiv.innerHTML = 'Your upload is successful..';
		$('returnBlock').innerHTML = this.responseText;
        }
	else {
        statusDiv.innerHTML = 'An error occurred during the upload. Try again.';
        }
    };
    xhr.send(formData);
}
// SEARCH BOX FUNCTIONS
function searchKey(V,C) {
	// V = INPUT VALUE
	// C = REPONSE CONTAINER
	
	//dont need this, search is local for speeeeed!
	//plax.update('/cgi-bin/core.pl?do=sub&task=search&session='+RazSession,C);
	
	// here is a test call back that just says what you type:
	//$(C).innerHTML = V;

 var searchJSON = JSON.parse(localStorage.getItem('SEARCHJSON'));
 if(!searchJSON) { 
	console.log('Search data not found in storage, fetching now..');
	fetchJSON('SEARCH'); 
	searchJSON = JSON.parse(localStorage.getItem('SEARCHJSON'));
 }
 
 $('results').textContent = '';
 var searchData = searchJSON.dictionary;
 var searchUL = document.createElement('ul');
 searchUL.setAttribute('rel', 'open');
 searchUL.setAttribute('style', 'display: block;');

 for (i = 0; i < searchData.length; i++) {
	var searchItem = searchData[i].text;
	var regex = new RegExp(V, 'gi');
	var searchMatch = searchItem.match(regex);
	if( V.length >0 && searchMatch ) {
		
		// USER FOR NO HIGHLIGHTS:
		//var LinkText = searchData[i].text;
		
		// USER FOR HIGHLIGHTS:
		var LinkText = searchItem.replace(new RegExp(V, "gi"), (match) => `<b style=\'background:yellow\'>${match}</b>`);
		
		var LinkClick = searchData[i].link;
		var searchLI = document.createElement('li');
		searchLI.setAttribute('onclick', LinkClick);
		searchLI.setAttribute('style', 'cursor:pointer;');
		//var searchText = document.createTextNode(' '+LinkText);
		
		if(searchData[i].icon) { 
			var LinkIcon = searchData[i].icon; 
			var searchIcon = document.createElement('img');
			searchIcon.setAttribute('src',LinkIcon);
			searchIcon.setAttribute('width','16px');
			searchIcon.setAttribute('height','16px');
			searchLI.appendChild(searchIcon);
		}
							
		searchLI.innerHTML = LinkText;
		searchUL.appendChild(searchLI);
		$('results').appendChild(searchUL);
	}
 }
}

// RAZDC USER TABS
function openRazUser(evt, UserName) {
  var i, tabcontent, tablinks;
  tabcontent = document.getElementsByClassName("usertabcontent");
  for (i = 0; i < tabcontent.length; i++) {
    tabcontent[i].style.display = "none";
  }
  tablinks = document.getElementsByClassName("usertablinks");
  for (i = 0; i < tablinks.length; i++) {
    tablinks[i].className = tablinks[i].className.replace(" active", "");
  }
  document.getElementById(UserName).style.display = "block";
  evt.currentTarget.className += " active";
}

// GPO Policy TABS
function openPolicy(evt, PolicyName) {
  var i, tabcontent, tablinks;
  tabcontent = document.getElementsByClassName("policytabcontent");
  for (i = 0; i < tabcontent.length; i++) {
    tabcontent[i].style.display = "none";
  }
  tablinks = document.getElementsByClassName("policytablinks");
  for (i = 0; i < tablinks.length; i++) {
    tablinks[i].className = tablinks[i].className.replace(" active", "");
  }
  document.getElementById(PolicyName).style.display = "block";
  evt.currentTarget.className += " active";
}

// Meeting Tool Tips:
function copyText() {
  var copyText = document.getElementById("myinvite");
  copyText.select();
  copyText.setSelectionRange(0, 99999); /* For mobile devices */
  navigator.clipboard.writeText(copyText.value);
  alert("Copied the text: " + copyText.value);
} 

function clipTip() {
  var tooltip = document.getElementById("myTooltip");
  tooltip.innerHTML = "Copy to clipboard";
}

// WEB SOCKET
if(!window.RazSocket)RazSocket = {};

RazConnectWS = function(){
  try {
	 // WE NEED IP DYNAMIC!!
    var websockethost = 'wss://'+RazIP+'/ws';
    webSocket = new WebSocket( websockethost );
	$("socketStatus").className = 'socketYellow';
	console.log('Connecting to the RazDC Socket Server.');
	
	webSocket.onopen = function() {
		$("socketStatus").className = 'socketGreen';
		RazSocket.playSound('login');
		//$('loginMessageBox').innerHTML = 'RazDC Socket Connected.';		
	}
	
	// incomimg message processing
	webSocket.onmessage = function( msg ) {
		
	// create varible from data recieved	
	msgData = msg.data;
	// handle socket data for messages
	
	
	///////// NEW SOCKET CODE FOR RAZDC
	if( msgData.match(/::CPU::/) ) {
		if($('dashboard')) {
			msgData = msgData.replace("::CPU::","");
			cpu=parseFloat(msgData);
			cleanCPU = cpu.toFixed(2);
			cpuseries.append(new Date().getTime(), parseFloat(cleanCPU));
		}
	}
	
	if( msgData.match(/::MEM::/) ) {
		if($('dashboard')) {
			msgData = msgData.replace("::MEM::","");
			mem=parseFloat(msgData);
			cleanMEM = mem.toFixed(2);
			memseries.append(new Date().getTime(), parseFloat(cleanMEM));
		}
	}
	
	if( msgData.match(/::TRM::/) ) {
		if($('termWinData')) {
			msgData = msgData.replace("::TRM::","");
			var newDiv = document.createElement('div');
	
			if( msgData.match(/Command:/) ) {
				var theCmd = msgData.replace("Command: ","");
				var cmdA = document.createElement('a');
				var textCommand = document.createTextNode('Command: ');
				cmdA.setAttribute('href','#');
				cmdA.setAttribute('onclick','$(\'wt_text\').value=\''+theCmd+'\';return false;');
				cmdA.setAttribute('style','color:lime;');
				cmdA.textContent = theCmd;
				newDiv.appendChild(textCommand);
				newDiv.appendChild(cmdA);
			}
			else {
				newText = document.createTextNode(msgData);
				newDiv.appendChild(newText);
			}
			
			//autoscroll
			$('termWinData').appendChild(newDiv);
			$('termWinData').scrollTop = $('termWinData').scrollHeight++;
		}
	}
	
	if( msgData.match(/::NOTIFY::/) ) {
		msgData = msgData.replace("::NOTIFY::","");
		var NCount = $('systemEventTray').childElementCount;
		var messageid = NCount++;
		$('eventCount').innerHTML = NCount;
		var newDiv = document.createElement('div');
		newDiv.setAttribute('id','message'+messageid);
		newDiv.setAttribute('style','background:#000;margin:5px;border:1px #696969 solid; padding-top:30px; padding:10px; min-height:50px;');
		newDiv.innerHTML=msgData;
		$('systemEventTray').appendChild(newDiv);
		RazSocket.playSound('razbot');
	}
	
	if( msgData.match(/::MSG::/) ) {

		msgData = msgData.replace("::MSG::","");
		msgParts = msgData.split(/::SEP::/);
		userVar = msgParts[0];
		chanVar = msgParts[1];
		msgVar = msgParts[2];

		console.log(userVar,msgVar,chanVar);



		if (! document.hasFocus() ) {
			RazSocket.notify('RazDC New Message.');
		}
	}
}	

// handle closed sockets
webSocket.onclose = function() {
 		$("socketStatus").className = 'socketRed';
		//RazSocket.logWsChatMessage(botVar,'Server disconnected.','chatbot');
		RazSocket.playSound('error');
		//$('chatButton').value = 'Connect';
	}
  } catch( exception ) {
		$("socketStatus").className = 'socketRed';
		//RazSocket.logWsChatMessage(botVar,exception,'chatbot');
		RazSocket.playSound('error');
  }
}

// start update loop
RazSocket.startUserUpdates = function() {
	if(Logged) {
		if( RazSocket.isConnectedWsChat() ) {

			try{
				if(AFK) { sendUserStatus = 1; }
				else { sendUserStatus = 0; }
					webSocket.send( '::USER::' + chatUser + '::' + REMOTEADDR + '::' + sendUserStatus + '::' + currentChannel + '::' + isTyping + '::' + userStrikes);
			} catch( exception ){			
				RazSocket.logWsChatMessage(botVar,exception,'chatbot');
			}
		theTimeout = setTimeout(function(){ RazSocket.startUserUpdates() }, 1000);
		}
	}
}

//remove html tags
RazSocket.removeHTMLTags = function(obj){
	if( obj ){
		var strInputCode = obj;
		/* 
			This line is optional, it replaces escaped brackets with real ones, 
			i.e. &lt; is replaced with < and &gt; is replaced with >
		*/	
		strInputCode = strInputCode.replace(/&(lt|gt);/g, function (strMatch, p1){
			return (p1 == "lt")? "<" : ">";
		});
		var strTagStrippedText = strInputCode.replace(/<\/?[^>]+(>|$)/g, "");
	}
	return strTagStrippedText;
}

// play the sound called by ID
RazSocket.playSound = function(soundobj) {
	var thissound=$(soundobj);
	thissound.play();
}

// notify users if chat is not focused
RazSocket.notify = function(sendUser,newMessage,notifyChannel) {
	//clean messages for desktop notifications
	//sendUser = RazSocket.removeHTMLTags(sendUser);
	newMessage = RazSocket.removeHTMLTags(newMessage);
	
	// Let's check whether notification permissions have already been granted
	if (Notification.permission === "granted" && enableNotify) {
		if(currentChannel == notifyChannel) {
			// If it's okay let's create a notification
			var notification = new Notification(newMessage);
		}
	}
}

// handle socket checks
RazSocket.isConnectedWsChat = function() {
  if( webSocket && webSocket.readyState==1 ) {
    $('chatButton' ).value='Disconnect';
    return 1;
  } else {
    $('chatButton').value='Connect';
    return 0;
  }
}
