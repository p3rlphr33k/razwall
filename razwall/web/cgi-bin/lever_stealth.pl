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

my %zones = (
    'LAN' => _('LAN'),
    'LAN2' => _('LAN2'),
    'DMZ' => _('DMZ'),
    );

my @static_keys=(
         'DNS1',
         'DNS2',

         'ENABLED',
         
         'WAN_DEV',
         'DEFAULT_GATEWAY',
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
    init_wantools($session, $settings);
}


sub lever_load() {
    return;
}


sub enable_zones_with_min_two_ifaces($) {
    my $ifaces = shift;
    my %ifacesnr;

    foreach my $zone (@zones) {
        if ($session->{$zone.'_DEVICES'} eq 'unset') {
            $ifacesnr{$zone} = 0;
            next;
        }
        my @ifaces = split(/\|/, $session->{$zone.'_DEVICES'});
        $ifacesnr{$zone} = $#ifaces+1;
    }

    my $wan_dev = pick_device($session->{'WAN_DEVICES'});
    foreach my $item (@$ifaces) {
        my $selected = $item->{'DEV_LOOP_SELECTED'};
        my $checked = $item->{'DEV_LOOP_CHECKED'};
        my $disabled = '';

        my $zone = $item->{'DEV_LOOP_ZONE'};
        if ($ifacesnr{$zone} < 2) {
            $disabled = 'disabled';
            $selected = '';
            $checked = '';
        }
        elsif ($wan_dev eq $item->{'DEV_LOOP_DEVICE'}) {
            $selected = 'selected';
            $checked = 'checked';
        }

        $item->{'DEV_LOOP_DISABLED'} = $disabled;
        $item->{'DEV_LOOP_CHECKED'} = $checked;
        $item->{'DEV_LOOP_SELECTED'} = $selected;
    }
}

sub lever_prepare_values() {

    my $step = $live_data->{'step'};
    my $substep = $live_data->{'substep'};

    $tpl_ph->{'subtitle'} = _('Substep')." $substep/$substepnum: ".$substeps{$substep};

    if ($substep eq '1') {
        $session->{'DNS_N'} = '1';
        $ifaces = create_ifaces_list('');
        enable_zones_with_min_two_ifaces($ifaces);
        $tpl_ph->{'IFACE_WAN_LOOP'} = $ifaces;
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

        if ($session->{'ASK_DNSMANUAL'}) {
            $session->{'DNS_N'} = $par->{'DNS_N'};
        }

        my $ifacelist = ifnum2device($par->{'WAN_DEVICES'});
            if ($ifacelist =~ /^$/) {
                my $zone = _('WAN');
            $err .= _('Please select at least one interface for zone %s!', $zone).'<BR><BR>';
            }

        if ($err ne '') {
            return $err;
        }

        ($valid, $ip, $mask) = check_ip($par->{'DEFAULT_GATEWAY'}, '255.255.255.255');
        if ($valid) {
            $session->{'DEFAULT_GATEWAY'} = $ip;
        } else {
            $err .= _('The gateway address is not correct.').'<BR>';
        }

        if ($err ne '') {
            return $err;
        }

        my $selected_device = getifbynum(pick_device($par->{'WAN_DEVICES'}))->{'device'};
        $session->{'WAN_DEVICES'} = $selected_device;

        my $gwzone = getzonebyiface($selected_device);
        if (! network_overlap($session->{$gwzone.'_IPS'}, $session->{'DEFAULT_GATEWAY'}. '/32')) {
            $err .= _('Gateway must be within %s network.', $zones{$gwzone}).'<BR>';
        }
        return $err;
    }

    return $err;
}

sub lever_apply() {
    $session->{'WAN_DEV'} = pick_device($session->{'WAN_DEVICES'});
    save_wan('main', select_from_hash(\@static_keys, $session));
    return;
}

sub lever_check_substep() {
    return defined($substeps{$live_data->{'substep'}});
}


1;

