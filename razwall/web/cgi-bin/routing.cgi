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

require 'routing.pl';

my $l2tp = 0;
eval {
    require l2tplib;
    $l2tp = 1;
};

my $ENABLED_PNG = '/images/on.png';
my $DISABLED_PNG = '/images/off.png';
my $EDIT_PNG = '/images/edit.png';
my $DELETE_PNG = '/images/delete.png';
my $OPTIONAL_PNG = '/images/blob.png';

my (%par,%checked,%selected);
my $errormessage = '';

sub display_rules($$) {
    my $is_editing = shift;
    my $line = shift;

    printf <<END
    
    <table class="ruleslist" cellpadding="0" cellspacing="0" width='100%'>
        <tr>    
            <td class="boldbase" style="width: 120px;">%s</td>
            <td class="boldbase" style="width: 120px;">%s</td>
            <td class="boldbase" style="width: 150px;">%s</td>
            <td class="boldbase">%s</td>
            <td class="boldbase" style="width: 60px;">%s</td>
        <tr>
END
    ,
    _('Source Network'),
    _('Destination Network'),
    _('Via Gateway'),
    _('Remark'),
    _('Actions')
    ;

    my @lines = read_config_file();
    my $i = -1;
    foreach my $thisline (@lines) {
    chomp($thisline);
    my %splitted = config_line($thisline);

    if (! $splitted{'valid'}) {
        next;
    }
    
    $i++;
    
    if ($splitted{'protocol'} ne "") {
        next;
    }

    my $source = value_or_nbsp($splitted{'source'});
    my $destination = value_or_nbsp($splitted{'destination'});
    if (! validipormask($destination) and ! validipormask($source)) {
        next;
    }

    my $gw = $splitted{'gw'};
    if ($gw =~ /^UPLINK:(.*)$/) {
        my $uplink = $1;
        chomp($uplink);
        my %uplinkinfo = get_uplink_info($uplink);
        $gw = "<font color='". $zonecolors{'WAN'} ."'>".$uplinkinfo{'NAME'}."</font>";
    }
    if ($gw =~ /^OPENVPNUSER:(.*)$/) {
        my $openvpnuser = $1;
        chomp($openvpnuser);
        $gw = "<font color='". $colourvpn ."'>"._("%s (OpenVPN user)", $openvpnuser)."</font>";
    }
    if ($gw =~ /^L2TPIP:(.*)$/) {
        my $user = $1;
        chomp($user);
        $gw = "<font color='". $colourvpn ."'>"._("%s (L2TP user)", $user)."</font>";
    }
    $gw = value_or_nbsp($gw);
    my $remark = value_or_nbsp($splitted{'remark'});
    my $tos = value_or_nbsp($splitted{'tos'});

    my $enabled_gif = $DISABLED_PNG;
    my $enabled_alt = _('Disabled (click to enable)');
    my $enabled_action = 'enable';
    if ($splitted{'enabled'} eq 'on') {
        $enabled_gif = $ENABLED_PNG;
        $enabled_alt = _('Enabled (click to disable)');
        $enabled_action = 'disable';
    }

    my $bgcolor = setbgcolor($is_editing, $line, $i);

        printf <<EOF
    <tr class="$bgcolor">
        <td>$source</td>
        <td>$destination</td>
        <td>$gw</td>
        <td>$remark</td>
        <td class="actions">
            <form method="post" ACTION="$ENV{'SCRIPT_NAME'}" class="inline">
                <input class='imagebutton' type='image' name="submit" SRC="$enabled_gif" ALT="$enabled_alt" />
                <input type="hidden" name="ACTION" value="$enabled_action">
                <input type="hidden" name="line" value="$i">
            </form>
            <form method="post" ACTION="$ENV{'SCRIPT_NAME'}" class="inline">
                <input class='imagebutton' type='image' name="submit" SRC="$EDIT_PNG" ALT="%s" />
                <input type="hidden" name="ACTION" value="edit">
                <input type="hidden" name="line" value="$i">
            </form>
            <form method="post" ACTION="$ENV{'SCRIPT_NAME'}" class="inline">
                <input class='imagebutton' type='image' name="submit" SRC="$DELETE_PNG" ALT="%s" />
                <input type="hidden" name="ACTION" value="delete">
                <input type="hidden" name="line" value="$i">
            </form>
        </td>
    </tr>
EOF
,
_('Edit'),
_('Delete');
    }


    printf <<EOF
</table>

<table class="list-legend" cellpadding="0" cellspacing="0">
  <tr>
    <td class="boldbase">
      <B>%s:</B>
    </td>
    <td>&nbsp;<IMG SRC="$ENABLED_PNG" ALT="%s" /></td>
    <td class="base">%s</td>
    <td>&nbsp;&nbsp;<IMG SRC='$DISABLED_PNG' ALT="%s" /></td>
    <td class="base">%s</td>
    <td>&nbsp;&nbsp;<IMG SRC="$EDIT_PNG" alt="%s" /></td>
    <td class="base">%s</td>
    <td>&nbsp;&nbsp;<IMG SRC="$DELETE_PNG" ALT="%s" /></td>
    <td class="base">%s</td>
  </tr>
</table>
EOF
,
_('Legend'),
_('Enabled (click to disable)'),
_('Enabled (click to disable)'),
_('Disabled (click to enable)'),
_('Disabled (click to enable)'),
_('Edit'),
_('Edit'),
_('Remove'),
_('Remove')
;

    &closebox();
    
}

sub get_openvpn_lease() {
    my @users = sort split(/\n/, `$openvpn_passwd list`);
    return \@users;
}

sub display_add($$) {
    my $is_editing = shift;
    my $line = shift;
    my %config;
    my %checked;

    if (($is_editing) && ($par{'sure'} ne 'y')) {
        %config = config_line(read_config_line($line));
    }
    else {
        %config = %par;
    }
    
    my $enabled = $config{'enabled'};
    my $source = $config{'source'};
    my $destination = $config{'destination'};
    my $gateway = $config{'gw'};
    my $remark = $config{'remark'};
    my $tos = $config{'tos'};

    my $via_type = 'gw';
    my %selected;
    if ($gateway =~ /^UPLINK:/) {
        $via_type = 'uplink';
    }
    if ($gateway =~ /^OPENVPNUSER:/) {
        $via_type = 'openvpn';
    }
    if ($gateway =~ /^L2TPIP:/) {
        $via_type = 'l2tp';
    }

    $selected{'uplink'}{$gateway} = 'selected';
    $selected{'openvpn'}{$gateway} = 'selected';
    $selected{'gw_l2tp'}{$gateway} = 'selected';
    $selected{'via_type'}{$via_type} = 'selected';

    my $action = 'add';
    my $sure = '';
    my $title = _('Add routing entry');
    if ($is_editing) {
        $action = 'edit';
        $sure = '<input type="hidden" name="sure" value="y">';
        $title = _('Edit routing entry');
    }
    else {
        $enabled = 'on';
    }

    $checked{'ENABLED'}{$enabled} = 'checked';

    my %foil = ();
    $foil{'value'}{'via_gw'} = 'none';
    $foil{'value'}{'via_uplink'} = 'none';
    $foil{'value'}{'via_openvpn'} = 'none';
    $foil{'value'}{'via_l2tp'} = 'none';
    $foil{'value'}{"via_$via_type"} = 'block';

    $buttontext = $par{'ACTION'} eq 'edit' || $par{'KEY1'} ne '' ? _("Update Route") : _("Add Route");

    if($par{'ACTION'} eq 'edit' || $errormessage ne '') {
        $show = "showeditor";
    }

    my $openvpn_ref = get_openvpn_lease();
    my @openvpnusers = @$openvpn_ref;

    my $l2tp_ref = ();
    if ($l2tp) {
       $l2tp_ref = get_l2tp_users();
    }
    my @l2tpusers = @$l2tp_ref;

    &openeditorbox(_('Add a new route'), $title, $show, "createrule", @errormessages);

    printf <<EOF
<table width="100%">
  <tr>
    <td width="30%">
      <strong>%s</strong>
    </td>
    <td width="70%">&nbsp;</td>
  </tr>
  <tr>
    <td>%s</td>
    <td>
      <input type="text" name="source" value="$source" />
    </td>
  </tr>
  <tr>
    <td>%s</td>
    <td>
      <input type="text" name="destination" value="$destination" />
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td colspan="2" class="border-top">
      <strong>%s *</strong>
    </td>
  </tr>

  <tr>
    <td>
      <select name="via_type" onchange="toggleTypes('via');" onkeyup="toggleTypes('via');">
        <option value="gw" $selected{'via_type'}{'gw'}>%s</option>
        <option value="uplink" $selected{'via_type'}{'uplink'}>%s</option>
        <option value="openvpn" $selected{'via_type'}{'openvpn'}>%s</option>
EOF
, _('Selector')
, _('Source Network')
, _('Destination Network')
, _('Route Via')
, _('Static Gateway')
, _('Uplink')
, _('OpenVPN User')
;

    if ($l2tp) {
	printf <<EOF
        <option value="l2tp" $selected{'via_type'}{'l2tp'}>%s</option>
EOF
, _('L2TP User')
;
    }

    printf <<EOF
      </select>
    </td>
    <td>
      <div ID='via_gw_v' style='display:$foil{'value'}{'via_gw'}'>
        <input type="text" name="gw" value="$gateway" />
      </div>
      <div ID='via_uplink_v' style='display:$foil{'value'}{'via_uplink'}'>
        <select name="uplink" style="width: 139px;">
EOF
;

    foreach my $name (@{get_uplinks()}) {
        my $key = "UPLINK:$name";
        my %uplinkinfo = get_uplink_info($name);
        printf <<EOF 
                  <option value='$key' $selected{'uplink'}{$key}>$uplinkinfo{'NAME'}</option>
EOF
;
    }

    printf <<EOF
        </select>
      </div>
      <div ID='via_openvpn_v' style='display:$foil{'value'}{'via_openvpn'}'>
        <select name="openvpn">
EOF
;

    foreach my $item (@openvpnusers) {
        printf <<EOF
          <option value="OPENVPNUSER:$item" $selected{'openvpn'}{"OPENVPNUSER:$item"}>$item</option>
EOF
    ;
    }

    printf <<EOF
        </select>
      </div>
EOF
;

    if ($l2tp) {
        printf <<EOF
      <div ID='via_l2tp_v' style='display:$foil{'value'}{'via_l2tp'}'>
          <select name="gw_l2tp">
EOF
;
        foreach my $item (@l2tpusers) {
            printf <<EOF
              <option value="L2TPIP:$item" $selected{'via_l2tp'}{"L2TPIP:$item"}>$item</option>
EOF
;
        }

        printf <<EOF
          </select>
      </div>
EOF
;
    }

    printf <<EOF
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td colspan="2" class="border-top">
      <span id='via_gw_t'>&nbsp;</span>
      <span id='via_uplink_t'>&nbsp;</span>
      <span id='via_openvpn_t'>&nbsp;</span>
EOF
;

    if ($l2tp) {
	printf <<EOF
      <span id='via_l2tp_t'>&nbsp;</span>
EOF
;
    }

    printf <<EOF
    </td>
  </tr>

  <tr>
    <td>%s</td>
    <td>
      <input type="checkbox" name="enabled" value="on" $checked{'ENABLED'}{'on'}/>
    </td>
  </tr>

  <tr>
    <td>%s</td>
    <td colspan="2">
      <input type="text" name="remark" value="$config{'remark'}" size="55" maxlength="50" />
    </td>
  </tr>

  <tr>
    <td>&nbsp;</td>
    <td class="base">
      <font class="base"></font>
    </td>
  </tr>
</table>
<input type="hidden" name="ACTION" value="$action">
<input type="hidden" name="line" value="$line">
<input type="hidden" name="sure" value="y">
EOF
, _('Enabled')
, _('Remark')
;

&closeeditorbox($buttontext, _("Cancel"), "routebutton", "createrule", $ENV{'SCRIPT_NAME'});

}

sub reset_values() {
    %par = ();
}

sub save() {
    my $action = $par{'ACTION'};
    my $sure = $par{'sure'};
    if ($action eq 'apply') {
        system($setrouting);
        system($setpolicyrouting);
        system("rm -f $needreload");

        $notemessage = _("Routing rules applied successfully");
        return;
    }
    if ($action eq 'delete') {
        delete_line($par{'line'});
        reset_values();
        return;
    }

    if ($action eq 'enable') {
        if (toggle_enable($par{'line'}, 1)) {
            reset_values();
            return;
        }
    }
    if ($action eq 'disable') {
        if (toggle_enable($par{'line'}, 0)) {
            reset_values();
            return;
        }
    }

 
        # ELSE
    if (($action eq 'add') ||
        (($action eq 'edit')&&($sure eq 'y'))) {
        my $via = '';
        if ($par{'via_type'} eq 'gw') {
            $via = $par{'gw'};
        }
        if ($par{'via_type'} eq 'uplink') {
            $via = $par{'uplink'};
        }
        if ($par{'via_type'} eq 'openvpn') {
            $via = $par{'openvpn'};
        }
        if ($par{'via_type'} eq 'l2tp') {
            $via = $par{'gw_l2tp'};
        }

        if(! ($par{'source'} or $par{'destination'})) {
            $errormessage = _('At least one source or destination network required!');
            return;
        }

        my $enabled = $par{'enabled'};
        if (save_line($par{'line'},
                  $enabled,
                  $par{'source'},
                  $par{'destination'},
                  $via,
                  $par{'remark'},
                  $par{'tos'})) {

            reset_values();
        }
    }
}

&getcgihash(\%par);

&showhttpheaders();
my $extraheader = '<script language="JavaScript" src="/include/firewall_type.js"></script>';
&openpage(_('Routing'), 1, $extraheader);

save();
if ($reload) {
    system("touch $needreload");
}

&openbigbox($errormessage, $warnmessage, $notemessage);

if (-e $needreload) {
    applybox(_("Routing rules have been changed and need to be applied in order to make the changes active"));
}

&openbox('100%', 'left', _('Current routing entries'));
display_add(($par{'ACTION'} eq 'edit'), $par{'line'});
display_rules(($par{'ACTION'} eq 'edit'), $par{'line'});
&closebox();

&closebigbox();
&closepage();
