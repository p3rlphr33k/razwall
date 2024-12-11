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

require 'ifacetools.pl';
require 'netwizard_tools.pl';
require 'header.pl';
require 'ethconfig.pl';
require 'modemtools.pl';

use File::Path qw( rmtree );

my $session = 0;
my %ifaces = {};
my @validifaces= qw 'eth vlan';
my $bridgefiles = 'ethernet/';

# -------------------------------------------------------------------
# Check if the demo mode is enabled

my $demo_conffile = "${swroot}/demo/settings";
my $demo_conffile_default = "/usr/lib/efw/demo/default/settings";
my %demo_settings_hash = ();
my $demo_settings = \%demo_settings_hash;

if (-e $demo_conffile_default) {
    readhash($demo_conffile_default, $demo_settings);
}

if (-e $demo_conffile) {
    readhash($demo_conffile, $demo_settings);
}

my $demo = $demo_settings->{'DEMO_ENABLED'} eq 'on';

# -------------------------------------------------------------------

my $ENABLED_PNG = '/images/on.png';
my $DISABLED_PNG = '/images/off.png';

my %allow = ("NONE" => 1, "STATIC" => -1, "DHCP" => -1, "PPPOE" => -1, "ADSL" => 1 ,"ISDN" => 1 ,"PPTP" => -1, "ANALOG" => -1, "STEALTH" => 1);
my %device_used = ();
my %uplink_networks = ();

my %zones = (
    'GREEN' => _('GREEN'),
    'BLUE' => _('BLUE'),
    'ORANGE' => _('ORANGE')
);

my %zone_devices = (
    'GREEN' => 'br0',
    'ORANGE' => 'br1',
    'BLUE' => 'br2'
);

my %red_names = ();
my %network_types = ();
my %network_names = ("ROUTED" => _("Routed"), "BRIDGED" => _("Bridged"), "NOUPLINK" => _("No uplink"));
my %network_labels = ("ROUTED" => _("Uplink type"), "BRIDGED" => "", "NOUPLINK" => "");

foreach my $regfile (glob("/home/httpd/cgi-bin/uplinkType-*.pl")) {
    require $regfile;
    $red_names{$uplink_code} = $uplink_name;
    if (exists $network_types{$network_type}) {
        push(@{$network_types{$network_type}}, $uplink_code);
    } else {
        my @tmp = ();
        $network_types{$network_type} = \@tmp;
        push(@{$network_types{$network_type}}, $uplink_code);
    }
}

# Sort Routed uplinks
if ($#{$network_types{"ROUTED"}} > 0) {
    my @network_types_preferred_order = ("DHCP", "STATIC", "MODEM", "PPPOE", "PPTP", "ANALOG", "ISDN", "ADSL", "NONE", "STEALTH");
    my %found_network_types = map { $_ => 1 } @{$network_types{"ROUTED"}} ;
    my @tmp = ();
    $network_types{"ROUTED"} = \@tmp;
    foreach $n (@network_types_preferred_order) {
        if (exists($found_network_types{$n})) {
            push(@{$network_types{"ROUTED"}}, $n);
            delete $found_network_types{$n};
        }
    }
    foreach $n (keys %found_network_types) {
        push(@{$network_types{"ROUTED"}}, $n);
        delete $found_network_types{$n};
    }
}

my @adsl_protocols = ("RFC2364", "RFC1483", "STATIC", "DHCP");
my %adsl_names = ("RFC2364" => "PPPoA", "RFC1483" => "PPPoE", "STATIC" => "PPPoE static", "DHCP" => "PPPoE dhcp");
my @auth_types = ("pap-or-chap", "pap", "chap");
my %auth_names = ("pap-or-chap" => "PAP or CHAP", "pap" => "PAP", "chap" => "CHAP");
my %encap_names = ("0" => "bridged VC", "1" => "bridged LLC", "2" => "routed VC", "3" => "routed LLC");
my @pptp_methods = ("STATIC", "DHCP");
my %pptp_names = ("STATIC" => _("static"), "DHCP" => "dhcp");
my @analog_modems = ("modem", "hsdpa", "cdma");
my %analog_modem_names = ("modem" => "Simple analog modem", "hsdpa" => "UMTS/HSDPA modem", "cdma" => "UMTS/CDMA modem");
my @speeds = ('300', '1200', '2400', '4800', '9600', '19200', '38400', '57600', '115200', '230400', '460800');

init_ethconfig();
(my $ifaces, my $ifacesdata) = list_devices_description(3, 'RED|NONE', 1);
(my $stealth_ifaces, my $stealth_ifacesdata) = list_devices_description(3, 'GREEN|ORANGE|BLUE', 1);

my $adsl_modems = iterate_modems("adsl");
my $isdn_modems = iterate_modems("isdn");
my $modeminforef = iterate_comports();
my @comports = @$modeminforef;

my $uplinkdir = '/var/efw/uplinks';

my $UP_PNG = '/images/stock_up-16.png';
my $DOWN_PNG = '/images/stock_down-16.png';
my $ENABLED_PNG = '/images/on.png';
my $DISABLED_PNG = '/images/off.png';
my $EDIT_PNG = '/images/edit.png';
my $DELETE_PNG = '/images/delete.png';
my $OPTIONAL_PNG = '/images/blob.png';

my @errormessages = ();

my @uplinklist = ();
my %uplinks = ();
my %uplink_info = ();

my $show_advanced = false;

my %selected = ();
my %checked = ();
my %display = ();

sub check_allow($) { #check if the maximum allowed number is reached
    my $type = shift;
    if (($type eq "NONE" || $type eq "STEALTH") && ($allow{'NONE'} eq 0 || $allow{'STEALTH'} eq 0)) {
        $notification = _("Could not enable Uplink. Only one uplink of type Bridged or No uplink may be enabled.");
        return 1;
    }
    return 0;
}

sub check_device($$$) { #check if network device can be enabled
    my $uplink = shift;
    my $dev = shift;
    my $type = shift;

    foreach (@{get_uplinks()}) {
        my %u_info = get_uplink_info($_);
        if ($u_info{'ENABLED'} eq "on" && $u_info{'ID'} ne $uplink && $u_info{'RED_DEV'} eq $dev) {
            if (($u_info{'RED_TYPE'} ne $type) || ($u_info{'RED_TYPE'} ne "PPTP" && $u_info{'RED_TYPE'} ne "PPPOE")) {
                $notification = _("Could not enable Uplink. Device <b>%s</b> is already used by <b>%s</b>", $dev, $u_info{'NAME'});
                return 1;
            }
        }
    }
    return 0;
}

sub check_ips() {
    my $redip = "";
    if ($par{'RED_TYPE'} eq "STATIC" || ($par{'RED_TYPE'} eq "PPTP" && $par{'METHOD'} eq "STATIC")) {
        if ($par{'RED_ADDRESS'} eq "") {
            push(@errormessages, _("IP address must not be <b>empty</b>."));
            return;
        }
        if ($par{'RED_NETMASK'} eq "") {
            push(@errormessages, _("Netmask must not be <b>empty</b>."));
            return;
        }
        $redip = $par{'RED_ADDRESS'}.'/'.$par{'RED_NETMASK'};
    }
    else {
        $par{'RED_ADDRESS'} = "";
        $par{'RED_NETMASK'} = "";
    }
    ($red_ips, $nok_ips) = createIPS($redip, $par{'RED_IPS'});
    $par{'RED_IPS'} = $red_ips;
    #$red_ips = $ok_ips;
    if ($nok_ips eq "") {
        foreach my $invalid (@{checkNetaddress($red_ips)}) {
            push(@errormessages, _("The IP address '%s' is the same as its network address, which is not allowed!", $invalid));
        }
        foreach my $invalid (@{checkBroadcast($red_ips)}) {
            push(@errormessages, _("The IP address '%s' is the same as its broadcast address, which is not allowed!", $invalid));
        }
        foreach my $invalid (@{checkInvalidMask($red_ips)}) {
            push(@errormessages, _("The network mask of the IP address '%s' addresses only 1 IP address, which will lock you out if applied. Choose another one!", $invalid));
        }
    }
    else {
        foreach my $nokip (split(/,/, $nok_ips)) {
            push(@errormessages, _('The RED IP address or network mask "%s" is not correct.', $nokip));
        }
    }
    foreach my $uplink (keys %uplink_networks) {
        if ($uplink eq $par{'ID'} || $uplink_networks{$uplink} eq "") {
            next;
        }
        if (network_overlap($red_ips, $uplink_networks{$uplink},)) {
            push(@errormessages, _('The networks of this uplink are not distinct with \'%s\' networks.', $uplink));
        }
    }
    if (network_overlap($red_ips, $settings{'GREEN_IPS'},)) {
        push(@errormessages, _('The RED and GREEN networks are not distinct.'));
    }
    if (orange_used()) {
        if (network_overlap($red_ips, $settings{'ORANGE_IPS'},)) {
            push(@errormessages, _('The RED and ORANGE networks are not distinct.'));
        }
    }
    if (blue_used()) {
        if (network_overlap($red_ips, $settings{'BLUE_IPS'})) {
            push(@errormessages, _('The RED and BLUE networks are not distinct.'));
        }
    }
}

sub check_hosts() { #check if the checkhosts are valid
    if ($par{'CHECKHOSTS'} eq "") {
        push(@errormessages, _("'Check if these hosts are reachable' must not be empty!"));
        return;
    }
    @temp = split(/\n/,$par{'CHECKHOSTS'});
    foreach (@temp)    {
        s/^\s+//g; s/\s+$//g;
        if ($_) {
            chomp $_;
            if (!check_ip($_, "255.255.255.0") && !validdomainname($_) && $_ ne "") {
                push(@errormessages, _("'%s' is not a valid IP address or domain name!", $_));
                $show_advanced = true;
            }
        }
    }
}

sub check_apn() { #check if the apn is valid
    if ($par{'APN'} && !check_ip($par{'APN'}, "255.255.255.0") && !validdomainname($par{'APN'})) {
        push(@errormessages, _("Access Point Name: '%s' is not a valid IP address or domain name!", $_));
        $show_advanced = true;
    }
}

sub getzonebydev($) {
    my $dev = shift;
    
    my $validzones=validzones();
    foreach my $zone (@$validzones) {
        if ($zone eq 'RED') {
            next;
        }
        foreach my $zone_dev (@{get_zone_devices($zone_devices{$zone})}) {
            if ($zone_dev eq $dev) {
                return $zone;
            }
        }
    }
    return "";
}

sub check_gateway() { #check if gateway is correct
    undef $valid;
    if ($par{'DEFAULT_GATEWAY'} eq "") {
        push(@errormessages, _("Default gateway must not be <b>empty</b>."));
    }
    elsif ($par{'RED_TYPE'} eq "NONE") {
        (my $valid, my $ip, my $mask) = check_ip($par{'DEFAULT_GATEWAY'}, '255.255.255.0');
        if (!$valid) {
            push(@errormessages, _('The gateway address is not correct.'));
        }
    }
    elsif ($par{'RED_TYPE'} eq "STEALTH") {
        my $gwzone = getzonebydev($par{'STEALTH_DEV'});
        if (! network_overlap($settings{$gwzone.'_IPS'}, $par{'DEFAULT_GATEWAY'}. '/32')) {
            push(@errormessages, _('Gateway must be within %s network.', $zones{$gwzone}));
        }
    }
    else {
        (my $valid, my $ip, my $mask) = check_ip($par{'DEFAULT_GATEWAY'}, '255.255.255.255');
        if (!$valid) {
            push(@errormessages, _('The gateway address is not correct.'));
            return @errormessages
        }
        if (network_overlap($settings{'GREEN_IPS'}, $par{'DEFAULT_GATEWAY'}. '/32')) {
            push(@errormessages, _('The DEFAULT GATEWAY is within the GREEN network.'));
        }
        if (orange_used()) {
            if (network_overlap($settings{'ORANGE_IPS'}, $par{'DEFAULT_GATEWAY'}. '/32')) {
                push(@errormessages, _('The DEFAULT GATEWAY is within the ORANGE network.'));
            }
        }
        if (blue_used()) {
            if (network_overlap($settings{'BLUE_IPS'}, $par{'DEFAULT_GATEWAY'}. '/32')) {
                push(@errormessages, _('The DEFAULT GATEWAY is within the BLUE network.'));
            }
        }
    }
}

sub check_dns() { #check if dns entries are valid
    undef $valid;
    if ($par{'DNS'} eq "on") {
        if ($par{'DNS1'} eq "" && $par{'DNS2'} eq "") {
            push(@errormessages, _("Primary DNS must not be <b>empty</b>."));
        }
        else {
            (my $valid, my $ip, my $mask) = check_ip($par{'DNS1'}, "255.255.255.255");
            if (!$valid) {
                push(@errormessages, _('The IP address of DNS1 is not correct.'));
            }
            elsif ($par{'DNS2'} eq "") { # if DNS1 is correct and DNS2 is empty DNS2 is set to DNS1
                $par{'DNS2'} = $par{'DNS1'};
            }
            (my $valid, my $ip, my $mask) = check_ip($par{'DNS2'}, "255.255.255.255");
            if (!$valid) {
                push(@errormessages, _('The IP address of DNS2 is not correct.'));
            }
            elsif ($par{'DNS2'} eq "") {
                $par{'DNS1'} = $par{'DNS2'};
            }
        }
    }
}

sub check_mac() { #check if mac address is valid
    if ($par{'MACACTIVE'} eq "on") {
        if ($par{'MAC'} eq "") {
            push(@errormessages, _("The MAC address must not be <b>empty</b>"));
            $show_advanced = true;
        }
        elsif (! validmac($par{'MAC'})) {
            push(@errormessages, _('The MAC address "%s" is invalid. Correct format is: xx:xx:xx:xx:xx:xx!', $par{'MAC'}));
            $show_advanced = true;
        }
    }
}

sub toggle_enable($$) {
    if ($demo) {
        return;
    }
    my $uplink = shift;
    my $enable = shift;
    if ($enable) {
        $enable = 'on';
    } else {
        $enable = 'off';
    }
    if ($enable eq "on") {
        my %u_info = get_uplink_info($uplink);
        my $used = check_device($uplink, $u_info{'RED_DEV'}, $u_info{'RED_TYPE'});
        if ($used == 1) {
            return;
        }
        my $used = check_allow($u_info{'RED_TYPE'});
        if ($used == 1) {
            return;
        }
    }
    &readhash("$uplinkdir/$uplink/settings", \%settings);
    $settings{'ENABLED'} =  $enable;
    &writehash("$uplinkdir/$uplink/settings", \%settings );
    system("sudo /etc/rc.d/uplinks stop $uplink");
}

sub save_uplink() {
    if ($demo) {
        return;
    }
    my $restart = 0;
    my %oldsettings = ();

    my %config = ();

    &readhash('/var/efw/ethernet/settings', \%settings);

    # check if it is the default profile
    if ($par{'NAME'} eq _("Main uplink")) {
        $save = "main";
        $name = _("Main uplink");
    }
    $save = $par{'ID'};
    if ($save eq "main" && $par{'NAME'} eq "") {
        $par{'NAME'} = _("Main uplink");
    }
    $old_name = $par{'OLD_NAME'};
    $name = $par{'NAME'};

    if ($save ne "main") {
        if ($name eq "") {
            $name = sprintf "%s $red_names{$par{'RED_TYPE'}}", _("Uplink");
        }
        elsif ($name eq _("Main uplink")) {
            $name = sprintf "%s $red_names{$par{'RED_TYPE'}}", _("Uplink");
        }
        if (($name ne $old_name)) {
            $i = 0;
            $exists = 1;
            $tmp_name = $name;
            while ($exists eq 1) {
                $exists = 0;
                foreach (@{get_uplinks()}) {
                    $u_info = get_uplink_info($_);
                    if ("$u_info{'NAME'}" eq "$name") {
                        $exists = 1;
                        $name = "$tmp_name $i";
                    }
                    $i++;
                }
            }
        }
    }
    $config{'NAME'} = $name;

    if ($save eq "") {
        $restart = 1;
        $tmpdir = "$uplinkdir/uplink";
        $i = 1;
        $dir = "$tmpdir$i";
        $save = "uplink$i";
        while ( -e "$dir/settings" && ! -z "$dir/settings") {
            $dir = "$tmpdir$i";
            $save = "uplink$i";
            $i++;
        }
        if (! (-d $dir)) {
            mkdir($dir);
        }
    }
    else {
        $dir = "$uplinkdir/$save";
        if (-e "$uplinkdir/$save/settings") {
            &readhash("$uplinkdir/$save/settings", \%oldsettings);
            $config{'DOWNLOAD'} = $oldsettings{'DOWNLOAD'};
            $config{'UPLOAD'} = $oldsettings{'UPLOAD'};
            $config{'SHAPING'} = $oldsettings{'SHAPING'};
        }
    }
    
    if ($par{'RED_IPS_ACTIVE'} ne "on") {
        $par{'RED_IPS'} = "";
    }
    if ($par{'BACKUPPROFILEACTIVE'} ne "on" || $par{'BACKUPPROFILE'} eq $par{'ID'}) {
        $par{'BACKUPPROFILE'} = "";
    }
    $config{'BACKUPPROFILE'} = $par{'BACKUPPROFILE'};
    if ($par{'LINKCHECK'} eq "on") {
        check_hosts();
    }
    $config{'LINKCHECK'} = $par{'LINKCHECK'};
    if ($par{'PROTOCOL'} eq "STATIC" || $par{'PROTOCOL'} eq "DHCP") {
        $config{'METHOD'} = $par{'PROTOCOL'};
        $config{'PROTOCOL'} = "RFC1483";
    }

    if ($par{'MACACTIVE'} ne "on") {
        $par{'MAC'} = "";
    }
    if ($par{'MTU'} ne "" && ! ($par{'MTU'} =~ m/^\d+$/)) {
        push(@errormessages, _('MTU must be an integer.'));
    }
    if ($par{'RECONNECT_TIMEOUT'} ne "" && ! ($par{'RECONNECT_TIMEOUT'} =~ m/^\d+$/)) {
        push(@errormessages, _('Reconnection timeout must be an integer.'));
    }

    if ($par{'ENABLED'} eq "on") {
        my $dev = $par{'RED_DEV'};
        my $type = $par{'RED_TYPE'};
        if ($par{'NETWORK_TYPE'} eq "BRIDGED") {
            $dev = $par{'STEALTH_DEV'};
            $type = "STEALTH";
        } elsif ($par{'NETWORK_TYPE'} eq "NOUPLINK") {
            $type = "NONE";
        }
        my $used = check_device($save, $dev, $type);
        if ($used == 1) {
            $par{'ENABLED'} = "off";
        }
        my $used = check_allow($type);
        if ($used == 1) {
            $par{'ENABLED'} = "off";
        }
    }

    if ($par{'NETWORK_TYPE'} eq "NOUPLINK") {
        $par{'RED_TYPE'} = "NONE";
        $config{'RED_DEV'} = "";
        if ($par{'CHECKHOSTS'} eq "") {
            $par{'CHECKHOSTS'} = "127.0.0.1";
        }
        $config{'CHECKHOSTS'} = $par{'CHECKHOSTS'};
        check_gateway();
        $config{'DEFAULT_GATEWAY'} = $par{'DEFAULT_GATEWAY'};
        $par{'DNS'} = "on";
        check_dns();
    }
    elsif ($par{'NETWORK_TYPE'} eq "BRIDGED") {
        $par{'RED_TYPE'} = "STEALTH";
        $config{'RED_DEV'} = $par{'STEALTH_DEV'};
        
        if ($par{'CHECKHOSTS'} eq "") {
            $par{'CHECKHOSTS'} = "127.0.0.1";
        }
        $config{'CHECKHOSTS'} = $par{'CHECKHOSTS'};
        check_gateway();
        $config{'DEFAULT_GATEWAY'} = $par{'DEFAULT_GATEWAY'};
        $par{'DNS'} = "on";
        check_dns();
    }
    elsif ($par{'RED_TYPE'} eq "STATIC") {
        $config{'RED_DEV'} = $par{'RED_DEV'};
        check_ips();
        check_gateway();
        $config{'DEFAULT_GATEWAY'} = $par{'DEFAULT_GATEWAY'};
        $par{'DNS'} = "on";
        check_dns();
        check_mac();
        $config{'MAC'} = $par{'MAC'};
    }
    elsif ($par{'RED_TYPE'} eq "DHCP") {
        $config{'RED_DEV'} = $par{'RED_DEV'};
        $par{'RED_IPS'} = "";
        check_ips();
        check_dns();
        check_mac();
        $config{'MAC'} = $par{'MAC'};
    }
    elsif ($par{'RED_TYPE'} eq "PPPOE") {
        $config{'METHOD'} = "PPPOE";
        $config{'PROTOCOL'} = "RFC1483";
        $config{'RED_DEV'} = $par{'RED_DEV'};
        $config{'AUTH'} = $par{'AUTH'};
        check_ips();
        check_dns();
        check_mac();
        $config{'MAC'} = $par{'MAC'};
        $config{'CONCENTRATORNAME'} = $par{'CONCENTRATORNAME'};
        $config{'SERVICENAME'} = $par{'SERVICENAME'};
    }
    elsif ($par{'RED_TYPE'} eq "PPTP") {
        $config{'RED_DEV'} = $par{'RED_DEV'};
        $config{'METHOD'} = $par{'METHOD'};
        $config{'PHONENUMBER'} = $par{'TELEPHONE'};
        $config{'AUTH'} = $par{'AUTH'};
        check_ips();
        if ($par{'METHOD'} eq "STATIC") {
            check_gateway();
            $config{'DEFAULT_GATEWAY'} = $par{'DEFAULT_GATEWAY'};
            $par{'DNS'} = "";
        }
        else {
            check_dns();
        }
        check_mac();
        $config{'MAC'} = $par{'MAC'};
    }
    elsif ($par{'RED_TYPE'} eq "ADSL") {
        $config{'RED_DEV'} = "";
        $config{'TYPE'} = $par{'ADSL_TYPE'};
        $config{'PROTOCOL'} = $par{'PROTOCOL'};
        $config{'METHOD'} = $par{'METHOD'};
        $config{'ENCAP'} = $par{'ENCAP'};

        check_ips();
        if ($par{'VCI'} eq "" || $par{'VPI'} eq "") {
            push(@errormessages, _("VCI and VPI must not be <b>empty</b>."));
        }
        if ($par{'VCI'} < 32 || $par{'VCI'} > 65535) {
            push(@errormessages, _("VCI must be between 32 and 65535."));
        }
        if ($par{'VPI'} < 0 || $par{'VPI'} > 255) {
            push(@errormessages, _("VPI must be between 0 and 255."));
        }
        $config{'VCI'} = $par{'VCI'};
        $config{'VPI'} = $par{'VPI'};

        if ($par{'PROTOCOL'} ne "RFC1483") {
            $config{'AUTH'} = $par{'AUTH'};
        }

        if ($par{'PROTOCOL'} eq "RFC1483" && $par{'METHOD'} eq "STATIC") {
            check_gateway();
            # with RFC1483 uplinksdaemon currently uses GATEWAY. will save DEFAULT_GATEWAY & GATEWAY in this case, so it also works in future
            $config{'GATEWAY'} = $par{'DEFAULT_GATEWAY'};
            $config{'DEFAULT_GATEWAY'} = $par{'DEFAULT_GATEWAY'};
            $par{'DNS'} = "on";
            check_dns();
        }
        elsif ($par{'PROTOCOL'} eq "RFC2364" || ($par{'PROTOCOL'} eq "RFC1483" && $par{'METHOD'} eq "PPPOE")) {
            check_dns();
        }
    }
    elsif ($par{'RED_TYPE'} eq "ISDN") {
        $config{'RED_DEV'} = "";
        $config{'TELEPHONE'} = $par{'TELEPHONE'};
        $config{'AUTH'} = $par{'AUTH'};
        $config{'MSN'} = $par{'MSN'};
        check_ips();
        check_dns();
        $config{'TYPE'} = $par{'ISDN_TYPE'};
        $config{'TIMEOUT'} = $par{'RECONNECT_TIMEOUT'};
    }
    elsif ($par{'RED_TYPE'} eq "ANALOG") {
        $config{'RED_DEV'} = "";
        $config{'TELEPHONE'} = $par{'TELEPHONE'};
        $config{'COMPORT'} = $par{'COMPORT'};
        $config{'MODEMTYPE'} = $par{'MODEMTYPE'};
        $config{'SPEED'} = $par{'SPEED'};
        $config{'AUTH'} = $par{'AUTH'};
        check_ips();
        check_dns();
        check_apn();
        $config{'APN'} = $par{'APN'};
    }
    elsif ($par{'RED_TYPE'} eq "MODEM") {
        $config{'MM_MODEM'} = $par{'MM_MODEM'};
        $config{'MM_MODEM_TYPE'} = $par{'MM_MODEM_TYPE'};

        if (!$par{'MM_MODEM'}) {
            push(@errormessages, _("you need to select a modem"));
            $show_advanced = true;
        }

        $config{'MM_PROVIDER_COUNTRY'} = $par{'MM_PROVIDER_COUNTRY'};
        $config{'MM_PROVIDER_PROVIDER'} = $par{'MM_PROVIDER_PROVIDER'};
        $config{'MM_PROVIDER_APN'} = $par{'MM_PROVIDER_APN'};
        $config{'RED_DEV'} = "";
        $config{'TELEPHONE'} = $par{'TELEPHONE'};
        $config{'AUTH'} = $par{'AUTH'};
        check_ips();
        check_dns();
        check_apn();
        $config{'APN'} = $par{'APN'};
    }

    if ($par{'DNS'} eq "") {
        $config{'DNS'} = "Automatic";
        $config{'DNS1'} = "";
        $config{'DNS2'} = "";
    }
    else {
        $config{'DNS'} = "Manuell";
        $config{'DNS1'} = $par{'DNS1'};
        $config{'DNS2'} = $par{'DNS2'};
    }
    # check if errormessage is empty if not show the errors and do not save.
    if (scalar(@errormessages) eq 0) {
        $config{'RED_TYPE'} = $par{'RED_TYPE'};
        $config{'RED_ADDRESS'} = $par{'RED_ADDRESS'};
        $config{'RED_NETMASK'} = $par{'RED_NETMASK'};
        $config{'CIDR'} = $config{'RED_CIDR'};
        $config{'RED_IPS'} = $par{'RED_IPS'};
        $config{'USERNAME'} = $par{'USERNAME'};
        $config{'PASSWORD'} = $par{'PASSWORD'};
        $config{'RECONNECT_TIMEOUT'} = $par{'RECONNECT_TIMEOUT'};
        $config{'MTU'} = $par{'MTU'};

        @temp = split(/[\r\n,]/,$par{'CHECKHOSTS'});
        $par{'CHECKHOSTS'} = "";
        foreach (@temp) {
            if ($_) {
                chomp $_;
                if (/$_/ ne "") {
                    if ($par{'CHECKHOSTS'} eq "") {
                        $par{'CHECKHOSTS'} = $_;
                    }
                    else {
                        $par{'CHECKHOSTS'} = $par{'CHECKHOSTS'}.",".$_;
                    }
                }
            }
        }
        $config{'CHECKHOSTS'} = $par{'CHECKHOSTS'};

        if($par{'ENABLED'} ne "on") {
            $par{'ENABLED'} = "off";
        }
        $config{'ENABLED'} = $par{'ENABLED'};

        if($par{'MANAGED'} ne "on") {
            $par{'MANAGED'} = "off";
        }
        $config{'MANAGED'} = $par{'MANAGED'};

        if($par{'DISABLE_SIGNATURE_DOWNLOAD'} ne "on") {
            $par{'DISABLE_SIGNATURE_DOWNLOAD'} = "off";
        }
        $config{'DISABLE_SIGNATURE_DOWNLOAD'} = $par{'DISABLE_SIGNATURE_DOWNLOAD'};

        if($par{'ONBOOT'} ne "on") {
            $par{'ONBOOT'} = "off";
        }
        $config{'ONBOOT'} = $par{'ONBOOT'};
        $config{'AUTOSTART'} = $par{'ONBOOT'};

        &writehash("$dir/settings", \%config );

        if ($restart ne 1 && %oldsettings ne ()) {
            for my $key (keys %oldsettings) {
                if ($key eq "CHECKHOST" || $key eq "NAME" || $key eq "BACKUPPROFILE") {
                    next;
                }
                if ($oldsettings{$key} ne $config{$key}) {
                    $restart = 1;
                    last;
                }
            }
        }

        %par = ();
        if ($restart eq 1 && $config{'ENABLED'} eq "on") {
            system("sudo /etc/rc.d/uplinks stop $save");
        }
    }

    # Force HA sync
    system("jobcontrol call base.noop &>/dev/null")
}

sub delete_uplink($) {
    if ($demo) {
        return;
    }
    my $uplink = shift;
    my %u_info = get_uplink_info($uplink);
    #iterate over all uplinks to check if the uplinks is used as backupuplink
    foreach (@{get_uplinks()}) {
        if ($_ ne $uplink) { # do not check if uplink is its own backupuplink
            my %backup_info = get_uplink_info($_);
            if ($backup_info{'BACKUPPROFILE'} eq $uplink) {
                &openbigbox(_("Uplink <b>%s</b> is <b>used</b> as backup-link by <b>%s</b>.", $backup_info{'NAME'}, $u_info{'NAME'}), $warnmessage, $notemessage);
                return
            }
        }
    }
    # delete uplink if it is not used as backupuplink
    # system("jobcontrol call network.delete_uplink --uplink $par{'ID'} &>/dev/null")
    if ($u_info{'ENABLED'} eq "on") {
        system("sudo /etc/rc.d/uplinks stop $uplink");
    }
    rmtree("$uplinkdir/$uplink")
}

sub get_uplink_display() {
    $display{'uplinkeditor'} = "";
    $display{'folding_advanced'} = "";
    if (scalar(@errormessages) eq 0) {
        undef $disabled;
    }
    else {
        $display{'uplinkeditor'} = "showeditor";
        if ($show_advanced eq true) {
            $display{'folding_advanced'} = "open";
        }
    }
    if ($par{'RED_TYPE'} eq "") {
        $par{'RED_TYPE'} = "NONE";
    }
    if ($par{'RED_IPS_ACTIVE'} eq "on") {
        $checked{'RED_IPS_ACTIVE'} = "checked=\"checked\"";
    }
    if ($par{'MACACTIVE'} eq "on") {
        $checked{'MACACTIVE'} = "checked=\"checked\"";
    }
    if ($par{'DNS'} eq "on") {
        $checked{'DNS'} = "checked=\"checked\"";
    }
    if ($par{'MACACTIVE'} eq "on") {
        $checked{'MACACTIVE'} = "checked=\"checked\"";
    }
    if ($uplink ne "" || $#errormessages ne -1) {
        $button = _("Update uplink");
        $selected{$par{'RED_TYPE'}} = "selected=\"selected\"";
    }
    else {
        $button = _("Create uplink");
        $selected{'NONE'} = "selected=\"selected\"";
    }
    if ($par{'ENABLED'} eq "on") {
        $checked{'ENABLED'} = "checked=\”checked\""
    }
    if ($par{'MANAGED'} eq "on") {
        $checked{'MANAGED'} = "checked=\”checked\""
    }
    if ($par{'DISABLE_SIGNATURE_DOWNLOAD'} eq "on") {
        $checked{'DISABLE_SIGNATURE_DOWNLOAD'} = "checked=\”checked\""
    }
    if ($par{'ONBOOT'} eq "on") {
        $checked{'ONBOOT'} = "checked=\”checked\""
    }
    if ($par{'BACKUPPROFILE'} ne "") {
        if (-e "${swroot}/uplinks/$par{'BACKUPPROFILE'}/settings") {
            $checked{'BACKUPPROFILEACTIVE'} = "checked=\"checked\"";
        }
    }
}

sub show_uplink_types() {
    printf <<EOF
    <div class="uplinktypes" id="uplinkdevice">
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="RED_DEV">
EOF
    ,
    _("Device"),
    ;
    foreach $iface (@$ifaces) {
        if ($iface->{'device'} eq $par{'RED_DEV'}) {
            $selected = "selected=\"selected\"";
        }
        else {
            undef $selected;
        }
        printf <<EOF
                        <option value="$iface->{'device'}" $selected >$iface->{'shortlabel'}</option>
EOF
        ,
        ;
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
        </table>
    </div>
EOF
    ,
    ;
    printf <<EOF
    <div class="uplinktypes" id="uplinkstealthdevice">
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="STEALTH_DEV">
EOF
    ,
    _("Device"),
    ;
    foreach $iface (@$stealth_ifaces) {
        my @zone_dev = @{get_zone_devices($zone_devices{$iface->{'zone'}})};
        if ($#zone_dev le 0) {
            next;
        }
        if ($iface->{'device'} eq $par{'RED_DEV'}) {
            $selected = "selected=\"selected\"";
        }
        else {
            undef $selected;
        }
        printf <<EOF
                        <option value="$iface->{'device'}" $selected >$iface->{'shortlabel'}</option>
EOF
        ,
        ;
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkisdntype" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="ISDN_TYPE">
EOF
    ,
    _("ISDN modem"),
    ;
    foreach my $modem (@$isdn_modems) {
        my $caption = get_info('isdn', $modem);
        next if ($caption eq '');
        my $detected = '';
        if (detect('isdn', $modem) > 0) {
            $caption .= ' '.'-->'._('detected').'<--';
        }
        if ( $modem eq $par{'ISDN_TYPE'}) {
            $selected = "selected=\"selected\"";
        }
        else {
            undef $selected;
        }
        printf <<EOF
                        <option value="$modem" $selected>$caption</option>
EOF
        ,
        ;
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkcomport" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="COMPORT">
EOF
    ,
    _("Serial/USB Port"),
    ;
    foreach my $comport (@comports) {
        if ( $comport eq $par{'COMPORT'}) {
            $selected = "selected=\"selected\"";
        }
        else {
            undef $selected;
        }
        my $caption = $comport;
        $caption =~ s/\/dev\/tty//g; #make it more human readable
        $caption =~ s/^S/Serial Port /g;
        $caption =~ s/^USB/USB Port /g;
        printf <<EOF
                        <option value="$comport" $selected>$caption</option>
EOF
        ,
        ;
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
        </table>
    </div>

    <script src="/include/modemmanager.js"></script>

    <div class="uplinktypes" id="uplink_mm_modems">
      <table width="100%">
        <tr>
          <td style="width: 100px;">%s *</td>
          <td>
            <input type="hidden" class="form" name="MM_MODEM_TYPE"/>
            <select class="form" name="MM_MODEM"></select>

            <a href="javascript: void(0);" id="refresh_mm_button">
              <img src="/images/reconnect.png" id="mm_refresh_icon" border="0" alt="refresh" title="refresh" style="vertical-align: middle"/>
            </a>
          </td>
        </tr>
        <tr>
          <td style="width: 100px;">%s:</td>
          <td id="mm_modem_info_type"></td>
        </tr>
  
        <tr>
          <td style="width: 100px;">%s:</td>
          <td id="mm_modem_info_id"></td>
        </tr>
  
        <tr>
          <td style="width: 100px;">%s:</td>
          <td id="mm_modem_info_status"></td>
        </tr>
        <tr>
          <td style="width: 100px;">%s:</td>
          <td>
            <select class="form" name="MM_PROVIDER_COUNTRY" ></select>
          </td>
        </tr>
        <tr>
          <td style="width: 100px;">%s:</td>
          <td>
            <select class="form" name="MM_PROVIDER_PROVIDER"></select>
          </td>
        </tr>
          <tr id="uplink_mm_apn">
            <td style="width: 100px;">%s:</td>
            <td>
              <select class="form" name="MM_PROVIDER_APN"></select>
            </td>
          </tr>
      </table>
    </div>
EOF
    ,
    _("Modem"),
    _("Modem type"),
    _("Identifier/IMEI"),
    _("Status"),
    _("Select country"),
    _("Select provider"),
    _("Select APN"),
    ;
    printf <<EOF


    <div class="uplinktypes" id="uplinkmodemtype" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="MODEMTYPE">
EOF
    ,
    _("Modem type"),
    ;
    foreach my $modem (@analog_modems) {
        my $caption = $analog_modem_names{$modem};
        if ( $modem eq $par{'MODEMTYPE'}) {
            $selected = "selected=\"selected\"";
        }
        else {
            undef $selected;
        }
        printf <<EOF
                        <option value="$modem" $selected>$caption</option>
EOF
        ,
        ;
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkspeeds" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="SPEED">
EOF
    ,
    _("Baud-rate"),
    ;
    foreach my $speed (@speeds) {
        if ($speed eq $par{'SPEED'}) {
            $selected = "selected=\"selected\""
        }
        else {
            undef $selected;
        }
        printf <<EOF
                        <option value="$speed" $selected>$speed</option>
EOF
        ,
        ;
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkapn" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s</td>
                <td><input class="form" type="text" value="$par{'APN'}" name="APN"/></td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkprotocol" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="PROTOCOL">
EOF
    ,
    _("Access Point Name"),
    _("ADSL protocol"),
    ;
    foreach $protocol (@adsl_protocols) {
        if ($protocol eq $par{'PROTOCOL'} || ($par{'PROTOCOL'} eq "RFC1483" && $protocol eq $par{'METHOD'})) {
            $selected = "selected=\"selected\"";
        }
        else {
            undef $selected;
        }
        printf <<EOF
                        <option value="$protocol" $selected>$adsl_names{$protocol}</option>
EOF
        ,
        ;
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkadsltype" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="ADSL_TYPE">
EOF
    ,
    _("ADSL modem/router"),
    ;
    foreach my $modem (@$adsl_modems) {
        my $caption = get_info('adsl', $modem);
        next if ($caption eq '');
        my $detected = '';
        if (detect('adsl', $modem) > 0) {
            $caption .= ' '.'-->'._('detected').'<--';
            $selected = "selected=\"selected\"";
        }
        if ( $modem eq $par{'ADSL_TYPE'}) {
            $selected = "selected=\"selected\"";
        }
        else {
            undef $selected;
        }
        printf <<EOF
                        <option value="$modem" $selected>$caption</option>
EOF
        ,
        ;
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkmethod" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="METHOD">
EOF
    ,
    _("PPTP method"),
    ;
    foreach $method (@pptp_methods) {
        if ($method eq $par{'METHOD'}) {
            $selected = "selected=\"selected\""
        }
        else {
            undef $selected;
        }
        printf <<EOF
                        <option value="$method" $selected>$pptp_names{$method}</option>
EOF
        ,
        ;
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkvcivpi" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">VPI *</td>
                <td style="width: 50px;"><input class="form" type="text" maxlenght="3" size="3" value="$par{'VPI'}" name="VPI"/></td>
                <td style="width: 10px;"></td>
                <td style="width: 100px;">VCI *</td>
                <td><input class="form" type="text" maxlength="5" size="5" value="$par{'VCI'}" name="VCI"/></td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkencap" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="ENCAP">
EOF
    ,
    _("Encapsulation type"),
    ;
    for (my $type=0; $type<4; $type++) {
        if ($type eq $par{'ENCAP'}) {
            $selected = "selected=\"selected\""
        }
        else {
            undef $selected;
        }
        printf <<EOF
                        <option value="$type" $selected>$encap_names{$type}</option>
EOF
        ,
        ;
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkaddress" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td style="width: 150px;"><input class="form" type="text" maxlength="15" size="15" value="$par{'RED_ADDRESS'}" name="RED_ADDRESS"/></td>
                <td style="width: 10px;"></td>
                <td style="width: 100px;">%s *</td>
                <td><input class="form" type="text" maxlength="15" size="15" value="$par{'RED_NETMASK'}" name="RED_NETMASK"/></td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkipsactive" >
        <table width="100%">
            <tr>
                <td><input class="form" type="checkbox" style="margin-left:0px;" name="RED_IPS_ACTIVE" $checked{'RED_IPS_ACTIVE'}/>&nbsp;%s</td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkips" >
        <table width="100%" >
            <tr style="padding-top: 0px;">
                <td style="padding-top: 0px;">
                    <textarea class="form" cols="30" rows="6" style="padding: 0px;" name="RED_IPS">$par{'RED_IPS'}</textarea>
                </td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkphonenumber" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s</td>
                <td style="width: 150px;"><input class="form" type="text" value="$par{'TELEPHONE'}" name="TELEPHONE"/></td>
                <td style="width: 10px;"></td>
                <td style="width: 100px;"></td>
                <td></td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkuserpass" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s</td>
                <td style="width: 150px;"><input class="form" type="text" value="$par{'USERNAME'}" name="USERNAME"/></td>
                <td style="width: 10px;"></td>
                <td style="width: 100px;">%s</td>
                <td><input class="form" type="password" value="$par{'PASSWORD'}" name="PASSWORD"/></td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkmsn" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s</td>
                <td style="width: 150px;"><input class="form" type="text" value="$par{'MSN'}" name="MSN"/></td>
                <td style="width: 10px;"></td>
                <td style="width: 100px;"></td>
                <td></td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkauth" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="AUTH">
EOF
    ,
    _("IP address"),
    _("Netmask"),
    _("Add additional addresses (one IP/Netmask or IP/CIDR per line)"),
    _("Phone number"),
    _("Username"),
    _("Password"),
    _("Caller ID/MSN"),
    _("Authentication method"),
    ;
    foreach my $auth (@auth_types) {
        if ($auth eq $par{'AUTH'}) {
            $selected = "selected=\"selected\""
        }
        else {
            undef $selected;
        }
        printf <<EOF
                        <option value="$auth" $selected>$auth_names{$auth}</option>
EOF
        ,
        ;
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkgateway" >
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s *</td>
                <td><input class="form" type="text" value="$par{'DEFAULT_GATEWAY'}" name="DEFAULT_GATEWAY"/></td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkdns" >
        <table width="100%">
            <tr>
                <td colspan="5"><input class="form" type="checkbox" style="margin:0px;" name="DNS" $checked{'DNS'}/>&nbsp;%s</td>
            </tr>
        </table>
    </div>
    <div class="uplinktypes" id="uplinkmanualdns" >
        <table width="100%">
            <tr style="padding-top: 0px;">
                <td style="width: 100px; padding-top: 0px;">%s *</td>
                <td style="width: 150px; padding-top: 0px;"><input class="form" type="text" value="$par{'DNS1'}" name="DNS1"/></td>
                <td style="width: 10px; padding-top: 0px;"></td>
                <td style="width: 100px; padding-top: 0px;">%s</td>
                <td style="padding-top: 0px;"><input class="form" type="text" value="$par{'DNS2'}" name="DNS2"/></td>
            </tr>
        </table>
    </div>
    <hr size="1" color="#cccccc">
EOF
    ,
    _("Default gateway"),
    _("Use custom DNS settings"),
    _("Primary DNS"),
    _("Secondary DNS"),
    ;
}

sub show_uplink_advanced() {
    print get_folding("advanced", "start", _("Advanced settings"), $display{'folding_advanced'});
    printf <<EOF
        <div class="uplinktypes" id="uplinkmacactive" >
            <table width="100%">
                <tr style="padding-bottom: 0px;">
                    <td colspan="5" style="padding-bottom: 0px;"><input class="form" type="checkbox" style="margin:0px;" name="MACACTIVE" $checked{'MACACTIVE'}/>&nbsp;%s</td>
                </tr>
            </table>
        </div>
        <div class="uplinktypes" id="uplinkmac" >
            <table width="100%">
                <tr>
                    <td><input class="form" type="text" value="$par{'MAC'}" maxlength="17" size="17" name="MAC" /> *</td>
                </tr>
            </table>
        </div>
        <div class="uplinktypes" id="uplinkconcentrator" >
            <table width="100%">
                <tr>
                    <td style="width: 100px;">%s</td>
                    <td style="width: 150px;"><input class="form" type="text" value="$par{'CONCENTRATORNAME'}" name="CONCENTRATORNAME"/></td>
                    <td style="width: 10px;"></td>
                    <td style="width: 100px;">%s</td>
                    <td><input class="form" type="text" value="$par{'SERVICENAME'}" name="SERVICENAME"/></td>
                </tr>
            </table>
        </div>
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s</td>
                <td style="width: 50px;"><input class="form" type="text" size="4" name="RECONNECT_TIMEOUT" value="$uplink_info{'RECONNECT_TIMEOUT'}"></td>
                <td style="width: 10px;"></td>
                <td style="width: 100px;">%s</td>
                <td><input class="form" type="text" size="4" name="MTU" value="$uplink_info{'MTU'}"></td>
            </tr>
        </table>
EOF
    ,
    _("Use <b>custom</b> MAC address"),
    _("Concentrator name"),
    _("Service name"),
    _("Reconnection timeout"),
    _("MTU"),
    ;
    print get_folding();
}

sub show_uplink() {
    openeditorbox(_("Create an uplink"), _("Uplink editor"), $display{'uplinkeditor'}, "createuplink", @errormessages);

    printf <<EOF
EOF
    ,
    ;
    if ($uplink ne "main") {
        printf <<EOF
        <input type="hidden" name="ACTION" value="save" />
        <table width="100%">
            <tr>
                <td style="width: 100px;">%s</td>
                <td>
                    <input class="form" type="text" name="NAME" value="$par{'NAME'}"/>
                    <input class="form" type="hidden" name="OLD_NAME" value="$par{'OLD_NAME'}"/>
                    <input class="form" type="hidden" name="ID" value="$par{'ID'}"/>
                </td>
            </tr>
EOF
        ,
        _("Description"),
        ;
    }
    printf <<EOF
            <tr>
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="NETWORK_TYPE" id="type_chooser">
EOF
        ,
        _("Network mode"),
        ;
        foreach my $network_type (keys %network_types) {
            if ($network_type eq $par{'NETWORK_TYPE'}) {
                $selected = "selected=\"selected\"";
            } else {
                undef $selected;
            }
            printf <<EOF
                    <option value="$network_type" $selected>$network_names{$network_type}</option>
EOF
            ,
            ;
        }
        printf <<EOF
                    </select>
                </td>
            </tr>
EOF
    ,
    ;
    foreach my $network_type (keys %network_types) {
        if ($#{$network_types{$network_type}} > 0) {
            printf <<EOF
            <tr class="redtype $network_type">
                <td style="width: 100px;">%s *</td>
                <td>
                    <select class="form" name="RED_TYPE" id="type_chooser">
EOF
            ,
            _("Uplink type"),
            ;
            foreach $type (@{$network_types{$network_type}}) {
                if ($type eq $par{'RED_TYPE'}) {
                    $selected = "selected=\"selected\"";
                } else {
                    undef $selected;
                }
                printf <<EOF
                        <option value="$type" $selected>$red_names{$type}</option>
EOF
                ,
                ;
            }
            printf <<EOF
                    </select>
                </td>
            </tr>
EOF
            ,
            ;
        }
    }
    printf <<EOF
        </table>
        <hr size="1" color="#cccccc">
EOF
    ,
    ;
    show_uplink_types();
    printf <<EOF
    <table width="100%">
        <tr>
            <td style="width: 370px;"><input class="form" type="checkbox" style="margin:0px;" name="ENABLED" $checked{'ENABLED'}/>&nbsp;%s</td>
            <td style="width: 15px;"></td>
            <td style="width: 370px;"><input class="form" type="checkbox" style="margin:0px;" name="ONBOOT" $checked{'ONBOOT'} />&nbsp;%s</td>
            <td style="width: 15px;"></td>
        </tr>
        <tr>
            <td style="width: 370px;"><input class="form" type="checkbox" style="margin:0px;" name="MANAGED" $checked{'MANAGED'}/>&nbsp;%s</td>
            <td style="width: 15px;"></td>
            <td style="width: 370px;"><input class="form" type="checkbox" style="margin:0px;" name="DISABLE_SIGNATURE_DOWNLOAD" $checked{'DISABLE_SIGNATURE_DOWNLOAD'} />&nbsp;%s</td>
            <td style="width: 15px;"></td>
        </tr>
    </table>
EOF
    ,
    _("Uplink is enabled"),
    _("Activate uplink on boot"),
    _("Uplink is automatically managed by system"),
    _("Disable signature updates if uplink is online")
    ;

    if (@uplinklist <= 0) {
        $disabled = "disabled=\"disabled\"";
    }
    printf <<EOF
    <hr size="1" color="#cccccc">
    <table width="100%">
        <tr class="column">
            <td colspan="5">
                $uplink
                <input class="form" type="checkbox" style="margin:0px;" name="BACKUPPROFILEACTIVE" $disabled $checked{'BACKUPPROFILEACTIVE'} />
                &nbsp;%s
                <select class="form" name="BACKUPPROFILE" $disabled>
EOF
    ,
    _("If this uplink <i>fails</i> activate"),
    ;

    foreach $backup (@uplinklist) {
        #if ($backup ne $uplink) {
            foreach $b (@uplinklist) {
                if ($b eq $backup) {
                    %backup_info = get_uplink_info($b);
                }
                if ($backup eq $par{'BACKUPPROFILE'}) {
                    $selected = "selected=\"selected\"";
                    last;
                }
                else {
                    undef $selected;
                }
            }
            printf <<EOF
                        <option value="$backup" $selected>$backup_info{'NAME'} ($backup)</option>
EOF
            ,
            ;
        #}
    }
    printf <<EOF
                    </select>
                </td>
            </tr>
            <tr style="padding-bottom: 0px;">
                <td style="padding-bottom: 0px;"><input class="form" type="checkbox" style="margin:0px;" name="LINKCHECK" $checked{'LINKCHECK'} /> %s</td>
            </tr>
        </table>
        <div id="uplinkcheckhosts" >
            <table>
                <tr style="padding-top: 0px;">
                    <td style="padding-top: 0px;">
                        <textarea class="form" cols="30" rows="3" name="CHECKHOSTS">$par{'CHECKHOSTS'}</textarea>
                    </td>
                </tr>
            </table>
        </div>
        <hr size="1" color="#cccccc"/>
EOF
    ,
    _("Check if these hosts are reachable")
    ;

    show_uplink_advanced();
    printf <<EOF
    </div>
    <input type="hidden" name="createbutton" value="%s" />
    <input type="hidden" name="updatebutton" value="%s" />
    </div>

EOF
    ,
    _("Create Uplink"),
    _("Update Uplink")
    ;

    &closeeditorbox($button, _("Cancel"), "uplinkbutton", "createuplink");
}

sub show_uplinklist() {
    openbox('100%', "center", _("Current uplinks"));
    show_uplink();
    @uplinklist = @{get_uplinks()};
    if (scalar(@uplinklist) >= 0) {
        printf <<EOF
    <table class="ruleslist" id="ruleslist" width="100%" cellspacing="0" cellpadding="0">
        <tr>
            <td class="boldbase">%s</td>
            <td class="boldbase" width="30%">%s</td>
            <td class="boldbase" width="15%">%s</td>
            <td class="boldbase" width="30%">%s</td>
            <td class="boldbase" width="10%">%s</td>
        </tr>
EOF
        ,
        _("ID"),
        _("Description"),
        _("Type"),
        _("Backup-link"),
        _("Actions"),
        ;
        $count = 0;
        foreach $uplink (@uplinklist) {
            %uplink_info = get_uplink_info($uplink);
            
            if ($uplink_info{'RED_TYPE'} eq "NONE") {
                $uplink_info{'NETWORK_TYPE'} = "NOUPLINK";
            } elsif ($uplink_info{'RED_TYPE'} eq "STEALTH") {
                $uplink_info{'STEALTH_DEV'} = $uplink_info{'RED_DEV'};
                $uplink_info{'NETWORK_TYPE'} = "BRIDGED";
            } else {
                $uplink_info{'NETWORK_TYPE'} = "ROUTED";
            }
            
            my ($primary, $ip, $mask, $cidr) = getPrimaryIP($uplink_info{'RED_IPS'});
            $uplink_info{'RED_ADDRESS'} = $ip;
            $uplink_info{'RED_NETMASK'} = $mask;
            $uplink_info{'CIDR'} = $cidr;
            $uplink_info{'MACACTIVE'} = $uplink_info{'MAC'} eq "" ? "" : "on";
            if ($uplink_info{'RED_TYPE'} eq "STATIC" || $uplink_info{'RED_TYPE'} eq "PPTP") {
                $uplink_info{'RED_IPS'} = getAdditionalIPs($uplink_info{'RED_IPS'});
            }
            if ($uplink_info{'RED_TYPE'} eq "PPTP") {
                $uplink_info{'TELEPHONE'} = $uplink_info{'PHONENUMBER'};
            }
            if ($uplink_info{'RED_TYPE'} eq "ISDN") {
                $uplink_info{'ISDN_TYPE'} = $uplink_info{'TYPE'};
            }
            my $enabled_gif = $DISABLED_PNG;
            my $enabled_alt = _('Disabled (click to enable)');
            my $enabled_action = 'enable';
            if ($uplink_info{'ENABLED'} eq 'on') {
                $enabled_gif = $ENABLED_PNG;
                $enabled_alt = _('Enabled (click to disable)');
                $enabled_action = 'disable';
            }
            if ( $count % 2 eq 1 ) {
                $color = "even";
            }
            else {
                $color = "odd";
            }
            $count++;

            printf <<EOF
        <tr class="$color" id="row_$uplink">
            <td>$uplink</td>
            <td>$uplink_info{'NAME'}</td>
            <td>$red_names{$uplink_info{'RED_TYPE'}}</td>
            <td>$uplink_info{'BACKUPPROFILENAME'}</td>
            <td class="actions">
                <form method="post" action="$ENV{'SCRIPT_NAME'}" style="float:left">
                  <input class='imagebutton' type='image' name="submit" src="$enabled_gif" alt="$enabled_alt" />
                  <input TYPE="hidden" name="ACTION" value="$enabled_action">
                  <input TYPE="hidden" name="ID" value="$uplink">
                  <input class="form" type="hidden" name="OLD_RED_TYPE" value="$par{'OLD_RED_TYPE'}" />
                </form>
                <input class="imagebutton" type="image" name="edituplink" value="$uplink" src="$EDIT_PNG" alt="%s" title="%s" />
                <input type="hidden" class="$uplink" name="rowcolor" value="$color" />
EOF
            ,
            _("Edit"),
            _("Edit uplink"),
            ;
            for $key (keys %uplink_info) {
                if ($key eq "DNS") {
                    if ($uplink_info{$key} eq "Automatic") {
                        $uplink_info{$key} = "off";
                    }
                    else {
                        $uplink_info{$key} = "on";
                    }
                }
                printf <<EOF
                <input type="hidden" class="$uplink" name="$key" value="$uplink_info{$key}" />
EOF
                ;
            }

            if ($uplink ne "main") {
                printf <<EOF
                <form enctype="multipart/form-data" method="post" onsubmit="return confirm('%s');" action="$ENV{SCRIPT_NAME}">
                    <input type="hidden" name="ACTION" value="delete" />
                    <input type="hidden" name="ID" value="$uplink" />
                    <input class="imagebutton" type="image" name="submit" src="$DELETE_PNG" alt="%s" title="%s" />
                </form>
EOF
                ,
                _("Do you really want to delete this uplink?"),
                _("Remove"),
                _("Remove uplink"),
                ;
            }
            printf <<EOF
            </td>
        </tr>
        <tr>
            <td colspan="8" id="td_$uplink" style="padding:0px;border: 0px;">
EOF
            ,

            ;
            printf <<EOF
                </div>
            </td>
        </tr>
EOF
            ,
            ;
        }
        printf <<EOF
    </table>
    <input type="hidden" name="default_checkhosts" value="" />
EOF
        ;
        printf <<EOF
    <div  style="text-align: left;">
    <table>
        <tr>
            <td class="boldbase">&nbsp; <b>%s:</b></td>
            <td>&nbsp;<IMG SRC="$ENABLED_PNG" alt="%s" /></td>
            <td class="base">%s</td>
            <td>&nbsp;&nbsp;<IMG SRC='$DISABLED_PNG' ALT="%s" /></td>
            <td class="base">%s</td>
            <td>&nbsp; &nbsp; <img src='$EDIT_PNG' alt="%s" /></td>
            <td class="base">%s</td>
            <td>&nbsp; &nbsp; <img src="$DELETE_PNG" alt="%s" /></td>
            <td class="base">%s</td>
        </tr>
    </table>
    </div>
EOF
        ,
        _('Legend'),
        _('Enabled (click to disable)'),
        _('Enabled (click to disable)'),
        _('Disabled (click to enable)'),
        _('Disabled (click to enable)'),
        _('Edit'),
        _('Edit'),
        _('Delete'),
        _('Delete'),
        ;
    }
    else {
        printf <<EOF
    <table>
        <tr>
            <td><i>%s</></td>
        </tr>
    </table>
EOF
        ,
        _("No uplinks available"),
        ;
    }
    &closebox();
}

sub reload_par() {
    getcgihash( \%par );
    if ($par{'BACKUPPROFILEACTIVE'} ne "on") {
        $par{'BACKUPPROFILE'} = "";
    }
    $par{'RED_IPS'} =~ s/,/\n/g;
    $par{'CHECKHOSTS'} =~ s/,/\n/g;
    @uplinklist = @{get_uplinks()};
}


$notification = "";

&showhttpheaders();
reload_par();

for my $uplink (@uplinklist) {
    my %tmp = get_uplink_info($uplink); #check if maximum amount of the red_type is reached
    $uplink_networks{$uplink} = $tmp{'RED_IPS'};
    if ($tmp{'ENABLED'} eq "on") {  #check which devices are already used
        if (($tmp{'RED_TYPE'} eq "STATIC") || ($tmp{'RED_TYPE'} eq "DHCP") || ($tmp{'RED_TYPE'} eq "PPPOE") || ($tmp{'RED_TYPE'} eq "PPTP")) {
            $device_used{$tmp{'RED_DEV'}} = $uplink;
        }
    } else {
        next;
    }
    if ($allow{$tmp{'RED_TYPE'}} > 0) {
        $allow{$tmp{'RED_TYPE'}}--;
    }
}

&openpage(_('Uplinks configuration'), 1, $refresh);

if ( $par{'ACTION'} eq "save" ) {
# ----------------------------------------------------------------
# save uplink
# ----------------------------------------------------------------
    save_uplink();
    reload_par();
}
elsif ( $par{'ACTION'} eq "enable" ) {
# ----------------------------------------------------------------
# enable uplink
# ----------------------------------------------------------------
    toggle_enable($par{'ID'}, 1);
    reload_par();
}
elsif ( $par{'ACTION'} eq "disable" ) {
# ----------------------------------------------------------------
# disable uplink
# ----------------------------------------------------------------
    toggle_enable($par{'ID'}, 0);
    reload_par();
}
elsif ( $par{'ACTION'} eq "delete" ) {
# ----------------------------------------------------------------
# delete uplink
# ----------------------------------------------------------------
    delete_uplink($par{'ID'});
    reload_par();
}

if ($notification ne "") {
    notificationbox($notification);
}
&readhash("/etc/uplinksdaemon/uplinksdaemon.conf", \%default);

get_uplink_display();

show_uplinklist();

&closepage();
