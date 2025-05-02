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


##############################################################################
# this file makes the wizard ipcop capable.
##############################################################################

use lib '/razwall/web/cgi-bin/';
require 'header.pl';
require 'razwall-netwiz.cgi';

getcgihash(\%par);

my $reload_from_wizard = '/usr/local/bin/restart_from_wizard';
my %producthash;
my $productfile = '/razwall/config/product/settings';
my %wizardhash;
my $wizardfile = '/razwall/config/wizard/settings';


#if ($0 =~ /step2\/*(netwiz|wizard).cgi/) { # NEEDED FOR FUTURE OOB SETUP?
#    $pagename =  "firstwizard";
#    $nomenu = 1;
#    setFlavour('setup');
#    $nostatus = 1;
#} else {
#    undef $pagename;
#    undef $nomenu;
#    undef $nostatus;
#}

#readhash($productfile, \%producthash);
#readhash($wizardfile, \%wizardhash);
# redirect to main.cgi if cancel is pressed during wizard
#if (
#    ($pagename eq "firstwizard") and
#    ($producthash{"FORCE_REGISTRATION"} ne 'on') and
#    (uc($wizardhash{"WIZARD_STATE"}) ne 'NETWIZARD')
#    ) {
#    my $httphost = getHTTPRedirectHost();
#    print "Status: 302 Moved\n";
#    print "Location: https://${httphost}/cgi-bin/dashboard.cgi\n\n";
#    exit;
#}


# build system paths
$cgi_path = $1 if (($ENV{'SCRIPT_FILENAME'}||$0) =~ m/^(.*)(\\|\/)(.+?)$/);
$templates = $cgi_path . '/templates.pl';

# Check that templates file can be loaded..
&loadTemplates;

showhttpheaders();

&getTemplate('openHeader');
&printTemplate;

# EXTRA HEADER DATA HERE
print qq~
<!-- BEGIN NETOWRK CUSTOM HEADER -->

<link rel="stylesheet" type="text/css" href="/css/uplinkinformationcontent.css" media="all" />
<link rel="stylesheet" type="text/css" href="/css/autorefreshwrapper.css" media="all" />
<style type="text/css">
.current-zones .zones-header,
.current-zones .zones-row {
  display: flex;
  align-items: center;
  padding: 0.5em 0;
}
.current-zones .zones-header {
  font-weight: bold;
  border-bottom: 1px solid #444;
  margin-bottom: 0.5em;
}
.zone-col { width: 15%; }
.desc-col { width: 45%; }
.type-col { width: 20%; }
.iface-col { width: 20%; }

.new-zones .zone-input-row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5em;
  margin-bottom: 0.5em;
}
/*
.new-zones .zone-input-row input[type="text"] {
  flex: 2;
}
.new-zones .zone-input-row select {
  flex: 1;
}
*/
.new-zones .zone-input-row input[type="color"] {
  width: 35px;
  height: 35px;
  padding: 0;
  border: none;
}
.add-zone {
  margin-bottom: 1em;
}
.form-actions {
  display: flex;
  gap: 1em;
  margin-top: 1em;
}
.error-message .error { color: red; }
</style>

<script type="text/javascript" src="/js/systeminformationplugin.js"></script>
<script type="text/javascript" src="/js/uplinkinformationplugin.js"></script>
<script type="text/javascript" src="/js/autorefreshwrapper.js"></script>
<script language="JavaScript" src="/js/services_selector.js"></script>

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

	<script type="text/javascript">
	// Submit new zone data
	document.addEventListener('DOMContentLoaded', () => {
		var addBtn = document.getElementById('addZoneBtn');
		var form   = document.getElementById('zonesForm');
		addBtn.addEventListener('click', () => {
			form.submit();
		});
	});
	</script>


<!-- END NETWORK CUSTOM HEADER-->
~;

&getTemplate('closeHeader');
&printTemplate;

my ($reload, $extraheader, $content, $rebuildcert) = print_template($swroot);

#openpage(_('Network setup wizard'), 1, $extraheader,$nomenu=$nomenu);

#&openbigbox($errormessage, $warnmessage, $notemessage);
#openbox('100%', 'left', _('Network setup wizard'));

print $content;

#closebox();
#closebigbox();
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

# CUSTOM FOOTER JS

&getTemplate('footer');
&printTemplate;


if ($reload eq 'YES DO IT') {

    my $options = '';
    if ($rebuildcert) {
	$options .= 'REBUILDCERT';
    }

    if ( -x $reload_from_wizard) {
	`$reload_from_wizard $options &`;
    }
}
1;
