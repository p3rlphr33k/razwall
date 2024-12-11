# RazDC Templates
# Modified: 12-07-2020
#
# This is the core HTML Template file. It contains all HTML templates for different windows called in RazDC
# This will consolidate all original HTML files into one script so authentication can be verified with each request
#
######################################################################################################################
# NOTHING
#####################################
$template{'nothing'} = qq|
Nothing here yet.
|;

# Header
#####################################
$template{'header'} = qq|
<!DOCTYPE html>
<html lang="en-us">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>[!PAGETITLE!]</title>
 <link href="/css/global.css" rel="stylesheet" type="text/css">
 <link href="/css/search.css" rel="stylesheet" type="text/css">
 <link href="/css/dark.css" rel="stylesheet" type="text/css" id="csstheme">
 <link href="/css/simpletree.css" rel="stylesheet" type="text/css">
 <link rel="stylesheet" type="text/css" href="/css/smoothie.css"/>
 <script language="javascript" src="/js/simpletreemenu.js"></script>
 <script language="javascript" src="/js/drag.js"></script>
 <script language="javascript" src="/js/win.js"></script>
 <script language="javascript" src="/js/plaxlib.js"></script>
 <script language="javascript" src="/js/md5.js"></script>
 <script language="javascript" src="/js/cookie.js"></script>
 <script language="javascript" src="/js/jsonhandle.js"></script>
 <script language="javascript" src="/js/blocks.js"></script>
 <script language="javascript" src="/js/calls.js"></script>
 <script language="javascript" src="/js/smoothie.js"></script>
</head>
 <body>
 <span id="dummy" style="display:none;height:0px;width:0px;">
  <audio id="incoming" src="/sounds/sound_1.mp3" preload="true" autobuffer></audio>
  <audio id="outgoing" src="/sounds/sound_2.mp3" preload="true" autobuffer></audio>
  <audio id="login" src="/sounds/sound_3.mp3" preload="true" autobuffer></audio>
  <audio id="logout" src="/sounds/sound_4.mp3" preload="true" autobuffer></audio>
  <audio id="razbot" src="/sounds/sound_5.mp3" preload="true" autobuffer></audio>
  <audio id="error" src="/sounds/sound_6.mp3" preload="true" autobuffer></audio>
 </span> 
<div id="headContainer">
	<div style="float:left;"><div id="socketStatus" class="socketYellow" onClick="RazConnectWS(); return false;"></div></div>
	<div id="logoframe">
		<img src="/images/RazDC.png">
	</div>
	<div style="float:right;" id="notifytab">
		<div class="tab field-tip floatr" id="notify" onclick="notifyMenu(); return false;"><img src="/images/notify.png" alt="Notifications"><span class="tip-below">Notifications</span></div>
				<div id="eventCount" style="z-index:10;float:right;position:absolute;top:3px;right:3px;width:15px;height:15px;background:red;border:3px red solid;font-size:10px;font-weight:bold;color:#FFFFFF;border-radius: 50%;">0</div>
	</div>
</div>
|;
# Loading Window Content
#####################################
$template{'loading'} = qq~
<br><center><img src="/images/loading.gif" height="50px"><br>Loading...</center>
~;
# Not Ready Yet - TABLE TO DIV WIP
#####################################
$template{'not_ready'} = qq~
 <div id="tabframe">
 	<div id="menutabs">
	 		<div class="tab field-tip" id="exit" onclick="eraseCookie('RazDC-Session-Key'); window.open('/index.html','_Top');"><img src="/images/exit.png" alt="Exit"><span class="tip-content">Log off</span></div>
 	</div>
	</div>
 </div>
 
 <div id="dataframe">
	<div id="indicator"></div>
 </div>

 <div id="notifyframe" class="barColor">
 </div>
 
<div id="dragableSetup" class="drsElement" style="opacity: 0.99; box-shadow: rgba(0, 0, 0, 0.6) 0px 10px 40px 3px, rgb(89, 89, 89) 0px -1px 0px; border: 1px solid rgb(105, 105, 105); width: 700px; height: 500px; position: absolute; top: 212px; left: 297px; z-index: 3;">

<table width="100%" height="100%" cellspacing="0px" cellpadding="0px" border="0px">
	<tbody>
		<tr>
			<td class="drsMoveHandle barColor" style="background-position: -46.7px -72.7px;">
				<b class="windowtitle">Setup RazDC</b>
			</td>
		</tr>
		<tr>
		<td valign="top" align="left">
			<div id="setupContent" style="border:0px;margin:0px;padding:0px;position:absolute;top:33px;left:0px;right:0px;bottom:0px;overflow:auto;">
			<table width="100%" border="0" cellpadding="20px" cellspacing="0">
			<tr>
				<td>
					<h3>It looks like this is your first time logging in.</h3>
					<h3>Lets setup a few things..</h3>
					<hr>
					<p>1. <button style="width:400px;" onclick="win('','Change Password','/cgi-bin/core.pl?do=sub&amp;task=administrator&amp;session=[!SESSION!]','600','300',false);">Change Password</button></p>
					<p>2. <button style="width:400px;" onclick="win('','Time &amp; Region','/cgi-bin/core.pl?do=sub&amp;task=getRegions&amp;session=[!SESSION!]','500','350',false);">Time &amp; Region</button></p>
					<p>3. <button style="width:400px;" onclick="win('','Network Setup','/cgi-bin/core.pl?do=sub&amp;task=fullnet&amp;session=[!SESSION!]','600','450',false);">Setup Network</button></p>
					<p>4. <button style="width:400px;" onclick="win('','Restart RazDC','/cgi-bin/core.pl?do=sub&amp;task=restart&amp;session=YWRtaW46ODFkYzliZGI1MmQwNGRjMjAwMzZkYmQ4MzEzZWQwNTU6','400','200',false);">Reboot</button></p>
				</td>
			</tr>
			</table>
			</form>
			</div>
		</td>
	</tr>
	</tbody>
</table>
<div class="dragresize dragresize-tl" style="visibility: inherit;"></div>
<div class="dragresize dragresize-tm" style="visibility: inherit;"></div>
<div class="dragresize dragresize-tr" style="visibility: inherit;"></div>
<div class="dragresize dragresize-ml" style="visibility: inherit;"></div>
<div class="dragresize dragresize-mr" style="visibility: inherit;"></div>
<div class="dragresize dragresize-bl" style="visibility: inherit;"></div>
<div class="dragresize dragresize-bm" style="visibility: inherit;"></div>
<div class="dragresize dragresize-br" style="visibility: inherit;"></div>
</div>
</body> 
</html>
~;
# Provision Head
#####################################
$template{'provision_head'} = qq~
<div class="winBlock" style="border:0px #000 solid;color:#000;padding:5px;margin:10px;height:400px;overflow:scroll;">
~;
# Provision Foot
#####################################
$template{'provision_foot'} = qq~
</div>
~;
# Provision 
#####################################
$template{'provision'} = qq~
<div class="blockSection">
		<div class="inline left">
			[!MESSAGE!]
		</div>
	</div>
</table>
~;
# Setup Window Info
#####################################
$template{'setup_data'} = qq~
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			<h2>&emsp;Welcome to RazDC!<h2>
			<h3>&emsp;Before you begin we have to ask, what would you like to do?</h3>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
			&emsp;<input type="button" style="width:150px;height:150px;" value="New Domain" onClick="plax.update('/cgi-bin/core.pl?do=sub&task=newdc&session=[!SESSION!]','setupContent'); return false;">
			&emsp;<input type="button" style="width:150px;height:150px;" value="Join Domain" onClick="plax.update('/cgi-bin/core.pl?do=sub&task=olddc&session=[!SESSION!]','setupContent'); return false;"><br>
			&emsp;<input type="button" style="width:150px;height:150px;" value="Restore" onClick="plax.update('/cgi-bin/core.pl?do=sub&task=restoredc&session=[!SESSION!]','setupContent'); return false;" disabled>
			&emsp;<input type="button" style="width:150px;height:150px;" value="Takeover" onClick="plax.update('/cgi-bin/core.pl?do=sub&rask=takeoverdc&session=[!SESSION!]','setupContent'); return false;" disabled>
		</div>
	</div>
</div>
~;
# Setup
#####################################
$template{'setup'} = qq~
 <div id="tabframe">
 	<div id="menutabs">
	 		<div class="tab field-tip" id="exit" onclick="eraseCookie('RazDC-Session-Key'); window.open('/index.html','_Top');"><img src="/images/exit.png" alt="Exit"><span class="tip-content">Log off</span></div>	
 	</div>
	</div>
 </div>
 <div id="menuframe">
 	<div class="box">
 		<div class="container">
 			<input type="search" id="search" placeholder="Search..." onkeyup="searchKey(this.value,'results');" autocomplete="off">
 		</div>
 	</div>
 	<div id="results">
	Test Result
	</div>
 </div>
 <div id="dataframe">
	 <div id="indicator"></div>
</div>
 <div id="dashboard"></div>
<div id="dragableSetup" class="drsElement" style="opacity: 0.99; box-shadow: rgba(0, 0, 0, 0.6) 0px 10px 40px 3px, rgb(89, 89, 89) 0px -1px 0px; border: 1px solid rgb(105, 105, 105); width: 700px; height: 550px; position: absolute; top: 212px; left: 297px; z-index: 3;">

<table width="100%" height="100%" cellspacing="0px" cellpadding="0px" border="0px">
	<tbody>
		<tr>
			<td class="drsMoveHandle barColor" style="background-position: -46.7px -72.7px;">
				<b class="windowtitle">Let's Get Setup</b>
			</td>
		</tr>
		<tr>
		<td valign="top" align="left">
			<div id="setupContent" style="border:0px;margin:0px;padding:0px;position:absolute;top:33px;left:0px;right:0px;bottom:0px;overflow:auto;">
			
			<!-- START SETUP DATA -->
			
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			<h2>&emsp;Welcome to RazDC!<h2>
			<h3>&emsp;Before you begin we have to ask, what would you like to do?</h3>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
			&emsp;<input type="button" style="width:150px;height:150px;" value="New Domain" onClick="plax.update('/cgi-bin/core.pl?do=sub&task=newdc&session=[!SESSION!]','setupContent'); return false;">
			&emsp;<input type="button" style="width:150px;height:150px;" value="Join Domain" onClick="plax.update('/cgi-bin/core.pl?do=sub&task=olddc&session=[!SESSION!]','setupContent'); return false;"><br>
			&emsp;<input type="button" style="width:150px;height:150px;" value="Restore" onclick="plax.update('/cgi-bin/core.pl?do=sub&task=restoredc&session=[!SESSION!]','setupContent'); return false;" disabled>
			&emsp;<input type="button" style="width:150px;height:150px;" value="Takeover" onclick="plax.update('/cgi-bin/core.pl?do=sub&task=takeoverdc&session=[!SESSION!]','setupContent'); return false;" disabled>
		</div>
	</div>
</div>

			<!-- END SETUP DATA-->
			
			</div>
		</td>
	</tr>
	</tbody>
</table>
<div class="dragresize dragresize-tl" style="visibility: inherit;"></div>
<div class="dragresize dragresize-tm" style="visibility: inherit;"></div>
<div class="dragresize dragresize-tr" style="visibility: inherit;"></div>
<div class="dragresize dragresize-ml" style="visibility: inherit;"></div>
<div class="dragresize dragresize-mr" style="visibility: inherit;"></div>
<div class="dragresize dragresize-bl" style="visibility: inherit;"></div>
<div class="dragresize dragresize-bm" style="visibility: inherit;"></div>
<div class="dragresize dragresize-br" style="visibility: inherit;"></div>
</div>
</body> 
</html>
~;

# Provision Preview
#####################################
$template{'preview'} = qq~
<div id="provisonBlock">
<form action="/cgi-bin/core.pl" id="provisionForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','provisionForm','provisionBlock'); return false;">
<table width="100%" border="0" cellpadding="0" cellspacing="0">
<tr>
     	<td align="left" colspan="2">
			<img src="/images/left.png" id="setupBack" onClick="plax.update('/cgi-bin/core.pl?do=sub&task=setup_back&session=[!SESSION!]','setupContent');">
		</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr>
        <td align="right">Server Hostname:&emsp;</td>
        <td align="left">[!HOST!]</td>
</tr>
<tr>
	<td align="right">Server FQDN:&emsp;</td>
	<td align="left">[!FQDN!]</td>
</tr>
<tr>
	<td align="right">Realm Name:&emsp;</td>
	<td align="left">[!DOMAIN!]</td>
</tr>
<tr>
	<td align="right">Domain:&emsp;</td>
	<td align="left">[!REALM!]</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr>
	<td align="right">IP Address:&emsp;</td>
	<td align="left">[!IPADDR!]</td>
</tr>
<tr>
	<td align="right">Subnet Mask:&emsp;</td>
	<td align="left">[!NETMASK!]</td>
</tr>
<tr>
	<td align="right">Gateway Address:&emsp;</td>
	<td align="left">[!GATEWAY!]</td>
</tr>
<tr>
	<td align="right">Name Server:&emsp;</td>
	<td align="left">[!NAMESERVERS!]</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
~;

# Provision New DC
#####################################
$template{'newdc'} = qq~
<tr>
	<td align="right">Create a new realm:&emsp;</td>
	<td align="left">&emsp;<b>[!DOMAIN!]</b></td>
</tr>
<tr>
	<td align="right">Create the new realm in domain:&emsp;</td>
	<td align="left">&emsp;<b>[!REALM!]</b></td>
</tr>
<tr>
	<td align="right">Server Role:&emsp;</td>
	<td align="left">&emsp;<b>Domain Controller (DC)</b></td>
</tr>
<tr>
		<td align="right">DNS Backed Type:&emsp;</td>
		<td align="left">&emsp;<select name="backend">
			<option value="BIND9_DLZ">Bind 9 DLZ</option>
			<option value="SAMBA_INTERNAL">Samba Internal</option>
			<option value="BIND9_FLATFILE">Bind Flatfile</option>
			<option value="NONE">None</option>
		</select>
		</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr>
	<td align="center" colspan="2">
		<input type="hidden" name="do" value="sub">
		<input type="hidden" name="task" value="provision">
		<input type="hidden" name="role" value="dc">
		<input type="hidden" name="type" value="newdc">
		<input type="hidden" name="session" value="[!SESSION!]">
		<input type="button" value="Provision: [!REALM!]" onClick="this.disabled='disabled'; plax.update('/cgi-bin/core.pl?do=sub&task=loading&session=[!SESSION!]','loadProvision'); plax.submit('/cgi-bin/core.pl','provisionForm','provisionBlock'); return false;">
	</td>
</tr>
<tr>
	<td colspan="2">
	<div id="loadProvision"></div>
	</td>
</tr>
</table>
</form>
</div>
~;

# Provision Secondary DC
#####################################
$template{'olddc'} = qq~
<tr>
    	<td align="right">Create secondary DC for:&emsp;</td>
        <td align="left">&emsp;<b>[!DOMAIN!]</b></td>
</tr>
<tr>
		<td align="right">DNS Backend Type:&emsp;</td>
		<td align="left">&emsp;<select name="backend">
			<option value="BIND9_DLZ" selected>Bind 9 DLZ</option>
			<option value="SAMBA_INTERNAL">Samba Internal</option>
			<option value="BIND9_FLATFILE">Bind Flatfile</option>
			<option value="NONE">None</option>
		</select>
		</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr>
    	<td align="right">Primary Domain Controller IP:&emsp;</td>
        <td align="left">&emsp;<input type="text" name="PDCIP" value=""></td>
</tr>
<tr>
    	<td align="right">[!REALM!] Password:&emsp;</td>
        <td align="left">&emsp;<input type="password" name="PASS1"></td>
</tr>
<tr>
    	<td align="right">Confirm [!DOMAIN!] Password:&emsp;</td>
        <td align="left">&emsp;<input type="password" name="PASS2"></td>
</tr>

<tr><td colspan="2">&nbsp;</td></tr>

<tr>
    	<td align="center" colspan="2">
			<input type="hidden" name="do" value="sub">
			<input type="hidden" name="task" value="provision">
			<input type="hidden" name="role" value="dc">
			<input type="hidden" name="type" value="olddc">
			<input type="hidden" name="session" value="[!SESSION!]">
			<input type="button" value="Setup Secondary DC for [!REALM!]" onClick="this.disabled='disabled'; plax.update('/cgi-bin/core.pl?do=sub&task=loading&session=[!SESSION!]','loadProvision'); plax.submit('/cgi-bin/core.pl','provisionForm','provisionBlock'); return false;">
		</td>
</tr>
<tr>
	<td colspan="2">
	<div id="loadProvision"></div>
	</td>
</tr>
</table>
</form>
</div>
~;
# Index
#####################################
$template{'loggedIn'} = qq~
 <div id="tabframe">
 	<div id="menutabs"></div>
 </div>
 
 <div id="menuframe">
 	<div class="box">
 		<div class="container">
 			<input type="search" id="search" placeholder="Search..." onkeyup="searchKey(this.value,'results');" autocomplete="off">
 		</div>
 	</div>
 	<div id="results"></div>
 </div>
 
 <div id="dataframe">
	 <div id="indicator"></div>
 </div>
 
 <div id="consoleframe">
	<div class="barColor" id="consoleBar">
		<div id="consoleHS" onclick="consoleView();"></div>
	</div>
	<div id="consoleData"></div>
 </div>
 
 <div id="notifyframe" class="barColor">
	<button onclick="\$('systemEventTray').innerHTML='';\$('eventCount').innerHTML='0';return false;">Clear Notifications</button>
	<div id="systemEventTray" style="overflow-x:none;overflow-y: auto;width: 100%;height: 100%;">
	
	</div>
 </div>
 
 <div id="dashboard">
	<div id="centerPins"></div>
 </div>
 
 <div id="splashScreen"><img src="/images/loading.gif" id="loadImg"></div>
 
 <script language="JavaScript" type="text/javascript">
 	if (console.everything === undefined) {
		
		console.everything = [];
		var now = new Date()
		//var date = now.toLocaleDateString();
		var time = now.toLocaleTimeString();
	
		console.defaultLog = console.log.bind(console);
		console.log = function(){
			//console.everything.push({"type":"log", "datetime":Date().toLocaleString(), "value":Array.from(arguments)});
			//console.defaultLog.apply(console, arguments);	
			consMsg = document.createTextNode(time + '  Log: ' + Array.from(arguments));
			var myP = document.createElement('p');
			myP.appendChild(consMsg);
			\$('consoleData').appendChild(myP);
			\$('consoleData').scrollTop = \$('consoleData').scrollHeight;
		}
		console.defaultError = console.error.bind(console);
		console.error = function(){
			//console.everything.push({"type":"error", "datetime":Date().toLocaleString(), "value":Array.from(arguments)});
			//console.defaultError.apply(console, arguments);
			consMsg = document.createTextNode(time + '  Error: ' + Array.from(arguments));
			var myP = document.createElement('p');
			myP.appendChild(consMsg);
			\$('consoleData').appendChild(myP);
			\$('consoleData').scrollTop = \$('consoleData').scrollHeight;
		}
		console.defaultWarn = console.warn.bind(console);
		console.warn = function(){
			//console.everything.push({"type":"warn", "datetime":Date().toLocaleString(), "value":Array.from(arguments)});
			//console.defaultWarn.apply(console, arguments);
			consMsg = document.createTextNode(time + '  Warning: ' + Array.from(arguments));
			var myP = document.createElement('p');
			myP.appendChild(consMsg);
			\$('consoleData').appendChild(myP);
			\$('consoleData').scrollTop = \$('consoleData').scrollHeight;
		}
		console.defaultDebug = console.debug.bind(console);
		console.debug = function(){
			//console.everything.push({"type":"debug", "datetime":Date().toLocaleString(), "value":Array.from(arguments)});
			//console.defaultDebug.apply(console, arguments);
			consMsg = document.createTextNode(time + '  Debug: ' + Array.from(arguments));
			var myP = document.createElement('p');
			myP.appendChild(consMsg);
			\$('consoleData').appendChild(myP);
			\$('consoleData').scrollTop = \$('consoleData').scrollHeight;
		}
	}
	var consoleTrue = 1;
	function consoleView(){
		if(consoleTrue) {
			\$('consoleData').style.display='block';
			consoleTrue = 0;
		}
		else {
			\$('consoleData').style.display='none';
			consoleTrue = 1;
		}
	}
	
	var cpuchart = new SmoothieChart({
			tooltip:true,
			timestampFormatter:SmoothieChart.timeFormatter,
			millisPerPixel:54,
			maxValueScale:1.01,
			grid:{borderVisible:false},
			labels:{fontSize:19},
			tooltip:true,
			maxValue:100,
			minValue:0
		});
	var cpuseries = new TimeSeries();
	var memchart = new SmoothieChart({
			tooltip:true,
			timestampFormatter:SmoothieChart.timeFormatter,
			millisPerPixel:54,
			maxValueScale:1.01,
			grid:{borderVisible:false},
			labels:{fontSize:19},
			tooltip:true,
			maxValue:100,
			minValue:0
		});
	var memseries = new TimeSeries();
	var RazSession = readCookie('[!RAZCOOKIE!]');
	var RazIP = '[!RAZIP!]';
 	splash();
	fetchJSON('CONFIG',false);
	fetchJSON('DASH',false);
	fetchJSON('MENU',false);
</script>
<script language="javascript" src="/js/tabs.js"></script>
 <script language="JavaScript" type="text/javascript"> 
	RazSetup();
	window.onresize = function(){ setupBlocks(window.innerWidth); }
	initjson();
	var eventCounter = document.getElementById("systemEventTray").childElementCount;
	\$('eventCount').innerHTML = eventCounter;

 </script>

</body>
</html>
~;


# Edit PC form
######################################
$template{'editPC'} = qq~
<div id="editPCBlock">
<br>
<form action="/cgi-bin/core.pl" id="editUserForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','editPCForm','editPCBlock'); return false;">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<img src="/images/[!PCIMG!]" height="120px">
		</div>
	</div>
</div>

<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Machine Name" name="Unixusername" value="[!UNIXUSERNAME!]" disabled>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Description" name="Accountdesc" value="[!ACCOUNTDESC!]" size="40">
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			User SID:
		</div>
		<div class="inline right">
			<b>[!ACCTUSERSID!]</b>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
			Primary Group SID:
		</div>
		<div class="inline right">
			<b>[!ACCTGROUPSID!]</b>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
			Logon time:
		</div>
		<div class="inline right">
			<b>[!ACCTLOGONTIME!]</b>
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			Logon Hours:
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Logon Hours" name="acctLogonHours" value="[!ACCTLOGONHOURS!]" size="40" disabled="disabled">
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="checkbox" name="userDisabled" [!ACCTDISABLED!]> Computer Disabled
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="checkbox" name="ACCTTRUST" [!ACCTTRUST!]> Workstation Trust Account
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="button" value="Save Computer" onclick="splash(); plax.submit('/cgi-bin/core.pl','editPCForm','editPCBlock'); return false;">
			<input type="button" value="Delete Computer" onclick="plax.update('/cgi-bin/core.pl?do=sub&task=deletePC&Unixusername=[!UNIXUSERNAME!]&session=[!SESSION!]','editPCBlock'); return false;">
		</div>
	</div>
</div>
<input type="hidden" id="Unixusername" name="Unixusername" value="[!UNIXUSERNAME!]">
<input type="hidden" id="do" name="do" value="sub">
<input type="hidden" id="task" name="task" value="savePC">
<input type="hidden" id="session" name="session" value="[!SESSION!]">
</form>
</div>
~;
# Delete PC
#####################################
$template{'deletePC'} = qq~
<form action="/cgi-bin/core.pl" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','deletePCForm','editPCBlock'); return false;" name="deletePCForm" id="deletePCForm">
	<div class="winBlock">
		<div class="winSection">
			<h2>Type 'DELETE' to remove computer: [!UNIXUSERNAME!]</h2>
		</div>
	
		<div class="winSection">
			<input type="text" name="pcConfirmDelete" id="pcConfirmDelete" value="">
		</div>

		<div class="winSection">
			<input type="hidden" id="Unixusername" name="Unixusername" value="[!UNIXUSERNAME!]">
			<input type="hidden" id="do" name="do" value="sub">
			<input type="hidden" id="task" name="task" value="deletePCConfirm">
			<input type="hidden" id="session" name="session" value="[!SESSION!]">
			<input type="button" style="margin:2px;" id="sendIt" value="Delete Computer" onclick="plax.submit('/cgi-bin/core.pl','deletePCForm','editPCBlock'); return false;">
		</div>
	</div>
</form>
~;

# Edit PC form
######################################
$template{'editDC'} = qq~
<div id="editPCBlock">
<br>
<h3>-THIS IS A DOMAIN CONTROLLER-</h3>
<h3>DO NOT EDIT UNLESS YOU KNOW WHAT YOU ARE DOING!</h3>
<br>
<form action="/cgi-bin/core.pl" id="editUserForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','editPCForm','editPCBlock'); return false;">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Machine Name" name="Unixusername" value="[!UNIXUSERNAME!]" disabled>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Description" name="Accountdesc" value="[!ACCOUNTDESC!]" size="40">
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			User SID:
		</div>
		<div class="inline right">
			<b>[!ACCTUSERSID!]</b>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
			Primary Group SID:
		</div>
		<div class="inline right">
			<b>[!ACCTGROUPSID!]</b>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
			Logon time:
		</div>
		<div class="inline right">
			<b>[!ACCTLOGONTIME!]</b>
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			Logon Hours:
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Logon Hours" name="acctLogonHours" value="[!ACCTLOGONHOURS!]" size="40" disabled="disabled">
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="checkbox" name="userDisabled" [!ACCTDISABLED!]> Computer Disabled
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="checkbox" name="ACCTTRUST" [!ACCTTRUST!]> Workstation Trust Account
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="button" value="Save Computer" onclick="splash(); plax.submit('/cgi-bin/core.pl','editPCForm','editPCBlock'); return false;">
			<input type="button" value="Delete Server" onclick="plax.update('/cgi-bin/core.pl?do=sub&task=deleteDC&Unixusername=[!UNIXUSERNAME!]&session=[!SESSION!]','editPCBlock'); return false;">
		</div>
	</div>
</div>
<input type="hidden" id="Unixusername" name="Unixusername" value="[!UNIXUSERNAME!]">
<input type="hidden" id="do" name="do" value="sub">
<input type="hidden" id="task" name="task" value="savePC">
<input type="hidden" id="session" name="session" value="[!SESSION!]">
</form>
</div>
~;
# Delete PC
#####################################
$template{'deleteDC'} = qq~
<form action="/cgi-bin/core.pl" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','editDCBlock','deleteDCForm'); return false;" name="deleteDCForm" id="deleteDCForm">
	<div class="winBlock">
		<div class="winSection">
			<h2>Type 'DELETE' to remove server: [!UNIXUSERNAME!]</h2>
		</div>
	
		<div class="winSection">
			<input type="text" name="dcConfirmDelete" id="dcConfirmDelete" value="">
		</div>

		<div class="winSection">
			<input type="hidden" id="Unixusername" name="Unixusername" value="[!UNIXUSERNAME!]">
			<input type="hidden" id="do" name="do" value="sub">
			<input type="hidden" id="task" name="task" value="deleteDCConfirm">
			<input type="hidden" id="session" name="session" value="[!SESSION!]">
			<input type="button" style="margin:2px;" id="sendIt" value="Delete Server" onclick="plax.submit('/cgi-bin/core.pl','editDCBlock','deleteDCForm'); return false;">
		</div>
	</div>
</form>
~;
# New user form
######################################
$template{'newUser'} = qq~
<form action="/cgi-bin/core.pl" id="newUserForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','newUserForm','newUserBlock'); return false;">
<div id="newUserBlock">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Username" name="Unixusername" value="">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Full Name" name="FullName" value="" size="40">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Home Drive Letter (H:)" name="HomeDirDrive" value="">&nbsp;
			<input type="text" placeholder="Home Directory" name="HomeDirectory" value="">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Logon Script" name="LogonScript" value="">&nbsp;
			<input type="text" placeholder="Profile Path" name="ProfilePath" value="">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Description" name="Accountdesc" value="" size="40">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input placeholder="Password" type="password" name="password" value="">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input placeholder="Confirm Password" type="password" name="password2" value="">
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="checkbox" name="Disabled"> Disable Account
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="checkbox" name="noExpire"> Account never expires
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="button" value="Add User" onclick="plax.submit('/cgi-bin/core.pl','newUserForm','newUserBlock'); return false;">
		</div>
	</div>
</div>
<input type="hidden" id="do" name="do" value="sub">
<input type="hidden" id="task" name="task" value="createUser">
<input type="hidden" id="session" name="session" value="[!SESSION!]">
</div>
</form>
~;
# Create User
######################################
$template{'createUser'} = qq~
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			[!MESSAGE!]
		</div>
	</div>
</div>
~;
# Edit user form
######################################
$template{'editUser'} = qq~
<div id="editUserBlock">
<form action="/cgi-bin/core.pl" id="editUserForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','editUserForm','editUserBlock'); return false;">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Username" name="Unixusername" value="[!UNIXUSERNAME!]" disabled>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Full Name" name="FullName" value="[!FULLNAME!]" size="40">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Home Drive Letter (H:)" name="HomeDirDrive" value="[!HOMEDIRDRIVE!]">&nbsp;
			<input type="text" placeholder="Home Directory" name="HomeDirectory" value="[!HOMEDIRECTORY!]">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Logon Script" name="LogonScript" value="[!LOGINSCRIPT!]">&nbsp;
			<input type="text" placeholder="Profile Path" name="ProfilePath" value="[!PROFILEPATH!]">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="text" placeholder="Description" name="Accountdesc" value="[!ACCOUNTDESC!]" size="40">
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="checkbox" name="userDisabled" [!ACCTDISABLED!]> Disable Account
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input type="checkbox" name="noExpire" [!NOEXPIRE!]> Account never expires
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="button" value="Save User" onclick="this.disabled='true';this.value='Saving..';plax.submit('/cgi-bin/core.pl','editUserForm','editUserBlock'); return false;">
			<input type="button" value="Groups" onclick="win('','[!UNIXUSERNAME!] Groups','/cgi-bin/core.pl?do=sub&task=editGroup&Unixusername=[!UNIXUSERNAME!]&session=[!SESSION!]','640','500',''); return false;">
			<input type="button" value="Reset Password" onclick="this.disabled='true';plax.update('/cgi-bin/core.pl?do=sub&task=userPasswd&Unixusername=[!UNIXUSERNAME!]&session=[!SESSION!]','editUserBlock'); return false;">
			<input type="button" value="Delete User" onclick="this.disabled='true';plax.update('/cgi-bin/core.pl?do=sub&task=deleteUser&Unixusername=[!UNIXUSERNAME!]&session=[!SESSION!]','editUserBlock'); return false;">
		</div>
	</div>
</div>
<input type="hidden" id="Unixusername" name="Unixusername" value="[!UNIXUSERNAME!]">
<input type="hidden" id="do" name="do" value="sub">
<input type="hidden" id="task" name="task" value="saveUser">
<input type="hidden" id="session" name="session" value="[!SESSION!]">
</form>
</div>
~;
# Delete User
#####################################
$template{'deleteUser'} = qq~
<form action="/cgi-bin/core.pl" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','deleteUserForm','editUserBlock'); return false;" name="deleteUserForm" id="deleteUserForm">
	<div class="winBlock">
		<div class="winSection">
			<h2>Type 'DELETE' to remove user: [!UNIXUSERNAME!]</h2>
		</div>
	
		<div class="winSection">
			<input type="text" name="userConfirmDelete" id="userConfirmDelete" value="">
		</div>

		<div class="winSection">
			<input type="hidden" id="Unixusername" name="Unixusername" value="[!UNIXUSERNAME!]">
			<input type="hidden" id="do" name="do" value="sub">
			<input type="hidden" id="task" name="task" value="deleteUserConfirm">
			<input type="hidden" id="session" name="session" value="[!SESSION!]">
			<input type="button" style="margin:2px;" id="sendIt" value="Delete User" onclick="plax.submit('/cgi-bin/core.pl','deleteUserForm','editUserBlock'); return false;">
		</div>
	</div>
</form>
~;
# Change Password
#####################################
$template{'userPassword'} = qq~
<form action="/cgi-bin/core.pl" id="userPassForm" name="userPassForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','userPassForm','editUserBlock'); return false;">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<h2>Reset Password for: [!UNIXUSERNAME!]</h2>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input placeholder="New Password" type="password" name="userpassword" value="">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline right">
			<input placeholder="Confirm Password" type="password" name="userpassword2" value="">
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="button" value="Reset Password" onclick="this.disabled='true';plax.submit('/cgi-bin/core.pl','userPassForm','editUserBlock'); return false;">
		</div>
	</div>
</div>
<input type="hidden" id="Unixusername" name="Unixusername" value="[!UNIXUSERNAME!]">
<input type="hidden" id="do" name="do" value="sub">
<input type="hidden" id="task" name="task" value="setUserPass">
<input type="hidden" id="session" name="session" value="[!SESSION!]">
</form>
~;
# User Groups
######################################
$template{'userGroups'} = qq~
<div id="userGroupsBlock">
<form action="/cgi-bin/core.pl" id="userGroupsForm" name="userGroupsForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','userGroupsForm','userGroupsBlock'); return false;">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<h2>[!UNIXUSERNAME!] Groups</h2>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
		Member of:<br>
		<select name="usersGroup" id="usersGroup" size="10">
		[!USERGROUPS!]
		</select>
		</div>
		<div class="inline left">
		Available:<br>
		<select name="allGroups" id="allGroups" size="10">
		[!ALLGROUPS!]
		</select>
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="button" value="<< Add" onclick="this.disabled='true';this.value='Working..';\$('GroupType').value='add'; plax.submit('/cgi-bin/core.pl','userGroupsForm','userGroupsBlock'); return false;">
			<input type="button" value="Remove >>" onclick="this.disabled='true';this.value='Working..';\$('GroupType').value='remove'; plax.submit('/cgi-bin/core.pl','userGroupsForm','userGroupsBlock'); return false;">
		</div>
	</div>
</div>
<input type="hidden" id="Unixusername" name="Unixusername" value="[!UNIXUSERNAME!]">
<input type="hidden" id="GroupType" name="GroupType" value="">
<input type="hidden" id="do" name="do" value="sub">
<input type="hidden" id="task" name="task" value="saveUserGroups">
<input type="hidden" id="session" name="session" value="[!SESSION!]">
</form>
</div>
~;
# Manage Groups
######################################
$template{'groups'} = qq~
<form action="/cgi-bin/core.pl" id="groupForm" name="groupForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','userPassForm','editUserBlock'); return false;">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<h2>Manage Groups</h2>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
		Groups<br>
		<select name="userGroups" id="userGroups" size="10" onchange="javascript:fetchMembers(this.options[this.selectedIndex].value); return false;">
		[!ALLGROUPS!]
		</select>	
		</div>
		<div class="inline left">
		Members<br>
		<select name="groupMembers" id="groupMembers" size="10" width="200px" disabled>
		<option>No Selection</option>
		</select>
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="button" value="New Group" onclick="win('','Create Group','/cgi-bin/core.pl?do=sub&task=addGroup&session=[!SESSION!]','400','300',''); return false;">
			<input type="button" value="Delete Group" onclick="var GRP=\$('userGroups').options[\$('userGroups').selectedIndex].value;GRP=GRP.replace(/(\\r\\n|\\n|\\r)/gm,'');win('','Delete Group','/cgi-bin/core.pl?do=sub&task=delGroupConfirm&delGroup='+GRP+'&session=[!SESSION!]','400','300',''); return false;">
		</div>
	</div>
</div>
<input type="hidden" id="do" name="do" value="sub">
<input type="hidden" id="task" name="task" value="setUserPass">
<input type="hidden" id="session" name="session" value="[!SESSION!]">
</form>
~;
# Add Group
######################################
$template{'addGroup'} = qq~
<div id="addGroupBlock">
<form action="/cgi-bin/core.pl" id="addGroupForm" name="addGroupForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','addGroupForm','addGroupBlock'); return false;">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<h2>Add Group</h2>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
		New Group Name:<br>
		<input type="text" id="newGroup" name="newGroup" value="" placeholder="New Group Name">		</select>	
		</div>
	</div>
</div>
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<input type="button" value="Create Group" onclick="this.value='Loading..';this.disabled=true;plax.submit('/cgi-bin/core.pl','addGroupForm','addGroupBlock'); return false;">
		</div>
	</div>
</div>
<input type="hidden" id="do" name="do" value="sub">
<input type="hidden" id="task" name="task" value="saveGroup">
<input type="hidden" id="session" name="session" value="[!SESSION!]">
</form>
</div>
~;

# Add Group
######################################
$template{'deleteGroup'} = qq~
<div id="delGroupBlock">
<form action="/cgi-bin/core.pl" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','delGroupForm','delGroupBlock'); return false;" name="delGroupForm" id="delGroupForm">
	<div class="winBlock">
		<div class="winSection">
			<h2>Type 'DELETE' to remove group:<br>'[!DELGROUP!]'</h2>
		</div>
	
		<div class="winSection">
			<input type="text" name="delConfirm" id="delConfirm" value="">
		</div>

		<div class="winSection">
			<input type="hidden" id="delGroup" name="delGroup" value="[!DELGROUP!]">
			<input type="hidden" id="do" name="do" value="sub">
			<input type="hidden" id="task" name="task" value="delGroup">
			<input type="hidden" id="session" name="session" value="[!SESSION!]">
			<input type="button" style="margin:2px;" id="sendIt" value="Delete Group" onclick="this.value='Loading..';this.disabled=true;plax.submit('/cgi-bin/core.pl','delGroupForm','delGroupBlock'); return false;">
		</div>
	</div>
</form>
</div>
~;

# Import users form
######################################
$template{'importUsers'} = qq~
<div id="returnBlock">
<form action="/cgi-bin/core.pl" id="importForm" name="importForm" method="post" enctype="multipart/form-data" onsubmit="plax.submit('/cgi-bin/core.pl','importForm','returnBlock'); return false;">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			Select CSV: <input type="file" placeholder="users_cvs.txt" accept=".csv" name="usersfile" id="usersfile" value="">
			<input type="button" value="Import Users" onclick="doSubmit()">
		</div>
	</div>
	<div class="blockSection">
		<div id="uploadStatus" class="inline right">
		
		</div>
	</div>
</div>
<input type="hidden" id="uploadDo" name="do" value="sub">
<input type="hidden" id="uploadTask" name="task" value="completeImport">
<input type="hidden" id="returnBlock" name="returnBlock" value="importUsersBlock">
<input type="hidden" id="uploadSession" name="session" value="[!SESSION!]">
</form>
<hr>
[!IMPORTFILES!]
</div>
~;
# File List Template
######################################
$template{'fileItem'} = qq~
<div class="winBlock" width="100%">
	<div class="blockSection">
		<div class="inline left">[!FILENAME!]</div>
		<div class="inline right small">
			<button onClick="window.open('/cgi-bin/core.pl?do=save&filename=[!FILENAME!]&session=[!SESSION!]&ref=export','Download'); return false;">Download <img src="/images/download_16.png"></button>
		</div>
		<div class="inline right small">
			<form name="[!FORMID!]" id="[!FORMID!]" action="/cgi-bin/core.pl" method="post">
			<button onClick="plax.submit('/cgi-bin/core.pl','exportBlock','[!FORMID!]'); return false;">Delete <img src="/images/close_16.png"></button>
			<input type="hidden" id="[!FORMID!]Do" name="do" value="sub">
			<input type="hidden" id="[!FORMID!]Task" name="task" value="delfile">
			<input type="hidden" id="[!FORMID!]Callback" name="callback" value="export">
			<input type="hidden" id="[!FORMID!]Filename" name="filename" value="[!FILENAME!]">
			<input type="hidden" id="[!FORMID!]Session" name="session" value="[!SESSION!]">
			</form>
		</div>
	</div>
</div>
~;
# Backup List Template
######################################
$template{'backupItem'} = qq~
<div class="winBlock" width="100%">
	<div class="blockSection">
		<div class="inline left">[!FILENAME!]</div>
		<div class="inline right small">
			<button onClick="window.open('/cgi-bin/core.pl?do=savebackup&filename=[!FILENAME!]&session=[!SESSION!]&ref=backup','Download'); return false;">Download <img src="/images/download_16.png"></button>
		</div>
		<div class="inline right small">
			<form name="[!FORMID!]" id="[!FORMID!]" action="/cgi-bin/core.pl" method="post">
			<button onClick="plax.submit('/cgi-bin/core.pl','backupBlock','[!FORMID!]'); return false;">Delete <img src="/images/close_16.png"></button>
			<input type="hidden" id="[!FORMID!]Do" name="do" value="sub">
			<input type="hidden" id="[!FORMID!]Task" name="task" value="delbackup">
			<input type="hidden" id="[!FORMID!]Callback" name="callback" value="backup">
			<input type="hidden" id="[!FORMID!]Filename" name="filename" value="[!FILENAME!]">
			<input type="hidden" id="[!FORMID!]Session" name="session" value="[!SESSION!]">
			</form>
		</div>
	</div>
</div>
~;
# Backup List Template
######################################
$template{'restoreItem'} = qq~
<div class="winBlock" width="100%">
	<div class="blockSection">
		<div class="inline left">[!FILENAME!]</div>
		<div class="inline right small">
			<form name="[!FORMID!]" id="[!FORMID!]" action="/cgi-bin/core.pl" method="post">
			<button onClick="plax.submit('/cgi-bin/core.pl','backupBlock','[!FORMID!]'); return false;">Restore <img src="/images/import_16.png"></button>
			<input type="hidden" id="[!FORMID!]Do" name="do" value="sub">
			<input type="hidden" id="[!FORMID!]Task" name="task" value="restore">
			<input type="hidden" id="[!FORMID!]Callback" name="callback" value="backup">
			<input type="hidden" id="[!FORMID!]Filename" name="filename" value="[!FILENAME!]">
			<input type="hidden" id="[!FORMID!]Session" name="session" value="[!SESSION!]">
			</form>
		</div>
	</div>
</div>
~;
# Export List Template
######################################
$template{'importItem'} = qq~
<div class="winBlock" width="100%">
	<div class="blockSection">
		<div class="inline left">[!FILENAME!]</div>
		<div class="inline right small">
			<form name="[!FORMID!]" id="[!FORMID!]" action="/cgi-bin/core.pl" method="post">
			<button onClick="plax.submit('/cgi-bin/core.pl','importUsersBlock','[!FORMID!]'); return false;">Import Users <img src="/images/import_16.png"></button>
			<input type="hidden" id="[!FORMID!]Do" name="do" value="sub">
			<input type="hidden" id="[!FORMID!]Task" name="task" value="import">
			<input type="hidden" id="[!FORMID!]Callback" name="callback" value="importUsers">
			<input type="hidden" id="[!FORMID!]Filename" name="filename" value="[!FILENAME!]">
			<input type="hidden" id="[!FORMID!]Session" name="session" value="[!SESSION!]">
			</form>
		</div>
		<div class="inline right small">
			<form name="[!FORMID!]Delete" id="[!FORMID!]Delete" action="/cgi-bin/core.pl" method="post">
			<button onClick="plax.submit('/cgi-bin/core.pl','importUsersBlock','[!FORMID!]Delete'); return false;">Delete <img src="/images/close_16.png"></button>
			<input type="hidden" id="[!FORMID!]Do" name="do" value="sub">
			<input type="hidden" id="[!FORMID!]Task" name="task" value="delfile">
			<input type="hidden" id="[!FORMID!]Callback" name="callback" value="importUsers">
			<input type="hidden" id="[!FORMID!]Filename" name="filename" value="[!FILENAME!]">
			<input type="hidden" id="[!FORMID!]Session" name="session" value="[!SESSION!]">
			</form>
		</div>
	</div>
</div>
~;
# Export users
######################################
$template{'export'} = qq~
<div id="exportBlock">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<form action="/cgi-bin/core.pl" id="exportUsersForm" name="exportUsersForm" method="post">
			<input type="button" value="Export Users" onclick="plax.submit('/cgi-bin/core.pl','exportBlock','exportUsersForm'); return false;">
			<input type="hidden" id="do" name="do" value="sub">
			<input type="hidden" id="exportTask" name="task" value="exportUsers">
			<input type="hidden" id="session" name="session" value="[!SESSION!]">
			</form>
		</div>
	</div>
</div>
[!USERLIST!]
<hr>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline right">
			<form action="/cgi-bin/core.pl" id="exportPCsForm" name="exportPCsForm" method="post">
			<input type="button" value="Export Computers" onclick="plax.submit('/cgi-bin/core.pl','exportBlock','exportPCsForm'); return false;">
			<input type="hidden" id="do" name="do" value="sub">
			<input type="hidden" id="exportTask" name="task" value="exportPCs">
			<input type="hidden" id="session" name="session" value="[!SESSION!]">
			</form>
		</div>
	</div>
</div>
[!PCLIST!]
</div>
~;
# SSL List Item
######################################
$template{'sslitem'} = qq~
 <div class="tr [!EVENODD!]" id="[!SSLID!]">
	<div class="td winSection inline left" onclick="plax.submit('/cgi-bin/core.pl?do=sub&task=usecert&file=[!SSLFILE!]&filekey=[!SSLKEY!]&session=[!SESSION!]','ssllistBlock',''); var t=\$('[!SSLID!]'); return false;"><img src="/images/[!SSLSTATUS!].png" alt="[!SSLSTATUS!]"></div>
	<div class="td winSection inline left">[!SSLNAME!]</div>
	<div class="td winSection inline left">[!SSLEND!]</div>
	<div class="td winSection inline left"><input type="button" onClick="win('','Certificate Details','/cgi-bin/core.pl?do=sub&task=ssldetails&cert=[!SSLCERT!]&session=[!SESSION!]','750','580',''); return false;" value="Details"></div>
	<div class="td winSection inline left"><input type="button" value="Delete" onClick="plax.get('/cgi-bin/core.pl?do=sub&task=ssldel&delfile=[!SSLFILE!]&filekey=[!SSLKEY!]&session=[!SESSION!]',''); var t=\$('[!SSLID!]'); t.remove(); return false;" [!SSLDEL!]></div>
 </div>
~;
# CSR List Item
######################################
$template{'csritem'} = qq~
 <div class="tr [!EVENODD!]" id="[!CSRID!]">
	<div class="td winSection inline left">[!SSLNAME!]</div>
	<div class="td winSection inline left"><input type="button" onClick="win('','Complete Request','/cgi-bin/core.pl?do=sub&task=csrcomplete&csrfile=[!CSRFILE!]&session=[!SESSION!]','750','580',''); return false;" value="Complete"></div>
	<div class="td winSection inline left"><input type="button" value="Delete" onClick="plax.get('/cgi-bin/core.pl?do=sub&task=csrdel&delfile=[!SSLFILE!]&session=[!SESSION!]',''); var t=\$('[!CSRID!]'); t.remove();  return false;" [!SSLCSR!]></div>
 </div>
~;
# SSL Main List
######################################
$template{'ssllist'} = qq~
<div id="ssllistBlock">
[!MESSAGE!]
<div class="table">
 <div class="tr">
 	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -34.6px -141px;">Active</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -34.6px -141px;">Name</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -34.6px -141px;">Expires</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -34.6px -141px;">More</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -34.6px -141px;">Delete</div>
 </div>

 [!SSLLIST!]

</div>
<div class="table">
 <div class="tr">
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -34.6px -141px;">CSR Request</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -34.6px -141px;">Complete</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -34.6px -141px;">Delete</div>
 </div>

 [!SSLCSR!]

</div>
</div>
~;
# SSL Details
######################################
$template{'ssldetails'} = qq~
<div class="table">
 <div class="tr">
	<div class="td winSection inline left">Certificate Name:</div>
	<div class="td winSection inline left"><b>[!SSLNAME!]</b></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Certificate Start:</div>
	<div class="td winSection inline left"><b>[!SSLSTART!]</b></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Certificate End:</div>
	<div class="td winSection inline left"><b>[!SSLEND!]</b></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Serial Number:</div>
	<div class="td winSection inline left"><b>[!SERIAL!]</b></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Common Name:</div>
	<div class="td winSection inline left"><b>[!SSLCN!]</b></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Organization:</div>
	<div class="td winSection inline left"><b>[!SSLO!]</b></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">City:</div>
	<div class="td winSection inline left"><b>[!SSLL!]</b></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">State:</div>
	<div class="td winSection inline left"><b>[!SSLST!]</b></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Country:</div>
	<div class="td winSection inline left"><b>[!SSLC!]</b></div>
 </div>
</div>
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			Public Key:<br>
			<textarea cols="65" rows="13">[!SSLKEY!]</textarea>
		</div>
	</div>
</div>
~;
# SSL NEW
######################################
$template{'sslnew'} = qq~
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			<h2>&emsp;What type of certificate?</h2>
		</div>
		<div class="inline left">
			<small><a href="#" onclick="win('','SSL Help','/cgi-bin/core.pl?do=sub&task=sslhelp&session=[!SESSION!]','500',500,''); return false;">[Help me choose]</a></small>
		</div>
	</div>
</div>

<div class="table">
 <div class="tr">
	<div class="td winSection inline left"><input type="button" value="Self-Signed Certificate" onClick="win('','Self-Signed Cert','/cgi-bin/core.pl?do=sub&task=selfsigned&session=[!SESSION!]','500',500,''); return false;"></div>
	<div class="td winSection inline left"><input type="button" value="Signed Certificate Request" onClick="win('','Certificate Request','/cgi-bin/core.pl?do=sub&task=signedrequest&session=[!SESSION!]','500','500',''); return false;"></div>
 </div>
</div>
~;
# SSL SELF-SIGNED
######################################
$template{'sslselfsigned'} = qq~
<div id="sscertBlock">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			<h3>&emsp;Enter Self-Signed Certificate Info:</h3>
		</div>
	</div>
</div>
<form name="sscertForm" id="sscertForm">
<div class="table">
 <div class="tr">
	<div class="td winSection inline left">Certificate Name:</div>
	<div class="td winSection inline left"><input type="text" name="SSLNAME" value="" placeholder="CertificateName"><small>(No Spaces)</small></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Common Name:</div>
	<div class="td winSection inline left"><input type="text" name="SSLCN" value="" placeholder="DC01"></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Organization:</div>
	<div class="td winSection inline left"><input type="text" name="SSLO" value="" placeholder="Supervene LLC"></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">City:</div>
	<div class="td winSection inline left"><input type="text" name="SSLL" value="" placeholder="Reynolds"></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">State:</div>
	<div class="td winSection inline left"><input type="text" name="SSLST" value="" placeholder="ND"></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Country:</div>
	<div class="td winSection inline left"><input type="text" name="SSLC" value="" placeholder="US" maxlength="2"><small>(Only two Letters e.g. 'US')</small></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">
	<input type="hidden" name="do" value="sub">
	<input type="hidden" name="task" value="sscertcreate">
	<input type="hidden" name="session" value="[!SESSION!]">
	</div>
	<div class="td winSection inline left"><input type="button" value="Create Certificate" onClick="plax.submit('/cgi-bin/core.pl','sscertBlock','sscertForm'); this.disabled=true; this.value='Working..'; return false;"></div>
 </div>
</div>
</form>
</div>
~;
# SSL COMPLETE SELF-SIGNED
######################################
$template{'sscertcomplete'} = qq~
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			<h3>&emsp;Self-Signed Certificate Complete</h3>
		</div>
	</div>
</div>

<div class="table">
 <div class="tr">
	<div class="td winSection inline left">Certificate Name:</div>
	<div class="td winSection inline left"><b>[!SSLNAME!]</b></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left"></div>
	<div class="td winSection inline left"></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left"><input type="button" value="View Details" onClick="win('','Certificate Details','/cgi-bin/core.pl?do=sub&task=ssldetails&cert=[!SSLCERT!]&session=[!SESSION!]','750','580',''); return false;"></div>
	<div class="td winSection inline left"><input type="button" value="Manage SSL" onclick="win('','Manage Certificates','/cgi-bin/core.pl?do=sub&task=ssllist&session=[!SESSION!]','600','400',''); return false;"></div>
 </div>
</div>
~;
# SSL HELP
######################################
$template{'sslhelp'} = qq~
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			<h3>&emsp;About Certificates</h3>
			<p>For all intents and purposes, there are two types of SSL Certificates when you're talking about signing. There are Self-Signed SSL Certificates and certificates that are signed by a Trusted Certificate Authority (CA).<br><br>While both offer encryption, they are not equal.<br><br>Trusted CA's are trusted for a reason, as the name implies the browser community trusts them and they are allowed to issue SSL certificates to websites that display the standard trust indicators and avoid those pesky warnings. Self-Signed certificates don't receive those same benefits, despite offering basic encryption.By the end of this article, you'll see why it's better to go with a Trusted CA Signed SSL Certificate over a Self-Signed one.</p>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
			<h4>&emsp;Self-Signed Certificates VS CA Certificates</h4>
			<p>A self-signed SSL Certificate is an SSL Certificate that is issued by the RazDC server. It's issued with software packaged inside RazDC. This can be good for testing and private environments but it's got some major drawbacks, we'll get to those in a bit, but essentially what you need to know is that when a browser receives an SSL Certificate it's looking for it to be issued by a party it trusts. When you sign your own certificate you're essentially vouching for your own identity. After all, that's one of the biggest aspects of SSL authentication.<br><br>Self-signing a certificate is the same thing as handing a self-made driver's license to a police officer that's pulling you over. It might have your real identifying information on it, but the officer isn't going to just take your word for it. He needs to see identification that's been verified by a trusted third party, in this case, a DMV. Likewise, the browsers need to see an SSL certificate that's been verified by a trusted third party, in this case, a Certificate Authority or CA for short.<br><br>And that's what a Trusted CA Signed SSL Certificate (CA Certificate) is, it's an SSL Certificate that's been authenticated by one of the trusted Certificate Authorities that are authorized to issue them. These CA's are trusted by the browsers for a reason, they meet all the requirements that have been set for issuing SSL Certificates and they have safeguards in place to mitigate mis-issuances and other sorts of fraudulent behavior. The browsers trust the CA's, and if they've issued your RazDC an SSL Certificate, by extension the browsers trust you.<br><br>There are a number of reasons you shouldn't use a Self Signed SSL Certificate outside of a testing or private environment. For starters, as we just touched on, the browsers that individuals use to surf the Internet do not trust self-signed SSL certificates. This is the whole point of authentication; a trusted third party is going to vet you or your organization to verify your identity. Without verification you will receive browser warnings that say a secure connection has failed. <i>"This certificate is not trusted because it is self-signed."</i><br><br>On the other hand, using a Trusted CA Signed SSL Certificate is going to garner no browser warnings, rather the browser will display all the visual indicators that come with a working SSL Certificate. That means you will see the padlock and either a green HTTPS or a green address bar with your organization's name in it. These all indicate that your RazDC and domain is safe, verified, and will give you peace of mind to continue doing business. The downside of the trusted CA Certificate is that require purchase from a trusted CA, and they require additional steps to setup. This is where the Certificate Signing Request or CSR comes in.</p>
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
			<h4>&emsp;Signed Certificate Requests</h4>
			<p>Generating a signed certificate request is only the first stage of validating your RazDC web portal. Once you have the certificate request, you have to copy the key and submit it to a CA for signing. Usually payment is required before processing. A verified certificate is issued in the form of a certificate file with a crt file extension. This certificate file is then imported into RazDC by completing the CSR request from the Manage SSL window.</p>
		</div>
	</div>

</div>
~;
# SSL SELF-SIGNED
######################################
$template{'sslsr'} = qq~
<div id="srcertBlock">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			<h3>&emsp;CA Request Information:</h3>
		</div>
	</div>
</div>
<form name="srcertForm" id="srcertForm">
<div class="table">
 <div class="tr">
	<div class="td winSection inline left">Request Name:</div>
	<div class="td winSection inline left"><input type="text" name="SSLNAME" value="" placeholder="RequestName"><small>(No Spaces)</small></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Common Name:</div>
	<div class="td winSection inline left"><input type="text" name="SSLCN" value="" placeholder="DC01"></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Organization Unit:</div>
	<div class="td winSection inline left"><input type="text" name="SSLOU" value="" placeholder="I.T. Department"></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Organization:</div>
	<div class="td winSection inline left"><input type="text" name="SSLO" value="" placeholder="Supervene LLC"></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">City:</div>
	<div class="td winSection inline left"><input type="text" name="SSLL" value="" placeholder="Reynolds"></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">State:</div>
	<div class="td winSection inline left"><input type="text" name="SSLST" value="" placeholder="ND"></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left">Country:</div>
	<div class="td winSection inline left"><input type="text" name="SSLC" value="" placeholder="US" maxlength="2"><small>(Only two Letters e.g. 'US')</small></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">
	<input type="hidden" name="do" value="sub">
	<input type="hidden" name="task" value="csrrequest">
	<input type="hidden" name="session" value="[!SESSION!]">
	</div>
	<div class="td winSection inline left"><input type="button" value="Create Request" onClick="plax.submit('/cgi-bin/core.pl','srcertBlock','srcertForm'); this.disabled=true; this.value='Working..'; return false;"></div>
 </div>
</div>
</form>
</div>
~;
$template{'srcertcomplete'} = qq~
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			<h3>&emsp;CA Request Complete</h3>
		</div>
	</div>
</div>

<div class="table">
 <div class="tr">
	<div class="td winSection inline left">Request Name:</div>
	<div class="td winSection inline left"><b>[!SSLNAME!]</b></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left"></div>
	<div class="td winSection inline left"></div>
 </div>
 <div class="tr">
	<div class="td winSection inline left"></div>
	<div class="td winSection inline left"><input type="button" value="Manage SSL" onclick="win('','Manage Certificates','/cgi-bin/core.pl?do=sub&task=ssllist&session=[!SESSION!]','600','400',''); return false;"></div>
 </div>
</div>
~;
# FWHOSTLINE
######################################
$template{'fwHostLine'} = qq~
<div class="blockSection">
	<div class="inline left">
		<input type="input" id="host_[!TYPE!][!ID!]" name="host_[!TYPE!][!ID!]" value="[!HOST!]"><input type="input" id="comment[!ID!]" name="comment[!ID!]" value="[!COMMENT!]"><img src="/images/x2.png" onclick="document.getElementById('host_[!TYPE!][!ID!]').value='';document.getElementById('comment_[!TYPE!][!ID!]').value='';return false;">
	</div>
</div>
~;

# FWHOSTS
######################################
$template{'fwHosts'} = qq~
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			<h2>&emsp;Edit Hosts<h2>
			<p>[!MESSAGE!]</p>
		</div>
	</div>
	[!HOSTS!]
	<div class="blockSection">
		<div class="inline left">
			<input type="input" name="host_[!TYPE!]_new" value="" placeholder="Host/Network"><input type="input" name="comment_[!TYPE!]_new" value="" placeholder="Comment">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
			<input type="hidden" name="frtype" value="[!TYPE!]">
			<input type="hidden" name="session" value="[!SESSION!]">
			<input type="hidden" name="sub" value="sub">
			<input type="hidden" name="task" value="[!TASK!]">
			<input type="button" value="Save">
		</div>
	</div>
</div>
~;

# FWPORTLINE
######################################
$template{'fwPortLine'} = qq~
<div class="blockSection">
	<div class="inline left">
		
		<select name="int[!ID!]">
			<option selected>[!INT!]</option>
			[!INTS!]
		</select>
		
		<select name="proto[!ID!]">
			<option selected>[!PROTO!]</option>
			[!PROTOS!]
		</select>
		
		<input type="input" id="port_[!TYPE!][!ID!]" name="port_[!TYPE!][!ID!]" value="[!PORT!]" size="6">
		<input type="input" id="comment_[!TYPE!][!ID!]" name="comment_[!TYPE!][!ID!]" value="[!COMMENT!]" size="20"><img src="/images/x2.png" onclick="document.getElementById('port_[!TYPE!][!ID!]').value='';document.getElementById('comment_[!TYPE!][!ID!]').value='';return false;"
	</div>
</div>
~;

# FWPORTS
######################################
$template{'fwPorts'} = qq~
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			<h2>&emsp;Edit Ports<h2>
			<p>[!MESSAGE!]</p>
		</div>
	</div>
	[!PORTS!]
	<div class="blockSection">
		<div class="inline left">
		
			<select name="int_new">
			<option></option>
			[!INTS!]
			</select>
			
			<select name="proto_new">
			<option></option>
			[!PROTOS!]
			</select>
			
			<input type="input" name="port_new" value="" placeholder="Port" size="6">
			<input type="input" name="comment_new" value="" placeholder="Comment" size="20">
		</div>
	</div>
	<div class="blockSection">
		<div class="inline left">
			<input type="hidden" name="session" value="[!SESSION!]">
			<input type="hidden" name="sub" value="sub">
			<input type="hidden" name="task" value="[!TASK!]">
			<input type="button" value="Save">
		</div>
	</div>
</div>
~;

# RESET FORM
######################################
$template{'reset'} = qq~
<form action="/cgi-bin/core.pl" method="post" onsubmit="factory_reset()" name="reset_form" id="reset_form">
<div class="table" id="reset_update_form">
	<div class="winBlock">
		<div class="winSection">
			Type 'RESET' to confirm factory reset.
			<h3>WARNING: THIS IS WILL DELETE ALL DOMAIN DATA!</h3>
		</div>
	
		<div class="winSection">
			<input type="text" name="userConfirmReset" id="userConfirmReset" value="">
		</div>

		<div class="winSection">
			<input type="hidden" id="do" name="do" value="sub">
			<input type="hidden" id="task" name="task" value="reset_confirm">
			<input type="hidden" id="session" name="session" value="[!SESSION!]">
			<input type="button" style="margin:2px;" id="sendIt" onclick="factory_reset()" value="Factory Reset">
		</div>
	</div>
</div>
</form>
~;
# RESET CONFIRM
######################################
$template{'reset_confirm'} = qq~
	<div class="winBlock">
		<div class="winSection">
			RazDC has been factory reset.
		</div>
	
		<div class="winSection">
			<input type="button" onclick="window.open('/cgi-bin/core.pl?do=login','_top');" value="Logoff">
		</div>
	</div>
~;
# Login
######################################
$template{'login'} = qq~
 <div id="tabframe">
 	<div id="menutabs">
 	</div>
	</div>
 </div>
 
 <div id="menuframe">
 	<div class="box">
 		<div class="container">
 		</div>
 	</div>
 	<div id="results"></div>
 </div>
 <div id="dataframe">
	 <div id="indicator"></div>
 </div>
 <div id="notifyframe" class="barColor">
 </div>
 <div id="dashboard"></div>
<div id="dragableSetup" class="drsElement" style="opacity: 0.99; box-shadow: rgba(0, 0, 0, 0.6) 0px 10px 40px 3px, rgb(89, 89, 89) 0px -1px 0px; border: 1px solid rgb(105, 105, 105); width: 400px; height: 400px; position: absolute; top: 212px; left: 297px; z-index: 3;">

<table width="100%" height="100%" cellspacing="0px" cellpadding="0px" border="0px">
	<tbody>
		<tr>
			<td class="drsMoveHandle barColor" style="background-position: -46.7px -72.7px;">
				<b class="windowtitle">Login</b>
			</td>
		</tr>
		<tr>
		<td valign="top" align="left">
			<center><h3 style="color:red;">[!ERRMESSAGE!]</h3></center>
		<form action="/cgi-bin/core.pl" method="post" id="loginForm" onsubmit="return validateLogin()">

		<table border="0" cellpadding="3" cellspacing="3" style="padding:25px;">
		<tr>
			<td>
				<input type="text" name="username" id="usernameField" placeholder="Username" style="padding:5px;font-size:25px;padding:5px;" class="username_box">
			</td>
		</tr>
		<tr>
			<td>
				<input type="password" name="passwd" id="passwordField" placeholder="Password" style="padding:5px;font-size:25px;padding:5px;" class="password_box">
			</td>
		</tr>
		<tr>
			<td>
				<input type="submit"  class="barColor" style="width:315px;font-size:25px;padding:7px;" value="Login" id="sendIt">		
			</td>
		</tr>
		<tr><td colspan="2">&nbsp;</td></tr>
		<tr><td colspan="2" align="center"><span style="font-family:verdana;font-size:small;">RazDC &copy; <a href="http://razdc.com" target="new">RazDC.com</a></span></td></tr>
		</table>
	
		<input type="hidden" id="md5hash" name="md5hash" value="">
		<input type="hidden" id="do" name="do" value="home">
		</form>
		
		</td>
	</tr>
	</tbody>
</table>
<div class="dragresize dragresize-tl" style="visibility: inherit;"></div>
<div class="dragresize dragresize-tm" style="visibility: inherit;"></div>
<div class="dragresize dragresize-tr" style="visibility: inherit;"></div>
<div class="dragresize dragresize-ml" style="visibility: inherit;"></div>
<div class="dragresize dragresize-mr" style="visibility: inherit;"></div>
<div class="dragresize dragresize-bl" style="visibility: inherit;"></div>
<div class="dragresize dragresize-bm" style="visibility: inherit;"></div>
<div class="dragresize dragresize-br" style="visibility: inherit;"></div>
</div>
<script language="javascript">
localStorage.clear();
</script>
</body> 
</html>
~;

# RazDC Website iFrame
######################################
$template{'razdcWebsite'} = qq~
<iframe src="https://razdc.com/cgi-bin/account/secure.pl?a=activate&s=[!SERIAL!]" id="razdc_website" style="display: block; width: 100%; height: 100%; border: none;"></iframe>
~;
# Dashboard System Info - DONE!
######################################
$template{'dash_sysinfo'} = qq~
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left small">Operating System:</div>
		<div class="inline right small">[!OSVERSION!]</div>
	</div>
	<div class="blockSection">
		<div class="inline left small">Active Directory:</div>
		<div class="inline right small">[!SAMBAV!]</div>
	</div>
	<div class="blockSection">
		<div class="inline left small">RazDC Version:</div>
		<div class="inline right small">[!RAZDCV!]</div>
	</div>
	<div class="blockSection">
		<div class="inline left small">Hostname:</div>
		<div class="inline right small">[!HOST!]</div>
	</div>
	<div class="blockSection">
		<div class="inline left small">Fully Qualified Domain Name:</div>
		<div class="inline right small">[!FQDN!]</div>
	</div>
	<div class="blockSection">
		<div class="inline left small">Domain:</div>
		<div class="inline right small">[!DOMAIN!]</div>
	</div>
	<div class="blockSection">
		<div class="inline left small">Realm:</div>
		<div class="inline right small">[!REALM!]</div>
	</div>
	<div class="blockSection">
		<div class="inline left small">IP Address:</div>
		<div class="inline right small">[!IPADDR!]</div>
	</div>
	<div class="blockSection">
		<div class="inline left small">Netmask:</div>
		<div class="inline right small">[!NETMASK!]</div>
	</div>
	<div class="blockSection">
		<div class="inline left small">Gateway:</div>
		<div class="inline right small">[!GATEWAY!]</div>
	</div>
</div>
~;

# Administrator password - DONE!
######################################
$template{'administrator'} = qq~
<form action="/cgi-bin/core.pl" method="post" target="tabFrame" onsubmit="return validateUpdate()" id="pass_form" name="pass_form">
<div class="table" id="passwd_update_form">
	<div class="tr">
		<div class="td" align="right">&nbsp;</div> 
		<div class="td" align="left">&nbsp;</div> 
	</div> 
	<div class="tr">
		<div class="td" align="right">Current Password:&emsp;</div> 
		<div class="td" align="left">&emsp;<input type="password" id="oldPass" name="oldPass" value="">&emsp;</div> 
	</div>
	<div class="tr">
		<div class="td" align="right">&nbsp;</div> 
		<div class="td" align="left">&nbsp;</div> 
	</div> 
	<div class="tr">
		<div class="td" align="right">New Password:&emsp;</div> 
		<div class="td" align="left">&emsp;<input type="password" id="newPass" name="newPass" value="">&emsp;</div> 
	</div>
	<div class="tr">
		<div class="td" align="right">&nbsp;</div> 
		<div class="td" align="left">&nbsp;</div> 
	</div> 
	<div class="tr"> 
		<div class="td" align="right">Confirm Password:&emsp;</div> 
		<div class="td" align="left">&emsp;<input type="password" id="newPass2" name="newPass2" value="">&emsp;</div> 
	</div>
	<div class="tr">
		<div class="td" align="right">&nbsp;</div> 
		<div class="td" align="left">&nbsp;</div> 
	</div> 
	<div class="tr">
		<div class="td" align="right">Mask Password Fields:&emsp;</div> 
		<div class="td" align="left">&emsp;<input type="checkbox" id="pwdMask" checked="true" onClick="toggleMask()">&emsp;</div> 
	</div>
	<div class="tr">
		<div class="td" align="right">&nbsp;</div> 
		<div class="td" align="left">&nbsp;</div> 
	</div> 
	<div class="tr">
		<input type="hidden" id="do" name="do" value="sub">
		<input type="hidden" id="task" name="task" value="saveAdmin">
		<input type="hidden" id="session" name="session" value="[!SESSION!]">
		<input type="hidden" id="omd5hash" name="omd5hash" value="">
		<input type="hidden" id="nmd5hash" name="nmd5hash" value="">
		<input type="hidden" id="nmd5hash2" name="nmd5hash2" value="">
		<div class="td" colspan="2" align="center">&emsp;<input type="submit" id="sendIt" value="Save">&emsp;</div> 
	</div>  
</div>
</form>
~;
# Dash Services start
###################################
$template{'dash_services_start'} = qq~
	<div class="table winBlock [!CLASS!]">
~;
# Dash Services INNER
###################################
$template{'dash_services_inner'} = qq~
	<div class="tr">
		<div class="td winSection inline left">[!SVCNAME!]</div>
		<div class="td winSection inline right" style="color:[!COLOR!];font-weight:bold;">[!SVCSTATUS!]</div>
	</div>
~;
# Dash Services end
###################################
$template{'dash_services_end'} = qq~
	</div>
~;

# Local Users Start
###################################
$template{'razUsers'} = qq~
<div class="usertab" width="100%">
	<div class="usertablink">
		<select>
			<option></option>
			[!USERTABS!]
		</select>
	</div>
	<div class="usertablink" style="float:right;" onclick="openRazUser(event, 'NewUserTab')"><img src="/images/user_add_16.png" width="16px" height="16px">&nbsp;New User</div>
</div>
[!TABCONTENT!]
<div id="NewUserTab" class="usertabcontent">
<form action="" method="post" target="tabFrame" onsubmit="return false;" id="NewUser_form" name="NewUser_form">
<div class="table" id="NewUser_update_form">
<div class="tr">
	<div class="td" align="left">User</div>
	<div class="td" align="left"><input type="text" name="newRazDCUser" value="" placeholder="NewUser"></div>
</div>
<div class="tr">
	<div class="td" align="left">Enable</div>
	<div class="td" align="left"><input type="checkbox" name="razUserEnabled"></div>
</div>
<div class="tr">
	<div class="td" align="left">Dashboard</div>
	<div class="td" align="left"><input type="checkbox" name="razUserDash"></div>
</div>
<div class="tr">
	<div class="td" align="left">Refresh</div>
	<div class="td" align="left"><input type="checkbox" name="razUserRefresh"></div>
</div>
<div class="tr">
	<div class="td" align="left">Language</div>
	<div class="td" align="left"><input type="checkbox" name="razUserLanguage"></div>
</div>
<div class="tr">
	<div class="td" align="left">System</div>
	<div class="td" align="left"><input type="checkbox" name="razUserSystem"></div>
</div>
<div class="tr">
	<div class="td" align="left">Server</div>
	<div class="td" align="left"><input type="checkbox" name="razUserServer"></div>
</div>
<div class="tr">
	<div class="td" align="left">Network</div>
	<div class="td" align="left"><input type="checkbox" name="razUserNetwork"></div>
</div>
<div class="tr">
	<div class="td" align="left">Users</div>
	<div class="td" align="left"><input type="checkbox" name="razUserADUsers"></div>
</div>
<div class="tr">
	<div class="td" align="left">Logs</div>
	<div class="td" align="left"><input type="checkbox" name="razUserLog"></div>
</div>
<div class="tr">
	<div class="td" align="left"></div>
	<div class="td" align="left"><input type="button" name="razUserCreate" value="Create User" disabled></div>
</div>
</div>
</form>
</div>
~;

# User PErmissions Content
###################################
$template{'razUserTabContent'} = qq~
<div id="[!LUSER!]Tab" class="usertabcontent">
<form action="" method="post" target="tabFrame" onsubmit="return false;" id="[!LUSER!]_form" name="[!LUSER!]_form">
<table id="[!LUSER!]_update_form" cellpadding="0" cellspacing="0" border="0" width="100%">
<tr class="evenRow">
	<td align="left" style="width:200px;">Local User</td>
	<td align="right">[!LUSER!]</td>
	
</tr>
<tr class="oddRow">
	<td align="left" style="width:200px;">Enable User</td>
	<td align="right"><input type="checkbox" name="razUserEnabled" [!LENABLE!]></td>
</tr>
<tr class="evenRow">
	<td align="left" style="width:200px;">Dashboard</td>
	<td align="right"><input type="checkbox" name="razUserDash" [!LDASH!]></td>
</tr>
<tr class="oddRow">
	<td align="left" style="width:200px;">Refresh</td>
	<td align="right"><input type="checkbox" name="razUserRefresh" [!LREFRESH!]></td>
</tr>
<tr class="evenRow">
	<td align="left" style="width:200px;">Language</td>
	<td align="right"><input type="checkbox" name="razUserLanguage" [!LLANG!]></td>
</tr>
<tr class="barColor">
	<td align="left" style="padding:3px;width:200px;">System</td>
	<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>	
</tr>
<tr id="razUserSystemOptions">
	<td colspan="3" style="border:1px #000 solid;">
	
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left"  style="width:200px;padding:3px;">Settings</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">RazDC Password</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">System Services</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Network Information</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Time & Region</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Tasks & Schedules</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">RazDC Users</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">Firmware</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Backups</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Restore</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Update</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Reset</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">Diagnostics</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Domain Shares</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Domain Controller</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">DNS Internal</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">DNS External</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Kerberos Test</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">Power</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Shutdown</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Restart</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>

	</td>	
</tr>
<tr class="barColor" style="border-top:1px #fff solid;">
	<td align="left" style="width:200px;padding:3px;">Server</td>
	<td align="right"><input type="checkbox" name="razUserServer" [!LSERV!]></td>
</tr>
<tr id="razUserServerOptions">
	<td colspan="3" style="border:1px #000 solid;">
	
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">Domain</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Infomration</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Password Policy</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Role Management</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Function Levels</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Domain Trust</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Group Policies</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
	
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">DHCP</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Settings</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Client Leases</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">New Scope</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">New Static</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">DNS</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Options</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Internal Resolution</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Forwarding Servers</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Recursive Lookups</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Allow Transfers</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Flush Cache</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Zone Manager</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">SSL Certificates</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">New Certificate</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Manage SSL</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
	</td>
</tr>
<tr class="barColor" style="border-top:1px #fff solid;">
	<td align="left" style="width:200px;padding:3px;">Network</td>
	<td align="right"><input type="checkbox" name="razUserNetwork" [!LNET!]></td>
</tr>
<tr id="razUserNetworkOptions">
	<td colspan="3" style="border:1px #000 solid;">
		
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">Network Settings</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Network Address</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Local Hosts</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">E-Mail Settings</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">Firewall</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Good Hosts</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Bad Hosts</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Firewall Ports</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
	</td>
</tr>
<tr class="barColor" style="border-top:1px #fff solid;">
	<td align="left" style="width:200px;padding:3px;">Users</td>
	<td align="right"><input type="checkbox" name="razUserADUsers" [!LADU!]></td>
</tr>
<tr id="razUserUsersOptions">
	<td colspan="3" style="border:1px #000 solid;">
	
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">Options</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Create User</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Manage Groups</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Import Users</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Export</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
	</td>
</tr>
<tr class="barColor" style="border-top:1px #fff solid;">
	<td align="left" style="width:200px;padding:3px;">Logs</td>
	<td align="right"><input type="checkbox" name="razUserLog" [!LLOG!]></td>
</tr>
<tr id="razUserLogOptions">
	<td colspan="3" style="border:1px #000 solid;">
	
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">Web Logs</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Security Log</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Error Log</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Access Log</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">Active Directroy Logs</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Samba Logs</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Replication Log</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
		<table style="padding:5px;" cellpadding="0" cellspacing="0" width="100%">
			<tr class="barColor">
				<td align="left" style="width:200px;padding:3px;">System Logs</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Enable All</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>				
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Boot Log</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>				
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">DMesg</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>				
			</tr>
			<tr class="oddRow">
				<td align="left" style="width:200px;">Message Log</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>				
			</tr>
			<tr class="evenRow">
				<td align="left" style="width:200px;">Update Log</td>
				<td align="right"><input type="checkbox" name="razUserSystem" [!LSYS!]></td>
			</tr>
		</table>
		
	</td>
</tr>
<tr>
	<td align="left"><input type="button" name="razUserPassword" onClick="conosle.log('[!LPASS!]');" value="Password Reset" disabled></td>
	<td align="left"><input type="button" name="razUserDelete" value="Delete [!LDELETE!]" disabled></td>
</tr>
</table>
</form>
</div>
~;

# Local Users Entry Items
###################################

# Local Users Entry Items
###################################
$template{'RazUserEntry'} = qq~
  <option onclick="openRazUser(event, '[!LUSER!]Tab')">[!LUSER!]</option>
~;

# Services Start
###################################
$template{'services_main'} = qq~
<div class="table">
<div class="tr">
	<div class="barColor td" style="padding:5px;height:30px;">&emsp;Name</div>
	<div class="barColor td" style="padding:5px;height:30px;">&emsp;Status</div>
	<div class="barColor td" style="padding:5px;height:30px;">&emsp;Start/Stop</div>
	<div class="barColor td" style="padding:5px;height:30px;">&emsp;Restart</div>
</div>
[!SVCITEMS!]
</div>
~;

# Services
###################################
$template{'services'} = qq~
 <div class="tr [!CLASS!]" id="service_container_[!DAEMON!]">
	<div class="td winSection inline left">[!SVCNAME!]</div>
	<div class="td winSection inline left" style="color:[!COLOR!];font-weight:bold;">[!SVCSTATUS!]</div>
	<div class="td winSection inline left">
		<input type="button" value="[!SVCSTARTSTOP!]" onclick="plax.update('/cgi-bin/core.pl?do=sub&task=controlService&svcname=[!SVCNAME!]&control=[!SVCSTARTSTOP!]&daemon=[!DAEMON!]&session=[!SESSION!]','service_container_[!DAEMON!]'); return false;">
	</div>
	<div class="td winSection inline left">
		<input type="button" value="Restart" onclick="this.disabled='disabled'; this.value='Working..';plax.update('/cgi-bin/core.pl?do=sub&task=controlService&svcname=[!SVCNAME!]&control=restart&daemon=[!DAEMON!]&session=[!SESSION!]','service_container_[!DAEMON!]'); return false;">
	</div>
</div>
~;
# Services Disabled
###################################
$template{'servicesDisabled'} = qq~
 <div class="tr [!CLASS!]" id="service_container_[!DAEMON!]">
	<div class="td winSection inline left">[!SVCNAME!]</div>
	<div class="td winSection inline left" style="color:[!COLOR!];font-weight:bold;">[!SVCSTATUS!]</div>
	<div class="td winSection inline left">
	<input type="button" value="Disabled" disabled>
	</div>
	<div class="td winSection inline left">
		<input type="button" value="Restart" onclick="this.disabled='disabled'; this.value='Working..';plax.update('/cgi-bin/core.pl?do=sub&task=controlService&svcname=[!SVCNAME!]&control=restart&daemon=[!DAEMON!]&session=[!SESSION!]','service_container_[!DAEMON!]'); return false;">
	</div>	
</div>
~;

# Service Control
###################################
$template{'service_control'} = qq~
	<div class="td winSection inline left">[!SVCNAME!]</div>
	<div class="td winSection inline left" style="color:[!COLOR!];font-weight:bold;">[!SVCSTATUS!]</div>
	<div class="td winSection inline left">
		<input type="button" value="[!SVCSTARTSTOP!]" onclick="plax.update('/cgi-bin/core.pl?do=sub&task=controlService&svcname=[!SVCNAME!]&control=[!SVCSTARTSTOP!]&daemon=[!DAEMON!]&session=[!SESSION!]','service_container_[!DAEMON!]'); return false;">		
	</div>
	<div class="td winSection inline left">
		<input type="button" value="Restart" onclick="this.disabled='disabled'; this.value='Working..';plax.update('/cgi-bin/core.pl?do=sub&task=controlService&svcname=[!SVCNAME!]&control=restart&daemon=[!DAEMON!]&session=[!SESSION!]','service_container_[!DAEMON!]'); return false;">
	</div>
~;

# Date and Time  - REPLACES current_zone to add time
###################################
$template{'datetime'} = qq~
<div id="timezonecontainer">
<div class="tr"> 
	<div class="td winSection inline left">Date & Time: </div> 
	<div class="td winSection inline left"> <b>[!CURRENTTIME!]</b></div> 
</div> 
<div class="tr"> 
	<div class="td winSection inline left">Time Zone: </div>
	<div class="td winSection inline left"> <b>[!CURRENTZONE!]</b></div>
</div>
<hr>
~;

# Timezone start
##################
$template{'timezonestart'} = qq~
<div class="tr">  
	<div class="td winSection inline left">Change Time Zone:</div> 
</div>
<div class="tr">
	<div class="td winSection inline left">
	<select name="timezone" onChange="plax.update('/cgi-bin/core.pl?do=sub&task=setTZ&tz='+this.options[this.selectedIndex].value+'&session=[!SESSION!]','timezonecontainer'); return false;">
	<option value="none"></option>
~;

# generic option
##################
$template{'option'} = qq~
	<option value="[!VALUE!]" [!SELECTED!]>[!TEXT!]</option>
~;

# Timezone end
##################
$template{'timezoneend'} = qq~
	</select>
	</div>
</div>
<form name="dtForm" id="dtForm" onsubmit="plax.submit('/cgi-bin/core.pl','timezonecontainer','dtForm'); return false;">
<div class="tr">  
	<div class="td winSection inline left">Change Time:</div> 
</div>
<div class="tr">
	<div class="td winSection inline left">
~;

# Time end
##################
$template{'timeend'} = qq~
	</div>
</div>
<div class="tr">  
	<div class="td winSection inline left">
		<input type="hidden" name="do" value="sub">
		<input type="hidden" name="task" value="setTD">
		<input type="hidden" name="session" value="[!SESSION!]">
		<input type="submit" value="Save Changes">
	</div> 
</div>
</form>
</div>
~;

# NTP Servers start
######################
$template{'ntpstart'} = qq~
<div class="tr"> 
        <div class="td winSection inline right">External NTP Servers: </div>
        <div class="td winSection inline left">
~;
# NTP Servers end
######################
$template{'ntpend'}	= qq~
		</div>
</div>
~;

# NTP Box for servers
############################
$template{'ntpbox'} = qq~
<div class="tr"> 
	<div class="td winSection inline left">
		<input type="text" name="ntp[!NUMBER!]" id="ntp[!NUMBER!]" value="[!NTPSERVER!]" onblur="saveNTP(this,this.value);">
	</div>
</div>
~;
# WEB TERMINAL
########################################
$template{'webterm'} = qq~
<table width="100%" height="100%" border="0" cellpadding="0" cellspacing="0" class="barColor" style="background-color:#000;color:#ffffff;width:100%;height:100%;">
	<tr>
		<td style="padding:0px; overflow:scroll;position:absolute;position:absolute;top:0px;bottom:60px;left:0px;right:0px;white-space:pre;font-family:monospace;fint-size:small;" id="termWinData">
		</td>
	</tr>
	<tr>
		<td style="border-top:3px #696969 solid;padding:0px;height:55px;">
			<textarea id="wt_text"style="border:0px;margin:0px;padding:0px;width:100%;height:100%;background:transparent;resize:none;color:#fff;font-weight:bold;outline:0;"></textarea>
		</td>
	</tr>
</table>
~;

# Tasks
########################################
$template{'tasks'} = qq~
<table width="100%" border="0" cellpadding="0" cellspacing="0" style="color:#000000;width:100%;">  
<tr>
<td class="barColor td" style="padding:5px;height:30px;">Name</td>
<td class="barColor td" style="padding:5px;height:30px;">Command</td>
<td class="barColor td" style="padding:5px;height:30px;">Minute</td>
<td class="barColor td" style="padding:5px;height:30px;">Hour</td>
<td class="barColor td" style="padding:5px;height:30px;">Day</td>
<td class="barColor td" style="padding:5px;height:30px;">Month</td>
<td class="barColor td" style="padding:5px;height:30px;">Weekday</td>
</tr>
[!TASKS!]
</table>
~;
# Task Item
########################################
$template{'taskItem'} = qq~
<tr>
<td style="padding:20px;">[!TNAME!]</td>
<td style="padding:20px;">[!TSCRIPT!]</td>
<td style="padding:20px;">[!TMIN!]</td>
<td style="padding:20px;">[!THOUR!]</td>
<td style="padding:20px;">[!TDAY!]</td>
<td style="padding:20px;">[!TMON!]</td>
<td style="padding:20px;">[!TWDAY!]</td>
</tr>
~;
# SCHEDULING - DELETE!?
####################################
$template{'scheduling'} = qq~
<div class="table">
 <div class="tr">
	<div class="td winSection inline left"><input type="button" value="View Schedule" onClick="win('','Edit Scheduled Tasks','/cgi-bin/core.pl?do=sub&task=tasks&session=[!SESSION!]','500',500,''); return false;"></div>
	<div class="td winSection inline left"><input type="button" value="New Task" onClick="win('','Create a New Task','/cgi-bin/core.pl?do=sub&task=newtask&session=[!SESSION!]','850','450',''); return false;"></div>
 </div>
</div>
~;
# New Task
########################################
$template{'newtask'} = qq~
<div id="newTaskContainer">
<form name="newTaskForm" id="newTaskForm" onsubmit="">
<font face="Arial">
  Task: <select name="cron_name" id="cron_name" onChange="e=\$('cron_name');strVal=e.value;plax.update('/cgi-bin/core.pl?do=sub&task=scheduling&cron_name='+strVal+'&session=[!SESSION!]','newTaskContainer'); return false;">
  <option value="new">New Task</option>
  [!TASKS!]
  </select> Name: <input type="text" name="cron_name" size="30" value="[!TNAME!]"><br>
  Command: <input type="text" name="cron_command" size="70" value="[!TSCRIPT!]"><br>
  Description: <input type="text" name="cron_desc" size="70" value="[!TDESC!]">
  <br>
  <select size="5" name="cron_minute" multiple>
    [!CRONMIN!]
  </select>
  <select size="5" name="cron_hour" multiple>
    [!CRONHOUR!]
  </select>
  <select size="5" name="cron_day" multiple>
    [!CRONDAY!]
  </select>
  <select size="5" name="cron_month" multiple>
    [!CRONMON!]
  </select>
  <select size="5" name="cron_week" multiple>
	[!CRONWEEK!]
  </select>
  <br>
  <br>
  <input type="hidden" value="[!SESSION!]" name="session">
  <input type="hidden" value="sub" name="do">
  <input type="hidden" value="updateCron" name="task" >
  <input type="submit" value="Save Changes" name="cron_submit" > [!TASKDEL!]
</font>
</form>
</div>
~;
# Storage
#########################################
$template{'storage'} = qq~
<table width="100%" border="0" cellpadding="0" cellspacing="0" style="color:#000000;border:1px #696969 solid;background:#E3E3E3;width:100%;border-radius:10px;box-shadow:0 0 10px rgba(33, 33, 33, 0.95);">
<tr>
	<td align="left" colspan="2" style="padding:5px;background:URL('../images/glossyback2.gif');height:30px;border-top-left-radius:10px;border-top-right-radius:10px;">&emsp;NAS Storage Device&emsp;</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr>
	<td align="right">&emsp;Help:&emsp;</td>
	<td align="left">&emsp;&emsp;<input type="button" value="Variable Map" onClick="window.open('key.html','_NEW','location=0,toolbar=0,status=0,menubar=0,width=610,height=610,resizeable=1,scrollbars=1');">&emsp;</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr>
	<td align="right">Profile Logon Path:&emsp;</td>
	<td align="left">&emsp;<input type="text" name="profilePath" value="">&emsp;</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr>
	<td align="right">Home Path:&emsp;</td>
	<td align="left">&emsp;<input type="text" name="homePath" value="">&emsp;</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr>
	<td align="right">Home Drive:&emsp;</td>
	<td align="left">&emsp;<input type="text" name="homeDrive" value="H:">&emsp;</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr>
	<td colspan="2" align="center">&emsp;<input type="submit" value="Save Changes">&emsp;</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
</table>
~;

# USB
#########################################
$template{'usb'} = qq~
<table width="100%" border="0" cellpadding="2" cellspacing="0" style="color:#000000;width:100%;">
<tr>
        <td align="left" class="barColor" style="padding:5px;height:30px;">Device</td>
        <td align="left" class="barColor" style="padding:5px;height:30px;">Path</td>
        <td align="left" class="barColor" style="padding:5px;height:30px;">Type</td>
        <td align="left" class="barColor" style="padding:5px;height:30px;">Size</td>
        <td align="left" class="barColor" style="padding:5px;height:30px;">Used</td>
        <td align="left" class="barColor" style="padding:5px;height:30px;">Available</td>
        <td align="left" class="barColor" style="padding:5px;height:30px;">% Used</td>
        <td align="left" class="barColor" style="padding:5px;height:30px;">Options</td>
</tr>

<!--include virtual='/cgi-bin/get_usb.cgi'-->
[!DRIVES!]
<tr><td colspan="8">&nbsp;</td></tr>
</table>
~;
# Backup
########################################
$template{'backup'} = qq~
<div id="backupBlock">
[!BACKUPFILES!]
</div>
~;
# Restore
#######################################
$template{'restore'} = qq~
<div id="returnBlock">
<form action="/cgi-bin/core.pl" id="restoreForm" name="restoreForm" method="post" enctype="multipart/form-data" onsubmit="plax.submit('/cgi-bin/core.pl','returnBlock','restoreForm'); return false;">
<div class="winBlock">
	<div class="blockSection">
		<div class="inline left">
			Select Backup: <input type="file" placeholder="backup-date.raz" accept=".raz" name="usersfile" id="usersfile" value="">
			<input type="button" value="Import Backup" onclick="doSubmit()">
		</div>
	</div>
	<div class="blockSection">
		<div id="uploadStatus" class="inline right">
		
		</div>
	</div>
</div>
<input type="hidden" id="uploadDo" name="do" value="sub">
<input type="hidden" id="uploadTask" name="task" value="backupImport">
<input type="hidden" id="returnBlock" name="returnBlock" value="returnBlock">
<input type="hidden" id="uploadSession" name="session" value="[!SESSION!]">
</form>
<hr>
[!IMPORTFILES!]
</div>
~;

# Update
#####################################
$template{'update'} = qq~
<div id="RazDCUpdateContainer">
<form action="/cgi-bin/core.pl" id="RazDCUpdateForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','RazDCUpdateForm','RazDCUpdateContainer'); return false;">
<table border="0" cellpadding="0" cellspacing="0" style="width:100%;" style="font-size:25px;">
<tr>
	<td width="100px" height="100px"><img src="../images/RazDC4-2021-medium.png" width="100px" height="100px" style="margin:10px;"></td>
</tr>
<tr>
	<td>
		<table border="0" cellpadding="0" cellspacing="0" style="width:100%;" style="font-size:25px;">
		<tr>
			<td align="right" width="200px"><b>My Release:</b></td>
			<td align="left" >&emsp; <b>[!MYVERSION!]</b></td>
		</tr>
		<tr>
			<td colspan="2"><div style="min-height:12px;"></div></td>
		</tr>
		<tr>
			<td align="right" width="200px"><b>Current Release:</b></td>
			<td align="left" >&emsp; <b>[!SERVERVERSION!]</b></td>
		</tr>
		<tr>
			<td colspan="2"><div style="min-height:12px;"></div></td>
		</tr>
		<tr>
			<td colspan="1" align="left"><input type="button" value="Update RazDC" onclick="this.disabled='disable';this.value='Running...';plax.submit('/cgi-bin/core.pl','RazDCUpdateForm','RazDCUpdateContainer'); return false;" style="font-size:25px;padding:5px;margin:2px;" [!DISABLED!]></td>
			<td colspan="1" align="left"><input type="button" value="Update History" onClick="win('','Update Log','/cgi-bin/core.pl?do=sub&task=updatelog&session=[!SESSION!]','900','550','');" style="font-size:25px;padding:5px;margin:2px;"></td>
		</tr>
		<tr>
			<td colspan="2" align="left"><input type="checkbox" name="autoupdate" disabled="true">&emsp;Install updates automatically.&emsp;</td>
		</tr>
		</table>
	
	</td>
</tr>
</table>
<table border="0" cellpadding="0" cellspacing="0" style="width:100%;" style="font-size:25px;">
	<tr>
    	<td align="left">
			<b>Release Comments:</b>
			<hr>[!UPDATEDESC!]
		</td>
	</tr>
</table>
<input type="hidden" name="do" value="sub">
<input type="hidden" name="task" value="completeUpdate">
<input type="hidden" name="session" value="[!SESSION!]">
</form>
</div>
~;

# Generic Window
#################################
$template{'genericwin'} = qq~
<div class="winBlock">
	<div class="winSection">
		<pre>
[!GENERICDATA!]
		</pre>
	</div>
</div>
~;

# Expanded External DNS diagnostics
################################
$template{'exdiag'} = qq~
<div class="winBlock" id="exdiagBlock">
<form name="exdiagForm" id="exdiagForm" action="/cgi-bin/core.pl" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','exdiagForm','exdiagBlock'); return false;">
	<div class="winSection">
		<div class="inline right"></div>
	</div>
	<div class="winSection">
		<div class="inline left">External DNS lookup test.</div>
		<div class="inline right"></div>
	</div>
	<div class="winSection">
		<div class="inline right"></div>
	</div>
	<div class="winSection">
		<div class="inline left">Domain (e.g. razdc.com):</div>
	</div>
	<div class="winSection">
		<div class="inline right"></div>
	</div>
	<div class="winSection">
		<div class="inline right">
			<input type="text" name="exdomain" id="exdomain" placeholder="razdc.com">
			<input type="hidden" name="do" value="sub">
			<input type="hidden" name="task" value="exrun">
			<input type="hidden" name="session" value="[!SESSION!]">
		</div>
	</div>
	<div class="winSection">
		<div class="inline right"></div>
	</div>
	<div class="winSection">
		<div class="inline left"></div>
		<div class="inline right"><input type="button" value="Lookup" onclick="plax.submit('/cgi-bin/core.pl','exdiagForm','exdiagBlock'); return false;"></div>
	</div>
	</form>
</div>
~;

# Kerberos Diagnostic
################################
$template{'krb5diag'} = qq~
<div class="winBlock" id="krb5content"> 
	<div class="winSection">
		<div class="inline right"></div>
	</div>
	<div class="winSection">
		<div class="inline left">Credentials are required to test kerberos.</div>
		<div class="inline right"></div>
	</div>
	<div class="winSection">
		<div class="inline right"></div>
	</div>
	<div class="winSection">
		<div class="inline left">Enter the Password for: <b>[!DOMAIN!]\\Administrator</b></div>
	</div>
	<div class="winSection">
		<div class="inline right"></div>
	</div>
	<div class="winSection">
		<div class="inline right">
			Password: <input type="password" name="krbpass" id="krbpass" placeholder="Password">
			<input type="hidden" name="session" value="[!SESSION!]">
		</div>
	</div>
	<div class="winSection">
		<div class="inline right"></div>
	</div>
	<div class="winSection">
		<div class="inline left"></div>
		<div class="inline right"><input type="button" value="Test Kerberos" onclick="krbSend();"></div>
	</div>
</div>
~;

# Domain Information
###############################
$template{'domaininfo'} = qq~
<div class="winBlock"> 
	<div class="winSection">
		<div class="inline left">Forest:</div>
		<div class="inline right">[!FOREST!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Domain:</div>
		<div class="inline right">[!DOMAIN!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Netbios Domain:</div>
		<div class="inline right">[!NBDOMAIN!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">DC Name:</div>
		<div class="inline right">[!DCNAME!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">DC Netbios Name:</div>
		<div class="inline right">[!DCNBNAME!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Server Site:</div>
		<div class="inline right">[!SERVERSITE!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Client Site:</div>
		<div class="inline right">[!CLIENTSITE!]</div>
	</div>
</tr>
</div>
~;

# Function Levels
##############################
$template{'levels'} = qq~
<div class="winBlock" id="[!CONTAINERID!]">
	<div class="winSection">
		<div class="inline left">[!LVLNAME!]: <b>[!VALUE!]</b></div>
	</div>
	<div class="winSection">
		<div class="inline right">Raise function level to: <button id="" onClick="plax.update('/cgi-bin/core.pl?do=sub&task=raiselvl&func=[!FORESTDOMAIN!]&level=[!NEWFUNC!]&session=[!SESSION!]','[!CONTAINERID!]'); return false;" [!DISABLED!]>(Windows) [!NEWTEXT!]</button></div>
	</div>
</div>
<br>
~;

# Raise Levels
##############################
$template{'raiselvl'} = qq~
	<div class="winSection">
		<div class="inline left">[!FUNC!] has been raise to:[!LEVEL!]</b></div>
	</div>
	<div class="winSection">
		<div class="inline right">[!MESG!]</div>
	</div>
~;

# No Levels
##############################
$template{'nolvl'} = qq~
	<div class="winSection">
		<div class="inline left"></b></div>
	</div>
	<div class="winSection">
		<div class="inline right">[!LVLNAME!] is already at the highest possible function level: [!VALUE!]</div>
	</div>
~;

# Raise Levels2
##############################
$template{'raiselvl2'} = qq~
	<div class="winSection">
		<div class="inline left">[!LVLNAME!]: <b>[!VALUE!]</b></div>
	</div>
	<div class="winSection">
		<div class="inline right">Raise function level to: <button id="" onClick="plax.update('/cgi-bin/core.pl?do=sub&task=raiselvl&func=[!FORESTDOMAIN!]&level=[!NEWFUNC!]&session=[!SESSION!]','[!CONTAINERID!]'); return false;" [!DISABLED!]>(Windows) [!NEWTEXT!]</button></div>
	</div>
~;

# Password Policy begin
###########################
$template{'pass_policy_begin'} = qq~
	<form action="/cgi-bin/core.pl" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','passpol_form','passpolBlock'); return false;" id="passpol_form" name="passpol_form">
	<div class="table" id="passpolBlock">	
~;

# Password Policy dropdown
###########################
$template{'pass_policy_drop'} = qq~
	<div class="tr">
		<div class="td" align="right">&nbsp;</div> 
		<div class="td" align="left">&nbsp;</div> 
	</div> 
	<div class="tr">
		<div class="td" align="left">&emsp;[!KEY!]:</div> 
		<div class="td" align="left">
			<select name="[!SNAME!]">
			[!OPTIONS!]
			</select>
			<small>[!COMMENT!]</small>
		</div> 
	</div>
~;

# Password Policy input
###########################
$template{'pass_policy_input'} = qq~
	<div class="tr">
		<div class="td" align="right">&nbsp;</div> 
		<div class="td" align="left">&nbsp;</div> 
	</div> 
	<div class="tr">
		<div class="td" align="left">&emsp;[!KEY!]:</div> 
		<div class="td" align="left">
			<input type="text" name="[!INAME!]" value="[!VALUE!]" size="3" onkeypress="this.value=this.value.replace(/[^0-9]/,'')">
			<small>[!COMMENT!]</small>
		</div> 
	</div> 
~;

# Password Policy end
############################
$template{'pass_policy_end'} = qq~
	<div class="tr">
		<div class="td" align="right">&nbsp;</div> 
		<div class="td" align="left">&nbsp;</div> 
	</div> 
		<div class="tr">
			<div class="td" align="left">
				<input type="hidden" id="do" name="do" value="sub">
				<input type="hidden" id="task" name="task" value="passpol_update">
				<input type="hidden" id="session" name="session" value="[!SESSION!]">
				&emsp;<input type="button" onclick="plax.submit('/cgi-bin/core.pl','passpol_form','passpolBlock'); plax.update('/cgi-bin/core.pl?session=[!SESSION!]&do=sub&task=loading','passpolBlock'); return false;" value="Update Password Policy">
			</div>
			<div class="td" colspan="2" align="center"></div> 
		</div>
	</div>
</form>
~;

# FSMO Current Roles Head
##########################
$template{'currentRolesHead'} = qq~
<div id="rolesBlock">
<div class="winBlock"> 
	<div class="winSection">
		<div class="inline center bold">[!FSMOMSG!]</div>
	</div>
</div>
~;

# FSMO Current Roles Temp2
##########################
$template{'rolesTemp'} = qq~
	<div class="tr">
		<div class="td" align="left">[!ROLENAME!]</div> 
		<div class="td" align="left">[!ROLEHOST!]</div>  
		<div class="td" align="left">
			<form id="roleTransfer[!ROLEID!]Form" action="/cgi-bin/core.pl" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','rolesBlock','roleTransfer[!ROLEID!]Form'); return false;" name="roleTransfer[!ROLEID!]Form">
			<input type="button" value="Transfer" [!DISABLED!] onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','rolesBlock','roleTransfer[!ROLEID!]Form'); return false;">
			<input type="hidden" id="do" name="do" value="sub">
			<input type="hidden" id="task" name="task" value="transferRole">
			<input type="hidden" id="role" name="role" value="[!ROLE!]">
			<input type="hidden" id="session" name="session" value="[!SESSION!]">
			</form>
		</div>
		<div class="td" align="left">
			<form id="roleSeize[!ROLEID!]Form" action="/cgi-bin/core.pl" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','rolesBlock','roleSeize[!ROLEID!]Form'); return false;" name="roleSeize[!ROLEID!]Form">
			<input type="button" value="Seize" [!DISABLED!] onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','rolesBlock','roleSeize[!ROLEID!]Form'); return false;">
			<input type="hidden" id="do" name="do" value="sub">
			<input type="hidden" id="task" name="task" value="seizeRole">
			<input type="hidden" id="role" name="role" value="[!ROLE!]">
			<input type="hidden" id="session" name="session" value="[!SESSION!]">
			<input type="checkbox" id="force" name="force" [!DISABLED!]> Force
			</form>
		</div>
	</div> 
~;


# FSMO Roles Foot
##########################
$template{'rolesFoot'} = qq~
</div>
~;

# Local Hosts
#########################
$template{'localhosts'} = qq~
<div id="localHostsBlock">
<form action="/cgi-bin/core.pl" name="localHostsForm" id="localHostsForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','lcoalHostsForm','localHostsBlock'); return false;">
<table border="0" cellpadding="0" cellspacing="0" style="width:100%;">
<tr>
	<td align="center">&nbsp;[!MESG!]</td>
</tr>
<tr>
	<td align="center">Local Hosts:&emsp;<br><textarea name="localhosts" cols="50">[!LOCALHOSTS!]</textarea><br><small>(One host per line.)</small></td>
</tr>
<tr>
	<td>&nbsp;</td>
</tr>
<tr>
	<td align="center" colspan="2">
		<input type="hidden" id="do" name="do" value="sub">
		<input type="hidden" id="task" name="task" value="save_hosts">
		<input type="hidden" id="session" name="session" value="[!SESSION!]">
		<input type="button" style="margin:7px;" value="Save Settings" onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','localHostsForm','localHostsBlock'); return false;" disabled>
	</td>
</tr>
<tr>
	<td>&nbsp;</td>
</tr>
</table>
</form>
</div>
~;

# IP Address
#########################
$template{'ipaddr'} = qq~
<div id="netsettings">
[!MESSAGE!]
<form name="netsettingsform">
<div class="table">
 <div class="tr">
	<div class="td winSection inline left">Hostname:</div>
	<div class="td winSection inline left"><input type="text" name="host" value="[!HOST!]" placeholder="Server Name" disabled></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">Domain:</div>
	<div class="td winSection inline left"><input type="text" name="domain" value="[!DOMAIN!]" placeholder="My Domain" disabled></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">Realm:</div>
	<div class="td winSection inline left"><input type="text" name="realm" value="[!REALM!]" placeholder="My Realm" disabled></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">IP Address:</div>
	<div class="td winSection inline left"><input type="text" name="ipaddr" value="[!IPADDR!]" placeholder="192.168.0.10"></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">Subnet Mask:</div>
	<div class="td winSection inline left"><input type="text" name="netmask" value="[!NETMASK!]" placeholder="255.255.255.0"></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">Gateway:</div>
	<div class="td winSection inline left"><input type="text" name="gwaddr" value="[!GWADDR!]" placeholder="192.168.0.1"></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">
		<input type="hidden" id="do" name="do" value="sub">
		<input type="hidden" id="task" name="task" value="save_ipaddr">
		<input type="hidden" id="session" name="session" value="[!SESSION!]">
	</div>
	<div class="td winSection inline left"><input type="button" value="Save Settings" disabled></div>
 </div>
</div>
</form>
</div>
~;

# Full Network Setup
#########################
$template{'fullnet'} = qq~
<div id="updateNetBlock">
[!MESSAGE!]
<form name="updateNetForm" action="/cgi-bin/core.pl" name="updateNetForm" id="updateNetForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','updateNetForm','updateNetBlock'); return false;">
<div class="table">
 <div class="tr">
	<div class="td winSection inline left">Hostname:</div>
	<div class="td winSection inline left"><input type="text" name="update_host" value="[!HOST!]" placeholder="dc01"></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">Domain:</div>
	<div class="td winSection inline left"><input type="text" name="update_domain" value="[!DOMAIN!]" placeholder="razdc.local"></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">IP Address:</div>
	<div class="td winSection inline left"><input type="text" name="update_ipaddr" value="[!IPADDR!]" placeholder="192.168.0.10"></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">Subnet Mask:</div>
	<div class="td winSection inline left"><input type="text" name="update_netmask" value="[!NETMASK!]" placeholder="255.255.255.0"></div>
 </div>
  <div class="tr">
	<div class="td winSection inline left">Gateway:</div>
	<div class="td winSection inline left"><input type="text" name="update_gwaddr" value="[!GWADDR!]" placeholder="192.168.0.1"></div>
 </div>

   <div class="tr">
	<div class="td winSection inline left">DNS:</div>
	<div class="td winSection inline left"><textarea name="update_dns" placeholder="8.8.8.8\n8.8.4.4" size="4">[!GLOBALNS!]</textarea></div>
 </div>

  <div class="tr">
	<div class="td winSection inline left">
		<input type="hidden" id="do" name="do" value="sub">
		<input type="hidden" id="task" name="task" value="save_ipaddr">
		<input type="hidden" id="session" name="session" value="[!SESSION!]">
	</div>
	<div class="td winSection inline left"><input type="button" value="Save Settings" onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','updateNetForm','updateNetBlock'); return false;"></div>
 </div>
</div>
</form>
</div>
~;

# Group Policies
#########################

$template{'policyEntry'} = qq~
  <option onclick="openPolicy(event, '[!POLICYID!]Tab')">[!POLICYNAME!]</option>
~;

$template{'gpo'} = qq~
<div class="usertab" width="100%">
	
	<div class="usertablink" style="float:left;" onclick="openNewPolicy(event, 'NewPolicyTab')"><img src="/images/user_add_16.png" width="16px" height="16px">&nbsp;Create Policy</div>
	<div class="usertablink" style="float:left;" onclick="openRazUser(event, 'NewUserTab')"><img src="/images/user_add_16.png" width="16px" height="16px">&nbsp;Current GPOs</div>
</div>

<div id="NewPolicyTab" class="policytabcontent">

	<form action="" method="post" onsubmit="return false;" id="newPolicyForm" name="newPolicyForm">
	<div class="table" id="NewPolicy_update_form">
	<div class="tr">
		<div class="td" align="left">User</div>
		<div class="td" align="left"><input type="text" name="newRazDCUser" value="" placeholder="Policy Name"></div>
	</div>
	<div class="tr">
		<div class="td" align="left">Enable</div>
		<div class="td" align="left"><input type="checkbox" name="razUserEnabled"></div>
	</div>
	<div class="tr">
		<div class="td" align="left">Enable</div>
		<div class="td" align="left"><input type="checkbox" name="razUserEnabled"></div>
	</div>
	<div class="tr">
		<div class="td" align="left"></div>
		<div class="td" align="left"><input type="button" name="razUserCreate" value="Create Policy" disabled></div>
	</div>
</div>
</form>
</div>
~;

# Group Policy Start
###################################
$template{'policyTemplate'} = qq~
<div class="policytab" width="100%">
	<div class="policytablink">
		<select>
			<option></option>
			[!POLICYTABS!]
		</select>
	</div>
	<div class="policytablink" style="float:right;" onclick="openPolicy(event, 'NewPolicyTab')"><img src="/images/database_add_16.png" width="16px" height="16px">&nbsp;New Policy</div>
</div>

[!POLICYTABCONTENT!]

<div id="NewPolicyTab" class="policytabcontent">
<form action="" method="post" target="tabFrame" onsubmit="return false;" id="NewPolicy_form" name="NewPolicy_form">
<div class="table" id="NewPolicy_update_form">
<div class="tr">
	<div class="td" align="left">Policy Name</div>
	<div class="td" align="left"><input type="text" name="newPolicyName" value="" placeholder="New Policy"></div>
</div>
<div class="tr">
	<div class="td" align="left"></div>
	<div class="td" align="left"><input type="button" name="razCreatPolicy" value="Create Policy" disabled></div>
</div>
</div>
</form>
</div>
~;

# GPO Tab Content
###################################
$template{'policyTabContent'} = qq~
<div id="[!POLICYID!]Tab" class="policytabcontent">
<form action="" method="post" target="tabFrame" onsubmit="return false;" id="[!LUSER!]_form" name="[!LUSER!]_form">
<table id="[!LUSER!]_update_form" cellpadding="0" cellspacing="0" border="0" width="100%">
<tr class="evenRow">
	<td align="left" style="width:150px;">Policy Name:</td>
	<td align="left">[!PDN!]</td>
</tr>
<tr class="oddRow">
	<td align="left" style="width:200px;">Policy ID:</td>
	<td align="left">[!POLICYID!]</td>
</tr>
<tr class="evenRow">
	<td align="left" style="width:200px;">Policy Object:</td>
	<td align="left">[!GPO!]</td>
</tr>
<tr class="oddRow">
	<td align="left" style="width:200px;">Path:</td>
	<td align="left">[!GPPATH!]</td>
</tr>
<tr class="evenRow">
	<td align="left" style="width:200px;">Domain name:</td>
	<td align="left">[!GPDN!]</td>
</tr>
<tr class="oddRow">
	<td align="left" style="width:200px;">Version:</td>
	<td align="left">[!GPV!]</td>
</tr>
<tr class="evenRow">
	<td align="left" style="width:200px;">Flags:</td>
	<td align="left">[!GPF!]</td>
</tr>

<tr>
	<td align="left"></td>
	<td align="left">
		<input type="button" name="razUserPassword" onClick="conosle.log('[!LPASS!]');" value="Edit Policy" disabled>
		<input type="button" name="razUserDelete" value="Delete Policy" disabled>
	</td>
</tr>
</table>
</form>
</div>
~;

# Network Shares NEEDED
##########################
$template{'shares'} = qq~
<table border="0" cellpadding="0" cellspacing="0" style="width:100%;">
<tr>
	<td class="barColor" style="padding:5px;height:30px;">&emsp;Share</td>
	<td class="barColor" style="padding:5px;height:30px;">&emsp;Delete</td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<!--#include virtual='/cgi-bin/shares.cgi' -->
[!SHARES!]
<tr><td colspan="2">&nbsp;</td></tr>
<tr><td colspan="2">&nbsp;</td></tr>
</table>
~;

# Network Interface DONE
############################
$template{'interface'} = qq~
<div class="winBlock"> 
	<div class="winSection">
		<div class="inline left">Hostname:</div>
		<div class="inline right">[!HOST!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">FQDN:</div>
		<div class="inline right">[!FQDN!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Domain:</div>
		<div class="inline right">[!DOMAIN!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Realm:</div>
		<div class="inline right">[!REALM!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Network Address:</div>
		<div class="inline right">[!IPADDR!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Subnet Mask:</div>
		<div class="inline right">[!NETMASK!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Gateway:</div>
		<div class="inline right">[!GATEWAY!]</div>
	</div>
</div>
~;

# DHCP - OPTIONS 1
###########################
$template{'dhcp_global'} = qq~
<form action="/cgi-bin/core.pl" id="dhGlobalsForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','dhGlobalsForm','saveDHBlock'); return false;">
<div id="saveDHBlock">

<table cellpadding="7" cellspacing="0" border="0" width="100%" >
<tr>
	<td>&emsp;DomainName:</td>
	<td><input type="text" name="domain" value="[!DHDOMAINNAME!]" placeholder="mydomain.com"></td>
</tr>
<tr>
	<td>&emsp;DNS Servers:</td>
	<td>
		[!DHDNSSERVERS!]
		<input type="text" name="[!DHDNSCOUNT!]" value="" placeholder="x.x.x.x"><br>
	</td>
</tr>
<tr>
	<td>&emsp;WINS Servers:</td>
	<td>
		[!DHWINSSERVERS!]
		<input type="text" name="[!DHWINSCOUNT!]" value="" placeholder="x.x.x.x"><br>
</td>
</tr>
<tr>
	<td>&emsp;Default Lease Time:</td>
	<td><input type="text" name="defaultleasetime" value="[!DEFAULTLEASETIME!]" placeholder="86400"></td>
</tr>
<tr>
	<td>&emsp;Max Lease Time:</td>
	<td><input type="text" name="maxleasetime" value="[!MAXLEASETIME!]" placeholder="604800"></td>
</tr>
<tr>
	<td>&emsp;Authoritative:</td>
	<td><input type="checkbox" value="authoritative" name="authoritative" checked="[!AUTHORITATIVE!]"></td>
</tr>
<tr>
	<td></td>
	<td align="left"><input type="button" value="&nbsp;Save&nbsp;" onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','dhGlobalsForm','saveDHBlock'); return false;"></td>
</tr>
</table>

<input type="hidden" id="do" name="do" value="sub">
<input type="hidden" id="task" name="task" value="dhsave">
<input type="hidden" id="session" name="session" value="[!SESSION!]">
</div>
</form>
<br>
~;

# DHCP - DNS SERVERS
###########################
$template{'dhcp_dns_server'} = qq~
	<input type="text" name="[!DHDNSCOUNT!]" value="[!DHDNSENTRY!]"><br>
~;

# DHCP - WINS SERVERS
###########################
$template{'dhcp_wins_server'} = qq~
	<input type="text" name="[!DHWINSCOUNT!]" value="[!DHWINSENTRY!]"><br>
~;

# DHCP Clients Table
###########################
$template{'dhcp_clients'} = qq~
<table border="0" cellpadding="0" cellspacing="0" style="width:100%;"> 
<tr> 
	<td align="left" class="barColor" style=">&emsp;IP</td> 
	<td align="left" class="barColor" style="height:30px;padding:5px;">&emsp;MAC</td> 
	<td align="left" class="barColor" style="height:30px;padding:5px;">&emsp;Name</td> 
	<td align="left" class="barColor" style="height:30px;padding:5px;">&emsp;Status</td>
	<td align="left" class="barColor" style="height:30px;padding:5px;">&emsp;Starts</td> 
	<td align="left" class="barColor" style="height:30px;padding:5px;">&emsp;Expires</td> 
</tr>
[!DHCPCLIENTS!]
</table>
~;

# DHCP Find IP
###########################
$template{'dhcpfindip'} = qq~
<div class="winBlock"> 
	<div class="winSection">
		<div class="inline left">Hostname:</div>
		<div class="inline right">[!DHCLIENTHOSTNAME!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">IP Address:</div>
		<div class="inline right">[!DHCP_IP!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">MAC Address:</div>
		<div class="inline right">[!DHCPHARDWARE!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Realm:</div>
		<div class="inline right">[!REALM!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Binding:</div>
		<div class="inline right">[!DHCPBINDING!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">Start Date:</div>
		<div class="inline right">[!DHCPSTARTS!]</div>
	</div>
	<div class="winSection">
		<div class="inline left">End Date:</div>
		<div class="inline right">[!DHCPENDS!]</div>
	</div>
</div>
~;

# DHCP Clients Rows
###########################
$template{'dhcp_rows'} = qq~
	<tr class="[!DHCPCLASS!]"> <!--onClick="win('','[!DHCP_IP!]','/cgi-bin/core.pl?do=sub&task=findip&clientip=[!DHCP_IP!]&session=[!SESSION!]','500',500,''); return false;"-->
	<td>&emsp;<font size=-1>[!DHCP_IP!]</td>
	<td>&emsp;<font size=-1>[!DHCPHARDWARE!]</td>
	<td>&emsp;<font size=-1>[!DHCLIENTHOSTNAME!]</td>
	<td>&emsp;<font size=-1>[!DHCPBINDING!]</td>
	<td>&emsp;<font size=-1>[!DHCPSTARTS!]</td>
	<td>&emsp;<font size=-1>[!DHCPENDS!]</td>
	</tr>
~;

# DHCP Scope table
##########################
$template{'scope_table'} = qq~
	<h3>Scopes: [!SCOPECOUNT!]</h3>
	<table width="100%" border="0" cellpadding="0" cellspacing="0" style="color:#000000;border:1px #696969 solid;background:#E3E3E3;width:100%;">
	<tr>
	<td align="left" class="barColor" style="height:30px;padding:5px;">Scope Name</td>
	<td align="left" class="barColor" style="height:30px;padding:5px;">DHCP Range</td>
	<td align="left" class="barColor" style="height:30px;padding:5px;">Edit</td>
	<td align="left" class="barColor" style="height:30px;padding:5px;">Delete</td>
	</tr>
	[!SCOPEROWS!]
	</table>
	<br>
~;

# DHCP Scope rows
##########################
$template{'scope_row'} = qq~
		<tr style="height:30px;padding:5px;border:1px #000 solid;">
			<td>&emsp;<b>[!SCOPENAME!]</b></td>
			<td>&emsp;<b>[!SCOPESTART!] - [!SCOPEEND!]</b></td>
			<td><img src="../images/edit.png" border="0" title="Edit" alt="Edit" style="cursor:pointer;" onClick="document.getElementById('scopeedit[!SCOPECOUNT!]').style.display = document.getElementById('scopeedit[!SCOPECOUNT!]').style.display == 'table-cell' ? 'none' : 'table-cell';"></td>
			<td><img src="../images/trash.png" border="0" title="Delete" alt="Delete" style="cursor:pointer;" onClick="win('','Delete Scope','/cgi-bin/core.pl?do=sub&task=delscope&scope=[!THISSCOPE!]&session=[!SESSION!]','700','300','');"></td>
		</tr>
		<tr style="display:table-row">
			<td colspan="4" id="scopeedit[!SCOPECOUNT!]" style="display:none;width:100%;">
				
				<form action="" method="post">
				<table border="0" cellpadding="3" cellspacing="0" style="width:100%;">
				<tr class="[!CLASSNAME!]">
					<td>&emsp;Network:</td>
					<td><input type="text" name="scopenetwork[!SCOPECOUNT!]" value="[!SUBNETV!]"></td>
				</tr>
				<tr class="[!CLASSNAME!]">
					<td>&emsp;Subnet:</td>
					<td><input type="text" name="scopemask[!SCOPECOUNT!]" value="[!NETMASKV!]"></td>
				</tr>
				<tr class="[!CLASSNAME!]">
					<td>&emsp;Range:</td>
					<td><textarea name="scoperange[!SCOPECOUNT!]">[!SCOPESTART!]\n[!SCOPEEND!]</textarea></td>
				</tr>
				<tr class="[!CLASSNAME!]">
					<td>&emsp;Broadcast:</td>
					<td><input type="text" name="broadcast[!SCOPECOUNT!]" value="[!BROADCAST!]"></td>
				</tr>
				<tr class="[!CLASSNAME!]">
					<td>&emsp;Router:</td>
					<td><input type="text" name="router[!SCOPECOUNT!]" value="[!GATEWAY!]"></td>
				</tr>
				<tr class="[!CLASSNAME!]">
					<td>&emsp;Domain:</td>
					<td><input type="text" name="domain[!SCOPECOUNT!]" value="[!DOMAIN!]"></td>
				</tr>
				<tr class="[!CLASSNAME!]">
					<td>&emsp;DNS:</td>
					<td><input type="text" name="dns[!SCOPECOUNT!]" value="[!DNS!]"></td>
				</tr>
				<tr class="[!CLASSNAME!]">
					<td>&emsp;WINS:</td>
					<td><input type="text" name="wins[!SCOPECOUNT!]" value="[!NETBIOS!]"></td>
				</tr>
				<tr class="[!CLASSNAME!]">
					<td>&emsp;Time Offset:</td>
					<td><input type="text" name="time[!SCOPECOUNT!]" value="[!OFFSET!]"></td>
				</tr>
				<tr class="[!CLASSNAME!]">
					<td></td>
					<td><input type="submit" value="Save Changes" onclick="this.disabled='disable';"></td>
				</tr>
			</table>
			<br>
			</form>
			</td>
		</tr>
~;

# DHCP Static Table
###########################
$template{'static_table'} = qq~
	<h3>Static Addresses: [!HOSTCOUNT!]</h3>
	<table width="100%" border="0" cellpadding="0" cellspacing="0" style="color:#000000;border:1px #696969 solid;background:#E3E3E3;width:100%;">
	<tr>
	<td align="left" class="barColor" style="height:30px;padding:5px;">&emsp;Hostname</td>
	<td align="left" class="barColor" style="height:30px;padding:5px;">&emsp;MAC Address</td>
	<td align="left" class="barColor" style="height:30px;padding:5px;">&emsp;IP Address</td>
	<td align="left" class="barColor" style="height:30px;padding:5px;">&emsp;Delete</td>
	</tr>
	[!STATICROWS!]
	</table>
	<br>
~;

# DHCP static row
###########################
$template{'static_row'} = qq~
	<tr class="[!CLASSNAME!]" style="height:30px;padding:5px;border:1px #000 solid;">
	<td>&emsp;<b>[!STATICHOST!]</b></td>
	<td>&emsp;<b>[!STATICMAC!]</b></td>
	<td>&emsp;<b>[!STATICIP!]</b></td>
	<td>&emsp;<img src="../images/trash.png" border="0" title="Delete" alt="Delete" style="cursor:pointer;" onClick="win('','Delete Static','/cgi-bin/core.pl?do=sub&task=delstatic&host=[!HOSTID!]&session=[!SESSION!]','700','300','');"></td>
	</tr>
~;

# Scope Help NEEDED
###########################
$template{'scope_help'} = qq~
<table border="1"> 
	<tbody>
		<tr><th> </th><th>Addresses</th><th>Hosts</th><th>Netmask</th><th>Amount of a Class C</th></tr>
		<tr align="center"><th>/30</th><td>4</td><td>2</td><td>255.255.255.252</td><td>1/64</td></tr>
		<tr align="center"><th>/29</th><td>8</td><td>6</td><td>255.255.255.248</td><td>1/32</td></tr>
		<tr align="center"><th>/28</th><td>16</td><td>14</td><td>255.255.255.240</td><td>1/16</td></tr>
		<tr align="center"><th>/27</th><td>32</td><td>30</td><td>255.255.255.224</td><td>1/8</td></tr> 
		<tr align="center"><th>/26</th><td>64</td><td>62</td><td>255.255.255.192</td><td>1/4</td></tr>
		<tr align="center"><th>/25</th><td>128</td><td>126</td><td>255.255.255.128</td><td>1/2</td></tr>
		<tr align="center"><th>/24</th><td>256</td><td>254</td><td>255.255.255.0</td><td>1</td></tr>
		<tr align="center"><th>/23</th><td>512</td><td>510</td><td>255.255.254.0</td><td>2</td></tr>
		<tr align="center"><th>/22</th><td>1024</td><td>1022</td><td>255.255.252.0</td><td>4</td></tr>
		<tr align="center"><th>/21</th><td>2048</td><td>2046</td><td>255.255.248.0</td><td>8</td></tr>
		<tr align="center"><th>/20</th><td>4096</td><td>4094</td><td>255.255.240.0</td><td>16</td></tr>
		<tr align="center"><th>/19</th><td>8192</td><td>8190</td><td>255.255.224.0</td><td>32</td></tr>
		<tr align="center"><th>/18</th><td>16384</td><td>16382</td><td>255.255.192.0</td><td>64</td></tr>
		<tr align="center"><th>/17</th><td>32768</td><td>32766</td><td>255.255.128.0</td><td>128</td></tr>
		<tr align="center"><th>/16</th><td>65536</td><td>65534</td><td>255.255.0.0</td><td>256</td></tr>
	</tbody>
</table>
~;

# New Scope NEEDED
###########################
$template{'new_scope'} = qq~
<div id="newScopeBlock">
	<table width="100%" border="0" cellpadding="0" cellspacing="0" style="width:100%;">
        <tr>
         <td id="scopeedit" style="width:100%;"> <br>
			<form action="/cgi-bin/core.pl" id="newScopeForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','newScopeForm','saveDHBlock'); return false;">
                                <table border="0" cellpadding="3" cellspacing="0" style="width:100%;">
								<tr>
                                        <td>&emsp;Scope Name:</td>
                                        <td><input type="text" name="scopename" value="" placeholder="My_Scope"> (No Spaces)</td>
                                </tr>
                                <tr>
                                        <td>&emsp;Network:</td>
                                        <td><input type="text" name="scopenetwork" value="" placeholder="x.x.x.0"> </td>
                                </tr>
                                <tr>
                                        <td>&emsp;Subnet:</td>
                                        <td><input type="text" name="scopemask" value="" placeholder="255.255.255.0"> (<a href="javascript:win('','Subnet Help','/cgi-bin/core.pl?do=sub&task=&scope_help&session=[!SESSION!]','500','700','');">?</a>)</td>
                                </tr>
                                <tr>
                                        <td>&emsp;Range:</td>
                                        <td><textarea name="scoperange" cols="25" rows="2" placeholder="x.x.x.2\nx.x.x.254"></textarea> (one address per line.)</td>
                                </tr>
                                <tr>
                                        <td>&emsp;Broadcast:</td>
                                        <td><input type="text" name="scopebroadcast" value="" placeholder="x.x.x.255"> </td>
                                </tr>
                               <tr>
                                        <td>&emsp;Router:</td>
                                        <td><input type="text" name="scoperouter" value="" placeholder="x.x.x.1"> </td>
                                </tr>
                                <tr>
                                        <td>&emsp;Domain:</td>
                                        <td><input type="text" name="scopedomain" value="" placeholder="mydomain.com"> (domain or workgroup)</td>
                                </tr>
                                <tr>
                                        <td>&emsp;DNS:</td>
                                        <td><input type="text" name="scopedns" value="" placeholder="8.8.8.8"> (optional but recommended)</td>
                                </tr>
                                <tr>
                                        <td>&emsp;WINS:</td>
                                        <td><input type="text" name="scopewins" value="" placeholder="RazDC IP"> (optional)</td>
                                </tr>
										<td>&emsp;Time Offset:</td>
                                        <td><input type="text" name="scopetime" value="" placeholder="-21600"> (offset in seconds from UTC, optional)</td>
                                </tr>
                                <tr>
                                        <td>
										<input type="hidden" id="do" name="do" value="sub">
										<input type="hidden" id="task" name="task" value="savescope">
										<input type="hidden" id="session" name="session" value="[!SESSION!]">
										</td>
										<td><input type="button" value="&nbsp;Save Scope&nbsp;" onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','newScopeForm','newScopeBlock'); return false;"></td>										
                                </tr>
							</table>
                        <br>
                    </form>	
				</td>
			</tr>
	</table>
</div>
~;

# New Static NEEDED
############################
$template{'new_static'} = qq~
<div id="newStaticBlock">
<form action="/cgi-bin/core.pl" method="post" id="newStaticForm" onsubmit="plax.submit('/cgi-bin/core.pl','newStaticForm','newStaticBlock'); return false;">
<table width="100%" border="0" cellpadding="0" cellspacing="0" style="width:100%;">
<tr>
	<td>
	<br>
	<table border="0" cellpadding="3" cellspacing="0" width="100%">
	<tr>
		<td>Host:</td>
		<td><input type="text" name="Host" value=""> (PC/Server or device name)</td>
	</tr>
	<tr>
		<td>Static IP:</td>
		<td><input type="text" name="StaticIP" value=""> (IP address of the PC/Server/device)</td>
	</tr>
	<tr>
		<td>MAC Address:</td>
		<td><input type="text" name="MACAddress" value=""> (MAC address of the PC/Server/device)</td>
	</tr>
	<tr>
		<td>
		<input type="hidden" id="do" name="do" value="sub">
		<input type="hidden" id="task" name="task" value="savestatic">
		<input type="hidden" id="session" name="session" value="[!SESSION!]">
		</td>
		<td colspan="2"><input type="button" value="Save Static Host" onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','newStaticForm','newStaticBlock'); return false;"></td>
	</tr>
	</table>
	</td>
</tr>
</table>
</form>
</div>
~;

# DNS Options NEEDED
##########################
$template{'dns_options'} = qq~
<div id="DNSOptionsBlock">
<form action="/cgi-bin/save_nsOptions.pl" method="post" id="DNSOptionsForm" onsubmit="plax.submit('/cgi-bin/core.pl','DNSOptionsForm','DNSOptionsBlock'); return false;">
<table border="0" cellspacing="0" cellpadding="0" width="100%">
[!NSDATA!]
</table>
<input type="hidden" id="do" name="do" value="sub">
<input type="hidden" id="task" name="task" value="save_ns">
<input type="hidden" id="session" name="session" value="[!SESSION!]">
<input type="button" style="margin:7px;" value="Save Settings" onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','DNSOptionsForm','DNSOptionsBlock'); return false;">
</form>
~;

# DNS OPTIONS ROW
#########################
$template{'dnsoption_row'} = qq~
        <tr> 
         <td style="padding:10px;width:250px;">[!NSKFORMAT!]</td>
         <td style="padding:10px;"><input style="height:30px;width:300px;" type="text" name="[!KNAME!]" value="[!VALUE!]"></td>
        </tr>
~;

# Internal DNS Servers NEEDED
#########################
$template{'internal_dns'} = qq~
<div id="InternalDNSBlock">
<form action="/cgi-bin/core.pl" name="InternalDNSForm" id="InternalDNSForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','InternalDNSForm','InternalDNSBlock'); return false;">
<table border="0" cellpadding="0" cellspacing="0" style="width:100%;">
<tr>
	<td colspan="2">&emsp;[!MESG!]</td>
</tr>
<tr>
    	<td align="right">Search:&emsp;</td>
        <td align="left"><input type="text" id="search" name="search" value="[!DOMAIN!]" maxlength="80"></td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr>
	<td align="right"></td>
	<td align="left">Name Servers:&emsp;<br><textarea name="nameservers">[!NAMESERVERS!]</textarea><br><small>(One address per line.)</small></td>
</tr>
<tr><td colspan="2">&nbsp;</td></tr>
<tr>
	<td align="center" colspan="2">
		<input type="hidden" id="do" name="do" value="sub">
		<input type="hidden" id="task" name="task" value="save_intns">
		<input type="hidden" id="session" name="session" value="[!SESSION!]">
		<input type="button" style="margin:7px;" value="Save Settings" onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','InternalDNSForm','InternalDNSBlock'); return false;">
	</td>
</tr>

</table>
</form>
</div>
~;

# DNS Forwarders NEEDED
##########################
$template{'dns_forwarders'} = qq~
<div id="ForwardDNSBlock">
<form action="/cgi-bin/core.pl" name="ForwardDNSForm" id="ForwardDNSForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','ForwardDNSForm','ForwardDNSBlock'); return false;">
<table border="0" cellpadding="0" cellspacing="0" style="width:100%;">
<tr>
	<td align="center">&nbsp;[!MESG!]</td>
</tr>
<tr>

	<td align="center">Forwarding Servers:&emsp;<br><textarea name="nameservers">[!NAMESERVERS!]</textarea><br><small>(One address per line.)</small></td>
</tr>
<tr>
	<td>&nbsp;</td>
</tr>
<tr>
	<td align="center" colspan="2">
		<input type="hidden" id="do" name="do" value="sub">
		<input type="hidden" id="task" name="task" value="save_forward">
		<input type="hidden" id="session" name="session" value="[!SESSION!]">
		<input type="button" style="margin:7px;" value="Save Settings" onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','ForwardDNSForm','ForwardDNSBlock'); return false;">
	</td>
</tr>
<tr>
	<td>&nbsp;</td>
</tr>
</table>
</form>
</div>
~;

# DNS Recursion NEEDED
###########################
$template{'dns_recursion'} = qq~
<div id="RecursiveDNSBlock">
<form action="/cgi-bin/core.pl" name="RecursiveDNSForm" id="RecursiveDNSForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','RecursiveDNSForm','RecursiveDNSBlock'); return false;">
<table border="0" cellpadding="0" cellspacing="0" style="width:100%;">
<tr>
	<td align="center">&nbsp;[!MESG!]</td>
</tr>
<tr>
	<td align="center">Allowed Clients:&emsp;<br><textarea name="nameservers">[!NAMESERVERS!]</textarea><br><small>(One address per line.)</small></td>
</tr>
<tr>
	<td>&nbsp;</td>
</tr>
<tr>
	<td align="center" colspan="2">
		<input type="hidden" id="do" name="do" value="sub">
		<input type="hidden" id="task" name="task" value="save_recurse">
		<input type="hidden" id="session" name="session" value="[!SESSION!]">
		<input type="button" style="margin:7px;" value="Save Settings" onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','RecursiveDNSForm','RecursiveDNSBlock'); return false;">
	</td>
</tr>
<tr>
	<td>&nbsp;</td>
</tr>
</table>
</form>
</div>
~;

# DNS Transfers NEEDED
##########################
$template{'dns_transfers'} = qq~
<div id="axfrDNSBlock">
<form action="/cgi-bin/core.pl" name="axfrDNSForm" id="axfrDNSForm" method="post" onsubmit="plax.submit('/cgi-bin/core.pl','axfrDNSForm','axfrDNSBlock'); return false;">
<table border="0" cellpadding="0" cellspacing="0" style="width:100%;">
<tr>
	<td align="center">&nbsp;[!MESG!]</td>
</tr>
<tr>
	<td align="center">Allow Transfer:&emsp;<br><textarea name="nameservers">[!NAMESERVERS!]</textarea><br><small>(One address per line.)</small></td>
</tr>
<tr>
	<td>&nbsp;</td>
</tr>
<tr>
	<td align="center" colspan="2">
		<input type="hidden" id="do" name="do" value="sub">
		<input type="hidden" id="task" name="task" value="save_trans">
		<input type="hidden" id="session" name="session" value="[!SESSION!]">
		<input type="button" style="margin:7px;" value="Save Settings" onclick="this.disabled='disable';plax.submit('/cgi-bin/core.pl','axfrDNSForm','axfrDNSBlock'); return false;">
	</td>
</tr>
<tr>
	<td>&nbsp;</td>
</tr>
</table>
</form>
</div>
~;

# Log Settings - Future email notifications - REMOVE TABLE
##########################
$template{'smtp_settings'} = qq~
<form action="/cgi-bin/notifySave.cgi" method="post" target="msgFrame">
<table width="100%" border="0" cellpadding="0" cellspacing="0" style="width:100%;">
<tr>
<td>
	<!--include virtual='/cgi-bin/get_email.cgi' -->
	<br>
	<table border="0" cellpadding="0" cellspacing="5" width="100%" style="margin:0px;">
	<tr>
		<td>
		<input placeholder="E-mail Address" type="email" id="eaddr" name="eaddr" value="" placeholder="you\@domain.local">
		</td>
	</tr>
	<tr>
		<td>
		<input placeholder="Subject" type="text" id="esubj" name="esubj" value="" placeholder="RazDC Logs">
		</td>
	</tr>
	<tr>
		<td></td>
	</tr>
	<tr>
		<td><input type="submit" value="Save E-Mail Settings"></td>
	</tr>
	</table>
	</td>
</tr>
</table>
</form>
~;

# Global Log Display - DONE
#########################
$template{'update_log'} = qq~ 
<div class="table" style="margin:7px;padding:0px;border:1px #000 solid;width:90%;">
	<div class="tr barColor" >
		<div class="inline left" style="float:left;padding:7px;">Update Release: <b>[!LOGVERSION!]</b></div>
		<div class="inline right" style="float:right;padding:5px">[!LOGSTAMP!]</div>
	</div>
	<div class="tr">
		<div class="td inline left" style="padding:7px;">
		[!LOGCOMMENT!]
		</div>
	</div>
	<div class="tr">
		<div class="td inline right">
		 <input type="button" value="Use Release [!LOGVERSION!]" disabled>
		</div>
	</div>
</div>
<br>
~;
				
# Global Log Display - DONE
#########################
$template{'view_logs'} = qq~
<div class="winBlock"> 
	<div class="winSection">
		<div style="position:absolute;top:15px;left:0px;right:0px;bottom:0px;margin:10px;padding:0px;">
			<pre>
[!VIEW_LOG!]
			</pre>
		</div>
	</div>
</div>
~;

# Shutdown - DONE
#######################
$template{'shutdown'} = qq~
<form action="/cgi-bin/core.pl" method="post" onsubmit="return shutdown()" name="shutdown_form" id="shutdown_form">
<div class="table" id="shutdown_update_form">
	<div class="winBlock">
		<div class="winSection">
			Type 'SHUTDOWN' to confirm shutdown.
		</div>
	
		<div class="winSection">
			<input type="text" name="userConfimShutdown" id="userConfirmShutdown" value="">
		</div>

		<div class="winSection">
			<input type="hidden" id="do" name="do" value="sub">
			<input type="hidden" id="task" name="task" value="power_shutdown">
			<input type="hidden" id="session" name="session" value="[!SESSION!]">
			<input type="submit" style="margin:2px;" id="sendIt" value="Shutdown">
		</div>
	</div>
</div>
</form>
~;

# Restart - DONE
#########################
$template{'restart'} = qq~
<form action="/cgi-bin/core.pl" method="post" onsubmit="return restart()" name="restart_form" id="restart_form">
<div class="table" id="restart_update_form">
	<div class="winBlock">
		<div class="winSection">
			Type 'RESTART' to confirm restart.
		</div>
	
		<div class="winSection">
			<input type="text" name="userConfimRestart" id="userConfirmRestart" value="">
		</div>

		<div class="winSection">
			<input type="hidden" id="do" name="do" value="sub">
			<input type="hidden" id="task" name="task" value="power_restart">
			<input type="hidden" id="session" name="session" value="[!SESSION!]">
			<input type="submit" style="margin:2px;" id="sendIt" value="Restart">
		</div>
	</div>
</div>
</form>
~;

#
######################
