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

use eSession;
use Net::IPv4Addr qw (:all);


##############################################################################
# part 1:  code common for all steps
##############################################################################

require 'header.pl' if (-e 'header.pl');  # if called from ipcop, header-pl is
                                          # already included.

require 'razinc.pl';
require 'wantools.pl';
require 'strings.pl';

my %par;
getcgihash(\%par);

#
# definitions
#

my %steps = ( 1 => _('Network Mode & Type'),
              2 => _('Network zones'),
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
my $swroot = '/razwall/config';
my $ethernet_settings = 'ethernet/settings'; # LAN
#my $main_settings_file = 'main/settings'; # ADMIN EMAIL, SMTP, NOT USED YET
my $host_settings_file = 'host/settings'; # HOST NAME
my $dhcp_settings_file = 'dhcp/settings'; # DHCP SETTINGS
my $wizard_settings_file = 'wizard/settings'; # SETUP WIZARD
my $autoconnect_file = '/razwall/config/ethernet/noautoconnect'; # AUTO CONNECT ON STARTUP? - NOT USED YET
my $hotspot_settings_file = 'hotspot/settings'; # HOSTSPOT - NOT USED YET
my $zone_settings = "${swroot}/zones/settings"; # RAZWALL ZONE SETTINGS
my $refresh = '45';

# firstwizard ?
if ($0 =~ /step2\/*(netwiz|wizard).cgi/) {
    $pagename="firstwizard";
} else { 
    $pagename="netwizard";
}


my @ALL_ZONES = &get_zones; # FETCH DYNAMIC ZONES - RAZWALL
#INITIAIZE ARRAY
my @eth_keys=('CONFIG_TYPE');

foreach $zone (@ALL_ZONES) {
	push(@eth_keys, "$zone_ADDRESS");
	push(@eth_keys, "$zone_NETMASK");
	push(@eth_keys, "$zone_NETADDRESS");
	push(@eth_keys, "$zone_BROADCAST");
	push(@eth_keys, "$zone_CIDR");
	push(@eth_keys, "$zone_DEV");
	push(@eth_keys, "$zone_IPS");
}

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

my @dhcp_keys=('ENABLE_LAN');

my @hotspot_keys=('HOTSPOT_ENABLED');

#my %type_config=( # NO LONGER NEEDED.. BUNCH OF IDIOTS!

my @dns_caption=(_('automatic'),
		 _('manual')
		 );

my @wan_network_types = (
    {'name' => 'ROUTED',
    'caption' => _("Routed"),
    'title' => _("Uplink type (<span style=\"color: red;\">WAN</span> zone)"),
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

my @wan_types = (
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

    push(@lines, $line);
    }
    close (FILE);
    return @lines;
}

 #######
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
    
    foreach my $type (@wan_network_types) {
        $i++;
        my %hash = (
            'NETWORK_LOOP_INDEX'       => $i,
            'NETWORK_LOOP_NAME'        => $type->{'name'},
            'NETWORK_LOOP_TITLE'       => $type->{'title'},
            'NETWORK_LOOP_CAPTION'     => $type->{'caption'},
            'NETWORK_LOOP_DESCRIPTION' => $type->{'description'},
            'NETWORK_LOOP_WAN_ITEM'    => '',
            'NETWORK_LOOP_SELECTED'    => ''
        );
        my @wan_items = @{load_wan_items($type->{'name'})};
        my $wan_names = '';
        foreach (@wan_items) {
            if ($_->{WAN_LOOP_SELECTED} eq 'checked') {
                $hash{'NETWORK_LOOP_SELECTED'} = 'checked';
            }
            if ($wan_names eq '') {
                $wan_names = $_->{WAN_LOOP_CAPTION};
            } else {
                $wan_names = $wan_names . ', ' . $_->{WAN_LOOP_CAPTION};
            }
        }
        if ($hash{'NETWORK_LOOP_NAME'} eq 'ROUTED') {
            $hash{'NETWORK_LOOP_DESCRIPTION'} = $hash{'NETWORK_LOOP_DESCRIPTION'} . $wan_names;
        }
        if (scalar @wan_items eq 1) {
            $hash{'NETWORK_LOOP_WAN_ITEM'} = $wan_items[0]->{'WAN_LOOP_NAME'};
        } else {
            $hash{'NETWORK_LOOP_WAN_ITEMS'} = \@wan_items;
        }
        push(@arr, \%hash);
    }
    
    return \@arr;
}

sub load_wan_items($) {
    my $network_type = shift;
    my @arr = ();
    my $i = 0;
    
    foreach my $type (@wan_types) {
        my $lever_file = 'lever_'.lc($type->{'name'}).'.pl';
        next if (! -e $lever_file);
        next if ($type->{'type'} ne $network_type);
        $i++;
        my %hash = (
            'WAN_LOOP_INDEX'    => $i,
            'WAN_LOOP_NAME'     => $type->{'name'},
            'WAN_LOOP_CAPTION'  => $type->{'caption'},
            'WAN_LOOP_SELECTED' => ($session->{'WAN_TYPE'} eq $type->{'name'} ? 'checked':'')
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

	my %hash = (
		    'ZONES_LOOP_INDEX'    => $i,
		    'ZONES_LOOP_NAME'     => $name,
		    'ZONES_LOOP_CAPTION'  => $caption,
		    'ZONES_LOOP_SELECTED' => ($session->{'ZONES'} eq $name ? 'checked':'')
		    );
			warn "INDEX: $i\n NAME: $name\n CAPTION: $caption\n SELECTED: $session->{'ZONES'}\n";
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
		warn "arrived here: 1";
        $tpl_ph->{'NETWORK_LOOP'} = load_network_items();
        return;
    }
    if ($live_data->{'step'} eq '2') {
		warn "arrived here: 2";
	$tpl_ph->{'ZONES_LOOP'} = load_zones_items();
	warn "ZONE_LOOP: @{$tpl_ph->{'ZONES_LOOP'}}";
	load_ifaces();
	return;
    }

    if ($live_data->{'step'} eq '3') {
	warn "arrived here: 3";
	
	warn "STEP 3 ZONES: @zones\n";

	# KEEP FOR PRIMARY LAN INTERFACE!:
	my ($primary, $ip, $mask, $cidr) = getPrimaryIP($session->{'LAN_IPS'});
	warn "PRIMARY: $primary\n IP: $ip\n MASK: $mask\n CIDR: $cidr\n";
	#######
	foreach $zone (@zones) {
		open(ZF, "< $swroot/zones/$zone") or print "Unable to open zone file: $!\n";
		@data = <ZF>;
		close(ZF);

		# @data sample:
		# ZIFACE=eth0|eth1|eth2
		# ZSTRING=LAN|PRETTY NAME|DUMB NAME
		# ZCOLOR=green|red|blue|orange|yellow|... endless opportunitures
		# ZTYPE=LAN|WAN|LOCAL
		# ZDESC=Description of zone
		# ZADDRESS=
		# ZNETMASK=
		# ZADDITIONAL=
		# ZDHCP=off
		
		foreach $kv (@data) {
			($k,$v) = split(/=/, $kv);
			${$k} = $v;
		}
		
		%zonecolors = ($zone => "$ZCOLOR");
		%strings_zone = ($zone => "$ZSTRING"); 
		%zone_ifaces = ($zone => "$ZIFACE");
		%zone_type = ($zone => "$ZTYPE");
		%zone_desc = ($zone => "$ZDESC");
		%zone_address = ($zone => "$ZADDRESS");
		%zone_netmask = ($zone => "$ZNETMASK");
		%zone_additional = ($zone => "$ZADDITIONAL");
		%zone_dhcp = ($zone => "$ZDHCP");

		# WE NEED TO MAKE THIS A LOOP FOR EACH ZONE AND DYAMICALLY GENERATE:
		$tpl_ph->{'DISPLAY_'.$ZSTRING.'_ADDRESS'} = $ZADDRESS;
		$tpl_ph->{'DISPLAY_'.$ZSTRING.'_NETMASK_LOOP'} = loadNetmasks($cidr);
		$tpl_ph->{'DISPLAY_'.$ZSTRING.'_ADDITIONAL'} = getAdditionalIPs($session->{$ZADDITIONAL});
		$tpl_ph->{'DISPLAY_'.$ZSTRING.'_ADDITIONAL'} =~ s/,/\n/g;
		$tpl_ph->{'DHCP_ENABLE_'.$ZSTRING} = ($session->{$ZDHCP} eq 'on' ? 'checked' : '');
		load_ifaces();
		$tpl_ph->{'IFACE_'.$ZSTRING.'_LOOP'} = create_ifaces_list($ZSTRING);
	}

	# WE NEED TO MAKE THIS A LOOP FOR EACH ZONE AND DYAMICALLY GENERATE:
#	$tpl_ph->{'DISPLAY_LAN_ADDRESS'} = $ip;
#	$tpl_ph->{'DISPLAY_LAN_NETMASK_LOOP'} = loadNetmasks($cidr);
#	$tpl_ph->{'DISPLAY_LAN_ADDITIONAL'} = getAdditionalIPs($session->{'LAN_IPS'});
#	$tpl_ph->{'DISPLAY_LAN_ADDITIONAL'} =~ s/,/\n/g;
 #   $tpl_ph->{'DHCP_ENABLE_LAN'} = ($session->{'ENABLE_LAN'} eq 'on' ? 'checked' : '');

#	load_ifaces();
#	$tpl_ph->{'IFACE_LAN_LOOP'} = create_ifaces_list('LAN');
	return;
    }

    if ($live_data->{'step'} eq '4') {
	warn "arrived here: 4";
	if ($lever ne '') {
	    lever_prepare_values();
	}

	$tpl_ph->{'DNS_SELECTED_0'} = ($session->{'DNS_N'} == 0 ? 'checked':'');
	$tpl_ph->{'DNS_SELECTED_1'} = ($session->{'DNS_N'} == 1 ? 'checked':'');
    }

    if ($live_data->{'step'} eq '5') {
		warn "arrived here: 5";
	$tpl_ph->{'DNS_CAPTION'} = @dns_caption[$session->{'DNS_N'}];
	if ($session->{'DNS_N'} == 1) {
	    $tpl_ph->{'DNS_MANUAL'} = 1;
	}
    }
    if ($live_data->{'step'} eq '8') {
		warn "arrived here: 8";
	my ($primary,$ip,$mask,$cidr) = getPrimaryIP($session->{'LAN_IPS'});
	$tpl_ph->{'LAN_LINK'} = 'https://'.$ip.':10443/cgi-bin/index.cgi';
    }
}

# ONLY NEEDED FOR SETTING WAN TYPE AND HAS WAN
sub set_config_type() {
    my $wan = $session->{'WAN_TYPE'};
    #my $zones = $session->{'ZONES'};
    my $has_wan = ($wan =~ /ADSL|ISDN/ ? 0:1);
}

# check parameters according to step,
# put valid parameters to the session and
# return error message if an invalid parameter was found
sub checkpar2session 
{
    ############ step 1

    if ($live_data->{'step'} eq '1') {
	my $wan_type = $par{'WAN_TYPE'};
	if (defined($wan_type) && ($wan_type =~ /(?:STATIC|DHCP|ADSL|PPPOE|NONE|STEALTH|ISDN|ANALOG|MODEM)/)) {
	    $session->{'WAN_TYPE'} = $wan_type;
	    set_config_type();
	    return;
	}
	return _('Please select a type of WAN interface!');
    }

    ############ step 2
	# ZONES: LAN|WAN|WAN2|DMZ|WIFI|LOCAL
    if ($live_data->{'step'} eq '2') {
	my @allzones = &get_zones;
	$zones = join("|", @allzones);
	warn "STEP 2 ZONES: $zones";
	if (defined($zones)) { # && ($zones =~ /(?:NONE|LAN2|DMZ|DMZ_LAN2)/)) {
	    $session->{'ZONES'} = $zones;
	    set_config_type();
	    return;
	}
	return _('Invalid zone!');
    }


    ############ step 3

    if ($live_data->{'step'} eq '3') {
		warn "MADE IT TO STEP 3 LIST BUILDER.\n";
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

	my $ifacelist = ifnum2device($par{'LAN_DEVICES'});
	$session->{'LAN_DEVICES'} = $ifacelist;
        if ($ifacelist =~ /^$/) {
            my $zone = _('LAN');
	    $err .= _('Please select at least one interface for zone %s!', $zone).'<BR><BR>';
        }

        if ($par{'DHCP_ENABLE_LAN'} eq 'on') {
            $session->{'ENABLE_LAN'} = 'on';
        } else {
            $session->{'ENABLE_LAN'} = 'off';
        }

	if (dmz_used()) {
	    my $ifacelist = ifnum2device($par{'DMZ_DEVICES'});
	    my $reterr = check_iface_free($ifacelist, 'DMZ');
	    if ($reterr) {
		$err .= $reterr;
	    } else {
		$session->{'DMZ_DEVICES'} = $ifacelist;
	    }
            # if ($ifacelist =~ /^$/) {
            #     my $zone = _('DMZ');
	        #     $err .= _('Please select at least one interface for zone %s!', $zone).'<BR><BR>';
            # }
	} else {
	    $session->{'DMZ_DEVICES'} = unset;
	}
	if (lan2_used()) {
	    my $ifacelist = ifnum2device($par{'LAN2_DEVICES'});
	    my $reterr = check_iface_free($ifacelist, 'LAN2');
	    if ($reterr) {
		$err .= $reterr;
	    } else {
		$session->{'LAN2_DEVICES'} = $ifacelist;
	    }
            # if ($ifacelist =~ /^$/) {
            #     my $zone = _('LAN2');
	        #     $err .= _('Please select at least one interface for zone %s!', $zone).'<BR><BR>';
            # }
	} else {
	    $session->{'LAN2_DEVICES'} = unset;
	}

	my ($ok_ips, $nok_ips) = createIPS($par{'DISPLAY_LAN_ADDRESS'}.'/'.$par{'DISPLAY_LAN_NETMASK'}, $par{'DISPLAY_LAN_ADDITIONAL'});
	if ($nok_ips ne '') {
	    foreach my $nokip (split(/,/, $nok_ips)) {
		$err .= _('The LAN IP address or network mask "%s" is not correct.', $nokip).'<BR>';
	    }
	} else {
	    my ($primary, $ip, $mask, $cidr) = getPrimaryIP($ok_ips);
	    my ($oldprimary, $oldip, $oldmask, $oldcidr) = getPrimaryIP($session->{'LAN_IPS'});
	    
	    if ($ip ne $oldip) {
		$session->{'lan_changed'} = 1;
	    }

	    $session->{'LAN_IPS'} = $ok_ips;

	    foreach my $invalid (@{checkNetaddress($session->{'LAN_IPS'})}) {
		$err .= _("The LAN IP address '%s' is the same as its network address, which is not allowed!", $invalid)."<BR><BR>";
	    }
	    foreach my $invalid (@{checkBroadcast($session->{'LAN_IPS'})}) {
		$err .= _("The LAN IP address '%s' is the same as its broadcast address, which is not allowed!", $invalid)."<BR><BR>";
	    }
	    foreach my $invalid (@{checkInvalidMask($session->{'LAN_IPS'})}) {
		$err .= _("The network mask of the LAN IP address '%s' addresses only 1 IP address, which will lock you out if applied. Choose another one!", $invalid)."<BR><BR>";
	    }
	}

	if (dmz_used()) {
	    my ($ok_ips, $nok_ips) = createIPS($par{'DISPLAY_DMZ_ADDRESS'}.'/'.$par{'DISPLAY_DMZ_NETMASK'}, $par{'DISPLAY_DMZ_ADDITIONAL'});
	    if ($nok_ips ne '') {
		foreach my $nokip (split(/,/, $nok_ips)) {
		    $err .= _('The DMZ IP address or network mask "%s" is not correct.', $nokip).'<BR>';
		}
	    } else {
		$session->{'DMZ_IPS'} = $ok_ips;
		
		foreach my $invalid (@{checkNetaddress($session->{'DMZ_IPS'})}) {
		    $err .= _("The DMZ IP address '%s' is the same as its network address, which is not allowed!", $invalid)."<BR><BR>";
		}
		foreach my $invalid (@{checkBroadcast($session->{'DMZ_IPS'})}) {
		    $err .= _("The DMZ IP address '%s' is the same as its broadcast address, which is not allowed!", $invalid)."<BR><BR>";
		}
		foreach my $invalid (@{checkInvalidMask($session->{'DMZ_IPS'})}) {
		    $err .= _("The network mask of the DMZ IP address '%s' addresses only 1 IP address, which will lock you out if applied. Choose another one!", $invalid)."<BR><BR>";
		}
	    }
	}
	if (lan2_used()) {
	    my ($ok_ips, $nok_ips) = createIPS($par{'DISPLAY_LAN2_ADDRESS'}.'/'.$par{'DISPLAY_LAN2_NETMASK'}, $par{'DISPLAY_LAN2_ADDITIONAL'});
	    if ($nok_ips ne '') {
		foreach my $nokip (split(/,/, $nok_ips)) {
		    $err .= _('The LAN2 IP address or network mask "%s" is not correct.', $nokip).'<BR>';
		}
	    } else {
		$session->{'LAN2_IPS'} = $ok_ips;
		
		foreach my $invalid (@{checkNetaddress($session->{'LAN2_IPS'})}) {
		    $err .= _("The LAN2 IP address '%s' is the same as its network address, which is not allowed!", $invalid)."<BR><BR>";
		}
		foreach my $invalid (@{checkBroadcast($session->{'LAN2_IPS'})}) {
		    $err .= _("The LAN2 IP address '%s' is the same as its broadcast address, which is not allowed!", $invalid)."<BR><BR>";
		}
		foreach my $invalid (@{checkInvalidMask($session->{'LAN2_IPS'})}) {
		    $err .= _("The network mask of the LAN2 IP address '%s' addresses only 1 IP address, which will lock you out if applied. Choose another one!", $invalid)."<BR><BR>";
		}
	    }
	}

	if ($err ne '') {
	    return $err;
	}


	# NEED TO BUILD A LOOP TO CROSS CHECK DYNAMIC ZONE DISTINCTION! - RAZWALL
	
	if (dmz_used()) {
	    if (network_overlap($session->{'LAN_IPS'}, $session->{'DMZ_IPS'})) {
		$err .= _('The LAN and DMZ networks are not distinct.').'<BR><BR>';
	    }
	}
	if (lan2_used()) {
	    if (network_overlap($session->{'LAN_IPS'}, $session->{'LAN2_IPS'})) {
		$err .= _('The LAN and LAN2 networks are not distinct.').'<BR><BR>';
		
	    }
	}
	if (lan2_used() && dmz_used()) {
	    if (network_overlap($session->{'DMZ_IPS'}, $session->{'LAN2_IPS'})) {
		$err .= _('The DMZ and LAN2 networks are not distinct.').'<BR><BR>';
		
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
    my $next_if = 1; # 0 == lan
    my $fixed = 0;

	
warn "WE ARE HERE!\n\n";
# MORE IDIOT CODE TOP REPLACE IN RAZWALL...

 #   my ($primary,$ip,$mask,$cidr) = getPrimaryIP($config{'LAN_IPS'});
 #   $config{'LAN_ADDRESS'} = $ip;
 #   $config{'LAN_NETMASK'} = $mask;
 #   $config{'LAN_CIDR'} = $cidr;
 #   ($config{'LAN_NETADDRESS'},) = ipv4_network($primary);
 #   $config{'LAN_BROADCAST'} = ipv4_broadcast($primary);

#    if (dmz_used()) {
#	my ($primary,$ip,$mask,$cidr) = getPrimaryIP($config{'DMZ_IPS'});
#	$config{'DMZ_ADDRESS'} = $ip;
#	$config{'DMZ_NETMASK'} = $mask;
#	$config{'DMZ_CIDR'} = $cidr;
#	($config{'DMZ_NETADDRESS'},) = ipv4_network($primary);
#	$config{'DMZ_BROADCAST'} = ipv4_broadcast($primary);
#    }
#    if (lan2_used()) {
#	my ($primary,$ip,$mask,$cidr) = getPrimaryIP($config{'LAN2_IPS'});
#	$config{'LAN2_ADDRESS'} = $ip;
#	$config{'LAN2_NETMASK'} = $mask;
#	$config{'LAN2_CIDR'} = $cidr;
#	($config{'LAN2_NETADDRESS'},) = ipv4_network($primary);
#	$config{'LAN2_BROADCAST'} = ipv4_broadcast($primary);
#    }
    return \%config;
}

sub apply() {
    satanize($session);
    if ($session->{'WAN_DEV'}) {
	disable_conflicting_uplinks($session->{'WAN_DEV'});
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
    set_wan_default("");

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
        # enable DHCP server on lan at the first netwizard
        $session->{'ENABLE_LAN'} = 'on';
    }

    my $hotspot_settings_hash = ();
    my $hotspot_settings = \%hotspot_settings_hash;
    readhash($hotspot_settings_file, $hotspot_settings);
    load_all_keys($session, \@hotspot_keys, $hotspot_settings, 0, 0);
    load_all_keys($settings, \@hotspot_keys, $hotspot_settings, 0, 0);

#    if (dmz_used()) {
#	$session->{'ZONES'} = 'DMZ';
#    }
#    if (lan2_used()) {
#	$session->{'ZONES'} = 'LAN2';
#    }
#    if (dmz_used() && lan2_used()) {
#	$session->{'ZONES'} = 'DMZ_LAN2';
#    }
#    if (! dmz_used() && ! lan2_used()) {
#	$session->{'ZONES'} = 'NONE';
#    }
#    $session->{'LAN_DEV'} = 'br0';
#    $session->{'DMZ_DEV'} = 'br1';
#    $session->{'LAN2_DEV'} = 'br2';
	@zones = get_zones;
	$zc=0 ;
	foreach $zone (@zones) {
		
		$session->{ $zone.'_DEV'} = 'br'.$zc;
	}
    load_wan('MAIN');
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
    $lever = lc($session->{'WAN_TYPE'});
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

    # Check if the hotspot is active and if a LAN2 zone is enabled.
    $tpl_ph->{'warning_message'} = '';

    if ($settings->{'HOTSPOT_ENABLED'} eq 'on') {
        #$session->{'HOTSPOT_ENABLED'} = $settings->{'HOTSPOT_ENABLED'};
        if ($par{'ZONES'} ne 'LAN2' && $par{'ZONES'} ne 'DMZ_LAN2') {
            #$session->{'HOTSPOT_ENABLED'} = 'off';
            $tpl_ph->{'warning_message'} = _('WARNING: no LAN2 zone selected; the hotspot will be turned off');
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
	my ($primary, $ip, $mask, $cidr) = getPrimaryIP($session->{'LAN_IPS'});
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
    init_wantools($session, $settings);
    init_ethconfig();

    load_values();
    state_machine();
    prepare_values();

	#RazWall — load dynamic zones and build a data structure for template
    my @zone_names = get_zones();
	#warn "DEBUG: zones found: ", join(", ", @zone_names), "\n";
    my @zone_list;
    foreach my $zone (@zone_names) {
		next if $zone eq 'LOCAL';
		
        my %info = ( name => $zone );
        open my $ZF, '<', "$swroot/zones/$zone"
          or warn "Unable to open zone file $zone: $!";
        while (<$ZF>) {
            chomp;
            next unless length;
            my ($k,$v) = split(/=/, $_, 2);
            $v =~ s/\r//g;
            $info{iface} = $v if $k eq 'ZIFACE';
            $info{name}  = $v if $k eq 'ZSTRING';
            $info{color} = $v if $k eq 'ZCOLOR';
            $info{type}  = $v if $k eq 'ZTYPE';
			$info{desc}  = $v if $k eq 'ZDESC';
			$info{address}  = $v if $k eq 'ZADDRESS';
			$info{netmask} = $v if $k eq 'ZNETMASK';
			$info{ips} = $v if $k eq 'ZADDITIONAL';
			$info{dhcp} = $v if $k eq 'ZDHCP';
        }
        close $ZF;
        push @zone_list, \%info;
    }

    # merge into your template values
    $values = hash_merge($values, { zones => \@zone_list });
	
    $values = hash_merge($values, satanize(prefix('NW_VAL_',$session)));
    $values = hash_merge($values, satanize(prefix('NW_VAL_',$tpl_ph)));

    $filename = 'netwiz'.$live_data->{'step'};
    if ($live_data->{'substep'} != 0) {
	$filename .= "_".$lever."_".$live_data->{'substep'};
    }

    my $content = get_template('/razwall/web/netwizard/' .$filename.'.tmpl', $values);
	#print "\%{$values}<br>\n";
    

	session_save($session_id, $session);
    my $header = '';

    if ($reload eq 'YES DO IT') {
	my ($primary,$ip,$mask,$cidr) = getPrimaryIP($session->{'LAN_IPS'});
        if ($pagename eq "firstwizard") {
	    my %wizardhash;
	    my $wizardfile = "/razwall/config/wizard/settings";
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
