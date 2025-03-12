var winid=100;
var Winz=100;
var WL=100;
var WT=100;
var curHeight=0
var curWidth=0
var curPos=0
var newPos=0
var mouseStatus='up'
var ie = document.all;
var ns = document.getElementById && !ie;
var isdrag = false;
var x,y;
var dobj;

function $(e){if(typeof e=='string'){e=document.getElementById(e);}return e};
function hideShow(id){
		e=$(id);
		if(e.style.display=="none"){
			e.style.display="block";
		}
		else {
		e.style.display="none"
		}
	};
function up(W){
	Winz++;
	$(W).style.zIndex=Winz;
}

// ICON,TITLE,APP,WIDTH,HEIGHT,TAB
function win(IC,TI,PA,WI,HE,TA) {
Winz++;
winid++;
WT=WT+10;
WL=WL+10;
d=document;

if (window.matchMedia('screen and (max-width: 768px)').matches) {
	winid = 0;
	where = $('dataframe');
	// close preview mobile window before creating a new one!
	if($('MOBILEWIN')) {
		cWin('MOBILEWIN','tray'+winid)
	}
	if(!$('MOBILEWIN')) {
	newWin = d.createElement('div');
	newWin.setAttribute('id','MOBILEWIN');
	newWin.style.width='100%';
	newWin.style.height='100%';
	newWin.style.position='absolute';
	newWin.style.top='0px';
	newWin.style.left='0px';
	newWin.style.zindex='1000';
	winTable = d.createElement('table');
	winTbody = d.createElement("tbody");
	row1 = d.createElement("tr");
	cell1 = d.createElement("td");
	cell1.innerHTML = '<img src=\"/images/R.png\" onClick=\"rWin(\''+PA+'\', \'content'+winid+'\');\" onMouseout=\"this.src=\'/images/R.png\';\" onMouseover=\"this.src=\'/images/R2.png\';\" style=\"float:left;cursor:pointer;\"><b class=\'button\'><img src=\"/images/x.png\" onClick=\"cWin(\'MOBILEWIN\',\'tray'+winid+'\')\" onMouseout=\"this.src=\'/images/x.png\';\" onMouseover=\"this.src=\'/images/x2.png\';\"></b>';
	row2 = d.createElement("tr");
	cell2 = d.createElement("td");
	cell2.setAttribute('valign','top');
	cell2.setAttribute('align','left');
	cell2.innerHTML = '<div id="content'+winid+'" style="background:#ffffff;border:0px;margin:0px;padding:0px;position:absolute;top:38px;left:0px;right:0px;bottom:0px;overflow:auto;"><br><center><img src="/images/loading.gif" height="50px"><br>Loading...</center></div>';		
	winTable.setAttribute('cellspacing','0px');
	winTable.setAttribute('cellpadding','0px');
	winTable.setAttribute('border','0px');
	winTable.setAttribute('width','100%');
	winTable.setAttribute('height','100%');
	cell1.setAttribute('class','barColor');
	row1.appendChild(cell1);
	row2.appendChild(cell2);	
	winTbody.appendChild(row1);
	winTbody.appendChild(row2);
	winTable.appendChild(winTbody);
	newWin.appendChild(winTable);
	where.appendChild(newWin);
	plax.fadeIn('MOBILEWIN',1000,0);
	}
	// LOAD CONTENT REQUESTED INTO WINDOW: 
	plax.update(PA, 'content'+winid);
}
else {
	where = d.body;
	newWin = d.createElement('div');
	newWin.setAttribute('id','dragable'+winid);
	newWin.setAttribute('class','drsElement');
	newWin.setAttribute('style','opacity:0.0;box-shadow: 0px 10px 40px 3px rgba(0, 0, 0, 0.6), 0px -1px 0px #595959;border:1px #696969 solid;');
	newWin.style.width=WI+'px';
	newWin.style.height=HE+'px';
	newWin.style.position='absolute';
	newWin.style.top=WT+'px';
	newWin.style.left=WL+'px';
	newWin.style.zindex=Winz;
	winTable = d.createElement('table');
	winTbody = d.createElement("tbody");
	row1 = d.createElement("tr");
	cell1 = d.createElement("td");
	cell1.setAttribute('ondblClick','minmax('+HE+','+winid+')');
	cell1.innerHTML = '<img src=\"/images/R.png\" onClick=\"rWin(\''+PA+'\', \'content'+winid+'\');\" onMouseout=\"this.src=\'/images/R.png\';\" onMouseover=\"this.src=\'/images/R2.png\';\" style=\"float:left;cursor:pointer;\"><b class="windowtitle">'+TI+'</b><b class=\'button\'><img src=\"/images/x.png\" onClick=\"cWin(\'dragable'+winid+'\',\'tray'+winid+'\')\" onMouseout=\"this.src=\'/images/x.png\';\" onMouseover=\"this.src=\'/images/x2.png\';\"></b>';
	row2 = d.createElement("tr");
	cell2 = d.createElement("td");
	cell2.setAttribute('valign','top');
	cell2.setAttribute('align','left');
	cell2.innerHTML = '<div id="content'+winid+'" style="border:0px;margin:0px;padding:0px;position:absolute;top:38px;left:0px;right:0px;bottom:0px;overflow:auto;"><br><center><img src="/images/loading.gif" height="50px"><br>Loading...</center></div>';		
	winTable.setAttribute('cellspacing','0px');
	winTable.setAttribute('cellpadding','0px');
	winTable.setAttribute('border','0px');
	winTable.setAttribute('width','100%');
	winTable.setAttribute('height','100%');
	cell1.setAttribute('class','drsMoveHandle barColor');
	row1.appendChild(cell1);
	row2.appendChild(cell2);	
	winTbody.appendChild(row1);
	winTbody.appendChild(row2);
	winTable.appendChild(winTbody);
	newWin.appendChild(winTable);
	where.appendChild(newWin);
	fobj = 'dragable'+winid;
	plax.fadeIn(fobj,1000,0);
	// LOAD ICON IN TASKBAR: - NOT USED
	// loadDoc(PA,'content'+i);
	// LOAD CONTENT REQUESTED INTO WINDOW: 
	plax.update(PA, 'content'+winid);
	// MOVE WINDOW UP ONE ORDER
	up('dragable'+winid);
}
// CLOSE THE MENU TAB
if(TA) {
	tab(TA);
}
}

function cWin(TheWin,TheTray) { // TRAY/TASKBAR IS NOT CURRENTLY IN USE BUT WE MIGHT IN THE FUTURE!
	//WT=WT-10;
	//WL=WL-10;
	if(TheWin === 'MOBILEWIN') {
		$('dataframe').removeChild($(TheWin));
	}
	else {
		plax.fadeOut(TheWin,1000,0);
		d=document;
		d.body.removeChild($(TheWin));
	}
}

function minmax(defaultHeight,WinID) {
	d=document;
	thiswin=d.getElementById('dragable'+WinID);
	vis=d.getElementById('content'+WinID);
	currentHeight = thiswin.style.height;
	
	if(currentHeight === '32px') {
		vis.style.display = "block";
		thiswin.style.height=defaultHeight+'px';
	}
	else {
		vis.style.display = "none";
		thiswin.style.height='32px';
	}
}
function rWin(PA,ID) {
	$(ID).innerHTML = '<br><center><img src="/images/loading.gif" height="50px"><br>Loading...</center>';
	if($(ID)) { plax.update(PA,ID); }
}