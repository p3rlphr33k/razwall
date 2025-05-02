#!/usr/bin/perl

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

use lib '/razwall/web/cgi-bin/';
require 'header.pl';

$thisPath = $ENV{'REQUEST_URI'};
$thisAddress = $ENV{'SERVER_NAME'};

#getcgihash(\%par);
#%template = ();

#undef $pagename;
#undef $nomenu;
#undef $nostatus;

#readhash($productfile, \%producthash);
#readhash($wizardfile, \%wizardhash);

# build system paths
$cgi_path = $1 if (($ENV{'SCRIPT_FILENAME'}||$0) =~ m/^(.*)(\\|\/)(.+?)$/);
$templates = $cgi_path . '/templates.pl';

# Check that templates file can be loaded..
&loadTemplates;

showhttpheaders();

#&openpage('Port forwarding / Destination NAT configuration'); # User this in header.pl later to build out template without template toolkit

&getTemplate('openHeader');
&printTemplate;

print qq~
<!-- BEGIN DASHBOARD CUSTOM HEADERS -->
<link rel="stylesheet" type="text/css" href="/css/plugin.css"/>
<!--link rel="stylesheet" type="text/css" href="/css/signaturesinformationcontent.css" media="all" /-->
<link rel="stylesheet" type="text/css" href="/css/hardwareinformationcontent.css" media="all" />
<link rel="stylesheet" type="text/css" href="/css/serviceinformationcontent.css" media="all" />
<link rel="stylesheet" type="text/css" href="/css/networkinformationcontent.css" media="all" />
<link rel="stylesheet" type="text/css" href="/css/uplinkinformationcontent.css" media="all" />
<link rel="stylesheet" type="text/css" href="/css/autorefreshwrapper.css" media="all" />

<script type="text/javascript" src="/js/systeminformationplugin.js"></script>
<!--script type="text/javascript" src="/js/signaturesinformationplugin.js"></script-->
<script type="text/javascript" src="/js/hardwareinformationplugin.js"></script>
<script type="text/javascript" src="/js/serviceinformationplugin.js"></script>
<script type="text/javascript" src="/js/networkinformationplugin.js"></script>
<script type="text/javascript" src="/js/uplinkinformationplugin.js"></script>
<script type="text/javascript" src="/js/jobsinformationplugin.js"></script>
<script type="text/javascript" src="/js/autorefreshwrapper.js"></script>


	<!-- Uplink Call -->
    <script type="text/javascript">
	document.addEventListener("DOMContentLoaded",function() {
		autorefreshwrapper_register('autorefreshwrapper-UpLinkInformationPlugin',
                                'uplinkinformationpluginInit',
                                '/cgi-bin/dash.pl?plugin=uplinks', 
                                null,
                                'uplinkinformationpluginUpdate',
                                '/cgi-bin/dash.pl?plugin=uplinks',
                                null,
                                '',
                                'True',
                                5000);
	});
    </script>
	<!-- System Info Call -->
     <script type="text/javascript">
	document.addEventListener("DOMContentLoaded", function() {
		autorefreshwrapper_register(
								"autorefreshwrapper-SystemInformationPlugin",
								"systeminformationpluginUpdate",
								"/cgi-bin/dash.pl?plugin=system",
								null,
								"systeminformationpluginUpdate",
								"/cgi-bin/dash.pl?plugin=system",
								null,
								"",
								"True",
								5000);
	});
	</script>
	<!-- Signatures Call -->
	<!--script type="text/javascript">
	document.addEventListener("DOMContentLoaded", function() {
    // needs to be done before pageload!!
    autorefreshwrapper_register('autorefreshwrapper-SignaturesInformationPlugin',
                                'signaturesinformationpluginUpdate',
                                '/cgi-bin/dash.pl?plugin=signatures', 
                                null,
                                'signaturesinformationpluginUpdate',
                                '/cgi-bin/dash.pl?plugin=signatures',
                                null,
                                '',
                                'True',
                                5000);
	});
    </script-->
	<!-- Hardware Call -->
	<script type="text/javascript">
	document.addEventListener("DOMContentLoaded", function() {
    // needs to be done before pageload!!
    autorefreshwrapper_register('autorefreshwrapper-HardwareInformationPlugin',
                                'hardwareinformationpluginUpdate',
                                '/cgi-bin/dash.pl?plugin=hardware', 
                                null,
                                'hardwareinformationpluginUpdate',
                                '/cgi-bin/dash.pl?plugin=hardware',
                                null,
                                '',
                                'True',
                                5000);
	});
    </script>
	<!-- Network Call -->
    <script type="text/javascript">
	document.addEventListener("DOMContentLoaded",function() {
    // needs to be done before pageload!!
    autorefreshwrapper_register('autorefreshwrapper-NetworkInformationPlugin',
                                'networkinformationpluginInit',
                                '/cgi-bin/dash.pl?plugin=network', 
                                null,
                                'networkinformationpluginUpdate',
                                '/cgi-bin/dash.pl?plugin=network',
                                null,
                                '',
                                'True',
                                5000);
	});
    </script>
	<!-- Services Call -->
    <!--script type="text/javascript">
	document.addEventListener("DOMContentLoaded",function() {
    // needs to be done before pageload!!
    autorefreshwrapper_register('autorefreshwrapper-ServiceInformationPlugin',
                                'serviceinformationpluginInit',
                                '/cgi-bin/dash.pl?plugin=service', 
                                null,
                                'serviceinformationpluginUpdate',
                                '/cgi-bin/dash.pl?plugin=service',
                                {"keys": ["memory/memory-used", "filecount-postfix_queue/files", "tail-smtp/connections-noqueue", "tail-smtp/connections-virus", "tail-smtp/connections-spam", "tail-smtp/connections-clean", "tail-smtp/connections-incoming", "tail-smtp/connections-sent", "tail-pop/connections-spam", "tail-pop/connections-virus", "tail-pop/connections-scanned", "tail-http/connections-hit", "tail-http/connections-miss", "tail-http/connections-denied", "tail-http/connections-virus"]},
                                '',
                                'True',
                                5000);
	});
    </script-->
	<!-- END DASHBOARD CUSTOM HEADERS -->
~;

&getTemplate('closeHeader');
&printTemplate;

print qq~
   <!-- Services Display Box -->
  <!--
	<div class="services">
	
	<div id="ServicesInformationPlugin">
        <div id="signaturesinformationplugin-information"></div>
	</div>
	
	</div>
  -->
  
  <!-- Signature Display Box -->
  <!--
	<div class="signature">
  
	<div id="SignaturesInformationPlugin">
		<div id="signaturesinformationplugin-information"></div>
    </div>
	
	</div>
  -->
  
  <!-- Wrap both boxes in a container -->
  <div class="plugin-container">

  <!-- Interfaces Display Box -->
  <div class="interfaces">
  <h3>Interfaces</h3>
	<div id="networkinformationplugin-information"></div>
  </div>
  
  <!-- Interfaces Display Box -->
  <div class="hardware">
  <h3>Resources</h3>
	<div id="hardwareinformationplugin"></div>
  </div>

  </div>
~;


print qq~
 <!-- END MAIN CONTENT -->
  </main>
   <!-- Navigation Tiles Footer -->
  <footer class="navigation" id="tileNav">
~;

    &showmenu();

print qq~
	</footer>

  <!-- Mobile Drawer Toggle -->
  <div class="drawer-toggle" onclick="toggleDrawer()">
    <span id="drawer-arrow">▲</span>
  </div>
~;

&getTemplate('footer');
&printTemplate;

1;
