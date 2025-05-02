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
require 'razinc.pl';
my $l2tp = 0;
eval {
    require l2tplib;
    $l2tp = 1;
};

$thisPath = $ENV{'REQUEST_URI'};
$thisAddress = $ENV{'SERVER_NAME'};

# Configuration paths setdnat.cgi
#$reload_flag = "/razwall/config/dnat/needreload"; # Path to the reload flag
#$config_file = '/razwall/config/dnat/config';
#$output_file = '/razwall/firewall/dnat/iptablesdnat';

my $configfile = "${swroot}/dnat/config";
my $configfile_default = "/razwall/settings/dnat/config.default";
my $ethernet_settings = "${swroot}/ethernet/settings";
my $interface_settings = "${swroot}/interfaces/settings";
my $zone_settings = "${swroot}/zones/settings";
my $setdnat = "/razwall/web/cgi-bin/setdnat.cgi";
my $openvpn_passwd   = '/usr/bin/openvpn-sudo-user';
my $confdir = '/razwall/firewall/dnat/';
my $needreload = "${swroot}/dnat/needreload";

my $ALLOW_PNG = '/images/firewall_accept.png';
my $IPS_PNG = '/images/firewall_ips.png';
my $DENY_PNG = '/images/firewall_drop.png';
my $REJECT_PNG = '/images/firewall_reject.png';
my $RETURN_PNG = '/images/return.png';
my $MAP_PNG = '/images/map.png';
my $UP_PNG = '/images/stock_up-16.png';
my $DOWN_PNG = '/images/stock_down-16.png';
my $ENABLED_PNG = '/images/on.png';
my $DISABLED_PNG = '/images/off.png';
my $ADD_PNG = '/images/add.png';
my $EDIT_PNG = '/images/edit.png';
my $DELETE_PNG = '/images/delete.png';
my $OPTIONAL_PNG = '/images/blob.png';

my (%par,%checked,%selected,%ether);
my @errormessages = ();
my $log_accepts = 'off';
my @nets;
my $reload = 0;

my $devices, $deviceshash = 0;

my $services_file = '/razwall/settings/dnat/services';
my $services_custom_file = '/razwall/config/dnat/services.custom';

&readhash($ethernet_settings, \%ether);

#sub have_net($) { # REMOVED IN RAZWALL 4/24/2025 - LEAVING FOR HISTORICAL PURPOSES 
#    my $net = shift;

    # AAAAAAARGH! dumb fools
#    my %net_config = (
#        'LAN' => [1,1,1,1,1,1,1,1,1,1],
#        'DMZ' => [0,1,0,3,0,5,0,7,0,0],
#        'LAN2' => [0,0,0,0,4,5,6,7,0,0]
#    );

#    if ($net_config{$net}[$ether{'CONFIG_TYPE'}] > 0) {
#        return 1;
#    }
#    return 0;
#}

sub configure_nets() {
	my @totest = &get_zones; # FETCH DYNAMIC ZONES - RAZWALL

    foreach (@totest) {
        my $thisnet = $_;
        if ($ether{$thisnet.'_DEV'}) {
            push (@nets, $thisnet);
        }
    }
}

sub get_zones() { # ADDED FOR RAZWALL DYNAMIC ZONES
	return read_config_file($zone_settings);
}

sub get_openvpn_lease() {
    my @users = sort split(/\n/, `$openvpn_passwd list`);
    return \@users;
}

sub read_config_file($$) {
    my $filename = shift;
    my $filename_default = shift;
    my @lines;
    if (! -e $filename) {
	$filename = $filename_default;
    }
    open (FILE, "$filename");
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
    my @lines = read_config_file($configfile, $configfile_default);
    return $lines[$line];
}

sub save_config_file($) {
    my $ref = shift;
    my @lines = @$ref;
    open (FILE, ">$configfile");
    foreach my $line (@lines) {
        if ($line ne "") {
            print FILE "$line\n";
        }
    }
    close(FILE);
    $reload = 1;
}

sub line_count() {
    my $filename = $configfile;
    if (! -e $filename) {
	$filename = $configfile_default;
    }
    open (FILE, "$filename") || return 0;
    my $i = 0;
    foreach (<FILE>) {
        $i++;
    }
    close FILE;
    return $i;
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
    $config{'protocol'} = $temp[1];
    $config{'src_dev'} = $temp[2];
    $config{'source'} = $temp[3];
    $config{'dst_dev'} = $temp[4];
    $config{'destination'} = $temp[5];
    $config{'port'} = $temp[6];
    $config{'target_ip'} = $temp[7];
    $config{'target_port'} = $temp[8];
    $config{'nat_target'} = $temp[9];
    $config{'remark'} = $temp[10];
    $config{'log'} = $temp[11];
    $config{'filter_target'} = $temp[12];
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
		     $data{'protocol'},
		     $data{'src_dev'},
		     $data{'source'},
		     $data{'dst_dev'},
		     $data{'destination'},
		     $data{'port'},
		     $data{'target_ip'},
		     $data{'target_port'},
		     $data{'nat_target'},
		     $data{'remark'},
		     $data{'log'},
		     $data{'filter_target'});
}

sub move($$) {
    my $line = shift;
    my $direction = shift;
    my $newline = $line + $direction;
    if ($newline < 0) {
        return;
    }
    my @lines = read_config_file($configfile, $configfile_default);

    if ($newline >= scalar(@lines)) {
        return;
    }

    my $temp = $lines[$line];
    $lines[$line] = $lines[$newline];
    $lines[$newline] = $temp;
    save_config_file(\@lines);
}

sub set_position($$) {
    my $old = shift;
    my $new = shift;
    my @lines = read_config_file($configfile, $configfile_default);
    my $myline = $lines[$old];
    my @newlines = ();

    # nothing to do
    if ($new == $old) {
        return;
    }
   
    if ($new > $#lines+1) {
        $new = $#lines+1;
    }

    open (FILE, ">$configfile");

    for ($i=0;$i<=$#lines+1; $i++) {
        if (($i == $new) && (($i==0) || ($i == $#lines) || ($old > $new))) {
            print FILE "$myline\n";
            if (!("$lines[$i]" eq "")) {
                print FILE "$lines[$i]\n";
            }
        }
        elsif (($i == $new)) {
            if (!("$lines[$i]" eq "")) {
                print FILE "$lines[$i]\n";
            }
            print FILE "$myline\n";                
        }
        else {
            if ($i != $old) {
                if (!("$lines[$i]" eq "")) {
                    print FILE "$lines[$i]\n";
                }
            }
        }
    }

    close(FILE);
}

sub delete_line($) {
    my $line = shift;
    my @lines = read_config_file($configfile, $configfile_default);
    if (! @lines[$line]) {
        return;
    }
    delete (@lines[$line]);
    save_config_file(\@lines);
}

sub create_line($$$$$$$$$$$$$) {

    my $enabled = shift;
    my $proto = shift;
    my $src_dev = shift;
    my $src_ip = shift;
    my $dst_dev = shift;
    my $dst_ip = shift;
    my $dst_port = shift;
    my $target_ip = shift;
    my $target_port = shift;
    my $nat_target = shift;
    my $remark = shift;
    my $log = shift;
    my $filter_target = shift;

    return "$enabled,$proto,$src_dev,$src_ip,$dst_dev,$dst_ip,$dst_port,$target_ip,$target_port,$nat_target,$remark,$log,$filter_target";
}

sub check_values($$$$$$$$$$$$$) {
    my $enabled = shift;
    my $proto = shift;
    my $src_dev = shift;
    my $src_ip = shift;
    my $dst_dev = shift;
    my $dst_ip = shift;
    my $dst_port = shift;
    my $target_ip = shift;
    my $target_port = shift;
    my $nat_target = shift;
    my $remark = shift;
    my $log = shift;
    my $filter_target = shift;
    
    my %valid_proto = ('TCP' => 1, 'UDP' => 1, 'TCP&UDP' => 1, 'ESP' => 1, 'GRE' => 1, 'ICMP' => 1);
    
    if ($protocol !~ /^$/) {
        if (! $valid_proto{uc($protocol)}) {
            push(@errormessages, _('Invalid protocol'));
        }
    }
    
    if ($dst_ip eq "" && $dst_dev eq "") {
        push(@errormessages, _('Incoming IP must be defined'));
    }
    
    foreach my $src (split(/\|/, $src_ip)) {
        foreach my $item (split(/&|\-/, $src)) {
            next if ($item =~ /^$/);
            next if ($item =~ /^OPENVPNUSER:/);
            next if ($item =~ /^any$/);
            if (! is_ipaddress($item)) {
                push(@errormessages, _('Invalid source IP address "%s"', $item));
            }
        }
    }

    foreach my $item (split(/&|\-/, $dst_ip)) {
        next if ($item =~ /^OPENVPNUSER:/);
        next if ($item =~ /^$/);
        if (!is_ipaddress($item)) {
            push(@errormessages, _('Invalid destination IP address "%s"', $item));
        }
    }

    foreach my $ports (split(/&|\-/, $dst_port)) {
        if ($ports !~ /^(\d{1,5})(?:\:(\d{1,5}))?$/) {
            push(@errormessages, _('Invalid incoming port "%s"', $ports));
        }
        my $port1 = $1;
        my $port2 = '65535';
        if ($2) {
            $port2 = $2;
        }

        if (($port1 < 0) || ($port1 > 65535)) {
            push(@errormessages, _('Invalid incoming port "%s"', $port1));
        }
        if(($port2 < 0) || ($port2 > 65535)) {
            push(@errormessages, _('Invalid incoming port "%s"', $port2));
        }
        if ($port1 > $port2) {
            push(@errormessages, _('The incoming port range has a first value that is greater than or equal to the second value.'));
        }
    }

    foreach my $item (split(/&|\-/, $target_ip)) {
        next if ($item =~ /^OPENVPNUSER:/);
        next if ($item =~ /^L2TPIP:/);
        next if ($item =~ /^$/);
        if (!is_ipaddress($item)) {
            push(@errormessages, _('Invalid target IP address "%s"', $item));
        }
    }

    if ($target eq 'NETMAP') {
	if (!validipandmask($target_ip)) {
	    push(@errormessages, _('Translation target "%s" is no subnet. Net mapping requires a subnet.', $target_ip));
	}
	my ($eat,$target_bits) = ipv4_parse($target_ip);

	if ($dst_ip eq '') {
	    push(@errormessages, _('Target must be a subnet!'));
	}
	foreach my $item (split(/&|\-/, $dst_ip)) {
	    next if ($item =~ /^$/);
	    if (!validipandmask($item)) {
		push(@errormessages, _('Target "%s" is no subnet. Net mapping requires a subnet.', $item));
		next;
	    }
	    my ($eat,$item_bits) = ipv4_parse($item);
	    if ($target_bits ne $item_bits) {
		push(@errormessages, _('Net mapping requires destination (%s) and translation subnet (%s) of equal size.', $item, $target_ip));
		next;
	    }
	}
    }

    foreach my $ports (split(/&|\-/, $target_port)) {
        if ($ports !~ /^(\d{1,5})(?:\:(\d{1,5}))?$/) {
            push(@errormessages, _('Invalid target port "%s"', $ports));
        }
        my $port1 = $1;
        my $port2 = '65535';
        if ($2) {
            $port2 = $2;
        }

        if (($port1 < 0) || ($port1 > 65535)) {
            push(@errormessages, _('Invalid target port "%s"', $port1));
        }
        if(($port2 < 0) || ($port2 > 65535)) {
            push(@errormessages, _('Invalid target port "%s"', $port2));
        }
        if ($port1 > $port2) {
            push(@errormessages, _('The target port range has a first value that is greater than or equal to the second value.'));
        }
    }

    if ($#errormessages eq -1) {
        return 1
    }
    else {
        return 0;
    } 
}

sub save_line($$$$$$$$$$$$$$) {

    my $line = shift;
    my $enabled = shift;
    my $proto = shift;
    my $src_dev = shift;
    my $src_ip = shift;
    my $dst_dev = shift;
    my $dst_ip = shift;
    my $dst_port = shift;
    my $target_ip = shift;
    my $target_port = shift;
    my $nat_target = shift;
    my $remark = shift;
    my $log = shift;
    my $filter_target = shift;
    
    # $src_ip =~ s/\n/&/gm;
    # $src_ip =~ s/\r//gm;
    $dst_ip =~ s/\n/&/gm;
    $dst_ip =~ s/\r//gm;
    $target_ip =~ s/\n/&/gm;
    $target_ip =~ s/\r//gm;
    $dst_port =~ s/\n/&/gm;
    $dst_port =~ s/\r//gm;
    $target_port =~ s/\-/:/g;
    $target_port =~ s/\n/&/gm;
    $target_port =~ s/\r//gm;
    $remark =~ s/\,//g;
    $dst_dev =~ s/\|/&/g;
    #$src_dev =~ s/\|/&/g;
    #$src_ip =~ s/\|/&/g;
    $dst_ip =~ s/\|/&/g;
    $target_ip =~ s/\|/&/g;
    $proto =~ s/\+/&/g;

    # if ($src_ip =~ /OPENVPNUSER:ALL/) {
    #     $src_ip = 'OPENVPNUSER:ALL';
    # }
    if ($target_ip =~ /OPENVPNUSER:ALL/) {
        $target_ip = 'OPENVPNUSER:ALL';
    }
    if ($target_ip =~ /L2TPIP:ALL/) {
        $target_ip = 'L2TPIP:ALL';
    }
    # if ($src_ip =~ /none/) {
    #     $src_ip = '';
    # }
    if ($dst_ip =~ /none/) {
        $dst_ip = '';
    }

    # if ($src_dev =~ /ALL/) {
    #     $src_dev = 'ALL';
    # }
    if ($src_dev =~ /none/) {
        $src_dev = '';
    }
    if ($dst_dev =~ /none/) {
        $dst_dev = '';
    }
    
    if ($dst_port =~ /any/) {
       $dst_port = '';
    }
    if ($proto =~ /any/) {
        $proto = '';
    }

    if ($proto eq 'icmp') {
        $dst_port = '8&30';
    }

    if ($nat_target eq 'NETMAP') {
	$filter_target = 'RETURN';
    }
    if ($nat_target eq 'RETURN') {
	$filter_target = 'RETURN';
    }

    if (! check_values($enabled, $proto, $src_dev, $src_ip, $dst_dev, 
		       $dst_ip, $dst_port, $target_ip, $target_port, 
		       $nat_target, $remark, $log, $filter_target)) {
        return 0;
    }
    my $tosave = create_line($enabled, $proto, $src_dev, $src_ip, $dst_dev, 
			     $dst_ip, $dst_port, $target_ip, $target_port, 
			     $nat_target, $remark, $log, $filter_target);
    my @lines = read_config_file($configfile, $configfile_default);
    if ($line !~ /^\d+$/) {
	push(@lines, $tosave);
	save_config_file(\@lines);
        return 1;
    }
    if (! $lines[$line]) {
        push(@errormessages, _('Configuration line not found!'));
        return 0;
    }

    my %split = config_line($lines[$line]);
    if (
	($split{'enabled'} ne $enabled) ||
	($split{'protocol'} ne $proto) ||
	($split{'src_dev'} ne $src_dev) ||
	($split{'source'} ne $src_ip) ||
	($split{'dst_dev'} ne $dst_dev) ||
	($split{'destination'} ne $dst_ip) ||
	($split{'port'} ne $dst_port) ||
	($split{'target_ip'} ne $target_ip) ||
	($split{'target_port'} ne $target_port) ||
	($split{'nat_target'} ne $nat_target) ||
	($split{'filter_target'} ne $filter_target) ||
	($split{'remark'} ne $remark) ||
	($split{'log'} ne $log)
	) {
        $lines[$line] = $tosave;
        save_config_file(\@lines);
    }
    return 1;
}

sub generate_addressing($$$$) {
    my $addr = shift;
    my $dev = shift;
    my $mac = shift;
    my $rulenr = shift;
    my @addr_values = ();

    foreach my $item (split(/&/, $addr)) {
        if ($item =~ /^OPENVPNUSER:(.*)$/) {
            my $user = $1;
            push(@addr_values, _("%s (OpenVPN User)", $user));
        }
        elsif ($item =~ /^L2TPIP:(.*)$/) {
            my $user = $1;
            push(@addr_values, _("%s (L2TP user)", $user));
        }
        else {
            push(@addr_values, $item);
        }
    }
    foreach my $item (split(/&/, $dev)) {
	my $ip = '';
	my $preip = '';
	my $postip = '';
	if ($item =~ /^(\d[\d\.]*):/) {
	    $ip = $1;
	    $preip = "$ip (";
	    $postip = ")";
	}
        if ($item =~ /^(?:.*:)?PHYSDEV:(.*)$/) {
            my $device = $1;
            my $data = $deviceshash->{$device};

	    push(@addr_values, "$preip<font color='". $zonecolors{$data->{'zone'}} ."'>".$data->{'portlabel'}."</font>$postip");
        }
        elsif ($item =~ /^(?:.*:)?VPN:(.*)$/) {
            my $dev = $1;
            push(@addr_values, "$preip<font color='". $colourvpn ."'>".$dev."</font>$postip");
        }
        elsif ($item =~ /^L2TPDEVICE:(.*)$/) {
            my $user = $1;
            push(@addr_values, "$preip<font color='". $colourvpn ."'>"._("%s (L2TP user)", $user)."</font>$postip");
        }
        elsif ($item =~ /^(?:.*:)?UPLINK:(.*)$/) {
            my $ul = get_uplink_label($1);
            push(@addr_values, "$preip<font color='". $zonecolors{'RED'} ."'>"._('Uplink')." ".$ul->{'description'}."</font>$postip");
        }
        else {
	    my $zone = $item;
	    if ($ip !~ /^$/) {
		($ip,$zone) = split(/:/, $item);
	    }
            push(@addr_values, "$preip<font color='". $zonecolors{$zone} ."'>".$strings_zone{$zone}."</font>$postip");
        }
    }

    if ($#addr_values == -1) {
        return 'ANY';
    }

    if ($#addr_values == 0) {
        return $addr_values[0];
    }

    my $long = '';
    foreach my $addr_value (@addr_values) {
        $long .= sprintf <<EOF
<div>$addr_value</div>
EOF
;
    }
    return $long;
}

sub generate_service($$$) {
    my $ports = shift;
    my $protocol = shift;
    my $rulenr = shift;
    $protocol = lc($protocol);
    my $display_protocol = $protocol;
    my @service_values = ();

    if ($protocol eq 'tcp&udp') {
        $display_protocol = 'TCP+UDP';
    }
    else {
        $display_protocol = uc($protocol);
    }

    if (($display_protocol ne '') && ($ports eq '')) {
        return "$display_protocol/"._('ANY');
    }

    foreach my $port (split(/&/, $ports)) {
        my $service = uc(getservbyport($port, $protocol));
        push(@service_values, "$display_protocol/$port");
    }
    if ($#service_values == -1) {
        return 'ANY';
    }

    if ($#service_values == 0) {
        return $service_values[0];
    }

    my $long = '';
    foreach my $value (@service_values) {
        $long .= sprintf <<EOF
<div>$value</div>
EOF
;
    }
    return $long;
}

sub getConfigFiles($) {
    my $dir = shift;
    my @arr = ();
    foreach my $f (glob("${dir}/*.conf")) {
    push(@arr, $f);
    }
    return \@arr;
}

sub display_rules($$$$$$) {
    my $is_editing = shift;
    my $add_external = shift;
    my $edit_external = shift;
    my $source = shift;
    my $src_dev = shift;
    my $line = shift;


    #&openbox('100%', 'left', _('Current rules'));
    display_add($is_editing, $add_external, $edit_external, $source, $src_dev, $line);

    generate_rules($configfile, $is_editing, $add_external, $edit_external, $source, $src_dev, $line, 1);

printf qq~
<br />
<b>%s</b>&nbsp;&nbsp;<b><input onclick="swapVisibility('systemrules')" value=" &gt;&gt; " type="button"></b>
~,_('Show system rules');

    #&closebox();

    print "<div id=\"systemrules\" style=\"display: none\">\n";
    #&openbox('100%', 'left', _('Rules automatically configured by the system'));
    generate_rules(getConfigFiles($confdir), 0, 0, 0, 0, 0, 0, 0);
   # &closebox();
    print "</div>";
    
}

sub generate_rules($$$$$$$$) {
    my $refconf = shift;
    my $is_editing = shift;
    my $add_external = shift;
    my $edit_external = shift;
    my $old_source = shift;
    my $old_src_dev = shift;
    my $line = shift;
    my $editable = shift;
    
    my @configs = ();
    if (ref($refconf) eq 'ARRAY') {
        @configs = @$refconf;
    }
    else {
        push(@configs, $refconf);
    }


print qq~
<div id="rulesContainer"><!-- ADDED FOR RAZWALL LAYOUT -->
~;

    my $i = 0;
    foreach my $configfile (@configs) {
        my @lines = read_config_file($configfile, $configfile_default);
        foreach my $thisline (@lines) {
            chomp($thisline);
            my %splitted = config_line($thisline);

            if (! $splitted{'valid'}) {
                next;
            }
            my $protocol = uc($splitted{'protocol'});
            my $source = $splitted{'source'};
            my $src_dev = $splitted{'src_dev'};
            my $num = $i+1;
        
            my $enabled_gif = $DISABLED_PNG;
            my $enabled_alt = _('Disabled (click to enable)');
            my $enabled_action = 'enable';
            if ($splitted{'enabled'} eq 'on') {
                $enabled_gif = $ENABLED_PNG;
                $enabled_alt = _('Enabled (click to disable)');
                $enabled_action = 'disable';
            }
            my $destination = $splitted{'destination'};
            my $dst_dev = $splitted{'dst_dev'};
            my $nat_target = $splitted{'nat_target'};
            my $filter_target = $splitted{'filter_target'};

            my $policy_gif = $DENY_PNG;
            my $policy_alt = _('DENY');
            my $policy_text = _('DENY from');
            my $policy_color = $colourred;
            if ($nat_target eq 'RETURN') {
                $policy_gif = $RETURN_PNG;
                $policy_alt = _('Do not NAT');
                $policy_text = _('Do not NAT from');
                $policy_color = $colourred;
            }
            if ($nat_target eq 'NETMAP') {
                $policy_gif = $MAP_PNG;
                $policy_alt = _('Map network');
                $policy_text = _('Map network from');
                $policy_color = $colourgreen;
            }
            if ($nat_target eq 'DNAT') {
                $policy_gif = $IPS_PNG;
                $policy_alt = _('ALLOW with IPS');
                $policy_text = _('ALLOW with IPS from');
                $policy_color = $colourgreen;
            if ($filter_target eq 'REJECT') {
                $policy_gif = $REJECT_PNG;
                $policy_alt = _('REJECT');
                $policy_text = _('REJECT from');
                $policy_color = $colourred;
            }
            if ($filter_target eq 'DROP') {
                $policy_gif = $DENY_PNG;
                $policy_alt = _('DENY');
                $policy_text = _('DENY from');
                $policy_color = $colourred;
            }
            if ($filter_target eq 'ACCEPT' || (!has_ips() && $target eq 'DNAT')) {
                $policy_gif = $ALLOW_PNG;
                $policy_alt = _('ALLOW');
                $policy_text = _('ALLOW from');
                $policy_color = $colourgreen;
            }
        }
        
            my $port = $splitted{'port'};
            my $remark = value_or_nbsp($splitted{'remark'});
            my $editing = 0;
            if ($is_editing || $add_external) {
                $editing = 1;
            }
            my $bgcolor = setbgcolor($editing, $line, $i);

            my $dest_long_value = generate_addressing($destination, $dst_dev, '', $i);
            if ($dest_long_value =~ /(?:^|&)ANY/) {
                $dest_long_value = "&lt;"._('ANY')."&gt;";
            }
            my $service_long_value = generate_service($port, $protocol, $i);
            if ($service_long_value =~ /(?:^|&)ANY/) {
                $service_long_value = "&lt;"._('ANY')."&gt;";
            }

            my $target_ip = $splitted{'target_ip'};
            my $target_port = $splitted{'target_port'};

            my $target_long_value = generate_addressing($target_ip, '', '', $i);
            if ($target_long_value =~ /(?:^|&)ANY/) {
                $target_long_value = "&lt;"._('ANY')."&gt;";
            }

	    my $style = ();
            if ($i eq 0) {
                $style{'up'} = "hidden";
                $style{'clear_up'} = "";
            }
            else {
                $style{'up'} = "";
                $style{'clear_up'} = "hidden";
            }
            if ($i + 1 eq scalar(@lines)) {
                $style{'down'} = "hidden";
                $style{'clear_down'} = "";
            }
            else {
                $style{'down'} = "";
                $style{'clear_down'} = "hidden";
            }

	    my $display_target_port = '';
	    if ($target_port ne '') {
		$display_target_port = ": $target_port";
	    }

printf qq~
      <!-- Rule $num -->
      <div class="rowItem $bgcolor">
		<div class="rowItem-header" onclick="toggleItem(this.parentElement)">
          <span class="rowItemPos">$num</span>
		  <span class="rowItemEle">$dest_long_value</span>
		  <span class="rowItemEle">$service_long_value</span>
		  <span class="rowItemIcon"><img src="$policy_gif" alt="$policy_alt" title="$policy_alt"></span>
		  <span class="rowItemEle">$target_long_value $dest_long_value</span>
          <span class="rowItemNote">$remark</span>
		  <span class="ruleOptions">
~;

           if ($editable) {
printf qq~
                    <form METHOD="post" action="$ENV{'SCRIPT_NAME'}" style="float:left">
                        <input class="imagebutton $style{'up'}" type='image' name="submit" SRC="$UP_PNG" ALT="%s" />
                        <input TYPE="hidden" name="ACTION" value="up"/>
                        <input TYPE="hidden" name="line" value="$i"/>
						<img class="clear $style{'clear_up'}" src="$CLEAR_PNG"/>
                    </form>
~,_("Up");

printf qq~
                    <form METHOD="post" action="$ENV{'SCRIPT_NAME'}" style="float:left">
                        <input class='imagebutton $style{'down'}' type='image' name="submit" SRC="$DOWN_PNG" ALT="%s"/>
                        <input TYPE="hidden" name="ACTION" value="down"/>
                        <input TYPE="hidden" name="line" value="$i"/>
						<img class="clear $style{'clear_down'}" src="$CLEAR_PNG"/>
                    </form>
~, _("Down");
=pod
printf qq~
                    <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
                        <input class='imagebutton' type='image' name="submit" SRC="$enabled_gif" ALT="$enabled_alt"/>
                        <input TYPE="hidden" name="ACTION" value="$enabled_action"/>
                        <input TYPE="hidden" name="line" value="$i"/>
                    </FORM>
                    <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
                        <input class='imagebutton' type='image' name="submit" SRC="$ADD_PNG" ALT="%s"/>
                        <input TYPE="hidden" name="ACTION" value="add_external"/>
                        <input TYPE="hidden" name="line" value="$i"/>
                    </FORM>                    
                    <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
                        <input class='imagebutton' type='image' name="submit" SRC="$EDIT_PNG" ALT="%s"/>
                        <input TYPE="hidden" name="source" value="$source"/>
                        <input TYPE="hidden" name="src_dev" value="$src_dev"/>
                        <input TYPE="hidden" name="ACTION" value="edit"/>
                        <input TYPE="hidden" name="line" value="$i"/>
                    </FORM>
                    <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
                        <input class='imagebutton' type='image' name="submit" SRC="$DELETE_PNG" ALT="%s" />
                        <input TYPE="hidden" name="ACTION" value="delete"/>
                        <input TYPE="hidden" name="line" value="$i"/>
                    </FORM>

~
, _('Add access rule')
, _('Edit')
, _('Delete');
=cut
	    }
        
	    if ($target ne 'NETMAP') {
            foreach my $src (split(/\|/, $source)) {
                my $editing = 0;
                if ($edit_external && ($src eq $old_source)) {
                    $editing = 1;
                }
                $bgcolor = setbgcolor($editing, $line, $i);
                my $src_long_value = generate_addressing($src, '', '', $i);
                if ($src_long_value =~ /(?:^|&)ANY/ || $src_long_value =~ /^any$/) {
                    $src_long_value = "&lt;"._('ANY')."&gt;";
                }
=pod
printf qq~
            <tr class="$bgcolor">
              <td>&nbsp;</td>
              <td valign="top" colspan='3'><font color='$policy_color'>$policy_text NETMAP</font>:</td>
              <td align='left' colspan='2'>$src_long_value</td>
              <td class="actions" valign="top" nowrap="nowrap" >
                  <img class="clear" src="$CLEAR_PNG"/>
                  <img class="clear" src="$CLEAR_PNG"/>
                  <img class="clear" src="$CLEAR_PNG"/>
                  <img class="clear" src="$CLEAR_PNG"/>
                  <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
                      <input class='imagebutton' type='image' name="submit" SRC="$EDIT_PNG" ALT="%s" />
                      <input TYPE="hidden" name="source" value="$src"/>
                      <input TYPE="hidden" name="ACTION" value="edit_external"/>
                      <input TYPE="hidden" name="line" value="$i"/>
                  </FORM>
                  <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
                      <input class='imagebutton' type='image' name="submit" SRC="$DELETE_PNG" ALT="%s" />
                      <input TYPE="hidden" name="old_source" value="$src"/>
                      <input TYPE="hidden" name="ACTION" value="delete_external"/>
                      <input TYPE="hidden" name="line" value="$i"/>
                  </FORM>
              </td>
            </tr>
~;
=cut
            }
            foreach my $src (split(/\|/, $src_dev)) {
                my $editing = 0;
                if ($edit_external && ($src eq $old_src_dev)) {
                    $editing = 1;
                }
                $bgcolor = setbgcolor($editing, $line, $i);
                my $src_long_value = generate_addressing('', $src, '', $i);
                if ($src_long_value =~ /(?:^|&)ANY/) {
                    $src_long_value = "&lt;"._('ANY')."&gt;";
                }
=pod				
printf qq~
            <tr class="$bgcolor">
              <td>&nbsp;</td>
              <td valign="top" colspan='3'><font color='$policy_color'>$policy_text</font>:</td>
              <td align='left' colspan='2'>$src_long_value</td>
              <td class="actions" valign="top" nowrap="nowrap" >
                  <img class="clear" src="$CLEAR_PNG"/>
                  <img class="clear" src="$CLEAR_PNG"/>
                  <img class="clear" src="$CLEAR_PNG"/>
                  <img class="clear" src="$CLEAR_PNG"/>
                  <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
                      <input class='imagebutton' type='image' name="submit" SRC="$EDIT_PNG" ALT="%s" />
                      <input TYPE="hidden" name="src_dev" value="$src"/>
                      <input TYPE="hidden" name="ACTION" value="edit_external"/>
                      <input TYPE="hidden" name="line" value="$i"/>
                  </FORM>
                  <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
                      <input class='imagebutton' type='image' name="submit" SRC="$DELETE_PNG" ALT="%s" />
                      <input TYPE="hidden" name="old_src_dev" value="$src"/>
                      <input TYPE="hidden" name="ACTION" value="delete_external"/>
                      <input TYPE="hidden" name="line" value="$i"/>
                  </FORM>
              </td>
            </tr>
~
, _('access from');
=cut
            }
	    } 
print qq~
		  <label class="switch" onclick="event.stopPropagation();">
            <input type="checkbox" class="rowItem-toggle" checked onchange="toggleItemSwitch(this)">
            <span class="slider"></span>
          </label>
        </div>
		
		
         <div class="rowItem-details">
          <form>
            <label>
              <span class="label-text">Source:</span>
              <select multiple>
                <option value="192.168.1.1">192.168.1.1</option>
                <option value="192.168.1.2">192.168.1.2</option>
                <option value="192.168.1.3">192.168.1.3</option>
              </select>
            </label>
            <label>
              <span class="label-text">Source Port:</span>
              <input type="number" value="80" />
            </label>
            <label>
              <span class="label-text">Destination:</span>
              <select multiple>
                <option value="192.168.1.10">192.168.1.10</option>
                <option value="192.168.1.20">192.168.1.20</option>
              </select>
            </label>
            <label>
              <span class="label-text">Destination Port:</span>
              <input type="number" value="80" />
            </label>
            <label>
              <span class="label-text">Rule Number:</span>
              <input type="text" value="1" readonly />
            </label>
            <label>
              <span class="label-text">Notes:</span>
              <textarea rows="2" cols="20">Sample note</textarea>
            </label>
            <div class="rowItem-actions">
              <button type="button" onclick="saveRule(1)">Save</button>
              <button type="button" onclick="deleteRule(1)">Delete</button>
            </div>
          </form>
        </div>
      </div>
~;
	    $i++;
		} # END LOOP
    }
    
printf qq~
</div>
~;
}

sub create_servicelist($$) {
    my $selected_protocol = lc(shift);
    my $selected_ports = shift;
    chomp($selected_protocol);
    chomp($selected_ports);
    
    my $selected = '';
    my @ret = ();

    my $userdef = sprintf <<EOF
<option value="">%s</option>
EOF
    , _('User defined')
    ;
    push(@ret, $userdef);

    my @services = ();
    open(SERVICE_FILE, $services_file) || return ($selected, \@ret);
    @services = <SERVICE_FILE>;
    close(SERVICE_FILE);

    if (open(SERVICE_FILE, $services_custom_file)) {
        foreach my $line (<SERVICE_FILE>) {
            push(@services, $line);
        }
        close(SERVICE_FILE);
    }

    foreach my $line (sort(@services)) {
        my ($desc, $ports, $proto) = split(/,/, $line);
        chomp($desc);
        chomp($ports);
        chomp($proto);
        my $choosen='';
        $proto = lc($proto);
        if (($proto eq $selected_protocol) && ($ports eq $selected_ports)) {
            $choosen='selected';
            $selected="$ports/$proto";
        }
        push (@ret, "<option value='$ports/$proto' $choosen>$desc</option>");
    }

    if ($selected eq "" && $selected_protocol ne "any" && $selected_protocol ne "") {
        @ret[0] =~ s/value=""/value="" selected/;
    }

    return ($selected, \@ret);
}

sub display_add($$$$$) {
    my $is_editing = shift;
    my $add_external = shift;
    my $edit_external = shift;
    my $source = shift;
    my $src_dev = shift;    
    my $line = shift;
    my $old_source = $source;
    my $old_src_dev = $src_dev;
    
    my %config;
    my %checked;
    my %selected;
    
    if (($is_editing || $add_external || $edit_external) && ($par{'sure'} ne 'y')) {
        %config = config_line(read_config_line($line));
    }
    else {
        %config = %par;
    }
    if (! $is_editing) {
	# put default values here
	$config{'enabled'} = 'on';
    }
    
    my $exteranl = 0;
    my $disabled = "";
    if ($add_external || $edit_external) {
        $external = 1;
        $disabled = "disabled";
    }
    my $enabled = $config{'enabled'};
    my $log = $config{'log'};
    my $protocol = $config{'protocol'};
    if (! $protocol && !$is_editing) {
        $protocol = 'any';
    }
    my $dst_dev = $config{'dst_dev'};
    if ($is_editing) {
        $source = $config{'source'};
        $src_dev = $config{'src_dev'};
    }
    my $src_ip = '';
    my $src_user = '';
    my $destination = $config{'destination'};
    my $dst_ip = '';
    my $dst_user = '';
    my $target = $config{'target_ip'};
    my $target_ip_ip = '';
    my $target_ip_user = '';
    my $target_ip_lb = '';
    my $target_ip_map = '';
    my $target_ip_l2tp = '';
    my $port = $config{'port'};
    my $target_port = $config{'target_port'};
    my $remark = $config{'remark'};
    my $nat_policy = $config{'nat_target'};
    my $filter_policy = $config{'filter_target'};
    if ($nat_policy =~ /^$/) {
	$nat_policy = 'DNAT';
    }
    if ($filter_policy =~ /^$/) {
	$filter_policy = 'ALLOW';
    }

    my $src_type = 'any';
    my $dst_type = 'dev';
    my $target_type = 'ip';

    $checked{'ENABLED'}{$enabled} = 'checked';
    $checked{'LOG'}{$log} = 'checked';
    $selected{'PROTOCOL'}{$protocol} = 'selected';

    if ($source =~ /^$/) {
        if ($src_dev ne "") {
            $src_type = 'dev';
	}
        foreach my $item (split(/&/, $src_dev)) {
            $selected{'src_dev'}{$item} = 'selected';
            $selected{'src_l2tp'}{$item} = 'selected';
        }
		if ($src_dev =~ /^L2TPDEVICE:/) {
			$src_type = 'l2tp';
		}
    }
	elsif ($source =~ /^any$/) {
		$src_type = 'any';
	}
    else {
        if ($source =~ /OPENVPNUSER:/) {
            $src_user = $source;
            foreach $item (split(/&/, $src_user)) {
                $selected{'src_user'}{$item} = 'selected';
            }
            $src_type = 'user';
        }
        else {
            $src_ip = $source;
            if ($src_ip !~ /^$/) {
                $src_type = 'ip';
            }
        }
    }

    if ($destination =~ /^$/) {
        foreach my $item (split(/&/, $dst_dev)) {
            $selected{'dst_dev'}{$item} = 'selected';
            $selected{'dst_l2tp'}{$item} = 'selected';
        }
	if ($dst_dev =~ /^L2TPDEVICE:/) {
	    $dst_type = 'l2tp';
	} else {
            $dst_type = 'dev';
        }
    }

    if ($destination !~ /^$/) {
        if ($destination =~ /OPENVPNUSER:/) {
            $dst_user = $destination;
            foreach $item (split(/&/, $dst_user)) {
                $selected{'dst_user'}{$item} = 'selected';
            }
            $dst_type = 'user';
        }
        else {
            $dst_ip = $destination;
            if ($dst_ip !~ /^$/) {
                $dst_type = 'ip';
            }
        }
    }

    if ($target !~ /^$/) {
        if ($target =~ /OPENVPNUSER:/) {
            $target_ip_user = $target;
            foreach $item (split(/&/, $target_ip_user)) {
                $selected{'target_user'}{$item} = 'selected';
            }
            $target_type = 'user';
        }
        elsif ($target =~ /L2TPIP:/) {
            $target_ip_l2tp = $target;
            foreach $item (split(/&/, $target_ip_l2tp)) {
                $selected{'target_l2tp'}{$item} = 'selected';
            }
            $target_type = 'l2tp';
        }
        else {
	    if ($target =~ /\-/) {
		$target_type = 'lb';
		$target_ip_lb = $target;
	    } else {
		$target_type = 'ip';
		$target_ip_ip = $target;
	    }
        }
    }
    if ($nat_policy eq 'NETMAP') {
	$target_type = 'map';
	$target_ip_map = $target;
    }
    
    $selected{'src_type'}{$src_type} = 'selected';
    $selected{'dst_type'}{$dst_type} = 'selected';
    $selected{'target_type'}{$target_type} = 'selected';
    $selected{'nat_policy'}{$nat_policy} = 'selected';
    $selected{'filter_policy'}{$filter_policy} = 'selected';

    my %foil = ();
    $foil{'title'}{'src_any'} = 'none';
    $foil{'title'}{'src_user'} = 'none';
    $foil{'title'}{'src_ip'} = 'none';
    $foil{'title'}{'src_dev'} = 'none';
    $foil{'title'}{'src_l2tp'} = 'none';
    $foil{'value'}{'src_any'} = 'none';
    $foil{'value'}{'src_user'} = 'none';
    $foil{'value'}{'src_ip'} = 'none';
    $foil{'value'}{'src_dev'} = 'none';
    $foil{'value'}{'src_l2tp'} = 'none';

    $foil{'title'}{'dst_user'} = 'none';
    $foil{'title'}{'dst_ip'} = 'none';
    $foil{'title'}{'dst_dev'} = 'none';
    $foil{'title'}{'dst_l2tp'} = 'none';
    $foil{'value'}{'dst_user'} = 'none';
    $foil{'value'}{'dst_ip'} = 'none';
    $foil{'value'}{'dst_dev'} = 'none';
    $foil{'value'}{'dst_l2tp'} = 'none';

    $foil{'title'}{'target_user'} = 'none';
    $foil{'title'}{'target_ip'} = 'none';
    $foil{'title'}{'target_lb'} = 'none';
    $foil{'title'}{'target_map'} = 'none';
    $foil{'title'}{'target_l2tp'} = 'none';
    $foil{'value'}{'target_user'} = 'none';
    $foil{'value'}{'target_ip'} = 'none';
    $foil{'value'}{'target_lb'} = 'none';
    $foil{'value'}{'target_map'} = 'none';
    $foil{'value'}{'target_l2tp'} = 'none';

    $foil{'title'}{"src_$src_type"} = 'block';
    $foil{'value'}{"src_$src_type"} = 'block';
    $foil{'title'}{"dst_$dst_type"} = 'block';
    $foil{'value'}{"dst_$dst_type"} = 'block';
    $foil{'title'}{"target_$target_type"} = 'block';
    $foil{'value'}{"target_$target_type"} = 'block';
    
    $src_ip =~ s/&/\n/gm;
    $dst_ip =~ s/&/\n/gm;
    $source =~ s/&/\n/gm;
    $destination =~ s/&/\n/gm;
    $port =~ s/&/\n/gm;
    $target_port =~ s/&/\n/gm;

    my $line_count = line_count();

    if ("$par{'line'}" eq "") {
        # if no line set last line
        #print "BIO";
        #$line = $line_count -1;
    }

    my $openvpn_ref = get_openvpn_lease();
    my @openvpnusers = @$openvpn_ref;

    my $l2tp_ref = ();
    if ($l2tp) {
       $l2tp_ref = get_l2tp_users();
    }
    my @l2tpusers = @$l2tp_ref;

    my $src_user_size = int($#openvpnusers / 5);
    if ($src_user_size < 5) {
       $src_user_size = 5;
    }
    my $dst_user_size = $src_user_size;
    my $action = 'add';
    my $sure = '';
    my $button = _("Create Rule");
    my $title = _('Port forwarding / Destination NAT Rule Editor');

    my $advanced = "hidden";
    my $simple = "";
    if ($target_type eq "ip" && $src_type eq "any" && ($filter_policy eq "ALLOW" || $filter_policy eq "RETURN")) {
        $advanced = "";
        $simple = "hidden";
    }
    my $policy = "";
    if ($filter_policy eq "RETURN") {
        $policy = "hidden";
    }
    $title .= '</b>&nbsp;<div style="float: right;">
                <span class="simple ' . $advanced . '">' . _('Simple Mode') . '</span>
                <a id="simple" class="' . $simple . '">' . _('Simple Mode') . '</a>
                &nbsp;|&nbsp;
                <span class="advanced ' . $simple . '">' . _('Advanced Mode') . '</span>
                <a id="advanced" class="' . $advanced . '">' . _('Advanced Mode') . '</a>
                </div><div style="clear: both;"></div><b>';
    
    if ($is_editing) {
        $action = 'edit';
        $button = _("Update Rule");
        $show = "showeditor";
    }
    elsif ($add_external) {
        $action = 'add_external';
        $button = _("Add access rule");
        $show = "showeditor";
        $title = _("Access Rule Editor");
    }
    elsif ($edit_external) {
        $action = 'edit_external';
        $button = _("Update access rule");
        $show = "showeditor";
        $title = _("Access Rule Editor");
    }
    else {
        $show = "";
    }

    #openeditorbox(_("Add a new Port forwarding / Destination NAT rule"), $title, $show, "createrule", @errormessages);

if (!$external) {
# TEST FORM
print qq~

	<!-- BEGIN DISPLAY ADD SECTION -->
   <h2>Port forwarding / Destination NAT configuration</h2>
    <!-- Add New Item Button -->
    <button type="button" class="btn add-object-btn" onclick="showNewItemForm()">Add New Rule</button>
    
    <!-- New Item Creation Form (initially hidden) -->
    <div id="newItemForm" class="new-object-form">
      <h3>Create New DNAT Policy</h3>
	  
<div class="editorbox" name="createrule">
  <div class="editortitle">
    <p>Port forward / Destination NAT</p>
    <div style="clear: both;"></div>
  </div>

  <form enctype="multipart/form-data" method="post" action="/cgi-bin/dnat.cgi#createrule" class="dnat-form">

    <!-- Fieldset: Incoming IP -->
    <fieldset class="incoming">
      <legend>Incoming IP</legend>
      <div class="incoming-grid">
        <div class="incoming-left fieldgroup">
          <label>
		  <span class="label-text">Type *</span>
		  
		    <select name="dst_type" $disabled onchange="toggleTypes('dst');" onkeyup="toggleTypes('dst');">
			  <option value="dev" $selected{'dst_type'}{'dev'}>Zone/VPN/Uplink</option>
			  <option value="ip" $selected{'dst_type'}{'ip'}>Network/IP/Range</option>
			  <option value="user" $selected{'dst_type'}{'user'}>OpenVPN User</option>
~;


if ($l2tp) {
printf qq~
			  <option value="l2tp" $selected{'dst_type'}{'l2tp'}>L2TP User</option>
~;
}

print qq~        
            </select>
          </label>
          <label>
		    <span class="label-text" id="dst_dev_t" style="display:$foil{'title'}{'dst_dev'}">Select interfaces (hold CTRL for multiselect)</span>
		    <span class="label-text" id="dst_ip_t" style="display:$foil{'title'}{'dst_ip'}">Insert network/IPs (one per line)</span>
		    <span class="label-text" id="dst_user_t" style="display:$foil{'title'}{'dst_user'}" style="width: 250px; height: 90px;">Select OpenVPN users (hold CTRL for multiselect)</span>
~;

if ($l2tp) {
print qq~
            <span class="label-text" id="dst_l2tp_t" style="display:$foil{'title'}{'dst_l2tp'}">Select L2TP users (hold CTRL for multiselect)</span>
~;
}

print qq~
            <span class="label-text" id='dst_dev_v' style='display:$foil{'value'}{'dst_dev'}'>
            <select name="dst_dev" multiple $disabled style="height: 100px;">
	            <option value='UPLINK:ANY' $selected{'dst_dev'}{'UPLINK:ANY'}>&lt;ANY Uplink&gt;</option>
~;

foreach my $ref (@{get_uplinks_list()}) {
	my $name = $ref->{'name'};
    my $key = $ref->{'dev'};
    my $desc = $ref->{'description'};
print qq~ 
				<option value='$key' $selected{'dst_dev'}{$key}>Uplink $desc - IP:All known</option>
~;
    eval {
        my %ulhash;
        &readhash("${swroot}/uplinks/$name/settings", \%ul);
        foreach my $ipcidr (split(/,/, $ul{'WAN_IPS'})) {
            my ($ip) = split(/\//, $ipcidr);
            next if ($ip =~ /^$/);
print qq~ 
				<option value='$ip:$key' $selected{'dst_dev'}{"$ip:$key"}>Uplink $desc - IP:$ip</option>
~;
        }
    }
}

foreach my $item (@nets) {
print qq~
				<option value="$item" $selected{'dst_dev'}{$item}>Zone $strings_zone{$item} - IP:All known</option>
~;
    foreach my $ipcidr (split(/,/, $ether{$item.'_IPS'})) {
        my ($ip) = split(/\//, $ipcidr);
        next if ($ip =~ /^$/);

print qq~
				<option value="$ip:$item" $selected{'dst_dev'}{"$ip:$item"}>Zone $strings_zone{$item} - %s:IP</option>
~;
    }
}

foreach my $tap (@{get_taps()}) {
    my $key = "VPN:".$tap->{'name'};
    my $name = $tap->{'name'};
    next if ($tap->{'bridged'});
print qq~
				<option value='$key' $selected{'dst_dev'}{$key}>VPN $name - IP:All known</option>
~;
}

print qq~
			</select>
		</span>
~;

print qq~
	<span class="label-text"  id='dst_ip_v' style='display:$foil{'title'}{'dst_ip'}'>
        <textarea name='dst_ip' wrap='off' $disabled style="height: 100px;">$dst_ip</textarea>
    </span>
~;

print qq~
    <span class="label-text"  id='dst_user_v' style='display:$foil{'title'}{'dst_user'}'>
        <select name="dst_user" multiple $disabled style="height: 100px;">
            <option value="OPENVPNUSER:ALL" $selected{'dst_user'}{'OPENVPNUSER:ALL'}>&lt;ANY&gt;</option>
~;

foreach my $item (@openvpnusers) {
print qq~
            <option value="OPENVPNUSER:$item" $selected{'dst_user'}{"OPENVPNUSER:$item"}>$item</option>
~;
}

print qq~
        </select>
    </span>
~;

if ($l2tp) {
print qq~
		<span class="label-text"  id='dst_l2tp_v' style='display:$foil{'value'}{'dst_l2tp'}'>
			<select name="dst_l2tp" multiple style="height: 100px;">
				<option value="L2TPDEVICE:ALL" $selected{'dst_l2tp'}{"L2TPDEVICE:ALL"}>&lt;ANY&gt;</option>
~;
	foreach my $item (@l2tpusers) {
print qq~
                <option value="L2TPDEVICE:$item" $selected{'dst_l2tp'}{"L2TPDEVICE:$item"}>$item</option>
~;
	}
print qq~
            </select>
        </span>
~;
}


print qq~
    </label>
    <!-- end destination -->
	</div>
        <div class="incoming-right">
          <div class="fieldgroup service">
            <label>
			<span class="label-text">Service *</span>
			  <select name="service_port" $disabled onchange="selectService('protocol', 'service_port', 'port'); toggle_target_ports('protocol');" onkeyup="selectService('protocol', 'service_port', 'port');">
                <option value="any/any">&lt;ANY&gt;</option>
~;

my ($sel, $arr) = create_servicelist($protocol, $config{'port'});
print @$arr;
# check if ports should be enabled
if ($protocol eq "" || $protocol eq "any") {
    $portsdisabled = 'disabled="true"';
}

print qq~
			  </select>
            </label>
          </div>
          <div class="fieldgroup protocol">
            <label>
			<span class="label-text"> Protocol *</span>
			  <select name="protocol" $disabled onchange="updateService('protocol', 'service_port', 'port'); toggle_target_ports('protocol');" onkeyup="updateService('protocol', 'service_port', 'port');">
				<option value="any" $selected{'PROTOCOL'}{'any'}>&lt;ANY&gt;</option>
				<option value="tcp" $selected{'PROTOCOL'}{'tcp'}>TCP</option>
				<option value="udp" $selected{'PROTOCOL'}{'udp'}>UDP</option>
				<option value="tcp&udp" $selected{'PROTOCOL'}{'tcp&udp'}>TCP + UDP</option>
				<option value="esp" $selected{'PROTOCOL'}{'esp'}>ESP</option>
				<option value="gre" $selected{'PROTOCOL'}{'gre'}>GRE</option>
				<option value="icmp" $selected{'PROTOCOL'}{'icmp'}>ICMP</option>			  
			  </select>
            </label>
          </div>
          <div class="fieldgroup port-range full-width">
            <label>
			<span class="label-text">Incoming port/range (one per line)</span>            
			<textarea name="port" $disabled rows="3" $portsdisabled onkeyup="updateService('protocol', 'service_port', 'port');">$port</textarea>
            </label>
          </div>
        </div>
      </div>
    </fieldset>


    <!-- Fieldset: Translate To -->
    <fieldset class="translate">
  <legend>Translate To</legend>
  <div class="translate-grid">
    <div class="fieldgroup">
      <label>
	  <span class="label-text">Type *</span>
        <select id="target_type" name="target_type" $disabled onchange="toggleTypes('target');" onkeyup="toggleTypes('target');">
			<option value="ip" $selected{'target_type'}{'ip'}>IP</option>
			<option value="user" $selected{'target_type'}{'user'}>OpenVPN User</option>
			<option value="lb" $selected{'target_type'}{'lb'}>Load Balancing</option>
			<option value="map" $selected{'target_type'}{'map'}>Map network</option>
~;

if ($l2tp) {
print qq~
            <option value="l2tp" $selected{'target_type'}{'l2tp'}>L2TP User</option>
~;
}

print qq~
		</select>
      </label>
    </div>
	
  <!-- ANY TRANSLATE SECTION -->
  <div class="target-row" id='target_ip_v' style='display:$foil{'value'}{'target_ip'}'>
	<div class="fieldgroup">
      <label> 
	  <span class="label-text"> NAT </span>
        <select class="policy" name="policy_ip" $disabled>
            <option value="DNAT" $selected{'nat_policy'}{'DNAT'}>NAT</option>
            <option value="RETURN" $selected{'nat_policy'}{'RETURN'}>Do not NAT</option>
        </select>
      </label>
    </div>
	<div class="fieldgroup">
      <label>
	  <span class="label-text"> Insert IP </span>
        <input name='target_ip_ip' value="$target_ip_ip" $disabled size="10" type="text" >
      </label>
    </div>
	<div class="fieldgroup">
      <label>
	  <span class="label-text"> Port/Range (e.g. 80, 80:88) </span>
        <input name='target_port_ip' value="$target_port" $disabled size="10" type="text">
      </label>
    </div>
  </div>
  
  <!-- VPN/USER TRANSLATE SECTION -->
  <div class="target-row" id='target_user_v' style='display:$foil{'value'}{'target_user'}'>
	<div class="fieldgroup">
      <label> 
	  <span class="label-text"> NAT </span>
        <select class="policy" name="policy_user" $disabled>
			<option value="DNAT" $selected{'nat_policy'}{'DNAT'}>NAT</option>
			<option value="RETURN" $selected{'nat_policy'}{'RETURN'}>Do not NAT</option>
		</select>
      </label>
    </div>
	<div class="fieldgroup">
      <label>
	  <span class="label-text"> Select OpenVPN user </span>
        <select name="target_ip_user" $disabled >
~;
foreach my $item (@openvpnusers) {
print qq~
        <option value="OPENVPNUSER:$item" $selected{'target_ip_user'}{"OPENVPNUSER:$item"}>$item</option>
~;
}
print qq~
		</select>
      </label>
    </div>
	<div class="fieldgroup">
      <label>
	  <span class="label-text"> Port/Range (e.g. 80, 80:88) </span>
        <input name='target_port_user' value="$target_port" $disabled size="10" type="text">
      </label>
    </div>
  </div>
  
  <!-- IP RANGE TRANSLATE SECTION -->
  <div class="target-row" id='target_lb_v' style='display:$foil{'value'}{'target_lb'}'>
	<div class="fieldgroup">
      <label> 
	  <span class="label-text"> NAT </span>
        <select class="policy" name="policy_lb" $disabled>
			<option value="DNAT" $selected{'nat_policy'}{'DNAT'}>NAT</option>
			<option value="RETURN" $selected{'nat_policy'}{'RETURN'}>Do not NAT</option>
        </select>
      </label>
    </div>
	<div class="fieldgroup">
      <label>
	  <span class="label-text"> Insert IP range (e.g. 10.1.1.1-10.1.1.10) </span>
        <input name='target_ip_lb' value="$target_ip_lb" $disabled size="10" type="text">
      </label>
    </div>
	<div class="fieldgroup">
      <label>
	  <span class="label-text"> Port/Range (e.g. 80, 80:88) </span>
        <input name='target_port_lb' value="$target_port" $disabled size="10" type="text">
      </label>
    </div>
  </div>
  
  <!-- NETMAP TRANSLATE SECTION -->
  <div id='target_map_v' style='display:$foil{'value'}{'target_map'}'>
    <span class="label-text"> Insert subnet </span>
	<input name='target_ip_map' value="$target_ip_map" $disabled size="10" type="text" >
  </div>

~;

       } # END IF (!$external) ENABLE ONCE COMPLETELY PORTED FROM OLD CODE BELOW....

if ($l2tp) {
print qq~

  <!-- L2TP TRANSLATE SECTION -->
  <div class="target-row" id='target_l2tp_v' style='display:$foil{'value'}{'target_l2tp'}'>
	<div class="fieldgroup">
      <label> 
	  <span class="label-text"> NAT </span>
        <select class="policy" name="policy_l2tp" $disabled>
			<option value="DNAT" $selected{'nat_policy'}{'DNAT'}>NAT</option>
			<option value="RETURN" $selected{'nat_policy'}{'RETURN'}>Do not NAT</option>
		</select>
      </label>
    </div>
	<div class="fieldgroup">
      <label>
	  <span class="label-text"> Select L2TP user </span>
		<select name="target_ip_l2tp" $disabled style="width: 250px;">
~;

foreach my $item (@l2tpusers) {
print qq~
			<option value="L2TPIP:$item" $selected{'target_ip_l2tp'}{"L2TPIP:$item"}>$item</option>
~;
}
print qq~
		</select>
      </label>
    </div>
	<div class="fieldgroup">
      <label>
	  <span class="label-text"> Port/Range (e.g. 80, 80:88) </span>
        <input name='target_port_l2tp' value="$target_port" $disabled size="10" type="text">
      </label>
    </div>
  </div>
 
~;
}

print qq~
</fieldset>
~;

if (!($old_source =~ m/\|/) && !($old_src_dev =~ m/\|/) && !($old_source && $old_src_dev)) {
print qq~

    <!-- Fieldset: Access From -->
    <fieldset class="access">
      <legend>Access From</legend>
      <div class="fieldgroup">
        <label>
		<span class="label-text">Source Type *</span>
			<select id="src_type" name="src_type" onchange="toggleTypes('src');" onkeyup="toggleTypes('src');">
				<option value="any" $selected{'src_type'}{'any'}>ANY</option>
				<option value="dev" $selected{'src_type'}{'dev'}>Zone/VPN/Uplink</option>
				<option value="ip" $selected{'src_type'}{'ip'}>Network/IP/Range</option>
				<option value="user" $selected{'src_type'}{'user'}>OpenVPN User</option>
~;

if ($l2tp) {
print qq~
				<option value="l2tp" $selected{'src_type'}{'l2tp'}>L2TP User</option>
~;
}

print qq~
	</select>

		<div id="src_any_t" style="display:$foil{'title'}{'src_any'}; height: 90px;">Access from every zone</div>
		<div id="src_dev_t" style="display:$foil{'title'}{'src_dev'};">Select interfaces (hold CTRL for multiselect)</div>
		<div id="src_ip_t" style="display:$foil{'title'}{'src_ip'};">Insert network/IPs (one per line)</div>
		<div id="src_user_t" style="display:$foil{'title'}{'src_user'};">Select OpenVPN users (hold CTRL for multiselect)</div>
~;


if ($l2tp) {
print qq~
	    <div id="src_l2tp_t" style="display:$foil{'title'}{'src_l2tp'}">Select L2TP users (hold CTRL for multiselect)</div>
~;
}

print qq~		  
			</select>
        </label>
        <label>
~;		  

print qq~
		<!-- ANY section -->
		<div id='src_any_v' style='display:$foil{'value'}{'src_any'}'>&nbsp;</div>
		
		<!--  UPLINK SECTION -->
		<div id='src_dev_v' style='display:$foil{'value'}{'src_dev'}'>
			<span class="label-text">Select interfaces</span>
			<select name="src_dev" multiple style="height: 100px;">
				<option value='UPLINK:ANY' $selected{'src_dev'}{'UPLINK:ANY'}>&lt;ANY Uplink&gt;</option>
~;

foreach my $ref (@{get_uplinks_list()}) {
    my $name = $ref->{'name'};
    my $key = $ref->{'dev'};
    my $desc = $ref->{'description'};
print qq~
                <option value='$key' $selected{'src_dev'}{$key}>Uplink $desc [WAN]</option>
~;
}

foreach my $item (@nets) {
print qq~
                <option value="$item" $selected{'src_dev'}{$item}>$strings_zone{$item}</option>
~;
}

foreach my $data (@$devices) {
    my $value = $data->{'portlabel'};
    my $key = "PHYSDEV:".$data->{'device'};
    my $zone = _("Zone: %s", $strings_zone{$data->{'zone'}});

print qq~
                <option value="$key" $selected{'src_dev'}{$key}>$value ($zone)</option>
~;
}

printf qq~
                <option value="VPN:IPSEC" $selected{'src_dev'}{'VPN:IPSEC'}>IPSEC</option>
~;

foreach my $tap (@{get_taps()}) {
    my $key = "VPN:".$tap->{'name'};
    my $name = $tap->{'name'};
    next if ($tap->{'bridged'});
print qq~ 
                <option value='$key' $selected{'src_dev'}{$key}>VPN $name</option>
~;
}

print qq~
			</select>
		</div>
~;		  


print qq~
		<!-- USER SECTION -->
		<div id='src_user_v' style='display:$foil{'value'}{'src_user'}'>
			<select name="src_user" multiple style="height: 100px;">
				<option value="OPENVPNUSER:ALL" $selected{'src_user'}{"OPENVPNUSER:ALL"}>&lt;ANY&gt;</option>
~;

foreach my $item (@openvpnusers) {
print qq~
                <option value="OPENVPNUSER:$item" $selected{'src_user'}{"OPENVPNUSER:$item"}>$item</option>
~;
}
	
print qq~
			</select>
		</div>
		<!-- IP SECTION -->
		<div id='src_ip_v' style='display:$foil{'value'}{'src_ip'}'>
			<textarea name='src_ip' wrap='off' style="height: 100px;">$src_ip</textarea>
		</div>
~;

if ($l2tp) {
print qq~
		<!-- L2TP SECTION -->
		<div id='src_l2tp_v' style='display:$foil{'value'}{'src_l2tp'}'>
			<select name="src_l2tp" multiple style=height: 100px;">
				<option value="L2TPDEVICE:ALL" $selected{'src_l2tp'}{"L2TPDEVICE:ALL"}>&lt;ANY&gt;</option>
~;
foreach my $item (@l2tpusers) {
print qq~
                <option value="L2TPDEVICE:$item" $selected{'src_l2tp'}{"L2TPDEVICE:$item"}>$item</option>
~;
}
print qq~
			</select>
		</div>
~;

print qq~		  
        </label>
      </div>
      <div class="fieldgroup">
        <label class="filter_policy $policy">
		<span class="label-text">Filter policy *</span>
~;
#} # L2TP SECTION

if (!$external) {
print qq~

        <select id="filter_policy" name="filter_policy" $disabled>
~;

if (has_ips()) {
print qq~
		   <option value="ALLOW" $selected{'TARGET'}{'ALLOW'}>ALLOW with IPS</option>\n
~;
}

print qq~
          <option value="ACCEPT" $selected{'filter_policy'}{'ACCEPT'}>ALLOW</option>
          <option value="DROP"   $selected{'filter_policy'}{'DROP'}>DROP</option>
          <option value="REJECT" $selected{'filter_policy'}{'REJECT'}>REJECT</option>
~;
}
print qq~
		  </select>
        </label>
      </div>
~;
}

if (!$external) {
		
print qq~
    </fieldset>
	
    <!-- Fieldset: Rule Options -->
    <fieldset class="rule-options">
      <legend>Rule Options</legend>
      <div class="checkbox-row">
        <label><input name="enabled" value="on" $disabled $checked{'ENABLED'}{'on'} type="checkbox"> Enabled </label>
        <label><input name="log" value="on" $disabled $checked{'LOG'}{'on'} type="checkbox"> Log </label>
      </div>
      <div class="fieldgroup">
        <label><span class="label-text">Remark</span>
          <input name="remark" value="$remark" $disabled size="50" maxlength="50" type="text"/>
        </label>
      </div>
      <div class="fieldgroup">
        <label>
		<span class="label-text">Position *</span>
          <select name="position" $disabled>
                <option value="0">First</option>
~;

        my $i = 1;
        while ($i <= $line_count) {
            my $title = _('After rule #%s', $i);
            my $selected = '';
            if ($i == $line_count) {
                $title = _('Last');
            }
            if ($line == $i || ($line eq "" && $i == $line_count)) {
                $selected = 'selected';
            }
print qq~
				<option value="$i" $selected>$title</option>
~;
            $i++;
        }

print qq~		  
		  </select>
        </label>
      </div>
    </fieldset>
~;
} # END IF

print qq~

    <!-- Hidden fields -->
    <input type="hidden" name="ACTION" value="$action"/>
    <input type="hidden" name="line" value="$line"/>
    <input type="hidden" name="old_source" value="$old_source"/>
    <input type="hidden" name="old_src_dev" value="$old_src_dev"/>
    <input type="hidden" name="sure" value="y"/>
~;

if (($old_source =~ m/\|/ || $old_src_dev =~ m/\|/) || ($old_source && $old_src_dev)) {
print qq~
        <input type="hidden" name="source" value="$old_source"/>
        <input type="hidden" name="src_dev" value="$old_src_dev"/>
~;
}

print qq~
    <!-- Actions -->
    <div class="actions">
      <span style="margin-left:auto;font-size:.85rem;color:#444;">* This Field is required.</span>
        <div class="rowItem-actions">
          <button type="button" class="btn" onclick="createUser()">Create User</button>
          <button type="button" class="btn" onclick="hideNewItemForm()">Cancel</button>
        </div>
	</div>
    </div>
	<!-- END DISPLAY ADD SECTION -->


  </form>
</div>
</div>
~;


}
} # END display_add ROUTINE


sub reset_values() {
    %par = ();
}

sub save() {
    my $action = $par{'ACTION'};
    my $sure = $par{'sure'};
    if ($action eq 'apply') {
        system($setdnat);
        system("rm -f $needreload");        
        $notemessage = _("NAT rules applied successfully");
        return;
    }
    if ($action eq 'save') {
        reset_values();
        return;
    }
    if ($action eq 'up') {
        move($par{'line'}, -1);
        reset_values();
        return;
    }
    if ($action eq 'down') {
        move($par{'line'}, 1);
        reset_values();
        return;
    }
    if ($action eq 'delete') {
        delete_line($par{'line'});
        reset_values();
        return;
    }

    if ($action eq 'enable') {
        if (toggle_enable($par{'line'}, 1)) {
            reset_values();
            return;
        }
    }
    if ($action eq 'disable') {
        if (toggle_enable($par{'line'}, 0)) {
            reset_values();
            return;
        }
    }
        # ELSE
    
    if (((($action eq 'add_external') || ($action eq 'edit_external')) && ($sure eq 'y')) || ($action eq 'delete_external')) {
        my $line = $par{'line'};
        my $src_type = $par{'src_type'};
        
        my %config = config_line(read_config_line($line));
        
        my $source = "";
        my $src_dev = "";
        my $old_source = "";
        my $old_src_dev = "";
        my $old_source = $par{'old_source'};
        my $old_src_dev = $par{'old_src_dev'};
        
        if ($action ne 'delete_external') {
            if ($src_type eq 'any') {
                $source = 'any';
            }
            if ($src_type eq 'ip') {
                $source = $par{'src_ip'};
            }
            if ($src_type eq 'user') {
                $source = $par{'src_user'};
            }
            if ($src_type eq 'dev') {
                $src_dev = $par{'src_dev'};
            }
            if ($src_type eq 'l2tp') {
                $src_dev = $par{'src_l2tp'};
            }
            $source =~ s/\n/&/gm;
            $source =~ s/\r//gm;
            $source =~ s/\|/&/g;
            $src_dev =~ s/\|/&/g;
        }
        if ($action eq 'add_external') {
            $config{'source'} .= "|$source";
            $config{'src_dev'} .= "|$src_dev";
        }
        else {
            if ($old_source) {
                $config{'source'} =~ s/($old_source)/$source/g;
            }
            elsif ($source) {
                $config{'source'} .= "|$source";
            }
            if ($old_src_dev) {
                $config{'src_dev'} =~ s/($old_src_dev)/$src_dev/g;
            }
            elsif ($src_dev) {
                $config{'src_dev'} .= "|$src_dev";
            }
        }
        
        $config{'source'} =~ s/\|\|/\|/g;
        $config{'source'} =~ s/^\|//g;
        $config{'source'} =~ s/\|$//g;
        $config{'src_dev'} =~ s/\|\|/\|/g;
        $config{'src_dev'} =~ s/^\|//g;
        $config{'src_dev'} =~ s/\|$//g;
        
        if (save_line($line,
                $config{'enabled'},
                $config{'protocol'},
                $config{'src_dev'},
                $config{'source'},
                $config{'dst_dev'},
                $config{'destination'},
                $config{'port'},
                $config{'target_ip'},
                $config{'target_port'},
                $config{'nat_target'},
                $config{'remark'},
                $config{'log'},
                $config{'filter_target'})) {
            reset_values();
        }
        else {
            $par{'src_dev'} = $src_dev;
            $par{'source'} = $source;
            $par{'sure'} = 'n';
        }
    }
    
    if (($action eq 'add') ||
        (($action eq 'edit')&&($sure eq 'y'))) {
        my $src_type = $par{'src_type'};
        my $dst_type = $par{'dst_type'};
        my $target_type = $par{'target_type'};
        my $source = '';
        my $destination = '';
        my $target = '';
        my $target_port = '';
        my $src_dev = '';
        my $dst_dev = '';
        my $old_pos = $par{'line'};
        my $nat_policy = '';
        my $filter_policy = '';
        if ($src_type eq 'any') {
            $source = 'any';
        }
        if ($src_type eq 'ip') {
            $source = $par{'src_ip'};
        }
        if ($src_type eq 'user') {
            $source = $par{'src_user'};
        }
        if ($src_type eq 'l2tp') {
            $src_dev = $par{'src_l2tp'};
        }
        if ($dst_type eq 'ip') {
            $destination = $par{'dst_ip'};
        }
        if ($dst_type eq 'user') {
            $destination = $par{'dst_user'};
        }
        if ($dst_type eq 'l2tp') {
            $dst_dev = $par{'dst_l2tp'};
        }
        if ($src_type eq 'dev') {
            $src_dev = $par{'src_dev'};
        }
        if ($src_type eq '') {
            $source = $par{'source'};
            $src_dev = $par{'src_dev'};
        }
        else {
            $source =~ s/\n/&/gm;
            $source =~ s/\r//gm;
            $source =~ s/\|/&/g;
            $src_dev =~ s/\|/&/g;
        }
        if ($dst_type eq 'dev') {
            $dst_dev = $par{'dst_dev'};
        }
        if ($target_type eq 'ip') {
            $target = $par{'target_ip_ip'};
            $target_port = $par{'target_port_ip'};
            $nat_policy = $par{'policy_ip'};
        }
        if ($target_type eq 'user') {
            $target = $par{'target_ip_user'};
            $target_port = $par{'target_port_user'};
            $nat_policy = $par{'policy_user'};
        }
        if ($target_type eq 'l2tp') {
            $target = $par{'target_ip_l2tp'};
            $target_port = $par{'target_port_l2tp'};
            $nat_policy = $par{'policy_l2tp'};
        }
        if ($target_type eq 'lb') {
            $target = $par{'target_ip_lb'};
            $target_port = $par{'target_port_lb'};
            $nat_policy = $par{'policy_lb'};
        }
        if ($target_type eq 'map') {
            $target = $par{'target_ip_map'};
            $nat_policy = "NETMAP";
        }

        my $enabled = $par{'enabled'};

	if (save_line($par{'line'},
		      $enabled,
		      $par{'protocol'},
		      $src_dev,
		      $source,
		      $dst_dev,
		      $destination,
		      $par{'port'},
		      $target,
		      $target_port,
		      $nat_policy,
		      $par{'remark'},
		      $par{'log'},
		      $par{'filter_policy'})) {

            if ($par{'line'} ne $par{'position'}) {
                if ("$old_pos" eq "") {
                    $old_pos = line_count()-1;
                }
                if (line_count() > 1) {
                    set_position($old_pos, $par{'position'});
                }
            }
            reset_values();
        }
        else {
            $par{'enabled'} = $enabled;
            $par{'src_dev'} = $src_dev;
            $par{'source'} = $source;
            $par{'dst_dev'} = $dst_dev;
            $par{'destination'} = $destination;
            $par{'target_ip'} = $target;
            $par{'target_port'} = $taret_port;
            $par{'nat_target'} = $nat_policy;
            $par{'filter_target'} = $par{'filter_policy'};
            $par{'sure'} = 'n';
        }
    }
}

#&getcgihash(\%par);
#&showhttpheaders();

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
<!-- BEGIN DNAT CUSTOM HEADER -->

<link rel="stylesheet" type="text/css" href="/css/uplinkinformationcontent.css" media="all" />
<link rel="stylesheet" type="text/css" href="/css/autorefreshwrapper.css" media="all" />

<script type="text/javascript" src="/js/systeminformationplugin.js"></script>
<script type="text/javascript" src="/js/uplinkinformationplugin.js"></script>
<script type="text/javascript" src="/js/autorefreshwrapper.js"></script>
<script language="JavaScript" src="/js/firewall_type.js"></script>
<script language="JavaScript" src="/js/services_selector.js"></script>
<script language="JavaScript" src="/js/dnat.js"></script>

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
<!-- END DNAT CUSTOM HEADER-->
~;

&getTemplate('closeHeader');
&printTemplate;


init_ethconfig();
configure_nets();
$ALLZONES = join(@nets, '|'); # ADDED TO JOIN DYNAMIC ZONES FOR NEXT ROUTINE - RAZWALL

	# list_devices_description from razinc.pl:
	# my $layer = shift;
	# my $showzones = shift;
	# my $showlink = shift;
    # layer:
    # 1: bond selector  (on top of which can be done ALL of those: bonding, vlan tagging, bridging, ethernet)
    # 2: vlan selector  (on top of which can be done ALL of those: vlan tagging, bridging, ethernet)
    # 3: ip assigning   (on top of which can be done ALL of those: bridging, ethernet)
    # 99: all devices
    #
    # negative means display only that type of devices. (-1 = only bonds, -2 = only vlans, -3 = only assignable)
    #
    # zones:
    # combinations of values: 	NEW VALUES ARE COMPILED FROM DYAMIC ZONES
	#							#RAZWALL ALPHA-1 TO NAMES: NONE, LAN, LAN2, DMZ, WAN 
	# 							#IPCOP/ENDIAN OLD DEFAULTS: NONE, GREEN, BLUE, ORANGE, WAN
    #
    # showlink:
    # decides whether to check if the link of the device is present or not.
    # Note that this value may be cached from earlier load_ethconfig() calls
($devices, $deviceshash) = list_devices_description(3, $ALLZONES, 0);
#($devices, $deviceshash) = list_devices_description(3, 'LAN|DMZ|LAN2', 0); # REPLACE WITH RAZWALL DYNAMIC ZONES
save();

if ($reload) {
    system("touch $needreload");
}

#&openbigbox("", $warnmessage, $notemessage);

if (-e $needreload) {
    applybox(_("Port forwarding / Destination NAT rules have been changed and need to be applied in order to make the changes active"));
}

my $is_editing = ($par{'ACTION'} eq 'edit');
my $add_external = ($par{'ACTION'} eq 'add_external');
my $edit_external = ($par{'ACTION'} eq 'edit_external');

display_rules($is_editing, $add_external, $edit_external, $par{'source'}, $par{'src_dev'}, $par{'line'});

#&closebigbox();


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
print qq~
<script language="javascript">
	function toggleItem(userElement) {
      // Collapse any other expanded user
      document.querySelectorAll('.rowItem.expanded').forEach(function(el) {
        if (el !== userElement) {
          el.classList.remove('expanded');
        }
      });
      userElement.classList.toggle('expanded');
    }
	
     function showNewItemForm() {
	  // Collapse any expanded user containers
	  document.querySelectorAll('.user.expanded').forEach(function(el) {
		el.classList.remove('expanded');
	  });
	  // Show the new user creation form
	  document.getElementById('newItemForm').style.display = 'block';
	}
    function hideNewItemForm() {
      document.getElementById('newItemForm').style.display = 'none';
    }
	
</script>
~;
&getTemplate('footer');
&printTemplate;


1;


