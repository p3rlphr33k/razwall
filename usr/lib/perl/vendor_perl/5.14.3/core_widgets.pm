#!/usr/bin/perl
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

sub stripdesc
{
    my $sring = $_[0];
    my @arr = split(/#/,$string);
    my $item = @arr[0];
    $item =~ s/^\s+//;
    $item =~ s/\s+$//;
    return item;
}

sub validsubnet($) {
    my $addr = shift;
    if ($addr !~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?:\/(\d{1,2}))?$/) {
		return 0;
    }

    my @parts = {$1, $2, $3, $4};
    my $cidr = '';
    if ($5) {
		$cidr = $5;
    }
    foreach my $number (@parts) {
		$number = s/\D//;
		if (($number < 0) || ($number > 255)) {
	    	return 0;
		}
    }
    if ($cidr ne '') {
		if (($cidr < 0) || ($cidr > 32)) {
	    	return 0;
		}
    }

    return 1;
}

sub validsubdomainname
{
    # Checks a domain name against RFC1035
    my $domainname = $_[0];
    my @parts = split (/\./, $domainname);	# Split hostname at the '.'
    my $partnumber = 1;
    
    foreach $part (@parts) {
        # Each part should be at least one characters in length 
        # but no more than 63 characters
        if (($partnumber ne 1 && length ($part) < 1) || length ($part) > 63) {
            return 0;}
        
        # Only valid characters are a-z, A-Z, 0-9 and - and also * if firstpart
        if ($partnumber eq 1) {
            if ($part !~ /^[\*a-zA-Z0-9-]*$/) {
                return 0;}
            if (substr ($part, 0, 1) !~ /^[\*a-zA-Z0-9]*$/) {
                return 0;}
        }
        else {
            # Only valid characters are a-z, A-Z, 0-9 and -
            if ($part !~ /^[a-zA-Z0-9-]*$/) {
                return 0;}
            # First character can only be a letter or a digit
            if (substr ($part, 0, 1) !~ /^[a-zA-Z0-9]*$/) {
                return 0;}
        }
        # Last character can only be a letter or a digit
        if (length($part) > 1 && substr ($part, -1, 1) !~ /^[a-zA-Z0-9]*$/) {
            return 0;}
        $partnumber += 1;
    }
    return 1;
}

sub validsubdomainname
{
    # Checks a domain name against RFC1035
    my $domainname = $_[0];
    my @parts = split (/\./, $domainname);	# Split hostname at the '.'
    my $partnumber = 1;
    
    foreach $part (@parts) {
        # Each part should be at least one characters in length 
        # but no more than 63 characters
        if (($partnumber ne 1 && length ($part) < 1) || length ($part) > 63) {
            return 0;}
        # Only valid characters are a-z, A-Z, 0-9 and -
        if ($part !~ /^[a-zA-Z0-9-]*$/) {
            return 0;}
        # First character can only be a letter or a digit
        if (substr ($part, 0, 1) !~ /^[a-zA-Z0-9]*$/) {
            return 0;}
        # Last character can only be a letter or a digit
        if (substr ($part, -1, 1) !~ /^[a-zA-Z0-9]*$/) {
            return 0;}
        $partnumber += 1;
    }
    return 1;
}

sub validfloat
{
    my $number = $_[0];
    if ($number =~ /^[+-]?\d+[\.]{1}\d+$/ ) {
        return 1;
    }
    if (validint($number) eq 1) {
        return 1;
    }
    return 0;
}

sub validint
{
    my $number = $_[0];
    if ($number =~ /^[+-]?\d+$/ ) {
        return 1;
    }
    return 0;
}

sub validextension
{
    my $ext = $_[0];
    if ($ext =~ /^\.[a-zA-Z0-9]+$/ ) {
        return 1;
    }
    return 0;
}

###########################################################
# FORM FIELD VALIDATION METHODS and HELPER METHODS ########
###########################################################

sub is_field_required($) {
    my $name = shift;
    my $field_ref = $field_definition{$name};
    my %field = %$field_ref;
    
    return $field{required} eq 1 ? 1 : 0;
}

sub is_field_filepath($) {
    return 1;
}

sub is_field_int($) {
    return 1;
}

sub get_field_label($) {
    my $name = shift;
    my $field_ref = $field_definition{$name};
    my %field = %$field_ref;
    
    return $field{label} ne "" ? $field{label} : $name;
}

sub get_field_description($) {
    my $name = shift;
    my $field_ref = $field_definition{$name};
    my %field = %$field_ref;
    
    return $field{description} ne "" ? $field{description} : "";
}

sub is_field_checked($) {
    my $checkvalue = shift;
    return $checkvalue eq "on" ? 1 : 0;
}

sub is_field_hidden($) {
    my $togglevalue = shift;
    return $togglevalue eq "on" ? 0 : 1;
}

sub get_field_selection($) {
    my $selectionstring = shift;
    
    my @selectionlist = split(/\|/, $selectionstring);
    my %selection;
    foreach $line (@selectionlist) {
        $selection{$line} = 1;
    };
    
    return \%selection
}

sub check_field($$) {
    my $name = shift;
    my $params_ref = shift;
    
    my %params = %$params_ref;
    my @errors = ();
    my $message = "";
    
    if (is_field_required($name) eq 1 && $params{$name} eq "") {
        push(@errors, _("\"%s\" is required!", get_field_label($name)) . "<br />");
    }
    
    my $field_ref = $field_definition{$name};
    my %field = %$field_ref;
    
    if (exists($field{checks}) && $params{$name} ne "") {
        my $overallvalid = 1;
        foreach my $item (split(/\n/, $params{$name})) {
            $item =~ s/[\r\n]//g;
            my $valid = 0;
            foreach $check (@{$field{checks}}) {                
                if ($check eq "email") {
                    $valid = validemail($item);
                }
                if ($check eq "ip") {
                    $valid = validip($item);
                }
                if ($check eq "subnet") {
                    $valid = validsubnet($item);
				}
                if ($check eq "mac") {
                    $valid = validmac($item);
                }
                if ($check eq "port") {
                    $valid = validport($item);
                }
                if ($check eq "portdesc") {
                    $valid = validport(stripdesc($item));
                }
                if ($check eq "portrange") {
                    $valid = validportrange($item);
                }
                if ($check eq "portrangedesc") {
                    $valid = validportrange(stripdesc($item));
                }
                if ($check eq "hostname") {
                    $valid = validhostname($item);
                }
                if ($check eq "domain") {
                    $valid = validdomainname($item);
                }
                if ($check eq "subdomain") {
                    $valid = validsubdomainname($item);
                }
                if ($check eq "fqdn") {
                    $valid = validfqdn($item);
                }
                if ($check eq "int") {
                    $valid = validint($item);
                }
                if ($check eq "float") {
                    $valid = validfloat($item);
                }
                if ($check eq "ext") {
                    $valid = validextension($item);
                }
                if ($valid eq 1) {
                    last;
                }
            }
            if ($valid eq 0) {
                push(@errors, _("\"%s\" at \"%s\" is not valid!", $item, get_field_label($name)) . "<br />");
            }
        }
    }
    
    foreach $error (@errors) {
        $message .= $error;
    }
    return $message;
}

###############################
# RENDER METHODS       ########
###############################

sub get_widget($$) {
    
    use HTML::Template::Expr;
    
    my $filename = shift;
    my $values_ref = shift;
    my %values = %$values_ref;
    
    my $template = HTML::Template::Expr->new(filename => $filename,
                                                die_on_bad_params => 0);
    $template->param(%values);
    return $template->output();
}

sub get_field_widget($$) {
    my $filename = shift;
    my $params_ref = shift;
    
    my %params = %$params_ref;
    
    $params{V_TEMPLATE} = $filename;
    
    if (!exists $params{V_ID} && exists $params{V_NAME}) {
        $params{V_ID} = lc($params{V_NAME});
    }
    
    if (!exists $params{V_REQUIRED}) {
        $params{V_REQUIRED} = is_field_required($params{V_NAME});
    }
    if (!exists $params{T_LABEL}) {
        $params{T_LABEL} = get_field_label($params{V_NAME});
    }
    if (!exists $params{T_DESCRIPTION}) {
        $params{T_DESCRIPTION} = get_field_description($params{V_NAME});
    }
    
    return get_widget($filename, \%params);
    
}

###############################
# FORM FIELD TEMPLATES ########
###############################

sub get_emptyfield_widget($) {
    # params (hashref):
    #     V_HIDDEN (optional)
    #         desc - defines if this field is visible
    #         value - 1 if true, 0 if false (default=0)
    #     V_TOGGLE_ID (optional)
    #         desc - id of field which toggles this field
    #         value - string (default=undefined)
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    if (!exists $params{V_STYLE} || $params{V_STYLE} eq "") {
        $params{V_STYLE} = "padding-bottom: 56px;";
    }
    
    return get_field_widget("/usr/share/efw-gui/core/widgets/empty.pltmpl", \%params);
}

sub get_textfield_widget($$) {
    # params (hashref):
    #     V_ID (required)
    #         desc - id of the field, label id=<id>_field
    #         value - string
    #         required
    #     V_NAME (required)
    #         desc - name of the field, used by post
    #         value - string
    #     V_VALUE (required)
    #         desc - value of the field
    #         value - string
    #     V_REQUIRED (optional)
    #         desc - show * if required
    #         value - 1 if true, 0 if false (default=0)
    #     V_HIDDEN (optional)
    #         desc - defines if this field is visible
    #         value - 1 if true, 0 if false (default=0)
    #     V_DISABLED (optional)
    #         desc - value of the field
    #         value - 1 if true, 0 if false (default=0)
    #     V_SIZE (optional)
    #         desc - size of input field
    #         value - int (default=30)
    #     V_MAXLENGTH (optional)
    #         desc - max length of value
    #         value - int optional (default=undefined)
    #     V_TOGGLE_ID (optional)
    #         desc - id of field which toggles this field
    #         value - string (default=undefined)
    #     T_LABEL (optional)
    #         desc - label text which descripes the field
    #         value - string (default=undefined)
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    if (!exists $params{V_VALUE}) {
        $params{V_VALUE} = $conf{$params{V_NAME}};
    }
    
    if ($params{V_SIZE} eq "") {
        $params{V_SIZE} = 30;
    }
    
    return get_field_widget("/usr/share/efw-gui/core/widgets/text.pltmpl", \%params);
}

sub get_passwordfield_widget($$) {
    # params (hashref):
    #     V_ID (required)
    #         desc - id of the field, label id=<id>_field
    #         value - string
    #         required
    #     V_NAME (required)
    #         desc - name of the field, used by post
    #         value - string
    #     V_VALUE (required)
    #         desc - value of the field
    #         value - string
    #     V_REQUIRED (optional)
    #         desc - show * if required
    #         value - 1 if true, 0 if false (default=0)
    #     V_HIDDEN (optional)
    #         desc - defines if this field is visible
    #         value - 1 if true, 0 if false (default=0)
    #     V_DISABLED (optional)
    #         desc - value of the field
    #         value - 1 if true, 0 if false (default=0)
    #     V_SIZE (optional)
    #         desc - size of input field
    #         value - int (default=30)
    #     V_MAXLENGTH (optional)
    #         desc - max length of value
    #         value - int optional (default=undefined)
    #     V_TOGGLE_ID (optional)
    #         desc - id of field which toggles this field
    #         value - string (default=undefined)
    #     T_LABEL (optional)
    #         desc - label text which descripes the field
    #         value - string (default=undefined)
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    if (!exists $params{V_VALUE}) {
        $params{V_VALUE} = $conf{$params{V_NAME}};
    }
    
    if ($params{V_SIZE} eq "") {
        $params{V_SIZE} = 30;
    }
    
    return get_field_widget("/usr/share/efw-gui/core/widgets/password.pltmpl", \%params);
}

sub get_textareafield_widget($$) {
    # params (hashref):
    #     V_ID (required)
    #         desc - id of the field, label id=<id>_field
    #         value - string
    #         required
    #     V_NAME (required)
    #         desc - name of the field, used by post
    #         value - string
    #     V_VALUE (required)
    #         desc - value of the field
    #         value - string
    #     V_REQUIRED (optional)
    #         desc - show * if required
    #         value - 1 if true, 0 if false (default=0)
    #     V_HIDDEN (optional)
    #         desc - defines if this field is visible
    #         value - 1 if true, 0 if false (default=0)
    #     V_DISABLED (optional)
    #         desc - value of the field
    #         value - 1 if true, 0 if false (default=0)
    #     V_TOGGLE_ID (optional)
    #         desc - id of field which toggles this field
    #         value - string (default=undefined)
    #     T_LABEL (optional)
    #         desc - label text which descripes the field
    #         value - string (default=undefined)
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    if (!exists $params{V_VALUE}) {
        $params{V_VALUE} = $conf{$params{V_NAME}};
        $params{V_VALUE} =~ s/,/\n/g;
        $params{V_VALUE} =~ s/\|/\n/g;
    }
    
    return get_field_widget("/usr/share/efw-gui/core/widgets/textarea.pltmpl", \%params);
}

sub get_checkboxfield_widget($$) {
    # params (hashref):
    #     V_ID (required)
    #         desc - id of the field, label id=<id>_field
    #         value - string
    #         required
    #     V_NAME (required)
    #         desc - name of the field, used by post
    #         value - string
    #     V_VALUE (required)
    #         desc - value of the field
    #         value - string
    #     V_CHECKED (optional)
    #         desc - status of the checkbox
    #         value - 1 if true, 0 if false (default=0)
    #     V_REQUIRED (optional)
    #         desc - show * if required
    #         value - 1 if true, 0 if false (default=0)
    #     V_HIDDEN (optional)
    #         desc - defines if this field is visible
    #         value - 1 if true, 0 if false (default=0)
    #     V_DISABLED (optional)
    #         desc - value of the field
    #         value - 1 if true, 0 if false (default=0)
    #     V_TOGGLE_ACTION (optional)
    #         desc - defines if field toggles other fields, which used this <V_ID> for <V_TOGGLE_ID>
    #         value - 1 if true, 0 if false (default=0)
    #     V_TOGGLE_ID (optional)
    #         desc - id of field which toggles this field
    #         value - string (default=undefined)
    #     T_LABEL (optional)
    #         desc - label text which descripes the field
    #         value - string (default=undefined)
    #     T_CHECKBOX (required)
    #         desc - label text which descripes the field
    #         value - string
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    if (!exists $params{V_CHECKED}) {
        $params{V_CHECKED} = $conf{$params{V_NAME}} eq "on" ? 1 : 0;    
    }
    
    return get_field_widget("/usr/share/efw-gui/core/widgets/checkbox.pltmpl", \%params);
}

sub get_selectfield_widget($$) {
    # params (hashref):
    #     V_ID (required)
    #         desc - id of the field, label id=<id>_field
    #         value - string
    #         required
    #     V_NAME (required)
    #         desc - name of the field, used by post
    #         value - string
    #     V_OPTIONS (required)
    #         desc - array of the options for the select box
    #         value - array
    #         V_VALUE (required)
    #             desc - value of the option
    #             value - string
    #         V_SELECTED (required)
    #             desc - defines if option is selected
    #             value - string
    #         T_OPTION (optional)
    #             desc - text which describes the option
    #             value - string (default=<V_VALUE> not implemented yet)
    #     V_REQUIRED (optional)
    #         desc - show * if required
    #         value - 1 if true, 0 if false (default=0)
    #     V_HIDDEN (optional)
    #         desc - defines if this field is visible
    #         value - 1 if true, 0 if false (default=0)
    #     V_DISABLED (optional)
    #         desc - value of the field
    #         value - 1 if true, 0 if false (default=0)
    #     V_TOGGLE_ACTION (optional)
    #         desc - defines if field toggles other fields based on the selected option, which use this <V_ID> + the options <V_VALUE> as <V_TOGGLE_ID>
    #         value - 1 if true, 0 if false (default=0)
    #     V_TOGGLE_ID (optional)
    #         desc - id of field which toggles this field
    #         value - string (default=undefined)
    #     T_LABEL (optional)
    #         desc - label text which descripes the field
    #         value - string (default=undefined)
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my $selection_ref = get_field_selection($conf{$params{V_NAME}});
    my %selection = %$selection_ref;
    my $i = 0;
    for $option_ref (@{$params{V_OPTIONS}}) {
        my %option = %$option_ref;
        if (!exists $params{V_OPTIONS}[$i]{V_SELECTED}) {
            $params{V_OPTIONS}[$i]{V_SELECTED} = $selection{$option{V_VALUE}};
        }
        $i += 1;
    }
    return get_field_widget("/usr/share/efw-gui/core/widgets/select.pltmpl", \%params);
}

sub get_multiselectfield_widget($$) {
    # params (hashref):
    #     V_ID (required)
    #         desc - id of the field, label id=<id>_field
    #         value - string
    #         required
    #     V_NAME (required)
    #         desc - name of the field, used by post
    #         value - string
    #     V_OPTIONS (required)
    #         desc - array of the options for the select box
    #         value - array
    #         V_VALUE (required)
    #             desc - value of the option
    #             value - string
    #         V_SELECTED (required)
    #             desc - defines if option is selected
    #             value - string
    #         T_OPTION (optional)
    #             desc - text which describes the option
    #             value - string (default=<V_VALUE> not implemented yet)
    #     V_REQUIRED (optional)
    #         desc - show * if required
    #         value - 1 if true, 0 if false (default=0)
    #     V_HIDDEN (optional)
    #         desc - defines if this field is visible
    #         value - 1 if true, 0 if false (default=0)
    #     V_DISABLED (optional)
    #         desc - value of the field
    #         value - 1 if true, 0 if false (default=0)
    #     V_TOGGLE_ACTION (optional)
    #         desc - defines if field toggles other fields, which used this <V_ID> for <V_TOGGLE_ID>
    #         value - 1 if true, 0 if false (default=0)
    #     V_TOGGLE_ID (optional)
    #         desc - id of field which toggles this field
    #         value - string (default=undefined)
    #     T_LABEL (optional)
    #         desc - label text which descripes the field
    #         value - string (default=undefined)
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;

    my $conf_ref = shift;
    my %conf = %$conf_ref;
    
    my $selection_ref = get_field_selection($conf{$params{V_NAME}});
    my %selection = %$selection_ref;
    my $i = 0;
    for $option_ref (@{$params{V_OPTIONS}}) {
        my %option = %$option_ref;
        if (!exists $params{V_OPTIONS}[$i]{V_SELECTED}) {
            $params{V_OPTIONS}[$i]{V_SELECTED} = $selection{$option{V_VALUE}};
        }
        $i += 1;
    }
    
    return get_field_widget("/usr/share/efw-gui/core/widgets/multiselect.pltmpl", \%params);
}

sub get_buttonfield_widget($) {
    # params (hashref):
    #     V_HIDDEN
    #     V_TOGGLE_ID
    #     V_ID
    #     V_NAME
    #     ONCLICK
    #     T_BUTTON
    #     T_LABEL
    #     T_DESCRIPTiON
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    return get_field_widget("/usr/share/efw-gui/core/widgets/button.pltmpl", \%params);
}

sub get_category_widget($) {
    # params (hashref):
    #     T_TITLE (required)
    #         desc - 
    #         value - 
    #     V_NAME (required)
    #         desc - 
    #         value - 
    #     V_HIDDEN (optional)
    #         desc - defines if this field is visible
    #         value - 1 if true, 0 if false (default=0)
    #     V_SUBCATEGORIES (required)
    #         desc - 
    #         value - 
    #         T_TITLE (required)
    #             desc - 
    #             value - 
    #         V_NAME (required)
    #             desc - 
    #             value - 
    #         V_ALLOWED (optional)
    #             desc - 
    #             value - 
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    return get_field_widget("/usr/share/efw-gui/core/widgets/category.pltmpl", \%params);
}

###############################
# MENU TEMPLATES ##############
###############################

sub get_subsection_widget($) {
    my $params_ref = shift;
    my %params = %$params_ref;
    
    return get_field_widget("/usr/share/efw-gui/core/widgets/subsection.pltmpl", \%params);
}

###############################
# GUI ELEMENTS TEMPLATES ######
###############################

sub get_save_widget($) {
    # params (hashref):
    #     T_SAVE_BUTTON (optional)
    #         desc - text of the savebutton
    #         value - string (default=Save)
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    if ($params{T_SAVE_BUTTON} eq "") {
        $params{T_SAVE_BUTTON} = _("Save");
    }
    $params{T_REQUIRED_HINT} = _("This Field is required.");
    
    return get_widget("/usr/share/efw-gui/core/widgets/save.pltmpl", \%params);
}

sub get_saveform_widget($) {
    # params (hashref):
    #     P_SCRIPT_NAME (optional)
    #         desc - name of cgi which is executed
    #         value - string (default=$ENV{'SCRIPT_NAME'})
    #     H_FORM_CONTAINER (required)
    #         desc - html which contains the formfields
    #         value - html code
    #     T_SAVE_BUTTON (optional)
    #         desc - text of the savebutton
    #         value - string (default=Save)
    #      V_NOBUTTON (optional)
    #         desc - do not show avebutton
    #         value - 1 if true, 0 if false (default=0)
    # returns:
    #     rendered html code
        
    my $params_ref = shift;
    my %params = %$params_ref;
    
    # my %textparams = (
    #     V_HIDDEN => 1,
    #     V_NAME => "ACTION",
    #     V_VALUE => "save",
    # );    
    
    if ($params{V_NOBUTTON} ne 1) {
        $params{H_FORM_CONTAINER} .= get_save_widget(\%params);
    }
    return get_widget("/usr/share/efw-gui/core/widgets/saveform.pltmpl", \%params); 
}

sub get_form_widget($) {
    # params (hashref):
    #     V_FIELDS (required)
    #         desc - value of the field
    #         value - array
    #         V_HIDDEN (optional)
    #             desc - defines if this field is visible (only needed if a field needs to be toggled by 2 diffrent toggle_ids)
    #             value - 1 if true, 0 if false (default=0)
    #         V_TOGGLE_ID (optional)
    #             desc - id of field which toggles this field (only needed if a field needs to be toggled by 2 diffrent toggle_ids)
    #             value - string (default=undefined)
    #         H_FIELD (required)
    #             desc - html code of the field
    #             value - valid html
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    return get_widget("/usr/share/efw-gui/core/widgets/form.pltmpl", \%params);
}

sub get_editorbox_widget($) {
    # params (hashref):
    #
    #     P_SCRIPT_NAME (optional)
    #         desc - name of cgi which is executed
    #         value - string (default=$ENV{'SCRIPT_NAME'})
    #     
    #     H_CONTAINER
    #     T_ADDRULE
    #     T_TITLE
    #     T_SAVE
    #     T_CANCEL
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    if (!exists $params{P_SCRIPT_NAME}) {
        $params{P_SCRIPT_NAME} = $ENV{SCRIPT_NAME};
    }
    if (!exists $params{T_ADDRULE}) {
        $params{T_ADDRULE} = _("Create a rule");
    }
    if (!exists $params{T_TITLE}) {
        $params{T_TITLE} = _("Rule editor");
    }
    if (!exists $params{T_SAVE}) {
        $params{T_SAVE} = _("Create rule");
    }
    if (!exists $params{T_CANCEL}) {
        $params{T_CANCEL} = _("Cancel");
    }
    return get_widget("/usr/share/efw-gui/core/widgets/editorbox.pltmpl", \%params);
}

sub get_switch_widget($) {
    # example param hash (all keys are needed!!!!):
    # 
    # my %params = (
    #     P_SCRIPT_NAME => $ENV{'SCRIPT_NAME'}, # empty string is $ENV{'SCRIPT_NAME}
    #     
    #     V_SERVICE_VALIDATION => "", # needs to be the name of the validation js function (empty string => null)
    #     
    #     V_SERVICE_NOTIFICATION_NAME => "smtp", # empty string deactivates the ajax notification (can also be a list of names: snort, snort-rules)
    #     
    #     V_SERVICE_ON => 1, # required # 1 or 0 (empty == 0)
    #     V_SERVICE_AJAXIAN_SAVE => 0, # 1 or 0 (empty == 0)
    #     V_SERVICE_PARTIAL_RELOAD => 0, # 1 or 0 (empty == 0)
    #     
    #     H_OPTIONS_CONTAINER => $template,
    #     
    #     T_SERVICE_TITLE => _('Enable SMTP Proxy'),
    #     T_SERVICE_STARTING => _("The SMTP Proxy is being enabled. Please hold..."),
    #     T_SERVICE_SHUTDOWN => _("The SMTP Proxy is being disabled. Please hold..."),
    #     T_SERVICE_RESTARTING => _("Settings are saved and the SMTP Proxy is being restarted. Please hold..."),
    #     T_SERVICE_DESCRIPTION => _("Use the switch above to set the status of the SMTP Proxy. Click on the save button below to make the changes active."),
    #     T_SAVE_BUTTON => _("Save and restart") # empty string is _("Save")
    # );
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    if ($params{P_SCRIPT_NAME} eq "") {
        $params{P_SCRIPT_NAME} = $ENV{SCRIPT_NAME};
    }
    if ($params{V_SERVICE_VALIDATION} eq "") {
        $params{V_SERVICE_VALIDATION} = "null";
    }
    if ($params{V_SERVICE_ON} eq "on" or $params{V_SERVICE_ON} eq 1) {
        $params{V_SERVICE_ON} = 1;
        $params{V_SERVICE_STATUS} = "on";
    }
    else {
        $params{V_SERVICE_ON} = 0;
        $params{V_SERVICE_STATUS} = "off";
    }
    if ($params{V_SERVICE_AJAXIAN_SAVE} eq "") {
        $params{V_SERVICE_AJAXIAN_SAVE} = 0;
    }    
    if ($params{V_SERVICE_PARTIAL_RELOAD} eq "") {
        $params{V_SERVICE_PARTIAL_RELOAD} = 0;
    }
    $params{V_NOBUTTON} = 1;
    
    $params{H_OPTIONS_CONTAINER} .= get_save_widget(\%params);;
    
    $params{H_FORM_CONTAINER} = get_widget("/usr/share/efw-gui/core/widgets/switch.pltmpl", \%params);
    
    return get_saveform_widget(\%params);
}

sub get_accordion_widget($) {
    # params (hashref):
    #     V_ACCORDION (required)
    #         desc - 
    #         value - 
    #         T_TITLE (required)
    #             desc - 
    #             value - 
    #         T_DESCRIPTION (required)
    #             desc - 
    #             value -
    #         T_SAVE_BUTTON (optional)
    #             desc - 
    #             value -
    #         H_CONTAINER (required)
    #             desc - 
    #             value - 
    #         V_HIDDEN (optional)
    #             desc - 
    #             value - 
    #         V_NOTVISIBLE (optional)
    #             desc - defines if this accordion is not visible
    #             value - 1 if true, 0 if false (default=1)
    #         T_STARTONLY (optional)
    #             desc - for backwards compatability to use instead of openbox
    #             value - 
    #         T_ENDONLY (optional)
    #             desc - for backwards compatability to use instead of openbox
    #             value - 
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    return get_widget("/usr/share/efw-gui/core/widgets/accordion.pltmpl", \%params);
}

sub get_listtable_widget($) {
    # params (hashref):
    #     V_HEADINGS
    #         HREF
    #         HEADING
    #     V_ACTIONS
    #         EDIT_ACTION
    #         REMOVE_ACTION
    #         UP_ACTION
    #         DOWN_ACTION
    #         ON_ACTION
    #         OFF_ACTION
    #     V_ROWS
    #         STYLE
    #         V_COLS
    #             V_CELL_CONTENT
    #         
    # returns:
    #     rendered html code
    
    my $params_ref = shift;
    my %params = %$params_ref;
    
    return get_widget("/usr/share/efw-gui/core/widgets/listtable.pltmpl", \%params);
}

###############################
# CUSTOM     TEMPLATES ########
###############################

sub get_zonestatus_widget() {
    my $description = shift;
    my $params_ref = shift;
    my $options_ref = shift;
    my $red = shift;
    my $red_options_ref = shift;
    
    my %params = %$params_ref;
    my @options = @$options_ref;
    my %selected = %$selected_ref;
    my @red_options = @$red_options_ref;
    
    my $description = shift;
    my $prefix = shift;
    if ($description eq "") {
        $description = _("Unfold to define the service status per zone.");
    }
    
    if (scalar(@options) eq 0) {
        push(@options, {V_NAME => "enabled", T_DESCRIPTION => _("active")});
        push(@options, {V_NAME => "transparent", T_DESCRIPTION => _("transparent mode")});
        push(@options, {V_NAME => "disabled", T_DESCRIPTION => _("inactive")});
    }
    
    if (scalar(@red_options) eq 0) {
        push(@red_options, {V_NAME => "enabled", T_DESCRIPTION => _("active")});
        push(@red_options, {V_NAME => "disabled", T_DESCRIPTION => _("inactive")});
    }
    
    my $valid_zones_ref = validzones();
    my @valid_zones = @$valid_zones_ref;
    
    my @zones = ();
    
    foreach $zone (@valid_zones) {
        if ($red ne 1 && uc($zone) eq "RED") {
            next;
        }
        my @zoneoptions = ();
        my @tmp = @options;
        if (uc($zone) eq "RED") {
            @tmp = @red_options;
        }
        
        foreach $option_ref (@tmp) {
            my %option = %$option_ref;
            
            if ($params{$prefix . uc($zone)."_ENABLED"} eq $option{V_NAME}) {
                $option{V_SELECTED} = 1;
            }
            else {
                $option{V_SELECTED} = 0;
            }
            push(@zoneoptions, \%option);
        }
        
        push(@zones, {V_NAME => $prefix . uc ($zone),
                        T_DESCRIPTION => _(uc ($zone)),
                        V_COLOR => lc ($zone),
                        V_OPTIONS => \@zoneoptions});
    }
    
    my %params = (
        V_ZONES => \@zones,
        T_ZONE_NOT_AVAILABLE => _("remote configuration")
    );
    
    return get_widget("/usr/share/efw-gui/core/widgets/zonestatus.pltmpl", \%params),
}

1; #needed because of require
