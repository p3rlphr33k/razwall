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

require 'header.pl';
require 'razinc.pl';

use POSIX qw(strftime);

use JSON::XS;
use LWP::Simple;


sub getNicStatus($) {
    my $iff = shift;

    my $iffargs = '';
    for my $i (@$iff) {
	$iffargs .= "nics=$i&";
    }
    my $url = "http://localhost:3131/manage/status/status.network.nicstatus/?";
    my $content = get $url.$iffargs;

    if ($content =~ /^$/) {
	return 0;
    }

    return JSON::XS->new->utf8->decode ($content);
}

sub loadNicInfo() {
    my ($nicarr, $nichash) = list_devices_description(0, -1, 1);
    my @niclist = ();
    foreach my $iff (@$nicarr) {
	# hide bond devices and vlan devices
	next if ($iff->{'bonddevices'});
	next if ($iff->{'physdev'});
	push(@niclist, $iff->{'device'});
    }
    my $nicstatus = getNicStatus(\@niclist);
    return (\@niclist, $nichash, $nicstatus);
}


my (%dhcpsettings, %netsettings, %openvpnsettings, %dhcpinfo, %pppsettings, $output);

&readhash("${swroot}/dhcp/settings", \%dhcpsettings);
&readhash("${swroot}/ethernet/settings", \%netsettings);
&readhash("${swroot}/openvpn/settings", \%openvpnsettings);

&showhttpheaders();
&openpage(_('Network status information'), 1, '');

&openbigbox($errormessage, $warnmessage, $notemessage);


my ($ref, $ref1, $ref2) = get_wan_ifaces_by_type('DHCP');
my @dhcpifaces = @$ref;
my @dhcplinks = @$ref1;

($ref, $ref1, $ref2) = get_wan_ifaces_by_type('ADSL');
my @adslifaces = @$ref;
my @adsllinks = @$ref;
my @adslconfigs = @$ref;

printf <<END
<table width='100%' cellspacing='0' cellpadding='5'border='0'>
    <tr>
        <td align='left'>
            <a href='#interfaces'>%s</a> |
END
,
_('Interfaces')
;

if ($#dhcpifaces >=0) {
    print "<a href='#wandhcp'>WAN  "._('DHCP configuration')."</a> |\n";
}
if ($dhcpsettings{'ENABLE_LAN'} eq 'on' || $dhcpsettings{'ENABLE_LAN2'} eq 'on') {
    print "<a href='#leases'>"._('Current dynamic leases')."</a> |\n";
}
if ($#adslconfigs >=0) {
    print "<a href='#adsl'>"._('ADSL settings')."</a> |\n";
}
printf <<END
            <a href='#nic'> %s</a> |
            <a href='#routing'>%s</a> |
            <a href='#arp'> %s</a>
        </td>
    </tr>
</table>
<br>
<a name='interfaces'></a>
END
,
_('NIC status'),
_('Routing table entries'),
_('ARP table entries');

&openbox('100%', 'left', _('Interfaces'));
print "</a>";
$output = `/sbin/ip addr show`;
$output = &cleanhtml($output,"y");

@itfs = ('DMZ','LAN2','LAN');
foreach my $itf (@itfs) {
    my $lc_itf=lc($itf);
    my $bridge = $netsettings{"${itf}_DEV"};
    if ($bridge =~ /^tun/) {
	$bridge = 'br2';
    }
    my $ref = get_zone_devices($bridge);
    my @ifaces = @$ref;
    # Exclude not configured interfaces.
    if (!@ifaces) {
	    $output =~ s/[0-9]?:\ $bridge.*?^([^\ ])/\1/sm;
	    next;
    }
    push(@ifaces, $bridge);
    if ($netsettings{"${itf}_DEV"} =~ /^tun/) {
	push(@ifaces, $netsettings{"${itf}_DEV"});
    }

    foreach my $dev (@ifaces) {
	chomp($dev);
	next if $dev =~ /^$/;
	$output =~ s/$dev/<b style="color: $colour${lc_itf};">${dev}<\/b>/;
    }
}

my @purpledev = ();
push(@purpledev, "ipsec");
if ($openvpnsettings{'PURPLE_DEVICE'}) {
    push(@purpledev, $openvpnsettings{'PURPLE_DEVICE'});
}
if (open(OVPN, "${swroot}/openvpn/clientconfig")) {
    foreach my $line (<OVPN>) {
	next if $line =~ /^$/;
	my @split = split(/:/, $line);
	if ($split[1]) {
	    push(@purpledev, $split[1]);
	}
    }
    close(OVPN);
}


foreach my $dev (@purpledev) {
    next if $dev =~ /^$/;
    my $lc_itf='purple';
    $output =~ s/$dev(\d*)/<b style="color: $colour${lc_itf};">${dev}\1<\/b>/g;
}

my $wanifs = get_wan_ifaces();
foreach my $line (@$wanifs) {
    chomp($line);
    next if $line =~ /^$/;
    my $lc_itf='wan';
    $output =~ s/$line(:\d+)?/<b style="color: $colour${lc_itf};">${line}\1<\/b>/g;
}

print "<pre>$output</pre>\n";
&closebox();



if ($#dhcpifaces >=0) {
    print "<a name='wandhcp'></a>\n";

    my $i=0;
    foreach my $dev (@dhcpifaces) {
	my $uplink = $dhcplinks[$i];
	$i++;
	my %dhcpinfo = ();
	&openbox('100%', 'left', "WAN "._('DHCP configuration')." ($uplink)");
	print "</a>";
	if (-s "/var/lib/dhclient/dhclient.$dev.info") {
	    &readhash("/var/lib/dhclient/dhclient.$dev.info", \%dhcpinfo);

	    my $expiry = strftime("%c", localtime($dhcpinfo{'EXPIRY'}));
            printf <<END
    <table width='100%'>
        <tr><td>%s</td><td>$dhcpinfo{'ASSIGNED_IP'}</td></tr>
        <tr><td>%s</td><td>$dhcpinfo{'SUBNET_MASK'}</td></tr>
        <tr><td>%s</td><td>$dhcpinfo{'ROUTERS'}</td></tr>
        <tr><td>%s</td><td>$dhcpinfo{'DNS'}</td></tr>
        <tr><td>%s</td><td>$dhcpinfo{'DHCP_SERVER'}</td></tr>
        <tr><td>%s</td><td>$expiry</td></tr>
        <tr><td>%s</td><td>$dhcpinfo{'DHCP_LEASE_TIME'}</td></tr>
    </table>
END
,
_('Assigned IP'),
_('Netmask'),
_('Gateway'),
_('Nameservers'),
_('DHCP server'),
_('Expires'),
_('Default lease time')
;
	} else {
	    print _('No DHCP lease has been acquired');
	}
	&closebox();
    }
}

if ($dhcpsettings{'ENABLE_LAN'} eq 'on' || $dhcpsettings{'ENABLE_LAN2'} eq 'on') {

	print "<a name='leases'></a>";
	&CheckSortOrder;
	&PrintActualLeases;
	#print "</a>";
}

if ($#adslconfigs >0) {
# XXX: needs rework
if ($pppsettings{'TYPE'} eq 'bewanadsl') {
	print "<a name='adsl'></a>\n";
	&openbox('100%', 'left', _('ADSL settings'));
	$output1 = `/usr/bin/unicorn_status`;
	$output1 = &cleanhtml($output1,"y");
	$output2 = `/bin/cat /proc/net/atm/UNICORN:*`;
	$output2 = &cleanhtml($output2,"y");
	print "<pre>$output1$output2</pre>\n";
	&closebox();
}
if ($pppsettings{'TYPE'} eq 'alcatelusbk') {
	print "<a name='adsl'></a>\n";
	&openbox('100%', 'left', _('ADSL settings'));
	$output = `/bin/cat /proc/net/atm/speedtch:*`;
	$output = &cleanhtml($output,"y");
	print "<pre>$output</pre>\n";
	&closebox();
}
if ($pppsettings{'TYPE'} eq 'conexantpciadsl') {
	print "<a name='adsl'></a>\n";
	&openbox('100%', 'left', _('ADSL settings'));
	$output = `/bin/cat /proc/net/atm/CnxAdsl:*`;
	$output = &cleanhtml($output,"y");
	print "<pre>$output</pre>\n";
	&closebox();
}
if ($pppsettings{'TYPE'} eq 'eagleusbadsl') {
	print "<a name='adsl'></a>\n";
	&openbox('100%', 'left', _('ADSL settings'));
	$output = `/usr/sbin/eaglestat`;
	$output = &cleanhtml($output,"y");
	print "<pre>$output</pre>\n";
	&closebox();
}

}

print "<a name='nic'></a>\n";
&openbox('100%', 'left', _('NIC status'));
my ($nicarr, $nichash, $nicstatus) = loadNicInfo();
if ($nicstatus && ! $nicstatus->{'exception'}) {
    print "<font class='base'>\n";
    print "<pre>\n";


    foreach my $device (@$nicarr) {
	my $iff = $nichash->{$device};
	my $statusinfo = $nicstatus->{$device};

	my $lc_itf = lc($iff->{'zone'});

	my $output = $iff->{'caption'};
	$output =~ s/$device/<b style="color: $colour${lc_itf};">${device}<\/b>/;
	if ($iff->{'link'} eq 'LINK OK') {
	    $output =~ s/(\[[^\[\]]+\])/<b>\1<\/b>/g;
	}

	print $output."\n";
	if ($statusinfo->{'speed'}) {
	    print "   " . _('Speed'). ": ". $statusinfo->{'speed'};
	    if ($statusinfo->{'duplex'}) {
		# this is for xgettext in order to retrieve possible values
		# of duplex.
		$translationhack = _('Full');
		$translationhack = _('Half');
		print "  " . _($statusinfo->{'duplex'}) . " " . _('Duplex');
	    }
	    print "\n";
	}
	if ($statusinfo->{'supports auto-negotiation'}) {
	    # value can be _('Yes') or _('No'), those are available through other translations.
	    print "   ". _("Support for auto-negotiation") . ": " 
		. _($statusinfo->{'supports auto-negotiation'}) . "  ";
	    if ($statusinfo->{'advertised auto-negotiation'}) {
		if ($statusinfo->{'advertised auto-negotiation'} eq 'Yes') {
		    print _('Advertised') . "  ";
		} else {
		    print _('Not advertised') . "  ";
		}
	    }
	    if ($statusinfo->{'auto-negotiation'}) {
		if ($statusinfo->{'auto-negotiation'} eq 'on') {
		    print _('Enabled') . "  ";
		} else {
		    print _('Disabled') . "  ";
		}
	    }
	    print "\n";
	}
	if ($statusinfo->{'advertised link modes'}) {
	    print "   ". _("Advertised link modes") . ":  ";
	    print join(" ", @{$statusinfo->{'advertised link modes'}});
	    print "\n";
	}
	if ($statusinfo->{'supported link modes'}) {
	    print "   ". _("Supported link modes") . ":  ";
	    print join(" ", @{$statusinfo->{'supported link modes'}});
	    print "\n";
	}

    }


    print "</pre>\n";
    print "</font>";
}
else {
    print _("<i>NIC status not available.</i>");
    print $nicstatus->{'error'};
}

&closebox();

print "<a name='routing'></a>\n";
&openbox('100%', 'left', _('Routing table entries'));
print "<font class='base'>\n";
$output = `/sbin/route -n`;
$output = &cleanhtml($output,"y");
print "<pre>$output</pre>\n";
print "</font>";
&closebox();

print "<a name='arp'></a>\n";
&openbox('100%', 'left', _('ARP table entries'));
print "<font class='base'>\n";
$output = `/sbin/arp -n`;
$output = &cleanhtml($output,"y");
print "<pre>$output</pre>\n";
print "</font>";
&closebox();

&closebigbox();

&closepage();
