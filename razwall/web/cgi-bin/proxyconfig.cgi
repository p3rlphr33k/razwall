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
require '/razwall/web/cgi-bin/proxy.pl';

my $appliance_settings = "${swroot}/product/settings";
my $service_restarted = 0;

# Read product settings.
my %appl_conf = ();
readhash($appliance_settings, \%appl_conf);

# return true if the appliance is a new mini.
sub is_new_mini() {
    return $appl_conf->{"PRODUCT_ID"} eq "mini-arm";
}

sub get_server_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "PROXY_PORT",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "VISIBLE_HOSTNAME",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "MAX_INCOMING_SIZE",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});

    if ($conf{ZONE_CONFIGURATION} eq "on") {
        my %params = (
            V_NAME => "TPROXY_NONTRANSPARENT_SPOOF",
            T_CHECKBOX => _("Keep original source IP address in not transparent mode")
        );
        push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    }

    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "ERR_LANGUAGE", 
        V_OPTIONS => [
            {V_VALUE => "en",
             T_OPTION => _("English")},
            {V_VALUE => "de",
             T_OPTION => _("German")},
            {V_VALUE => "it",
             T_OPTION => _("Italian")},
            {V_VALUE => "ja",
             T_OPTION => _("Japanese")},
        ],
    );
    push(@fields, {H_FIELD => get_selectfield_widget(\%params, \%conf)});
    
    if (!is_new_mini()) {
        my %params = (
            V_NAME => "ADMIN_MAIL_ADDRESS",
        );
        push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    }
    
    my %params = (
        V_NAME => "MAX_OUTGOING_SIZE",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});

    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_port_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "PORTS",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "SSLPORTS",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});    
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_log_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();

    my %params = (
        V_NAME => "LOGGING",
        V_TOGGLE_ACTION => 1,
        T_CHECKBOX => _("Enable logging")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "LOGQUERY",
        V_TOGGLE_ID => "logging",
        T_CHECKBOX => _("Log query terms")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "DANSGUARDIAN_LOGGING",
        V_TOGGLE_ID => "logging",
        T_CHECKBOX => _("Log contentfiltering")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = ();
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_NAME => "LOGUSERAGENT",
        V_TOGGLE_ID => "logging",
        T_CHECKBOX => _("Log useragents")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "LOG_FIREWALL",
        V_TOGGLE_ID => "logging",
        T_CHECKBOX => _("Log outgoing connections")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_bypass_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "BYPASS_SOURCE",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});    
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "BYPASS_DESTINATION",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});    
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_cache_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "CACHE_SIZE",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "CACHE_MEM",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "MAX_SIZE",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "MIN_SIZE",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "OFFLINE_MODE",
        T_CHECKBOX => _("Enable offline mode")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "CLEAR_CACHE",
        T_BUTTON => _("clear cache"),
        ONCLICK => "window.open('" . $ENV{'SCRIPT_NAME'} . "?ACTION=clearcache','_self');"
    );
    push(@fields, {H_FIELD => get_buttonfield_widget(\%params)});
    
    my %params = (
        V_NAME => "DST_NOCACHE",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_upstream_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "UPSTREAM_ENABLED",
        T_CHECKBOX => _("Use upstream proxy"),
        V_TOGGLE_ACTION => 1
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "UPSTREAM_SERVER",
        V_TOGGLE_ID => "upstream_enabled",
        V_HIDDEN => is_field_hidden($conf{"UPSTREAM_ENABLED"})
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "UPSTREAM_USER",
        V_TOGGLE_ID => "upstream_enabled",
        V_HIDDEN => is_field_hidden($conf{"UPSTREAM_ENABLED"})
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "FORWARD_USERNAME",
        T_CHECKBOX => _("Forward username to upstream proxy"),
        V_TOGGLE_ID => "upstream_enabled",
        V_HIDDEN => is_field_hidden($conf{"UPSTREAM_ENABLED"})
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = ();
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_NAME => "UPSTREAM_PORT",
        V_TOGGLE_ID => "upstream_enabled",
        V_HIDDEN => is_field_hidden($conf{"UPSTREAM_ENABLED"})
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "UPSTREAM_PASSWORD",
        V_TOGGLE_ID => "upstream_enabled",
        V_HIDDEN => is_field_hidden($conf{"UPSTREAM_ENABLED"})
    );
    push(@fields, {H_FIELD => get_passwordfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "FORWARD_IPADDRESS",
        T_CHECKBOX => _("Forward ipaddress to upstream proxy"),
        V_TOGGLE_ID => "upstream_enabled",
        V_HIDDEN => is_field_hidden($conf{"UPSTREAM_ENABLED"})
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub render_templates($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    my $template = '';
    
    my @options = ();
    
    push(@options, {V_NAME => "", T_DESCRIPTION => _("not transparent")});
    push(@options, {V_NAME => "transparent", T_DESCRIPTION => _("transparent")});
    push(@options, {V_NAME => "tproxy", T_DESCRIPTION => _("transparent (keep original source IP address)")});
    push(@options, {V_NAME => "inactive", T_DESCRIPTION => _("inactive")});
    
    if ($conf{ZONE_CONFIGURATION} eq "on") {
        $template .= get_zonestatus_widget("", \%conf, \@options);
    }

    my $cache_mngmt_label = _("Cache management");
    
    my %accordionparams = (
        V_ACCORDION => [
            {T_TITLE => _("Proxy settings"),
             T_DESCRIPTION => _("Unfold to define proxy settings (server port, hostname, cache admin, error language)."),
             H_CONTAINER => get_server_form(\%conf),
             V_HIDDEN => 0},
            {T_TITLE => _("Allowed ports and ssl ports"),
             T_DESCRIPTION => _("Unfold to define which ports are allowed when using the http proxy (ports and ssl ports)."),
             H_CONTAINER => get_port_form(\%conf),
             V_HIDDEN => 1},
            {T_TITLE => _("Log settings"),
             T_DESCRIPTION => _("Unfold to define the log settings (query terms, useragents, contentfiltering, firewall)."),
             H_CONTAINER => get_log_form(\%conf),
             V_HIDDEN => 1},
            {T_TITLE => _("Bypass transparent proxy"),
             T_DESCRIPTION => _("Unfold to define when to bypass the transparent proxy (bypass from source, bypass to destination)."),
             H_CONTAINER => get_bypass_form(\%conf),
             V_HIDDEN => 1},
            {T_TITLE => $cache_mngmt_label,
             T_DESCRIPTION => _("Unfold to define the cache management settings of the http proxy (cache size, object size, offline mode, no cache domains"),
             H_CONTAINER => get_cache_form(\%conf),
             V_HIDDEN => 1},
            {T_TITLE => _("Upstream proxy"),
             T_DESCRIPTION => _("Unfold to define an upstream proxy (host:port, username, password, username forwarding, client ip forwarding)."),
             H_CONTAINER => get_upstream_form(\%conf),
             V_HIDDEN => 1},
        ]
    );

    # If the current appliance is a mini-arm, remove the cache management.
    my %appl_conf = ();
    readhash($appliance_settings, \%appl_conf);
    if (is_new_mini()) {
        my $cache_idx = -1;
        my $counter = 0;
        foreach my $i (@{$accordionparams->{"V_ACCORDION"}}) {
            if ($i->{"T_TITLE"} eq $cache_mngmt_label) {
                $cache_idx = $counter;
                break;
	    }
	    $counter += 1;
	}
	if ($cache_idx != -1) {
    	    splice(@{$accordionparams->{"V_ACCORDION"}}, $cache_idx, 1);
        }
    }

    $template .= get_accordion_widget(\%accordionparams);
    
    my %switchparams = (
        V_SERVICE_ON => $conf{"PROXY_ENABLED"},
        V_SERVICE_AJAXIAN_SAVE => 1,
        H_OPTIONS_CONTAINER => $template,
        T_SERVICE_TITLE => _('Enable HTTP Proxy'),
        T_SERVICE_STARTING => _("The HTTP Proxy is being enabled. Please hold..."),
        T_SERVICE_SHUTDOWN => _("The HTTP Proxy is being disabled. Please hold..."),
        T_SERVICE_RESTARTING => _("The HTTP Proxy is being restarted. Please hold..."),
        T_SERVICE_STARTED => _("The HTTP Proxy was restarted successfully"),
        T_SERVICE_DESCRIPTION => _("Use the switch above to set the status of the HTTP Proxy. Click on the save button below to make the changes active."),
    );
    
    print get_switch_widget(\%switchparams);
}

sub validate_fields($) {
    my $params_ref = shift;
    my %params = %$params_ref;
    my $errors = "";
    
    $errors .= check_field("PROXY_PORT", \%params);
    if ($params{"PROXY_PORT"} eq "80") {
        $errors .= _("Port 80 is already used.");
    }
    $errors .= check_field("VISIBLE_HOSTNAME", \%params);
    $errors .= check_field("ADMIN_MAIL_ADDRESS", \%params);
    $errors .= check_field("PORTS", \%params);
    $errors .= check_field("SSLPORTS", \%params);
    $errors .= check_field("BYPASS_SOURCE", \%params);
    $errors .= check_field("BYPASS_DESTINATION", \%params);
    if (!is_new_mini()) {
        $errors .= check_field("CACHE_SIZE", \%params);
        if ($params{"CACHE_SIZE"} < 1) {
            $errors .= _("Harddisk cache must be greater than 0.");
        }
    }
    $errors .= check_field("CACHE_MEM", \%params);
    $errors .= check_field("DST_NOCACHE", \%params);
    $errors .= check_field("MAX_SIZE", \%params);
    $errors .= check_field("MIN_SIZE", \%params);
        
    if ($params{UPSTREAM_ENABLED} eq "on") {
        $errors .= check_field("UPSTREAM_SERVER", \%params);
        $errors .= check_field("UPSTREAM_PORT", \%params);
    }
    
    return $errors;
}

%field_definition = (
    PROXY_PORT => {
        label => _("Port used by proxy"),
        required => 1,
        checks => ["port"]},
    VISIBLE_HOSTNAME => {
        label => _("Visible Hostname used by proxy"),
        required => 0,
        checks => ["hostname"]},
    ADMIN_MAIL_ADDRESS => {
        label => _("Email used for notification (cache admin)"),
        required => 0,
        checks => ["email"]},
    ERR_LANGUAGE => {
        label => _("Error Language"),
        required => 1},
    MAX_INCOMING_SIZE => {
        label => _("Maximum download size (incoming in KB)"),
        required => 1,
        checks => ["int"]},
    TPROXY_NONTRANSPARENT_SPOOF => {
        label => _("Keep source IP address"),
        required => 0},
    MAX_OUTGOING_SIZE => {
        label => _("Maximum upload size (outgoing in KB)"),
        required => 1,
        checks => ["int"]},
    
    PORTS => {
        label => _("Allowed Ports (from client)"),
        required => 0,
        checks => ["portdesc", "portrangedesc"]},
    SSLPORTS => {
        label => _("Allowed SSL Ports (from client)"),
        required => 0,
        checks => ["portdesc", "portrangedesc"]},
    
    LOGGING => {
        label => _("HTTP proxy logging"),
        required => 0},
    LOGQUERY => {
        label => _("Query term logging"),
        required => 0},
    LOGUSERAGENT => {
        label => _("Useragent logging"),
        required => 0},
    DANSGUARDIAN_LOGGING => {
        label => _("Contentfilter logging"),
        required => 0},
    LOG_FIREWALL => {
        label => _("Firewall logging (transparent proxies only)"),
        required => 0},
    
    BYPASS_SOURCE => {
        label => _("Bypass transparent proxy from SUBNET/IP/MAC"),
        required => 0,
        checks => ["ip", "subnet", "mac"]},
    BYPASS_DESTINATION => {
        label => _("Bypass transparent proxy to SUBNET/IP"),
        required => 0,
        checks => ["ip", "subnet"]},
    
    CACHE_SIZE => {
        label => _("Cache size on harddisk (MB)"),
        required => 1,
        checks => ["int"]},
    OFFLINE_MODE => {
        label => _("Cache offline mode"),
        required => 0,
        checks => ["int"]},
    CACHE_MEM => {
        label => _("Cache size within memory (MB)"),
        required => 1,
        checks => ["int"]},
    DST_NOCACHE => {
        label => _("Do not cache this destinations"),
        required => 0,
        checks => ["ip", "domain", "subdomain", "fqdn"]},
    MAX_SIZE => {
        label => _("Maximum object size (KB)"),
        required => 1,
        checks => ["int"]},
    MIN_SIZE => {
        label => _("Minimum object size (KB)"),
        required => 1,
        checks => ["int"]},
    CLEAR_CACHE => {
        label => _("Clear cache")},
    
    UPSTREAM_ENABLED => {
        label => _("Upstream proxy"),
        required => 0},
    UPSTREAM_SERVER => {
        label => _("Upstream server"),
        required => 1,
        checks => ["ip", "hostname", "domain", "fqdn"]},
    UPSTREAM_PORT => {
        label => _("Upstream port"),
        required => 1,
        checks => ["port"]},
    UPSTREAM_USER=> {
        label => _("Upstream username"),
        required => 0},
    UPSTREAM_PASSWORD => {
        label => _("Upstream password"),
        required => 0},
    FORWARD_USERNAME => {
        label => _("Client username forwarding"),
        required => 0},
    FORWARD_IPADDRESS => {
        label => _("Client ip forwarding"),
        required => 0},
);

# If it's a new mini, remove the required fields of the cache management.
if (is_new_mini()) {
    foreach my $item ("CACHE_SIZE", "CACHE_MEM", "MAX_SIZE", "MIN_SIZE") {
        delete $field_definition->{$item};
    }
}

showhttpheaders();

my $conf_ref = reload_par();
my %conf = %$conf_ref;
my @checkboxes = ("LOGGING", "LOGQUERY", "TPROXY_NONTRANSPARENT_SPOOF", "LOGUSERAGENT", "DANSGUARDIAN_LOGGING", "LOG_FIREWALL", "OFFLINE_MODE", "FORWARD_IPADDRESS", "FORWARD_IPADDRESS", "UPSTREAM_ENABLED");
my $errormessage = "";

my $cgi_objekt = new CGI;
my $action = $cgi_objekt->param('ACTION');

getcgihash(\%par);
if ( $par{ACTION} eq 'save' ) {
    $par{PROXY_ENABLED} = $par{SERVICE_STATUS};
    $errormessage = validate_fields(\%par);
    if ($errormessage ne "") {
        %conf = %par;
    }
    else {
        my $forcerestart = 0;
        if ($par{PROXY_ENABLED} ne $conf{PROXY_ENABLED}) {
            $forcerestart = 1;
        }
        my $changed = save_settings(\%conf, \%par, \@checkboxes);
        $conf_ref = reload_par();
        %conf = %$conf_ref;
        if ($forcerestart eq 1) {
            $service_restarted = 1;
            system("/usr/local/bin/restartsquid --force");
        }elsif ($changed eq 1) {
            system("touch $proxyrestart");
        }
    }
}
elsif ($par{'ACTION'} eq 'apply'){
    &log(_('Apply proxy settings'));
    applyaction();
}
elsif ( $action eq 'clearcache') {
    $service_restarted = 1;
    system('/usr/local/bin/restartsquid --flush');
}

openpage(_("HTTP Configuration"), 1, 
    '<script type="text/javascript" src="/include/serviceswitch.js"></script>
     <script type="text/javascript" src="/include/fields.js"></script>' . $notification_script);

showapplybox(\%conf);

openbigbox($errormessage, $warnmessage, $notemessage);

render_templates(\%conf);

closebigbox();
closepage();
