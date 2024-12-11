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

use eSession;
use Net::IPv4Addr qw (:all);


##############################################################################
# part 1:  code common for all steps
##############################################################################

require 'header.pl' if (-e 'header.pl');  # if called from ipcop, header-pl is
                                          # already included.

require '/razwall/web/cgi-bin/netwizard_tools.pl';
require '/razwall/web/cgi-bin/ifacetools.pl';
require '/razwall/web/cgi-bin/ethconfig.pl';
require '/razwall/web/cgi-bin/redtools.pl';
require '/razwall/web/cgi-bin/strings.pl';

my %par;
getcgihash(\%par);

#
# definitions
#

my %steps = ( 1 => _('Choose network mode and uplink type'),
              2 => _('Choose network zones'),
              3 => _('Network preferences'),
              4 => _('Internet access preferences'),
	      5 => _('configure DNS resolver'),
	      6 => _('Configure default admin mail'),
	      7 => _('Apply configuration'),
	      8 => _('End')
            );
my $stepnum = scalar(keys(%steps));
my $reload = '';

my $lever = '';

my %tpl_ph_hash = ();
my $tpl_ph = \%tpl_ph_hash;
my %session_hash = ();
my $session = \%session_hash;
my %settings_hash = ();
my $settings = \%settings_hash;
my $session_id;
my $if_available = 0;

my %live_data_hash = ();
my $live_data = \%live_data_hash;

my $ethernet_settings = 'ethernet/settings';
my $main_settings_file = 'main/settings';
my $host_settings_file = 'host/settings';
my $dhcp_settings_file = 'dhcp/settings';
my $wizard_settings_file = 'wizard/settings';
my $autoconnect_file = '/var/efw/ethernet/noautoconnect';
my $hotspot_settings_file = 'hotspot/settings';

my $refresh = '45';

# firstwizard ?
if ($0 =~ /step2\/*(netwiz|wizard).cgi/) {
    $pagename="firstwizard";
} else { 
    $pagename="netwizard";
}


###


my @eth_keys=('CONFIG_TYPE',

	      'GREEN_ADDRESS',
	      'GREEN_NETMASK',
	      'GREEN_NETADDRESS',
	      'GREEN_BROADCAST',
	      'GREEN_CIDR',
	      'GREEN_DEV',
	      'GREEN_IPS',

	      'ORANGE_ADDRESS',
	      'ORANGE_NETMASK',
	      'ORANGE_NETADDRESS',
	      'ORANGE_BROADCAST',
	      'ORANGE_CIDR',
	      'ORANGE_DEV',
	      'ORANGE_IPS',

	      'BLUE_ADDRESS',
	      'BLUE_NETMASK',
	      'BLUE_NETADDRESS',
	      'BLUE_BROADCAST',
	      'BLUE_CIDR',
	      'BLUE_DEV',
	      'BLUE_IPS',

	      );

my @main_keys=('LANGUAGE',
	       'KEYMAP',
	       'TIMEZONE',
	       'MAIN_ADMINMAIL',
	       'MAIN_MAILFROM',
	       'MAIN_SMARTHOST',
	       'WINDOWWITHHOSTNAME',
	       );

my @host_keys=('HOSTNAME',
	       'DOMAINNAME',
	       );

my @dhcp_keys=('ENABLE_GREEN');

my @hotspot_keys=('HOTSPOT_ENABLED');

#red  blue orange
my %type_config=(
		 '000' => 0,
		 '001' => 1,
		 '100' => 2,
		 '101' => 3,
		 '010' => 4,
		 '011' => 5,
		 '110' => 6,
		 '111' => 7
		 );

my @dns_caption=(_('automatic'),
		 _('manual')
		 );

my @network_types = (
    {'name' => 'ROUTED',
    'caption' => _("Routed"),
    'title' => _("Uplink type (<span style=\"color: red;\">RED</span> zone)"),
    'description' => _("This is the standard operating mode. Uplinks of the following types can be configured here: %s")},
    {'name' => 'BRIDGED',
    'caption' => _("Bridged"),
    'title' => "",
    'description' => _("In this operating mode the appliance acts transparently without the user noticing or needing to change an existing network infrastructure.")},
    {'name' => 'NOUPLINK',
    'caption' => _("No uplink"),
    'title' => "",
    'description' => _("In this operating mode the appliance is part of the local network but does not act as a gateway. Clients like webbrowsers and email clients will have to address the appliance directly. This was previously named Gateway mode.")},
);

my @red_types = (
    {'name' => 'DHCP',
    'caption' => _('Ethernet DHCP'),
    'type' => 'ROUTED'},
    {'name' => 'STATIC',
    'caption' => _('Ethernet static'),
    'type' => 'ROUTED'},
    {'name' => 'MODEM',
    'caption' => _('Mobile Broadband (3G/4G)'),
    'type' => 'ROUTED'},
    {'name' => 'PPPOE',
    'caption' => _('PPPoE'),
    'type' => 'ROUTED'},
    {'name' => 'PPTP',
    'caption' => _('PPTP'),
    'type' => 'ROUTED'},
    {'name' => 'ADSL',
    'caption' => _('ADSL modem'),
    'type' => 'ROUTED'},
    {'name' => 'ISDN',
    'caption' => _('ISDN modem'),
    'type' => 'ROUTED'},
    {'name' => 'ANALOG',
    'caption' => _('ANALOG modem'),
    'type' => 'ROUTED'},
    {'name' => 'NONE',
    'caption' => _('Gateway'),
    'type' => 'NOUPLINK'},
    {'name' => 'STEALTH',
    'caption' => _('Stealth'),
    'type' => 'BRIDGED'}
);

sub init($) {
    $ethernet_settings = $swroot.'/ethernet/settings';
    $main_settings_file = $swroot.'/main/settings';
    $wizard_settings_file = $swroot.'/wizard/settings';
    $host_settings_file = $swroot.'/host/settings';
    $dhcp_settings_file = $swroot.'/dhcp/settings';
    $hotspot_settings_file = $swroot.'/hotspot/settings';
}

# initialize or check & load session
sub init_session() {

    # new session
    if (!defined($par{'session_id'})) {
	$session_id = session_start();
	session_save($session_id, $session);
	print_debug("$0: new session: $session_id\n");
	return;
    }

    # load session
    if (session_check($par{'session_id'})) {
	$session_id = $par{'session_id'};
	session_load($session_id, $session);
	print_debug("$0: existing session: $session_id\n");
	return;
    }

    die('invalid session');
}

sub load_network_items() {
    my @arr = ();
    my $i = 0;
    
    foreach my $type (@network_types) {
        $i++;
        my %hash = (
            'NETWORK_LOOP_INDEX'       => $i,
            'NETWORK_LOOP_NAME'        => $type->{'name'},
            'NETWORK_LOOP_TITLE'       => $type->{'title'},
            'NETWORK_LOOP_CAPTION'     => $type->{'caption'},
            'NETWORK_LOOP_DESCRIPTION' => $type->{'description'},
            'NETWORK_LOOP_RED_ITEM'    => '',
            'NETWORK_LOOP_SELECTED'    => ''
        );
        my @red_items = @{load_red_items($type->{'name'})};
        my $red_names = '';
        foreach (@red_items) {
            if ($_->{RED_LOOP_SELECTED} eq 'checked') {
                $hash{'NETWORK_LOOP_SELECTED'} = 'checked';
            }
            if ($red_names eq '') {
                $red_names = $_->{RED_LOOP_CAPTION};
            } else {
                $red_names = $red_names . ', ' . $_->{RED_LOOP_CAPTION};
            }
        }
        if ($hash{'NETWORK_LOOP_NAME'} eq 'ROUTED') {
            $hash{'NETWORK_LOOP_DESCRIPTION'} = $hash{'NETWORK_LOOP_DESCRIPTION'} . $red_names;
        }
        if (scalar @red_items eq 1) {
            $hash{'NETWORK_LOOP_RED_ITEM'} = $red_items[0]->{'RED_LOOP_NAME'};
        } else {
            $hash{'NETWORK_LOOP_RED_ITEMS'} = \@red_items;
        }
        push(@arr, \%hash);
    }
    
    return \@arr;
}

sub load_red_items($) {
    my $network_type = shift;
    my @arr = ();
    my $i = 0;
    
    foreach my $type (@red_types) {
        my $lever_file = 'lever_'.lc($type->{'name'}).'.pl';
        next if (! -e $lever_file);
        next if ($type->{'type'} ne $network_type);
        $i++;
        my %hash = (
            'RED_LOOP_INDEX'    => $i,
            'RED_LOOP_NAME'     => $type->{'name'},
            'RED_LOOP_CAPTION'  => $type->{'caption'},
            'RED_LOOP_SELECTED' => ($session->{'RED_TYPE'} eq $type->{'name'} ? 'checked':'')
        );
        push(@arr, \%hash);
    }
    
    return \@arr;
}

sub in_list(&@) {
    local $_;
    my $item = shift;
    for (@_) {
        if ($item->()) {
            return 1;
	}
    }
    return 0;
}

sub load_zones_items() {
    my @arr = ();
    my $wizard_settings_hash = ();
    my $wizard_settings = \%wizard_settings_hash;
    readhash($wizard_settings_file, $wizard_settings);
    load_all_keys($session, \@wizard_keys, $wizard_settings, 0, 0);
    load_all_keys($settings, \@wizard_keys, $wizard_settings, 0, 0);
    my @mandatory_zones = split('&', $wizard_settings_hash{'WIZARD_MANDATORY_ZONES'});

    for (my $i=0; $i<4; $i++) {

	my $name = '';
	my $caption = '';
	if ($i == 0) {
            if (scalar(@mandatory_zones)) {
                next;
            }
	    $name = 'NONE';
	    $caption = _('NONE');
	}
	if ($i == 1) {
            if ((in_list {'BLUE' eq $_} @mandatory_zones)) {
                next;
            }
	    $name = 'ORANGE';
	    $caption = _('ORANGE');
	}
	if ($i == 2) {
            if ((in_list {'ORANGE' eq $_} @mandatory_zones)) {
                next;
            }
	    $name = 'BLUE';
	    $caption = _('BLUE');
	}
	if ($i == 3) {
            if ((in_list {'ORANGE_BLUE' eq $_} @mandatory_zones)) {
                next;
            }
	    $name = 'ORANGE_BLUE';
	    $caption = _('ORANGE & BLUE');
	}

	my %hash = (
		    'ZONES_LOOP_INDEX'    => $i,
		    'ZONES_LOOP_NAME'     => $name,
		    'ZONES_LOOP_CAPTION'  => $caption,
		    'ZONES_LOOP_SELECTED' => ($session->{'ZONES'} eq $name ? 'checked':'')
		    );
	push(@arr, \%hash);
    }
    return \@arr;
}


# prepare placeholder data
sub prepare_values() {
    $tpl_ph->{'title'} = _('Step')." ".$live_data->{'step'}."/$stepnum:  ".$steps{$live_data->{'step'}};
    $tpl_ph->{'session_id'} = $session_id;
    $tpl_ph->{'self'} = '';
    $tpl_ph->{'step'} = $live_data->{'step'};
    $tpl_ph->{'substep'} = $live_data->{'substep'};

    my $if_count = get_if_number();
    $tpl_ph->{'if_count'} = $if_count;

    if ($live_data->{'step'} eq '1') {
        $tpl_ph->{'NETWORK_LOOP'} = load_network_items();
        return;
    }
    if ($live_data->{'step'} eq '2') {
	$tpl_ph->{'ZONES_LOOP'} = load_zones_items();
	load_ifaces();
	return;
    }
    if (orange_used()) {
	$tpl_ph->{'HAVE_ORANGE'} = 1;
    }
    if (blue_used()) {
	$tpl_ph->{'HAVE_BLUE'} = 1;
    }

    if ($live_data->{'step'} eq '3') {

	my ($primary, $ip, $mask, $cidr) = getPrimaryIP($session->{'GREEN_IPS'});
	$tpl_ph->{'DISPLAY_GREEN_ADDRESS'} = $ip;
	$tpl_ph->{'DISPLAY_GREEN_NETMASK_LOOP'} = loadNetmasks($cidr);

	$tpl_ph->{'DISPLAY_GREEN_ADDITIONAL'} = getAdditionalIPs($session->{'GREEN_IPS'});
	$tpl_ph->{'DISPLAY_GREEN_ADDITIONAL'} =~ s/,/\n/g;

        $tpl_ph->{'DHCP_ENABLE_GREEN'} = ($session->{'ENABLE_GREEN'} eq 'on' ? 'checked' : '');

	load_ifaces();
	$tpl_ph->{'IFACE_GREEN_LOOP'} = create_ifaces_list('GREEN');
	if (orange_used()) {
	    my ($primary, $ip, $mask, $cidr) = getPrimaryIP($session->{'ORANGE_IPS'});
	    $tpl_ph->{'DISPLAY_ORANGE_ADDRESS'} = $ip;
	    $tpl_ph->{'DISPLAY_ORANGE_NETMASK_LOOP'} = loadNetmasks($cidr);
	    $tpl_ph->{'DISPLAY_ORANGE_ADDITIONAL'} = getAdditionalIPs($session->{'ORANGE_IPS'});
	    $tpl_ph->{'DISPLAY_ORANGE_ADDITIONAL'} =~ s/,/\n/g;

	    $tpl_ph->{'IFACE_ORANGE_LOOP'} = create_ifaces_list('ORANGE');
	}
	if (blue_used()) {
	    my ($primary, $ip, $mask, $cidr) = getPrimaryIP($session->{'BLUE_IPS'});
	    $tpl_ph->{'DISPLAY_BLUE_ADDRESS'} = $ip;
	    $tpl_ph->{'DISPLAY_BLUE_NETMASK_LOOP'} = loadNetmasks($cidr);
	    $tpl_ph->{'DISPLAY_BLUE_ADDITIONAL'} = getAdditionalIPs($session->{'BLUE_IPS'});
	    $tpl_ph->{'DISPLAY_BLUE_ADDITIONAL'} =~ s/,/\n/g;

	    $tpl_ph->{'IFACE_BLUE_LOOP'} = create_ifaces_list('BLUE');
	}
	return;
    }

    if ($live_data->{'step'} eq '4') {

	if ($lever ne '') {
	    lever_prepare_values();
	}

	$tpl_ph->{'DNS_SELECTED_0'} = ($session->{'DNS_N'} == 0 ? 'checked':'');
	$tpl_ph->{'DNS_SELECTED_1'} = ($session->{'DNS_N'} == 1 ? 'checked':'');
    }

    if ($live_data->{'step'} eq '5') {
	$tpl_ph->{'DNS_CAPTION'} = @dns_caption[$session->{'DNS_N'}];
	if ($session->{'DNS_N'} == 1) {
	    $tpl_ph->{'DNS_MANUAL'} = 1;
	}
    }
    if ($live_data->{'step'} eq '8') {
	my ($primary,$ip,$mask,$cidr) = getPrimaryIP($session->{'GREEN_IPS'});
	$tpl_ph->{'GREEN_LINK'} = 'https://'.$ip.':10443/cgi-bin/index.cgi';
    }
}

sub set_config_type() {
    my $red = $session->{'RED_TYPE'};
    my $zones = $session->{'ZONES'};
    my $has_red = ($red =~ /ADSL|ISDN/ ? 0:1);
    my $has_blue = ($zones =~ /BLUE/? 1:0);
    my $has_orange = ($zones =~ /ORANGE/? 1:0);

    $session->{'CONFIG_TYPE'} = $type_config{"$has_red$has_blue$has_orange"};
}

# check parameters according to step,
# put valid parameters to the session and
# return error message if an invalid parameter was found
sub checkpar2session 
{
    ############ step 1

    if ($live_data->{'step'} eq '1') {
	my $red_type = $par{'RED_TYPE'};
	if (defined($red_type) && ($red_type =~ /(?:STATIC|DHCP|ADSL|PPPOE|NONE|STEALTH|ISDN|ANALOG|MODEM)/)) {
	    $session->{'RED_TYPE'} = $red_type;
	    set_config_type();
	    return;
	}
	return _('Please select a type of RED interface!');
    }

    ############ step 2

    if ($live_data->{'step'} eq '2') {
	my $zones = $par{'ZONES'};
	if (defined($zones) && ($zones =~ /(?:NONE|BLUE|ORANGE|ORANGE_BLUE)/)) {
	    $session->{'ZONES'} = $zones;
	    set_config_type();
	    return;
	}
	return _('Invalid zone!');
    }


    ############ step 3

    if ($live_data->{'step'} eq '3') {
	listdevices(1);
	my $err = '';
	if ($par{'HOSTNAME'} eq '') {
	    $err .= _('Please insert the hostname!').'<BR><BR>';
	} elsif (!($par{'HOSTNAME'} =~ /^[a-zA-Z]{1,1}[a-zA-Z0-9\.\-\_]{1,255}[a-zA-Z0-9]{1,1}$/)) {
	    $session->{'HOSTNAME'} = $par{'HOSTNAME'};
	    $err .= _('Please insert a valid hostname!').'<BR><BR>';	
	} else {
	    if ($settings->{'HOSTNAME'} ne $par{'HOSTNAME'}) {
		$session->{'rebuildcert'} = 1;
	    }
	    $session->{'HOSTNAME'} = $par{'HOSTNAME'};
	}


        if ((! $par{'DOMAINNAME'} eq '') && ! validdomainname($par{'DOMAINNAME'})) {
            $session->{'DOMAINNAME'} = $par{'DOMAINNAME'};
            $err .= _('Please insert a valid domainname!').'<BR><BR>';
	} else {
	    if ($settings->{'DOMAINNAME'} ne $par{'DOMAINNAME'}) {
		$session->{'rebuildcert'} = 1;
	    }
	    $session->{'DOMAINNAME'} = $par{'DOMAINNAME'};
	}

	my $ifacelist = ifnum2device($par{'GREEN_DEVICES'});
	$session->{'GREEN_DEVICES'} = $ifacelist;
        if ($ifacelist =~ /^$/) {
            my $zone = _('GREEN');
	    $err .= _('Please select at least one interface for zone %s!', $zone).'<BR><BR>';
        }

        if ($par{'DHCP_ENABLE_GREEN'} eq 'on') {
            $session->{'ENABLE_GREEN'} = 'on';
        } else {
            $session->{'ENABLE_GREEN'} = 'off';
        }

	if (orange_used()) {
	    my $ifacelist = ifnum2device($par{'ORANGE_DEVICES'});
	    my $reterr = check_iface_free($ifacelist, 'ORANGE');
	    if ($reterr) {
		$err .= $reterr;
	    } else {
		$session->{'ORANGE_DEVICES'} = $ifacelist;
	    }
            # if ($ifacelist =~ /^$/) {
            #     my $zone = _('ORANGE');
	        #     $err .= _('Please select at least one interface for zone %s!', $zone).'<BR><BR>';
            # }
	} else {
	    $session->{'ORANGE_DEVICES'} = unset;
	}
	if (blue_used()) {
	    my $ifacelist = ifnum2device($par{'BLUE_DEVICES'});
	    my $reterr = check_iface_free($ifacelist, 'BLUE');
	    if ($reterr) {
		$err .= $reterr;
	    } else {
		$session->{'BLUE_DEVICES'} = $ifacelist;
	    }
            # if ($ifacelist =~ /^$/) {
            #     my $zone = _('BLUE');
	        #     $err .= _('Please select at least one interface for zone %s!', $zone).'<BR><BR>';
            # }
	} else {
	    $session->{'BLUE_DEVICES'} = unset;
	}

	my ($ok_ips, $nok_ips) = createIPS($par{'DISPLAY_GREEN_ADDRESS'}.'/'.$par{'DISPLAY_GREEN_NETMASK'}, $par{'DISPLAY_GREEN_ADDITIONAL'});
	if ($nok_ips ne '') {
	    foreach my $nokip (split(/,/, $nok_ips)) {
		$err .= _('The GREEN IP address or network mask "%s" is not correct.', $nokip).'<BR>';
	    }
	} else {
	    my ($primary, $ip, $mask, $cidr) = getPrimaryIP($ok_ips);
	    my ($oldprimary, $oldip, $oldmask, $oldcidr) = getPrimaryIP($session->{'GREEN_IPS'});
	    
	    if ($ip ne $oldip) {
		$session->{'green_changed'} = 1;
	    }

	    $session->{'GREEN_IPS'} = $ok_ips;

	    foreach my $invalid (@{checkNetaddress($session->{'GREEN_IPS'})}) {
		$err .= _("The GREEN IP address '%s' is the same as its network address, which is not allowed!", $invalid)."<BR><BR>";
	    }
	    foreach my $invalid (@{checkBroadcast($session->{'GREEN_IPS'})}) {
		$err .= _("The GREEN IP address '%s' is the same as its broadcast address, which is not allowed!", $invalid)."<BR><BR>";
	    }
	    foreach my $invalid (@{checkInvalidMask($session->{'GREEN_IPS'})}) {
		$err .= _("The network mask of the GREEN IP address '%s' addresses only 1 IP address, which will lock you out if applied. Choose another one!", $invalid)."<BR><BR>";
	    }
	}

	if (orange_used()) {
	    my ($ok_ips, $nok_ips) = createIPS($par{'DISPLAY_ORANGE_ADDRESS'}.'/'.$par{'DISPLAY_ORANGE_NETMASK'}, $par{'DISPLAY_ORANGE_ADDITIONAL'});
	    if ($nok_ips ne '') {
		foreach my $nokip (split(/,/, $nok_ips)) {
		    $err .= _('The ORANGE IP address or network mask "%s" is not correct.', $nokip).'<BR>';
		}
	    } else {
		$session->{'ORANGE_IPS'} = $ok_ips;
		
		foreach my $invalid (@{checkNetaddress($session->{'ORANGE_IPS'})}) {
		    $err .= _("The ORANGE IP address '%s' is the same as its network address, which is not allowed!", $invalid)."<BR><BR>";
		}
		foreach my $invalid (@{checkBroadcast($session->{'ORANGE_IPS'})}) {
		    $err .= _("The ORANGE IP address '%s' is the same as its broadcast address, which is not allowed!", $invalid)."<BR><BR>";
		}
		foreach my $invalid (@{checkInvalidMask($session->{'ORANGE_IPS'})}) {
		    $err .= _("The network mask of the ORANGE IP address '%s' addresses only 1 IP address, which will lock you out if applied. Choose another one!", $invalid)."<BR><BR>";
		}
	    }
	}
	if (blue_used()) {
	    my ($ok_ips, $nok_ips) = createIPS($par{'DISPLAY_BLUE_ADDRESS'}.'/'.$par{'DISPLAY_BLUE_NETMASK'}, $par{'DISPLAY_BLUE_ADDITIONAL'});
	    if ($nok_ips ne '') {
		foreach my $nokip (split(/,/, $nok_ips)) {
		    $err .= _('The BLUE IP address or network mask "%s" is not correct.', $nokip).'<BR>';
		}
	    } else {
		$session->{'BLUE_IPS'} = $ok_ips;
		
		foreach my $invalid (@{checkNetaddress($session->{'BLUE_IPS'})}) {
		    $err .= _("The BLUE IP address '%s' is the same as its network address, which is not allowed!", $invalid)."<BR><BR>";
		}
		foreach my $invalid (@{checkBroadcast($session->{'BLUE_IPS'})}) {
		    $err .= _("The BLUE IP address '%s' is the same as its broadcast address, which is not allowed!", $invalid)."<BR><BR>";
		}
		foreach my $invalid (@{checkInvalidMask($session->{'BLUE_IPS'})}) {
		    $err .= _("The network mask of the BLUE IP address '%s' addresses only 1 IP address, which will lock you out if applied. Choose another one!", $invalid)."<BR><BR>";
		}
	    }
	}

	if ($err ne '') {
	    return $err;
	}

	if (orange_used()) {
	    if (network_overlap($session->{'GREEN_IPS'}, $session->{'ORANGE_IPS'})) {
		$err .= _('The GREEN and ORANGE networks are not distinct.').'<BR><BR>';
	    }
	}
	if (blue_used()) {
	    if (network_overlap($session->{'GREEN_IPS'}, $session->{'BLUE_IPS'})) {
		$err .= _('The GREEN and BLUE networks are not distinct.').'<BR><BR>';
		
	    }
	}
	if (blue_used() && orange_used()) {
	    if (network_overlap($session->{'ORANGE_IPS'}, $session->{'BLUE_IPS'})) {
		$err .= _('The ORANGE and BLUE networks are not distinct.').'<BR><BR>';
		
	    }
	}

	return $err;
    }
    
    
    
    ############ step 4
    
    if ($live_data->{'step'} eq '4') {
	my $err = '';

	if ($lever ne '') {
	    return lever_savedata();
	}
	return $err;
    }


    if ($live_data->{'step'} eq '5') {
	if ($session->{'DNS_N'} == 0) {
	    return;
	}

	my $ip = '';
	my $mask = '';
	my $err = '';
	    
	($err, $ip, $mask) = check_ip($par{'DNS1'}, '255.255.255.255');
	if ($err) {
	    $session->{'DNS1'} = $ip;
	} else {
	    $ret .= _('The IP address of DNS1 is not correct.').'<BR>';
	}

	($err, $ip, $mask) = check_ip($par{'DNS2'}, '255.255.255.255');
	if ($err) {
	    $session->{'DNS2'} = $ip;
	} else {
	    $ret .= _('The IP address of DNS2 is not correct.').'<BR>';
	}

	if ($ret ne '') {
	    return $ret;
	}
	return;
    }

    if ($live_data->{'step'} eq '6') {
	my $err = '';

	if ($par{'MAIN_MAILFROM'}) {
	    if (! validemail($par{'MAIN_MAILFROM'})) {
		$err .= _("Sender e-mail address '%s' is invalid", 
			  $par{'MAIN_MAILFROM'})."<BR>";
	    } else {
		$session->{'MAIN_MAILFROM'} = $par{'MAIN_MAILFROM'};
	    }
	}

	if ($par{'MAIN_ADMINMAIL'}) {
	    if (! validemail($par{'MAIN_ADMINMAIL'})) {
		$err .= _("Admin e-mail address '%s' is invalid", 
			  $par{'MAIN_ADMINMAIL'})."<BR>";
	    } else {
		$session->{'MAIN_ADMINMAIL'} = $par{'MAIN_ADMINMAIL'};
	    }
	}

	if ($par{'MAIN_SMARTHOST'}) {
	    my ($host, $port) = split(/:/, $par{'MAIN_SMARTHOST'});
	    my $ok = 1;
	    if (! (validip($host) || validfqdn($host) || validhostname($host))) {
		$err .= _("Host '%s' of mail smarthost '%s' is no valid fqdn, hostname or IP address",
			  $host, $par{'MAIN_SMARTHOST'}
		    );
		$ok = 0;
	    }
	    if ($port && !validport($port)) {
		$err .= _("Port '%s' of mail smarthost '%s' is no valid port.",
			  $port, $par{'MAIN_SMARTHOST'}
		    );
		$ok = 0;
	    }
	    if ($ok) {
		$session->{'MAIN_SMARTHOST'} = $par{'MAIN_SMARTHOST'};
	    }
	}

	return $err;
    }

    
    if ($live_data->{'step'} eq '7') {
	apply();
	$reload = 'YES DO IT';
	return;
    }
    
    return 'NOT IMPLEMENTED';
}

sub alter_eth_settings($) {
    my $ref = shift;
    my %config = %$ref;
    my $next_if = 1; # 0 == green
    my $fixed = 0;

    my ($primary,$ip,$mask,$cidr) = getPrimaryIP($config{'GREEN_IPS'});
    $config{'GREEN_ADDRESS'} = $ip;
    $config{'GREEN_NETMASK'} = $mask;
    $config{'GREEN_CIDR'} = $cidr;
    ($config{'GREEN_NETADDRESS'},) = ipv4_network($primary);
    $config{'GREEN_BROADCAST'} = ipv4_broadcast($primary);

    if (orange_used()) {
	my ($primary,$ip,$mask,$cidr) = getPrimaryIP($config{'ORANGE_IPS'});
	$config{'ORANGE_ADDRESS'} = $ip;
	$config{'ORANGE_NETMASK'} = $mask;
	$config{'ORANGE_CIDR'} = $cidr;
	($config{'ORANGE_NETADDRESS'},) = ipv4_network($primary);
	$config{'ORANGE_BROADCAST'} = ipv4_broadcast($primary);
    }
    if (blue_used()) {
	my ($primary,$ip,$mask,$cidr) = getPrimaryIP($config{'BLUE_IPS'});
	$config{'BLUE_ADDRESS'} = $ip;
	$config{'BLUE_NETMASK'} = $mask;
	$config{'BLUE_CIDR'} = $cidr;
	($config{'BLUE_NETADDRESS'},) = ipv4_network($primary);
	$config{'BLUE_BROADCAST'} = ipv4_broadcast($primary);
    }
    return \%config;
}

sub apply() {
    satanize($session);
    if ($session->{'RED_DEV'}) {
	disable_conflicting_uplinks($session->{'RED_DEV'});
    }
    my $eth_settings = alter_eth_settings(select_from_hash(\@eth_keys, $session));
    writehash($ethernet_settings, $eth_settings);
    writehash($main_settings_file, select_from_hash(\@main_keys, $session));
    writehash($host_settings_file, select_from_hash(\@host_keys, $session));
    writehash($dhcp_settings_file, select_from_hash(\@dhcp_keys, $session));
    #if ($session->{'HOTSPOT_ENABLED'} == 'off') {
    #    writehash($hotspot_settings_file, select_from_hash(\@hotspot_keys, $session));
    #}
    write_bridges();
    set_red_default("");

    if ($lever ne '') {
	lever_apply();
    }
}


# load all necessary values into the session, if not already present
sub load_values {
    my %ethhash = ();
    my $eth_settings = \%ethhash;

    readhash($ethernet_settings, $eth_settings);
    load_all_keys($session, \@eth_keys, $eth_settings, 0, 0);
    load_all_keys($settings, \@eth_keys, $eth_settings, 0, 0);

    my %main_settings_hash = ();
    my $main_settings = \%main_settings_hash;
    readhash($main_settings_file, $main_settings);
    load_all_keys($session, \@main_keys, $main_settings, 0, 0);
    load_all_keys($settings, \@main_keys, $main_settings, 0, 0);

    my $host_settings_hash = ();
    my $host_settings = \%host_settings_hash;
    readhash($host_settings_file, $host_settings);
    load_all_keys($session, \@host_keys, $host_settings, 0, 0);
    load_all_keys($settings, \@host_keys, $host_settings, 0, 0);

    my $dhcp_settings_hash = ();
    my $dhcp_settings = \%dhcp_settings_hash;
    readhash($dhcp_settings_file, $dhcp_settings);
    load_all_keys($session, \@dhcp_keys, $dhcp_settings, 0, 0);
    load_all_keys($settings, \@dhcp_keys, $dhcp_settings, 0, 0);

    if ($pagename eq "firstwizard") {
        # enable DHCP server on green at the first netwizard
        $session->{'ENABLE_GREEN'} = 'on';
    }

    my $hotspot_settings_hash = ();
    my $hotspot_settings = \%hotspot_settings_hash;
    readhash($hotspot_settings_file, $hotspot_settings);
    load_all_keys($session, \@hotspot_keys, $hotspot_settings, 0, 0);
    load_all_keys($settings, \@hotspot_keys, $hotspot_settings, 0, 0);

    if (orange_used()) {
	$session->{'ZONES'} = 'ORANGE';
    }
    if (blue_used()) {
	$session->{'ZONES'} = 'BLUE';
    }
    if (orange_used() && blue_used()) {
	$session->{'ZONES'} = 'ORANGE_BLUE';
    }
    if (! orange_used() && ! blue_used()) {
	$session->{'ZONES'} = 'NONE';
    }
    $session->{'GREEN_DEV'} = 'br0';
    $session->{'ORANGE_DEV'} = 'br1';
    $session->{'BLUE_DEV'} = 'br2';

    load_red('MAIN');
    if ($lever ne '') {
	lever_load();
    }
}


# realizes the substeps within modem configuration
sub substep($) {
    my $direction = shift;

    if (! lever_check_substep()) {
	$live_data->{'substep'} = 1;
	return;
    }
    $live_data->{'substep'} += $direction;
    if (! lever_check_substep()) {
	$live_data->{'step'} += $direction;
	$live_data->{'substep'} = 0;
    }
}

sub in_substep() {
    if (($live_data->{'step'} == 4) && ($lever ne '')) {
	return 1;
    }
    return 0;
}


sub set_lever() {
    if ($live_data->{'step'} != 4) {
	$lever = $session->{'lever'};
	return;
    }
    $lever = lc($session->{'RED_TYPE'});
    $session->{'lever'} = $lever;
}

sub load_lever() {
    my $lever_file = 'lever_skel.pl';
    if ($lever ne '') {
	$lever_file = 'lever_'.$lever.'.pl';
    }
    if (! -e $lever_file) {
	die("Lever file $lever_file not found!");
    }
    require $lever_file;
    lever_init($session, $settings, \%par, $tpl_ph, $live_data);
}


# check last step's parameters, update the session 
# and decide which step to do next
sub state_machine() {
    $live_data->{'step'} = $par{'step'};
    $live_data->{'substep'} = $par{'substep'};

    set_lever();
    load_lever();

    if (!exists($steps{$live_data->{'step'}})) {
	# first invocation -> step = 1
	$live_data->{'step'} = 1;
	return;
    }

    # Check if the hotspot is active and if a BLUE zone is enabled.
    $tpl_ph->{'warning_message'} = '';

    if ($settings->{'HOTSPOT_ENABLED'} eq 'on') {
        #$session->{'HOTSPOT_ENABLED'} = $settings->{'HOTSPOT_ENABLED'};
        if ($par{'ZONES'} ne 'BLUE' && $par{'ZONES'} ne 'ORANGE_BLUE') {
            #$session->{'HOTSPOT_ENABLED'} = 'off';
            $tpl_ph->{'warning_message'} = _('WARNING: no BLUE zone selected; the hotspot will be turned off');
	}
    }

    $tpl_ph->{'error_message'} = '';
    # follow up step -> see whether 'prev' or 'next' was pressed
    if (defined($par{'next'})) {
	# next -> check values and store them

	my $err = checkpar2session();
	if (defined($err) and $err ne '') {
	    # valid: go to next page
	    $tpl_ph->{'error_message'} = $err;
	    return;
	}
	$direction = 1;

    } elsif (defined($par{'prev'})) {
	# prev -> forget parameters, go the previous page
	$direction = -1;
    } elsif (defined($par{'cancel'})) {
	my ($primary, $ip, $mask, $cidr) = getPrimaryIP($session->{'GREEN_IPS'});
        $header = '<meta http-equiv="refresh" content="'.$refresh.'; URL=https://'.$ip.':10443/cgi-bin/main.cgi">';
    } else {
	die('no "next" or "prev" defined');
    }

    if (! in_substep()) {
	$live_data->{'step'} += $direction;
	if ($live_data->{'step'} == 0) {
	    $live_data->{'step'} = 1;
	}
    }

    set_lever();
    load_lever();

    if (in_substep()) {
	substep($direction);
	return;
    }
}

sub get_template($$) {
    
    use HTML::Template::Expr;

    my $filename = shift;
    my $values_ref = shift;
    my %values = %$values_ref;

    my $template = HTML::Template::Expr->new(filename => $filename,
					     die_on_bad_params => 0
					     );
    $template->param(%values);
    return $template->output();

}

sub satanize($) {
    my $ref = shift;
    foreach $key (%$ref) {
	if ($ref->{$key} eq '__EMPTY__') {
	    $ref->{$key} = '';
	}
    }
    return $ref;
}


# print template, filling placeholders with: %tr, %session and %tpl_ph
sub print_template($) {
    my $config_base = shift;
    my $filename = '';

    my %values_hash = ();
    my $values = \%values_hash;

    $values = hash_merge($values, \%strings);

    init($config_base);
    init_session();
    init_ifacetools($session, \%par);
    init_redtools($session, $settings);
    init_ethconfig();

    load_values();
    state_machine();
    prepare_values();

    $values = hash_merge($values, satanize(prefix('NW_VAL_',$session)));
    $values = hash_merge($values, satanize(prefix('NW_VAL_',$tpl_ph)));

    $filename = 'netwiz'.$live_data->{'step'};
    if ($live_data->{'substep'} != 0) {
	$filename .= "_".$lever."_".$live_data->{'substep'};
    }

    my $content = get_template('/usr/share/netwizard/' .$filename.'.tmpl', $values);
    session_save($session_id, $session);
    my $header = '';

    if ($reload eq 'YES DO IT') {
	my ($primary,$ip,$mask,$cidr) = getPrimaryIP($session->{'GREEN_IPS'});
        if ($pagename eq "firstwizard") {
	    my %wizardhash;
	    my $wizardfile = "/var/efw/wizard/settings";
	    readhash($wizardfile, \%wizardhash);
	    my $state = uc($wizardhash{'WIZARD_STATE'});
	    my $next = uc($wizardhash{"WIZARD_NEXT_$state"});
	    $wizardhash{'WIZARD_STATE'} = $next;
	    writehash($wizardfile, \%wizardhash);
            $header = '<meta http-equiv="refresh" content="'.$refresh.'; URL=https://'.$ip.':10443/cgi-bin/index.cgi" />';
        } else {
            $header = '<meta http-equiv="refresh" content="'.$refresh.'; URL=https://'.$ip.':10443/cgi-bin/main.cgi" />';
        }

    }
    return ($reload, $header, $content, $session->{'rebuildcert'});

}

if (defined($par{'cancel'})) {
    print "Status: 302 Moved\n";
    print "Location: https://".$ENV{'SERVER_ADDR'}.":10443/cgi-bin/main.cgi\n\n";
    exit;
}

1;
