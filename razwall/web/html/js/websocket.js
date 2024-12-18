// WEB SOCKET
if(!window.RazSocket)RazSocket = {};
$_=function(e){if(e){if(typeof e=='string')e=document.getElementById(e);}else{e=document.body;}return e}
RazConnectWS = function(){
  try {
	 // WE NEED IP DYNAMIC!!
    var websockethost = '/ws';
    webSocket = new WebSocket( websockethost );
	$_("socketStatus").className = 'socketYellow';
	console.log('Connecting to the RazWall Socket Server.');
	
	webSocket.onopen = function() {
		$_("socketStatus").className = 'socketGreen';
		RazSocket.playSound('login');
		//$_('loginMessageBox').innerHTML = 'RazWall Socket Connected.';		
	}
	
	// incomimg message processing
	webSocket.onmessage = function( msg ) {
		//console.log('SOCKET DATA DETECTED');
	// create varible from data recieved	
	msgData = msg.data;
	// handle socket data for messages
	
	
	///////// NEW SOCKET CODE FOR RazWall
	if( msgData.match(/::CPU::/) ) {
		//console.log('CPU DATA');
		//if($_('dashboard')) {
			msgData = msgData.replace("::CPU::","");
			cpu=parseFloat(msgData);
			cleanCPU = cpu.toFixed(2);
			if(cpuseries) {
				cpuseries.append(new Date().getTime(), parseFloat(cleanCPU));
			}
		//}
	}
	
	if( msgData.match(/::MEM::/) ) {
		//console.log('MEM DATA');
		//if($_('dashboard')) {
			msgData = msgData.replace("::MEM::","");
			mem=parseFloat(msgData);
			cleanMEM = mem.toFixed(2);
			if(memseries) {
				memseries.append(new Date().getTime(), parseFloat(cleanMEM));
			}
		//}
	}
	
	if( msgData.match(/::TRM::/) ) {
		if($_('termWinData')) {
			msgData = msgData.replace("::TRM::","");
			var newDiv = document.createElement('div');
	
			if( msgData.match(/Command:/) ) {
				var theCmd = msgData.replace("Command: ","");
				var cmdA = document.createElement('a');
				var textCommand = document.createTextNode('Command: ');
				cmdA.setAttribute('href','#');
				cmdA.setAttribute('onclick','$_(\'wt_text\').value=\''+theCmd+'\';return false;');
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
			$_('termWinData').appendChild(newDiv);
			$_('termWinData').scrollTop = $_('termWinData').scrollHeight++;
		}
	}
	
	if( msgData.match(/::NOTIFY::/) ) {
		msgData = msgData.replace("::NOTIFY::","");
		var NCount = $_('systemEventTray').childElementCount;
		var messageid = NCount++;
		$_('eventCount').innerHTML = NCount;
		var newDiv = document.createElement('div');
		newDiv.setAttribute('id','message'+messageid);
		newDiv.setAttribute('style','background:#000;margin:5px;border:1px #696969 solid; padding-top:30px; padding:10px; min-height:50px;');
		newDiv.innerHTML=msgData;
		$_('systemEventTray').appendChild(newDiv);
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
			RazSocket.notify('RazWall New Message.');
		}
	}
}	

// handle closed sockets
webSocket.onclose = function() {
 		$_("socketStatus").className = 'socketRed';
		//RazSocket.logWsChatMessage(botVar,'Server disconnected.','chatbot');
		RazSocket.playSound('error');
		//$_('chatButton').value = 'Connect';
	}
  } catch( exception ) {
		$_("socketStatus").className = 'socketRed';
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
	var thissound=document.getElementById(soundobj);
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
    $_('chatButton' ).value='Disconnect';
    return 1;
  } else {
    $_('chatButton').value='Connect';
    return 0;
  }
}