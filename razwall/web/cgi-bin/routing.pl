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

$reload = 0;
$routing_config = "${swroot}/routing/config";
$routing_settigns = "${swroot}/routing/settings";
$routing_default_settings = "${swroot}/routing/default/settings";
$ethernet_settings = "${swroot}/ethernet/settings";
$setrouting = "/usr/local/bin/setrouting";
$setpolicyrouting = "/usr/local/bin/setpolicyrouting";
$openvpn_passwd   = '/usr/bin/openvpn-sudo-user';
$needreload = "${swroot}/routing/needreload";
#$reload = 0;

sub read_config_file() {
    my @lines;
    open (FILE, "$routing_config");
    foreach my $line (<FILE>) {
        chomp($line);
        $line =~ s/[\r\n]//g;
        if (!is_valid($line)) {
            next;
        }
        push(@lines, $line);
    }
    close (FILE);
    return @lines;
}

sub read_config_line($) {
    my $line = shift;
    my @lines = read_config_file();
    return $lines[$line];
}

sub save_config_file($) {
    my $ref = shift;
    my @lines = @$ref;
    open (FILE, ">$routing_config");
    foreach my $line (@lines) {
        if ($line ne "") {
            print FILE "$line\n";
        }
    }
    close(FILE);
    $reload = 1;
}

sub line_count() {
    open (FILE, "$routing_config") || return 0;
    my $i = 0;
    foreach (<FILE>) {
        $i++;
    }
    close FILE;
    return $i;
}

sub append_config_file($) {
    my $line = shift;
    open (FILE, ">>$routing_config");
    print FILE $line."\n";
    close FILE;
    $reload = 1;
}

sub is_valid($) {
    my $line = shift;
    # temporary hack;
    # if ($line =~ /(?:(?:[^,]*),){10}/ || $line =~ /(?:(?:[^,]*),){7}/) {
    #     return 1;
    # }
    return 1;
}

sub config_line($) {
    my $line = shift;
    my %config;
    $config{'valid'} = 0;
    if (! is_valid($line)) {
        return;
    }
    my @temp = split(/,/, $line);
    $config{'enabled'} = $temp[0];
    $config{'source'} = $temp[1];
    $config{'destination'} = $temp[2];
    $config{'gw'} = $temp[3];
    $config{'remark'} = $temp[4];
    $config{'tos'} = $temp[5];
    $config{'protocol'} = $temp[6];
    $config{'port'} = $temp[7];
    $config{'mac'} = $temp[8];
    $config{'log'} = $temp[9];
    $config{'src_dev'} = $temp[10];
    $config{'backup_allow'} = $temp[11];
    $config{'valid'} = 1;

    return %config;
}

sub toggle_enable($$) {
    my $line = shift;
    my $enable = shift;
    if ($enable) {
        $enable = 'on';
    } 
    else {
        $enable = 'off';
    }

    my %data = config_line(read_config_line($line));
    $data{'enabled'} = $enable;

    return save_line($line,
                     $data{'enabled'},
                     $data{'source'},
                     $data{'destination'},
                     $data{'gw'},
                     $data{'remark'},
                     $data{'tos'},
                     $data{'protocol'},
                     $data{'port'},
                     $data{'mac'},
                     $data{'log'},
                     $data{'src_dev'},
                     $data{'backup_allow'});
}

sub delete_line($) {
    my $line = shift;
    my @lines = read_config_file();
    if (! @lines[$line]) {
        return;
    }
    delete (@lines[$line]);
    save_config_file(\@lines);
}

sub create_line($$$$$$$$$$$$) {
    my $enabled = shift;
    my $source = shift;
    my $destination = shift;
    my $gateway = shift;
    my $remark = shift;
    my $tos = shift;
    my $protocol = shift;
    my $port = shift;
    my $mac = shift;
    my $log = shift;
    my $src_dev = shift;
    my $backup_allow = shift;

    return "$enabled,$source,$destination,$gateway,$remark,$tos,$protocol,$port,$mac,$log,$src_dev,$backup_allow";
}

sub save_line($$$$$$$$$$$$$) {
    my $line = shift;
    my $enabled = shift;
    my $source = shift;
    my $destination = shift;
    my $gateway = shift;
    my $remark = shift;
    my $tos = shift;
    my $protocol = shift;
    my $port = shift;
    my $mac = shift;
    my $log = shift;
    my $src_dev = shift;
    my $backup_allow = shift;

    $source =~ s/\n/&/gm;
    $source =~ s/\r//gm;
    $destination =~ s/\n/&/gm;
    $destination =~ s/\r//gm;
    $gateway =~ s/\n/&/gm;
    $gateway =~ s/\r//gm;
    $tos =~ s/\n/&/gm;
    $tos =~ s/\r//gm;
    $port =~ s/\n/&/gm;
    $port =~ s/\r//gm;
    $port =~ s/\-/:/g;
    $mac =~ s/\n/&/gm;
    $mac =~ s/\r//gm;
    $mac =~ s/\-/:/g;
    $remark =~ s/\,//g;
    $src_dev =~ s/\|/&/g;
    $source =~ s/\|/&/g;
    $destination =~ s/\|/&/g;

    if (!($enabled eq "on")){
	$enabled = "off";
    }

    if ($source =~ /OPENVPNUSER:ALL/) {
        $source = 'OPENVPNUSER:ALL';
    }
    if ($destination =~ /OPENVPNUSER:ALL/) {
        $destination = 'OPENVPNUSER:ALL';
    }
    if ($destination =~ /L2TPIP:ALL/) {
        $destination = 'L2TPIP:ALL';
    }
    if ($source =~ /none/) {
        $source = '';
    }
    if ($destination =~ /none/) {
        $destination = '';
    }
    if ($source =~ '(?:^|&)0.0.0.0/0(?:$|&)') {
	$source = '';
    }
    if ($destination =~ '(?:^|&)0.0.0.0/0(?:$|&)') {
	$destination = '';
    }


    if ($src_dev =~ /L2TPDEVICE:ALL/) {
        $src_dev = 'L2TPDEVICE:ALL';
    } elsif ($src_dev =~ /ALL/) {
        $src_dev = 'ALL';
    }
    if ($src_dev =~ /none/) {
        $src_dev = '';
    }

    if ($source !~ /^$/) {
        $src_dev = '';
    }
    if ($mac !~ /^$/) {
        $source = '';
        $src_dev = '';
    }
    if ($port =~ /any/) {
       $port = '';
    }
    if ($protocol =~ /any/) {
        $protocol = '';
    }

    if ($protocol eq 'icmp') {
        $port = '8&30';
    }
    
    if (! check_values($enabled, $source, $destination, $gateway, $remark, $tos, $protocol, $port, $mac, $log, $src_dev, $backup_allow)) {
        return 0;
    }

    my $tosave = create_line($enabled, $source, $destination, $gateway, $remark, $tos, $protocol, $port, $mac, $log, $src_dev, $backup_allow);
    
    if ($line !~ /^\d+$/) {
        append_config_file($tosave);
        return 1;
    }
    my @lines = read_config_file();
    if (! $lines[$line]) {
        push(@errormessages, _('Configuration line not found!'));
        return 0;
    }

    my %split = config_line($lines[$line]);
    if (($split{'enabled'} ne $enabled) ||
            ($split{'source'} ne $source) ||
            ($split{'destination'} ne $destination) ||
            ($split{'gw'} ne $gateway) ||
            ($split{'remark'} ne $remark) ||
            ($split{'tos'} ne $tos) ||
            ($split{'protocol'} ne $protocol) ||
            ($split{'port'} ne $port) ||
            ($split{'mac'} ne $mac) ||
            ($split{'log'} ne $log) ||
            ($split{'src_dev'} ne $src_dev) ||
            ($split{'backup_allow'} ne $backup_allow)) {
        $lines[$line] = $tosave;
        save_config_file(\@lines);
    }
    return 1;
}

sub check_values($$$$$$$$$$$$) {
    my $enabled = shift;
    my $source = shift;
    my $destination = shift;
    my $gateway = shift;
    my $remark = shift;
    my $tos = shift;
    my $protocol = shift;
    my $port = shift;
    my $mac = shift;
    my $log = shift;
    my $src_dev = shift;
    my $backup_allow = shift;
    
    my %valid_proto = ('TCP' => 1, 'UDP' => 1, 'TCP&UDP' => 1, 'ESP' => 1, 'GRE' => 1, 'ICMP' => 1);
    

    if ($protocol !~ /^$/) {
        if (! $valid_proto{uc($protocol)}) {
            push(@errormessages, _('Invalid protocol'));
        }
    }
    foreach my $item (split(/&/, $source)) {
        next if ($item =~ /^OPENVPNUSER:/);
        if (! is_ipaddress($item)) {
            push(@errormessages, _('Invalid source IP address "%s"', $item));
        }
    }
    foreach my $item (split(/&/, $mac)) {
        if (!validmac($item)) {
            push(@errormessages, _('Invalid MAC address "%s"', $item));
        }
    }
    foreach my $item (split(/&/, $destination)) {
        next if ($item =~ /^OPENVPNUSER:/);
        next if ($item =~ /^L2TPIP:/);
        if (!is_ipaddress($item)) {
            push(@errormessages, _('Invalid destination IP address "%s"', $item));
        }
    }
    foreach my $ports (split(/&/, $port)) {
        if ($ports !~ /^(\d{1,5})(?:\:(\d{1,5}))?$/) {
            push(@errormessages, _('Invalid destination port "%s"', $ports));
        }
        my $port1 = $1;
        my $port2 = '65535';
        if ($2) {
            $port2 = $2;
        }

        if (($port1 < 0) || ($port1 > 65535)) {
            push(@errormessages, _('Invalid destination port "%s"', $port1));
        }
        if(($port2 < 0) || ($port2 > 65535)) {
            push(@errormessages, _('Invalid destination port "%s"', $port2));
        }
        if ($port1 > $port2) {
            push(@errormessages, _('The destination port range has a first value that is greater than or equal to the second value.'));
        }
    }
    
    if ($gateway =~ /^$/) {
        push(@errormessages, _('Gateway cannot be empty.'));
    }
    elsif (($gateway !~ /^UPLINK:/) && 
	   ($gateway !~ /^L2TPIP:/)&& 
	   ($gateway !~ /^OPENVPNUSER:/)) {
        if (! is_ipaddress($gateway)) {
            push(@errormessages, _('Invalid gateway address.'));
        }
        elsif ($gw =~ /\//) {
            push(@errormessages, _('Gateway needs to be an ip address instead of a network.'));
        }
    }

    if ($tos !~ /^$/) {
        if ($tos != "0x00" && $tos != "0x10" && $tos != "0x08" && $tos != "0x04") {
            push(@errormessages, _('Type of Service value is invalid!'));
        }
    }
    
    if ($#errormessages eq -1) {
        return 1
    }
    else {
        return 0;
    } 
}
