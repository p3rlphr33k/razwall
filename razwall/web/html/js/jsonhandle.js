var json;
var searchjson;
var razdc;
var razsearch;
var submenu;
var alltabs = [];
var menuString;
// NEW FETCH JSON BY PIECES:
function fetchJSON(e,astf){
 var ITEM = e;
 console.log('Check for RazDC session data.');
 if(RazSession) {
	console.log('Session exists!');
	console.log('Check for local storage.');
	if(ITEM+'JSON' in localStorage) {
		console.log('RazDC found valid '+ITEM+' data in local storage.');
		jsonString = localStorage.getItem(ITEM+'JSON');
		console.log(ITEM+' JSON retrieved from storage.');
	}
	else {
		console.log('No '+ITEM+' storage data, request from the server...');
		var xhr = new XMLHttpRequest();
		xhr.open("GET", '/cgi-bin/core.pl?do=JSON&task='+ITEM+'&session='+RazSession, astf);
		xhr.onload = function (e) {
			if (xhr.readyState === 4) {
				console.log('RazDC is accepting requests.');
				if (xhr.status === 200) {
					console.log('Requesting the '+ITEM+' data.');
					json = xhr.responseText;
					//jsonString = JSON.stringify(json);
					localStorage.setItem(ITEM+'JSON',json);
					console.log(ITEM+' JSON retrieved from server.');
				}
				else {
					console.error(xhr.statusText);
				}
			}
		};
		xhr.onerror = function (e) {
			console.log('RazDC threw an error while requesting '+ITEM+' data from server.');
			console.error(xhr.statusText);
		};
		xhr.send(null); 		
	 }
 }
 else {
		console.log('No valid session!');
		localStorage.clear(ITEM+'JSON');
 }
}

function RazSetup() {
	console.log('Building RazDC environment with retrieved data.');
	buildMenu();
	buildDash();
	RazConnectWS();
	endSplash();
	Array.max = function( array ){ return Math.max.apply( Math, array ); };
	Array.min = function( array ){ return Math.min.apply( Math, array ); };
	console.log('Open dashboard..');
	tab('dash');
	setTimeout('setupBlocks(window.innerWidth)', 500);
	console.log('Check version and updates..');
	setTimeout(function(){plax.gets('/cgi-bin/core.pl?do=sub&task=updateCheck&session='+RazSession)},10000);
}

function ADSetup() {
	console.log('Building user environment with retrieved data.');
	buildMenu();
	RazConnectWS();
	endSplash();
	Array.max = function( array ){ return Math.max.apply( Math, array ); };
	Array.min = function( array ){ return Math.min.apply( Math, array ); };
}

function buildMenu(){
 var mainMenu = JSON.parse(localStorage.getItem('MENUJSON'));
 console.log('Build main menu.');
 $('menutabs').textContent = '';
 for (i = 0; i < mainMenu.menu.length; i++) {
	var newDiv = document.createElement('div');
	newDiv.setAttribute('class','tab field-tip');
	newDiv.setAttribute('id',mainMenu.menu[i].id);
	newDiv.setAttribute('onclick',mainMenu.menu[i].onclick);
	var newImg = document.createElement('img');
	newImg.setAttribute('src',mainMenu.menu[i].img);
	newImg.setAttribute('alt',mainMenu.menu[i].alt);
	var newSpan = document.createElement('span');
	newSpan.setAttribute('class','tip-content');
	var newTip = document.createTextNode(mainMenu.menu[i].alt);
	newSpan.appendChild(newTip);
	newDiv.appendChild(newImg);
	newDiv.appendChild(newSpan);
	$('menutabs').appendChild(newDiv);
	alltabs.push(mainMenu.menu[i].id);
 }
}

function buildDash() {
var dashboard = JSON.parse(localStorage.getItem("DASHJSON"));
if(dashboard) {
console.log('Building dashboard.');
 $('centerPins').textContent = '';
 for (i = 0; i < dashboard.widgets.length; i++) {
	var newTable = document.createElement('table');
	newTable.setAttribute('border','0');
	newTable.setAttribute('cellpadding','0');
	newTable.setAttribute('cellspacing','0');
	newTable.setAttribute('class', 'block');
	var newTR1 = document.createElement('tr');
	var newTD1 = document.createElement('td');
	newTD1.setAttribute('class', 'barColor');
	newTD1.setAttribute('style', 'height:30px;');
	var newTitle ='&emsp;' + dashboard.widgets[i].title;
	newTD1.insertAdjacentHTML('beforeend', newTitle);
	newTR1.appendChild(newTD1);
	newTable.appendChild(newTR1);
	var newTR2 = document.createElement('tr');
	var newTD2 = document.createElement('td');
	newTD2.setAttribute('style', 'padding:5px;');
	if(dashboard.widgets[i].content) {
		var newContent = plax.gets(dashboard.widgets[i].content);
		newTD2.insertAdjacentHTML('beforeend', newContent);
	}
	if(dashboard.widgets[i].html) {
		var newContent = dashboard.widgets[i].html;
		newTD2.insertAdjacentHTML('beforeend', newContent);
	}
	if(dashboard.widgets[i].links) {
		for (j = 0; j < dashboard.widgets[i].links.length; j++) {
			var newLink = document.createElement('A');
			newLink.setAttribute('href', dashboard.widgets[i].links[j].link);
			newLink.setAttribute('onclick', dashboard.widgets[i].links[j].onclick);
			
			var LinkText = document.createTextNode( dashboard.widgets[i].links[j].text );
			newLink.appendChild(LinkText);
			newTD2.appendChild(newLink);
			var newSpace = document.createTextNode(' | ');
			newTD2.appendChild(newSpace);
		}
		var newBR = document.createElement('br');
		newTD2.appendChild(newBR);
	}
	if(dashboard.widgets[i].image) {
		var newImage = document.createElement('img');
		newImage.src = dashboard.widgets[i].image;
		newImage.id = dashboard.widgets[i].container;
		newTD2.appendChild(newImage);
	}
	else {
	newTD2.id = dashboard.widgets[i].container;
	}
	newTR2.appendChild(newTD2);
	newTable.appendChild(newTR2);
	$('centerPins').appendChild(newTable);
 }
}
    cpucanvas = $('cpu-chart'),cpuseries = new TimeSeries();
	memcanvas = $('mem-chart'),memseries = new TimeSeries();
	cpuchart.addTimeSeries(cpuseries, {lineWidth:2.3,strokeStyle:'#05d6fa',fillStyle:'rgba(103,224,31,0.61)'});
	memchart.addTimeSeries(memseries, {lineWidth:2.3,strokeStyle:'#f8c807',fillStyle:'rgba(194,188,61,0.61)'});
	cpuchart.streamTo(cpucanvas, 0);
	memchart.streamTo(memcanvas, 0);
}

function subMenu(ITEM) {
 console.log('Fetching '+ITEM+' data from local storage.');
 $('results').textContent = '';
 submenu = JSON.parse(localStorage.getItem(ITEM+'JSON'));
 var MenuIDS = [];
 var MenuJS = "";
 
 if(!submenu) { 
	console.log(ITEM+' not found in storage, fetching now..');
	fetchJSON(ITEM); 
	submenu = JSON.parse(localStorage.getItem(ITEM+'JSON'));
 }
	// <ul id="SystemMenu" class="treeview">
	var newUL = document.createElement('ul');
	newUL.setAttribute('class','treeview');
	newUL.setAttribute('id',submenu.text+'Menu');
	var newMenuID = submenu.text+'Menu';
	MenuIDS.push(newMenuID);
	
	for(i=0; i<submenu.options.length; i++) {
		//<li>Power
		var newLI = document.createElement('li');
		newLI.setAttribute('class','submenu');
		var liID = submenu.options[i].text;
		liID = liID.replace(/\s/g, '');
		newLI.setAttribute('id',liID);
		
		var LIText = document.createTextNode(submenu.options[i].text);
		newLI.appendChild(LIText);
		newUL.appendChild(newLI);
		
		var folder = submenu.options[i].options;
		if(folder) {
			//<ul rel="open">
			var subUL = document.createElement('ul');
			subUL.setAttribute('rel','open');
			for(j=0; j<folder.length; j++) {
				//<li>Shutdown</li>
				var LinkText = folder[j].text;
				var LinkClick = folder[j].onclick;
				var LinkHref = folder[j].href;
				var subLI = document.createElement('li');
				
				subLI.setAttribute('onclick', LinkClick);
				var subText = document.createTextNode(' '+LinkText);
				
				if(folder[j].icon) { 
					var LinkIcon = folder[j].icon; 
					var subIcon = document.createElement('img');
					subIcon.setAttribute('src',LinkIcon);
					subIcon.setAttribute('width','16px');
					subIcon.setAttribute('height','16px');
					// add image to <li>
					subLI.appendChild(subIcon);
				}
				// add text to <li>
				subLI.appendChild(subText);
				// add <li> to <ul>
				subUL.appendChild(subLI);
				// add submenu <ul> to main menu <li>
				newLI.appendChild(subUL);
				// push all results to div
				$('results').appendChild(newUL);
			}
		}
		else { // only create link
			var newLI = document.createElement('li');
			newLI.setAttribute('onclick',submenu.onclick);
			var LIText = document.createTextNode(submenu.text);
			newLI.appendChild(LIText);
			newUL.appendChild(newLI);
			$('results').appendChild(newUL);
		}
		//if(ITEM == 'Users' && submenu.options[i].text !== 'Options') {
		//	dynamicMenu(submenu.options[i].text,liID);
		//}
	}
 // append javascript to results to allow menus to collapse
 if(MenuIDS.length > 0) {
	var JStext;
	var newJS = document.createElement('script');
	for (z = 0; z < MenuIDS.length; z++) {
		JStext = 'ddtreemenu.createTree("' + MenuIDS[z] + '", false, 30);\n';
		newJS.text += JStext;
		//ddtreemenu.createTree(MenuIDS[z], false, 30);
	}
	newJS.text += JStext;
	$('results').appendChild(newJS);
 }
 if (!window.matchMedia('screen and (max-width: 768px)').matches) {
	if($('search')) { $('search').focus(); }
 }
}

function dynamicMenu(G,E) {
		menuString='';
		var xhr = new XMLHttpRequest();
		xhr.open("GET", '/cgi-bin/core.pl?do=JSON&task=GROUP&gid='+G+'&session='+RazSession, false);
		xhr.onload = function (e) {
			if (xhr.readyState === 4) {
				console.log('RazDC is accepting requests.');
				if (xhr.status === 200) {
					console.log('Requesting the menu \''+G+'\'.');
					json = xhr.responseText;
					menuString = JSON.parse(json);
					//localStorage.setItem(ITEM+'JSON',json);
					console.log('Menu retrieved from server.');
				}
				else {
					console.error(xhr.statusText);
				}
			}
		};
		xhr.onerror = function (e) {
			console.log('RazDC threw an error while requesting '+G+' menu from server.');
			console.error(xhr.statusText);
		};
		xhr.send(null);
		
			var subUL = document.createElement('ul');
			subUL.setAttribute('rel','open');
			//subUL.setAttribute('style','display: block;');
			//console.log('Length: '+menuString.menu.length);
			for(j=0; j<menuString.menu.length; j++) {
				//<li>Shutdown</li>
				var LinkText = menuString.menu[j].text;
				var LinkClick = menuString.menu[j].onclick;
				var LinkHref = menuString.menu[j].href;
				var subLI = document.createElement('li');
				
				subLI.setAttribute('onclick', LinkClick);
				var subText = document.createTextNode(' '+LinkText);
				
				if(menuString.menu[j].icon) { 
					var LinkIcon = menuString.menu[j].icon; 
					var subIcon = document.createElement('img');
					subIcon.setAttribute('src',LinkIcon);
					subIcon.setAttribute('width','16px');
					subIcon.setAttribute('height','16px');
					// add image to <li>
					subLI.appendChild(subIcon);
				}
				// add text to <li>
				subLI.appendChild(subText);
				// add <li> to <ul>
				subUL.appendChild(subLI);
				//console.log(subUL);
				// push all results to li by ID
				$(E).appendChild(subUL);
			}
			
}
function notifyMenu() {
	if($('notifyframe').style.display === 'block') {
		$('notifyframe').setAttribute('style', 'display: none;');
	}
	else {
		$('notifyframe').setAttribute('style', 'display: block;');
	}
}

function OLDfetchSearch(){
 console.log('Check for RazDC search data.');
 if(RazSession) {
	console.log('Search exists!');
		var xhr = new XMLHttpRequest();
		xhr.open("GET", '/cgi-bin/core.pl?do=JSON&task=SEARCH&session='+RazSession, true);
		xhr.onload = function (e) {
			if (xhr.readyState === 4) {
				console.log('RazDC is accepting requests.');
				if (xhr.status === 200) {
					console.log('Requesting the search data.');
					searchjson = xhr.responseText;
					razsearch = JSON.parse(xhr.responseText);
					//localStorage.setItem("RDCJSON",JSON.stringify(searchjson));
					console.log('SEARCH retrieved from server.');
					//console.log(razsearch);
					//ADD ADDITIONAL CALLS HERE
				}
				else {
					console.error(xhr.statusText);
				}
			}
		};
		xhr.onerror = function (e) {
			console.log('RazDC threw an error while requesting search data from server.');
			console.error(xhr.statusText);
		};
	xhr.send(null); 
 }
 else {
		console.log('No valid session!');
		window.open('/index.html','_top');
 }
}
