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

sub get_auth_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();

    my %params = (
        V_NAME => "AUTH_REALM",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});

    my %params = (
        V_NAME => "AUTH_CHILDREN",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "AUTH_MAX_USERIP",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = ();
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
        
    my %params = (
        V_NAME => "AUTH_CACHE_TTL",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "AUTH_IPCACHE_TTL",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_ncsa_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "NCSA_USER_GUI",
        T_BUTTON => _("manage users"),
        ONCLICK => "window.open('/cgi-bin/proxyuser.cgi','_self');"
    );
    push(@fields, {H_FIELD => get_buttonfield_widget(\%params)});
    
    my %params = (
        V_NAME => "NCSA_MIN_PASS_LEN",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "NCSA_GROUP_GUI",
        T_BUTTON => _("manage groups"),
        ONCLICK => "window.open('/cgi-bin/proxygroup.cgi','_self');"
    );
    push(@fields, {H_FIELD => get_buttonfield_widget(\%params)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_ntlm_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "NTLM_DOMAIN",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});

    my %params = (
        V_NAME => "AUTH_REALM_LEGACY",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "NTLM_PDC",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "PDC_ADDRESS",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "JOIN_DOMAIN",
        T_BUTTON => _("join domain"),
        ONCLICK => "window.open('/manage/proxy/adjoin','_self');"
    );
    push(@fields, {H_FIELD => get_buttonfield_widget(\%params)});
    
    my %params = (
        V_NAME => "NTLM_BDC",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});

    my %params = (
        V_NAME => "BDC_ADDRESS",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_ldap_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "LDAP_SERVER",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "LDAP_BASEDN",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "LDAP_BINDDN_USER",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "LDAP_PERSON_OBJECT_CLASS",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "LDAP_PORT",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "LDAP_TYPE", 
        V_OPTIONS => [
            {V_VALUE => "ADS",
             T_OPTION => _("Active Directory Server")},
            {V_VALUE => "V3",
             T_OPTION => _("LDAP v3 Server")},
            {V_VALUE => "V2",
             T_OPTION => _("LDAP v2 Server")},
            {V_VALUE => "NDS",
             T_OPTION => _("Novell eDirectory Server")},
        ],
    );
    push(@fields, {H_FIELD => get_selectfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "LDAP_BINDDN_PASS",
    );
    push(@fields, {H_FIELD => get_passwordfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "LDAP_GROUP_OBJECT_CLASS",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_radius_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "RADIUS_SERVER",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "RADIUS_IDENTIFIER",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "RADIUS_PORT",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "RADIUS_SECRET",
    );
    push(@fields, {H_FIELD => get_passwordfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub render_templates($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my %params = (
        V_NAME => "AUTH_METHOD", 
        V_OPTIONS => [
            {V_VALUE => "ncsa",
             T_OPTION => _("Local Authentication (NCSA)")},
            {V_VALUE => "ntlm",
             T_OPTION => _("Windows Active Directory (NTLM)")},
            {V_VALUE => "ldap",
             T_OPTION => _("LDAP (v2, v3, Novell eDirectory, AD)")},
            {V_VALUE => "radius",
             T_OPTION => _("RADIUS")},
        ],
        V_TOGGLE_ACTION => 1, 
    );
    my $container = get_selectfield_widget(\%params, \%conf) . "<br />";
    
    my %accordionparams = (
        V_ACCORDION => [
            {T_TITLE => _("Authentication settings"),
             T_DESCRIPTION => _("Unfold to define authentication settings."),
             H_CONTAINER => get_auth_form(\%conf)},
            {T_TITLE => _("NCSA specific settings"),
             T_DESCRIPTION => _("Unfold to define NCSA specific authentication settings."),
             H_CONTAINER => get_ncsa_form(\%conf),
             V_TOGGLE_ID => "auth_method ncsa",
             V_NOTVISIBLE => $conf{AUTH_METHOD} eq "ncsa" ? 0 : 1},
            {T_TITLE => _("NTLM specific settings"),
             T_DESCRIPTION => _("Unfold to define NTLM specific authentication settings."),
             H_CONTAINER => get_ntlm_form(\%conf),
             V_TOGGLE_ID => "auth_method ntlm",
             V_NOTVISIBLE => $conf{AUTH_METHOD} eq "ntlm" ? 0 : 1},
            {T_TITLE => _("LDAP specific settings"),
             T_DESCRIPTION => _("Unfold to define LDAP specific authentication settings."),
             H_CONTAINER => get_ldap_form(\%conf),
             V_TOGGLE_ID => "auth_method ldap",
             V_NOTVISIBLE => $conf{AUTH_METHOD} eq "ldap" ? 0 : 1},
            {T_TITLE => _("RADIUS specific settings"),
             T_DESCRIPTION => _("Unfold to define RADIUS specific authentication settings."),
             H_CONTAINER => get_radius_form(\%conf),
             V_TOGGLE_ID => "auth_method radius",
             V_NOTVISIBLE => $conf{AUTH_METHOD} eq "radius" ? 0 : 1},
        ]
    );
    
    $container .= get_accordion_widget(\%accordionparams);
    
    my %params = (
        H_FORM_CONTAINER => $container,
    );
    
    print get_saveform_widget(\%params);
    
}

sub validate_fields($) {
    my $params_ref = shift;
    my %params = %$params_ref;
    my $errors = "";
    
    $errors .= check_field("AUTH_REALM", \%params);
    $errors .= check_field("AUTH_REALM_LEGACY", \%params);
    $errors .= check_field("AUTH_CHILDREN", \%params);
    $errors .= check_field("AUTH_CACHE_TTL", \%params);
    $errors .= check_field("AUTH_MAX_USERIP", \%params);
    $errors .= check_field("AUTH_IPCACHE_TTL", \%params);
    
    if ($params{AUTH_METHOD} eq "ncsa") {
        $errors .= check_field("NCSA_MIN_PASS_LEN", \%params);
    }
    if ($params{AUTH_METHOD} eq "ntlm") {
        $errors .= check_field("NTLM_DOMAIN", \%params);
        $errors .= check_field("NTLM_PDC", \%params);
        $errors .= check_field("NTLM_BDC", \%params);
        $errors .= check_field("PDC_ADDRESS", \%params);
        $errors .= check_field("BDC_ADDRESS", \%params);
        if ($params{NTLM_BDC} ne "" && $params{BDC_ADDRESS} eq "") {
            $errors .= _("\"%s\" is required!", get_field_label("BDC_ADDRESS")) . "<br />";
        }
    }
    if ($params{AUTH_METHOD} eq "ldap") {
        $errors .= check_field("LDAP_SERVER", \%params);
        $errors .= check_field("LDAP_PORT", \%params);
        $errors .= check_field("LDAP_BASEDN", \%params);
        $errors .= check_field("LDAP_BINDDN_USER", \%params);
        $errors .= check_field("LDAP_BINDDN_PASS", \%params);
        $errors .= check_field("LDAP_PERSON_OBJECT_CLASS", \%params);
        $errors .= check_field("LDAP_GROUP_OBJECT_CLASS", \%params);
    }
    if ($params{AUTH_METHOD} eq "radius") {
        $errors .= check_field("RADIUS_SERVER", \%params);
        $errors .= check_field("RADIUS_PORT", \%params);
        $errors .= check_field("RADIUS_IDENTIFIER", \%params);
        $errors .= check_field("RADIUS_SECRET", \%params);
    }
    
    return $errors;
}

%field_definition = (
    AUTH_METHOD => {
        label => _("Choose Authentication Method"),
        required => 1},
    AUTH_REALM => {
        label => _("Authentication Realm"),
        required => 1},
    AUTH_REALM_LEGACY => {
        label => _("Domain name for legacy systems (Windows 2000 and older)"),
        required => 0},
    AUTH_CHILDREN => {
        label => _("Number of Authentication Children"),
        required => 1,
        checks => ["int"]},
    AUTH_CACHE_TTL => {
        label => _("Authentication cache TTL (in minutes)"),
        required => 1,
        checks => ["int"]},
    AUTH_MAX_USERIP => {
        label => _("Number of different ips per user"),
        required => 1,
        checks => ["int"]},
    AUTH_IPCACHE_TTL => {
        label => _("User / IP cache TTL (in minutes)"),
        required => 1,
        checks => ["int"]},
    
    NCSA_USER_GUI => {
        label => _("NCSA user management")},
    NCSA_GROUP_GUI => {
        label => _("NCSA group management")},
    NCSA_MIN_PASS_LEN => {
        label => _("Min password length"),
        required => 1,
        checks => ["int"]},
    
    NTLM_DOMAIN => {
        label => _("Domainname of AD server"),
        required => 1,
        checks => ["domain"]},
    JOIN_DOMAIN => {
        label => _("Join AD domain")},
    NTLM_PDC => {
        label => _("PDC hostname of AD server"),
        required => 1,
        checks => ["hostname"]},
    NTLM_BDC => {
        label => _("BDC hostname of AD server"),
        required => 0,
        checks => ["hostname"]},
    PDC_ADDRESS => {
        label => _("PDC ip address of AD server"),
        required => 1,
        checks => ["ip"]},
    BDC_ADDRESS => {
        label => _("BDC ip address of AD server"),
        checks => ["ip"]},
    
    LDAP_SERVER => {
        label => _("LDAP server"),
        required => 1,
        checks => ["ip", "hostname", "fqdn", "domain"]},
    LDAP_PORT => {
        label => _("Port of LDAP server"),
        required => 1,
        checks => ["port"]},
    LDAP_BASEDN => {
        label => _("Bind DN settings"),
        required => 1},
    LDAP_TYPE => {
        label => _("LDAP type"),
        required => 1},
    LDAP_BINDDN_USER => {
        label => _("Bind DN username")},
    LDAP_BINDDN_PASS => {
        label => _("Bind DN password")},
    LDAP_PERSON_OBJECT_CLASS => {
        label => _("user objectClass"),
        required => 1},
    LDAP_GROUP_OBJECT_CLASS => {
        label => _("group objectClass"),
        required => 1},
    
    RADIUS_SERVER => {
        label => _("Radius server"),
        required => 1,
        checks => ["ip", "hostname", "fqdn", "domain"]},
    RADIUS_PORT => {
        label => _("Port of RADIUS server"),
        required => 1,
        checks => ["port"]},
    RADIUS_IDENTIFIER => {
        label => _("Identifier"),
        required => 1},
    RADIUS_SECRET => {
        label => _("Shared secret"),
        required => 1},
);

showhttpheaders();

my $conf_ref = reload_par();
my %conf = %$conf_ref;
my @checkboxes = ();
my $errormessage = "";

my $cgi_objekt = new CGI;
my $action = $cgi_objekt->param('ACTION');

getcgihash(\%par);

if ( $par{ACTION} eq 'save' ) {
    $errormessage = validate_fields(\%par);
    if ($errormessage ne "") {
        %conf = %par;
    }
    else {
        my $changed = save_settings(\%conf, \%par, \@checkboxes);
        $conf_ref = reload_par();
        %conf = %$conf_ref;
        if ($changed eq 1) {
            system("touch $proxyreload");
        }
    }
}
elsif ($par{'ACTION'} eq 'apply'){
    &log(_('Apply proxy settings'));
    applyaction();
}
elsif ($action eq "join") {
    if ($conf{'AUTH_METHOD'} eq 'ntlm') {
        if ($conf{'AUTH_REALM'} eq '') {
            $errormessage = _('Please enter the realm for the NT domain');
        }
        if ($conf{'NTLM_DOMAIN'} eq '') {
            $errormessage = _('Windows domain name required');
        }
        if ($conf{'NTLM_PDC'} eq '') {
            $errormessage = _('Hostname for Primary Domain Controller required');
        }
        if (!&validhostname($conf{'NTLM_PDC'})) {
            $errormessage = _('Invalid hostname for Primary Domain Controller');
        }
        if ((!($conf{'NTLM_BDC'} eq '')) && (!&validhostname($par{'NTLM_BDC'}))) {
            $errormessage = _('Invalid hostname for Backup Domain Controller');
        }

        # check if we can resolv the name 
        use Net::hostent ':FIELDS';

        if (!(gethost($par{'NTLM_PDC'}))) {
            $errormessage = _('Cannot resolve PDC hostname. Is the PDC listed in the Host list?');
        }
    }
}

openpage(_("HTTP Authentication"), 1, 
    '<script type="text/javascript" src="/include/fields.js"></script>' . $notification_script);

showapplybox(\%conf);

openbigbox($errormessage, $warnmessage, $notemessage);

render_templates(\%conf);

closebigbox();
closepage();
