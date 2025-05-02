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


#
# IPCop stuff
#

require 'header.pl';
require '/razwall/web/cgi-bin/netwiz.cgi';

getcgihash(\%par);

my $reload_from_wizard = '/usr/local/bin/restart_from_wizard';
my %producthash;
my $productfile = '/var/efw/product/settings';
my %wizardhash;
my $wizardfile = '/var/efw/wizard/settings';


#
# start IPCop-style page
#

if ($0 =~ /step2\/*(netwiz|wizard).cgi/) {
    $pagename =  "firstwizard";
    $nomenu = 1;
    setFlavour('setup');
    $nostatus = 1;
} else {
    undef $pagename;
    undef $nomenu;
    undef $nostatus;
}

readhash($productfile, \%producthash);
readhash($wizardfile, \%wizardhash);
# redirect to main.cgi if cancel is pressed during wizard
if (
    ($pagename eq "firstwizard") and
    ($producthash{"FORCE_REGISTRATION"} ne 'on') and
    (uc($wizardhash{"WIZARD_STATE"}) ne 'NETWIZARD')
    ) {
    my $httphost = getHTTPRedirectHost();
    print "Status: 302 Moved\n";
    print "Location: https://${httphost}/cgi-bin/main.cgi\n\n";
    exit;
}

showhttpheaders();
my ($reload, $extraheader, $content, $rebuildcert) = print_template($swroot);

openpage(_('Network setup wizard'), 1, $extraheader,$nomenu=$nomenu);

&openbigbox($errormessage, $warnmessage, $notemessage);
openbox('100%', 'left', _('Network setup wizard'));

print $content;

#
# end IPCop-style page
#

closebox();
closebigbox();
closepage($nostatus=$nostatus);

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
