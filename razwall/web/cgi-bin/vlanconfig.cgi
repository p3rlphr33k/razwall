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
#

 
require 'header.pl';
require 'ethconfig.pl';

my $reload_from_wizard = '/usr/local/bin/restart_from_wizard';
my $ethernet_dir = '/var/efw/ethernet/';
my $needreload = "${swroot}/outgoing/vlanneedreload";

my (%par, %netsettings);

my $selectdevices, $selectdeviceshash = ();

my $reload = 0;

sub show_vlans() {
    &openbox('100%', 'left', _('Current configured VLANs'));

    show_add();

printf <<END
<table class="ruleslist" width='100%' cellpadding="0" cellspacing="0">
  <tr>
    <td width='10%' class='boldbase'>%s</td>
    <td width='15%' class='boldbase'>%s</td>
    <td width='60%' class='boldbase'>%s</td>
    <td width='10%' class='boldbase'>%s</td>
    <td width='5%' class='boldbase'>%s</td>
  </tr>
END
,
_('Device'),
_('VLAN ID'),
_('on Interface'),
_('Zone'),
_('Actions');

    my $i = 0;
    my ($vlans) = list_devices_description(-2, -1, 1);
    foreach my $data (@$vlans) {
	my $iface = $data->{'device'};
	my $description = $data->{'parent'}->{'label'};
	my $shortdesc = $data->{'parent'}->{'shortlabel'};
	my $zone = $data->{'zone'};
	my $vid = $data->{'vid'};
	my $physdev = $data->{'physdev'};
	my $zonecolor = $zonecolors{$zone};
	my $bgcolor = setbgcolor(0, 0, $i);

	printf <<END
<tr class="$bgcolor">
  <td>$iface</td>
  <td>$vid</td>
  <td>$shortdesc <a href="javascript:void(0);" onmouseover="return overlib('$description', STICKY, MOUSEOFF);" onmouseout="return nd();">?</a></td>
  <td><font color="$zonecolor">$zone</font></td>
  <td class="actions">
    <form enctype='multipart/form-data' method="post" action="$ENV{'SCRIPT_NAME'}" onSubmit="return confirm('%s');">
      <input type='hidden' name='ACTION' value='remove' />
      <input class='imagebutton' type='image' name='remove' src='/images/delete.png' alt="%s" title="%s" style="%s" />
      <input type='hidden' name='DEVICE' value='$physdev' />
      <input type='hidden' name='VID' value='$vid' />
      <input type='hidden' name='ZONE' value='$zone' />
    </form>
  </td>
</tr>
END
, _('Do you really want to remove VLAN %s?', $vid)
, _('Remove'),
_('Remove'),
($zone eq 'RED') ? "display: none" : ""
;
	$i++;
    }
printf <<END
    </table>
END
;
    &closebox();
}

sub show_add() {
    openeditorbox(_('Add new VLAN'), _('Add new VLAN'), "", "createvlan");
    #&openbox('100%', 'left', _('Add new VLAN'));

    printf <<END
<input type='hidden' name='ACTION' value='add' />
<table>
  <tr>
    <td>%s *</td>
    <td colspan="5">
      <select name="DEVICE">
END
, _('Interface')
;

    foreach my $devicedata (@$selectdevices) {
	my $device = $devicedata->{'device'};
        print "<option value='$device'>".$devicedata->{'shortlabel'}."</option>";
    }

printf <<END
      </select>
    </td>
  </tr>

  <tr>
    <td>%s *</td>
    <td>
      <input type="text" name="VID" MAXLENGTH="6" />
    </td>
    <td>%s *</td>
    <td>
      <select name="ZONE">
        <option value='NONE'>%s</option>
END
, _('VLAN ID')
, _('Zone')
, _('NONE')
;

    my $allzones = validzones();
    foreach my $zone (sort @$allzones) {
	next if ($zone eq 'RED');
        print "<option value='$zone'>". $strings_zone{$zone} ."</option>";
    }

printf <<END
      </select>
    </td>
  </tr>
</table>
END
;

closeeditorbox(_("Add VLAN"), _("Cancel"), "vlanbutton", "createvlan");

# printf <<END
# <form enctype='multipart/form-data' method="post" action="$ENV{'SCRIPT_NAME'}">
#     <input type='hidden' name='ACTION' value='apply' />
#     <input class='submitbutton' type="submit" name="apply" value="%s">
# </form>
# 
# END
# ,
# _('Save'),
# _('Apply configuration')
# ;
    #&closebox();
    
}

sub write_vlanconfig($) {
    my $iface = shift;
    open(F, ">${ethernet_dir}/vlan_${iface}") or return (0, _('Could not write VLAN configuration'));

    my $conf = $selectdeviceshash->{$iface}->{'vlans'};
    foreach my $vdevice (keys %$conf) {
	print F $conf->{$vdevice}->{'vid'} ."\n"
    }
    close(F);
}

sub do_add($$$) {
    my $iface = shift;
    my $vid = shift;
    my $zone = shift;
    my $vdevice = "$iface.$vid";
    my $data = $selectdeviceshash->{$iface};

    if (! $data) {
	return (0, _('Interface %s does not exist', $iface));
    }
    if (($vid !~ /^\d+$/) || ($vid <= 0) || ($vid >= 4095)) {
	return (0, _('Invalid VLAN ID. Must be greater than 0 and smaller than 4095'));
    }
    if ($data->{'vlans'}->{$vdevice}) {
	return (0, _('VLAN %s does already exist on device "%s"', $vid, $iface));
    }

    # check whether the physical interface of the vlan is
    #      already part of a bridge and bail if it is.
    #
    # This check is necessary because:
    # A physdev (eth) which has vlans (eth0.90, eth0.91) can't become part
    # of a bridge (br0). As soon as eth0 would be added to br0, the vlan
    # devices eth0.90, eth0.91 would stop working.
    # It's only possible to add the vlan devices to bridges, not the physdev
    # device. It is possible to use the physdev device as long as it will not
    # be joined to a bridge.
    #
    my $ifdata = $selectdeviceshash->{$iface};
    my $physdevzone = $ifdata->{'zone'};
    if (($physdevzone ne '') && ($physdevzone ne $zone)) {
	my $langzone = $strings_zone{$physdevzone};
	return (0, _('Physical interface "%s" on port %s is already assigned to the %s zone! Remove the interface from that zone, before a VLAN can be assigned to this interface.', $iface, $ifdata->{'port'}, $langzone));
    }
    my $item = create_vlan_data($vid, $iface);
    $ifdata->{'vlans'}->{$item->{'device'}} = $item;
    write_vlanconfig($iface);
    if ($zone ne 'NONE') {
	    joinbridge($ethsettings{$zone.'_DEV'}, $item->{'device'});
    }
    if ($physdevzone ne '') {
	    removefrombridge($ethsettings{$zone.'_DEV'}, $iface);
    }
    load_ethconfig(1);
    return 1;
}

sub do_remove($$$) {
    my $iface = shift;
    my $vid = shift;
    my $zone = shift;
    my $vdevice = "$iface.$vid";
    my $data = $selectdeviceshash->{$iface};
    if (! $data) {
	    return (0, _('Interface %s does not exist', $iface));
    }
    if (! $data->{'vlans'}->{$vdevice}) {
	    return (0, _('VLAN does not exist on device %s', $iface));
    }
    delete($data->{'vlans'}->{$vdevice});
    write_vlanconfig($iface);
    removefrombridge($ethsettings{$zone.'_DEV'}, $vdevice);
    load_ethconfig(1);
    return 1;
}

sub do_apply() {
    $notemessage = _("VLAN configuration applied successfully");
    system("jobcontrol call network.restart_vlans &>/dev/null");
    system("rm $needreload");
    return 0;
    
}

sub do_action($) {
    my $par = shift;
    if ($par->{'ACTION'} eq 'apply') {
        return do_apply();
    }
    elsif ($par->{'ACTION'} eq 'add') {
        return do_add($par->{'DEVICE'}, $par->{'VID'}, $par->{'ZONE'});
    }
    elsif ($par->{'ACTION'} eq 'remove') {
        return do_remove($par->{'DEVICE'}, $par->{'VID'}, $par->{'ZONE'});
    }
    else {
        # go crying and sitting in a corner.
        return 0;
    }
}


&getcgihash(\%par);
&showhttpheaders();
($selectdevices, $selectdeviceshash) = list_devices_description(2, -1, 1);

&openpage(_('VLAN configuration'), 1, '');

my ($reload, $errormessage) = do_action(\%par);
&openbigbox($errormessage, $warnmessage, $notemessage);

if ($reload) {
    system("touch $needreload");
}

if (-e $needreload) {
    applybox(_("VLAN configuration has been changed and need to be applied in order to make the changes active."));
}

show_vlans();

&closebigbox();

&closepage();
