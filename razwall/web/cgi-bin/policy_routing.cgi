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
require 'routing.pl';
require 'razinc.pl';

my $l2tp = 0;
eval {
    require l2tplib;
    $l2tp = 1;
};

my (%par,%checked,%selected,%ether,%routing);
my $log_accepts = 'off';
my @nets;
my %routinghash=();
my $routing = \%routinghash;

my $devices, $deviceshash = 0;

my $services_file = '/usr/lib/efw/routing/services';
my $services_custom_file = '/razwall/config/routing/services.custom';

my @tostypes = ("default", "lowdelay", "throughput", "reliability");

my %toslist = (
    default => "0x00",
    lowdelay => "0x10",
    throughput => "0x08",
    reliability => "0x04"
);

&readhash($ethernet_settings, \%ether);
&readhash($routing_settigns, \%routing);

sub have_net($) {
    my $net = shift;

    # AAAAAAARGH! dumb fools
    my %net_config = (
        'LAN' => [1,1,1,1,1,1,1,1,1,1],
        'DMZ' => [0,1,0,3,0,5,0,7,0,0],
        'LAN2' => [0,0,0,0,4,5,6,7,0,0]
    );

    if ($net_config{$net}[$ether{'CONFIG_TYPE'}] > 0) {
        return 1;
    }
    return 0;
}

sub configure_nets() {
    my @totest = ('LAN', 'LAN2', 'DMZ');

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

sub move($$) {
    my $line = shift;
    my $direction = shift;
    my $newline = $line + $direction;
    if ($newline < 0) {
        return;
    }
    my @lines = read_config_file();

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
    my @lines = read_config_file();
    my $myline = $lines[$old];
    my @newlines = ();

    # nothing to do
    if ($new == $old) {
        return;
    }
   
    if ($new > $#lines+1) {
        $new = $#lines+1;
    }

    open (FILE, ">$routing_config");

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

sub generate_addressing($$$$) {
    my $addr = shift;
    my $dev = shift;
    my $mac = shift;
    my $rulenr = shift;
    my @addr_values = ();

    foreach my $item (split(/&/, $addr)) {
        if ($item =~ /^OPENVPNUSER:(.*)$/) {
            my $user = $1;
            push(@addr_values, "<font color='". $colourvpn ."'>"._("%s (OpenVPN User)", $user)."</font>");
        }
        elsif ($item =~ /^L2TPIP:(.*)$/) {
            my $user = $1;
            push(@addr_values, "<font color='". $colourvpn ."'>"._("%s (L2TP user)", $user)."</font>");
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
        elsif ($item =~ /^L2TPDEVICE:(.*)$/) {
            my $user = $1;
            push(@addr_values, "<font color='". $colourvpn ."'>"._("%s (L2TP user)", $user)."</font>");
        }
        elsif ($item =~ /^VPN:(.*)$/) {
            my $dev = $1;
            push(@addr_values, "<font color='". $colourvpn ."'>".$dev."</font>");
        }
        elsif ($item =~ /^UPLINK:(.*)$/) {
            #my $ul = $1;
            my %ul = get_uplink_info($1);
            push(@addr_values, "<font color='". $zonecolors{'RED'} ."'>".$ul{'NAME'}."</font>");
        }
        else {
            push(@addr_values, "<font color='". $zonecolors{$item} ."'>".$strings_zone{$item}."</font>");
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
        return "$display_protocol<br />"._('ANY');
    }

    foreach my $port (split(/&/, $ports)) {
        my $service = uc(getservbyport($port, $protocol));
        # FIXME: this should use the services file
        #if ($service =~ /^$/) {
        #    push(@service_values, "$display_protocol/$port");
        #    next;
        #}
        #push(@service_values, "$service");
        push(@service_values, "$display_protocol<br/>$port");
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

sub display_rules($$) {
    my $is_editing = shift;
    my $line = shift;
    
    &openbox('100%', 'left', _('Current rules'));
    display_add($is_editing, $line);
    
    printf <<END
    <table width="100%" cellpadding="0" cellspacing="0" border="0" class="ruleslist">
        <tr>
            <td class="boldbase" width="2%">#</td>
            <td class="boldbase" style="width:120px;">%s</td>
            <td class="boldbase" style="width:120px;">%s</td>
            <td class="boldbase" width="5%">%s</td>
            <td class="boldbase" width="12%">%s</td>
            <td class="boldbase" width="8%">%s</td>
            <td class="boldbase" style="width:150px;">%s</td>
            <td class="boldbase" style="width:130px;">%s</td>
        </tr>
END
    , _('Source')
    , _('Destination')
    , _('ToS')
    , _('Via Gateway')
    , _('Service')
    , _('Remark')
    , _('Actions')
    ;

    my @lines = read_config_file();
    my $i = 0;
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
        my $destination = $splitted{'destination'};
        my $src_dev = $splitted{'src_dev'};
        my $tos = $splitted{'tos'};
        my $gateway = '';
        my $backup_allow = $splitted{'backup_allow'};
        if ($splitted{'gw'} =~ /^UPLINK:(.*)$/) {
	        $gateway = generate_addressing('', $splitted{'gw'}, '', $i);
        } elsif ($splitted{'gw'} =~ /^(OPENVPNUSER|L2TPIP):(.*)$/) {
	        $gateway = generate_addressing($splitted{'gw'}, '', '', $i);
        }
        else {
	        $gateway = $splitted{'gw'};
	    }
        my $port = $splitted{'port'};
        my $remark = value_or_nbsp($splitted{'remark'});
        my $log = '';
        if ($splitted{'log'} eq 'on') {
            $log = _('yes');
        }
        my $mac = $splitted{'mac'};
        my $bgcolor = setbgcolor($is_editing, $line, $i);
        my $dest_long_value = generate_addressing($destination, '', '', $i);
        if ($dest_long_value =~ /(?:^|&)ANY/) {
            $dest_long_value = "&lt;"._('ANY')."&gt;";
        }
        my $src_long_value = generate_addressing($source, $src_dev, $mac, $i);
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
        if ( $i eq (@lines - 1) ) {
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
            <td valign="top">$tos</td>
            <td valign="top">$gateway</td>
            <td valign="top">$service_long_value</td>
            <td valign="top">$remark</td>
            <td class="actions" valign="top" nowrap="nowrap">
                <form METHOD="post" action="$ENV{'SCRIPT_NAME'}" style="float:left">
                    <input class='imagebutton $style{'up'}' type='image' name="submit" SRC="$UP_PNG" ALT="%s" />
                    <input TYPE="hidden" name="ACTION" value="up">
                    <input TYPE="hidden" name="line" value="$i">
                </form>
                <img class="clear $style{'clear_up'}" src="$CLEAR_PNG"/>

                <form METHOD="post" action="$ENV{'SCRIPT_NAME'}" style="float:left">
                    <input class='imagebutton $style{'down'}' type='image' name="submit" SRC="$DOWN_PNG" ALT="%s" />
                    <input TYPE="hidden" name="ACTION" value="down">
                    <input TYPE="hidden" name="line" value="$i">
                </form>
                <img class="clear $style{'clear_down'}" src="$CLEAR_PNG"/>

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
        ,
        _("Up"),
        _("Down"),
        _('Edit'),
        _('Delete');

        $i++;
    }
    
    printf <<EOF
    </table>
    <table>
        <tr>
            <td CLASS="boldbase"><B>%s</B></td>
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
    ,
    _('Legend'),
    _('Enabled (click to disable)'),
    _('Enabled (click to disable)'),
    _('Disabled (click to enable)'),
    _('Disabled (click to enable)'),
    _('Edit'),
    _('Edit'),
    _('Remove'),
    _('Remove')
    ;

    &closebox();    
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
        $config{'enabled'} = "on";
    }
    
    my $enabled = $config{'enabled'};
    my $protocol = $config{'protocol'};
    if (! $protocol && !$is_editing) {
        $protocol = 'any';
    }
    my $src_dev = $config{'src_dev'};
    my $source = $config{'source'};
    my $source_ip = '';
    my $source_user = '';
    my $destination = $config{'destination'};
    my $destination_ip = '';
    my $destination_user = '';
    my $gateway = $config{'gw'};
    my $uplink = '';
    my $openvpn = '';
    my $gw_l2tp = '';
    my $backup_allow = $config{'backup_allow'};
    my $tos = $config{'tos'};
    my $port = $config{'port'};
    my $remark = $config{'remark'};

    my $mac = $config{'mac'};
    my $log = $config{'log'};
    my $src_type = 'ip';
    my $dst_type = 'ip';

    $checked{'ENABLED'}{$enabled} = 'checked';
    $checked{'BACKUP_ALLOW'}{$backup_allow} = 'checked';
    $checked{'LOG'}{$log} = 'checked';
    $selected{'PROTOCOL'}{$protocol} = 'selected';
    
    if ($source =~ /^$/) {
        foreach my $item (split(/&/, $src_dev)) {
            $selected{'src_dev'}{$item} = 'selected';
            $selected{'src_l2tp'}{$item} = 'selected';
        }
        if ($src_dev !~ /^$/) {
	    if ($src_dev =~ /^L2TPDEVICE:/) {
		$src_type = 'l2tp';
	    } else {
		$src_type = 'dev';
	    }
        }
    }

    if ($source !~ /^$/) {
        if ($source =~ /^OPENVPNUSER:/) {
            $source_user = $source;
            foreach $item (split(/&/, $source_user)) {
                $selected{'src_user'}{$item} = 'selected';
            }
            $src_type = 'user';
        }
        else {
            $source_ip = $source;
            if ($source_ip !~ /^$/) {
                $src_type = 'ip';
            }
        }
    }
    if ($destination !~ /^$/) {
        if ($destination =~ /^OPENVPNUSER:/) {
            $destination_user = $destination;
            foreach $item (split(/&/, $destination_user)) {
                $selected{'dst_user'}{$item} = 'selected';
            }
            $dst_type = 'user';
        }
        elsif ($destination =~ /^L2TPIP:/) {
            $destination_user = $destination;
            foreach $item (split(/&/, $destination_user)) {
                $selected{'dst_l2tp'}{$item} = 'selected';
            }
            $dst_type = 'l2tp';
        }
        else {
            $destination_ip = $destination;
            if ($destination_ip !~ /^$/) {
                $dst_type = 'ip';
            }
        }
    }
    if ($mac !~ /^$/) {
        $src_type = 'mac';
    }
    if ($is_editing) {
        if (($source =~ /^$/) && ($src_dev =~ /^$/) &&! ($mac !~ /^$/)) {
            $src_type = 'any';
        }
        if ($destination =~ /^$/) {
            $dst_type = 'any';
        }
    }

    $selected{'src_type'}{$src_type} = 'selected';
    $selected{'dst_type'}{$dst_type} = 'selected';
    
    my $via_type = 'gw';
    if ($gateway =~ /^UPLINK:/) {
	    $via_type = 'uplink';
	    $uplink = $gateway;
	    $gateway = '';
    }
    if ($gateway =~ /^OPENVPNUSER:/) {
	    $via_type = 'openvpn';
	    $openvpn = $gateway;
	    $gateway = '';
    }
    if ($gateway =~ /^L2TPIP:/) {
	    $via_type = 'l2tp';
	    $gw_l2tp = $gateway;
	    $gateway = '';
    }

    $selected{'uplink'}{$uplink} = 'selected';
    $selected{'openvpn'}{$openvpn} = 'selected';
    $selected{'gw_l2tp'}{$gw_l2tp} = 'selected';
    $selected{'via_type'}{$via_type} = 'selected';

    my %foil = ();
    $foil{'title'}{'src_any'} = 'none';
    $foil{'title'}{'src_dev'} = 'none';
    $foil{'title'}{'src_user'} = 'none';
    $foil{'title'}{'src_ip'} = 'none';
    $foil{'title'}{'src_mac'} = 'none';
    $foil{'title'}{'src_l2tp'} = 'none';
    $foil{'value'}{'src_any'} = 'none';
    $foil{'value'}{'src_dev'} = 'none';
    $foil{'value'}{'src_user'} = 'none';
    $foil{'value'}{'src_ip'} = 'none';
    $foil{'value'}{'src_mac'} = 'none';
    $foil{'value'}{'src_l2tp'} = 'none';

    $foil{'title'}{'dst_any'} = 'none';
    $foil{'title'}{'dst_user'} = 'none';
    $foil{'title'}{'dst_ip'} = 'none';
    $foil{'title'}{'dst_l2tp'} = 'none';
    $foil{'value'}{'dst_any'} = 'none';
    $foil{'value'}{'dst_user'} = 'none';
    $foil{'value'}{'dst_ip'} = 'none';
    $foil{'value'}{'dst_l2tp'} = 'none';

    $foil{'title'}{"src_$src_type"} = 'block';
    $foil{'value'}{"src_$src_type"} = 'block';
    $foil{'title'}{"dst_$dst_type"} = 'block';
    $foil{'value'}{"dst_$dst_type"} = 'block';
    
    $foil{'value'}{'via_gw'} = 'none';
    $foil{'value'}{'via_uplink'} = 'none';
    $foil{'value'}{'via_openvpn'} = 'none';
    $foil{'value'}{'via_l2tp'} = 'none';
    $foil{'value'}{"via_$via_type"} = 'block';

    $source_ip =~ s/&/\n/gm;
    $destination_ip =~ s/&/\n/gm;
    $mac =~ s/&/\n/gm;
    $port =~ s/&/\n/gm;

    my $line_count = line_count();

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
    my $src_dev_size = int((length(%$deviceshash) + $#nets) / 3);
    if ($src_dev_size < 3) {
       $src_dev_size = 3;
    }
    my $action = 'add';
    my $sure = '';
    $button = _("Create Rule");
    my $title = _('Policy routing rule editor');
    
    if ($is_editing) {
        $action = 'edit';
        my $sure = '<input TYPE="hidden" name="sure" value="y">';
        $button = _("Update Rule");
        $show = "showeditor";
    }
    else {
        $show = "";
    }
    openeditorbox(_("Create a policy routing rule"), $title, $show, "createrule", @errormessages);
    printf <<EOF
        <table width="100%" cellpadding="0" cellspacing="0">
            <tr width="50%">
                <!-- begin source/dest -->
                <td valign="top" width="40%">
                <!-- begin source -->
                    <b>%s *</b><br />
                    <table width="100%" cellpadding="0" cellspacing="0">
                        <tr>
                            <td>%s&nbsp;&nbsp;
                                <select name="src_type" onchange="toggleTypes('src');" onkeyup="toggleTypes('src');">
                                    <option value="any" $selected{'src_type'}{'any'}>&lt;%s&gt;</option>
                                    <option value="dev" $selected{'src_type'}{'dev'}>%s</option>
                                    <option value="user" $selected{'src_type'}{'user'}>%s</option>
EOF
, _('Source')
, _('Type')
, _('ANY')
, _('Zone/Interface')
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
                                    <option value="ip" $selected{'src_type'}{'ip'}>%s</option>
                                    <option value="mac" $selected{'src_type'}{'mac'}>%s</option>
                                </select>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <div id="src_any_t" style="display:$foil{'title'}{'src_any'}">%s</div>
                                <div id="src_dev_t" style="display:$foil{'title'}{'src_dev'}">%s</div>
                                <div id="src_user_t" style="display:$foil{'title'}{'src_user'}">%s</div>
EOF
, _('Network/IP')
, _('MAC')
, _('This rule will match any source')
, _('Select interfaces (hold CTRL for multiselect)')
, _('Select OpenVPN users (hold CTRL for multiselect)')
;

    if ($l2tp) {
	printf <<EOF
                                <div id="src_l2tp_t" style="display:$foil{'title'}{'src_l2tp'}">%s</div>
EOF
, _('Select L2TP users (hold CTRL for multiselect)')
;
    }

    printf <<EOF
                                <div id="src_ip_t" style="display:$foil{'title'}{'src_ip'}">%s</div>
                                <div id="src_mac_t" style="display:$foil{'title'}{'src_mac'}">%s</div>
                                <div id="src_any_v" style="display:$foil{'value'}{'src_any'}" style="width: 250px; height: 90px;">&nbsp;</div>
EOF
, _('Insert network/IPs (one per line)')
, _('Insert MAC addresses (one per line)')
;


##########
# SOURCE #
##########

#### Device begin ###########################################################
    printf <<EOF
                            <div id='src_dev_v' style='display:$foil{'value'}{'src_dev'}'>
                                <select name="src_dev" multiple style="width: 250px; height: 90px;">
                                    <option value="LOCAL" $selected{'src_dev'}{"LOCAL"}>%s</option>
EOF
, _('LOCAL')
;
    foreach my $item (@nets) {
        printf <<EOF
                                    <option value="$item" $selected{'src_dev'}{$item}>%s</option>
EOF
        ,$strings_zone{$item}
        ;
    }
    foreach my $data (@$devices) {
        my $value = $data->{'portlabel'};
	my $key = "PHYSDEV:".$data->{'device'};
	my $zone = _("Zone: %s", $strings_zone{$data->{'zone'}});
	printf <<EOF
	          <option value="$key" $selected{'src_dev'}{$key}>$value ($zone)</option>
EOF
;
    }
    printf <<EOF
                                    <option value="VPN:IPSEC" $selected{'src_dev'}{'VPN:IPSEC'}>IPSEC</option>
                                </select>
                            </div>
EOF
    ;
#### Device end #############################################################


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
                                    <option value="L2TPDEVICE:ALL" $selected{'src_l2tp'}{"L2TPDEVICE:ALL"}>&lt;%s&gt;</option>
EOF
, _('ANY')
;
	foreach my $item (@l2tpusers) {
	    printf <<EOF
                                    <option value="L2TPDEVICE:$item" $selected{'src_l2tp'}{"L2TPDEVICE:$item"}>$item</option>
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

#### MAC begin ##############################################################
    printf <<EOF
                            <div id='src_mac_v' style='display:$foil{'value'}{'src_mac'}'>
                                <textarea name='mac' wrap='off' style="width: 250px; height: 90px;">$mac</textarea>
                            </div>
EOF
    ;
#### MAC end ################################################################

    printf <<EOF
                        </td>
                    </tr>
                </table>
                <!-- end source field -->
            </td>
            <td valign="top" width="50%">
                <!-- begin destination -->
                <b>%s *</b><br />
                <table cellpadding="0" cellspacing="0">
                    <tr>
                        <td>%s&nbsp;&nbsp;
                            <select name="dst_type" onchange="toggleTypes('dst');" onkeyup="toggleTypes('dst');">
                                <option value="any" $selected{'dst_type'}{'any'}>&lt;%s&gt;</option>
                                <option value="user" $selected{'dst_type'}{'user'}>%s</option>
EOF
, _('Destination')
, _('Type')
, _('ANY')
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
                                <option value="ip" $selected{'dst_type'}{'ip'}>%s</option>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <div id="dst_any_t" style="display:$foil{'title'}{'dst_any'}">%s</div>
                            <div id="dst_user_t" style="display:$foil{'title'}{'dst_user'}">%s</div>
EOF
, _('Network/IP')
, _('This rule will match any destination')
, _('Select OpenVPN users (hold CTRL for multiselect)')
;
    if ($l2tp) {
	printf <<EOF
                            <div id="dst_l2tp_t" style="display:$foil{'title'}{'dst_l2tp'}">%s</div>
EOF
, _('Select L2TP users (hold CTRL for multiselect)')
;
    }

    printf <<EOF
                            <div id="dst_ip_t" style="display:$foil{'title'}{'dst_ip'}">%s</div>
                            <div id="dst_any_v" style="display:$foil{'value'}{'src_any'}" style="width: 250px; height: 90px;">&nbsp;</div>
EOF
, _('Insert network/IPs (one per line)')
;

###############
# DESTINATION #
###############

#### User begin #############################################################
    printf <<EOF
                            <div id='dst_user_v' style='display:$foil{'title'}{'dst_user'}'>
                                <select name="dst_user" multiple style="width: 250px; height: 90px;">
                                    <option value="OPENVPNUSER:ALL" $selected{'src_user'}{'OPENVPNUSER:ALL'}>&lt;%s&gt;</option>
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
                                    <option value="L2TPIP:ALL" $selected{'dst_l2tp'}{"L2TPIP:ALL"}>&lt;%s&gt;</option>
EOF
, _('ANY')
;

	foreach my $item (@l2tpusers) {
	    printf <<EOF
                                    <option value="L2TPIP:$item" $selected{'dst_l2tp'}{"L2TPIP:$item"}>$item</option>
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
                            <div id='dst_ip_v' style='display:$foil{'title'}{'dst_ip'}'>
                                <textarea name='destination' wrap='off' style="width: 250px; height: 90px;">$destination_ip</textarea>
                            </div>
EOF
    ;
#### IP end #################################################################

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
    my ($sel, $arr) = create_servicelist($protocol, $config{'port'});
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
                <select name="via_type" onchange="toggleTypes('via');" onkeyup="toggleTypes('via');">
                    <option value="gw" $selected{'via_type'}{'gw'}>%s</option>
                    <option value="uplink" $selected{'via_type'}{'uplink'}>%s</option>
                    <option value="openvpn" $selected{'via_type'}{'openvpn'}>%s</option>
EOF
, _('Protocol')
, _('ANY')
, _('Destination port (one per line)')
, _('Route via')
, _('Static gateway')
, _('Uplink')
, _('OpenVPN User')
;

    if ($l2tp) {
	printf <<EOF
                    <option value="l2tp" $selected{'via_type'}{'l2tp'}>%s</option>
EOF
, _('L2TP User')
;
    }


    printf <<EOF
                </select>
            </td>
            <td>
                <div id='via_gw_v' style='display:$foil{'value'}{'via_gw'}'>
                     <input type="text" name="gw" value="$gateway" />
                </div>
                <div id='via_uplink_v' style='display:$foil{'value'}{'via_uplink'}'>
                    <select name="uplink" style="width: 139px;">
EOF
;

    foreach my $name (@{get_uplinks()}) {
        my $key = "UPLINK:$name";
        my %uplinkinfo = get_uplink_info($name);
        printf <<EOF
                          <option value='$key' $selected{'uplink'}{$key}>$uplinkinfo{'NAME'}</option>
EOF
        ;
    }

    printf <<EOF
                    </select>
                </div>
                <div ID='via_openvpn_v' style='display:$foil{'value'}{'via_openvpn'}'>
                    <select name="openvpn">
EOF
;

    foreach my $item (@openvpnusers) {
        printf <<EOF
                        <option value="OPENVPNUSER:$item" $selected{'openvpn'}{"OPENVPNUSER:$item"}>$item</option>
EOF
    ;
    }

    printf <<EOF
                    </select>
                </div>
EOF
;

    if ($l2tp) {
	printf <<EOF
                <div ID='via_l2tp_v' style='display:$foil{'value'}{'via_l2tp'}'>
                    <select name="gw_l2tp">
EOF
;
	foreach my $item (@l2tpusers) {
	    printf <<EOF
                        <option value="L2TPIP:$item" $selected{'via_l2tp'}{"L2TPIP:$item"}>$item</option>
EOF
;
	}

	printf <<EOF
                    </select>
                </div>
EOF
;
    }


    printf <<EOF
            </td>
            <td>
                <div id='via_uplink_t' style='display:$foil{'value'}{'via_uplink'}'>
                    <input name="backup_allow" value="on" $checked{'BACKUP_ALLOW'}{'on'} type="checkbox">&nbsp;%s
                </div>
                <div id='via_gw_t' style='display:$foil{'value'}{'via_gw'}'></div>
                <div id='via_openvpn_t' style='display:$foil{'value'}{'via_openvpn'}'></div>
                <div id='via_l2tp_t' style='display:$foil{'value'}{'via_l2tp'}'></div>
            </td>
        </tr>
    </table>
    <hr size="1" color="#cccccc">
    <table>
        <tr>
            <td>%s</td>
            <td>
                <select name="tos" style="width: 139px;">
                    <option value=''>%s</option>
EOF
    , _('Use backuplink if uplink fails')
    , _('Type Of Service')
    , _('not defined')
    ;
    foreach my $key (@tostypes) {
        my $selected = "";
        if ($toslist{$key} eq $tos) {
            $selected = 'selected';
        }
        printf <<EOF
                    <option value='$toslist{$key}' $selected>$key - $toslist{$key}</option>
EOF
        ;
    }

    printf <<EOF
                </select>
            </td>
            <td align="top">%s
                <input name="remark" value="$remark" size="50" maxlength="50" type="text">
            </td>
            <td>&nbsp;</td>
            <td align="left">%s&nbsp;
                <select name="position">
                    <option value="0">%s</option>
EOF
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
            <td></td>
            <td></td>
        </tr>
    </table>
    <input type="hidden" name="ACTION" value="$action">
    <input type="hidden" name="line" value="$line">
    <input type="hidden" name="sure" value="y">
EOF
    , _('Enabled')
    , _('Log all accepted packets')
    ;

    #&closebox();
    &closeeditorbox($button, _("Cancel"), "routebutton", "createrule", "$ENV{SCRIPT_NAME}");

    # end of ruleedit div
    #print "</div>"

}

sub reset_values() {
    %par = ();
    $par{'LOG_ACCEPTS'} = $log_accepts;
}

sub save() {
    my $action = $par{'ACTION'};
    my $sure = $par{'sure'};
    if ($action eq 'apply') {
        system($setrouting);
        system($setpolicyrouting);
        system("rm -f $needreload");

        $notemessage = _("Routing rules applied successfully");
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
        my $mac = '';
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
        if ($dst_type eq 'user') {
            $destination = $par{'dst_user'};
        }
        if ($src_type eq 'dev') {
            $src_dev = $par{'src_dev'};
        }
        if ($src_type eq 'mac') {
            $mac = $par{'mac'};
        }
        if ($src_type eq 'l2tp') {
            $src_dev = $par{'src_l2tp'};
        }
        if ($dst_type eq 'l2tp') {
            $destination = $par{'dst_l2tp'};
        }

	my $gateway = '';
	if ($par{'via_type'} eq 'gw') {
	    $gateway = $par{'gw'};
	} elsif ($par{'via_type'} eq 'openvpn') {
	    $gateway = $par{'openvpn'};
	} elsif ($par{'via_type'} eq 'l2tp') {
	    $gateway = $par{'gw_l2tp'};
	} else {
	    $gateway = $par{'uplink'};
	}
        my $enabled = $par{'enabled'};
        if (save_line($par{'line'},
                      $enabled,
                      $source,
                      $destination,
                      $gateway,
                      $par{'remark'},
                      $par{'tos'},
                      $par{'protocol'},
                      $par{'port'},
                      $mac,
                      $par{'log'},
                      $src_dev,
                      $par{'backup_allow'},)) {

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
$log_accepts = $routing{'LOG_ACCEPTS'};

&showhttpheaders();
my $extraheader = '<script language="JavaScript" src="/include/firewall_type.js"></script>
<script language="JavaScript" src="/include/services_selector.js"></script>';
&openpage(_('Policy Routing'), 1, $extraheader);

init_ethconfig();
configure_nets();
($devices, $deviceshash) = list_devices_description(3, 'LAN|DMZ|LAN2', 0);
save();

if ($reload) {
    system("touch $needreload");
}

&openbigbox("", $warnmessage, $notemessage);

if (-e $needreload) {
    applybox(_("Routing rules have been changed and need to be applied in order to make the changes active"));
}

my $is_editing = ($par{'ACTION'} eq 'edit');
display_rules($is_editing, $par{'line'});

&closebigbox();
&closepage();
