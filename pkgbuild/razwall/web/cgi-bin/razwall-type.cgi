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


##############################################################################
# this file makes the wizard ipcop capable.
##############################################################################
use DBI;
use lib '/razwall/web/cgi-bin/';
require 'header.pl';
use eSession;
use Net::IPv4Addr qw (:all);

getcgihash(\%par);


# build system paths
$cgi_path = $1 if (($ENV{'SCRIPT_FILENAME'}||$0) =~ m/^(.*)(\\|\/)(.+?)$/);
$templates = $cgi_path . '/templates.pl';

%strings = (
  'nr_interfaces' => _('Number of interfaces'),
  'hardware_information' => _('Hardware information'),
  'nw_next' => _('Save >>>'),
  'nw_cancel' => _('<<< Cancel'),
 );
my %par;

#
# definitions
#
my $reload_from_wizard = '/usr/local/bin/restart_from_wizard';
my %producthash;
my $productfile = '/razwall/config/product/settings';
my %wizardhash;
my $wizardfile = '/razwall/config/wizard/settings';
#my %steps = ( 1 => _('Network Mode & Type'));
my $ifacesjson = '/razwall/cache/ethconfig/interfaces.json';
#my $stepnum = scalar(keys(%steps));
#my $reload = '';
#my $lever = '';
#my %tpl_ph_hash = ();
#my $tpl_ph = \%tpl_ph_hash;
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
#my $hotspot_settings_file = 'hotspot/settings'; # HOSTSPOT - NOT USED YET
my $zone_settings = "$swroot/zones/settings"; # RAZWALL ZONE SETTINGS
my $refresh = '45';

# firstwizard ?
#if ($0 =~ /step2\/*(netwiz|wizard).cgi/) {
#    $pagename="firstwizard";
#} else { 
#    $pagename="netwizard";
#}

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

#my @hotspot_keys=('HOTSPOT_ENABLED');

#my %type_config=( # NO LONGER NEEDED.. BUNCH OF IDIOTS!

my @dns_caption=(_('automatic'),
		 _('manual')
		 );


sub hash_merge($$) {
    my $first = shift;
    my $second = shift;

    foreach my $key (keys %$second) {
	$first->{$key} = $second->{$key};
    }

    return $first;
}

sub print_debug($) {
    my $msg = shift;

    return unless ($debug);
    print STDERR $msg;
}

sub init_ifacetools($$) {
    $session = shift;
    $par = shift;
    $bridgefiles = ${swroot}.'/ethernet/';
}

sub init_wantools($$) {
    $session = shift;
    $settings = shift;
    $uplinks = ${swroot}.'/uplinks/';
}

sub init_ethconfig() {
    load_ethconfig();
}

sub load_ethconfig($) {
    my $checklink = shift;
    my $mac="";
    my $desc="";
    my $businfo="";
    my $label="";
    my $device="";
    my $bonds = get_bonds(); #  NEED TO ADDRESS THIS IN THE FUTURE OF RAZWALL...
    my %businfosorted_hash = ();
    my $businfosorted = \%businfosorted_hash;
    my $i = 0;

    if (! -e $ifacesjson) {
		system("touch $ifacesjson");
		system("chmod 0777 $ifacesjson");
		system("perl /razwall/scripts/ethconfig.pl > $ifacesjson");
    }
    open(J, $ifacesjson);
    my $jsonobj = JSON::XS->new->utf8->decode(join('', <J>));
    close J;

    readhash($ethernet_settings_file, $ethernetconfig);

    foreach my $item (@$jsonobj) {
	$mac = $item->{'mac'};
	$desc = $item->{'name'};
	$label = $item->{'label'};
	$businfo = $item->{'businfo'};
	$device = $item->{'iface'};
	$driver = $item->{'driver'};

	my %recordhash = ();
	my $record = \%recordhash;
	$i++;
	$record->{'port'} = $i;
	$record->{'mac'} = $mac;
	$record->{'description'} = $desc;
	($record->{'shortdesc'}) = split(/ /, $desc);
	$record->{'description.orig'} = $record->{'description'};
	$record->{'shortdesc.orig'} = $record->{'shortdesc'};
	$record->{'portlabel'} = _('Interface %s', $record->{'port'});

	$record->{'label'} = $label;
	$record->{'device'} = $device;
	$record->{'businfo'} = $businfo;

	$record->{'bond'} = bond_of_if($bonds, $device);
	if ($record->{'bond'}) {
	    $record->{'description'} .= ' '. _('bonded in %s', $record->{'bond'});
	    $record->{'shortdesc'} .= ' '. _('bonded in %s', $record->{'bond'});
	    $record->{'portlabel'} = $record->{'shortdesc'};
	}

	$record->{'vlans'} = 0;
	$record->{'vid'} = 0;
	my $vlans = get_vlan_ids($device);
	if ($vlans) {
	    $record->{'vlans'} = $vlans;
	    $record->{'description'} .= ' '. _("with VLANs");
	    $record->{'shortdesc'} .= ' '. _("with VLANs");
	}

	$record->{'enabled'} = 1;
	if ($record->{'bond'} ne "") {
	    $record->{'enabled'} = 0;
	}
	$ethconfig->{$device} = $record;
	if ($businfo =~ /^\s*n\/a\s*$/) {
	    $businfosorted->{$businfo.$device} = $device;
	} else {
	    $businfosorted->{$businfo} = $device;
	}

	$record->{'zone'} = getzonebyinterface($device);
    }

    foreach my $bond (keys %$bonds) {
	my %recordhash = ();
	my $record = \%recordhash;
	my $bondedports = join(", ", getPortByDevice($bonds->{$bond}));
	$device = $bond;
	$record->{'description'} = _('Bond with ports %s', $bondedports);
	$record->{'description.orig'} = $record->{'description'};
	$record->{'shortdesc'} = _('Bond');
	$record->{'shortdesc.orig'} = $bond;
	$record->{'portlabel'} = _('Bond %s', $device);
	$record->{'label'} = "";
	$record->{'device'} = $device;
	$record->{'bondname'} = $device;
	$record->{'bonddevices'} = $bonds->{$device};
	$record->{'vlans'} = 0;
	$record->{'vid'} = 0;

	my $vlans = get_vlan_ids($device);
	if ($vlans) {
	    $record->{'vlans'} = $vlans;
	}
	$record->{'enabled'} = 1;
	$record->{'port'} = 0;
	$ethconfig->{$device} = $record;
	$businfosorted->{'00'.$device} = $device;
	$record->{'zone'} = getzonebyinterface($device);
    }

    my @mactable = ();
    my @description = ();
    my $i = 0;

    my @sorted = ();

    if ($ethernetconfig->{'FIXED_NICS'} eq 'yes') {
        # sorted by device name, but they has been presorted by businfotab
	@sorted = sort(keys(%$ethconfig));
	my $j = 0;
	foreach my $item (@sorted) {
	    if ($ethconfig->{$item}->{'device'} !~ /bond/) {
		$j++;
		$ethconfig->{$item}->{'port'} = $j;
	    }
	}
    } elsif ($ethernetconfig->{'FIXED_NICS_DEFINITION_FILE'} !~ /^$/) {
	my $ref = get_fixed_if_list($ethernetconfig->{'FIXED_NICS_DEFINITION_FILE'});
	@sorted = ();
	foreach my $bond (sort(keys(%$bonds))) {
	    push(@sorted, $bond);
	}
	foreach my $bond (@$ref) {
	    push(@sorted, $bond);
	}
	my $j = 0;
	foreach my $item (@sorted) {
	    next if (! $ethconfig->{$item});
	    if ($ethconfig->{$item}->{'device'} !~ /bond/) {
		$j++;
		$ethconfig->{$item}->{'port'} = $j;
	    }
	}
    } else {
        # sort by businfo
	my @orderby = ();
        if ($ethernetconfig->{'REVERSE_NICS'} eq 'yes') {
	    @orderby = sort{$b cmp $a} (keys(%$businfosorted));
        } else {
	    @orderby = sort(keys(%$businfosorted));
        }
	my $j = 0;
	foreach my $businfo (@orderby) {
	    my $item = $businfosorted->{$businfo};
	    if ($item->{'device'} !~ /bond/) {
		$j++;
		$item->{'port'} = $j;
	    }
	    push(@sorted, $item);
	}
    }

    # fix port numbers in bond since sorting changed them
    foreach my $bond (keys %$bonds) {
	my $bondedports = join(", ", getPortByDevice($bonds->{$bond}));
        $ethconfig->{$bond}->{'description'} = _('Bond with ports %s', $bondedports);
    }

    @sortedethconfig=();
    foreach my $item (@sorted) {
	next if (! $ethconfig->{$item});
	push(@sortedethconfig, $ethconfig->{$item});
	my $retarr = explode_vlans(\@sortedethconfig, $ethconfig->{$item});
	@sortedethconfig = @$retarr;
    }
    add_numerator(\@sortedethconfig);
    format_description(\@sortedethconfig, $checklink);
    return \@sortedethconfig;
}

sub get_bonds() { #  NEED TO ADDRESS THIS IN THE FUTURE OF RAZWALL...
    my %bonds = ();
    my $ret = \%bonds;
    foreach my $bondfile (`ls -1 $bondfiles 2>/dev/null`) {
	chomp($bondfile);
	next if ($bondfile !~ /(bond\d+)$/);
	my $bond = $1;
	$ret->{$bond} = get_zone_devices($bond);
    }
    return $ret;
}

sub bond_of_if($$) {
    my $bonds = shift;
    my $iff = shift;

    foreach my $bond (keys %$bonds) {
	my $iffarr = $bonds->{$bond};
	foreach my $bondiff (@$iffarr) {
	    return $bond if ($bondiff eq $iff);
	}
    }
    return "";
}

sub get_vlan_ids($) {
    my $device = shift;
    my %rethash = ();
    my $ret = \%rethash;

    return 0 if (! -e "/razwall/config/ethernet/vlan_${device}");
    open(F, "/razwall/config/ethernet/vlan_${device}") || return 0;
    foreach my $line (<F>) {
	chomp($line);
	next if ($line =~ /^\ *$/);
	my $vid = $line;
	my $data = create_vlan_data($vid, $device);
	$ret->{$data->{'device'}} = $data;
    }
    close(F);
    return 0 if (scalar(%rethash) == 0);
    return $ret;
}

sub explode_vlans($$) {
    my $eths = shift;
    my $item = shift;
    my @arr = @$eths;
    if ($item->{'vlans'} == 0) {
	return \@arr;
    }

    my $vlans = $item->{'vlans'};
    foreach my $vdevice (sort keys(%$vlans)) {
	my %newitemhash = ();
	my $newitem = \%newitemhash;
	my $vdata = $vlans->{$vdevice};
	$newitem->{'mac'} = $item->{'mac'};
	$newitem->{'description'} = _('VLAN %s on %s', $vdata->{'vid'}, $item->{'description.orig'});
	$newitem->{'shortdesc'} = _('VLAN %s on %s', $vdata->{'vid'}, $item->{'shortdesc.orig'});
	$newitem->{'portlabel'} = _('VLAN %s on %s', $vdata->{'vid'}, $item->{'portlabel'});
	$newitem->{'device'} = $vdevice;
	$newitem->{'physdev'} = $item->{'device'};
	$newitem->{'vid'} = $vdata->{'vid'};
	$newitem->{'businfo'} = $item->{'businfo'};
	if ($item->{'port'} > 0) {
	    $newitem->{'port'} = $item->{'port'}.'.'.$vdata->{'vid'};
	}
	$newitem->{'bondname'} = $item->{'bondname'};
	$newitem->{'zone'} = getzonebyinterface($newitem->{'device'});
	$newitem->{'parent'} = $item;
	push(@arr, $newitem);
    }
    return \@arr;
}

sub add_numerator($) {
    my $eths = shift;
    my $i = 0;
    foreach my $item (@$eths) {
	$item->{'index'} = $i;
	$i++;
    }
}

sub format_description($$) {
    my $eths = shift;
    my $checklink = shift;
    refreshLinkStatus();
    foreach my $item (@$eths) {
	my $device = $item->{'device'};

	# *** link check ***
	my $link = '';
	my $linkcaption = _('Link status n/a');
	my $linkicon = 'linkna';
	if ($checklink) {
	    if ($item->{'device'} !~ /bond/) {
		if ($item->{'vid'} != 0) {
		    $link = $item->{'parent'}->{'link'};
		} else {
		    $link = check_link($device);
		}
		if ($link eq 'LINK OK') {
		    $linkcaption = _('Link OK');
		    $linkicon = 'linkok';
		}
		if ($link eq 'NO LINK') {
		    $linkcaption = _('NO Link');
		    $linkicon = 'linknotok';
		}
	    }
	}

	# *** DESCRIPTION ***
	my $desc = $item->{'description'};
	my $shortdesc = $item->{'shortdesc'};
	my $mac = $item->{'mac'};
	if ($mac =~ /^$/) {
	    $mac = _('No MAC');
	}

	# *** INDEX ***
	my $port = $item->{'port'};
	if (! $port) {
	    $port = 'n/a';
	}

	$item->{'port'} = $port;
	$item->{'link'} = $link;
	$item->{'linkcaption'} = $linkcaption;
	$item->{'linkicon'} = $linkicon;
	$item->{'caption'} = $port.") $device: $desc - $mac [$linkcaption]";
	$item->{'label'} = $port.") $device: $desc [$linkcaption]";
	$item->{'shortlabel'} = $port.") $device: $shortdesc [$linkcaption]";
    }
}

sub refreshLinkStatus() {
    for my $line (`sudo /usr/sbin/ifplugstatus 2>/dev/null`) {
	my ($iff, $status) = split(/:/, $line);
	if ($line =~ /link beat detected$/) {
	    $linkStatusCache{$iff} = "LINK OK";
	    next;
	}
	if ($line =~ /unplugged$/) {
	    $linkStatusCache{$iff} = "NO LINK";
	    next;
	}
	$linkStatusCache{$iff} = "LINK STATUS N/A";
    }
}

sub load_all_keys($$$$$) {
    my $session = shift;
    my $keys_ref = shift;
    my $value_base = shift;
    my $default_base = shift;
    my $override = shift;
    my @keys = @$keys_ref;

    foreach (@keys) {
	$key = $_;
	load_to_session($session, $key, $value_base, $default_base, $override);
    }
}

sub load_to_session($$$$$) {
    my $session = shift;
    my $key = shift;
    my $value_base = shift;
    my $default_base = shift;
    my $override = shift;

    if (($override == 0) && exists($session->{$key})) {
	return;
    }

    if (exists($value_base->{$key})) {
	$session->{$key} = $value_base->{$key};
	return;
    }

    if ($default_base == 0) {
	return;
    }
    if (exists($default_base->{$key})) {
	$session->{$key} = $default_base->{$key};
	return;
    }
}

sub load_wan($) {
    my $uplink = shift;
    $uplink = lc($uplink);
    return if ($uplink =~ /^$/);
    my %wan_settings_hash = ();
    my $wan_settings = \%wan_settings_hash;
    readhash($uplinks.$uplink.'/settings', $wan_settings);
    my @keys = keys(%$wan_settings);
    load_all_keys($session, \@keys, $wan_settings, 0, 0);
    load_all_keys($settings, \@keys, $wan_settings, 0, 0);
}

sub get_if_number() {

	if (! -e $ifacesjson) {
	system("touch $ifacesjson");
	system("chmod 0777 $ifacesjson");
	system("perl /razwall/scripts/ethconfig.pl > $ifacesjson");
    }
    open(J, $ifacesjson);
    my $jsonobj = JSON::XS->new->utf8->decode(join('', <J>));
    close J;

	return scalar @{ $jsonobj };
}

sub prefix($$) {
    my $prefix = shift;
    my $ref = shift;
    my %ret_hash = ();
    my $ret = \%ret_hash;

    foreach $key (%$ref) {
	$ret->{$prefix.$key} = $ref->{$key};
    }

    return $ret;
}

sub blank_config() {
    foreach my $zone (@zones) {
	$session->{$zone.'_DEVICES'} = "";
    }
}

sub load_ifacesconfig() {
    blank_config();
    my $validzones=validzones();
    foreach my $zone (@$validzones) {
	my $devicelist = 0;
	if ($zone eq 'WAN') {
	    my %mainuplink = ();
	    &readhash("${swroot}/uplinks/main/settings", \%mainuplink);
            my @devarr = ();
            $devicelist = \@devarr;
            push(@devarr, $mainuplink{'WAN_DEV'});
	} else {
	    $devicelist = get_zone_devices($session->{$zone.'_DEV'});
	}

	foreach my $dev (@$devicelist) {
	    $session->{$zone.'_DEVICES'} .= $dev.'|';
	}
    }
}

sub load_ifaces() {
    load_ifacesconfig();
    my $validzones=validzones();
    my %wizardhash;
    &readhash("${swroot}/wizard/settings", \%wizardhash);
    if (($wizardhash{'WIZARD_ENABLED'} eq 'on') and
	($wizardhash{'WIZARD_STATE'} eq 'netwizard')) {
	#this is during first netwizard, where we want default configuration
	setdefaultifaces();
	return;
    }
    foreach my $zone (@$validzones) {
	if (($session->{$zone.'_DEVICES'}) && ($zone ne 'LAN')) {
	    return;
	}
    }
    setdefaultifaces();
}

sub setdefaultifaces() { # SMH... WHY?! ... REPLACE WITH RAZWALL DYNAMIC ZONE IFACE ASSIGNMENT
    my $devices = listdevices(1);
    my $i = 0;
    foreach my $item (@$devices) {
	my $dev = $item->{"device"};
	if ($i==0) {
	    $session->{"LAN_DEVICES"}=$dev;
	}
	if ($i==1) {
	    if (dmz_used()) {
		$session->{"DMZ_DEVICES"}=$dev;
	    }
	}
	if ($i==2) {
	    if (lan2_used()) {
		$session->{"LAN2_DEVICES"}=$dev;
	    }
	}
	if ($i==3) {
	    if (!is_modem()) {
		$session->{"WAN_DEVICES"}=$dev;
	    }
	}
	if ($i>=4) {
	    $session->{"LAN_DEVICES"}.='|'.$dev;
	}
	$i++;
    }
}

sub listdevices($) {
    my $showlink = shift;
    if ($#sortedethconfig <= 0) {
	load_ethconfig($showlink)
    }
    return \@sortedethconfig;
}

sub check_link($) {
    my $iface = shift;
    if ($linkStatusCache{$iface} =~ /^$/) {
	refreshLinkStatus();
    }
    my $status = $linkStatusCache{$iface};
    if ($status =~ /^$/) {
	return "LINK STATUS N/A";
    }
    return $status;
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
sub checkpar2session  {
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
    #if ($session->{'HOTSPOT_ENABLED'} == 'off') { writehash($hotspot_settings_file, select_from_hash(\@hotspot_keys, $session)); }
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

# NEED TO MAKE SURE WE BUILD BRIDGES FOR EACH LAN CREATED:
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

if (defined($par{'cancel'})) {
    print "Status: 302 Moved\n";
    print "Location: https://".$ENV{'SERVER_ADDR'}.":10443/cgi-bin/dashboard.cgi\n\n";
    exit;
}

# Check that templates file can be loaded..
&loadTemplates;

showhttpheaders();

&getTemplate('openHeader');
&printTemplate;

# EXTRA HEADER DATA HERE
print qq~
<!-- BEGIN NETOWRK CUSTOM HEADER -->

<link rel="stylesheet" type="text/css" href="/css/uplinkinformationcontent.css" media="all" />
<link rel="stylesheet" type="text/css" href="/css/autorefreshwrapper.css" media="all" />
<style type="text/css">
.current-zones .zones-header,
.current-zones .zones-row {
  display: flex;
  align-items: center;
  padding: 0.5em 0;
}
.current-zones .zones-header {
  font-weight: bold;
  border-bottom: 1px solid #444;
  margin-bottom: 0.5em;
}
.zone-col { width: 15%; }
.desc-col { width: 45%; }
.type-col { width: 20%; }
.iface-col { width: 20%; }

.new-zones .zone-input-row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5em;
  margin-bottom: 0.5em;
}
.new-zones .zone-input-row input[type="color"] {
  width: 35px;
  height: 35px;
  padding: 0;
  border: none;
}
.add-zone {
  margin-bottom: 1em;
}
.form-actions {
  display: flex;
  gap: 1em;
  margin-top: 1em;
}
.error-message .error { color: red; }
</style>

<script type="text/javascript" src="/js/systeminformationplugin.js"></script>
<script type="text/javascript" src="/js/uplinkinformationplugin.js"></script>
<script type="text/javascript" src="/js/autorefreshwrapper.js"></script>
<script language="JavaScript" src="/js/services_selector.js"></script>

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
	<script type="text/javascript">
	  // Change handlers for list items
	  function changeNetworkType() {
		const input = this.querySelector('input');
		if (!input) return;
		input.checked = true;
		input.dispatchEvent(new Event('change', { bubbles: true }));
	  }

	  function changeWanType() {
		const input = this.querySelector('input');
		if (!input) return;
		input.checked = true;
		input.dispatchEvent(new Event('change', { bubbles: true }));
	  }

	  // Show/hide WAN type and description panels based on selected network type
	  function toggleNetworkTypes() {
		const selected = document.querySelector('input[name="NETWORK_TYPE"]:checked');
		if (!selected) return;
		const networkType = selected.value;

		document.querySelectorAll('div.wan_types').forEach(el => {
		  el.style.display = el.classList.contains(networkType) ? '' : 'none';
		});
		document.querySelectorAll('div.network_description').forEach(el => {
		  el.style.display = el.classList.contains(networkType) ? '' : 'none';
		});
	  }

	  // On hover, show only the description for the hovered item
	  function toggleNetworkDescription() {
		const input = this.querySelector('input');
		if (!input) return;
		const networkType = input.value;

		document.querySelectorAll('div.network_description').forEach(el => {
		  el.style.display = el.classList.contains(networkType) ? '' : 'none';
		});
	  }

	  // Initialize everything once the DOM is ready
	  document.addEventListener('DOMContentLoaded', () => {
		// Initial toggle
		toggleNetworkTypes();

		// Wire up inputs
		document.querySelectorAll('input[name="NETWORK_TYPE"]').forEach(input => {
		  input.addEventListener('change', toggleNetworkTypes);
		  const parent = input.parentElement;
		  parent.addEventListener('mouseenter', toggleNetworkDescription);
		  parent.addEventListener('mouseleave', toggleNetworkTypes);
		});

		// Wire up list-item clicks
		document.querySelectorAll('li.network_type').forEach(li => {
		  li.addEventListener('click', changeNetworkType);
		});
		document.querySelectorAll('li.wan_type').forEach(li => {
		  li.addEventListener('click', changeWanType);
		});
	  });
</script>
<!-- END NETWORK CUSTOM HEADER-->
~;

&getTemplate('closeHeader');
&printTemplate;

#my ($reload, $extraheader, $content, $rebuildcert) = print_template($swroot);

#print $content;
my @wan_types = (
    {'
		name' => 'DHCP',
		'caption' => _('Ethernet DHCP'),
		'type' => 'ROUTED'
	},
    {
		'name' => 'STATIC',
		'caption' => _('Ethernet static'),
		'type' => 'ROUTED'
	},
    {
		'name' => 'MODEM',
		'caption' => _('Mobile Broadband (4G/5G)'),
		'type' => 'ROUTED'
	},
    {
		'name' => 'PPPOE',
		'caption' => _('PPPoE'),
		'type' => 'ROUTED'
	},
    {
		'name' => 'PPTP',
		'caption' => _('PPTP'),
		'type' => 'ROUTED'
	},
    {
		'name' => 'ADSL',
		'caption' => _('ADSL modem'),
		'type' => 'ROUTED'
	},
    {
		'name' => 'ISDN',
		'caption' => _('ISDN modem'),
		'type' => 'ROUTED'
	},
    {
		'name' => 'ANALOG',
		'caption' => _('ANALOG modem'),
		'type' => 'ROUTED'
	},
    {
		'name' => 'NONE',
		'caption' => _('Gateway'),
		'type' => 'NOUPLINK'
	},
    {
		'name' => 'STEALTH',
		'caption' => _('Stealth'),
		'type' => 'BRIDGED'
	}
);

@wan_network_types = (
    {
		'name' => 'ROUTED',
		'caption' => _("Routed"),
		'title' => _("Uplink type (<span style=\"color: red;\">WAN</span> zone)"),
		'description' => _("This is the standard operating mode. Uplinks of the following types can be configured here: %s")
	},
    {
		'name' => 'BRIDGED',
		'caption' => _("Bridged"),
		'title' => "",
		'description' => _("In this operating mode the appliance acts transparently without the user noticing or needing to change an existing network infrastructure.")
	},
    {
		'name' => 'NOUPLINK',
		'caption' => _("No uplink"),
		'title' => "",
		'description' => _("In this operating mode the appliance is part of the local network but does not act as a gateway. Clients like webbrowsers and email clients will have to address the appliance directly. This was previously named Gateway mode.")
	},
);

# if($err_msg) { &getTemplate('netwiz1_error');... &doSub('ERROR_MESSAGE', $err_msg); @ERROR=&printTemplate; }

my @NW_LOOP1;
foreach $key (@wan_network_types) {
	&getTemplate('netwiz1_loop1'); # [!NETNAME!] [!NETSELECTED!] [!NETCAPTION!]
	&doSub('NETNAME', $key->{'name'});
	#&doSub('NETSELECTED', $key{''});
	&doSub('NETCAPTION', $key->{'caption'});
	push @NW_LOOP1, $_;
}

my @NW_LOOP2;
foreach $key (@wan_network_types) {
	&getTemplate('netwiz1_loop2'); # [!NETNAME!] [!NETCAPTION!] [!NETDESC!]
	&doSub('NETNAME', $key->{'name'});;
	&doSub('NETCAPTION', $key->{'caption'});
	&doSub('NETDESC', $key->{'description'});
	push @NW_LOOP2, $_;
}



&getTemplate('netwiz1');
	#&doSub('ERROR_MESSAGE', @ERROR);
	&doSub('TITLE','Network Mode & Type');
	&doSub('MODE_LEGEND','Network modes');
	&doSub('NETLOOP1', join('',@NW_LOOP1));
	&doSub('NETLOOP2', join('',@NW_LOOP2));
&printTemplate;

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

&getTemplate('footer');
&printTemplate;


if ($reload eq 'YES DO IT') {

    my $options = '';
    if ($rebuildcert) {
	$options .= 'REBUILDCERT';
    }

    if ( -x $reload_from_wizard) {
	`$reload_from_wizard $options &`;
    }
}
1;
