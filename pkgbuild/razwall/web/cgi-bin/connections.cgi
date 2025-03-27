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

# Setup LAN, DMZ, IPCOP, VPN CIDR networks, masklengths and colours only once

my @network;
my @masklen;
my @colour;

use Net::IPv4Addr qw( :all );
use lib '/razwall/web/cgi-bin/';
require 'header.pl';

&getcgihash(\%par);

# Read various files

my %netsettings;
&readhash("${swroot}/ethernet/settings", \%netsettings);

# Add Green Firewall Interface
push(@network, $netsettings{'LAN_ADDRESS'});
push(@masklen, "255.255.255.255" );
push(@colour, $colourfw );

# Add Green Network to Array
push(@network, $netsettings{'LAN_NETADDRESS'});
push(@masklen, $netsettings{'LAN_NETMASK'} );
push(@colour, $colourgreen );

#print STDERR "LAN_DEV: $netsettings{'LAN_DEV'} \n";
# Add Green Routes to Array
my @routes = `/sbin/route -n | /bin/grep $netsettings{'LAN_DEV'}`;
foreach my $route (@routes) {
    chomp($route);
    my @temp = split(/[\t ]+/, $route);
	#print STDERR "TEMP0: $temp[0] \n";
	#print STDERR "TEMP2: $temp[2] \n";
	#print STDERR "color: $colourgreen \n";
    push(@network, $temp[0]);
    push(@masklen, $temp[2]);
    push(@colour, $colourgreen );
}
#print STDERR "COLORS: @colour \n";
# Add Firewall Localhost 127.0.0.1
push(@network, '127.0.0.1');
push(@masklen, '255.255.255.255' );
push(@colour, $colourfw );

push(@network, '127.0.0.2');
push(@masklen, '255.255.255.255' );
push(@colour, $colourfw );

# Add Orange Network
if (dmz_used()) {
	print STDERR "DMZ is used!\n";
    push(@network, $netsettings{'DMZ_NETADDRESS'});
    push(@masklen, $netsettings{'DMZ_NETMASK'} );
    push(@colour, $colourorange );
    # Add Orange Routes to Array
    @routes = `/sbin/route -n | /bin/grep $netsettings{'DMZ_DEV'}`;
    foreach my $route (@routes) {
        chomp($route);
        my @temp = split(/[\t ]+/, $route);
        push(@network, $temp[0]);
        push(@masklen, $temp[2]);
        push(@colour, $colourorange );
    }
}

# Add Blue Network
if (lan2_used()) {
	print STDERR "LAN2 is used!\n";
    push(@network, $netsettings{'LAN2_NETADDRESS'});
    push(@masklen, $netsettings{'LAN2_NETMASK'} );
    push(@colour, $colourblue );
    # Add Blue Routes to Array
    @routes = `/sbin/route -n | /bin/grep $netsettings{'LAN2_DEV'}`;
    foreach my $route (@routes) {
        chomp($route);
        my @temp = split(/[\t ]+/, $route);
        push(@network, $temp[0]);
        push(@masklen, $temp[2]);
        push(@colour, $colourblue );
    }
}

# add openvpn tunnels
my $tunnels = get_taps();
foreach my $taps (@$tunnels) {
    my $tun = $taps->{'tap'};
    my @routes = `/sbin/route -n | /bin/grep $tun`;
    foreach my $route (@routes) {
        chomp($route);
        my @temp = split(/[\t ]+/, $route);
        push(@network, $temp[0]);
        push(@masklen, $temp[2]);
        push(@colour, $colourvpn);
    }
}

# add remote openvpn networks
if (-f "${swroot}/openvpn/enable") {
    my %openvpnsettings=();
    &readhash("${swroot}/openvpn/settings", \%openvpnsettings);
    my @routes = `/sbin/route -n | /bin/grep $openvpnsettings{'PURPLE_DEVICE'}`;
    foreach my $route (@routes) {
        chomp($route);
        my @temp = split(/[\t ]+/, $route);
        push(@network, $temp[0]);
        push(@masklen, $temp[2]);
        push(@colour, $colourvpn);
    }
}

my $uplinksref = get_uplinks();
foreach my $uplink (@$uplinksref) {
    next if (! -f "${swroot}/uplinks/$uplink/active");
    next if (! -f "${swroot}/uplinks/$uplink/data");
    my %hash;
    readhash("${swroot}/uplinks/$uplink/data", \%hash);
    my $ip = $hash{'ip_address'};
    next if ($ip =~ /^$/);

    push(@network, $ip);
    push(@masklen, '255.255.255.255' );
    push(@colour, $colourfw );
}

&showhttpheaders();
if($par{'action'} ne 'reload') {
    &openpage(_('Connections'), 1, '');
    &openbigbox($errormessage, $warnmessage, $notemessage);
    &openbox('100%', 'left', _('IPTables connection tracking'));
}
if($par{'action'} ne 'reload') {
    printf <<END
        <script type="text/javascript">
            function loadConnections() {
                \$('#connections').load('/cgi-bin/connections.cgi', {action: 'reload'});
            }
            
            \$(document).ready(function() {
                var itvl = setInterval("loadConnections()", 1000*5);
            });
        </script>
END
;
}

if($par{'action'} ne 'reload') {
    print '<div id="connections">'
}

printf <<END
<table width='100%'>
<tr><td align='center'><b>%s: </b></td>
     <td align='center' bgcolor='$colourgreen'><b><font color='#FFFFFF'>%s</font></b></td>
     <td align='center' bgcolor='$colourred'><b><font color='#FFFFFF'>%s</font></b></td>
     <td align='center' bgcolor='$colourorange'><b><font color='#FFFFFF'>%s</font></b></td>
     <td align='center' bgcolor='$colourblue'><b><font color='#FFFFFF'>%s</font></b></td>
     <td align='center' bgcolor='$colourfw'><b><font color='#FFFFFF'>%s</font></b></td>
     <td align='center' bgcolor='$colourvpn'><b><font color='#FFFFFF'>%s</font></b></td>
</tr>
</table>
<br />
<table cellpadding='2' width="100%">
  <tr>
    <td align='center'><b>%s</b></td>
    <td align='center'><b>%s</b></td>
    <td align='center'><b>%s</b></td>
    <td align='center'><b>%s</b></td>
    <td align='center'><b>%s</b></td>
    <td align='center'><b>%s</b></td>
    <td align='center'><b>%s</b></td>
  </tr>
END
, 
_('Legend'), 
_('LAN'), 
_('INTERNET'), 
_('DMZ'), 
_('Wireless'), 
$brand.' '.$product,
_('VPN (IPsec)'),
_('Source IP'),
_('Source port'),
_('Destination IP'),
_('Destination port'),
_('Protocol'),
_('Status'),
_('Expires')

;

my @active = `iptstate -s -R -bt`;

#open (ACTIVE, "/proc/net/ipsec_eroute");
#my @vpn = <ACTIVE>;
#close (ACTIVE);


my $i=0;
my %color_hash = ();
foreach my $line (@active) {
    $i++;
    if ($i < 3) {
        next;
    }
    chomp($line);
    my @temp = split(' ',$line);

    my ($sip, $sport) = split(':', $temp[0]);
    my ($dip, $dport) = split(':', $temp[1]);
    my $proto = $temp[2];
    my $state = $temp[3];
    my $ttl = $temp[4];

    if (($proto eq 'udp') && ($ttl eq '')) {
        $ttl = $state;
        $state = '&nbsp;';  
    }

    if ( not exists $color_hash{ $sip } ) {
        $color_hash{ $sip } = ipcolour($sip);
    }
    if ( not exists $color_hash{ $dip } ) {
        $color_hash{ $dip } = ipcolour($dip);
    }

    my $dipcol = $color_hash{ $dip };
    my $sipcol = $color_hash{ $sip };

    my $sserv = '';
    if ($sport < 1024) {
        $sserv = uc(getservbyport($sport, lc($proto)));
        if ($sserv ne '') {
            $sserv = "&nbsp($sserv)";
        }
    }

    my $dserv = '';
    if ($dport < 1024) {
        $dserv = uc(getservbyport($dport, lc($proto)));
        if ($dserv ne '') {
            $dserv = "&nbsp($dserv)";
        }
    }

    printf <<END
    <tr class='odd'>
      <td align='center' bgcolor='$sipcol'>
        <a href='/cgi-bin/ipinfo.cgi?ip=$sip'>
          <font color='#FFFFFF'>$sip</font>
        </a>
      </td>
      <td align='center' bgcolor='$sipcol'>
        <a href='http://isc.sans.org/port_details.php?port=$sport' target='top'>
          <font color='#FFFFFF'>$sport$sserv</font>
        </a>
      </td>
      <td align='center' bgcolor='$dipcol'>
        <a href='/cgi-bin/ipinfo.cgi?ip=$dip'>
          <font color='#FFFFFF'>$dip</font>
        </a>
      </td>
      <td align='center' bgcolor='$dipcol'>
        <a href='http://isc.sans.org/port_details.php?port=$dport' target='top'>
          <font color='#FFFFFF'>$dport$dserv</font>
        </a>
      </td>
      <td align='center'>$proto</td>
      <td align='center'>$state</td>
      <td align='center'>$ttl</td>
    </tr>
END
;
}

print '</table>';

if($par{'action'} ne 'reload') {
    print '</div>';
}

if($par{'action'} ne 'reload') {
    &closebox();
    &closebigbox();
    &closepage();
}

sub ipcolour($) {
    my $id = 0;
    my $line;
    my $colour = $colourred;
    my ($ip) = $_[0];
    foreach my $line (@network)
    {
        if (ipv4_in_network( $network[$id] , $masklen[$id], $ip) ) {
            return $colour[$id];
        }
        $id++;
    }
    return $colour
}
