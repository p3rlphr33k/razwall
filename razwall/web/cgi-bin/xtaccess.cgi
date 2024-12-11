#!/usr/bin/perl
# +--------------------------------------------------------------------------+
# | Endian Firewall                                                          |
# +--------------------------------------------------------------------------+
# | Copyright (c) 2005-2016 Endian S.p.A. <info@endian.com>                  |
# |         Endian S.p.A.                                                    |
# |         via Pillhof 47                                                   |
# |         39057 Appiano (BZ)                                               |
# |         Italy                                                            |
# |                                                                          |
# | This program is free software; you can redistribute it and/or modify     |
# | it under the terms of the GNU General Public License as published by     |
# | the Free Software Foundation; either version 2 of the License, or        |
# | (at your option) any later version.                                      |
# |                                                                          |
# | This program is distributed in the hope that it will be useful,          |
# | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            |
# | GNU General Public License for more details.                             |
# |                                                                          |
# | You should have received a copy of the GNU General Public License along  |
# | with this program; if not, write to the Free Software Foundation, Inc.,  |
# | 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.              |
# +--------------------------------------------------------------------------+

require 'header.pl';
require 'ethconfig.pl';
my $l2tp = 0;
eval {
    require l2tplib;
    $l2tp = 1;
};

my $xtaccess_config = "${swroot}/xtaccess/config";
my $xtaccess_config_default = "/usr/lib/efw/xtaccess/config.default";
my $provisioningfile = "/var/emc/xtaccess/config";
my $xtaccess_settings = "${swroot}/xtaccess/settings";
my $ethernet_settings = "${swroot}/ethernet/settings";
my $setxtaccess = "/usr/local/bin/setxtaccess";
my $inputfwdir = '/etc/firewall/inputfw/';
my $needreload = "${swroot}/xtaccess/needreload";
my $openvpn_servers_cmd = '/usr/local/bin/openvpn-servers';

my $ALLOW_PNG = '/images/firewall_accept.png';
my $IPS_PNG = '/images/firewall_ips.png';
my $DENY_PNG = '/images/firewall_drop.png';
my $REJECT_PNG = '/images/firewall_reject.png';
my $UP_PNG = '/images/stock_up-16.png';
my $DOWN_PNG = '/images/stock_down-16.png';
my $ENABLED_PNG = '/images/on.png';
my $DISABLED_PNG = '/images/off.png';
my $EDIT_PNG = '/images/edit.png';
my $DELETE_PNG = '/images/delete.png';
my $OPTIONAL_PNG = '/images/blob.png';


my (%par,%checked,%selected,%ether,%xtaccess);
my $errormessage = '';
my $policy = 'DENY';
my $log_accepts = 'off';
my @nets;
my $reload = 0;
my %xtaccesshash=();
my $xtaccess = \%xtaccesshash;

my $devices, $deviceshash = 0;
my $services_file = '/usr/lib/efw/xtaccess/services';
my $services_custom_file = '/var/efw/xtaccess/services.custom';

&readhash($ethernet_settings, \%ether);
&readhash($xtaccess_settings, \%xtaccess);

my @vpn_servers = `$openvpn_servers_cmd`;
chomp @vpn_servers;

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

sub set_policy() {
    if ($log_accepts ne $par{'LOG_ACCEPTS'}) {
    $log_accepts = $par{'LOG_ACCEPTS'};
    open(FILE,">$xtaccess_settings") or die "Unable to open config file '$xtaccess_settings' because $!.";
    print FILE "LOG_ACCEPTS=$log_accepts\n";
    close FILE;
    }
    $reload = 1;
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
    my @lines = read_config_file($xtaccess_config, $xtaccess_config_default);
    return $lines[$line];
}

sub save_config_file($) {
    my $ref = shift;
    my @lines = @$ref;
    open (FILE, ">$xtaccess_config");
    foreach my $line (@lines) {
        if ($line ne "") {
            print FILE "$line\n";
        }
    }
    close(FILE);
    $reload = 1;
}

sub line_count() {
    my $filename = $xtaccess_config;
    if (! -e $filename) {
	$filename = $xtaccess_config_default;
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
    if ($line =~ /(?:(?:[^,]*),){4}/) {
        return 1;
    }
    return 0;
}

sub config_line($) {
    my $line = shift;
    my %config;
    $config{'valid'} = 0;
    if (! is_valid($line)) {
        return;
    }
    my @temp = split(/,/, $line);
    $config{'protocol'} = $temp[0];
    $config{'source'} = $temp[1];
    $config{'port'} = $temp[2];
    $config{'enabled'} = $temp[3];
    $config{'destination'} = $temp[4];
    $config{'dst_dev'} = $temp[5];
    $config{'log'} = $temp[6];
    $config{'logprefix'} = $temp[7];
    $config{'target'} = $temp[8];
    $config{'mac'} = $temp[9];
    $config{'remark'} = $temp[10];
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
             $data{'protocol'},
             $data{'source'},
             $data{'port'},
             $data{'enabled'},
             $data{'destination'},
             $data{'dst_dev'},
             $data{'log'},
             $data{'target'},
             $data{'mac'},
             $data{'remark'}
             );
}

sub move($$) {
    my $line = shift;
    my $direction = shift;
    my $newline = $line + $direction;
    if ($newline < 0) {
        return;
    }
    my @lines = read_config_file($xtaccess_config, $xtaccess_config_default);

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
    my @lines = read_config_file($xtaccess_config, $xtaccess_config_default);
    my $myline = $lines[$old];
    my @newlines = ();

    # nothing to do
    if ($new == $old) {
        return;
    }
   
    if ($new > $#lines+1) {
        $new = $#lines+1;
    }

    open (FILE, ">$xtaccess_config");

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
    my @lines = read_config_file($xtaccess_config, $xtaccess_config_default);
    if (! @lines[$line]) {
        return;
    }
    delete (@lines[$line]);
    save_config_file(\@lines);
}

sub create_line($$$$$$$$$$) {
    my $protocol = shift;
    my $source = shift;
    my $port = shift;
    my $enabled = shift;
    my $destination = shift;
    my $dst_dev = shift;
    my $log = shift;
    my $target = shift;
    my $mac = shift;
    my $remark = shift;

    return "$protocol,$source,$port,$enabled,$destination,$dst_dev,$log,INPUTFW,$target,$mac,$remark";
}

sub check_values($$$$$$$$$) {
    my $protocol = shift;
    my $source = shift;
    my $port = shift;
    my $enabled = shift;
    my $destination = shift;
    my $dst_dev = shift;
    my $log = shift;
    my $target = shift;
    my $mac = shift;

    my %valid_proto = ('TCP' => 1, 'UDP' => 1, 'TCP&UDP' => 1, 'ESP' => 1, 'GRE' => 1, 'ICMP' => 1);
    my %valid_targets = ( 'ACCEPT' => 1, 'ALLOW' => 1, 'DROP' => 1, 'REJECT' => 1 );

    if ($protocol !~ /^$/) {
        if (! $valid_proto{uc($protocol)}) {
            $errormessage = _('Invalid protocol');
            return 0;
        }
    }

    foreach my $item (split(/&/, $source)) {
        if (! is_ipaddress($item) && ! validmac($item)) {
            $errormessage = _('Invalid source IP address "%s"', $item);
            return 0;
        }
    }

    foreach my $item (split(/&/, $mac)) {
        if (!validmac($item)) {
            $errormessage = _('Invalid MAC address "%s"', $item);
            return 0;
        }
    }

    foreach my $ports (split(/&/, $port)) {
        if ($ports !~ /^(\d{1,5})(?:\:(\d{1,5}))?$/) {
            $errormessage = _('Invalid destination port "%s"', $ports);
            return 0;
        }
        my $port1 = $1;
        my $port2 = '65535';
        if ($2) {
            $port2 = $2;
        }

        if (($port1 < 0) || ($port1 > 65535)) {
                $errormessage = _('Invalid destination port "%s"', $port1);
            return 0;
        }

        if (($port2 < 0) || ($port2 > 65535)) {
            $errormessage = _('Invalid destination port "%s"', $port2);
            return 0;
        }
        if ($port1 > $port2) {
            $errormessage = _('The destination port range has a first value that is greater than or equal to the second value.');
            return 0;
        }
    }

    if (! $valid_targets{uc($target)}) {
        $errormessage = _('Invalid policy "%s"', $target);
        return 0;
    }

    return 1;
}

sub save_line($$$$$$$$$$$) {
    my $line = shift;
    my $protocol = shift;
    my $source = shift;
    my $port = shift;
    my $enabled = shift;
    my $destination = shift;
    my $dst_dev = shift;
    my $log = shift;
    my $target = shift;
    my $mac = shift;
    my $remark = shift;

    $source =~ s/\n/&/gm;
    $source =~ s/\r//gm;
    $source =~ s/\-/:/g;
    $destination =~ s/\n/&/gm;
    $destination =~ s/\r//gm;
    $port =~ s/\n/&/gm;
    $port =~ s/\r//gm;
    $port =~ s/\-/:/g;
    $mac =~ s/\n/&/gm;
    $mac =~ s/\r//gm;
    $mac =~ s/\-/:/g;
    $remark =~ s/\,//g;

    $dst_dev =~ s/\|/&/g;
    $source =~ s/\|/&/g;
    $destination =~ s/\|/&/g;

    if ($source =~ /none/) {
        $source = '';
    }
    if ($destination =~ /none/) {
        $destination = '';
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

    if ($destination !~ /^$/) {
        $dst_dev = '';
    }
    if ($mac !~ /^$/) {
        $source = '';
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

    if ($target eq '') {
        $target = 'ACCEPT';
    }

    if (! check_values($protocol, $source, $port, $enabled, $destination, $dst_dev, $log, $target, $mac)) {
        return 0;
    }

    my $tosave = create_line($protocol, $source, $port, $enabled, $destination, $dst_dev, $log, $target, $mac, $remark);

    my @lines = read_config_file($xtaccess_config, $xtaccess_config_default);
    if ($line !~ /^\d+$/) {
	push(@lines, $tosave);
	save_config_file(\@lines);
        return 1;
    }
    if (! $lines[$line]) {
        $errormessage = _('Configuration line not found!');
        return 0;
    }

    my %split = config_line($lines[$line]);
    if (($split{'enabled'} ne $enabled) ||
        ($split{'protocol'} ne $protocol) ||
        ($split{'source'} ne $source) ||
        ($split{'port'} ne $port) ||
        ($split{'target'} ne $target) ||
        ($split{'mac'} ne $mac) ||
        ($split{'log'} ne $log) ||
        ($split{'remark'} ne $remark) ||
        ($split{'dst_dev'} ne $dst_dev)
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
        if (($addr eq '0.0.0.0/0') or ($addr eq '')) {
            push (@addr_values, 'ANY');
            next;
        }
        push(@addr_values, $item);
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
        elsif ($item =~ /^(?:.*:)?UPLINK:(.*)$/) {
            my $ul = get_uplink_label($1);
            push(@addr_values, "$preip<font color='". $zonecolors{'RED'} ."'>"._('Uplink')." ".$ul->{'description'}."</font>$postip");
        }
        elsif ($item =~ /^(?:.*:)?VPN:(.*)$/) {
            my $val = $1;
            if ($val eq 'ANY') {
                $val = _('ANY');
            }
            if ($val eq 'SERVER') {
                $val = _('Openvpn Server');
            }
            if ($val =~ m/'SERVER:(?:.*)'/) {
                $val = _('Openvpn Server') . " $1";
	    }
            push(@addr_values, "$preip<font color='". $colourvpn ."'>"._('VPN')." ".$val."</font>$postip");
        }
        elsif ($item =~ /^L2TPDEVICE:(.*)$/) {
            my $user = $1;
            push(@addr_values, _("%s (L2TP user)", $user));
	}
        elsif ($item =~ /^ANY$/) {
            my $val = $1;
            push(@addr_values, "ANY");
        }
        else {
	    my $zone = $item;
	    if ($ip !~ /^$/) {
		($ip,$zone) = split(/:/, $item);
	    }
            push(@addr_values, "$preip<font color='". $zonecolors{$zone} ."'>".$strings_zone{$zone}."</font>$postip");
        }
    }
    foreach my $item (split(/&/, $mac)) {
        push(@addr_values, $item);
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
        <td class="boldbase" width="22%">%s</td>
        <td class="boldbase" width="22%">%s</td>
        <td class="boldbase" width="12%">%s</td>
        <td class="boldbase" width="3%">%s</td>
        <td class="boldbase" width="22%">%s</td>
END
    , _('Source address')
    , _('Source interface')
    , _('Service')
    , _('Policy')
    , _('Remark')
    ;
    if ($editable) {
        printf <<END
        <td class="boldbase" width="18%">%s</td>
END
        , _('Actions')
        ;
    }
    printf <<END
    </tr>
END
    ;

    my $i = 0;
    foreach my $configfile (@configs) {
        my @lines = read_config_file($configfile, $configfile);
        foreach my $thisline (@lines) {
            chomp($thisline);
            my %splitted = config_line($thisline);

            if (! $splitted{'valid'}) {
                next;
            }

            my $protocol = uc($splitted{'protocol'});
            my $source = $splitted{'source'};
            my $num = $i+1;

            my $enabled_gif = $DISABLED_PNG;
            my $enabled_alt = _('Disabled (click to enable)');
            my $enabled_action = 'enable';
            if ($splitted{'enabled'} eq 'on') {
                $enabled_gif = $ENABLED_PNG;
                $enabled_alt = _('Enabled (click to disable)');
                $enabled_action = 'disable';
            }
            my $dst_dev = $splitted{'dst_dev'};
            my $port = $splitted{'port'};
        
            my $target = $splitted{'target'};
            my $policy_gif = $IPS_PNG;
            my $policy_alt = _('ALLOW with IPS');
            if ($target eq 'ACCEPT' || (!has_ips() && $target eq 'ALLOW')) {
                $policy_gif = $ALLOW_PNG;
                $policy_alt = _('ALLOW');
            }
            if ($target eq 'DROP') {
                $policy_gif = $DENY_PNG;
                $policy_alt = _('DENY');
            }
            if ($target eq 'REJECT') {
                $policy_gif = $REJECT_PNG;
                $policy_alt = _('REJECT');
            }
            my $remark = value_or_nbsp($splitted{'remark'});
            if (!$editable) {
                $remark = _('Service (%s)', $splitted{'logprefix'});
            }

            my $log = '';
            if ($splitted{'log'} eq 'on') {
                $log = _('yes');
            }
            my $mac = $splitted{'mac'};

            my $bgcolor = setbgcolor($is_editing, $line, $i);
            my $dest_long_value = generate_addressing($destination, $dst_dev, '', $i);
            if ($dest_long_value =~ /(?:^|&)ANY/) {
                $dest_long_value = "&lt;"._('ANY')."&gt;";
            }
            my $src_long_value = generate_addressing($source, 0, $mac, $i);
            if ($src_long_value =~ /(?:^|&)ANY/) {
                $src_long_value = "&lt;"._('ANY')."&gt;";
            }
            my $service_long_value = generate_service($port, $protocol, $i);
            if ($service_long_value =~ /(?:^|&)ANY/) {
                $service_long_value = "&lt;"._('ANY')."&gt;";
            }
            if ( $i eq 0 ) {
                $style{'up'} = "hidden";
                $style{'clear_up'} = "";
            }
            else {
                $style{'up'} = "";
                $style{'clear_up'} = "hidden";
            }
            if ( $i + 1 eq scalar(@lines) ) {
                $style{'down'} = "hidden";
                $style{'clear_down'} = "";
            }
            else {
                $style{'down'} = "";
                $style{'clear_down'} = "hidden";
            }
            printf <<EOF
  <tr class="$bgcolor">
    <TD VALIGN="top" ALIGN="center">$num</TD>
    <TD VALIGN="top">$src_long_value</TD>
    <TD VALIGN="top">$dest_long_value</TD>
    <TD VALIGN="top">$service_long_value</TD>
    <TD VALIGN="top" ALIGN="center">
      <IMG SRC="$policy_gif" ALT="$policy_alt" TITLE="$policy_alt">
    </TD>
    <TD VALIGN="top" >$remark</TD>
EOF
            ;

            if ($editable) {
                printf <<EOF
    <TD class="actions" VALIGN="top" ALIGN="center" nowrap="nowrap">
      <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
        <input class='imagebutton $style{'up'}' type='image' NAME="submit" SRC="$UP_PNG" ALT="%s" />
        <INPUT TYPE="hidden" NAME="ACTION" VALUE="up">
        <INPUT TYPE="hidden" NAME="line" VALUE="$i">
        <img class="clear $style{'clear_up'}" src="$CLEAR_PNG"/>
      </FORM>
      <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
        <input class='imagebutton $style{'down'}' type='image' NAME="submit" SRC="$DOWN_PNG" ALT="%s" />
        <INPUT TYPE="hidden" NAME="ACTION" VALUE="down">
        <INPUT TYPE="hidden" NAME="line" VALUE="$i">
        <img class="clear $style{'clear_down'}" src="$CLEAR_PNG"/>
      </FORM>
      <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
        <input class='imagebutton' type='image' NAME="submit" SRC="$enabled_gif" ALT="$enabled_alt" />
        <INPUT TYPE="hidden" NAME="ACTION" VALUE="$enabled_action">
        <INPUT TYPE="hidden" NAME="line" VALUE="$i">
      </FORM>
      <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
        <input class='imagebutton' type='image' NAME="submit" SRC="$EDIT_PNG" ALT="%s" />
        <INPUT TYPE="hidden" NAME="ACTION" VALUE="edit">
        <INPUT TYPE="hidden" NAME="line" VALUE="$i">
      </FORM>
      <FORM METHOD="post" ACTION="$ENV{'SCRIPT_NAME'}" style="float:left">
        <input class='imagebutton' type='image' NAME="submit" SRC="$DELETE_PNG" ALT="%s" />
        <INPUT TYPE="hidden" NAME="ACTION" VALUE="delete">
        <INPUT TYPE="hidden" NAME="line" VALUE="$i">
      </FORM>
     </td>

EOF
                , _('Up')
                , _('Down')
                , _('Edit')
                , _('Delete')
                ;
            }
            $i++;
        }
    }
    printf <<EOF
    </TR>
</TABLE>

<TABLE cellpadding="0" cellspacing="0" class="list-legend">
  <TR>
    <TD CLASS="boldbase">
      <B>%s:</B>
    </TD>
    <TD>&nbsp;<IMG SRC="$ENABLED_PNG" ALT="%s" /></TD>
    <TD CLASS="base">%s</TD>
    <TD>&nbsp;&nbsp;<IMG SRC='$DISABLED_PNG' ALT="%s" /></TD>
    <TD CLASS="base">%s</TD>
    <TD>&nbsp;&nbsp;<IMG SRC="$EDIT_PNG" alt="%s" /></TD>
    <TD CLASS="base">%s</TD>
    <TD>&nbsp;&nbsp;<IMG SRC="$DELETE_PNG" ALT="%s" /></TD>
    <TD CLASS="base">%s</TD>
  </TR>
</TABLE>
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

sub display_rules($$) {
    my $is_editing = shift;
    my $line = shift;

    my %checked;
    $checked{'LOG_ACCEPTS'}{$log_accepts} = 'checked = checked';

    printf <<END
<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td align="left">
      <form action="/cgi-bin/xtaccess.cgi" method="post">
END
;

    my $log_disabled = $xtaccess{'DISABLE_LOGS'};
    if ($log_disabled ne 'on') {
        printf <<END
        <input name="LOG_ACCEPTS" value="on" type="checkbox" $checked{'LOG_ACCEPTS'}{'on'}>%s&nbsp;&nbsp;
        <input type="hidden" name="ACTION" value="save">
        <input name="save" value="%s" type="submit">
      </form>
    </td>
  </tr>
</table>
<br />
END
, _('Log packets')
, _('Save')
;
    } else {
        printf <<END
        <input type="hidden" name="ACTION" value="save">
      </form>
    </td>
  </tr>
</table>
<br />
END
;
    }
    display_add($is_editing, $line);
    generate_rules($xtaccess_config, $is_editing, $line, 1);
    printf <<EOF
<br />
<b>%s</b>&nbsp;&nbsp;<b><input onclick="swapVisibility('systemrules')" value=" &gt;&gt; " type="button"></b>
EOF
, _('Show rules of system services')
;
    print "<div id=\"systemrules\" style=\"display: none\">\n";
    generate_rules(getConfigFiles($inputfwdir), 0, 0, 0);
    &closebox();
    print "</div>";
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
    } else {
    %config = %par;
    }

    my $enabled = $config{'enabled'};
    my $target = $config{'target'};
    if (! $target) {
    $target = 'ALLOW';
    $enabled = 'on';  # hacky.. i assume if target is not set, default options must be used.
    }
    my $protocol = $config{'protocol'};
    if (! $protocol && !$is_editing) {
    $protocol = 'any';
    }
    my $dst_dev = $config{'dst_dev'};
    if ($dst_dev eq '0.0.0.0' or $dst_dev eq '') {
    $dst_dev = 'ANY';
    }
    my $source = $config{'source'};
    my $port = $config{'port'};
    my $remark = $config{'remark'};

    my $mac = $config{'mac'};
    my $log = $config{'log'};

    my $l2tp_ref = ();
    if ($l2tp) {
	$l2tp_ref = get_l2tp_users();
    }
    my @l2tpusers = @$l2tp_ref;

    $checked{'ENABLED'}{$enabled} = 'checked';
    $checked{'LOG'}{$log} = 'checked';
    $selected{'PROTOCOL'}{$protocol} = 'selected';
    $selected{'TARGET'}{$target} = 'selected';

    foreach my $item (split(/&/, $dst_dev)) {
    $selected{'dst_dev'}{$item} = 'selected';
    }

    $source =~ s/&/\n/gm;
    $mac =~ s/&/\n/gm;
    $port =~ s/&/\n/gm;

    my $line_count = line_count();

    if ("$par{'line'}" eq "") {
        # if no line set last line
        #print "BIO";
        #$line = $line_count -1;
    }

    my $action = 'add';
    my $sure = '';
    my $title = _('Add a system access rule');
    if ($is_editing) {
    $action = 'edit';
    $sure = '<INPUT TYPE="hidden" NAME="sure" VALUE="y">';
    $title = _('Edit system access rule');
    }

    my $show = "";
    my $button = ($par{'ACTION'} eq 'add' || $par{'ACTION'} eq '' ? _("Add Rule") : _("Update Rule"));
    if ($is_editing) {
        $show = "showeditor";
    }
    #&openbox('100%', 'left', $title);
    openeditorbox(_("Add a new system access rule"), $title, $show, "createrule", @errormessages);
    printf <<EOF
  <table width="100%" cellpadding="0" cellspacing="0">
    <tr>
      <!-- begin source/dest -->
      <td valign="top" width="35%">
        <!-- begin source -->
        <b>%s</b><br />
        <table width="100%" cellpadding="0" cellspacing="0">
          <tr>
            <td>
              <div>%s</div>

EOF
, _('Source address')
, _('Insert network/IPs/MACs (one per line).')
;

##########
# SOURCE #
##########

#### IP begin ###############################################################
    printf <<EOF
              <div>
                <textarea name='source' wrap='off' style="width: 250px; height: 90px;">$source</textarea>
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
            <td>
              <div>%s</div>
EOF
, _('Source interface')
, _('Select interfaces (hold CTRL for multiselect)')
;

###############
# DESTINATION #
###############

#### Device begin ###########################################################
    printf <<EOF
              <div>
                <select name="dst_dev" multiple style="width: 250px; height: 90px;">
              <option value="ANY" $selected{'dst_dev'}{'ANY'}>%s</option>
EOF
, _('ANY')
;
    foreach my $item (@nets) {
    printf <<EOF
              <option value="$item" $selected{'dst_dev'}{$item}>%s</option>
EOF
,$strings_zone{$item}
;
    }
    printf <<EOF
              <option value="RED" $selected{'dst_dev'}{'RED'}>%s</option>
EOF
, _('RED')
;
    foreach my $ref (@{get_uplinks_list()}) {
	my $name = $ref->{'name'};
	my $key = $ref->{'dev'};
	my $desc = $ref->{'description'};
        printf <<EOF 
                                    <option value='$key' $selected{'dst_dev'}{$key}>%s $desc - %s:%s</option>
EOF
, _('Uplink')
, _('IP')
, _('All known')
;

        eval {
            my %ulhash;
            &readhash("${swroot}/uplinks/$name/settings", \%ul);
            foreach my $ipcidr (split(/,/, $ul{'RED_IPS'})) {
                my ($ip) = split(/\//, $ipcidr);
                next if ($ip =~ /^$/);
                printf <<EOF
                                    <option value='$ip:$key' $selected{'dst_dev'}{"$ip:$key"}>%s $desc - %s:$ip</option>
EOF
, _('Uplink')
, _('IP')
;
            }
        }
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
              <option value="VPN:ANY" $selected{'dst_dev'}{'VPN:ANY'}>%s</option>
	      <option value="VPN:IPSEC" $selected{'dst_dev'}{'VPN:IPSEC'}>IPSEC</option>
	<option value="VPN:SERVER" $selected{'dst_dev'}{'VPN:SERVER'}>%s</option>
EOF
, _('VPN')
, _('All Openvpn Servers')
;
    foreach my $vpn_server (@vpn_servers) {
      my @server_data = split(',', $vpn_server);
      printf <<EOF
                                    <option value="VPN:SERVER:$server_data[1]" $selected{'dst_dev'}{"VPN:SERVER:$server_data[1]"}>VPN %s $server_data[1]</option>
EOF
, _('Openvpn Server')
;
    }

    foreach my $tap (@{get_taps()}) {
        my $key = "VPN:".$tap->{'name'};
	my $name = $tap->{'name'};
	my $addzone = '';
	if ($tap->{'bridged'}) {
	    my $zone = _("Zone: %s", $strings_zone{$tap->{'zone'}});
	    $addzone = "($zone)";
	}
        printf <<EOF 
                                    <option value='$key' $selected{'dst_dev'}{$key}>%s $name $addzone</option>
EOF
, _('VPN')
;
    }

    if($l2tp) {
        printf <<EOF 
                                    <option value='L2TPDEVICE:ALL' $selected{'dst_dev'}{$key}>%s $name $addzone</option>
EOF
, _('ANY L2TP User')
;

	foreach my $item (@l2tpusers) {
	    printf <<EOF
                                    <option value="L2TPDEVICE:$item" $selected{'dst_dev'}{"L2TPDEVICE:$item"}>%s $item</option>
EOF
, _('L2TP')
;
	}
    }

    printf <<EOF
                </select>
              </div>
EOF
;
#### Device end #############################################################

    printf <<EOF
            </td>
          </tr>
        </table>
        <!-- end destination -->
      </td>
      <!-- end source/dest -->
    </tr>
    <tr>
      <td colspan="2" class="border-top">
        <strong>%s</strong>
        <table>
          <tr>
            <td valign="top" nowrap="true">%s:&nbsp;<img src="$OPTIONAL_PNG" alt="*" align="top"><br />
              <select name="service_port" onchange="selectService('protocol', 'service_port', 'port');" onkeyup="selectService('protocol', 'service_port', 'port');">
                <option value="any/any">&lt;%s&gt;</option>
EOF
, _('Service/Port')
, _('Service')
, _('ANY')
;
    my ($sel, $arr) = create_servicelist($protocol, $config{'port'});
    print @$arr;

# check if ports should be enabled
if ($protocol eq "" || $protocol eq "any") {
    $portsdisabled = 'disabled="true"';
}
    printf <<EOF
              </select>
            </td>
            <td valign="top">%s:<br />
              <select name="protocol" onchange="updateService('protocol', 'service_port', 'port');" onkeyup="updateService('protocol', 'service_port', 'port');">
                <option value="any" $selected{'PROTOCOL'}{'any'}>&lt;%s&gt;</option>
                <option value="tcp" $selected{'PROTOCOL'}{'tcp'}>TCP</option>
                <option value="udp" $selected{'PROTOCOL'}{'udp'}>UDP</option>
            <option value="tcp&udp" $selected{'PROTOCOL'}{'tcp&udp'}>TCP + UDP</option>
            <option value="esp" $selected{'PROTOCOL'}{'esp'}>ESP</option>
            <option value="gre" $selected{'PROTOCOL'}{'gre'}>GRE</option>
            <option value="icmp" $selected{'PROTOCOL'}{'icmp'}>ICMP</option>
              </selected>
            </td>
            <td valign="top">%s: <img src="$OPTIONAL_PNG" alt="*" align="top"><br />
              <textarea name="port" rows="3" $portsdisabled onkeyup="updateService('protocol', 'service_port', 'port');">$port</textarea>
            </td>
          </tr>
        </table>
      </td>
    </tr>
    <tr>
      <td colspan="2" class="border-top">
        <b>%s</b>
        <table cellpadding="5">
          <tr>
            <td>%s:&nbsp;
              <select name="target">
                %s
                <option value="ACCEPT" $selected{'TARGET'}{'ACCEPT'}>%s</option>
                <option value="DROP" $selected{'TARGET'}{'DROP'}>%s</option>
                <option value="REJECT" $selected{'TARGET'}{'REJECT'}>%s</option>
              </select>
            </td>
            <td>&nbsp;</td>
            <td align="top">%s:&nbsp;<img src="$OPTIONAL_PNG" alt="*" align="top">
              <input name="remark" value="$remark" size="50" maxlength="50" type="text">
            </td>
            <td>&nbsp;</td>
            <td align="left">%s: &nbsp;
              <select name="position">
                <option value="0">%s</option>
EOF
, _('Protocol')
, _('ANY')
, _('Destination port (one per line)')
, _('Policy')
, _('Action')
, has_ips() ? "<option value=\"ALLOW\" $selected{'TARGET'}{'ALLOW'}>" . _('ALLOW with IPS') . "</option>" : ""
, _('ALLOW')
, _('DENY')
, _('REJECT')
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
          <tr>
            <td><input name="enabled" value="on" $checked{'ENABLED'}{'on'} type="checkbox">%s</td>
            <td>&nbsp;</td>
            <td><input name="log" value="on" $checked{'LOG'}{'on'} type="checkbox">%s</td>
          </tr>
        </table>
      </td>
    </tr>
    <input type="hidden" name="ACTION" value="$action">
    <input type="hidden" name="line" value="$line">
    <input type="hidden" name="sure" value="y">
  </table>
EOF
, _('Enabled')
, _('Log all accepted packets')
, _('Save')
;

    &closeeditorbox($button, _("Cancel"), "routebutton", "createrule", "$ENV{'SCRIPT_NAME'}");
    #&closebox();

    # end of ruleedit div
    #print "</div>"

}


sub display_deny() {
    my $is_editing = ($par{'ACTION'} eq 'edit');

    my %selected;
    my %checked;
    $checked{'LOG_ACCEPTS'}{$log_accepts} = 'checked = checked';
    $selected{'POLICY'}{$policy} = 'selected';
    
    &openbox('100%', 'left', _('Current rules'));

    display_rules($is_editing, $par{'line'});
}

sub reset_values() {
    %par = ();
    $par{'LOG_ACCEPTS'} = $log_accepts;
}

sub save() {
    my $action = $par{'ACTION'};
    my $sure = $par{'sure'};
    if ($action eq 'apply') {
        system($setxtaccess);
        system("rm -f $needreload");
        $notemessage = _("Firewall rules applied successfully");
        return;
    }
    if ($action eq 'save') {
        set_policy();
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

        my $src = '';
        my $mac = '';
        my $dst_dev = '';
        my $old_pos = $par{'line'};

    $src = $par{'source'};
    $dst_dev = $par{'dst_dev'};

    my $enabled = $par{'enabled'};
    if (save_line($par{'line'},
              $par{'protocol'},
              $src,
              $par{'port'},
              $enabled,
              '',
              $dst_dev,
              $par{'log'},
              $par{'target'},
              $mac,
              $par{'remark'}
              )) {

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
    }
}

&getcgihash(\%par);
$log_accepts = $xtaccess{'LOG_ACCEPTS'};

&showhttpheaders();
my $extraheader = '<script language="JavaScript" src="/include/services_selector.js"></script>';
&openpage(_('System access'), 1, $extraheader);

init_ethconfig();
configure_nets();
($devices, $deviceshash) = list_devices_description(3, 'GREEN|ORANGE|BLUE', 0);
save();

if ($reload) {
    system("touch $needreload");
}

&openbigbox($errormessage, $warnmessage, $notemessage);

if (-e $needreload) {
    applybox(_("Firewall rules have been changed and need to be applied in order to make the changes active"));
}

display_deny();

&closebigbox();
&closepage();
