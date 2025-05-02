#
#        +-----------------------------------------------------------------------------+
#        | RazWall Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2024 RazWall                                                  |
#        |                                                                             |
#        | This program is free software; you can redistribute it and/or               |
#        | modify it under the terms of the GNU General Public License                 |
#        | as published by the Free Software Foundation; either version 2              |
#        | of the License, or (at your option) any later version.                      |
#        |                                                                             |
#        | This program is distributed in the hope that it will be useful,             |
#        | but WITHOUT ANY WARRANTY; without even the implied warranty of              |
#        | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               |
#        | GNU General Public License for more details.                                |
#        |                                                                             |
#        | You should have received a copy of the GNU General Public License           |
#        | along with this program; if not, write to the Free Software                 |
#        | Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. |
#        | http://www.fsf.org/                                                         |
#        +-----------------------------------------------------------------------------+
#
# RazWall Templates
# Modified: 12-17-2024
#
# This is the core HTML Template file.
######################################################################################################################

# NOTHING
#####################################
$template{'nothing'} = qq~
Nothing here yet.
~;

# Open Header
#####################################
$template{'openHeader'} = qq~
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>RazWall Firewall</title>

<link rel="shortcut icon" href="/favicon.ico" />
<link rel="stylesheet" type="text/css" href="/css/SocketStatus.css">
<link rel="stylesheet" type="text/css" href="/css/razwall-main.css">
<link rel="stylesheet" type="text/css" href="/css/razwall-slider.css">
<link rel="stylesheet" type="text/css" href="/css/razwall-form.css">
<link rel="stylesheet" type="text/css" href="/css/razwall-rows.css">

<link rel="stylesheet" type="text/css" href="/css/tiles.css">
<link rel="stylesheet" type="text/css" href="/css/smoothie.css"/>

<script type="text/javascript" src="/js/websocket.js"></script>   
<script language="javascript" src="/js/smoothie.js"></script>
<script type="text/javascript" src="/js/consolelogger.js"></script>
<!-- END OPEN HEADER -->
~;

# Close Header
#####################################
$template{'closeHeader'} = qq~
<!-- BEGIN CLOSE HEADER-->
</head>
<body>

<!-- Preload audio clips -->
<span id="dummy" style="display:none;height:0px;width:0px;">
	<audio id="incoming" src="/sounds/sound_1.mp3" preload="true" autobuffer=""></audio>
	<audio id="outgoing" src="/sounds/sound_2.mp3" preload="true" autobuffer=""></audio>
	<audio id="login" src="/sounds/sound_3.mp3" preload="true" autobuffer=""></audio>
	<audio id="logout" src="/sounds/sound_4.mp3" preload="true" autobuffer=""></audio>
	<audio id="razbot" src="/sounds/sound_5.mp3" preload="true" autobuffer=""></audio>
	<audio id="error" src="/sounds/sound_6.mp3" preload="true" autobuffer=""></audio>
</span> 

  <header>
    <div>
      <div class="logo">
		<img src="" alt="Socket" id="socketStatus" onclick="RazConnectWS(); return false;"/><img src="/images/2025/razwall_light.png" alt="RazWall" id="razwall" class="theme-icon"/>
	  </div>
    </div>
	
	<div class="version">
		Appliance <span  id="systeminformationplugin-appliance"></span><br>
	    Version <span  id="systeminformationplugin-version"></span><br>
	    Kernel <span  id="systeminformationplugin-kernel"></span><br>
	    Uptime <span  id="systeminformationplugin-uptime"></span><br>
	</div>
	
    <div class="status-bar">
	
	<!-- Uplink display -->
	  
	<div id="UpLinkInformationPlugin">
		<script type="text/javascript">
		var UPLINK_RECONNECT = 'reconnect';
		</script>
		<div id="uplinkinformationplugin-information"></div>	
		<div><i>&rarr; = F/O</i></div>
	</div>

	</div>
    
  </header>
  <!-- Add Overlay titles to graphs -->
  <div class="graphs">
    <div class="graph">
		<div class="dashboard-graph-title">Incoming</div>
		<canvas id="rx-chart"></canvas>
	</div>
    <div class="graph">
		<div class="dashboard-graph-title">Outgoing</div>
		<canvas id="tx-chart"></canvas>
	</div>
  </div>
  <!-- END CLOSE HEADER-->
  <!-- START MAIN CONTENT -->
  <main>
~;

# Footer
#####################################
$template{'footer'} = qq~
  <!-- BEGIN FOOTER -->
  <script>
	function toggleTheme() {
	  document.body.classList.toggle('light-theme');
	  var isLight = document.body.classList.contains('light-theme');
	  localStorage.setItem('theme', isLight ? 'dark' : 'light');

	  // Swap icons using ID
	  document.querySelectorAll('.theme-icon').forEach(icon => {
		var id = icon.id; 
		var curTheme = isLight ? 'dark' : 'light';
		icon.src = '/images/2025/' + id + '_' + curTheme + '.png';
	  });
	}
	
	function toggleDrawer() {
      const nav = document.getElementById('tileNav');
      const arrow = document.getElementById('drawer-arrow');
      if (nav.classList.contains('open')) {
        nav.classList.remove('open');
        arrow.textContent = '▲';
      } else {
        nav.classList.add('open');
        arrow.textContent = '▼';
      }
    }
	

    window.onload = () => {
      var saved = localStorage.getItem('theme');
      if (saved === 'dark') {
        document.body.classList.add('light-theme');
      }
    };
	
	var rxchart = new SmoothieChart({millisPerPixel:100,grid:{fillStyle:'transparent'},labels:{showIntermediateLabels:true},tooltip:true,tooltipLine:{strokeStyle:'#bbbbbb'},horizontalLines:[{color:'#ffffff',lineWidth:1,value:0},{color:'#880000',lineWidth:2,value:3333},{color:'#880000',lineWidth:2,value:-3333}]}),
    rxcanvas = document.getElementById('rx-chart'),
    netRXseries = new TimeSeries();
	
	var txchart = new SmoothieChart({millisPerPixel:100,grid:{fillStyle:'transparent'},labels:{showIntermediateLabels:true},tooltip:true,tooltipLine:{strokeStyle:'#bbbbbb'},horizontalLines:[{color:'#ffffff',lineWidth:1,value:0},{color:'#880000',lineWidth:2,value:3333},{color:'#880000',lineWidth:2,value:-3333}]}),
    txcanvas = document.getElementById('tx-chart'),
    netTXseries = new TimeSeries();

	rxchart.addTimeSeries(netRXseries, {lineWidth:2,strokeStyle:'#00ff00',fillStyle:'rgba(0,255,0,0.20)',interpolation:'bezier'});
	rxchart.streamTo(rxcanvas, 5000);

	txchart.addTimeSeries(netTXseries, {lineWidth:2,strokeStyle:'#ff0000',fillStyle:'rgba(255,0,0,0.20)',interpolation:'bezier'});
	txchart.streamTo(txcanvas, 5000);

	var RazIP = '$thisAddress';
	RazConnectWS();
	
	function resizeCanvas(canvas) {
	// Set the internal resolution to match the displayed size
	canvas.width = canvas.offsetWidth;
	canvas.height = canvas.offsetHeight;
	}

	// Call it initially and on resize for both canvases
	function updateCanvases() {
	  resizeCanvas(rxcanvas);
	  resizeCanvas(txcanvas);
	}
	
	// Initial resize
	updateCanvases();

	// Update on window resize
	window.addEventListener('resize', updateCanvases);
  </script>
	
</body>
</html>
<!-- END FOOTER -->
~;

# Loading Window Content
#####################################
$template{'loading'} = qq~
<br><center><img src="/images/2025/razwall_loading.gif" height="50px"><br>Loading...</center>
~;

# Dashboard
#####################################
$template{'dashboard'} = qq~

~;



# Network Setup Wizard Template 1
############################################################################################################
$template{'netwiz1_error'} = qq~
    <!-- Fieldset: Error Code -->
    <fieldset class="incoming">
      <legend>Error:</legend>
      <div class="incoming-grid">
        <div class="incoming-left fieldgroup">
          <label>
		  <span class="label-text"><font color="red">[!ERROR_MESSAGE!]</font></span>
		  </label>
		</div>
	  </div>
	</fieldset>
~;

$template{'netwiz1_loop1'} = qq~
		  <span class="label-text">
                <input type="radio" name="NETWORK_TYPE" value="[!NETNAME!]" [!NETSELECTED!]>&nbsp;[!NETCAPTION!]</input>
		  </span>
~;

$template{'netwiz1_loop2'} = qq~
		<span class="label-text">
			<div class="network_description [!NETNAME!]" style="display: none;">
				<span style="font-weight: bold;">[!NETCAPTION!]</span>
				<br>
				<span>[!NETDESC!]</span>
			</div>
		 </span>
~;

$template{'netwiz1'} = qq~
<div class="editorbox" name="createrule">
  <div class="editortitle">
    <p>[!TITLE!]</p>
    <div style="clear: both;"></div>
  </div>

	[!ERROR!]

    <!-- Fieldset: Network Mode -->
    <fieldset class="incoming">
      <legend>[!MODE_LEGEND!]</legend>
      <div class="incoming-grid">
        <div class="incoming-left fieldgroup">
          
		  <label>
		  [!NETLOOP1!]
		  </label>
		  
		</div>
		<div class="incoming-left fieldgroup">
		
		  <label>
		  [!NETLOOP2!]
		  </label>
		  
		</div>
	  </div>
	</fieldset>


<br style="clear:both">

NW_VAL_NETWORK_LOOP

<!-- HIDEABLE DIV -->
<div class="wan_types TMPL_VAR NAME=NETWORK_LOOP_NAME" style="display: none;">

    <!-- Fieldset: Network Mode -->
    <fieldset class="incoming">


	  <legend>TMPL_VAR NAME=NETWORK_LOOP_TITLE</legend> -> <legend>Uplink type (<span style="color: red;">WAN</span> zone)</legend>
	  </TMPL_IF>
	
	 <div class="incoming-grid">
     <div class="incoming-left fieldgroup">

		<label>
		<form action="TMPL_VAR NAME=NW_VAL_self" method="post">
        <input type="hidden" name="session_id" value="TMPL_VAR NAME=NW_VAL_session_id">
        <input type="hidden" name="step" value="TMPL_VAR NAME=NW_VAL_step">
        
		TMPL_IF EXPR="NETWORK_LOOP_WAN_ITEM ne ''"
        <input type="hidden" name="WAN_TYPE" value="TMPL_VAR NAME=NETWORK_LOOP_WAN_ITEM">

			
		    TMPL_LOOP NAME=NETWORK_LOOP_WAN_ITEMS
			<span class="label-text">
				<input type="radio" name="WAN_TYPE" value="TMPL_VAR NAME=WAN_LOOP_NAME" TMPL_VAR NAME=WAN_LOOP_SELECTED>&nbsp;TMPL_VAR NAME=WAN_LOOP_CAPTION</input>
			</span>
			TMPL_LOOP
		</label>

	 </div>
	   
	 <div class="incoming-left fieldgroup">
	
		<label>
			TMPL_IF EXPR="NETWORK_LOOP_NAME eq 'ROUTED'"
				<span class="label-text">Hardware information</span>
				<span class="label-text">Number of interfaces</span>
				<span class="label-text">[!IF_COUNT!]></span>
			TMPL_IF
        </label>
      
   	 </div>
     </div>
	  
TMPL_IF
		<br style="clear:both">
        
		<div style="padding-left: 10px;">
            <input type="submit" name="cancel" value="TMPL_VAR NAME=nw_cancel" class="btn">
            &nbsp;
            <input type="submit" name="next" value="TMPL_VAR NAME=nw_next" class="btn">
        </div>
		</form>

	</fieldset>
</div>
<!-- END HIDEABLE DIV -->

TMPL_LOOP

    <br style="clear: both;">
</div>
~;

############################################################################################################
# Network Setup Wizard Template 2
#####################################
$template{'netwiz2'} = qq~

~;

# Network Setup Wizard Template 3
#####################################
$template{'netwiz3'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>

<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<TMPL_IF EXPR="NW_VAL_warning_message ne ''">
  <br>
  <font color="red"><TMPL_VAR NAME=NW_VAL_warning_message></font>
</TMPL_IF>
<br>

<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">

  <table border="0" class="none" columns="5">
    <tr>
      <td colspan="3"><b><font color="green"><TMPL_VAR NAME=nw_lan></font></b> <font color="#666666">(<TMPL_VAR NAME=nw_lan_descr>)</font>:
      </td>
    <tr>
    <tr>
      <td colspan="2">
          <input name="DHCP_ENABLE_LAN" type="checkbox" value="on" style="vertical-align: middle; position: relative;" <TMPL_VAR NAME=NW_VAL_DHCP_ENABLE_LAN> />
           <TMPL_VAR NAME=nw_dhcp_enable>
      </td>
    <tr>

    <tr>
      <td style="width: 100px;"><TMPL_VAR NAME=nw_ip>:</td>
      <td style="width: 150px;">
        <input type="text" name="DISPLAY_LAN_ADDRESS" value="<TMPL_VAR NAME=NW_VAL_DISPLAY_LAN_ADDRESS>" size="15">
      </td>
      <td style="width: 10px;">&nbsp;</td>
      <td style="width: 100px;"><TMPL_VAR NAME=nw_mask>:</td>
      <td>
        <select name="DISPLAY_LAN_NETMASK">
  <TMPL_LOOP NAME=NW_VAL_DISPLAY_LAN_NETMASK_LOOP>
          <option value="<TMPL_VAR NAME=MASK_LOOP_VALUE>" <TMPL_VAR NAME=MASK_LOOP_SELECTED>><TMPL_VAR NAME=MASK_LOOP_CAPTION></option>
  </TMPL_LOOP>
        </select>
      </td>
    </tr>

    <tr>
      <td colspan="5"><TMPL_VAR NAME=nw_additionalips>:</td>
    </tr>
    <tr>
      <td colspan="5">
        <textarea cols="30" rows="3" name="DISPLAY_LAN_ADDITIONAL"><TMPL_VAR NAME=NW_VAL_DISPLAY_LAN_ADDITIONAL></textarea>
      </td>
    </tr>

    <tr>
      <td colspan="5">&nbsp;</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_interface>:</td>
      <td colspan="4">&nbsp;</td>
    </tr>
    <tr>
      <td colspan="5">
        <table>
          <tr>
            <td>&nbsp;</td>
            <td align="center"><b><TMPL_VAR NAME=nw_port></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_link></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_description></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_mac></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_device></b></td>
          </tr>

  <TMPL_LOOP NAME=NW_VAL_IFACE_LAN_LOOP>
          <tr class="<TMPL_VAR NAME=DEV_LOOP_BGCOLOR>">
            <td bgcolor="<TMPL_VAR NAME=DEV_LOOP_ZONECOLOR>">
            <TMPL_IF EXPR="(DEV_LOOP_CHECKED eq 'checked') and (DEV_LOOP_DISABLED eq 'disabled')">
                <input name="LAN_DEVICES" type="hidden" value="<TMPL_VAR NAME=DEV_LOOP_NAME>">
            </TMPL_IF>
            <TMPL_IF EXPR="DEV_LOOP_HIDE eq 'hide'">
              &nbsp;
            <TMPL_ELSE>
              <input name="LAN_DEVICES" type="checkbox" value="<TMPL_VAR NAME=DEV_LOOP_NAME>" <TMPL_VAR NAME=DEV_LOOP_CHECKED> <TMPL_VAR NAME=DEV_LOOP_DISABLED>>
            </TMPL_IF>
            </td>
            <td align="center"><TMPL_VAR NAME=DEV_LOOP_PORT></td>
            <td>
                <img src="/images/<TMPL_VAR NAME=DEV_LOOP_LINKICON>.png" title="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>" alt="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>">
            </td>
            <td><TMPL_VAR NAME=DEV_LOOP_SHORT_DESC>
                <a href="javascript:void(0);" onmouseover="return overlib('<TMPL_VAR NAME=DEV_LOOP_DESCRIPTION>', STICKY, MOUSEOFF);" onmouseout="return nd();">?</a>
            </td>

            <td><TMPL_VAR NAME=DEV_LOOP_MAC></td>
            <td><TMPL_VAR NAME=DEV_LOOP_DEVICE></td>
          </tr>
  </TMPL_LOOP>
        </table>
      </td>
    </tr>

  <tr>
    <td colspan="5">&nbsp;</td>
  </tr>
  <tr>
    <td colspan="5">&nbsp;</td>
  </tr>
<!--
  <TMPL_IF NW_VAL_HAVE_DMZ>
    <tr>
      <td colspan="5"><b><font color="orange"><TMPL_VAR NAME=nw_dmz></font></b> <font color="#666666">(<TMPL_VAR NAME=nw_dmz_descr>)</font>:</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_ip>:</td>
      <td>
        <input type="text" name="DISPLAY_DMZ_ADDRESS" value="<TMPL_VAR NAME=NW_VAL_DMZ_ADDRESS>" size="15">
      </td>
      <td>&nbsp;</td>
      <td><TMPL_VAR NAME=nw_mask>:</td>
      <td>
        <select name="DISPLAY_DMZ_NETMASK">
  <TMPL_LOOP NAME=NW_VAL_DISPLAY_DMZ_NETMASK_LOOP>
          <option value="<TMPL_VAR NAME=MASK_LOOP_VALUE>" <TMPL_VAR NAME=MASK_LOOP_SELECTED>><TMPL_VAR NAME=MASK_LOOP_CAPTION></option>
  </TMPL_LOOP>
        </select>
      </td>
    </tr>

    <tr>
      <td colspan="5"><TMPL_VAR NAME=nw_additionalips>:</td>
    </tr>
    <tr>
      <td colspan="5">
        <textarea cols="30" rows="3" name="DISPLAY_DMZ_ADDITIONAL"><TMPL_VAR NAME=NW_VAL_DISPLAY_DMZ_ADDITIONAL></textarea>
      </td>
    </tr>

    <tr>
      <td colspan="5">&nbsp;</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_interface>:</td>
      <td colspan="4">&nbsp;</td>
    </tr>
    <tr>
      <td colspan="5">
        <table>
          <tr>
            <td>&nbsp;</td>
            <td align="center"><b><TMPL_VAR NAME=nw_port></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_link></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_description></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_mac></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_device></b></td>
          </tr>

  <TMPL_LOOP NAME=NW_VAL_IFACE_DMZ_LOOP>
          <tr class="<TMPL_VAR NAME=DEV_LOOP_BGCOLOR>">
            <td bgcolor="<TMPL_VAR NAME=DEV_LOOP_ZONECOLOR>">
            <TMPL_IF EXPR="(DEV_LOOP_CHECKED eq 'checked') and (DEV_LOOP_DISABLED eq 'disabled')">
                <input name="DMZ_DEVICES" type="hidden" value="<TMPL_VAR NAME=DEV_LOOP_NAME>">
            </TMPL_IF>
            <TMPL_IF EXPR="DEV_LOOP_HIDE eq 'hide'">
              &nbsp;
            <TMPL_ELSE>
              <input name="DMZ_DEVICES" type="checkbox" value="<TMPL_VAR NAME=DEV_LOOP_NAME>" <TMPL_VAR NAME=DEV_LOOP_CHECKED> <TMPL_VAR NAME=DEV_LOOP_DISABLED>>
            </TMPL_IF>
            </td>
            <td align="center"><TMPL_VAR NAME=DEV_LOOP_PORT></td>
            <td>
                <img src="/images/<TMPL_VAR NAME=DEV_LOOP_LINKICON>.png" title="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>" alt="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>">
            </td>
            <td><TMPL_VAR NAME=DEV_LOOP_SHORT_DESC>
                <a href="javascript:void(0);" onmouseover="return overlib('<TMPL_VAR NAME=DEV_LOOP_DESCRIPTION>', STICKY, MOUSEOFF);" onmouseout="return nd();">?</a>
            </td>

            <td><TMPL_VAR NAME=DEV_LOOP_MAC></td>
            <td><TMPL_VAR NAME=DEV_LOOP_DEVICE></td>
          </tr>
  </TMPL_LOOP>
        </table>
      </td>
    </tr>

  <tr>
    <td colspan="5">&nbsp;</td>
  </tr>
  <tr>
    <td colspan="5">&nbsp;</td>
  </tr>
  </TMPL_IF>
-->

<!--
  <TMPL_IF NAME=NW_VAL_HAVE_LAN2>
    <tr>
      <td colspan="5"><b><font color="blue"><TMPL_VAR NAME=nw_lan2></font></b> <font color="#666666">(<TMPL_VAR NAME=nw_lan2_descr>)</font>:</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_ip>:</td>
      <td>
        <input type="text" name="DISPLAY_LAN2_ADDRESS" value="<TMPL_VAR NAME=NW_VAL_LAN2_ADDRESS>" size="15">
      </td>
      <td>&nbsp;</td>
      <td><TMPL_VAR NAME=nw_mask>:</td>
      <td>
        <select name="DISPLAY_LAN2_NETMASK">
  <TMPL_LOOP NAME=NW_VAL_DISPLAY_LAN2_NETMASK_LOOP>
          <option value="<TMPL_VAR NAME=MASK_LOOP_VALUE>" <TMPL_VAR NAME=MASK_LOOP_SELECTED>><TMPL_VAR NAME=MASK_LOOP_CAPTION></option>
  </TMPL_LOOP>
        </select>
      </td>
    </tr>

    <tr>
      <td colspan="5"><TMPL_VAR NAME=nw_additionalips>:</td>
    </tr>
    <tr>
      <td colspan="5">
        <textarea cols="30" rows="3" name="DISPLAY_LAN2_ADDITIONAL"><TMPL_VAR NAME=NW_VAL_DISPLAY_LAN2_ADDITIONAL></textarea>
      </td>
    </tr>

    <tr>
      <td colspan="5">&nbsp;</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_interface>:</td>
      <td colspan="4">&nbsp;</td>
    </tr>
    <tr>
      <td colspan="5">
        <table>
          <tr>
            <td>&nbsp;</td>
            <td align="center"><b><TMPL_VAR NAME=nw_port></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_link></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_description></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_mac></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_device></b></td>
          </tr>

  <TMPL_LOOP NAME=NW_VAL_IFACE_LAN2_LOOP>
          <tr class="<TMPL_VAR NAME=DEV_LOOP_BGCOLOR>">
            <td bgcolor="<TMPL_VAR NAME=DEV_LOOP_ZONECOLOR>">
            <TMPL_IF EXPR="(DEV_LOOP_CHECKED eq 'checked') and (DEV_LOOP_DISABLED eq 'disabled')">
                <input name="LAN2_DEVICES" type="hidden" value="<TMPL_VAR NAME=DEV_LOOP_NAME>">
            </TMPL_IF>
            <TMPL_IF EXPR="DEV_LOOP_HIDE eq 'hide'">
              &nbsp;
            <TMPL_ELSE>
              <input name="LAN2_DEVICES" type="checkbox" value="<TMPL_VAR NAME=DEV_LOOP_NAME>" <TMPL_VAR NAME=DEV_LOOP_CHECKED> <TMPL_VAR NAME=DEV_LOOP_DISABLED>>
            </TMPL_IF>
            </td>
            <td align="center"><TMPL_VAR NAME=DEV_LOOP_PORT></td>
            <td>
                <img src="/images/<TMPL_VAR NAME=DEV_LOOP_LINKICON>.png" title="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>" alt="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>">
            </td>
            <td><TMPL_VAR NAME=DEV_LOOP_SHORT_DESC>
                <a href="javascript:void(0);" onmouseover="return overlib('<TMPL_VAR NAME=DEV_LOOP_DESCRIPTION>', STICKY, MOUSEOFF);" onmouseout="return nd();">?</a>
            </td>

            <td><TMPL_VAR NAME=DEV_LOOP_MAC></td>
            <td><TMPL_VAR NAME=DEV_LOOP_DEVICE></td>
          </tr>
  </TMPL_LOOP>
        </table>
      </td>
    </tr>

  <tr>
    <td colspan="5">&nbsp;</td>
  </tr>
  <tr>
    <td colspan="5">&nbsp;</td>
  </tr>
  </TMPL_IF>
-->

<!--NEW LOOP-->

  <TMPL_LOOP NAME=NW_ZONES>

	<TMPL_VAR NAME=DYN_ZONE_CODE>

  </TMPL_LOOP>

 <!--END NEW LOOP-->

    <tr>
      <td><TMPL_VAR NAME=nw_hostname>:</td>
      <td colspan="4">
        <input type="text" name="HOSTNAME" value="<TMPL_VAR NAME=NW_VAL_HOSTNAME>" size="15">
      </td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_domainname>:</td>
      <td colspan="4">
        <input type="text" name="DOMAINNAME" value="<TMPL_VAR NAME=NW_VAL_DOMAINNAME>" size="15">
      </td>
    </tr>

  </table>
  <br><br><br>

  <input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">

</form>
~;

# Network Setup Wizard Template 4 - Analog 1
#####################################
$template{'netwiz4_analog_1'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_VAR NAME=NW_VAL_subtitle>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>
<br>

<table border="0">
<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">
  <input type="hidden" name="substep" value="<TMPL_VAR NAME=NW_VAL_substep>">

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_comport>:</td>
    <td>
      <select name="COMPORT" <TMPL_VAR NAME=NW_VAL_MODEM_SELECTION>>
   <TMPL_LOOP NAME=NW_VAL_CONF_MODEMS_LOOP >
        <option value="<TMPL_VAR NAME=CONF_MODEMS_LOOP_NAME>" <TMPL_VAR NAME=CONF_MODEMS_LOOP_SELECTED>><TMPL_VAR NAME=CONF_MODEMS_LOOP_CAPTION></option>
   </TMPL_LOOP>
      </select>
      </td>
  </tr>

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_modemtype>:</td>
    <td>
      <select name="MODEMTYPE">
        <option value="modem" <TMPL_IF EXPR="NW_VAL_MODEMTYPE eq 'modem'">selected</TMPL_IF>><TMPL_VAR NAME=nw_analog_modem></option>
        <option value="hsdpa" <TMPL_IF EXPR="NW_VAL_MODEMTYPE eq 'hsdpa'">selected</TMPL_IF>><TMPL_VAR NAME=nw_hsdpa_modem></option>
        <option value="cdma" <TMPL_IF EXPR="NW_VAL_MODEMTYPE eq 'cdma'">selected</TMPL_IF>><TMPL_VAR NAME=nw_cdma_modem></option>
      </select>
    </td>
  </tr>

</table>

<br>
<br>
<input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">

</form>

~;

# Network Setup Wizard Template 4 - Analog 2
#####################################
$template{'netwiz4_analog_2'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_VAR NAME=NW_VAL_subtitle>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>
<br>

<table border="0">
<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">
  <input type="hidden" name="substep" value="<TMPL_VAR NAME=NW_VAL_substep>">
  <input type="hidden" name="lever" value="<TMPL_VAR NAME=NW_VAL_lever>">

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_speed>:</td>
    <td>
      <select name="SPEED">
   <TMPL_LOOP NAME=NW_VAL_CONF_SPEED_LOOP >
        <option value="<TMPL_VAR NAME=CONF_SPEED_LOOP_NAME>" <TMPL_VAR NAME=CONF_SPEED_LOOP_SELECTED>><TMPL_VAR NAME=CONF_SPEED_LOOP_CAPTION></option>
   </TMPL_LOOP>
      </select>
    </td>
  </tr>

<TMPL_IF EXPR="NW_VAL_MODEMTYPE eq 'modem'">
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_dial_telephone>:</td>
    <td>
      <input type="text" name="TELEPHONE" value="<TMPL_VAR NAME=NW_VAL_TELEPHONE>" size="15">
    </td>
  </tr>
</TMPL_IF>

<TMPL_IF EXPR="NW_VAL_MODEMTYPE eq 'hsdpa'">
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_apn>:</td>
    <td>
      <input type="text" name="APN" value="<TMPL_VAR NAME=NW_VAL_APN>" size="15">
    </td>
  </tr>
</TMPL_IF>

  <tr>
    <td width="25%"><TMPL_VAR NAME=username>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="USERNAME" value="<TMPL_VAR NAME=NW_VAL_USERNAME>" size="15">
    </td>
  </tr>

  <tr>
    <td width="25%"><TMPL_VAR NAME=password>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="PASSWORD" value="<TMPL_VAR NAME=NW_VAL_PASSWORD>" size="15">
    </td>
  </tr>

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_auth_method>:</td>
    <td>
      <select name="AUTH_N">
        <option value="0" <TMPL_IF EXPR="NW_VAL_AUTH_N == 0">selected</TMPL_IF>><TMPL_VAR NAME=nw_papchap></option>
        <option value="1" <TMPL_IF EXPR="NW_VAL_AUTH_N == 1">selected</TMPL_IF>><TMPL_VAR NAME=nw_pap></option>
        <option value="2" <TMPL_IF EXPR="NW_VAL_AUTH_N == 2">selected</TMPL_IF>><TMPL_VAR NAME=nw_chap></option>
      </select>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td colspan="2"><TMPL_VAR NAME=nw_additionalips>:</td>
  </tr>
  <tr colspan="2">
    <td>
      <textarea cols="30" rows="3" name="DISPLAY_WAN_ADDITIONAL"><TMPL_VAR NAME=NW_VAL_DISPLAY_WAN_ADDITIONAL></textarea>
    </td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mtu>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="MTU" value="<TMPL_VAR NAME=NW_VAL_MTU>" size="15">
    </td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_dns_quest>:</td>
    <td>
      <input type="radio" name="DNS_N" value="0" <TMPL_VAR NAME=NW_VAL_DNS_SELECTED_0>/><TMPL_VAR NAME=nw_automatic>&nbsp;
      <input type="radio" name="DNS_N" value="1" <TMPL_VAR NAME=NW_VAL_DNS_SELECTED_1>/><TMPL_VAR NAME=nw_manual>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td class='base' width='50%'>
      <img src='/images/blob.png' alt ='*' align='top' />&nbsp;
      <font class='base'><TMPL_VAR NAME=nw_field_blank></font>
    </td>
    <td>&nbsp;</td>
  </tr>

</table>

<br>
<br>
<input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">
</form>
~;

# Network Setup Wizard Template 4 - DHCP
#####################################
$template{'netwiz4_dhcp_1'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>

<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">
  <input type="hidden" name="substep" value="<TMPL_VAR NAME=NW_VAL_substep>">
  <input type="hidden" name="lever" value="<TMPL_VAR NAME=NW_VAL_lever>">

  <table border="0" class="none">
  
    <tr>
      <td colspan="2"><b><font color="red"><TMPL_VAR NAME=nw_wan></font></b> <font color="#666666">(<TMPL_VAR NAME=nw_wan_descr>)</font>:</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_interface>:</td>
      <td>&nbsp;</td>
    </tr>
    <tr>
      <td colspan="2">
        <table>
          <tr>
            <td>&nbsp;</td>
            <td align="center"><b><TMPL_VAR NAME=nw_port></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_link></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_description></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_mac></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_device></b></td>
          </tr>

  <TMPL_LOOP NAME=NW_VAL_IFACE_WAN_LOOP>
          <tr class="<TMPL_VAR NAME=DEV_LOOP_BGCOLOR>">
            <td bgcolor="<TMPL_VAR NAME=DEV_LOOP_ZONECOLOR>">
            <TMPL_IF EXPR="(DEV_LOOP_CHECKED eq 'checked') and (DEV_LOOP_DISABLED eq 'disabled')">
                <input name="WAN_DEVICES" type="hidden" value="<TMPL_VAR NAME=DEV_LOOP_NAME>">
            </TMPL_IF>
            <TMPL_IF EXPR="DEV_LOOP_HIDE eq 'hide'">
              &nbsp;
            <TMPL_ELSE>
              <input name="WAN_DEVICES" type="radio" value="<TMPL_VAR NAME=DEV_LOOP_NAME>" <TMPL_VAR NAME=DEV_LOOP_CHECKED> <TMPL_VAR NAME=DEV_LOOP_DISABLED>>
            </TMPL_IF>
            </td>
            <td align="center"><TMPL_VAR NAME=DEV_LOOP_PORT></td>
            <td>
                <img src="/images/<TMPL_VAR NAME=DEV_LOOP_LINKICON>.png" title="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>" alt="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>">
            </td>
            <td><TMPL_VAR NAME=DEV_LOOP_SHORT_DESC>
                <a href="javascript:void(0);" onmouseover="return overlib('<TMPL_VAR NAME=DEV_LOOP_DESCRIPTION>', STICKY, MOUSEOFF);" onmouseout="return nd();">?</a>
            </td>

            <td><TMPL_VAR NAME=DEV_LOOP_MAC></td>
            <td><TMPL_VAR NAME=DEV_LOOP_DEVICE></td>
          </tr>
  </TMPL_LOOP>
        </table>
      </td>
    </tr>
    
  <tr>
    <td colspan="2">&nbsp;</td>
  </tr>

  <tr>
    <td><TMPL_VAR NAME=nw_mtu>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="MTU" value="<TMPL_VAR NAME=NW_VAL_MTU>" size="15">
    </td>
  </tr>

  <tr>
    <td><TMPL_VAR NAME=nw_mac_spoof>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="MAC" value="<TMPL_VAR NAME=NW_VAL_MAC>" size="15">
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td><TMPL_VAR NAME=nw_dns_quest>:</td>
    <td>
      <input type="radio" name="DNS_N" value="0" <TMPL_VAR NAME=NW_VAL_DNS_SELECTED_0> /><TMPL_VAR NAME=nw_automatic>&nbsp;
      <input type="radio" name="DNS_N" value="1" <TMPL_VAR NAME=NW_VAL_DNS_SELECTED_1> /><TMPL_VAR NAME=nw_manual>
    </td>
  </tr>

    <tr>
      <td colspan="2"><br></td>
    </tr>
  
    <tr>
      <td class='base' colspan="2">
        <img src='/images/blob.png' alt ='*' align='top' />&nbsp;
        <font class='base'><TMPL_VAR NAME=nw_field_blank></font>
      </td>
    </tr>

  </table>
  <br><br>

  <input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">
</form>

~;

# Network Setup Wizard Template 4 - Modem 1
#####################################
$template{'netwiz4_modem_1'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_VAR NAME=NW_VAL_subtitle>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>
<br>

<script src="/include/modemmanager.js"></script>

<table border="0">

<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">
  <input type="hidden" name="substep" value="<TMPL_VAR NAME=NW_VAL_substep>">
  <input type="hidden" name="MM_MODEM_TYPE" value="<TMPL_VAR NAME=NW_VAL_MM_MODEM_TYPE>">

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mm_select_modem>:</td>
    <td>
      <select name="MM_MODEM" id="mm_select">
      </select>

      <a href="javascript: void(0);" id="refresh_mm_button">
          <img src="/images/reconnect.png" id="mm_refresh_icon" border="0" alt="refresh" title="refresh" style="vertical-align: middle"/>
      </a>
    </td>
  </tr>

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mm_modem_type>:</td>
    <td id="mm_modem_info_type"></td>
  </tr>

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mm_identifier>:</td>
    <td id="mm_modem_info_id"></td>
  </tr>

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mm_status>:</td>
    <td id="mm_modem_info_status"></td>
  </tr>

</table>


<br>
<br>
<input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">

</form>

<input type="hidden" name="MM_MODEM" value="<TMPL_VAR NAME=NW_VAL_MM_MODEM>">
~;

# Network Setup Wizard Template 4 - Modem 2
#####################################
$template{'netwiz4_modem_2'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_VAR NAME=NW_VAL_subtitle>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>
<br>

<script src="/include/modemmanager.js"></script>

<table border="0">

<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">
  <input type="hidden" name="substep" value="<TMPL_VAR NAME=NW_VAL_substep>">
  <input type="hidden" name="lever" value="<TMPL_VAR NAME=NW_VAL_lever>">



<TMPL_IF EXPR="NW_VAL_MM_MODEM_TYPE eq 'POTS'">
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_speed>:</td>
    <td>
      <select name="SPEED">
   <TMPL_LOOP NAME=NW_VAL_CONF_SPEED_LOOP >
        <option value="<TMPL_VAR NAME=CONF_SPEED_LOOP_NAME>" <TMPL_VAR NAME=CONF_SPEED_LOOP_SELECTED>><TMPL_VAR NAME=CONF_SPEED_LOOP_CAPTION></option>
   </TMPL_LOOP>
      </select>
    </td>
  </tr>

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_dial_telephone>:</td>
    <td>
      <input type="text" name="TELEPHONE" value="<TMPL_VAR NAME=NW_VAL_TELEPHONE>" size="15">
    </td>
  </tr>
</TMPL_IF>


<TMPL_IF EXPR="NW_VAL_MM_MODEM_TYPE eq 'GSM'">
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mm_select_country>:</td>
    <td>
      <select name="MM_PROVIDER_COUNTRY">
      </select>
    </td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mm_select_provider>:</td>
    <td>
      <select name="MM_PROVIDER_PROVIDER">
      </select>
    </td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mm_select_apn>:</td>
    <td>
      <select name="MM_PROVIDER_APN">
      </select>
    </td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_apn>:</td>
    <td>
      <input type="text" name="APN" value="<TMPL_VAR NAME=NW_VAL_APN>" size="15">
    </td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=username>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="USERNAME" value="<TMPL_VAR NAME=NW_VAL_USERNAME>" size="15">
    </td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=password>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="PASSWORD" value="<TMPL_VAR NAME=NW_VAL_PASSWORD>" size="15">
    </td>
  </tr>

</TMPL_IF>




<TMPL_IF EXPR="NW_VAL_MM_MODEM_TYPE eq 'CDMA'">
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mm_select_country>:</td>
    <td>
      <select name="MM_PROVIDER_COUNTRY">
      </select>
    </td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mm_select_provider>:</td>
    <td>
      <select name="MM_PROVIDER_PROVIDER">
      </select>
    </td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=username>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="USERNAME" value="<TMPL_VAR NAME=NW_VAL_USERNAME>" size="15">
    </td>
  </tr>

  <tr>
    <td width="25%"><TMPL_VAR NAME=password>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="PASSWORD" value="<TMPL_VAR NAME=NW_VAL_PASSWORD>" size="15">
    </td>
  </tr>

</TMPL_IF>









  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_auth_method>:</td>
    <td>
      <select name="AUTH_N">
        <option value="0" <TMPL_IF EXPR="NW_VAL_AUTH_N == 0">selected</TMPL_IF>><TMPL_VAR NAME=nw_papchap></option>
        <option value="1" <TMPL_IF EXPR="NW_VAL_AUTH_N == 1">selected</TMPL_IF>><TMPL_VAR NAME=nw_pap></option>
        <option value="2" <TMPL_IF EXPR="NW_VAL_AUTH_N == 2">selected</TMPL_IF>><TMPL_VAR NAME=nw_chap></option>
      </select>
    </td>
  </tr>

<!--   <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td colspan="2"><TMPL_VAR NAME=nw_additionalips>:</td>
  </tr>
  <tr colspan="2">
    <td>
      <textarea cols="30" rows="3" name="DISPLAY_WAN_ADDITIONAL"><TMPL_VAR NAME=NW_VAL_DISPLAY_WAN_ADDITIONAL></textarea>
    </td>
  </tr>
 -->
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mtu>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="MTU" value="<TMPL_VAR NAME=NW_VAL_MTU>" size="15">
    </td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_dns_quest>:</td>
    <td>
      <input type="radio" name="DNS_N" value="0" <TMPL_VAR NAME=NW_VAL_DNS_SELECTED_0>/><TMPL_VAR NAME=nw_automatic>&nbsp;
      <input type="radio" name="DNS_N" value="1" <TMPL_VAR NAME=NW_VAL_DNS_SELECTED_1>/><TMPL_VAR NAME=nw_manual>
      <input type="hidden" name="DNS1"/>
      <input type="hidden" name="DNS2"/>
    </td>
  </tr>


  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td class='base' width='50%'>
      <img src='/images/blob.png' alt ='*' align='top' />&nbsp;
      <font class='base'><TMPL_VAR NAME=nw_field_blank></font>
    </td>
    <td>&nbsp;</td>
  </tr>

</table>

<br>
<br>
<input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">
</form>

<input type="hidden" name="MM_MODEM" value="<TMPL_VAR NAME=NW_VAL_MM_MODEM>">
<input type="hidden" name="MM_MODEM_TYPE" value="<TMPL_VAR NAME=NW_VAL_MM_MODEM_TYPE>">
<input type="hidden" name="MM_PROVIDER_COUNTRY" value="<TMPL_VAR NAME=NW_VAL_MM_PROVIDER_COUNTRY>">
<input type="hidden" name="MM_PROVIDER_PROVIDER" value="<TMPL_VAR NAME=NW_VAL_MM_PROVIDER_PROVIDER>">
<input type="hidden" name="MM_PROVIDER_APN" value="<TMPL_VAR NAME=NW_VAL_MM_PROVIDER_APN>">
~;

# Network Setup Wizard Template 4 - None
#####################################
$template{'netwiz4_none_1'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>

<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">
  <input type="hidden" name="substep" value="<TMPL_VAR NAME=NW_VAL_substep>">
  <input type="hidden" name="lever" value="<TMPL_VAR NAME=NW_VAL_lever>">

  <table border="0" class="none">
  
    <tr>
      <td colspan="2"><b><font color="red"><TMPL_VAR NAME=nw_wan></font></b> <font color="#666666">(<TMPL_VAR NAME=nw_wan_descr>)</font>:</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_gateway>:</td>
      <td>
        <input type="text" name="DEFAULT_GATEWAY" value="<TMPL_VAR NAME=NW_VAL_DEFAULT_GATEWAY>" size="15">
      </td>
    </tr>

  </table>
  <br><br>

  <input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">
</form>
~;

# Network Setup Wizard Template 4 - PPPOE
#####################################
$template{'netwiz4_pppoe_1'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_VAR NAME=NW_VAL_subtitle>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>
<br>

<table border="0" cols="2">
<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">
  <input type="hidden" name="substep" value="<TMPL_VAR NAME=NW_VAL_substep>">
  <input type="hidden" name="lever" value="<TMPL_VAR NAME=NW_VAL_lever>">

    <tr>
      <td><TMPL_VAR NAME=nw_interface>:</td>
      <td>&nbsp;</td>
    </tr>
    <tr>
      <td colspan="2">
        <table>
          <tr>
            <td>&nbsp;</td>
            <td align="center"><b><TMPL_VAR NAME=nw_port></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_link></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_description></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_mac></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_device></b></td>
          </tr>

  <TMPL_LOOP NAME=NW_VAL_IFACE_WAN_LOOP>
          <tr class="<TMPL_VAR NAME=DEV_LOOP_BGCOLOR>">

            <td bgcolor="<TMPL_VAR NAME=DEV_LOOP_ZONECOLOR>">
            <TMPL_IF EXPR="(DEV_LOOP_CHECKED eq 'checked') and (DEV_LOOP_DISABLED eq 'disabled')">
                <input name="WAN_DEVICES" type="hidden" value="<TMPL_VAR NAME=DEV_LOOP_NAME>">
            </TMPL_IF>
            <TMPL_IF EXPR="DEV_LOOP_HIDE eq 'hide'">
              &nbsp;
            <TMPL_ELSE>
              <input name="WAN_DEVICES" type="radio" value="<TMPL_VAR NAME=DEV_LOOP_NAME>" <TMPL_VAR NAME=DEV_LOOP_CHECKED> <TMPL_VAR NAME=DEV_LOOP_DISABLED>>
            </TMPL_IF>
            </td>
            <td align="center"><TMPL_VAR NAME=DEV_LOOP_PORT></td>
            <td>
                <img src="/images/<TMPL_VAR NAME=DEV_LOOP_LINKICON>.png" title="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>" alt="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>">
            </td>
            <td><TMPL_VAR NAME=DEV_LOOP_SHORT_DESC>
                <a href="javascript:void(0);" onmouseover="return overlib('<TMPL_VAR NAME=DEV_LOOP_DESCRIPTION>', STICKY, MOUSEOFF);" onmouseout="return nd();">?</a>
            </td>

            <td><TMPL_VAR NAME=DEV_LOOP_MAC></td>
            <td><TMPL_VAR NAME=DEV_LOOP_DEVICE></td>
          </tr>
  </TMPL_LOOP>
        </table>
      </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td colspan="2"><TMPL_VAR NAME=nw_additionalips>:</td>
  </tr>

  <tr colspan="2">
    <td>
      <textarea cols="30" rows="3" name="DISPLAY_WAN_ADDITIONAL"><TMPL_VAR NAME=NW_VAL_DISPLAY_WAN_ADDITIONAL></textarea>
    </td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td><TMPL_VAR NAME=username>:</td>
    <td>
      <input type="text" name="USERNAME" value="<TMPL_VAR NAME=NW_VAL_USERNAME>" size="15">
    </td>
  </tr>

  <tr>
    <td><TMPL_VAR NAME=password>:</td>
    <td>
      <input type="text" name="PASSWORD" value="<TMPL_VAR NAME=NW_VAL_PASSWORD>" size="15">
    </td>
  </tr>

  <tr>
    <td><TMPL_VAR NAME=nw_auth_method>:</td>
    <td>
      <select name="AUTH_N">
        <option value="0" <TMPL_IF EXPR="NW_VAL_AUTH_N == 0">selected</TMPL_IF>><TMPL_VAR NAME=nw_papchap></option>
        <option value="1" <TMPL_IF EXPR="NW_VAL_AUTH_N == 1">selected</TMPL_IF>><TMPL_VAR NAME=nw_pap></option>
        <option value="2" <TMPL_IF EXPR="NW_VAL_AUTH_N == 2">selected</TMPL_IF>><TMPL_VAR NAME=nw_chap></option>
      </select>
    </td>
  </tr>
  <tr>
    <td><TMPL_VAR NAME=nw_mtu>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="MTU" value="<TMPL_VAR NAME=NW_VAL_MTU>" size="15">
    </td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td><TMPL_VAR NAME=nw_dns_quest>:</td>
    <td>
      <input type="radio" name="DNS_N" value="0" <TMPL_VAR NAME=NW_VAL_DNS_SELECTED_0>/><TMPL_VAR NAME=nw_automatic>&nbsp;
      <input type="radio" name="DNS_N" value="1" <TMPL_VAR NAME=NW_VAL_DNS_SELECTED_1>/><TMPL_VAR NAME=nw_manual>
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td><TMPL_VAR NAME=service>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="SERVICENAME" value="<TMPL_VAR NAME=NW_VAL_SERVICENAME>" size="15">
    </td>
  </tr>

  <tr>
    <td><TMPL_VAR NAME=nw_concentrator_name>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="CONCENTRATORNAME" value="<TMPL_VAR NAME=NW_VAL_CONCENTRATORNAME>" size="15">
    </td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td class='base' colspan="2">
      <img src='/images/blob.png' alt ='*' align='top' />&nbsp;
      <font class='base'><TMPL_VAR NAME=nw_field_blank></font>
    </td>
  </tr>

</table>

<br>
<br>
<input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">
</form>
~;

# Network Setup Wizard Template 4 - Static
#####################################
$template{'netwiz4_static_1'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>

<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">
  <input type="hidden" name="substep" value="<TMPL_VAR NAME=NW_VAL_substep>">
  <input type="hidden" name="lever" value="<TMPL_VAR NAME=NW_VAL_lever>">

  <table border="0" class="none" columns="5">

  
    <tr>
      <td colspan="5"><b><font color="red"><TMPL_VAR NAME=nw_wan></font></b> <font color="#666666">(<TMPL_VAR NAME=nw_wan_descr>)</font>:</td>
    </tr>

    <tr>
      <td style="width: 100px;"><TMPL_VAR NAME=nw_ip>:</td>
      <td style="width: 150px;">
        <input type="text" name="DISPLAY_WAN_ADDRESS" value="<TMPL_VAR NAME=NW_VAL_WAN_ADDRESS>" size="15">
      </td>
      <td style="width: 10px;">&nbsp;</td>
      <td style="width: 100px;"><TMPL_VAR NAME=nw_mask>:</td>
      <td>
        <select name="DISPLAY_WAN_NETMASK">
  <TMPL_LOOP NAME=NW_VAL_DISPLAY_WAN_NETMASK_LOOP>
          <option value="<TMPL_VAR NAME=MASK_LOOP_VALUE>" <TMPL_VAR NAME=MASK_LOOP_SELECTED>><TMPL_VAR NAME=MASK_LOOP_CAPTION></option>
  </TMPL_LOOP>
        </select>
      </td>
    </tr>

    <tr>
      <td colspan="5"><TMPL_VAR NAME=nw_additionalips>:</td>
    </tr>

    <tr colspan="5">
      <td>
        <textarea cols="30" rows="3" name="DISPLAY_WAN_ADDITIONAL"><TMPL_VAR NAME=NW_VAL_DISPLAY_WAN_ADDITIONAL></textarea>
      </td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_interface>:</td>
      <td colspan="4">&nbsp;</td>
    </tr>
    <tr>
      <td colspan="5">
        <table>
          <tr>
            <td>&nbsp;</td>
            <td align="center"><b><TMPL_VAR NAME=nw_port></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_link></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_description></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_mac></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_device></b></td>
          </tr>

  <TMPL_LOOP NAME=NW_VAL_IFACE_WAN_LOOP>
          <tr class="<TMPL_VAR NAME=DEV_LOOP_BGCOLOR>">
            <td bgcolor="<TMPL_VAR NAME=DEV_LOOP_ZONECOLOR>">

            <TMPL_IF EXPR="(DEV_LOOP_CHECKED eq 'checked') and (DEV_LOOP_DISABLED eq 'disabled')">
                <input name="WAN_DEVICES" type="hidden" value="<TMPL_VAR NAME=DEV_LOOP_NAME>">
            </TMPL_IF>
            <TMPL_IF EXPR="DEV_LOOP_HIDE eq 'hide'">
              &nbsp;
            <TMPL_ELSE>
              <input name="WAN_DEVICES" type="radio" value="<TMPL_VAR NAME=DEV_LOOP_NAME>" <TMPL_VAR NAME=DEV_LOOP_CHECKED> <TMPL_VAR NAME=DEV_LOOP_DISABLED>>
            </TMPL_IF>
            </td>
            <td align="center"><TMPL_VAR NAME=DEV_LOOP_PORT></td>
            <td>
                <img src="/images/<TMPL_VAR NAME=DEV_LOOP_LINKICON>.png" title="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>" alt="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>">
            </td>
            <td><TMPL_VAR NAME=DEV_LOOP_SHORT_DESC>
                <a href="javascript:void(0);" onmouseover="return overlib('<TMPL_VAR NAME=DEV_LOOP_DESCRIPTION>', STICKY, MOUSEOFF);" onmouseout="return nd();">?</a>
            </td>

            <td><TMPL_VAR NAME=DEV_LOOP_MAC></td>
            <td><TMPL_VAR NAME=DEV_LOOP_DEVICE></td>
          </tr>
  </TMPL_LOOP>
        </table>
      </td>
    </tr>

    <tr>
      <td>&nbsp;</td>
      <td colspan="4">&nbsp;</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_gateway>:</td>
      <td colspan="4">
        <input type="text" name="DEFAULT_GATEWAY" value="<TMPL_VAR NAME=NW_VAL_DEFAULT_GATEWAY>" size="15">
      </td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_mtu>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
      <td colspan="4">
        <input type="text" name="MTU" value="<TMPL_VAR NAME=NW_VAL_MTU>" size="15">
      </td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_mac_spoof>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
      <td colspan="4">
        <input type="text" name="MAC" value="<TMPL_VAR NAME=NW_VAL_MAC>" size="15">
      </td>
    </tr>

    <tr>
      <td colspan="5"><br></td>
    </tr>

    <tr>
      <td class='base' colspan="5">
        <img src='/images/blob.png' alt ='*' align='top' />&nbsp;
        <font class='base'><TMPL_VAR NAME=nw_field_blank></font>
      </td>
    </tr>

  </table>
  <br><br>

  <input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">
</form>
~;

# Network Setup Wizard Template 4 - Stealth
#####################################
$template{'netwiz4_stealth_1'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>

<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">
  <input type="hidden" name="substep" value="<TMPL_VAR NAME=NW_VAL_substep>">
  <input type="hidden" name="lever" value="<TMPL_VAR NAME=NW_VAL_lever>">

  <table border="0" class="none" columns="5">

  
    <tr>
      <td colspan="5"><b><font color="red"><TMPL_VAR NAME=nw_wan_stealth></font></b> <font color="#666666">(<TMPL_VAR NAME=nw_wan_descr>)</font>:</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_interface>:</td>
      <td colspan="4">&nbsp;</td>
    </tr>
    <tr>
      <td colspan="5">
        <table>
          <tr>
            <td>&nbsp;</td>
            <td align="center"><b><TMPL_VAR NAME=nw_port></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_link></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_description></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_mac></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_device></b></td>
          </tr>

  <TMPL_LOOP NAME=NW_VAL_IFACE_WAN_LOOP>
          <tr class="<TMPL_VAR NAME=DEV_LOOP_BGCOLOR>">
            <td bgcolor="<TMPL_VAR NAME=DEV_LOOP_ZONECOLOR>">

            <TMPL_IF EXPR="(DEV_LOOP_CHECKED eq 'checked') and (DEV_LOOP_DISABLED eq 'disabled')">
                <input name="WAN_DEVICES" type="hidden" value="<TMPL_VAR NAME=DEV_LOOP_NAME>">
            </TMPL_IF>
            <TMPL_IF EXPR="DEV_LOOP_HIDE eq 'hide'">
              &nbsp;
            <TMPL_ELSE>
              <input name="WAN_DEVICES" type="radio" value="<TMPL_VAR NAME=DEV_LOOP_NAME>" <TMPL_VAR NAME=DEV_LOOP_CHECKED> <TMPL_VAR NAME=DEV_LOOP_DISABLED>>
            </TMPL_IF>
            </td>
            <td align="center"><TMPL_VAR NAME=DEV_LOOP_PORT></td>
            <td>
                <img src="/images/<TMPL_VAR NAME=DEV_LOOP_LINKICON>.png" title="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>" alt="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>">
            </td>
            <td><TMPL_VAR NAME=DEV_LOOP_SHORT_DESC>
                <a href="javascript:void(0);" onmouseover="return overlib('<TMPL_VAR NAME=DEV_LOOP_DESCRIPTION>', STICKY, MOUSEOFF);" onmouseout="return nd();">?</a>
            </td>

            <td><TMPL_VAR NAME=DEV_LOOP_MAC></td>
            <td><TMPL_VAR NAME=DEV_LOOP_DEVICE></td>
          </tr>
  </TMPL_LOOP>
        </table>
      </td>
    </tr>

    <tr>
      <td>&nbsp;</td>
      <td colspan="4">&nbsp;</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_gateway>:</td>
      <td colspan="4">
        <input type="text" name="DEFAULT_GATEWAY" value="<TMPL_VAR NAME=NW_VAL_DEFAULT_GATEWAY>" size="15">
      </td>
    </tr>

    <tr>
      <td colspan="5"><br></td>
    </tr>

    <tr>
      <td class='base' colspan="5">
        <img src='/images/blob.png' alt ='*' align='top' />&nbsp;
        <font class='base'><TMPL_VAR NAME=nw_field_blank></font>
      </td>
    </tr>

  </table>
  <br><br>

  <input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">
</form>
~;

# Network Setup Wizard Template 5
#####################################
$template{'netwiz5'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>

<table border="0">
<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">

<TMPL_IF NAME=NW_VAL_DNS_MANUAL>
  <tr>
    <td colspan="2"><TMPL_VAR NAME=nw_dns_manual>:</td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_dns1>:</td>
    <td>
      <input type="text" name="DNS1" value="<TMPL_VAR NAME=NW_VAL_DNS1>" size="15">
    </td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_dns2>:</td>
    <td>
      <input type="text" name="DNS2" value="<TMPL_VAR NAME=NW_VAL_DNS2>" size="15">
    </td>
  </tr>
<TMPL_ELSE>
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_dns_quest>:</td>
    <td><TMPL_VAR NAME=NW_VAL_DNS_CAPTION></td>
  </tr>
</TMPL_IF>

</table>

<br>
<br>
<input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">
</form>
~;

# Network Setup Wizard Template 6
#####################################
$template{'netwiz6'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>

<table border="0">
<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">

  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_admin_mail>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="MAIN_ADMINMAIL" value="<TMPL_VAR NAME=NW_VAL_MAIN_ADMINMAIL>" size="15">
    </td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mail_from>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="MAIN_MAILFROM" value="<TMPL_VAR NAME=NW_VAL_MAIN_MAILFROM>" size="15">
    </td>
  </tr>
  <tr>
    <td width="25%"><TMPL_VAR NAME=nw_mail_smarthost>:&nbsp;<img src='/images/blob.png' alt='*' /></td>
    <td>
      <input type="text" name="MAIN_SMARTHOST" value="<TMPL_VAR NAME=NW_VAL_MAIN_SMARTHOST>" size="15">
    </td>
  </tr>

  <tr>
    <td class='base' colspan="5">
      <img src='/images/blob.png' alt ='*' align='top' />&nbsp;
      <font class='base'><TMPL_VAR NAME=nw_field_blank></font>
    </td>
  </tr>

</table>

<br>
<br>
<input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="submit" name="next" value="<TMPL_VAR NAME=nw_next>">
</form>
~;

# Network Setup Wizard Template 7
#####################################
$template{'netwiz7'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>

<form action="<TMPL_VAR NAME=NW_VAL_self>" method="post">
  <input type="hidden" name="session_id" value="<TMPL_VAR NAME=NW_VAL_session_id>">
  <input type="hidden" name="step" value="<TMPL_VAR NAME=NW_VAL_step>">

  <p>
  <TMPL_VAR NAME=nw_final_msg>
  <br><br>
  <br><br>

  <input type="submit" name="prev" value="<TMPL_VAR NAME=nw_prev>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="cancel" value="<TMPL_VAR NAME=nw_cancel>">
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <input type="submit" name="next" value="<TMPL_VAR NAME=nw_last>">
</form>

~;

# Network Setup Wizard Template 8
#####################################
$template{'netwiz8'} = qq~
<TMPL_VAR NAME=NW_VAL_title>
<br>
<TMPL_IF EXPR="NW_VAL_error_message ne ''">
  <font color="red"><TMPL_VAR NAME=NW_VAL_error_message></font>
</TMPL_IF>
<br>
<TMPL_VAR NAME=nw_end_msg>
<br><br>
<TMPL_IF NW_VAL_lan_changed>
  <TMPL_VAR NAME=nw_lan_changed_explain>
  <A HREF="<TMPL_VAR NAME=NW_VAL_LAN_LINK>"><TMPL_VAR NAME=nw_lan_changed_link></A>
  <BR>
</TMPL_IF>
<BR>
<TMPL_VAR NAME=nw_lan_changed_proxy>
~;

# Network Setup Wizard Template - Zones
#####################################
$template{'netwiz_zone'} = qq~
    <tr>
      <td colspan="5"><b><font color="blue"><TMPL_VAR NAME=nw_lan2></font></b> <font color="#666666">(<TMPL_VAR NAME=nw_lan2_descr>)</font>:</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_ip>:</td>
      <td>
        <input type="text" name="DISPLAY_LAN2_ADDRESS" value="<TMPL_VAR NAME=NW_VAL_LAN2_ADDRESS>" size="15">
      </td>
      <td>&nbsp;</td>
      <td><TMPL_VAR NAME=nw_mask>:</td>
      <td>
        <select name="DISPLAY_LAN2_NETMASK">
  <TMPL_LOOP NAME=NW_VAL_DISPLAY_LAN2_NETMASK_LOOP>
          <option value="<TMPL_VAR NAME=MASK_LOOP_VALUE>" <TMPL_VAR NAME=MASK_LOOP_SELECTED>><TMPL_VAR NAME=MASK_LOOP_CAPTION></option>
  </TMPL_LOOP>
        </select>
      </td>
    </tr>

    <tr>
      <td colspan="5"><TMPL_VAR NAME=nw_additionalips>:</td>
    </tr>
    <tr>
      <td colspan="5">
        <textarea cols="30" rows="3" name="DISPLAY_LAN2_ADDITIONAL"><TMPL_VAR NAME=NW_VAL_DISPLAY_LAN2_ADDITIONAL></textarea>
      </td>
    </tr>

    <tr>
      <td colspan="5">&nbsp;</td>
    </tr>

    <tr>
      <td><TMPL_VAR NAME=nw_interface>:</td>
      <td colspan="4">&nbsp;</td>
    </tr>
    <tr>
      <td colspan="5">
        <table>
          <tr>
            <td>&nbsp;</td>
            <td align="center"><b><TMPL_VAR NAME=nw_port></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_link></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_description></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_mac></b></td>
            <td align="center"><b><TMPL_VAR NAME=nw_device></b></td>
          </tr>

  <TMPL_LOOP NAME=NW_VAL_IFACE_LAN2_LOOP>
          <tr class="<TMPL_VAR NAME=DEV_LOOP_BGCOLOR>">
            <td bgcolor="<TMPL_VAR NAME=DEV_LOOP_ZONECOLOR>">
            <TMPL_IF EXPR="(DEV_LOOP_CHECKED eq 'checked') and (DEV_LOOP_DISABLED eq 'disabled')">
                <input name="LAN2_DEVICES" type="hidden" value="<TMPL_VAR NAME=DEV_LOOP_NAME>">
            </TMPL_IF>
            <TMPL_IF EXPR="DEV_LOOP_HIDE eq 'hide'">
              &nbsp;
            <TMPL_ELSE>
              <input name="LAN2_DEVICES" type="checkbox" value="<TMPL_VAR NAME=DEV_LOOP_NAME>" <TMPL_VAR NAME=DEV_LOOP_CHECKED> <TMPL_VAR NAME=DEV_LOOP_DISABLED>>
            </TMPL_IF>
            </td>
            <td align="center"><TMPL_VAR NAME=DEV_LOOP_PORT></td>
            <td>
                <img src="/images/<TMPL_VAR NAME=DEV_LOOP_LINKICON>.png" title="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>" alt="<TMPL_VAR NAME=DEV_LOOP_LINKCAPTION>">
            </td>
            <td><TMPL_VAR NAME=DEV_LOOP_SHORT_DESC>
                <a href="javascript:void(0);" onmouseover="return overlib('<TMPL_VAR NAME=DEV_LOOP_DESCRIPTION>', STICKY, MOUSEOFF);" onmouseout="return nd();">?</a>
            </td>

            <td><TMPL_VAR NAME=DEV_LOOP_MAC></td>
            <td><TMPL_VAR NAME=DEV_LOOP_DEVICE></td>
          </tr>
  </TMPL_LOOP>
        </table>
      </td>
    </tr>

  <tr>
    <td colspan="5">&nbsp;</td>
  </tr>
  <tr>
    <td colspan="5">&nbsp;</td>
  </tr>
 ~;
