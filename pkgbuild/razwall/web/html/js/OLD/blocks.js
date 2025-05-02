 var colWidth = 485;
 var padWidth = 0;
 var margin = 7;
 var borWidth = 0;
 
 function setupBlocks(WinW) {
 	var blocks = [];
 	var colCount = Math.floor(WinW/(colWidth+(margin*2)+(borWidth*2)+(padWidth*2)));
 	for(var i=0;i<colCount;i++)
 		{
 		blocks.push(margin);
 		}
 	positionBlocks(blocks);
 	}
 
 function positionBlocks(MyARRAY) {
 var blocks = MyARRAY;
 var winBlock = MygetElementsByClass('block',document,'table');
 
 for (var i = 0; i < winBlock.length; i++) {
         var blockHeight = winBlock[i].clientHeight;
 		var min = Array.min(blocks);
 		var newmin = min+50;
 		var max = Array.max(blocks);
 		var myWidth = window.innerWidth;
 		var pinCols = (myWidth/colWidth)+(margin*2);
 
 		document.getElementById('centerPins').style.height=max+'px';
 
 		var index = blocks.indexOf(min); 
 		var leftPos = margin+(index*(colWidth+(margin*3)));
         	winBlock[i].setAttribute('style', 'position:absolute; left:'+leftPos+'px; top:'+newmin+'px');
 		blocks[index] = min+blockHeight+margin;  //min+colMargin;
 		//alert('Smallest: '+min+' Left: '+leftPos+' Column: '+index+' Blocks: '+blocks);
 	};
 	}
 
 function MygetElementsByClass(searchClass,node,tag) {
 	var classElements = new Array();
 	if ( node == null )
 		node = document;
 	if ( tag == null )
 		tag = '*';
 	var els = node.getElementsByTagName(tag);
 	var elsLen = els.length;
 	var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
 	for (i = 0, j = 0; i < elsLen; i++) {
 		if ( pattern.test(els[i].className) ) {
 			classElements[j] = els[i];
 			j++;
 		}
 	}
 	return classElements;
 }