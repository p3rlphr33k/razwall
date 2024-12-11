#!/usr/bin/perl
#
# SMTP Proxy CGI for Endian Firewall
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
require '/razwall/web/cgi-bin/smtpscan.pl';

sub get_spam_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "SA_ENABLED",
        V_TOGGLE_ACTION => 1,
        T_CHECKBOX => _("Filter mail for spam")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "FINAL_SPAM_DESTINY", 
        V_OPTIONS => [
            {V_VALUE => "D_DISCARD_DEFAULT",
             T_OPTION => _("move to default quarantine location")},
            {V_VALUE => "D_DISCARD_EMAIL",
             T_OPTION => _("send to quarantine email address")},
            {V_VALUE => "D_PASS",
             T_OPTION => _("mark as spam")},
            {V_VALUE => "D_DROP_EMAIL",
             T_OPTION => _("drop email")},
        ],
        V_TOGGLE_ACTION => 1,
        V_TOGGLE_ID => "sa_enabled",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_selectfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "SA_SPAM_SUBJECT_TAG",
        V_TOGGLE_ID => "sa_enabled",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "SA_TAG_LEVEL_DEFLT",
        V_TOGGLE_ID => "sa_enabled",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "SA_KILL_LEVEL_DEFLT",
        V_TOGGLE_ID => "sa_enabled",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "GREYLISTING_ENABLED",
        V_TOGGLE_ACTION => 1,
        V_TOGGLE_ID => "sa_enabled",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}),
        T_CHECKBOX => _("Activate greylisting for spam")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "GREYLISTING_DELAY",
        V_TOGGLE_ID => "sa_enabled greylisting_enabled",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}) eq 0 && $conf{GREYLISTING_ENABLED} eq "on" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});

    my %params = (
        V_NAME => "JAPANIZATION_ENABLED",
        V_TOGGLE_ACTION => 1,
        V_TOGGLE_ID => "sa_enabled",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}),
        T_CHECKBOX => _("Activate support for Japanese emails")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});

    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    if ($commtouch eq 1) {
        my %params = (
            V_NAME => "COMMTOUCH_ENABLED",
            V_TOGGLE_ACTION => 1,
            V_TOGGLE_ID => "sa_enabled",
            V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}),
            T_CHECKBOX => _("Activate commtouch for spam filtering")
        );
        push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    }
    else {
        my %params = ();
        push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    }
    
    my %params = (
        V_ID => "spam_default_quarantine",
        V_TOGGLE_ID => "sa_enabled final_spam_destiny D_DISCARD_DEFAULT",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}) eq 0 && $conf{FINAL_SPAM_DESTINY} eq "D_DISCARD_DEFAULT" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_ID => "spam_pass",
        V_TOGGLE_ID => "sa_enabled final_spam_destiny D_PASS",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}) eq 0 && $conf{FINAL_SPAM_DESTINY} eq "D_PASS" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
        
    my %params = (
        V_NAME => "SPAM_QUARANTINE_TO_EMAIL",
        V_TOGGLE_ID => "sa_enabled final_spam_destiny D_DISCARD_EMAIL",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}) eq 0 && $conf{FINAL_SPAM_DESTINY} eq "D_DISCARD_EMAIL" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_ID => "spam_drop",
        V_TOGGLE_ID => "sa_enabled final_spam_destiny D_DROP_EMAIL",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}) eq 0 && $conf{FINAL_SPAM_DESTINY} eq "D_DROP_EMAIL" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_NAME => "SPAM_ADMIN",
        V_TOGGLE_ID => "sa_enabled",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "SA_TAG2_LEVEL_DEFLT",
        V_TOGGLE_ID => "sa_enabled",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "SA_DSN_CUTOFF_LEVEL",
        V_TOGGLE_ID => "sa_enabled",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
        
    my %params = (
        V_NAME => "BODY_SUMMARY_ENABLED",
        V_TOGGLE_ACTION => 1,
        V_TOGGLE_ID => "sa_enabled",
        V_HIDDEN => is_field_hidden($conf{"SA_ENABLED"}),
        T_CHECKBOX => _("Add spam report to mail body")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_virus_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "AV_ENABLED",
         V_TOGGLE_ACTION => 1,
        T_CHECKBOX => _("Scan mail for virus")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "FINAL_VIRUS_DESTINY",
        V_OPTIONS => [
            {V_VALUE => "D_DISCARD_DEFAULT",
             T_OPTION => _("move to default quarantine location")},
            {V_VALUE => "D_DISCARD_EMAIL",
             T_OPTION => _("send to quarantine email address")},
            {V_VALUE => "D_PASS",
             T_OPTION => _("pass to recipient (regardless of bad contents)")},
            {V_VALUE => "D_DROP_EMAIL",
             T_OPTION => _("drop email")},
        ],
        V_TOGGLE_ACTION => 1,
        V_TOGGLE_ID => "av_enabled",
        V_HIDDEN => is_field_hidden($conf{"AV_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_selectfield_widget(\%params, \%conf)});

    my %params = (
        V_NAME => "VIRUS_ADMIN",
        V_TOGGLE_ID => "av_enabled",
        V_HIDDEN => is_field_hidden($conf{"AV_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = ();
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_ID => "virus_default_quarantine",
        V_TOGGLE_ID => "av_enabled final_virus_destiny D_DISCARD_DEFAULT",
        V_HIDDEN => is_field_hidden($conf{"AV_ENABLED"}) eq 0 && $conf{FINAL_VIRUS_DESTINY} eq "D_DISCARD_DEFAULT" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_ID => "virus_pass",
        V_TOGGLE_ID => "av_enabled final_virus_destiny D_PASS",
        V_HIDDEN => is_field_hidden($conf{"AV_ENABLED"}) eq 0 && $conf{FINAL_VIRUS_DESTINY} eq "D_PASS" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_NAME => "VIRUS_QUARANTINE_TO_EMAIL",
        V_TOGGLE_ID => "av_enabled final_virus_destiny D_DISCARD_EMAIL",
        V_HIDDEN => is_field_hidden($conf{"AV_ENABLED"}) eq 0 && $conf{FINAL_VIRUS_DESTINY} eq "D_DISCARD_EMAIL" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    
    my %params = (
        V_ID => "virus_drop",
        V_TOGGLE_ID => "av_enabled final_virus_destiny D_DROP_EMAIL",
        V_HIDDEN => is_field_hidden($conf{"AV_ENABLED"}) eq 0 && $conf{FINAL_VIRUS_DESTINY} eq "D_DROP_EMAIL" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_file_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "EXT_ENABLED",
        V_TOGGLE_ACTION => 1,
        T_CHECKBOX => get_field_label("EXT_ENABLED")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "FINAL_BANNED_DESTINY",
        V_OPTIONS => [
            {V_VALUE => "D_DISCARD_DEFAULT",
             T_OPTION => _("move to default quarantine location")},
            {V_VALUE => "D_DISCARD_EMAIL",
             T_OPTION => _("send to quarantine email address")},
            {V_VALUE => "D_PASS",
             T_OPTION => _("pass to recipient (regardless of blocked files)")},
        ],
        V_TOGGLE_ACTION => 1,
        V_TOGGLE_ID => "ext_enabled",
        V_HIDDEN => is_field_hidden($conf{"EXT_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_selectfield_widget(\%params, \%conf)});

    my %params = (
        V_NAME => "BANNED_ADMIN",
        V_TOGGLE_ID => "ext_enabled",
        V_HIDDEN => is_field_hidden($conf{"EXT_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});

    my %params = (
        V_NAME => "BANNEDFILES_ARCHIVE",
        V_TOGGLE_ID => "ext_enabled",
        V_HIDDEN => is_field_hidden($conf{"EXT_ENABLED"}),
        T_CHECKBOX => get_field_label("BANNEDFILES_ARCHIVE")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});

    my @options = ();
    my @file_extensions = read_config_file($extensions_file);
    my @custom_file_extensions = read_config_file($extensions_file_custom);
    push(@file_extensions, @custom_file_extensions);
    
    foreach $line (sort @file_extensions) {
        my @extension = split(/\|/, $line);
        push(@options, {V_VALUE => "$extension[0]",
                        T_OPTION => "$extension[1] (.$extension[0])"});
    };
    
    my %params = (
        V_NAME => "BANNEDFILES", 
        V_OPTIONS => \@options,
        V_TOGGLE_ID => "ext_enabled",
        V_HIDDEN => is_field_hidden($conf{"EXT_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_multiselectfield_widget(\%params, \%conf)});

    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = ();
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_ID => "banned_default_quarantine",
        V_TOGGLE_ID => "ext_enabled final_banned_destiny D_DISCARD_DEFAULT",
        V_HIDDEN => is_field_hidden($conf{"EXT_ENABLED"}) eq 0 && $conf{FINAL_BANNED_DESTINY} eq "D_DISCARD_DEFAULT" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_ID => "banned_pass",
        V_TOGGLE_ID => "ext_enabled final_banned_destiny D_PASS",
        V_HIDDEN => is_field_hidden($conf{"EXT_ENABLED"}) eq 0 && $conf{FINAL_BANNED_DESTINY} eq "D_PASS" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});
    
    my %params = (
        V_NAME => "BANNED_QUARANTINE_TO_EMAIL",
        V_TOGGLE_ID => "ext_enabled final_banned_destiny D_DISCARD_EMAIL",
        V_HIDDEN => is_field_hidden($conf{"EXT_ENABLED"}) eq 0 && $conf{FINAL_BANNED_DESTINY} eq "D_DISCARD_EMAIL" ? 0 : 1,
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});

    my %params = ();
    push(@fields, {H_FIELD => get_emptyfield_widget(\%params)});

    my %params = (
        V_NAME => "DE_ENABLED",
        V_TOGGLE_ID => "ext_enabled",
        V_TOGGLE_ACTION => 1,
        V_HIDDEN => is_field_hidden($conf{"EXT_ENABLED"}),
        T_CHECKBOX => get_field_label("DE_ENABLED")
    );
    push(@fields, {H_FIELD => get_checkboxfield_widget(\%params, \%conf)});

    my %params = (
        V_NAME => "DE_LIST",
        V_TOGGLE_ID => "ext_enabled de_enabled",
        V_HIDDEN => is_field_hidden($conf{"DE_ENABLED"}) || is_field_hidden($conf{"EXT_ENABLED"}),
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});

    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub get_quarantine_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (V_NAME => "QUARANTINE_RETENTION");
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});
    my %fparams = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%fparams);
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

sub render_templates($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my $template = get_zonestatus_widget(_("Unfold to define the status of the SMTP proxy per zone (active, transparent mode, inactive)."), 
                                            \%conf, "", 1);
    
    my %accordionparams = (
        V_ACCORDION => [
            {T_TITLE => _("Spam settings"),
             T_DESCRIPTION => _("Unfold to define the anti spam settings of the SMTP proxy (handling, spam admin, quarantine location, spam subject, tag / mark / quarantine level)."),
             H_CONTAINER => get_spam_form(\%conf),
             V_HIDDEN => 1},
            {T_TITLE => _("Virus settings"),
             T_DESCRIPTION => _("Unfold to define the anti virus settings of the SMTP proxy (handling; virus admin; quarantine location)."),
             H_CONTAINER => get_virus_form(\%conf),
             V_HIDDEN => 1},
            {T_TITLE => _("File settings"),
             T_DESCRIPTION => _("Unfold to define which files should be blocked by the SMTP proxy (handling, file admin, quarantine location, file types)."),
             H_CONTAINER => get_file_form(\%conf),
             V_HIDDEN => 1},
            {T_TITLE => _("Quarantine settings"),
             T_DESCRIPTION => _("Unfold to define the quarantine settings."),
             H_CONTAINER => get_quarantine_form(\%conf),
             V_HIDDEN => 1},
            {T_TITLE => _("Bypass transparent proxy"),
             T_DESCRIPTION => _("Unfold to define when to bypass the transparent proxy (bypass from source, bypass to destination)."),
             H_CONTAINER => get_bypass_form(\%conf),
             V_HIDDEN => 1},
        ]
    );
    
    $template .= get_accordion_widget(\%accordionparams);
    
    my %switchparams = (
        V_SERVICE_ON => $conf{"SMTPSCAN_ENABLED"},
        V_SERVICE_AJAXIAN_SAVE => 1,
        H_OPTIONS_CONTAINER => $template,
        T_SERVICE_TITLE => _('Enable SMTP Proxy'),
        T_SERVICE_STARTING => _("The SMTP Proxy is being enabled. Please hold..."),
        T_SERVICE_SHUTDOWN => _("The SMTP Proxy is being disabled. Please hold..."),
        T_SERVICE_RESTARTING => _("The SMTP Proxy is being restarted. Please hold..."),
        T_SERVICE_STARTED => _("The SMTP Proxy was restarted successfully"),
        T_SERVICE_DESCRIPTION => _("Use the switch above to set the status of the SMTP Proxy. Click on the save button below to make the changes active."),
    );
    
    print get_switch_widget(\%switchparams);
}

sub validate_fields($) {
    my $params_ref = shift;
    my %params = %$params_ref;
    my $errors = "";
    
    if ($params{SA_ENABLED} eq "on") {
        $errors .= check_field("FINAL_SPAM_DESTINY", \%params);
        if ($params{FINAL_SPAM_DESTINY} eq "D_DISCARD_EMAIL") {
            $errors .= check_field("SPAM_QUARANTINE_TO_EMAIL", \%params); 
        }
        $errors .= check_field("SA_SPAM_SUBJECT_TAG", \%params);
        $errors .= check_field("SPAM_ADMIN", \%params);
        $errors .= check_field("SA_TAG_LEVEL_DEFLT", \%params);
        $errors .= check_field("SA_TAG2_LEVEL_DEFLT", \%params);
        $errors .= check_field("SA_KILL_LEVEL_DEFLT", \%params);
        $errors .= check_field("SA_DSN_CUTOFF_LEVEL", \%params);

        $errors .= check_field("QUARANTINE_RETENTION", \%params);

        if ($params{GREYLISTING_ENABLED} eq "on") {
            $errors .= check_field("GREYLISTING_DELAY", \%params);
        }
    }
    
    if ($params{AV_ENABLED} eq "on") {
        $errors .= check_field("FINAL_VIRUS_DESTINY", \%params);
        if ($params{FINAL_VIRUS_DESTINY} eq "D_DISCARD_EMAIL") {
            $errors .= check_field("VIRUS_QUARANTINE_TO_EMAIL", \%params); 
        }
        $errors .= check_field("VIRUS_ADMIN", \%params);
    }
    
    if ($params{EXT_ENABLED} eq "on") {
        $errors .= check_field("FINAL_BANNED_DESTINY", \%params);
        if ($params{FINAL_VIRUS_DESTINY} eq "D_DISCARD_EMAIL") {
            $errors .= check_field("BANNED_QUARANTINE_TO_EMAIL", \%params); 
        }
        $errors .= check_field("BANNED_ADMIN", \%params);
        if ($params{DE_ENABLED} eq "on") {
            $errors .= check_field("DE_LIST", \%params);
        }
    }
    
    $errors .= check_field("BYPASS_SOURCE", \%params);
    $errors .= check_field("BYPASS_DESTINATION", \%params);
    
    return $errors;
}

%field_definition = (
    SA_ENABLED => {
        label => _("Mail spam filter"),
        required => 1},
    COMMTOUCH_ENABLED => {
        label => _("Commtouch spam engine"),
        required => 1},
    FINAL_SPAM_DESTINY => {
        label => _("Choose spam handling"),
        required => 1},
    SA_SPAM_SUBJECT_TAG => {
        label => _("Spam subject"),
        required => 0},
    GREYLISTING_ENABLED => {
        label => _("Spam filtering"),
        required => 1},
    SPAM_QUARANTINE_TO_EMAIL => {
        label => _("Spam quarantine email address"),
        required => 1,
        checks => ["email"]},
    SPAM_ADMIN => {
        label => _("Email used for spam notifications (spam admin)"),
        checks => ["email"]},
    SA_TAG_LEVEL_DEFLT => {
        label => _("Spam tag level"),
        required => 1,
        checks => ["float"]},
    SA_TAG2_LEVEL_DEFLT => {
        label => _("Spam mark level"),
        required => 1,
        checks => ["float"]},
    SA_KILL_LEVEL_DEFLT => {
        label => _("Spam quarantine level"),
        required => 1,
        checks => ["float"]},
    SA_DSN_CUTOFF_LEVEL => {
        label => _("Send notification only below level"),
        required => 1,
        checks => ["float"]},
                
    GREYLISTING_DELAY => {
        label => _("Delay for greylisting (sec)"),
        required => 1,
        checks => ["int"]},
    
    AV_ENABLED => {
        label => _("Mail virus scanner"),
        required => 1},
    FINAL_VIRUS_DESTINY => {
        label => _("Choose virus handling"),
        required => 1},
    VIRUS_QUARANTINE_TO_EMAIL => {
        label => _("Virus quarantine email address"),
        required => 1,
        checks => ["email"]},
    VIRUS_ADMIN => {
        label => _("Email used for virus notifications (virus admin)"),
        checks => ["email"]},
    
    EXT_ENABLED => {
        label => _("Block files by extension"),
        required => 1},
    FINAL_BANNED_DESTINY => {
        label => _("Choose handling of blocked files"),
        required => 1},
    BANNEDFILES => {
        label => _("Choose filetypes to block (by extension)")},
    BANNED_QUARANTINE_TO_EMAIL => {
        label => _("Blocked files quarantine email address"),
        required => 1,
        checks => ["email"]},
    BANNED_ADMIN => {
        label => _("Email used for blocked file notifications (file admin)"),
        checks => ["email"]},
    DE_ENABLED => {
        label => _("Block files with double extension")},
    DE_LIST => {
        label => _("Block files with double extensions ending in"),
        checks => ["ext"],
        description => _("Example:<br/><br/>.exe<br/>.cmd")},
    BANNEDFILES_ARCHIVE => {
        label => _("Block archives that contain blocked filetypes"),
        required => 1},
    
    QUARANTINE_RETENTION => {
        label => _("Quarantine retention time (in days)"),
	checks => ["int"],
        required => 1},

    BYPASS_SOURCE => {
        label => _("Bypass transparent proxy from SUBNET/IP/MAC"),
        required => 0,
        checks => ["ip", "subnet", "mac"]},
    BYPASS_DESTINATION => {
        label => _("Bypass transparent proxy to SUBNET/IP"),
        required => 0,
        checks => ["ip", "subnet"]},
    JAPANIZATION_ENABLED => {
        label => _("Japanization"),
        required => 1},
    BODY_SUMMARY_ENABLED => {
        label => _("Spam report"),
        required => 1},
);

showhttpheaders();

(my $default_conf_ref, my $conf_ref) = reload_par();
my %default_conf = %$default_conf_ref;
my %conf = %$conf_ref;
my @checkboxes = ("SA_ENABLED", "COMMTOUCH_ENABLED", "AV_ENABLED", "EXT_ENABLED", "GREYLISTING_ENABLED", "DE_ENABLED","JAPANIZATION_ENABLED", "BODY_SUMMARY_ENABLED", "BANNEDFILES_ARCHIVE");
my $errormessage = "";
                
getcgihash(\%par);
if ( $par{ACTION} eq 'save' ) {
    $par{SMTPSCAN_ENABLED} = $par{SERVICE_STATUS};
    $errormessage = validate_fields(\%par);
    if ($errormessage ne "") {
        %conf = %par;
    }
    else {
        my $forcerestart = 0;
        if ($par{SMTPSCAN_ENABLED} ne $conf{SMTPSCAN_ENABLED}) {
            $forcerestart = 1;
        }
        my $changed = save_settings(\%default_conf, \%conf, \%par, \@checkboxes);
        ($default_conf_ref, $conf_ref) = reload_par();
        %default_conf = %$default_conf_ref;
        %conf = %$conf_ref;
        if ($forcerestart eq 1) {
            $service_restarted = 1;
            system("/usr/local/bin/restartsmtpscan >/dev/null 2>&1");
        }elsif ($changed eq 1) {
            system("touch $proxyrestart");
        }
    }
}
elsif ($par{'ACTION'} eq 'apply') {
    &log(_('Apply proxy settings'));
    applyaction();
}

openpage(_("SMTP Configuration"), 1, 
    '<script type="text/javascript" src="/include/serviceswitch.js"></script>
     <script type="text/javascript" src="/include/fields.js"></script>' . $notification_script);

showapplybox(\%conf);

openbigbox($errormessage, $warnmessage, $notemessage);

render_templates(\%conf);

closebigbox();
closepage();
