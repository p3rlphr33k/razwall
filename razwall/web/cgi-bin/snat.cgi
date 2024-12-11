#!/usr/bin/perl

#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2005-2006 Endian                                              |
#        |         Endian GmbH/Srl                                                     |
#        |         Bergweg 41 Via Monte                                                |
#        |         39057 Eppan/Appiano                                                 |
#        |         ITALIEN/ITALIA                                                      |
#        |         info@endian.it                                                      |
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
require 'ethconfig.pl';
my $l2tp = 0;
eval {
    require l2tplib;
    $l2tp = 1;
};

my $configfile = "${swroot}/snat/config";
my $configfile_default = "/usr/lib/efw/snat/config.default";
my $provisioningfile = "/var/emc/snat/config";
my $ethernet_settings = "${swroot}/ethernet/settings";
my $setsnat = "/usr/local/bin/setsnat";
my $openvpn_passwd   = '/usr/bin/openvpn-sudo-user';
my $confdir = '/etc/firewall/snat/';
my $needreload = "${swroot}/snat/needreload";

my $ALLOW_PNG = '/images/firewall_accept.png';
my $DENY_PNG = '/images/firewall_drop.png';
my $UP_PNG = '/images/stock_up-16.png';
my $DOWN_PNG = '/images/stock_down-16.png';
my $ENABLED_PNG = '/images/on.png';
my $DISABLED_PNG = '/images/off.png';
my $EDIT_PNG = '/images/edit.png';
my $DELETE_PNG = '/images/delete.png';
my $OPTIONAL_PNG = '/images/blob.png';

my (%par,%checked,%selected,%ether);
my @errormessages = ();
my $log_accepts = 'off';
my @nets;
my $reload = 0;

my $devices, $deviceshash = 0;

my $services_file = '/usr/lib/efw/snat/services';
my $services_custom_file = '/var/efw/snat/services.custom';

&readhash($ethernet_settings, \%ether);

sub have_net($) {
    my $net = shift;

    # AAAAAAARGH! dumb fools
    my %net_config = (
        'GREEN' => [1,1,1,1,1,1,1,1,1,1],
        'ORANGE' => [0,1,0,3,0,5,0,7,0,0],
        'BLUE' => [0,0,0,0,4,5,6,7,0,0]
    );

    if ($net_config{$net}[$ether{'CONFIG_TYPE'}] > 0) {
        return 1;
    }
    return 0;
}

sub configure_nets() {
    my @totest = ('GREEN', 'BLUE', 'ORANGE');

    foreach (@totest) {
        my $thisnet = $_;
        if (! have_net($thisnet)) {
            next;
        }
        if ($ether{$thisnet.'_DEV'}) {
            push (@nets, $thisnet);
        }
    }

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
    $config{'proto'} = $temp[1];
    $config{'src_ip'} = $temp[2];
    $config{'dst_ip'} = $temp[3];
    $config{'dst_port'} = $temp[4];
    $config{'dst_dev'} = $temp[5];
    $config{'target'} = $temp[6];
    $config{'remark'} = $temp[7];
    $config{'log'} = $temp[8];
    $config{'snat_to'} = $temp[9];
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
                    $data{'proto'},
                    $data{'src_ip'},
                    $data{'dst_ip'},
                    $data{'dst_port'},
                    $data{'dst_dev'},
                    $data{'target'},
                    $data{'remark'},
                    $data{'log'},
                    $data{'snat_to'});
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

sub create_line($$$$$$$$$$) {

    my $enabled = shift;
    my $proto = shift;
    my $src_ip = shift;
    my $dst_ip = shift;
    my $dst_port = shift;
    my $dst_dev = shift;
    my $target = shift;
    my $remark = shift;
    my $log = shift;
    my $snat_to = shift;

    return "$enabled,$proto,$src_ip,$dst_ip,$dst_port,$dst_dev,$target,$remark,$log,$snat_to";
}

sub check_values($$$$$$$$$$) {
    my $enabled = shift;
    my $protocol = shift;
    my $src_ip = shift;
    my $dst_ip = shift;
    my $dst_port = shift;
    my $dst_dev = shift;
    my $target = shift;
    my $remark = shift;
    my $log = shift;
    my $snat_to = shift;
    
    my %valid_proto = ('TCP' => 1, 'UDP' => 1, 'TCP&UDP' => 1, 'ESP' => 1, 'GRE' => 1, 'ICMP' => 1);
    
    if ($protocol !~ /^$/) {
        if (! $valid_proto{uc($protocol)}) {
            push(@errormessages, _('Invalid protocol'));
        }
    }
    
    if ($dst_ip eq "" && $dst_dev eq "") {
        push(@errormessages, _('SNAT destination must be defined'));
    }
    
    foreach my $item (split(/&/, $src_ip)) {
        next if ($item =~ /^$/);
        next if ($item =~ /^OPENVPNUSER:/);
        next if ($item =~ /^L2TPIP:/);
        if (! is_ipaddress($item)) {
            push(@errormessages, _('Invalid source IP address "%s"', $item));
        }
    }

    foreach my $item (split(/&/, $dst_ip)) {
        next if ($item =~ /^OPENVPNUSER:/);
        next if ($item =~ /^$/);
        if (!is_ipaddress($item)) {
            push(@errormessages, _('Invalid destination IP address "%s"', $item));
        }
    }

    foreach my $ports (split(/&/, $dst_port)) {
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

    foreach my $item (split(/&/, $snat_to)) {
        next if ($item =~ /^UPLINK:/);
        next if ($item =~ /^VPN:/);
        next if ($item =~ /^GREEN|ORANGE|BLUE/);
        next if ($item =~ /^L2TPDEVICE:/);
        next if ($item =~ /^$/);
        if (!is_ipaddress($item)) {
            push(@errormessages, _('Invalid SNAT source IP address "%s"', $item));
        }
    }

    if ($target eq 'NETMAP') {
	if (($snat_to =~ /^$/) || !validipandmask($snat_to)) {
	    push(@errormessages, _('MAP target "%s" is no subnet. Net mapping requires a subnet.', $snat_to));
	} else {
	    my ($eat,$target_bits) = ipv4_parse($snat_to);
	    if ($src_ip eq '') {
		push(@errormessages, _('Source must be a subnet!'));
	    }
	    foreach my $item (split(/&|\-/, $src_ip)) {
		next if ($item =~ /^$/);
		if (!validipandmask($item)) {
		    push(@errormessages, _('Source "%s" is no subnet. Net mapping requires a subnet.', $item));
		    next;
		}
		my ($eat,$item_bits) = ipv4_parse($item);
		if ($target_bits ne $item_bits) {
		    push(@errormessages, _('Net mapping requires source (%s) and MAP subnet (%s) of equal size.', $item, $snat_to));
		    next;
		}
	    }
	}
    }

    if ($#errormessages eq -1) {
        return 1
    }
    else {
        return 0;
    } 
}

sub save_line($$$$$$$$$$$) {
    my $line = shift;
    my $enabled = shift;
    my $proto = shift;
    my $src_ip = shift;
    my $dst_ip = shift;
    my $dst_port = shift;
    my $dst_dev = shift;
    my $target = shift;
    my $remark = shift;
    my $log = shift;
    my $snat_to = shift;
        
    $src_ip =~ s/\n/&/gm;
    $src_ip =~ s/\r//gm;
    $dst_ip =~ s/\n/&/gm;
    $dst_ip =~ s/\r//gm;
    $dst_port =~ s/\n/&/gm;
    $dst_port =~ s/\r//gm;
    $dst_port =~ s/\-/:/g;
    $remark =~ s/\,//g;
    $dst_dev =~ s/\|/&/g;
    $src_ip =~ s/\|/&/g;
    $dst_ip =~ s/\|/&/g;

    if ($src_ip =~ /OPENVPNUSER:ALL/) {
        $src_ip = 'OPENVPNUSER:ALL';
    }
    if ($src_ip =~ /L2TPIP:ALL/) {
        $src_ip = 'L2TPIP:ALL';
    }
    if ($dst_ip =~ /OPENVPNUSER:ALL/) {
        $dst_ip = 'OPENVPNUSER:ALL';
    }
    if ($src_ip =~ /none/) {
        $src_ip = '';
    }
    if ($dst_ip =~ /none/) {
        $dst_ip = '';
    }

    # reduce multiselect to L2TPDEVICE:ALL or ALL if this item
    # is part of the select
    if ($dst_dev =~ /L2TPDEVICE:ALL/) {
        $dst_dev = 'L2TPDEVICE:ALL';
    } elsif ($dst_dev =~ /ALL/) {
	$dst_dev = 'ALL';
    }
    if ($dst_dev =~ /none/) {
        $dst_dev = '';
    }

    if ($dst_ip !~ /^$/) {
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

    if (! check_values($enabled, $proto, $src_ip, $dst_ip, $dst_port, $dst_dev, $target, $remark, $log, $snat_to)) {
        return 0;
    }
    
    my $tosave = create_line($enabled, $proto, $src_ip, $dst_ip, $dst_port, $dst_dev, $target, $remark, $log, $snat_to);
    
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
    if (($split{'enabled'} ne $enabled) ||
            ($split{'proto'} ne $proto) ||
            ($split{'src_ip'} ne $src_ip) ||
            ($split{'dst_ip'} ne $dst_ip) ||
            ($split{'dst_port'} ne $dst_port) ||
            ($split{'dst_dev'} ne $dst_dev) ||
            ($split{'target'} ne $target) ||
            ($split{'remark'} ne $remark) ||
            ($split{'log'} ne $log) ||
            ($split{'snat_to'} ne $snat_to)) {
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
        if ($item =~ /^PHYSDEV:(.*)$/) {
            my $device = $1;
            my $data = $deviceshash->{$device};

          push(@addr_values, "<font color='". $zonecolors{$data->{'zone'}} ."'>".$data->{'portlabel'}."</font>");
        }
        elsif ($item =~ /^VPN:(.*)$/) {
            my $dev = $1;
            push(@addr_values, "<font color='". $colourvpn ."'>".$dev."</font>");
        }
        elsif ($item =~ /^UPLINK:(.*)$/) {
            my $ul = get_uplink_label($1);
            push(@addr_values, "<font color='". $zonecolors{'RED'} ."'>"._('Uplink')." ".$ul->{'description'}."</font>");
        }
        elsif ($item =~ /^L2TPDEVICE:(.*)$/) {
            my $user = $1;
            push(@addr_values, _("%s (L2TP user)", $user));
        }
        else {
            push(@addr_values, "<font color='". $zonecolors{$item} ."'>".$strings_zone{$item}."</font>");
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
        # FIXME: this should use the services file
        #if ($service =~ /^$/) {
        #    push(@service_values, "$display_protocol/$port");
        #    next;
        #}
        #push(@service_values, "$service");
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
    if (-e $provisioningfile) { 
    push(@arr, $provisioningfile);
    }
    return \@arr;
}

sub display_rules($$) {
    my $is_editing = shift;
    my $line = shift;

    &openbox('100%', 'left', _('Current rules'));
    display_add($is_editing, $line);

    generate_rules($configfile, $is_editing, $line, 1);
    printf <<EOF
<br />
<b>%s</b>&nbsp;&nbsp;<b><input onclick="swapVisibility('systemrules')" value=" &gt;&gt; " type="button"></b>
EOF
, _('Show system rules')
;
    &closebox();

    print "<div id=\"systemrules\" style=\"display: none\">\n";
    &openbox('100%', 'left', _('Rules automatically configured by the system'));
    generate_rules(getConfigFiles($confdir), 0, 0, 0);
    &closebox();
    print "</div>";
    
}

sub generate_rules($$$$) {
    my $refconf = shift;
    my $is_editing = shift;
    my $line = shift;
    my $editable = shift;

    my @configs = ();
    if (ref($refconf) eq 'ARRAY') {
        @configs = @$refconf;
    }
    else {
        push(@configs, $refconf);
    }

    printf <<END
    <table class="ruleslist" cellpadding="0" cellspacing="0" width="100%">
        <tr>
            <td class="boldbase" width="2%">#</td>
            <td class="boldbase" width="15%">%s</td>
            <td class="boldbase" width="15%">%s</td>
            <td class="boldbase" width="12%">%s</td>
            <td class="boldbase" width="12%">%s</td>
            <td class="boldbase" width="22%">%s</td>
            <td class="boldbase" style="width: 150px;">%s</td>
        </tr>
END
    , _('Source')
    , _('Destination')
    , _('Service')
    , _('NAT to')
    , _('Remark')
    , _('Actions')
    ;

    my $i = 0;
    foreach my $configfile (@configs) {
        my @lines = read_config_file($configfile, $configfile_default);
        foreach my $thisline (@lines) {
            chomp($thisline);
            my %splitted = config_line($thisline);

            if (! $splitted{'valid'}) {
                next;
            }
            my $protocol = uc($splitted{'proto'});
            my $source = $splitted{'src_ip'};
            my $num = $i+1;
        
            my $enabled_gif = $DISABLED_PNG;
            my $enabled_alt = _('Disabled (click to enable)');
            my $enabled_action = 'enable';
            if ($splitted{'enabled'} eq 'on') {
                $enabled_gif = $ENABLED_PNG;
                $enabled_alt = _('Enabled (click to disable)');
                $enabled_action = 'disable';
            }
            my $destination = $splitted{'dst_ip'};
            my $dst_dev = $splitted{'dst_dev'};
            my $snat_to = $splitted{'snat_to'};
            if ($splitted{'target'} eq 'RETURN') {
                $snat_to = _('No NAT');
            } elsif ($splitted{'target'} eq 'NETMAP') {
		$snat_to = _('Map Network to %s', $snat_to);
	    } else {
                if (!is_ipaddress($splitted{'snat_to'})) {
                    $snat_to = generate_addressing('', $splitted{'snat_to'}, '', $i);
                }
                if ($snat_to eq 'ANY') {
                    $snat_to = _('Auto');
                }
            }
        
            my $port = $splitted{'dst_port'};
            my $remark = value_or_nbsp($splitted{'remark'});
            my $bgcolor = setbgcolor($is_editing, $line, $i);

            my $dest_long_value = generate_addressing($destination, $dst_dev, '', $i);
            if ($dest_long_value =~ /(?:^|&)ANY/) {
                $dest_long_value = "&lt;"._('ANY')."&gt;";
            }
            my $src_long_value = generate_addressing($source, '', '', $i);
            if ($src_long_value =~ /(?:^|&)ANY/) {
                $src_long_value = "&lt;"._('ANY')."&gt;";
            }
            my $service_long_value = generate_service($port, $protocol, $i);
            if ($service_long_value =~ /(?:^|&)ANY/) {
                $service_long_value = "&lt;"._('ANY')."&gt;";
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
        
            printf <<EOF
            <tr class="$bgcolor">
                <td valign="top" align="center">$num</td>
                <td valign="top">$src_long_value</td>
                <td valign="top">$dest_long_value</td>
                <td valign="top">$service_long_value</td>
                <td valign="top">$snat_to</td>
                <td valign="top" >$remark</td>
                <td class="actions" valign="top" nowrap="nowrap">
EOF
            ;
            if ($editable) {
		printf <<EOF
                    <form METHOD="post" action="$ENV{'SCRIPT_NAME'}" style="float:left">
                        <input class='imagebutton $style{'up'}' type='image' name="submit" SRC="$UP_PNG" ALT="%s" />
                        <input TYPE="hidden" name="ACTION" value="up">
                        <input TYPE="hidden" name="line" value="$i">
			<img class="clear $style{'clear_up'}" src="$CLEAR_PNG"/>
                    </form>
EOF
                    , _("Up")
                    ;
                printf <<EOF
EOF
                ;
		printf <<EOF
                    <form METHOD="post" action="$ENV{'SCRIPT_NAME'}" style="float:left">
                        <input class='imagebutton $style{'down'}' type='image' name="submit" SRC="$DOWN_PNG" ALT="%s" />
                        <input TYPE="hidden" name="ACTION" value="down">
                        <input TYPE="hidden" name="line" value="$i">
			<img class="clear $style{'clear_down'}" src="$CLEAR_PNG"/>
                    </form>
EOF
                    , _("Down")
                    ;
                printf <<EOF
                    <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
                        <input class='imagebutton' type='image' name="submit" SRC="$enabled_gif" ALT="$enabled_alt" />
                        <input TYPE="hidden" name="ACTION" value="$enabled_action">
                        <input TYPE="hidden" name="line" value="$i">
                    </FORM>
                    <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
                        <input class='imagebutton' type='image' name="submit" SRC="$EDIT_PNG" ALT="%s" />
                        <input TYPE="hidden" name="ACTION" value="edit">
                        <input TYPE="hidden" name="line" value="$i">
                    </FORM>
                    <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
                        <input class='imagebutton' type='image' name="submit" SRC="$DELETE_PNG" ALT="%s" />
                        <input TYPE="hidden" name="ACTION" value="delete">
                        <input TYPE="hidden" name="line" value="$i">
                    </FORM>
                </td>
            </tr>
EOF
            , _('Edit')
            , _('Delete');
        }
        $i++;
    }
}
    
    printf <<EOF
    </table>
    <table>
        <tr>
            <td CLASS="boldbase">%s:</td>
            <td>&nbsp;<IMG SRC="$ENABLED_PNG" ALT="%s" /></td>
            <td CLASS="base">%s</td>
            <td>&nbsp;&nbsp;<IMG SRC='$DISABLED_PNG' ALT="%s" /></td>
            <td CLASS="base">%s</td>
            <td>&nbsp;&nbsp;<IMG SRC="$EDIT_PNG" alt="%s" /></td>
            <td CLASS="base">%s</td>
            <td>&nbsp;&nbsp;<IMG SRC="$DELETE_PNG" ALT="%s" /></td>
            <td CLASS="base">%s</td>
        </tr>
    </table>
EOF
, _('Legend')
, _('Enabled (click to disable)')
, _('Enabled (click to disable)')
, _('Disabled (click to enable)')
, _('Disabled (click to enable)')
, _('Edit')
, _('Edit')
, _('Remove')
, _('Remove')
;
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

sub display_add($$) {
    my $is_editing = shift;
    my $line = shift;
    my %config;
    my %checked;
    my %selected;
        
    if (($is_editing) && ($par{'sure'} ne 'y')) {
        %config = config_line(read_config_line($line));
    }
    else {
        %config = %par;
    }

    if (! $is_editing) {
	# put default values here
	$config{'enabled'} = 'on';
    }

    my $enabled = $config{'enabled'};
    my $protocol = $config{'proto'};
    if (! $protocol && !$is_editing) {
        $protocol = 'any';
    }
    my $dst_dev = $config{'dst_dev'};
    my $source = $config{'src_ip'};
    my $source_ip = '';
    my $source_user = '';
    my $destination = $config{'dst_ip'};
    my $destination_ip = '';
    my $destination_user = '';
    my $destination_dev = '';
    my $port = $config{'dst_port'};
    my $remark = $config{'remark'};
    my $snat_to = $config{'snat_to'};
    my $snat_to_ip = '';
    my $snat_to_map = '';
    my $target = $config{'target'};
    if ($target =~ /^$/) {
    $target = 'SNAT';
    }

    my $src_type = 'ip';
    my $dst_type = 'dev';

    $checked{'ENABLED'}{$enabled} = 'checked';
    $selected{'PROTOCOL'}{$protocol} = 'selected';
    
    if ($source !~ /^$/) {
        if ($source =~ /OPENVPNUSER:/) {
            $source_user = $source;
            foreach $item (split(/&/, $source_user)) {
                $selected{'src_user'}{$item} = 'selected';
            }
            $src_type = 'user';
        }
	elsif ($source =~ /L2TPIP:/) {
            $source_user = $source;
            foreach $item (split(/&/, $source_user)) {
                $selected{'src_l2tp'}{$item} = 'selected';
            }
            $src_type = 'l2tp';
        }

        else {
            $source_ip = $source;
            if ($source_ip !~ /^$/) {
                $src_type = 'ip';
            }
        }
    }

    if ($destination =~ /^$/) {
        foreach my $item (split(/&/, $dst_dev)) {
            $selected{'dst_dev'}{$item} = 'selected';
            $selected{'dst_l2tp'}{$item} = 'selected';
        }
        if ($dst_dev !~ /^$/) {
	    if ($dst_dev =~ /^L2TPDEVICE:/) {
		$dst_type = 'l2tp';
	    } else {
		$dst_type = 'dev';
	    }
        }
    }

    if ($destination !~ /^$/) {
        if ($destination =~ /OPENVPNUSER:/) {
            $destination_user = $destination;
            foreach $item (split(/&/, $destination_user)) {
                $selected{'dst_user'}{$item} = 'selected';
            }
            $dst_type = 'user';
        }
        else {
            $destination_ip = $destination;
            if ($destination_ip !~ /^$/) {
                $dst_type = 'ip';
            }
        }
    }

    if ($target eq 'NETMAP') {
	$snat_to_map = $snat_to;
    } else {
	$snat_to_ip = $snat_to;
    }
    $selected{'src_type'}{$src_type} = 'selected';
    $selected{'dst_type'}{$dst_type} = 'selected';
    
    $selected{'target'}{$target} = 'selected';
    $selected{'snat_to'}{$snat_to} = 'selected';

    my %foil = ();
    $foil{'title'}{'src_user'} = 'none';
    $foil{'title'}{'src_ip'} = 'none';
    $foil{'title'}{'src_l2tp'} = 'none';
    $foil{'value'}{'src_user'} = 'none';
    $foil{'value'}{'src_ip'} = 'none';
    $foil{'value'}{'src_l2tp'} = 'none';

    $foil{'title'}{'dst_user'} = 'none';
    $foil{'title'}{'dst_ip'} = 'none';
    $foil{'title'}{'dst_dev'} = 'none';
    $foil{'title'}{'dst_l2tp'} = 'none';
    $foil{'value'}{'dst_user'} = 'none';
    $foil{'value'}{'dst_ip'} = 'none';
    $foil{'value'}{'dst_dev'} = 'none';
    $foil{'value'}{'dst_l2tp'} = 'none';

    $foil{'title'}{"src_$src_type"} = 'block';
    $foil{'value'}{"src_$src_type"} = 'block';
    $foil{'title'}{"dst_$dst_type"} = 'block';
    $foil{'value'}{"dst_$dst_type"} = 'block';
    
    $foil{'value'}{'to_RETURN'} = 'none';
    $foil{'value'}{'to_SNAT'} = 'none';
    $foil{'value'}{'to_NETMAP'} = 'none';
    $foil{'value'}{"to_$target"} = 'block';

    $source_ip =~ s/&/\n/gm;
    $destination_ip =~ s/&/\n/gm;
    $port =~ s/&/\n/gm;

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
    $button = _("Create Rule");
    my $title = _('Source NAT rule editor');
    
    if ($is_editing) {
        $action = 'edit';
        my $sure = '<input TYPE="hidden" name="sure" value="y">';
        $button = _("Update Rule");
        $show = "showeditor";
    }
    else {
        $show = "";
    }
    openeditorbox(_("Add a new source NAT rule"), $title, $show, "createrule", @errormessages);
    #&openbox('100%', 'left', $title);
    printf <<EOF
        <table width="100%" cellpadding="0" cellspacing="0">
            <tr width="50%">
                <!-- begin source/dest -->
                <td valign="top" width="40%">
                <!-- begin source -->
                    <b>%s</b><br />
                    <table width="100%" cellpadding="0" cellspacing="0">
                        <tr>
                            <td>%s *&nbsp;&nbsp;
                                <select name="src_type" onchange="toggleTypes('src');" onkeyup="toggleTypes('src');">
                                    <option value="ip" $selected{'src_type'}{'ip'}>%s</option>
                                    <option value="user" $selected{'src_type'}{'user'}>%s</option>
EOF
, _('Source')
, _('Type')
, _('Network/IP')
, _('OpenVPN User')
;

    if ($l2tp) {
	printf <<EOF
                                    <option value="l2tp" $selected{'src_type'}{'l2tp'}>%s</option>
EOF
, _('L2TP User')
;
    }

    printf <<EOF
                                </select>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <div id="src_ip_t" style="display:$foil{'title'}{'src_ip'}">%s</div>
                                <div id="src_user_t" style="display:$foil{'title'}{'src_user'}" style="width: 250px; height: 90px;">%s</div>
EOF
, _('Insert network/IPs (one per line)')
, _('Select OpenVPN users (hold CTRL for multiselect)')
;

    if ($l2tp) {
	printf <<EOF
                                <div id="src_l2tp_t" style="display:$foil{'title'}{'src_l2tp'}">%s</div>
EOF
, _('Select L2TP users (hold CTRL for multiselect)')
;
    }



##########
# SOURCE #
##########

#### User begin #############################################################
    printf <<EOF
                            <div id='src_user_v' style='display:$foil{'value'}{'src_user'}'>
                                <select name="src_user" multiple style="width: 250px; height: 90px;">
                                    <option value="OPENVPNUSER:ALL" $selected{'src_user'}{"OPENVPNUSER:ALL"}>&lt;%s&gt;</option>
EOF
    , _('ANY')
    ;
    foreach my $item (@openvpnusers) {
        printf <<EOF
                                    <option value="OPENVPNUSER:$item" $selected{'src_user'}{"OPENVPNUSER:$item"}>$item</option>
EOF
    ;
    }
    printf <<EOF
                                </select>
                            </div>
EOF
;
#### User end ###############################################################

#### L2tp begin #############################################################
    if ($l2tp) {
	printf <<EOF
                            <div id='src_l2tp_v' style='display:$foil{'value'}{'src_l2tp'}'>
                                <select name="src_l2tp" multiple style="width: 250px; height: 90px;">
                                    <option value="L2TPIP:ALL" $selected{'src_l2tp'}{"L2TPIP:ALL"}>&lt;%s&gt;</option>
EOF
    , _('ANY')
    ;
	foreach my $item (@l2tpusers) {
	    printf <<EOF
                                    <option value="L2TPIP:$item" $selected{'src_l2tp'}{"L2TPIP:$item"}>$item</option>
EOF
    ;
	}
	printf <<EOF
                                </select>
                            </div>
EOF
;
    }
#### L2tp end ###############################################################


#### IP begin ###############################################################
    printf <<EOF
                            <div id='src_ip_v' style='display:$foil{'value'}{'src_ip'}'>
                                <textarea name='source' wrap='off' style="width: 250px; height: 90px;">$source_ip</textarea>
                            </div>
EOF
    ;
#### IP end #################################################################

    printf <<EOF
                        </td>
                    </tr>
                </table>
                <!-- end source field -->
            </td>
            <td valign="top" width="50%">
                <!-- begin destination -->
                <b>%s</b><br />
                <table cellpadding="0" cellspacing="0">
                    <tr>
                        <td>%s *&nbsp;&nbsp;
                            <select name="dst_type" onchange="toggleTypes('dst');" onkeyup="toggleTypes('dst');">
                                <option value="dev" $selected{'dst_type'}{'dev'}>%s</option>
                                <option value="ip" $selected{'dst_type'}{'ip'}>%s</option>
                                <option value="user" $selected{'dst_type'}{'user'}>%s</option>
EOF
, _('Destination')
, _('Type')
, _('Zone/VPN/Uplink')
, _('Network/IP')
, _('OpenVPN User')
;

    if ($l2tp) {
	printf <<EOF
                                    <option value="l2tp" $selected{'dst_type'}{'l2tp'}>%s</option>
EOF
, _('L2TP User')
;
    }

    printf <<EOF
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <div id="dst_dev_t" style="display:$foil{'title'}{'dst_dev'}">%s</div>
                            <div id="dst_ip_t" style="display:$foil{'title'}{'dst_ip'}">%s</div>
                            <div id="dst_user_t" style="display:$foil{'title'}{'dst_user'}" style="width: 250px; height: 90px;">%s</div>
EOF
, _('Select interfaces (hold CTRL for multiselect)')
, _('Insert network/IPs (one per line)')
, _('Select OpenVPN users (hold CTRL for multiselect)')
;

    if ($l2tp) {
	printf <<EOF
                                <div id="dst_l2tp_t" style="display:$foil{'title'}{'dst_l2tp'}">%s</div>
EOF
, _('Select L2TP users (hold CTRL for multiselect)')
;
    }


###############
# DESTINATION #
###############

#### Device begin ###########################################################
    printf <<EOF
                            <div id='dst_dev_v' style='display:$foil{'value'}{'dst_dev'}'>
                                <select name="dst_dev" multiple style="width: 250px; height: 90px;">
EOF
;
    foreach my $item (@nets) {
        printf <<EOF
                                    <option value="$item" $selected{'dst_dev'}{$item}>%s</option>
EOF
,$strings_zone{$item}
;
    }
    foreach my $data (@$devices) {
        my $value = $data->{'portlabel'};
	my $key = "PHYSDEV:".$data->{'device'};
	my $zone = _("Zone: %s", $strings_zone{$data->{'zone'}});
	printf <<EOF
	    <option value="$key" $selected{'dst_dev'}{$key}>$value ($zone)</option>
EOF
;
    }
    printf <<EOF
                                    <option value="VPN:IPSEC" $selected{'dst_dev'}{'VPN:IPSEC'}>IPSEC</option>
EOF
    ;
    foreach my $tap (@{get_taps()}) {
        my $key = "VPN:".$tap->{'name'};
	my $name = $tap->{'name'};
	next if ($tap->{'bridged'});
        printf <<EOF 
                                    <option value='$key' $selected{'dst_dev'}{$key}>%s $name</option>
EOF
, _('VPN')
;
    }

    printf <<EOF 
                                    <option value='UPLINK:ANY' $selected{'dst_dev'}{'UPLINK:ANY'}>&lt;%s&gt;</option>
EOF
, _('ANY Uplink')
;

    foreach my $ref (@{get_uplinks_list()}) {
	my $name = $ref->{'name'};
	my $key = $ref->{'dev'};
	my $desc = $ref->{'description'};
        printf <<EOF 
                                    <option value='$key' $selected{'dst_dev'}{$key}>%s $desc [%s]</option>
EOF
, _('Uplink')
, _('RED')
;
    }
    printf <<EOF
                                </select>
                            </div>
EOF
    ;
#### Device end #############################################################

#### IP begin ###############################################################
    printf <<EOF
                            <div id='dst_ip_v' style='display:$foil{'title'}{'dst_ip'}'>
                                <textarea name='destination' wrap='off' style="width: 250px; height: 90px;">$destination_ip</textarea>
                            </div>
EOF
    ;
#### IP end #################################################################

#### User begin #############################################################
    printf <<EOF
                            <div id='dst_user_v' style='display:$foil{'title'}{'dst_user'}'>
                                <select name="dst_user" multiple style="width: 250px; height: 90px;">
                                    <option value="OPENVPNUSER:ALL" $selected{'dst_user'}{'OPENVPNUSER:ALL'}>&lt;%s&gt;</option>
EOF
    , _('ANY')
    ;
    foreach my $item (@openvpnusers) {
        printf <<EOF
                                    <option value="OPENVPNUSER:$item" $selected{'dst_user'}{"OPENVPNUSER:$item"}>$item</option>
EOF
        ;
    }
    printf <<EOF
                                </select>
                            </div>
EOF
    ;
#### User end ###############################################################

#### L2tp begin #############################################################
       if ($l2tp) {
           printf <<EOF
                            <div id='dst_l2tp_v' style='display:$foil{'value'}{'dst_l2tp'}'>
                                <select name="dst_l2tp" multiple style="width: 250px; height: 90px;">
                                    <option value="L2TPDEVICE:ALL" $selected{'dst_l2tp'}{"L2TPDEVICE:ALL"}>&lt;%s&gt;</option>
EOF
    , _('ANY')
    ;
           foreach my $item (@l2tpusers) {
               printf <<EOF
                                    <option value="L2TPDEVICE:$item" $selected{'dst_l2tp'}{"L2TPDEVICE:$item"}>$item</option>
EOF
    ;
           }
           printf <<EOF
                                </select>
                            </div>
EOF
;
       }
#### L2tp end ###############################################################



    printf <<EOF
                        </td>
                    </tr>
                </table>
                <!-- end destination -->
            </td>
            <!-- end source/dest -->
        </tr>
    </table>
    <hr size="1" color="#cccccc">
    <table>
        <tr>
            <td colspan="2"><b>%s</b></td>
        </tr>
        <tr>
            <td valign="top" nowrap="true">%s *<br />
                <select name="service_port" onchange="selectService('protocol', 'service_port', 'port');" onkeyup="selectService('protocol', 'service_port', 'port');">
                    <option value="any/any">&lt;%s&gt;</option>
EOF
    , _('Service/Port')
    , _('Service')
    , _('ANY')
    ;
    my ($sel, $arr) = create_servicelist($protocol, $config{'dst_port'});
    print @$arr;
# check if ports should be enabled
    if ($protocol eq "" || $protocol eq "any") {
        $portsdisabled = 'disabled="true"';
    }
    printf <<EOF
                </select>
            </td>
            <td valign="top">%s *<br />
                <select name="protocol" onchange="updateService('protocol', 'service_port', 'port');" onkeyup="updateService('protocol', 'service_port', 'port');">
                    <option value="any" $selected{'PROTOCOL'}{'any'}>&lt;%s&gt;</option>
                    <option value="tcp" $selected{'PROTOCOL'}{'tcp'}>TCP</option>
                    <option value="udp" $selected{'PROTOCOL'}{'udp'}>UDP</option>
                    <option value="tcp&udp" $selected{'PROTOCOL'}{'tcp&udp'}>TCP + UDP</option>
                    <option value="esp" $selected{'PROTOCOL'}{'esp'}>ESP</option>
                    <option value="gre" $selected{'PROTOCOL'}{'gre'}>GRE</option>
                    <option value="icmp" $selected{'PROTOCOL'}{'icmp'}>ICMP</option>
                </select>
            </td>
            <td valign="top">%s<br />
                <textarea name="port" rows="3" $portsdisabled onkeyup="updateService('protocol', 'service_port', 'port');">$port</textarea>
            </td>
        </tr>
    </table>
    <hr size="1" color="#cccccc">
    <table>
        <tr>
            <td colspan="2"><b>%s</b></td>
        </tr>
        <tr>
            <td>
                <select name="to_type" onchange="toggleTypes('to');" onkeyup="toggleTypes('to');">
                    <option value="SNAT" $selected{'target'}{'SNAT'}>%s</option>
                    <option value="RETURN" $selected{'target'}{'RETURN'}>%s</option>
                    <option value="NETMAP" $selected{'target'}{'NETMAP'}>%s</option>
                </select>
            </td>
            <td>
                <div id='to_RETURN_t'></div>
                <div id='to_RETURN_v' style='display:$foil{'value'}{'to_RETURN'}'>&nbsp;</div>
                <div id='to_NETMAP_t'></div>
                <div id='to_NETMAP_v' style='display:$foil{'value'}{'to_NETMAP'}'>%s 
                  <input name='snat_to_map' value="$snat_to_map" size="10" type="text" style="width: 150px;" />
                </div>
                <div id='to_SNAT_t'></div>
                <div id='to_SNAT_v' style='display:$foil{'value'}{'to_SNAT'}'>%s 
                    <select name="snat_to_ip" style="width: 200px;">
                          <option value='' $selected{'snat_to'}{''}>%s</option>
EOF
    , _('Protocol')
    , _('ANY')
    , _('Destination port (one per line)')

    , _('NAT')
    , _('NAT')
    , _('No NAT')
    , _('MAP Network')

    , _('to Subnet')
    , _('to source address')
    , _('Auto')
    ;

    foreach my $ref (@{get_uplinks_list()}) {
	my $name = $ref->{'name'};
	my $key = $ref->{'dev'};
	my $desc = $ref->{'description'};
        printf <<EOF
                          <option value='$key' $selected{'snat_to'}{$key}>%s $desc - %s:%s</option>
EOF
        , _('Uplink')
        , _('IP')
        , _('Auto')
        ;
        eval {
            my %ulhash;
            &readhash("${swroot}/uplinks/$name/settings", \%ul);
            foreach my $ipcidr (split(/,/, $ul{'RED_IPS'})) {
                my ($ip) = split(/\//, $ipcidr);
                next if ($ip =~ /^$/);
                printf <<EOF
                          <option value='$ip' $selected{'snat_to'}{$ip}>%s $desc - %s:$ip</option>
EOF
                , _('Uplink')
                , _('IP')
                , _('Auto')
                ;
            }
        }
    }

    foreach my $tap (@{get_taps()}) {
        my $key = "VPN:".$tap->{'name'};
        my $name = $tap->{'name'};
	next if ($tap->{'bridged'});
        printf <<EOF
                                    <option value='$key' $selected{'snat_to'}{$key}>%s $name - %s:%s</option>
EOF
        , _('VPN')
        , _('IP')
        , _('Auto')
        ;
    }

    foreach my $key (@l2tpusers) {
        printf <<EOF
                                    <option value='L2TPDEVICE:$key' $selected{'snat_to'}{'L2TPDEVICE:'.$key}>%s $key - %s:%s</option>
EOF
, _('L2TP')
, _('IP')
, _('Auto')
;
    }

    foreach my $name (@nets) {
        printf <<EOF
                                    <option value="$name" $selected{'snat_to'}{$name}>%s %s - %s:%s</option>
EOF
        , _('Zone')
        , $strings_zone{$name}
        , _('IP')
        , _('Auto')
        ;
        
        foreach my $ipcidr (split(/,/, $ether{$name.'_IPS'})) {
            my ($ip) = split(/\//, $ipcidr);
            next if ($ip =~ /^$/);

            printf <<EOF
                                    <option value="$ip" $selected{'snat_to'}{$ip}>%s %s - %s:$ip</option>
EOF
            , _('Zone')
            , $strings_zone{$name}
            , _('IP')
            ;
        }
    }

    printf <<EOF
                    </select>
                </div>
            </td>
        </tr>
    </table>
    <hr size="1" color="#cccccc">
    <table>
        <tr>
            <td><input name="enabled" value="on" $checked{'ENABLED'}{'on'} type="checkbox">%s</td>
        <td>&nbsp;</td>
            <td align="top">%s
                <input name="remark" value="$remark" size="50" maxlength="50" type="text"/>
            </td>
            <td>&nbsp;</td>
            <td align="left">%s *&nbsp;
                <select name="position">
                    <option value="0">%s</option>
EOF
    , _('Enabled')
    , _('Remark')
    , _('Position')
    , _('First')
    ;

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
        printf <<EOF
                    <option value="$i" $selected>$title</option>
EOF
        ;
        $i++;
    }

    printf <<EOF
                </select>
            </td>
        </tr>
    </table>
    <input type="hidden" name="ACTION" value="$action">
    <input type="hidden" name="line" value="$line">
    <input type="hidden" name="sure" value="y">
EOF
;

    &closeeditorbox($button, _("Cancel"), "routebutton", "createrule", $ENV{'SCRIPT_NAME'});
}

sub reset_values() {
    %par = ();
}

sub save() {
    my $action = $par{'ACTION'};
    my $sure = $par{'sure'};
    if ($action eq 'apply') {
        system($setsnat);
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
    if (($action eq 'add') ||
            (($action eq 'edit')&&($sure eq 'y'))) {
        my $src_type = $par{'src_type'};
        my $dst_type = $par{'dst_type'};
        my $source = '';
        my $destination = '';
        my $src_dev = '';
        my $old_pos = $par{'line'};

        if ($src_type eq 'ip') {
            $source = $par{'source'};
        }
        if ($dst_type eq 'ip') {
            $destination = $par{'destination'};
        }
        if ($src_type eq 'user') {
            $source = $par{'src_user'};
        }
        if ($src_type eq 'l2tp') {
            $source = $par{'src_l2tp'};
        }
        if ($dst_type eq 'user') {
            $destination = $par{'dst_user'};
        }
        if ($dst_type eq 'dev') {
            $dst_dev = $par{'dst_dev'};
        }
        if ($dst_type eq 'l2tp') {
            $dst_dev = $par{'dst_l2tp'};
        }

        my $snat_to = '';
        if ($par{'to_type'} eq 'RETURN') {
            $snat_to = '';
        } elsif ($par{'to_type'} eq 'NETMAP') {
            $snat_to = $par{'snat_to_map'};
        } else {
            $snat_to = $par{'snat_to_ip'};
        }
        my $enabled = $par{'enabled'};

        if (save_line($par{'line'},
                      $enabled,
                      $par{'protocol'},
                      $source,
                      $destination,
                      $par{'port'},
                      $dst_dev,
                      $par{'to_type'},
                      $par{'remark'},
                      '',
                      $snat_to)) {

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
	    $par{'sure'} = 'n';
	}
    }
}

&getcgihash(\%par);

&showhttpheaders();
my $extraheader = '<script language="JavaScript" src="/include/firewall_type.js"></script>
<script language="JavaScript" src="/include/services_selector.js"></script>';
&openpage(_('Source NAT configuration'), 1, $extraheader);

init_ethconfig();
configure_nets();
($devices, $deviceshash) = list_devices_description(3, 'GREEN|ORANGE|BLUE', 0);
save();

if ($reload) {
    system("touch $needreload");
}

&openbigbox("", $warnmessage, $notemessage);

if (-e $needreload) {
    applybox(_("Source NAT rules have been changed and need to be applied in order to make the changes active"));
}

my $is_editing = ($par{'ACTION'} eq 'edit');
display_rules($is_editing, $par{'line'});

&closebigbox();
&closepage();
