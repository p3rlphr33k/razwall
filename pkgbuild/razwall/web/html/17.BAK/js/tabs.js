document.addEventListener('mousemove', function (event) {
    if (window.event) { // IE fix
        event = window.event;
    }

    var mousex = event.clientX; //horizontal
    var mousey = event.clientY; //vertical
    var mywidth = screen.width;
    var myheight = screen.height;
	
    newy = mousey-110+'px'; // VERTICAL
	newx = mousex-70+'px'; // HORIZONTAL
    $('menutabs').style.backgroundPosition = '-10px ' + newy;
	$('headContainer').style.backgroundPosition = newx + ' 7px';
	
	var z = document.getElementsByClassName("barColor");
	var q;
	for (q = 0; q < z.length; q++) {
	  z[q].style.backgroundPosition = -mousex/10 + 'px '  + -mousey/10 + 'px';
	}

}, false);

$=function(e){if(e){if(typeof e=='string')e=document.getElementById(e);}else{e=document.body;}return e}

function tab(e,getThis) {
	// MOVED TO JSONHANDLE TO GENERATE DYNAMICALLY BASED ON PERMISSIONS IN JSON CONFIG
	//var alltabs = ['dash','system','server','users','logs','power','exit'];
	var tabsLength = alltabs.length;
	for (var i = 0; i < tabsLength; i++) {
		if(e == alltabs[i]) {
			if($(e).className == 'tab field-tip') {
				$(alltabs[i]).className = 'selected field-tip';
				
				if(e == 'dash') {
					$('dashboard').style.display='block';
					$('menuframe').style.display = 'none'; 
					$('notifyframe').style.display='none';
				} 
				else { 
					if($('dashboard')) {$('dashboard').style.display='none';}
					$('menuframe').style.display='block';
					$('notifyframe').style.display='none';
				}
			}
			else { 
				$(e).className = 'tab field-tip'; 
				$('menuframe').style.display = 'none'; 
				if($('dashboard')) { $('dashboard').style.display = 'none'; }
				$('notifyframe').style.display='none';
			}
		}
		else { $(alltabs[i]).className = 'tab field-tip'; }	
	}
}
