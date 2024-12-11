#!/usr/bin/perl
#
# HTTP Proxy CGI for Endian Firewall
#
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

# -------------------------------------------------------------
# some definitions
# -------------------------------------------------------------
require 'header23.pl';
require './endianinc.pl';

$flagdir                = "${swroot}/proxy";
$proxyrestart           = "$flagdir/restartproxy";
$proxyreload            = "$flagdir/reloadproxy";

$proxy_conffile         = "${swroot}/proxy/settings";

$dg_dir                 = "${swroot}/dansguardian";
$dg_profiledir          = "${dg_dir}/profiles";
$dg_conf                = "${dg_dir}/settings";

$policyrules            = "${swroot}/proxy/policyrules";
$policyrules_default    = "/usr/lib/efw/proxy/policyrules.default";

$contentfilter          = "${swroot}/webfilter/profiles";
$contentfilter_default    = "/usr/lib/efw/webfilter/profiles.default";

$useragent_file        = "/usr/lib/efw/proxy/default/useragents";
$custom_useragent_file = "${swroot}/proxy/useragents";

$ncsauser_file             = "${swroot}/proxy/ncsausers";
$ncsagroup_file            = "${swroot}/proxy/ncsagroups";

$service_restarted = 0;

$notification_script = '<script type="text/javascript">
    var error_view; 
    var notification_view; 
    var warning_view; 
    $(document).ready(function() {' .
        $hide_error . '
        notification_view = setTimeout(function() { $(\'.notification-fancy\').fadeOut(); }, 10000);
        error_view = setTimeout(function() { $(\'.error-fancy\').fadeOut(); }, 10000);
        warning_view = setTimeout(function() { $(\'.warning-fancy\').fadeOut(); }, 10000);
    });
 </script>';

sub read_file($) {
    # read out a file: needed for blacklists
    # attributes: filepath (string)
    # returns: filevalue (string)
    my $file = shift;
    undef $lines;
    open(FILE,"$file");
    while (<FILE>) { $lines .= $_ };
    close(FILE);
    return $lines;
}

sub write_file($$) {
    # writes a string into a file
    # attributes: filepath (string), value of file (string)
    my $file = shift;
    my $value = shift;
    
    open (FILE, ">$file");
    print FILE $value;
    close (FILE);
}

sub read_config_file($$) {
    my $filename = shift;
    my $filename_default = shift;
    my @lines;
    
    if ((! -e $filename) && -e $filename_default) {
        $filename = $filename_default;
    }
    open (FILE, "$filename");
    foreach my $line (<FILE>) {
        chomp($line);
        $line =~ s/[\r\n]//g;
        if (!is_valid($line) && ($filename eq $policyrules || $filename eq $policyrules_default)) {
            next;
        }
        push(@lines, $line);
    }
    close (FILE);
    return @lines;
}

sub read_config_line($$$) {
    my $line = shift;
    my $file = shift;
    my $default_file = shift;
    my @lines;
    @lines = read_config_file($file, $default_file);
    return $lines[$line];
}

sub save_config_file($$) {
    my $ref = shift;
    my $file = shift;
    my @lines = @$ref;
    open (FILE, ">$file");
    foreach my $line (@lines) {
        if ($line ne "") {
            print FILE "$line\n";
        }
    }
    close(FILE);
    $reload = 1;
}

sub line_count($$) {
    $file = shift;
    $default_file = shift;
    if (! -e $file) {
        $file = $default_file;
    }
    open (FILE, "$file") || return 0;
    my $i = 0;
    foreach (<FILE>) {
        $i++;
    }
    close FILE;
    return $i;
}

sub append_config_file($$) {
    my $line = shift;
    my $file = shift;
    open (FILE, ">>$file");
    print FILE $line."\n";
    close FILE;
    $reload = 1;
}

sub is_valid($) {
    my $line = shift;
    if ($line =~ /(?:(?:[^,]*),){9}/) {
        return 1;
    }
    return 0;
}

sub policy_line($) {
    my $line = shift;
    my %config;
    $config{'valid'} = 0;
    if (! is_valid($line)) {
        return;
    }
    my @temp = split(/,/, $line);
    $config{'enabled'} = $temp[0];
    $config{'policy'} = $temp[1];
    $config{'auth'} = $temp[2];
    $config{'auth_group'} = $temp[3];
    $config{'auth_user'} = $temp[4];    
    $config{'time_restriction'} = $temp[5];
    $config{'days'} = $temp[6];
    $config{'starthour'} = $temp[7];
    if ($config{'starthour'} eq "") {
        $config{'starthour'} = "00";
    }
    $config{'startminute'} = $temp[8];
    if ($config{'startminute'} eq "") {
        $config{'startminute'} = "00";
    }
    $config{'stophour'} = $temp[9];
    if ($config{'stophour'} eq "") {
        $config{'stophour'} = "24";
    }
    $config{'stopminute'} = $temp[10];
    if ($config{'stopminute'} eq "") {
        $config{'stopminute'} = "00";
    }
    $config{'filtertype'} = $temp[11];
    $config{'src_type'} = $temp[12];
    $config{'src'} = $temp[13];
    if($config{'src_type'} eq "zone") {
        $config{'src'} =~ s/&/\|/g;
    } else {
        $config{'src'} =~ s/&/\n/g;
    }
    $config{'dst_type'} = $temp[14];
    $config{'dst'} = $temp[15];
    if($config{'dst_type'} eq "zone") {
        $config{'dst'} =~ s/&/\|/g;
    } else {
        $config{'dst'} =~ s/&/\n/g;
    }
    $config{'mimetypes'} = $temp[16];
    $config{'useragents'} = $temp[17];
    $config{'useragents'} =~ s/&/\|/g;    
    $config{'valid'} = 1;
    
    return %config;
}

sub contentfilter_line($) {
    my $line = shift;
    my %config;
    my @temp = split(/,/, $line);
	$config{'id'} = lc $temp[0];
	$config{'id'} =~ s/\s//g;
    $config{'name'} = $temp[0];
    return %config;
}

sub toggle_policy($$) {
    my $line = shift;
    my $enable = shift;
    if ($enable) {
        $enable = 'on';
    }
    else {
        $enable = 'off';
    }
    
    my %data = policy_line(read_config_line($line, $policyrules, $policyrules_default));
    $data{'enabled'} = $enable;
    
    return save_policy($line,
                        $data{'enabled'},
                        $data{'policy'},
                        $data{'auth'},
                        $data{'auth_group'},
                        $data{'auth_user'},
                        $data{'time_restriction'},
                        $data{'days'},
                        $data{'starthour'},
                        $data{'startminute'},
                        $data{'stophour'},
                        $data{'stopminute'},
                        $data{'filtertype'},
                        $data{'src_type'},
                        $data{'src'},
                        $data{'dst_type'},
                        $data{'dst'},
                        $data{'mimetypes'},
                        $data{'useragents'});
}

sub move_policy($$) {
    my $line = shift;
    my $direction = shift;
    my $newline = $line + $direction;
    if ($newline < 0) {
        return;
    }
    my @lines = read_config_file($policyrules, $policyrules_default);

    if ($newline >= scalar(@lines)) {
        return;
    }

    my $temp = $lines[$line];
    $lines[$line] = $lines[$newline];
    $lines[$newline] = $temp;
    save_config_file(\@lines, $policyrules);
}

sub set_policy_position($$) {
    my $old = shift;
    my $new = shift;
    my @lines = read_config_file($policyrules, $policyrules_default);
    my $myline = $lines[$old];
    my @newlines = ();

    # nothing to do
    if ($new == $old) {
        return;
    }
   
    if ($new > $#lines+1) {
        $new = $#lines+1;
    }

    open (FILE, ">$policyrules");

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

sub delete_line($$$) {
    my $line = shift;
    my $file = shift;
    my $default_file = shift;
    my @lines = read_config_file($file, $default_file);
    if (! @lines[$line]) {
        return;
    }
    delete (@lines[$line]);
    save_config_file(\@lines, $file);
}

sub create_policy($$$$$$$$$$$$$$$$$$) {
    my $enabled = shift;
    my $policy = shift;
    my $auth = shift;
    my $auth_group = shift;
    my $auth_user = shift;
    my $time_restriction = shift;
    my $days = shift;
    my $starthour = shift;
    my $startminute = shift;
    my $stophour = shift;
    my $stopminute = shift;
    my $filtertype = shift;
    my $src_type = shift;
    my $src = shift;
    my $dst_type = shift;
    my $dst = shift;
    my $mimetypes = shift;
    my $useragents = shift;
    
    return "$enabled,$policy,$auth,$auth_group,$auth_user,$time_restriction,$days,$starthour,$startminute,$stophour,$stopminute,$filtertype,$src_type,$src,$dst_type,$dst,$mimetypes,$useragents";
}

sub check_policy($$$$$$$$$$$$$$$$$$) {
    my $enabled = shift;
    my $policy = shift;
    my $auth = shift;
    my $auth_group = shift;
    my $auth_user = shift;
    my $time_restriction = shift;
    my $days = shift;
    my $starthour = shift;
    my $startminute = shift;
    my $stophour = shift;
    my $stopminute = shift;
    my $filtertype = shift;
    my $src_type = shift;
    my $src = shift;
    my $dst_type = shift;
    my $dst = shift;
    my $mimetypes = shift;
    my $useragents = shift;
    
    return 1;
}

sub save_policy($$$$$$$$$$$$$$$$$$$) {
    my $line = shift;
    my $enabled = shift;
    my $policy = shift;
    my $auth = shift;
    my $auth_group = shift;
    my $auth_user = shift;
    my $time_restriction = shift;
    my $days = shift;
    my $starthour = shift;
    my $startminute = shift;
    my $stophour = shift;
    my $stopminute = shift;
    my $filtertype = shift;
    my $src_type = shift;
    my $src = shift;
    my $dst_type = shift;
    my $dst = shift;
    my $mimetypes = shift;
    my $useragents = shift;
    
    $src =~ s/\n/&/gm;
    $src =~ s/\r//gm;
    $dst =~ s/\n/&/gm; 
    $dst =~ s/\r//gm;
    if ($src_type eq "mac") {
        $src =~ s/\-/:/g;
    }
    elsif($src_type eq "zone") {
        $src =~ s/\|/&/g;
    }
    if($dst_type eq "zone") {
        $dst =~ s/\|/&/g;
    }
    
    $mimetypes =~ s/\n/&/gm;
    $mimetypes =~ s/\r//gm;
    
    $useragents =~ s/\|/&/g;
        
    if (! check_policy($enabled,$policy,$auth,$auth_group,$auth_user,$time_restriction,$days,$starthour,$startminute,$stophour,$stopminute,$filtertype,$src_type,$src,$dst_type,$dst,$mimetypes,$useragents)) {
        return 0;
    }

    my $tosave = create_policy($enabled,$policy,$auth,$auth_group,$auth_user,$time_restriction,$days,$starthour,$startminute,$stophour,$stopminute,$filtertype,$src_type,$src,$dst_type,$dst,$mimetypes,$useragents);

    if ($line !~ /^\d+$/) {
        append_config_file($tosave, $policyrules);
        return 1;
    }
    my @lines = read_config_file($policyrules, $policyrules_default);
    if (! $lines[$line]) {
        push(@errormessages, _('Configuration line not found!'));
        return 0;
    }

    my %split = policy_line($lines[$line]);
    if (($split{'enabled'} ne $enabled) ||
            ($split{'policy'} ne $policy) ||
            ($split{'auth'} ne $auth) ||
            ($split{'auth_group'} ne $auth_group) ||
            ($split{'auth_user'} ne $auth_user) ||
            ($split{'time_restriction'} ne $time_restriction) ||
            ($split{'days'} ne $days) ||
            ($split{'starthour'} ne $starthour) ||
            ($split{'startminute'} ne $startminute) ||
            ($split{'stophour'} ne $stophour) ||
            ($split{'stopminute'} ne $stopminute) ||
            ($split{'filtertype'} ne $filtertype) ||
            ($split{'src_type'} ne $src_type) ||
            ($split{'src'} ne $src) ||
            ($split{'dst_type'} ne $dst_type) ||
            ($split{'dst'} ne $dst) ||
            ($split{'mimetypes'} ne $mimetypes) ||
            ($split{'useragents'} ne $useragents)) {
        $lines[$line] = $tosave;
        save_config_file(\@lines, $policyrules);
    }
    return 1;
}

sub create_group($$) {
    my $group = shift;
    my $users = shift;
    
    return "$group,$users";
}

sub group_line($) {
    my $line = shift;
    my %config;

    my @temp = split(/,/, $line);
    $config{'group'} = $temp[0];
    $config{'users'} = $temp[1];
    $config{'users'} =~ s/&/\|/g;
    
    return %config;
}

sub save_group($$$) {
    my $line = shift;
    my $group = shift;
    my $users = shift;

    my $tosave = create_group($group,$users);
    
    if ($line !~ /^\d+$/) {
        append_config_file($tosave, $ncsagroup_file);
        return 1;
    }
    my @lines = read_config_file($ncsagroup_file, 0);
    if (! $lines[$line]) {
        push(@errormessages, _('Configuration line not found!'));
        return 0;
    }

    my %split = group_line($lines[$line]);
    if (($split{'group'} ne $group) ||
            ($split{'users'} ne $users)) {
        $lines[$line] = $tosave;
        save_config_file(\@lines, $ncsagroup_file);
    }
    return 1;
}

sub user_line($) {
    my $line = shift;
    my %config;

    my @temp = split(/:/, $line);
    $config{'user'} = @temp[0];
    $config{'pass'} = @temp[1];
    
    return %config;
}

sub save_user($$$$) {
    my $line = shift;
    my $user = shift;
    my $pass = shift;
    my $use_md5 = shift;
    
    my $tosave = "";
    
    $user = lc $user;

    if ($pass eq 'lEaVeAlOnE') {
        my %userinfo = user_line(read_config_line($line, $ncsauser_file, 0));
        $pass = $userinfo{'pass'};
        $tosave = $user . ":" . $pass;
    }
    else {
        my $md5_opt = '';
        if ($use_md5) {
            $md5_opt = '-m';
        }

        my $create = "";
        unless (-f "$ncsauser_file") {
            $create = "-c"; 
        }
        if ($line ne "") {
            delete_line($line, $ncsauser_file, 0);
        }
        system("/usr/bin/htpasswd $create $md5_opt -b $ncsauser_file \"$user\" \"$pass\"");
        return 1;
    }
    
    my @lines = read_config_file($ncsauser_file, 0);
    if (! $lines[$line]) {
        push(@errormessages, _('Configuration line not found!'));
        return 0;
    }
    
    my %split = user_line($lines[$line]);
    if (($split{'user'} ne $user) ||
            ($split{'pass'} ne $pass)) {
        $lines[$line] = $tosave;
        save_config_file(\@lines, $ncsauser_file);
    }
    return 1;
}

sub save_settings($$$) {
    # save settings to config files
    # attributes:
    #     default settings (hash reference)
    #     current settings (hash reference)
    #     params which should be saved (hash reference)
    #     checkboxes inside the form you want to save (array reference)
    
    my $conf_ref = shift;
    my $params_ref = shift;
    my $checkboxes_ref = shift; #needed because otherwhise we do not know when a checkbox is unchecked
    
    my %conf = %$conf_ref;
    my %params = %$params_ref;
    my @checkboxes = @$checkboxes_ref;
        
    foreach $checkbox (@checkboxes) {
        if (!exists $params{$checkbox}) {
            $params{$checkbox} = "off";
            next;
        }
    }
    
    my $changed = 0;
    while(($key, $value) = each(%params)) {
        # check if key needs to be saved
        $value =~ s/\r\n/,/g;
        $value =~ s/\n/,/g;
        $value =~ s/\r/,/g;
        
        if (!exists $conf{$key}) {
            next;
        }
        my $next = 0;
        if ($next eq 1) {
            next;
        }
        # check if key changed
        if ($conf{$key} eq $value) {
            next;
        }
        $changed = 1;
        
        $conf{$key} = $value;
    }
    
    writehash($proxy_conffile, \%conf);
    
    return $changed;
}

sub reload_par() {
## -------------------------------------------------------------
## get settings and CGI parameters
## -------------------------------------------------------------
    my %conf = ();
    
    &readhash( "$proxy_conffile", \%conf );
    return \%conf;
}

sub joindomain() {
    system('/usr/local/bin/restartdnsmasq &>/dev/null'); # restart dns masq to be shure that all custom dns server are known by the service
    system('/usr/local/bin/restartsamba --winbind-only &>/dev/null'); # restart samba to be shure that all ntlm services are running
    
    my @result = `sudo /usr/local/bin/netjoin.py`;
    
    foreach my $line (@result) {
        if ($line =~ m/Kinit failed: Clock skew too great/) {
            $answer = _("Clock skew is too great. Make sure the Firewall as
                        well as the PDC have a valid NTP (Network Time
                        Protocol) setup.");
            last;
        }
        elsif ($line =~ m/ads_connect: Cannot resolve network address/) {
            $answer = _("Cannot resolve PDC hostname in requested realm. Is the
                        PDC listed in the host list?");
            last;
        }
        elsif ($line =~ m/ads_connect: Operations error/) {
            $answer = _("Error while connecting to PDC. Is the PDC listed in 
                        the custom nameserver list?");
            last;
        }
        elsif ($line =~ m/ads_connect: Invalid argument/ || $line =~ m/ads_connect: Interrupted system call/) {
            $answer = _("Error while connecting to PDC. Is the authentication
                        realm set to the correct value? Is the PDC active?");
            last;
        }
        elsif ($line =~ m/Host is not configured as a member server./) {
            $answer = _("Host is not configured as a member server. Is 
                        authentication active on at least one zone?");
            last;
        }
        elsif ($line =~ m/ads_connect: Preauthentication failed./) {
            $answer = _("Authenication on the PDC failed. Check username, 
                        password and the privileges of the PDC user.");
            last;
        }
        elsif ($line =~ m/ads_connect: Client not found in Kerberos database/) {
            $answer = _("Authenication on the PDC failed. Check username, 
                        password and the privileges of the PDC user.");
            last;
        }
        $answer = "$line";    
    }   
    
    return $answer;
}

sub showapplybox($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    if ($conf{PROXY_ENABLED} eq "on" && (-e $proxyrestart || -e $proxyreload)) {
        applybox(_("Proxy settings have been changed and need to be applied in 
                    order to make the changes active"));
    }
    
    service_notifications(
        ['squid', 'icap', 'sarg'], 
        {
            'type' => $service_restarted == 1 ? "commit" : "observe",
            'interval' => 500, 
            'startMessage' => _("Proxy settings are being applied. Please hold..."),
            'endMessage' => _("Proxy settings have been applied successfully."),
        }
    );
}

sub applyaction() {
    if (-e $proxyrestart) {
        system("rm $proxyrestart");
        if(-e $proxyreload) {
            system("rm $proxyreload");
        }
        system("/usr/local/bin/restartsquid");
    }
    elsif(-e $proxyreload) {
        system("rm $proxyreload");
        system("/usr/local/bin/restartsquid");
    }
    $service_restarted = 1;
}
