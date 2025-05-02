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
#use strict;
#use warnings;
use Net::IPv4Addr qw( :all );
use lib '/razwall/web/cgi-bin/';
require 'header.pl';

&getcgihash(\%par);

# Build network arrays from settings (same as before)...
# (Your network, masklen, and colour arrays creation code goes here)

# ...

# Instead of iptstate, we now use /proc/net/tcp and /proc/net/udp.
my @active;

# Helper: Convert an 8-digit hex string to a dotted-decimal IP.
sub hex_to_ip {
    my $hex = shift;
    # Pack the hex string into four bytes.
    my @bytes = unpack("C4", pack("H8", $hex));
    # Since the numbers are in little-endian order, reverse them.
    return join(".", reverse @bytes);
}

# Read TCP connections from /proc/net/tcp.
if (-e "/proc/net/tcp") {
    open my $fh, '<', "/proc/net/tcp" or die "Cannot open /proc/net/tcp: $!";
    my $header = <$fh>;  # skip header line
    while (<$fh>) {
        chomp;
        my @fields = split(/\s+/, $_);
        # fields: 0=sl, 1=local_address, 2=rem_address, 3=st, etc.
        my $local = $fields[1];
        my $remote = $fields[2];
        my $state = $fields[3];  # hex state (e.g., "01")
        my ($laddr, $lport) = split(":", $local);
        my ($raddr, $rport) = split(":", $remote);
        $laddr = hex_to_ip($laddr);
        $raddr = hex_to_ip($raddr);
        $lport = hex($lport);
        $rport = hex($rport);
        push @active, {
            sip   => $laddr,
            sport => $lport,
            dip   => $raddr,
            dport => $rport,
            proto => "tcp",
            state => $state,
        };
    }
    close $fh;
}

# Read UDP connections from /proc/net/udp.
if (-e "/proc/net/udp") {
    open my $fh, '<', "/proc/net/udp" or die "Cannot open /proc/net/udp: $!";
    my $header = <$fh>;  # skip header line
    while (<$fh>) {
        chomp;
        my @fields = split(/\s+/, $_);
        my $local = $fields[1];
        my $remote = $fields[2];
        my $state = $fields[3];
        my ($laddr, $lport) = split(":", $local);
        my ($raddr, $rport) = split(":", $remote);
        $laddr = hex_to_ip($laddr);
        $raddr = hex_to_ip($raddr);
        $lport = hex($lport);
        $rport = hex($rport);
        push @active, {
            sip   => $laddr,
            sport => $lport,
            dip   => $raddr,
            dport => $rport,
            proto => "udp",
            state => $state,
        };
    }
    close $fh;
}

# Now output the connection data as table rows
my $i = 0;
my %color_hash = ();
foreach my $conn (@active) {
    $i++;
    my $sip   = $conn->{sip} // "";
    my $sport = $conn->{sport} // "";
    my $dip   = $conn->{dip} // "";
    my $dport = $conn->{dport} // "";
    my $proto = $conn->{proto} // "";
    my $state = $conn->{state} // "";
    
    if (not exists $color_hash{$sip}) {
        $color_hash{$sip} = ipcolour($sip);
    }
    if (not exists $color_hash{$dip}) {
        $color_hash{$dip} = ipcolour($dip);
    }
    my $sipcol = $color_hash{$sip};
    my $dipcol = $color_hash{$dip};
    
    my $sserv = '';
    if ($sport < 1024) {
        $sserv = uc(getservbyport($sport, lc($proto)));
        $sserv = ($sserv ne '') ? "&nbsp($sserv)" : "";
    }
    my $dserv = '';
    if ($dport < 1024) {
        $dserv = uc(getservbyport($dport, lc($proto)));
        $dserv = ($dserv ne '') ? "&nbsp($dserv)" : "";
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
      <td align='center'>--</td>
    </tr>
END
;
}

print '</table>';

if ($par{'action'} ne 'reload') {
    print '</div>';
}

if ($par{'action'} ne 'reload') {
    &closebox();
    &closebigbox();
    &closepage();
}

sub ipcolour($) {
    my $id = 0;
    my $line;
    my $colour = $colourred;
    my ($ip) = $_[0];
    foreach my $line (@network) {
        if (ipv4_in_network($network[$id], $masklen[$id], $ip)) {
            return $colour[$id];
        }
        $id++;
    }
    return $colour;
}
