if(!window.RazSocket)RazSocket = {};

RazConnectWS = function(){
  try {
    var websockethost = 'wss://192.168.19.177';
	
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
		//console.log(msgData);

		// handle messages regarding socket connections
		//EXAMPLE:
		//if(msgData.match(/::CONNECTIONS::/)) {
		// DO SOMETHING
		//}
		
	// handle socket data for messages
	
	if( msgData.match(/::CPU::/) ) {
		msgData = msgData.replace("::CPU::","");
		cpu=parseFloat(msgData);
		cleanCPU = cpu.toFixed(2);
		cpuseries.append(new Date().getTime(), parseFloat(cleanCPU));
	}
	
	if( msgData.match(/::MEM::/) ) {
		msgData = msgData.replace("::MEM::","");
		mem=parseFloat(msgData);
		cleanMEM = mem.toFixed(2);
		memseries.append(new Date().getTime(), parseFloat(cleanMEM));
	}
	//FUTURE JSON OVER WS:
	if( msgData.match(/::USERS::/) ) {
		msgData = msgData.replace("::USERS::","");
		console.log('User JSON: ' + msgData);
		ADUsers = JSON.parse(msgData);
		localStorage.setItem("USERSJSON",JSON.stringify(ADUsers));
		console.log('Users JSON retrieved from server.');
	}
	
	if( msgData.match(/::MSG::/) ) {

		msgData = msgData.replace("::MSG::","");
		msgParts = msgData.split(/::SEP::/);
		userVar = msgParts[0];
		chanVar = msgParts[1];
		msgVar = msgParts[2];

// MESSAGE PARSING HAPPENS HERE


		if (! document.hasFocus() ) {
			RazSocket.notify(userVar,msgVar,currentChannel);
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