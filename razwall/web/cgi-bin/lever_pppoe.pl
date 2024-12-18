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

require 'modemtools.pl';
require 'razinc.pl';
require 'wantools.pl';

my %substeps = ();
my $session = 0;
my $settings = 0;
my $par = 0;
my $tpl_ph = 0;
my $live_data = 0;

my %substeps = (
		1 => _('supply connection information')
		);
my $substepnum = scalar(keys(%substeps));

my @pppoe_keys=(
		'DNS',
		'TYPE',
		'MAXRETRIES',

		'MTU',

        'WAN_IPS',

		'DNS1',
		'DNS2',
		'RECONNECTION',
		'TIMEOUT',

		'AUTH',
		'SERVICENAME',
		'CONCENTRATORNAME',
		'USERNAME',
		'PASSWORD',

		'BACKUPPROFILE',
		'ENABLED',
		'WAN_DEV',
		'WAN_TYPE',

		'CHECKHOSTS',
		'AUTOSTART',
		'ONBOOT',
		'MANAGED',

		);

sub lever_init($$$$$) {
    $session = shift;
    $settings = shift;
    $par = shift;
    $tpl_ph = shift;
    $live_data = shift;

    init_ifacetools($session, $par);
    init_modemtools($session);
}


sub lever_load() {
    process_ppp_values($session, 0);
    return;
}


sub lever_prepare_values() {

    my $step = $live_data->{'step'};
    my $substep = $live_data->{'substep'};

    $tpl_ph->{'subtitle'} = _('Substep')." $substep/$substepnum: ".$substeps{$substep};

    if ($substep eq '1') {
        if ($session->{'DNS'} eq "Automatic") {
            $session->{'DNS_N'} = '0';
        }
        else {
            $session->{'DNS_N'} = '1';
        }
	$tpl_ph->{'IFACE_WAN_LOOP'} = create_ifaces_list('WAN');
	$tpl_ph->{'DISPLAY_WAN_ADDITIONAL'} = $session->{'WAN_IPS'};
	$tpl_ph->{'DISPLAY_WAN_ADDITIONAL'} =~ s/,/\n/g;
	return;
    }

    return;
}

sub lever_savedata() {
    my $step = $live_data->{'step'};
    my $substep = $live_data->{'substep'};

    my $ret = '';

    if ($substep eq '0') {
	die('invalid transition. step has no substeps');
    }

    if ($substep eq '1') {

	my $ifacelist = ifnum2device($par->{'WAN_DEVICES'});
	my $reterr = check_iface_free($ifacelist, 'WAN');
	if ($reterr) {
	    $ret .= $reterr;
	} else {
	    $session->{'WAN_DEVICES'} = $ifacelist;
	}
        if ($ifacelist =~ /^$/) {
            my $zone = _('WAN');
	    $err .= _('Please select at least one interface for zone %s!', $zone).'<BR><BR>';
        }

	if ($par->{'SERVICENAME'} ne '') {
	    $session->{'SERVICENAME'} = $par->{'SERVICENAME'};
	} else {
	    $session->{'SERVICENAME'} = '__EMPTY__';
	}
	if ($par->{'CONCENTRATORNAME'} ne '') {
	    $session->{'CONCENTRATORNAME'} = $par->{'CONCENTRATORNAME'};
	} else {
	    $session->{'CONCENTRATORNAME'} = '__EMPTY__';
	}
	my ($ok_ips, $nok_ips) = createIPS("", $par->{'DISPLAY_WAN_ADDITIONAL'});
	if ($nok_ips eq '') {
	    $session->{'WAN_IPS'} = $ok_ips;
	} else {
	    foreach my $nokip (split(/,/, $nok_ips)) {
		$ret .= _('The WAN IP address or network mask "%s" is not correct.', $nokip).'<BR>';
	    }
	}
	if ($par->{'USERNAME'} eq '') {
	    $ret .= _('you must supply a username for the authentication on your provider');
	}
	if ($par->{'PASSWORD'} eq '') {
	    $ret .= _('you must supply a password for the authentication on your provider');
	}
	$session->{'USERNAME'} = $par->{'USERNAME'};
	$session->{'PASSWORD'} = $par->{'PASSWORD'};

	$session->{'AUTH_N'} = $par->{'AUTH_N'};
	$session->{'DNS_N'} = $par->{'DNS_N'};

        if ($par->{'MTU'} !~ /^$/) {
            if ($par->{'MTU'} !~ /^\d+$/) {
                $err .= _('The MTU value "%s" is invalid! Must be numeric.', $par->{'MTU'}).'<BR><BR>';
            }
  	    $session->{'MTU'} = $par->{'MTU'};
        } else {
  	    $session->{'MTU'} = '__EMPTY__';
        }

	set_wan_default("");

	return $ret;
    }

    return $ret;
}

sub alter_ppp_settings($) {
    my $ref = shift;
    my %config = %$ref;

    $config{'AUTH'} = get_auth_value($session->{'AUTH_N'});
    $config{'DNS'} = get_dns_value($session->{'DNS_N'});
    $config{'TYPE'} = 'pppoe';
    # set maxretries
    $config{'MAXRETRIES'} = 5;
    return \%config;
}


sub lever_apply() {
    $session->{'WAN_DEV'} = pick_device($session->{'WAN_DEVICES'});

    my $ppp_settings = alter_ppp_settings(select_from_hash(\@pppoe_keys, $session));
    save_wan('main', $ppp_settings);
    return;
}


sub lever_check_substep() {
    return defined($substeps{$live_data->{'substep'}});
}


1;

