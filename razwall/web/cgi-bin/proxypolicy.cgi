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

# -------------------------------------------------------------
# some definitions
# -------------------------------------------------------------
require 'proxy.pl';

sub get_timeframefield_widget($$) {
    my $params_ref = shift;
    my %params = %$params_ref;
    
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my $selection_ref = get_field_selection($conf{starthour});
    my %selection = %$selection_ref;

    my @options = ();
    for ($i=0;$i<=23;$i++) {
        my $hour = sprintf("%02s",$i);
        push(@options, {V_VALUE => $hour, T_OPTION => $hour, V_SELECTED => $selection{$hour}});
    }
    $params{V_STARTHOURS} = \@options;
    
    my $selection_ref = get_field_selection($conf{stophour});
    my %selection = %$selection_ref;
    
    my @options = ();
    for ($i=0;$i<=24;$i++) {
        my $hour = sprintf("%02s",$i);
        push(@options, {V_VALUE => $hour, T_OPTION => $hour, V_SELECTED => $selection{$hour}});
    }
    $params{V_STOPHOURS} = \@options;
    
    my $selection_ref = get_field_selection($conf{startminute});
    my %selection = %$selection_ref;
    
    my @options = ();
    for ($i=0;$i<=59;$i++) {
        my $minute = sprintf("%02s",$i);
        push(@options, {V_VALUE => $minute, T_OPTION => $minute, V_SELECTED => $selection{$minute}});
    }
    $params{V_STARTMINUTES} = \@options;
    
    my $selection_ref = get_field_selection($conf{stopminute});
    my %selection = %$selection_ref;
    
    my @options = ();
    for ($i=0;$i<=59;$i++) {
        my $minute = sprintf("%02s",$i);
        push(@options, {V_VALUE => $minute, T_OPTION => $minute, V_SELECTED => $selection{$minute}});
    }
    $params{V_STOPMINUTES} = \@options;
    
    return get_field_widget("/usr/share/efw-gui/proxy/widgets/timeframe.pltmpl", \%params);
}

sub get_policyrules($$$$) {
    my $info_ref = shift;
    my $conf_ref = shift;
    my $id = shift;
    my $action = shift;
    
    my %info = %$info_ref;
    my %conf = %$conf_ref;
    
    $info{'id'} = $id;
    $info{'src_' . $info{src_type}} = $info{src};
    $info{'dst_' . $info{dst_type}} = $info{dst};
    
    if ($action ne "edit") {
        $info{'policy'} = "allow";
        $info{'enabled'} = "on";
        $info{'days'} = "MTWHFAS";
        $info{'starthour'} = "00";
        $info{'startminute'} = "00";
        $info{'stophour'} = "24";
        $info{'stopminute'} = "00";
    }
    $info{'days'} =~ s/|/\|/g;
    $info{'mimetypes'} =~ s/&/\n/g;
    
    my $valid_zones_ref = validzones();
    my @valid_zones = @$valid_zones_ref;
    my @zones = ();
    foreach $zone (@valid_zones) {
        if (uc($zone) eq "WAN") {
            next;
        }
        push(@zones, {V_VALUE => uc($zone), T_OPTION => uc($zone)});
    }
    
    my @fields = ();
    
    my %params = (
        V_NAME => "src_type", 
        V_OPTIONS => [
            {V_VALUE => "any",
            T_OPTION => "&lt;" . _("ANY") . "&gt;"},
            {V_VALUE => "zone",
             T_OPTION => _("Zone")},
            {V_VALUE => "ip",
             T_OPTION => _("Network/IP")},
            {V_VALUE => "mac",
             T_OPTION => _("MAC")},
        ],
        V_TOGGLE_ACTION => 1, 
    );
    push(@fields, {H_FIELD => get_selectfield_widget(\%params, \%info)});
    
    my %params = (
        V_TOGGLE_ID => "src_type any",
        V_HIDDEN => $info{src_type} eq "" || $info{src_type} eq "any" ? 0 : 1,
        T_TEXT => _("This rule will match any source"),
        V_STYLE => "padding-bottom: 82px;"
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_NAME => "src_zone", 
        V_OPTIONS => \@zones,
        V_TOGGLE_ID => "src_type zone",
        V_HIDDEN => $info{src_type} eq "zone" ? 0 : 1,
        # V_STYLE => "padding-bottom: 68px;"
    );
    push(@fields, {H_FIELD => get_multiselectfield_widget(\%params, \%info)});
    
    my %params = (
        V_NAME => "src_ip", 
        V_TOGGLE_ID => "src_type ip",
        V_HIDDEN => $info{src_type} eq "ip" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%info)});
    
    my %params = (
        V_NAME => "src_mac", 
        V_TOGGLE_ID => "src_type mac",
        V_HIDDEN => $info{src_type} eq "mac" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%info)});
    
    if ($conf{AUTH_ENABLED} eq "on") {
        my %params = (
            V_NAME => "auth", 
            V_OPTIONS => [
                {V_VALUE => "none",
                T_OPTION => _("disabled")},
                {V_VALUE => "user",
                 T_OPTION => _("user based")},
                {V_VALUE => "group",
                 T_OPTION => _("group based")},
            ],
            V_TOGGLE_ACTION => 1,
        );
        push(@fields, {H_FIELD => get_selectfield_widget(\%params, \%info)});
    }
    
    my %params = (
        V_TOGGLE_ID => "auth user group",
        V_HIDDEN => $info{auth} eq "none" || $info{auth} eq "" ? 1 : 0,
        V_STYLE=> "padding-bottom: 62px;"
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_NAME => "time_restriction",
        T_CHECKBOX => _("enable time restrictions"),
        V_TOGGLE_ACTION => 1
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%info)});
    
    my @options = ();
    push(@options, {V_VALUE => "M", T_OPTION => _("Monday")});
    push(@options, {V_VALUE => "T", T_OPTION => _("Tuesday")});
    push(@options, {V_VALUE => "W", T_OPTION => _("Wednesday")});
    push(@options, {V_VALUE => "H", T_OPTION => _("Thursday")});
    push(@options, {V_VALUE => "F", T_OPTION => _("Friday")});
    push(@options, {V_VALUE => "A", T_OPTION => _("Saturday")});
    push(@options, {V_VALUE => "S", T_OPTION => _("Sunday")});
    
    my %params = (
        V_TOGGLE_ID => "time_restriction",
        V_HIDDEN => $info{time_restriction} eq "on" ? 0 : 1,
        V_NAME => "days", 
        V_OPTIONS => \@options,
    );
    push(@fields, {H_FIELD => get_multiselectfield_widget(\%params, \%info)});
    
    my @options = ();
    my @useragents = read_config_file($useragent_file, 0);
    my @custom_useragents = read_config_file($custom_useragent_file, 0);
    push(@useragents, @custom_useragents);
    foreach $line (@useragents) {
        my @useragent = split(/,/, $line);
        push(@options, {V_VALUE => @useragent[0], T_OPTION => @useragent[1]});
    }
    
    my %params = (
        V_NAME => "useragents", 
        V_OPTIONS => \@options,
    );
    push(@fields, {H_FIELD => get_multiselectfield_widget(\%params, \%info)});    
    
    my %params = (
        V_NAME => "policy", 
        V_OPTIONS => [
            {V_VALUE => "allow",
            T_OPTION => _("Allow access")},
            {V_VALUE => "deny",
             T_OPTION => _("Deny access")},
        ],
        V_TOGGLE_ACTION => 1
    );
    push(@fields, {H_FIELD => get_selectfield_widget(\%params, \%info)});
    
    my %params = (
        V_NAME => "enabled",
        T_CHECKBOX => _("Enable policy rule")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%info)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();

    my %params = (
        V_NAME => "dst_type", 
        V_OPTIONS => [
            {V_VALUE => "any",
            T_OPTION => "&lt;" . _("ANY") . "&gt;"},
            {V_VALUE => "zone",
             T_OPTION => _("Zone")},
            {V_VALUE => "ip",
             T_OPTION => _("Network/IP")},
            {V_VALUE => "domain",
             T_OPTION => _("Domain")},
        ],
        V_TOGGLE_ACTION => 1,
    );
    push(@fields, {H_FIELD => get_selectfield_widget(\%params, \%info)});
    
    my %params = (
        V_TOGGLE_ID => "dst_type any",
        V_HIDDEN => $info{dst_type} eq "" || $info{dst_type} eq "any" ? 0 : 1,
        T_TEXT => _("This rule will match any destination"),
        V_STYLE => "padding-bottom: 82px;"
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my @zones = ();
    foreach $zone (@valid_zones) {
        if (uc($zone) eq "WAN") {
            next;
        }
        push(@zones, {V_VALUE => uc($zone), T_OPTION => uc($zone)});
    }
    
    my %params = (
        V_NAME => "dst_zone", 
        V_OPTIONS => \@zones,
        V_TOGGLE_ID => "dst_type zone",
        V_HIDDEN => $info{dst_type} eq "zone" ? 0 : 1,
        # V_STYLE => "padding-bottom: 68px;"
    );
    push(@fields, {H_FIELD => get_multiselectfield_widget(\%params, \%info)});
    
    my %params = (
        V_NAME => "dst_ip", 
        V_TOGGLE_ID => "dst_type ip",
        V_HIDDEN => $info{dst_type} eq "ip" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%info)});
    
    my %params = (
        V_NAME => "dst_domain", 
        V_TOGGLE_ID => "dst_type domain",
        V_HIDDEN => $info{dst_type} eq "domain" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%info)});
    
    
    my @options = ();
    
    if ($conf{AUTH_METHOD} eq "ntlm" || $conf{AUTH_METHOD} eq "ldap") {
        @tmp_groups = `/usr/local/bin/get-groups.py`;
        for my $group (@tmp_groups) {
            if ($group =~ m/\*\*\*./) {
                next;
            }
            $group =~ s/\n//g;
            my $groupid = $group;
            $groupid =~ s/,/&/g;
            push(@options, {V_VALUE => $groupid, T_OPTION => $group});
        }
    }
    elsif ($conf{AUTH_METHOD} eq "ncsa") {
        my @groups = read_config_file($ncsagroup_file, 0);
        
        foreach my $thisline (@groups) {
            chomp($thisline);
            my %splitted = group_line($thisline);
            push(@options, {V_VALUE => $splitted{group}, T_OPTION => $splitted{group}});
        }
    }
    
    #No Connection to the ADS/LDAP Directory
    if (scalar(@options) eq 0) {
        my $text = _("No groups available");
        if ($conf{AUTH_METHOD} eq "ntlm" || $conf{AUTH_METHOD} eq "ldap") {
            $text = _("Can´t find the AD / LDAP server.");
        }
        my %params = (
            T_LABEL => _("Allowed groups"),
			T_TEXT => $text,
            V_TOGGLE_ID => "auth group",
            V_HIDDEN => $info{auth} eq "group" ? 0 : 1,
            V_STYLE => "padding-bottom: 68px;"
        );
        push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    }
    else {
        my %params = (
            V_NAME => "auth_group", 
            V_OPTIONS => \@options,
            V_TOGGLE_ID => "auth group",
            V_HIDDEN => $info{auth} eq "group" ? 0 : 1,
        );
        push(@fields, {H_FIELD => get_multiselectfield_widget(\%params, \%info)});
    }
    
    my @options = ();
    
    if ($conf{AUTH_METHOD} eq "ntlm" || $conf{AUTH_METHOD} eq "ldap") {
        @tmp_groups = `/usr/local/bin/get-users.py`;
        for my $group (@tmp_groups) {
            if ($group =~ m/\*\*\*./) {
                next;
            }
            $group =~ s/\n//g;
            my $groupid = $group;
            $groupid =~ s/,/&/g;
            push(@options, {V_VALUE => $groupid, T_OPTION => $group});
        }
    }
    elsif ($conf{AUTH_METHOD} eq "ncsa") {
        my @users = read_config_file($ncsauser_file, 0);
        
        foreach my $thisline (@users) {
            chomp($thisline);
            my %splitted = user_line($thisline);
            push(@options, {V_VALUE => $splitted{user}, T_OPTION => $splitted{user}});
        }
    }
    
    #No Connection to the ADS/LDAP Directory
    if (scalar(@options) eq 0) {
        my $text = _("No users available");
        if ($conf{AUTH_METHOD} eq "ntlm" || $conf{AUTH_METHOD} eq "ldap") {
            $text = _("Can´t find the AD / LDAP server.");
        }
        my %params = (
	        T_LABEL => _('Allowed users'),
            T_TEXT => $text,
            V_TOGGLE_ID => "auth user",
            V_HIDDEN => $info{auth} eq "user" ? 0 : 1,
            V_STYLE => "padding-bottom: 68px;"
        );
        push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    }
    else {
        my %params = (
            V_NAME => "auth_user", 
            V_OPTIONS => \@options,
            V_TOGGLE_ID => "auth user",
            V_HIDDEN => $info{auth} eq "user" ? 0 : 1,
        );
        push(@fields, {H_FIELD => get_multiselectfield_widget(\%params, \%info)});
    }
    
    my %params = (
        V_TOGGLE_ID => "auth none",
        V_HIDDEN => $info{auth} eq "none" || $info{auth} eq "" ? 0 : 1,
        V_STYLE => "padding-bottom: 56px;"
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
        
    my %params = ();
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        T_LABELSTARTHOUR => _("Start hour"),
        T_LABELSTARTMINUTE => _("Start minute"),
        T_LABELSTOPHOUR => _("Stop hour"),
        T_LABELSTOPMINUTE => _("Stop minute"),
        V_TOGGLE_ID => "time_restriction",
        V_HIDDEN => $info{time_restriction} eq "on" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_timeframefield_widget(\%params, \%info)});

    my %params = (
        V_NAME => "mimetypes", 
        V_TOGGLE_ID => "policy deny",
        V_HIDDEN => $info{policy} eq "deny" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%info)});
    
    my %params = (
        V_TOGGLE_ID => "policy allow",
        V_HIDDEN => $info{policy} eq "deny" ? 1 : 0,
        V_STYLE => "padding-bottom: 68px;",
        T_LABEL => _("Mimetypes"),
        T_TEXT => _("Only available with Deny access policies.")
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my @options = ();
    push(@options, {V_VALUE => "none", T_OPTION => _("none")});
	
    my @profiles = read_config_file($contentfilter, $contentfilter_default);
    my $num = 1;
    
    foreach my $profile (@profiles) {
        chomp($profile);
        my %splitted = contentfilter_line($profile);
        push(@options, {V_VALUE => $splitted{'id'}, T_OPTION => $splitted{'name'}});
    }
    push(@options, {V_VALUE => "havp", T_OPTION => _("virus detection only")});
    
    my %params = (
        V_NAME => "filtertype", 
        V_OPTIONS => \@options,
        V_TOGGLE_ACTION => 1,
        V_TOGGLE_ID => "policy allow",
        V_HIDDEN => $info{policy} eq "deny" ? 1 : 0,
    );
    push(@fields, {H_FIELD => get_selectfield_widget(\%params, \%info)});
    
    my %params = (
        V_TOGGLE_ID => "policy deny",
        V_HIDDEN => $info{policy} eq "deny" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my @options = ();
    my $count = line_count($policyrules, $policyrules_default);
    if ($action ne "edit") {
        $count += 1;
    }
    for (my $i = 0; $i < $count; $i++) {
        push(@options, {V_VALUE => $i, T_OPTION => $i eq 0 ? _("First position") : ($i eq ($count - 1) ? _("Last position") : _("position %s", ($i + 1)))});
    }
    
    my %params = (
        V_NAME => "id",
        V_OPTIONS => \@options
    );
    push(@fields, {H_FIELD => get_selectfield_widget(\%params, \%info)});

    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    my %params = (
        H_CONTAINER => $form,
        T_ADDRULE => _("Add access policy"),
        T_SAVE => $action eq "edit" ? _("Update policy") : _("Create policy"),
        V_OPEN => $action eq "edit" ? 1 : 0,
        V_ID => $id
    );
    my $content = get_editorbox_widget(\%params);
    
    my @lines = read_config_file($policyrules, $policyrules_default);
    my @rows = ();
    my $num = 1;
    
    foreach my $thisline (@lines) {
        chomp($thisline);
        my %splitted = policy_line($thisline);
        my @cols = ();
        push(@cols, {V_CELL_CONTENT => $num});
        
        my $policy = "<font color='$colourred'><b>" . _("access denied") . "</b></font>";
        if($splitted{'policy'} eq "allow") {
            if($splitted{'filtertype'} eq "havp") {
                $policy = "<font color='$colourorange'><b>" . _("filter for virus") . "</b></font>";
            }
            elsif($splitted{'filtertype'} eq "none") {
                $policy = "<font color='$colourgreen'><b>" . _("unfiltered access") . "</b></font>";
	    }
            else {
                $policy = "<font color='$colourblue'><b>" . _("filter using '" . $splitted{'filtertype'} . "'") . "</b></font>";
            }
        }
        elsif ($splitted{'mimetypes'} ne "") {
            $policy .= "<br/>" . $splitted{'mimetypes'};
            $policy =~ s/&/<br\/>/g;
        }
        push(@cols, {V_CELL_CONTENT => $policy});
        
        my $source = $splitted{'src'};
        $source =~ s/\|/<br\/>/g;
        $source =~ s/LAN/<font color='$colourgreen'>LAN<\/font>/g;
        $source =~ s/DMZ/<font color='$colourorange'>DMZ<\/font>/g;
        $source =~ s/LAN2/<font color='$colourblue'>LAN2<\/font>/g;
        push(@cols, {V_CELL_CONTENT => $source eq "" ? "<b>" . _("ANY") . "</b>" : $source});
        
        my $destination = $splitted{'dst'};
        $destination =~ s/\|/<br\/>/g;
        $destination =~ s/LAN/<font color='$colourgreen'>LAN<\/font>/g;
        $destination =~ s/DMZ/<font color='$colourorange'>DMZ<\/font>/g;
        $destination =~ s/LAN2/<font color='$colourblue'>LAN2<\/font>/g;
        push(@cols, {V_CELL_CONTENT => $destination eq "" ? "<b>" . _("ANY") . "</b>" : $destination});
        
        my $auth = _("not required");
        if ($splitted{'auth'} eq "group") {
            $auth = $splitted{'auth_group'};
            $auth =~ s/&/,/g;
            $auth =~ s/\|/<br\/>/g;
        }
        elsif ($splitted{'auth'} eq "user") {
            $auth = $splitted{'auth_user'};
            $auth =~ s/&/,/g;
            $auth =~ s/\|/<br\/>/g;
        }
        elsif ($splitted{'auth'} eq "all") {
            $auth = "<b>" . _("ALL") . "</b>";
        }
        
        push(@cols, {V_CELL_CONTENT => $auth});
        
        if ($splitted{'time_restriction'} ne "on") {
            push(@cols, {V_CELL_CONTENT => _("Always")});
        }
        else {
            my $when = _("All day long");
            if ($splitted{'starthour'} ne "00" || $splitted{'startminute'} ne "00" || $splitted{'stophour'} ne "24" || $splitted{'stopminute'} ne "00") {
                $when = $splitted{'starthour'} . ":" . $splitted{'startminute'} . "-" . $splitted{'stophour'} . ":" . $splitted{'stopminute'};
            }
            
            push(@cols, {V_CELL_CONTENT => $splitted{'days'} . "<br />" . $when});
        }
        
        my $useragents = $splitted{'useragents'};
        $useragents =~ s/\|/<br\/>/g;
        push(@cols, {V_CELL_CONTENT => $useragents eq "" ? "<b>" . _("ANY") . "</b>" : $useragents});
        
        my %params = (
            V_COLS => \@cols,
            STYLE => setbgcolor($action eq "edit" ? 1 : 0, $id, ($num - 1)),
            EDIT_ACTION => "window.open('" . $ENV{'SCRIPT_NAME'} . "?ACTION=edit&ID=" . ($num - 1) . "','_self');",
            REMOVE_ACTION => "window.open('" . $ENV{'SCRIPT_NAME'} . "?ACTION=remove&ID=" . ($num - 1) . "','_self');",
            UP_ACTION => "window.open('" . $ENV{'SCRIPT_NAME'} . "?ACTION=up&ID=" . ($num - 1) . "','_self');",
            DOWN_ACTION => "window.open('" . $ENV{'SCRIPT_NAME'} . "?ACTION=down&ID=" . ($num - 1) . "','_self');",
            ON_ACTION => $splitted{'enabled'} eq "on" ? "window.open('" . $ENV{'SCRIPT_NAME'} . "?ACTION=on&ID=" . ($num - 1) . "','_self');" : 0,
            OFF_ACTION => $splitted{'enabled'} eq "on" ? 0 : "window.open('" . $ENV{'SCRIPT_NAME'} . "?ACTION=off&ID=" . ($num - 1) . "','_self');",
        );
        push(@rows, \%params);
        
        $num += 1;
    }
    
    my %params = (
        V_HEADINGS => [
            {HEADING => "#"},
            {HEADING => _("Policy")},
            {HEADING => _("Source")},
            {HEADING => _("Destination")},
            {HEADING => _("Authgroup/-user")},
            {HEADING => _("When")},
            {HEADING => _("Useragent")},
        ],
        V_ACTIONS => 1,
        V_ROWS => \@rows,
    );
    $content .= get_listtable_widget(\%params);
    
    return $content;
}

sub render_templates($$$$) {
    my $info_ref = shift;
    my $conf_ref = shift;
    my $id = shift;
    my $action = shift;
    
    my %info = %$info_ref;
    my %conf = %$conf_ref;
    
    print get_policyrules(\%info, \%conf, $id, $action);
}

sub validate_fields($) {
    my $params_ref = shift;
    my %params = %$params_ref;
    my $errors = "";
    
    if ($par{'src_type'} eq "ip") {
        $errors .= check_field("src_ip", \%params);    
    }
    elsif ($par{'src_type'} eq "mac") {
        $errors .= check_field("src_mac", \%params);
    }
    if ($par{'dst_type'} eq "ip") {
        $errors .= check_field("dst_ip", \%params);
    }
    elsif ($par{'dst_type'} eq "domain") {
        $errors .= check_field("dst_domain", \%params);
    }
    if ($par{'time_restriction'} eq "on") {
        if ($par{'days'} eq "") {
            $errors .= _("Select at least one day on which the policy should be active.") . "<br />";
        }
        if (($par{'starthour'} > $par{'stophour'}) ||
            ($par{'starthour'} eq $par{'stophour'} && $par{'startminute'} > $par{'stopminute'})) {
            $errors .= _("Start time must be earlier than stop time.") . "<br />";
        }
        elsif ($par{'starthour'} eq $par{'stophour'} && $par{'startminute'} eq $par{'stopminute'}) {
            $errors .= _("Start time must differ from stop time.") . "<br />";
        }
    }
    
    return $errors;
}

%field_definition = (
    policy => {
        label => _("Access policy"),
        required => 1},
    
    filtertype => {
        label => _("Filter profile"),
        required => 1},
    
    time_restriction => {
        label => _("Time restriction")},
    days => {
        label => _("Active days"),
        required => 1},
    
    src => {
        required => 1},
    src_type => {
        label => _("Source Type"),
        required => 1},
    src_zone => {
        label => _("Select Source Zone"),
        required =>1},
    src_ip => {
        label => _("Insert Source Network/IPs"),
        checks => ["subnet", "ip"],
        required =>1},
    src_mac => {
        label => _("Insert Source MAC Addresses"),
        checks => ["mac"],
        required =>1},
    
    dst => {
        required => 1},
    dst_type => {
        label => _("Destination Type"),
        required => 1},
    dst_zone => {
        label => _("Select Destination Zone"),
        required =>1},
    dst_ip => {
        label => _("Insert Destination Network/IPs"),
        checks => ["subnet", "ip"],
        required =>1},
    dst_domain => {
        label => _("Insert Domains (one per line)"),
        checks => ["domain", "subdomain", "hostname", "fqdn"],
        required =>1},
    
    auth => {
        label => _("Authentication")},
    auth_group => {
        label => _("Allowed Groups")},
    auth_user => {
        label => _("Allowed Users")},
    
    enabled => {
        label => _("Policy status")},
    id => {
        label => _("Position"),
        required => 1},
    
    mimetypes => {
        label => _("Mimetypes")},
    useragents => {
        label => _("Useragents"),
        description => _("hold CTRL (CMD on mac) for multiselect or unselect")},
);

showhttpheaders();

my $conf_ref = reload_par();
my %conf = %$conf_ref;
my @checkboxes = ("enabled", "time_restriction", "check_mimetypes", "check_useragents");
my $errormessage = "";

getcgihash(\%par);

my $cgi_objekt = new CGI;
my $action = $cgi_objekt->param('ACTION');
my $id = $cgi_objekt->param('ID');
my %info = ();

if ( $par{ACTION} eq 'save' ) {
    $par{'days'} =~ s/\|//g;
    if ($par{'src_type'} eq "zone") {
        $par{'src'} = $par{'src_zone'};
    }
    elsif ($par{'src_type'} eq "ip") {
        $par{'src'} = $par{'src_ip'};
    }
    elsif ($par{'src_type'} eq "mac") {
        $par{'src'} = $par{'src_mac'};
    }
    if ($par{'dst_type'} eq "zone") {
        $par{'dst'} = $par{'dst_zone'};
    }
    elsif ($par{'dst_type'} eq "ip") {
        $par{'dst'} = $par{'dst_ip'};
    }
    elsif ($par{'dst_type'} eq "domain") {
        $par{'dst'} = $par{'dst_domain'};
    }
    $errormessage = validate_fields(\%par);
    if ($errormessage ne "") {
        %info = %par;
        $action = "edit";
    }
    else {
        my $success = save_policy(
            $par{'ID'},
            $par{'enabled'},
            $par{'policy'},
            $par{'auth'},
            $par{'auth_group'},
            $par{'auth_user'},
            $par{'time_restriction'},
            $par{'days'},
            $par{'starthour'},
            $par{'startminute'},
            $par{'stophour'},
            $par{'stopminute'},
            $par{'filtertype'},
            $par{'src_type'},
            $par{'src'},
            $par{'dst_type'},
            $par{'dst'},
            $par{'mimetypes'},
            $par{'useragents'}
        );
        
        if ($success eq 1) {
            my $oldid = $par{'ID'};
            if ($oldid !~ /^\d+$/) {
                $oldid = line_count($policyrules, $policyrules_default) - 1;
            }
            set_policy_position($oldid, $par{'id'});
        }
        
        system("touch $proxyreload");
    }
}

if ($action eq "edit" && %info == ()) {
    %info = policy_line(read_config_line($id, $policyrules, $policyrules_default));
}
elsif ($action eq "remove") {
    delete_line($id, $policyrules, $policyrules_default);
    system("touch $proxyreload");
}
elsif ($action eq "on" or $action eq "off") {
    toggle_policy($id, $action eq "on" ? 0 : 1);
    system("touch $proxyreload");
}
elsif ($action eq "up" or $action eq "down") {
    move_policy($id, $action eq "up" ? -1 : 1);
    system("touch $proxyreload");
}
elsif ($par{'ACTION'} eq 'apply'){
    &log(_('Apply proxy settings'));
    applyaction();
}

openpage(_("HTTP Policy"), 1, 
    '<script type="text/javascript" src="/include/fields.js"></script>' . $notification_script);

showapplybox(\%conf);

openbigbox($errormessage, $warnmessage, $notemessage);

render_templates(\%info, \%conf, $action eq "edit" ? $id : "", $action);

closebigbox();
closepage();
