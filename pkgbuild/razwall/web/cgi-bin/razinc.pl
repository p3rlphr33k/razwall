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
 # COMBINED THESE INTO A SINGLE RESOURCE FILE: endianinc.pl, ifacetools.pl, netwizard_tools.pl, ethconfig.pl

#return 1;


require 'header.pl';

my $register_status_hash;
my $mactabfile = '/razwall/config/ethernet/mactab';
my $bondfiles = '/razwall/config/ethernet/bond*';
my $ifacesjson = '/razwall/cache/ethconfig/interfaces.json';
my $ethernet_settings_file = '/razwall/config/ethernet/settings';
my $ips_settings_file = '/razwall/defaults/efw/snort/default/settings';
my $session = 0;
my %ifaces = {};
my @validifaces= qw 'eth vlan';
my $bridgefiles = 'ethernet/';
my $par = 0;

my %ethconfighash=();
my $ethconfig=\%ethconfighash;
my %ethernethash=();
my $ethernetconfig=\%ethernethash;
my @sortedethconfig = ();
my %linkStatusCache = {};

use JSON::XS;
use Net::IPv4Addr qw (:all);

##### NETWIZARD TOOLS:

sub print_debug($) {
    my $msg = shift;

    return unless ($debug);
    print STDERR $msg;
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

sub hash_merge($$) {
    my $first = shift;
    my $second = shift;

    foreach my $key (keys %$second) {
	$first->{$key} = $second->{$key};
    }

    return $first;
}

sub select_from_hash($$) {
    my $ref = shift;
    my $session = shift;

    my @keys = @$ref;
    my %hash;

    foreach my $key (@keys) {
	$hash{$key} = $session->{$key};
    }
    return \%hash;
}

sub sanitize_ip {
    my $ip = shift;
    if ($ip =~ /^\d+\.\d+\.\d+\.\d+$/) {
	return $ip;
    }
    return '';
}

# check if this is a ordinary ip/mask pair.
sub check_ip ($$) {

    my $ip = shift;
    my $mask = shift;

    $ip   = sanitize_ip($ip);
    $mask = sanitize_ip($mask);

    $iptmp = eval { ipv4_parse($ip, $mask) };
    print_debug($iptmp);
    if (! defined($iptmp)) {
	return (0);
    }

    return (1, $ip, $mask);
}

sub get_pos($$) {
    my $ref = shift;
    my $search = shift;
    my @arr = @$ref;
    my $counter = 0;
    foreach $item (@arr) {
	if ($item eq $search) {
	    return $counter;
	}
	$counter++;
    }
    return undef;
}

# loads all values iedntified by the keys from the value_base into the session.
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


# loads one value identified by the key from the value_base into the session, if
# it does not already exist.
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
##### IFACETOOLS:
sub validzones() {
    my @ret = ();

    push(@ret, 'LAN');
    if (dmz_used()) {
	push(@ret, 'DMZ');
    }
    if (lan2_used()) {
	push(@ret, 'LAN2');
    }
    if (!is_modem()) {
	push(@ret, 'WAN');
    }

    return \@ret;
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

sub setdefaultifaces() {
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

sub ifisinzone($$) {
    my $conf=shift;
    my $dev=shift;
    my $search=$conf.'|';
    if ($search =~ /$dev\|/) {
	return $dev;
    }
    return "";
}

sub getzonebyiface($) {
    my $dev = shift;

    my $validzones=validzones();
    foreach my $zone (@$validzones) {
	if (ifisinzone($session->{$zone.'_DEVICES'}, $dev) ne "") {
	    return $zone;
	}
    }
    return "";
}

sub ifacesusedbyzone($$) {
    my $devs = shift;
    my $zone = shift;

    return 0 if (! $session->{$zone.'_DEVICES'});

    foreach my $dev (split(/\|/, $devs)) {
	chomp($dev);
	next if ($dev =~ /^$/);
	my $retdev=ifisinzone($session->{$zone.'_DEVICES'}, $dev);
	return $retdev if ($retdev ne "");
    }
    return 0;
}

sub init_ifacetools($$) {
    $session = shift;
    $par = shift;
    $bridgefiles = ${swroot}.'/ethernet/';
}

sub get_if_number() {
    if ($session->{'IF_COUNT'}) {
	return $session->{'IF_COUNT'};
    }
    my ($devices) = list_devices_description(3, -1, 0);
    my @devarr = @$devices;
    $session->{'IF_COUNT'} = $#devarr + 1;
    return $session->{'IF_COUNT'};
}

sub pick_device($) {
    my $devices=shift;
    my @arr = split(/\|/, $devices);
    return $arr[0];
}

sub isvalidzone($) {
    my $zone = shift;
    my $validzones=validzones();
    if (defined(get_pos($validzones, $zone))) {
	return 1;
    }
    return 0;
}

sub get_iface_by_name($) {
    my $name = shift;
    my $devices = listdevices(1);
    foreach my $dev (@$devices) {
	if ($dev->{'device'} eq $name) {
	    return $dev
	}
    }
    return 0;
}

sub disable_conflicting_uplinks($) {
    my $device = shift;
    my $uplinks = get_uplink_by_device($device);
    foreach my $ul (@$uplinks) {
	if (($ul !~ /^$/) && ($ul ne 'main')) {
	    disable_uplink($ul);
	}
    }
}

sub write_ifaces($$) {
    my $file = shift;
    my $selecteddevices = shift;

    my %devices = ();

    foreach my $dev (split(/\|/, $selecteddevices)) {
	next if $dev =~ /^$/;
	my $device = get_iface_by_name($dev);
	next if ($device eq 0);
	my $bond = $device->{'bond'};
	if ($bond =~ /^$/) {
	    $devices{$dev} = 1;
	}
	disable_conflicting_uplinks($dev);
    }

    if (!open(F, ">$file")) {
	warn("Could not open '$file' because $!");
	return;
    }
    print F join("\n", keys(%devices));
    print F "\n";
    close(F);
}

sub write_bridges() {
    foreach my $zone (@zones) {
	next if ($zone eq "WAN");
	my $devices = "";
	if (isvalidzone($zone)) {
	    $devices = $session->{$zone.'_DEVICES'};
	}
	my $ifacename=$session->{$zone.'_DEV'};
	next if ($ifacename =~ /^$/);
	write_ifaces($bridgefiles.$ifacename, $devices);
    }
}

sub create_ifaces_list($) {
    my $zone = shift;

    my @prof = ();
    my $index = 0;

    my ($devices) = list_devices_description(3, -1, 1);

    foreach my $item (@$devices) {
	my $assignedzone = getzonebyiface($item->{'device'});
	my $selected = ($zone eq $assignedzone);
	my $disabled = 0;
	my $hide = 0;
	if ($zone eq 'WAN') {
	    if (! $selected && $assignedzone) {
		$hide = 1;
		$disabled = 1;
	    }
	}
	if (($assignedzone eq '') && ($item->{'zone'} eq 'WAN')) {
	    $assignedzone = 'WAN';
	}

	my %hash = (
	    DEV_LOOP_INDEX => $index,
	    DEV_LOOP_NAME => $item->{'index'},
	    DEV_LOOP_PORT => $item->{'port'},
	    DEV_LOOP_DESCRIPTION => $item->{'description'},
	    DEV_LOOP_SHORT_DESC => $item->{'shortdesc'},
            DEV_LOOP_MAC => $item->{'mac'},
            DEV_LOOP_LINK => $item->{'link'},
            DEV_LOOP_LINKCAPTION => $item->{'linkcaption'},
            DEV_LOOP_LINKICON => $item->{'linkicon'},
            DEV_LOOP_BGCOLOR => (($index % 2) ? 'even' : 'odd'),
	    DEV_LOOP_SELECTED => ($selected ? 'selected' : ''),
	    DEV_LOOP_CHECKED => ($selected ? 'checked' : ''),
            DEV_LOOP_ZONECOLOR => $zonecolors{$assignedzone},
            DEV_LOOP_ZONE => $assignedzone,
            DEV_LOOP_DISABLED => ($disabled ? 'disabled' : ''),
            DEV_LOOP_HIDE => ($hide ? 'hide' : ''),
            DEV_LOOP_DEVICE => $item->{'device'},
	    );
	push(@prof, \%hash);

	$index++;
    }

    return \@prof;
}

sub check_iface_free($$) {
    my $devices = shift;
    my $zone = shift;
    my $err = "";

    if ($zone eq 'LAN') {
	return $err;
    }
    
    my $landev = ifacesusedbyzone($devices, 'LAN');
    if ($landev) {
	$err .= $landev.' '._('interface already assigned to zone %s', _('LAN')).'<BR>';
    }
    if ($zone eq 'DMZ') {
	return $err;
    }

    if (dmz_used()) {
	my $dmzdev = ifacesusedbyzone($devices, 'DMZ');
	if ($dmzdev) {
	    $err .= $dmzdev.' '._('interface already assigned to zone %s', _('DMZ')).'<BR>';
	}
    }
    if ($zone eq 'LAN2') {
	return $err;
    }

    if (lan2_used()) {
	my $lan2dev = ifacesusedbyzone($devices, 'LAN2');
	if ($lan2dev) {
	    $err .= $lan2dev.' '._('interface already assigned to zone %s', ('LAN2')).'<BR>';
	}
    }

    return $err;
}

# checks if there are overlappings in the address spaces.
sub network_overlap($$) {
    my $subnetlist1 = shift;
    my $subnetlist2 = shift;

    foreach my $subnet1 (split(/,/, $subnetlist1)) {
	foreach my $subnet2 (split(/,/, $subnetlist2)) {
	    if (ipv4_in_network($subnet1, $subnet2)) {
		return 1;
	    }
	    if (ipv4_in_network($subnet2, $subnet1)) {
		return 1;
	    }
	}
    }
    return 0;
}

# store the ip/mask pair into session if it is an ordinary ip/mask pair.
sub store_ip($$) {
    my $_ip = shift;
    my $_mask = shift;
    my ($ret, $ip, $mask);

    ($ret, $ip, $mask) = check_ip($par->{$_ip}, $par->{$_mask});
    if (! $ret) {
	return 0;
    }

    $session->{$_ip} = $ip;
    $session->{$_mask} = $mask;
    return 1;
}

# picks the primary ip address and returns it in cidr and bits notation
sub getPrimaryIP($) {
    my $subnets = shift;
    my @ips = split(/,/, $subnets);
    my $primary = $ips[0];
    return '' if ($primary eq '');
    my ($ip, $cidr) = ipv4_parse($primary);
    my $mask = ipv4_cidr2msk($cidr);
    return ($primary, $ip, $mask, $cidr);
}

sub getAdditionalIPs($) {
    my $subnets = shift;
    my @ips = split(/,/, $subnets);
    shift(@ips);
    return join(",", @ips);
}

sub checkIPs($$) {
    my $ip = shift;
    my $maxcidr = shift;
    my @ips = split(/[\r\n,]/, $ip);
    my @ok = ();
    my @nok = ();

    foreach my $net (@ips) {
	next if ($net =~ /^\s*$/);
	my $ok = 0;
	my $checknet = $net;
	$checknet .= '/32' if ($checknet !~ /\//);
	eval {
	    my ($ip, $cidr) = ipv4_parse($checknet);
	    if ($cidr > 0 and $cidr < $maxcidr) {
		push(@ok, "$ip/$cidr");
		$ok = 1;
	    }
	};
	if (! $ok) {
	    push(@nok, $net);
	}
    }
    return (join(",", @ok), join(",", @nok));
}

sub createIPS($$) {
    my $primary = shift;
    my $additional = shift;
    return checkIPs($primary.",".$additional, 32);
}

sub checkNetaddress($) {
    my $subnets = shift;

    my @ret = ();
    foreach my $net (split(/,/, $subnets)) {
	my ($netaddr,) = ipv4_network($net);
	my ($ip,) = ipv4_parse($net);

	if ($netaddr eq $ip) {
	    push(@ret, $net);
	}
    }
    return \@ret;
}

sub checkBroadcast($) {
    my $subnets = shift;

    my @ret = ();
    foreach my $net (split(/,/, $subnets)) {
	my ($bcast,) = ipv4_broadcast($net);
	my ($ip,) = ipv4_parse($net);

	if ($bcast eq $ip) {
	    push(@ret, $net);
	}
    }
    return \@ret;
}

sub checkInvalidMask($) {
    my $subnets = shift;

    my @ret = ();
    foreach my $net (split(/,/, $subnets)) {
	my ($ip,$mask) = ipv4_parse($net);

	if ($mask eq '255.255.255.255') {
	    push(@ret, $net);
	}
    }
    return \@ret;
}

sub loadNetmasks($) {
    my $selected = shift;
    my @arr = ();

    if ($selected eq '') {
	$selected = '24';
    }

    for (my $i=0; $i<=32; $i++) {
	my $bits = ipv4_cidr2msk($i);
	my $caption = "/$i - $bits";
	my %hash = (
		    'MASK_LOOP_INDEX'    => $i,
		    'MASK_LOOP_VALUE'    => $i,
		    'MASK_LOOP_CAPTION'  => $caption,
		    'MASK_LOOP_SELECTED' => ($selected eq $i ? 'selected':'')
		    );
	push(@arr, \%hash);
    }
    return \@arr;
}

sub is_modem {
    if ($session->{'CONFIG_TYPE'} =~ /^[0145]$/) {
	return 1;
    }
    return 0;
}

sub dmz_used () {
    if ($session->{'CONFIG_TYPE'} =~ /^[1357]$/) {
	return 1;
    }
    return 0;
}

sub lan2_used () {
    if ($session->{'CONFIG_TYPE'} =~ /^[4567]$/) {
	return 1;
    }
    return 0;
}

sub replace_primary_ip($$) {
    my $ips = shift;
    my $primary = shift;

    $ips =~ s/^[^,]+,/$primary,/;
    if ($ips =~ /^$/) {
	$ips = $primary;
    }
    return $ips;
}

##### ETHCONFIG:
sub init_ethconfig() {
#    load_ethconfig();
}

sub getifbynum($) {
    my $search = shift;
    my $devs = listdevices(0);
    return @$devs[$search];
}

sub getifbydevice($) {
    my $search = shift;
    return $ethconfig->{$search};
}

sub ifnum2device($) {
    my $ifnumbers = shift;
    my $ret = "";
    foreach my $item (split(/\|/, $ifnumbers)) {
	next if ($item =~ /^$/);
	my $devinfo = getifbynum($item);
	next if (!$devinfo);
	$ret.=$devinfo->{'device'}.'|';
    }
    return $ret;
}

sub get_system_vlans() {
    my %rethash = ();
    my $ret = \%rethash;
    my $vlanfile = '/proc/net/vlan/config';

    foreach my $line (`sudo cat $vlanfile`) {
	next if ($line !~ /^eth|bond/);
	my ($dev, $vid, $phys) = split(/\ *\|\ */, $line);
	chomp($dev);
	chomp($vid);
	chomp($phys);

	if (! $ret->{$phys}) {
	    my %subhash = ();
	    $ret->{$phys} = \%subhash;
	}
	$ret->{$phys}->{$vid} = $dev;
    }

    return $ret;
}

sub create_vlan_data($$) {
    my $vid = shift;
    my $iface = shift;

    my %vlanrhash = ();
    my $vlanr = \%vlanrhash;
    $vlanr->{'vid'} = $vid;
    $vlanr->{'device'} = "$iface.$vid";
    $vlanr->{'physdev'} = "$iface";
    $vlanr->{'priority'} = "";
    return $vlanr;
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

sub get_bonds() {
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

sub getPortByDevice($) {
    my $iffref = shift;
    my @ret = ();
    foreach my $iff (@$iffref) {
	push(@ret, $ethconfig->{$iff}->{'port'});
    }
    return @ret;
}

sub get_fixed_if_list($) {
    my $filename = shift;
    my @arr;
    my $ret = \@arr;

    if (! open(FD, $filename)) {
	return $ret;
    }
    foreach my $line (<FD>) {
	chomp($line);
	next if ($line eq '');
	push(@arr, $line);
    }
    close(FD);
    return $ret;
}

sub load_ethconfig($) {
    my $checklink = shift;
    my $mac="";
    my $desc="";
    my $businfo="";
    my $label="";
    my $device="";
    my $bonds = get_bonds();
    my %businfosorted_hash = ();
    my $businfosorted = \%businfosorted_hash;
    my $i = 0;

    if (! -e $ifacesjson) {
	#open(TMP, "> /razwall/web/cgi-bin/temp.txt") or die $!;
	#print TMP "$ifacesjson";
	#close(TMP);
	
	system("perl /razwall/scripts/ethconfig.pl --json --output $ifacesjson");
    }
    open(J, $ifacesjson);
    my $jsonobj = JSON::XS->new->utf8->decode (join('', <J>));
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

sub listdevices($) {
    my $showlink = shift;
    if ($#sortedethconfig <= 0) {
	load_ethconfig($showlink)
    }
    return \@sortedethconfig;
}

sub add_numerator($) {
    my $eths = shift;
    my $i = 0;
    foreach my $item (@$eths) {
	$item->{'index'} = $i;
	$i++;
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

sub list_devices_description($$$) {
    my $layer = shift;
    my $showzones = shift;
    my $showlink = shift;
    # layer:
    # 1: bond selector  (on top of which can be done ALL of those: bonding, vlan tagging, bridging, ethernet)
    # 2: vlan selector  (on top of which can be done ALL of those: vlan tagging, bridging, ethernet)
    # 3: ip assigning   (on top of which can be done ALL of those: bridging, ethernet)
    # 99: all devices
    #
    # negative means display only that type of devices. (-1 = only bonds, -2 = only vlans, -3 = only assignable)
    #
    # zones:
    # combinations of values: NONE, LAN, LAN2, DMZ, WAN
    #
    # showlink:
    # decides whether to check if the link of the device is present or not.
    # Note that this value may be cached from earlier load_ethconfig() calls

    my $devlist = listdevices($showlink);
    my @ret = ();
    my %rethash = ();

    foreach my $item (@$devlist) {

	if ($layer > 0) {
	    # *** hide because of level? ***
	    if ($layer < 99) {
		# hide devices which are part of a bond
		next if ($item->{'bond'});
	    }
	    if ($layer <= 3) {
		# hide devices which have vlans on top of them
		# exception: a device can have multiple vlans therefore don't
		#            hide them in layer which will be used for vlan
		#            tagging selection.
		if ($layer != 2) {
		    next if ($item->{'vlans'});
		}
	    }
	    if ($layer <= 2) {
		# hide virtual vlan devices
		next if ($item->{'vid'} != 0);
	    }
	    if ($layer <= 1) {
		# hide bonding devices
		next if ($item->{'bonddevices'});
	    }
	} else {
	    if ($layer == -1) {
		next if (! $item->{'bonddevices'});
	    }
	    if ($layer == -2) {
		next if ($item->{'vid'} == 0);
	    }
	}

	# *** hide because of assigned to zone? ***
	my $device = $item->{'device'};
	my $zone = $item->{'zone'};
	if ($showzones ne -1) {
	    if ($zone =~ /^$/) {
		$zone = 'NONE';
	    }
	    next if ($showzones !~ /$zone/);
	}

	push(@ret, $item);
	$rethash{$device} = $item;
    }
    return (\@ret, \%rethash);
}

sub has_ips() {
    return (-f $ips_settings_file);
}


##### RAZINC: (previously endianinc)

# -----------------------------------------------------------
# $hashref = readconf("fname"):
#    returns a hashref with the key/val pairs defined
#    in the properties-style configuration file "fname"
# -----------------------------------------------------------
sub readconf {
  my $fname = shift;
  my $line;
  my %conf;
  open(IN, $fname) or die();
  while ($line = <IN>) {
    next if ($line =~ /^\s*$/ or $line =~ /^\s*#/);
    if ($line =~ /^\s*(.+)\s*=\s*(.+)/) {
      $conf{$1} = $2;
    }
  }
  close(IN);
  return \%conf;
}


# -----------------------------------------------------------
# $out = filter($in)
# -----------------------------------------------------------
sub filter {
  my $in = shift;
  $in =~ s/=/-/g;  # used in conf files
  $in =~ s/"/''/g;  # used in HTML fields
  return $in;
}

# -----------------------------------------------------------
# return 1 if $value = on or 1
# -----------------------------------------------------------
sub is_on($) {
        my $value = shift;
        if ( ( $value == 1 ) || ( $value eq 'on' ) ) {
                return 1;
        }
        else {
                return 0;
        }
}

# ----------------------------------------------------------
# return checked='checked' if $value is on (for checkboxes)
# ----------------------------------------------------------
sub check($) {
        my $value = shift;
        if ( is_on($value) ) {
                return "checked='checked'";
        }
        else {
                return "";
        }
}

# ----------------------------------------------------------
# check if $value is a hostname
# ----------------------------------------------------------
sub is_hostname($) {
        my $hostname = shift;
        if ( $hostname =~ m/^[a-zA-Z._0-9\-]*$/ ) {
                return 1;
        }
        $errormessage = _('Invalid hostname.');
        return 0;
}


# ----------------------------------------------------------
# check if $value is a ipaddress (not ip/net)
# ----------------------------------------------------------
sub is_ipaddress($) {
        my $addr = shift;
        if ( $addr !~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ ) {
                return 0;
        }

        my @parts = { $1, $2, $3, $4 };
        foreach my $number (@parts) {
                $number = s/\D//;
                if ( ( $number < 0 ) || ( $number > 255 ) ) {
                        return 0;
                }
        }
        return 1;
}


# ----------------------------------------------------------
# check if $value is a port
# ----------------------------------------------------------
sub is_port($) {
        my $port = shift;
        if ( ( $port < 0 ) || ( $port > 65535 ) || ( $port !~ /^[0-9]*$/ ) ) {
                $errormessage = _('invalid destination port');
                return 0;
        }
        return 1;
}



# ----------------------------------------------------------
#  translate from german "Umlaute"
# ----------------------------------------------------------
sub translate_from_umlaute($) {
    my $ret = "";
    foreach my $word (split /\b/, $_[0]) {
        $word =~ s/ä/ae/g;
        $word =~ s/ö/oe/g;
        $word =~ s/ü/ue/g;
        if ( $word =~ /[a-z]/ ) {
            $word =~ s/Ä/Ae/g;
            $word =~ s/Ö/Oe/g;
            $word =~ s/Ü/Ue/g;
            $word =~ s/ß/ss/g;
        } else {
            $word =~ s/Ä/AE/g;
            $word =~ s/Ö/OE/g;
            $word =~ s/Ü/UE/g;
            $word =~ s/ß/SS/g;
        }
        $ret = $ret . $word;
    }
 return $ret;

}

# ----------------------------------------------------------
#  translate to german "Umlaute"
#  ----------------------------------------------------------
sub translate_to_umlaute($) {
    my $ret = "";
    foreach my $word (split /\b/, $_[0]) {
        $word =~ s/ae/ä/g;
        $word =~ s/oe/ö/g;
        $word =~ s/ue/ü/g;
        if ( $word =~ /[a-z]/ ) {
            $word =~ s/Ae/Ä/g;
            $word =~ s/Oe/Ö/g;
            $word =~ s/Ue/Ü/g;
        } else {
            $word =~ s/AE/Ä/g;
            $word =~ s/OE/Ö/g;
            $word =~ s/UE/Ü/g;
        }
        $ret = $ret . $word;
    }
 return $ret;

}

sub getpid($) {
    my $pidfile = shift;

    if (! open(FILE, "${pidfile}")) {
        return 0;
    }
    my $pid = <FILE>;
    chomp $pid;
    close FILE;
    return $pid;
}

sub getprocname($) {
    my $pid = shift;
    if ($pid == 0) {
        return '';
    }
    if (! open(FILE, "/proc/${pid}/status")) {
        return '';
    }

    my $cmd = '';
    while (<FILE>) {
        if (/^Name:\W+(.*)/) {
            $cmd = $1;
            last;
        }
    }
    close FILE;
    return $cmd;
}


sub getcmdline($) {
    my $pid = shift;
    if ($pid == 0) {
        return '';
    }
    if (! open(FILE, "/proc/${pid}/cmdline")) {
        return '';
    }
    my $cmdline = <FILE>;
    close FILE;

    return $cmdline;
}

sub isrunning() {
    my $process = shift;
    my $exename = $process->[0];
    my $pidfile = $process->[1];
    my $args = $process->[2];

    if ($pidfile eq '') {
        $pidfile = '/var/run/'.$exename.'.pid';
    }
    my $pid = getpid($pidfile);
    if ($pid == 0) {
        return 0;
    }
    my $cmd = getprocname($pid);
    if ($cmd eq '') {
        return 0;
    }
    if ($cmd ne $exename) {
        return 0;
    }

    if ($args eq '') {
        return 1;
    }
    my $cmdline = getcmdline($pid);
    if ($cmdline !~ /$args/) {
        return 0;
    }
    return 1;
} 


# ----------------------------------------------------------
#  Hotspot Editor
# ----------------------------------------------------------

sub hotspoteditpage(){
    my $language = shift;
    my $menu = shift;

    hotspotadminheader();
    hotspotcontentedit($language,$menu);
}

# ----------------------------------------------------------
#  Hotspot Header
# ----------------------------------------------------------
sub hotspotadminheader() {

    require 'header.pl';
    &showhttpheaders();
    
    my $helpuri = get_helpuri($menu);
    $title = $brand.' '.$product." - Hotspot";

printf <<EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML>
<HEAD><META CONTENT="text/html; charset=utf-8" HTTP-EQUIV="Content-Type">
    <TITLE>$title</TITLE>
    <META CONTENT="text/html; charset=UTF-8" HTTP-EQUIV="Content-Type">
    <LINK HREF="/favicon.ico" REL="shortcut icon">
    <STYLE TYPE="text/css">\@import url(/include/style.css);</STYLE>
    <STYLE TYPE="text/css">\@import url(/include/menu.css);</STYLE>
    <STYLE TYPE="text/css">\@import url(/include/content.css);</STYLE>
    <script language="javascript" type="text/javascript" src="/include/jquery.min.js"></script>
    <script language="javascript" type="text/javascript" src="/include/jquery.ifixpng.js"></script>
    <script language="JavaScript" type="text/javascript" src="/include/overlib_mini.js"></script>

    <script language="javascript" type="text/javascript" src="/include/uplink.js"></script>
    <link rel="stylesheet" type="text/css" media="screen" title="Uplinks Status" href="/include/uplinks-status.css" />
    
</HEAD>
<BODY>
<div id="flames">
  <DIV ID="main">
    <DIV ID="header">
EOF
;
    
    $image_path = `ls /razwall/web/html/images/product_*.jpg 2>/dev/null`;
    if ( ! $image_path ) {
        $image_path = `ls /razwall/web/html/images/logo_*.png 2>/dev/null`;
    }
    if ( $image_path ) { 
        $filename=substr($image_path,24);
        print "     <img id=\"logo-product\" src=\"/images/$filename\" alt=\"$product $brand\" />";
    };
    
printf <<EOF
      <DIV ID="header-icons">
      <ul>
           <li><a href="#" onclick="javascript:window.open('$helpuri','_blank','height=700,width=1000,location=no,menubar=no,scrollbars=yes');"><img src="/images/help.gif" alt="Help" border="0"> Help</a></li>
    	   <li><a href="/cgi-bin/logout.cgi" target="_self"><img src="/images/logout.gif" alt="Logout" border="0"> Logout</a></li>
      </ul>
      </DIV><!-- header-icons -->
      <DIV STYLE="margin-left: 25px;" ID="menu-top">
        <UL>
    <LI>
        <DIV CLASS="rcorner">
        <A HREF="/admin/">Hotspot</A>
        </DIV>
    </LI>
    <LI>
        <DIV CLASS="rcorner">
        <A HREF="/cgi-bin/hotspot-dial.cgi">%s</A>
        </DIV>
    </LI>
    </UL>
      </DIV><!-- menu-top -->
    </DIV><!-- header -->
EOF
,
_('Dialin'),
;
}

sub init_register_status($) {
    $register_status_hash = shift;
}

sub register_status($$) {
    my $item = shift;
    my $arr = shift;

    $register_status_hash->{$item} = $arr;
}
