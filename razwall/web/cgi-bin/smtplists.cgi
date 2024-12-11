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

sub get_rbl_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @ipsubcategories = ();
    my @domainsubcategories = ();
    
    @rbl_file = read_config_file($rbl_file);
    foreach $line (@rbl_file) {        
        my @rbl = split(/\|/, $line);
        if( $rbl[3] ne '') {
            $link = $rbl[3];
        }
        else {
            $link = $rbl[1];
        }
        if($rbl[2] eq "IP") {
            push(@ipsubcategories, {T_TITLE => $rbl[1], V_NAME => $rbl[0], V_HREF => $link, V_ALLOWED => $conf{$rbl[0]} });
        }
        elsif($rbl[2] eq "DOMAIN") {
            push(@domainsubcategories, {T_TITLE => $rbl[1], V_NAME => $rbl[0], V_HREF => $link, V_ALLOWED => $conf{$rbl[0]} });
        }
    }
    
    # print "<tr><td width='20%'>$link</td><td><input type='checkbox' name=$rbl[0] $checked{$rbl[0]} /></td><td><b>$rbl[2]</b></td></tr>";
    # push(@subcategories, {T_TITLE => $rbl[1], V_NAME => $rbl[0], V_ALLOWED => 1});
    # push(@subcategories, {T_TITLE => "subtitle", V_NAME => "subname", V_ALLOWED => 0});
    
    my @fields = ();
    my %params = (T_TITLE => _("IP based RBL"), V_NAME => "IP", V_SUBCATEGORIES => \@ipsubcategories);
    push(@fields, {H_FIELD => get_category_widget(\%params)});
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    my %params = (T_TITLE => _("DOMAIN based RBL"), V_NAME => "DOMAIN", V_SUBCATEGORIES => \@domainsubcategories);
    push(@fields, {H_FIELD => get_category_widget(\%params)});
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    $string1 = _("RBL enabled");
    $string2 = _("RBL disabled");
    $form .= "<br class=\"cb\" /><div style=\"float: left; padding-right: 10px;\"><img src=\"/images/accept.png\"/><span style=\"padding-left: 5px;\">$string1</span></div>
              <div style=\"float: left; padding-right: 10px;\"><img src=\"/images/deny.png\"/><span style=\"padding-left: 5px;\">$string2</span></div>";
    return $form;
}

sub get_list_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "SENDER_WHITELIST",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "RECIPIENT_WHITELIST",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "CLIENT_WHITELIST",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "SENDER_BLACKLIST",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "RECIPIENT_BLACKLIST",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (
        V_NAME => "CLIENT_BLACKLIST",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);

    return $form;
}

sub get_spam_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "SPAM_WHITELIST",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "SPAM_BLACKLIST",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}


sub get_grey_form($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "WHITELIST_RECIPIENT",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "WHITELIST_CLIENT",
    );
    push(@fields, {H_FIELD => get_textareafield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    return $form;
}

sub render_templates($) {
    my $conf_ref = shift;
    my %conf = %$conf_ref;
        
    my %accordionparams = (
        V_ACCORDION => [
            {T_TITLE => _("Accepted mail (Black- & Whitelists)"),
             T_DESCRIPTION => _("Unfold to white- and/or blacklist sender, recipient or clients when mail is accepted"),
             H_CONTAINER => get_list_form(\%conf)},
            {T_TITLE => _("Realtime Blacklist (RBL)"),
             T_DESCRIPTION => _("Unfold to enable/disable Realtime Blacklists (automatic blacklisting by ips or domains)."),
             H_CONTAINER => get_rbl_form(\%conf),
             V_HIDDEN => 1},
            {T_TITLE => _("Spam greylistling (Whitelists)"),
             T_DESCRIPTION => _("Unfold to whitelist sender/client from Spam greylisting."),
             H_CONTAINER => get_grey_form(\%conf),
             V_HIDDEN => 1},
            {T_TITLE => _("Spam (Black- & Whitelists)"),
             T_DESCRIPTION => _("Unfold to white- and/or blacklist sender, recipient or clients from spamfiltering."),
             H_CONTAINER => get_spam_form(\%conf),
             V_HIDDEN => 1}
        ]
    );
    
    my %params = (
        H_FORM_CONTAINER => get_accordion_widget(\%accordionparams),
    );
    
    print get_saveform_widget(\%params);
}

sub validate_fields($) {
    my $params_ref = shift;
    my %params = %$params_ref;
    my $errors = "";
    
    $errors .= check_field("SENDER_WHITELIST", \%params);
    $errors .= check_field("RECIPIENT_WHITELIST", \%params);
    $errors .= check_field("CLIENT_WHITELIST", \%params);
    $errors .= check_field("SENDER_BLACKLIST", \%params);
    $errors .= check_field("RECIPIENT_BLACKLIST", \%params);
    $errors .= check_field("CLIENT_BLACKLIST", \%params);
    $errors .= check_field("WHITELIST_RECIPIENT", \%params);
    $errors .= check_field("WHITELIST_CLIENT", \%params);
    $errors .= check_field("SPAM_WHITELIST", \%params);
    $errors .= check_field("SPAM_BLACKLIST", \%params);
    return $errors;
}

%field_definition = (
    SENDER_WHITELIST => {
        label => _("Whitelist sender"),
        description => _("Examples:<br/><br/>whitelist a domain(with subdomains):<br/>example.com<br/><br/>whitelist only subdomains:<br/>.example.com<br/><br/>whitelist a single address:<br/>info\@example.com<br/>admin\@example.com"),
        checks => ["email", "domain", "subdomain"]},
    RECIPIENT_WHITELIST => {
        label => _("Whitelist recipient"),
        description => _("Examples:<br/><br/>whitelist a domain(with subdomains):<br/>example.com<br/><br/>whitelist only subdomains:<br/>.example.com<br/><br/>whitelist a single address:<br/>info\@example.com<br/>admin\@example.com"),
        checks => ["email", "domain", "subdomain"]},
    CLIENT_WHITELIST => {
        label => _("Whitelist client"),
        description => _("Examples:<br/><br/>whitelist IPs:<br/>192.168.100.0/24<br/>"),
        checks => ["ip", "subnet"]},
    SENDER_BLACKLIST => {
        label => _("Blacklist sender"),
        description => _("Examples:<br/><br/>blacklist a domain(with subdomains):<br/>example.com<br/><br/>blacklist only subdomains:<br/>.example.com<br/><br/>blacklist a single address:<br/>info\@example.com<br/>admin\@example.com"),
        checks => ["email", "domain", "subdomain"]},
    RECIPIENT_BLACKLIST => {
        label => _("Blacklist recipient"),
        description => _("Examples:<br/><br/>blacklist a domain(with subdomains):<br/>example.com<br/><br/>blacklist only subdomains:<br/>.example.com<br/><br/>blacklist a single address:<br/>info\@example.com<br/>admin\@example.com"),
        checks => ["email", "domain", "subdomain"]},
    CLIENT_BLACKLIST => {
        label => _("Blacklist client"),
        description => _("Examples:<br/><br/>blacklist IPs:<br/>192.168.100.0/24<br/>"),
        checks => ["ip", "subnet"]},

    SPAM_WHITELIST => {
        label => _("Whitelist sender"),
        description => _("Examples:<br/><br/>whitelist a domain(with subdomains):<br/>example.com<br/><br/>whitelist only subdomains:<br/>.example.com<br/><br/>whitelist a single address:<br/>info\@example.com<br/>admin\@example.com"),
        checks => ["email", "domain", "subdomain"]},
    SPAM_BLACKLIST => {
        label => _("Blacklist sender"),
        description => _("Examples:<br/><br/>blacklist a domain(with subdomains):<br/>example.com<br/><br/>blacklist only subdomains:<br/>.example.com<br/><br/>blacklist a single address:<br/>info\@example.com<br/>admin\@example.com"),
        checks => ["email", "domain", "subdomain"]},

    WHITELIST_RECIPIENT => {
        label => _("Whitelist recipient"),
        description => _("Examples:<br/><br/>whitelist a domain(with subdomains):<br/>example.com<br/><br/>whitelist only subdomains:<br/>.example.com<br/><br/>whitelist a single address:<br/>info\@example.com<br/>admin\@example.com"),
        checks => ["email", "domain", "subdomain"]},
    WHITELIST_CLIENT => {
        label => _("Whitelist client"),
        description => _("Examples:<br/><br/>whitelist a domain/IPs:<br/>example.com<br/>192.168.100.0/24<br/>"),
        checks => ["ip", "subnet", "domain"]},
);

showhttpheaders();

(my $default_conf_ref, my $conf_ref) = reload_par();
my %default_conf = %$default_conf_ref;
my %conf = %$conf_ref;
my $errormessage = "";

getcgihash(\%par);

if ( $par{ACTION} eq 'save' ) {
    $errormessage = validate_fields(\%par);
    if ($errormessage ne "") {
        %conf = %par;
    }
    else {
        my $changed = save_settings(\%default_conf, \%conf, \%par, \@checkboxes);
        ($default_conf_ref, $conf_ref) = reload_par();
        %default_conf = %$default_conf_ref;
        %conf = %$conf_ref;
        if ($changed eq 1) {
            system("touch $proxyrestart");
        }
    }
}
elsif ($par{'ACTION'} eq 'apply') {
    &log(_('Apply proxy settings'));
    applyaction();
}

# <script type="text/javascript" src="/include/jquery-ui.packed.js"></script>

openpage(_("SMTP Black- & Whitelists"), 1, 
    '<script type="text/javascript" src="/include/category.js"></script>
     <script type="text/javascript" src="/include/fields.js"></script>' . $notification_script);

showapplybox(\%conf);

openbigbox($errormessage, $warnmessage, $notemessage);

render_templates(\%conf);

closebigbox();
closepage();