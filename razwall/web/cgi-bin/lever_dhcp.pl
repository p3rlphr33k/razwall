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

require 'razinc.pl';
require 'wantools.pl';

my %substeps = ();
my $session = 0;
my $settings = 0;
my $par = 0;
my $tpl_ph = 0;
my $live_data = 0;


my %substeps = (
		1 => _('Internet access preferences'),
		);
my $substepnum = scalar(keys(%substeps));

my @static_keys=(
		 'DNS1',
		 'DNS2',

		 'MTU',
                 'MAC',

		 'BACKUPPROFILE',
		 'ENABLED',
		 'WAN_TYPE',
		 'WAN_DEV',
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
    init_wantools($session, $settings);
}


sub lever_load() {
    return;
}


sub lever_prepare_values() {
    my $step = $live_data->{'step'};
    my $substep = $live_data->{'substep'};

    $tpl_ph->{'subtitle'} = _('Substep')." $substep/$substepnum: ".$substeps{$substep};

    if ($substep eq '1') {
	if ($session->{'DNS1'} =~ /^$/) {
	    $session->{'DNS_N'} = '0';
	} else {
	    $session->{'DNS_N'} = '1';
	}
	$tpl_ph->{'IFACE_WAN_LOOP'} = create_ifaces_list('WAN');
	return;
    }
    return;
}

sub lever_savedata() {
    my $step = $live_data->{'step'};
    my $substep = $live_data->{'substep'};

    my $err = "";

    if ($substep eq '0') {
	die('invalid transition. step has no substeps');
    }
    if ($substep eq '1') {
	$session->{'DNS_N'} = $par->{'DNS_N'};
	
	my $ifacelist = ifnum2device($par->{'WAN_DEVICES'});
	my $reterr = check_iface_free($ifacelist, 'WAN');
    	if ($reterr) {
	    $err .= $reterr;
    	} else {
	    $session->{'WAN_DEVICES'} = $ifacelist;
	}
        if ($ifacelist =~ /^$/) {
            my $zone = _('WAN');
	    $err .= _('Please select at least one interface for zone %s!', $zone).'<BR><BR>';
        }
        if ($par->{'MTU'} !~ /^$/) {
            if ($par->{'MTU'} !~ /^\d+$/) {
                $err .= _('The MTU value "%s" is invalid! Must be numeric.', $par->{'MTU'}).'<BR><BR>';
            }
  	    $session->{'MTU'} = $par->{'MTU'};
        } else {
  	    $session->{'MTU'} = '__EMPTY__';
        }

        if ($par->{'MAC'} !~ /^$/) {
            if (! validmac($par->{'MAC'})) {
                $err .= _('The MAC address "%s" is invalid. Correct format is: xx:xx:xx:xx:xx:xx!', $par->{'MAC'});
            }
            $session->{'MAC'} = $par->{'MAC'};
        } else {
  	    $session->{'MAC'} = '__EMPTY__';
        }
    }
    return $err;
}

sub lever_apply() {
    $session->{'WAN_DEV'} = pick_device($session->{'WAN_DEVICES'});
    if ($session->{'DNS_N'} == 0) {
	$session->{'DNS1'} = "";
	$session->{'DNS2'} = "";
    }
    save_wan('main', select_from_hash(\@static_keys, $session));
    return;
}

sub lever_check_substep() {
    return defined($substeps{$live_data->{'substep'}});
}


1;

