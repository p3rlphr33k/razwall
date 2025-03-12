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

sub get_ncsauser($$$) {
    my $conf_ref = shift;
    my $id = shift;
    my $action = shift;
    
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "user",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});

    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my %params = (
        V_NAME => "pass",
        V_VALUE => $action eq "edit" ? "lEaVeAlOnE" : ""
    );
    push(@fields, {H_FIELD => get_passwordfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    my %params = (
        H_CONTAINER => $form,
        T_ADDRULE => _("Add NCSA user"),
        T_TITLE => _("NCSA user"),
        T_SAVE => $action eq "edit" ? _("Update user") : _("Create user"),
        V_OPEN => $action eq "edit" ? 1 : 0,
        V_ID => $action eq "edit" ? $id : ""
    );
    my $content = get_editorbox_widget(\%params);
    
    my @rows = ();
    my $num = 1;
    
    my @users = read_config_file($ncsauser_file, 0);
    
    foreach my $thisline (@users) {
        chomp($thisline);
        my @splitted = split(/:/, $thisline);
        my $user = @splitted[0];
        my @cols = ();

        push(@cols, {V_CELL_CONTENT => $num});
        push(@cols, {V_CELL_CONTENT => @splitted[0]});
        
        my %params = (
            V_COLS => \@cols,
            STYLE => setbgcolor($action eq "edit" ? 1 : 0, $id, ($num - 1)),
            EDIT_ACTION => "window.open('" . $ENV{'SCRIPT_NAME'} . "?ACTION=edit&ID=" . ($num - 1) . "','_self');",
            REMOVE_ACTION => "window.open('" . $ENV{'SCRIPT_NAME'} . "?ACTION=remove&ID=" . ($num - 1) . "','_self');",
        );
        push(@rows, \%params);
        
        $num += 1;
    }
    
    my %params = (
        V_HEADINGS => [
            {HEADING => "#"},
            {HEADING => _("username")},
        ],
        V_ACTIONS => 1,
        V_ROWS => \@rows,
    );
    $content .= get_listtable_widget(\%params);
    
    return $content;
}

sub render_templates($$$) {
    my $conf_ref = shift;
    my $id = shift;
    my $action = shift;
    my %conf = %$conf_ref;
    
    print get_ncsauser(\%conf, $id, $action);
}

sub validate_fields($$) {
    my $params_ref = shift;
    my $conf_ref = shift;
    my %params = %$params_ref;
    my %conf = %$conf_ref;
    my $errors = "";
    
    $errors .= check_field("user", \%params);
    $errors .= check_field("pass", \%params);
    
    my @users = read_config_file($ncsauser_file, 0);
    my $line = 0;
    foreach my $thisline (@users) {
        chomp($thisline);
        my @splitted = split(/:/, $thisline);
        if (@splitted[0] eq $params{'user'} && $line ne $params{'ID'}) {
            $errors .= _("\"%s\" %s already exists!", $params{'user'}, _("Username"));
            last;
        }
        $line += 1;
    }
    if (length($params{'pass'}) < $conf{NCSA_MIN_PASS_LEN} && $params{'pass'} ne "lEaVeAlOnE") {
        $errors .= _("Length of \"%s\" is not valid!", _("Password"));
    }
    return $errors;
}

%field_definition = (
    user => {
        label => _("Username"),
        required => 1},
    pass => {
        label => _("Password"),
        required => 1},
);

showhttpheaders();
my $conf_ref = reload_par();
my %conf = %$conf_ref;
my @checkboxes = ();
my $errormessage = "";

getcgihash(\%par);
my $cgi_objekt = new CGI;
my $action = $cgi_objekt->param('ACTION');
my $id = $cgi_objekt->param('ID');

if ( $par{ACTION} eq 'save' ) {
    $errormessage = validate_fields(\%par, \%conf);
    
    if ($errormessage ne "") {
        %conf = %par;
    }
    else {
        save_user(
            $par{'ID'},
            $par{'user'},
            $par{'pass'},
	    1
        );
        system("touch $proxyreload");
    }
}
if ($action eq "edit") {
    %conf = user_line(read_config_line($id, $ncsauser_file, 0));
    system("touch $proxyreload");
}
elsif ($action eq "remove") {
    delete_line($id, $ncsauser_file, 0);
    system("touch $proxyreload");
}
elsif ($par{'ACTION'} eq 'apply'){
    &log(_('Apply proxy settings'));
    applyaction();
}

openpage(_("HTTP NCSA user"), 1, 
    '<script type="text/javascript" src="/include/fields.js"></script>' . $notification_script);

showapplybox(\%conf);

openbigbox($errormessage, $warnmessage, $notemessage);

render_templates(\%conf, $id, $action);

closebigbox();
closepage();
