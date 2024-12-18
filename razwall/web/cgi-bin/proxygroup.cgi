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

sub get_ncsagroup($$$) {
    my $conf_ref = shift;
    my $id = shift;
    my $action = shift;
    my %conf = %$conf_ref;
    
    my @fields = ();
    
    my %params = (
        V_NAME => "group",
    );
    push(@fields, {H_FIELD => get_textfield_widget(\%params, \%conf)});

    my %params = (V_FIELDS => \@fields);
    my $form = get_form_widget(\%params);
    
    my @fields = ();
    
    my @users = read_config_file($ncsauser_file, 0);
    my @options = ();
    foreach my $thisline (@users) {
        chomp($thisline);
        my %splitted = user_line($thisline);
        push(@options, {V_VALUE => $splitted{'user'}, T_OPTION => $splitted{'user'}});
    }
    my %params = (
        V_NAME => "users", 
        V_OPTIONS => \@options
    );
    push(@fields, {H_FIELD => get_multiselectfield_widget(\%params, \%conf)});
    
    my %params = (V_FIELDS => \@fields);
    $form .= get_form_widget(\%params);
    
    my %params = (
        H_CONTAINER => $form,
        T_ADDRULE => _("Add NCSA group"),
        T_TITLE => _("NCSA group"),
        T_SAVE => $action eq "edit" ? _("Update group") : _("Create group"),
        V_OPEN => $action eq "edit" ? 1 : 0,
        V_ID => $action eq "edit" ? $id : ""
    );
    my $content = get_editorbox_widget(\%params);
    
    my @rows = ();
    my $num = 1;
    
    my @groups = read_config_file($ncsagroup_file, 0);
    
    foreach my $thisline (@groups) {
        chomp($thisline);
        my %splitted = group_line($thisline);
        my @cols = ();
        
        push(@cols, {V_CELL_CONTENT => $num});
        push(@cols, {V_CELL_CONTENT => $splitted{'group'}});
        
        my $users = $splitted{'users'};
        $users =~ s/\|/<br \/>/g;
        push(@cols, {V_CELL_CONTENT => $users});
        
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
            {HEADING => _("groupname")},
            {HEADING => _("users")},
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
    
    print get_ncsagroup(\%conf, $id, $action);
}

sub validate_fields($) {
    my $params_ref = shift;
    my %params = %$params_ref;
    my $errors = "";

    return $errors;
}

%field_definition = (
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

if ( $par{ACTION} eq "save" ) {
    $errormessage = validate_fields(\%par);
    if ($errormessage ne "") {
        %conf = %par;
    }
    else {
        save_group(
            $par{'ID'},
            $par{'group'},
            $par{'users'}
        );
        system("touch $proxyreload");
    }
}
if ($action eq "edit") {
    %conf = group_line(read_config_line($id, $ncsagroup_file, 0));
    system("touch $proxyreload");
}
elsif ($action eq "remove") {
    delete_line($id, $ncsagroup_file, 0);
    system("touch $proxyreload");
}
elsif ($par{'ACTION'} eq 'apply'){
    &log(_('Apply proxy settings'));
    applyaction();
}

openpage(_("HTTP NCSA groups"), 1, 
    '<script type="text/javascript" src="/include/fields.js"></script>' . $notification_script);

showapplybox(\%conf);

openbigbox($errormessage, $warnmessage, $notemessage);

render_templates(\%conf, $id, $action);

closebigbox();
closepage();
