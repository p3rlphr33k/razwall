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
use Data::Dumper;

require '/razwall/web/cgi-bin/ifacetools.pl';
require '/razwall/web/cgi-bin/modemtools.pl';
require '/razwall/web/cgi-bin/redtools.pl';

my %substeps = ();
my $session = 0;
my $settings = 0;
my $par = 0;
my $tpl_ph = 0;
my $live_data = 0;

my %substeps = (
        1 => _('Choose modem'),
        2 => _('Supply connection information')
        );
my $substepnum = scalar(keys(%substeps));

my @modem_keys=(

        # Red type --> MODEM
        'RED_TYPE',

        # ModemManager variables
        'MM_MODEM',
        'MM_MODEM_TYPE',
        'MM_PROVIDER_COUNTRY',
        'MM_PROVIDER_PROVIDER',

        # AUTH
        'USERNAME',
        'PASSWORD',
        'AUTH',

        # DNS
        'DNS',
        'DNS1',
        'DNS2',

        # GSM/UMTS/HDSPA/LTE Modems
        'MM_PROVIDER_APN',
        'APN',

        # CDMA

        'RED_IPS',
        'MTU',

        # POTS
        'SPEED',
        'TELEPHONE',

        # Uplinksdaemon variables
        'BACKUPPROFILE',
        'ENABLED',
        'CHECKHOSTS',
        'AUTOSTART',
        'ONBOOT',
        'MANAGED',

        );

sub mm_debug($) {
    my $msg = shift;
    my $filename = '/tmp/ddd';
    open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
    say $fh "$msg\n";
    close $fh;
}

sub load_speeds() {
    my $index = 0;
    my @speeds = ();
    my $i = 0;

    my %hash = (
    'CONF_SPEED_LOOP_INDEX' => $i++,
    'CONF_SPEED_LOOP_NAME' => 'none',
    'CONF_SPEED_LOOP_CAPTION' => _('select a baud rate'),
    'CONF_SPEED_LOOP_SELECTED' => ($session->{'TYPE'} eq 'none' ? 'selected' : '')
    );
    push(@speedconf, \%hash);

    my @speeds = ('300', '1200', '2400', '4800', '9600', '19200', '38400', '57600', '115200', '230400', '460800', '921600');
    my $sel = 0;

    my $selection = $session->{'SPEED'};
    if (($selection =~ /^$/) && ($session->{'MODEMTYPE'} =~ /^(?:hsdpa|cdma)$/)) {
    $selection = '460800';
    }

    foreach my $speed (@speeds) {
    my $selected = '';
    if ($selection eq $speed) {
        $selected = 'selected';
    }
    my %item = (
        'CONF_SPEED_LOOP_INDEX' => $i++,
        'CONF_SPEED_LOOP_NAME' => $speed,
        'CONF_SPEED_LOOP_CAPTION' => $speed,
        'CONF_SPEED_LOOP_SELECTED' => $selected
        );
    push(@speedconf, \%item);
    }
    close(FILE);
    return \@speedconf;
}


sub lever_init($$$$$) {
    $session = shift;
    $settings = shift;
    $par = shift;
    $tpl_ph = shift;
    $live_data = shift;
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
        return;
    }

    if ($substep eq '2') {
        $session->{'DNS_N'} = '0';
        $tpl_ph->{'DISPLAY_RED_ADDITIONAL'} = $session->{'RED_IPS'};
        $tpl_ph->{'DISPLAY_RED_ADDITIONAL'} =~ s/,/\n/g;
        $tpl_ph->{'CONF_SPEED_LOOP'} = load_speeds();

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
        if ($par->{'MM_MODEM'} eq '') {
            return _('you need to select a modem');
        }
        $session->{'MM_MODEM'} = $par->{'MM_MODEM'};
        $session->{'MM_MODEM_TYPE'} = $par->{'MM_MODEM_TYPE'};
    }

    if ($substep eq '2') {
        my %checked = ();
        $checked{0} = 'off';
        $checked{1} = 'on';

        $session->{'AUTH_N'} = $par->{'AUTH_N'};

    if ($par->{'USERNAME'} ne '') {
        $session->{'USERNAME'} = $par->{'USERNAME'};
    } else {
        $session->{'USERNAME'} = '__EMPTY__';
    }
    if ($par->{'PASSWORD'} ne '') {
        $session->{'PASSWORD'} = $par->{'PASSWORD'};
    } else {
        $session->{'PASSWORD'} = '__EMPTY__';
    }

        $session->{'DNS_N'} = $par->{'DNS_N'};
        $session->{'DNS1'} = $par->{'DNS1'};
        $session->{'DNS2'} = $par->{'DNS2'};

        if ($par->{'MTU'} !~ /^$/) {
            if ($par->{'MTU'} !~ /^\d+$/) {
                $ret .= _('The MTU value "%s" is invalid! Must be numeric.', $par->{'MTU'}).'<BR><BR>';
            }
            $session->{'MTU'} = $par->{'MTU'};
        } else {
            $session->{'MTU'} = '__EMPTY__';
        }

        if ($session->{'MM_MODEM_TYPE'} eq "POTS") {
            if ($par->{'TELEPHONE'} !~ /^\d*$/) {
                $ret .= _('invalid phone number');
            }
            $session->{'TELEPHONE'} = $par->{'TELEPHONE'};
        }

        if ($session->{'MM_MODEM_TYPE'} eq "GSM") {
            if ($par->{'APN'} !~ /^[a-zA-Z]{1,1}[a-zA-Z0-9\.\-\_]{1,255}[a-zA-Z0-9]{1,1}$/) {
                $ret .= _('The APN host "%s" is invalid! Must be a hostname.', $par->{'APN'}).'<BR><BR>';
            }
            $session->{'APN'} = $par->{'APN'};
            $session->{'MM_PROVIDER_COUNTRY'} = $par->{'MM_PROVIDER_COUNTRY'};
            $session->{'MM_PROVIDER_PROVIDER'} = $par->{'MM_PROVIDER_PROVIDER'};
            $session->{'MM_PROVIDER_APN'} = $par->{'MM_PROVIDER_APN'};
        }

        if ($session->{'MM_MODEM_TYPE'} eq "CDMA") {
            $session->{'APN'} = "__EMPTY__";
            $session->{'MM_PROVIDER_COUNTRY'} = $par->{'MM_PROVIDER_COUNTRY'};
            $session->{'MM_PROVIDER_PROVIDER'} = $par->{'MM_PROVIDER_PROVIDER'};
        }

        my ($ok_ips, $nok_ips) = createIPS("", $par->{'DISPLAY_RED_ADDITIONAL'});
        if ($nok_ips eq '') {
            $session->{'RED_IPS'} = $ok_ips;
        } else {
            foreach my $nokip (split(/,/, $nok_ips)) {
              $ret .= _('The RED IP address or network mask "%s" is not correct.', $nokip).'<BR>';
            }
        }

        return $ret;
    }

    return $ret;
}

sub alter_ppp_settings($) {
    my $ref = shift;
    my %config = %$ref;

    $config{'AUTH'} = get_auth_value($session->{'AUTH_N'});
    $config{'DNS'} = get_dns_value($session->{'DNS_N'});


    mm_debug("------------------");
    mm_debug("config");
    mm_debug(Dumper($config));
    mm_debug("------------------");
    return \%config;
}


sub lever_apply() {
    mm_debug("------------------");
    mm_debug("session lever_apply");
    mm_debug(Dumper($session));
    mm_debug("------------------");
    my $ppp_settings = alter_ppp_settings(select_from_hash(\@modem_keys, $session));
    if ($session->{'DNS_N'} == 0) {
        $session->{'DNS1'} = "";
        $session->{'DNS2'} = "";
    }
    mm_debug("------------------");
    mm_debug("ppp_settings");
    mm_debug(Dumper($ppp_settings));
    mm_debug("------------------");
    save_red('main', $ppp_settings);
    return;
}


sub lever_check_substep() {
    return defined($substeps{$live_data->{'substep'}});
}


1;

