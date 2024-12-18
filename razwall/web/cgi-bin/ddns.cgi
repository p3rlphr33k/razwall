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

require 'header.pl';
require 'razinc.pl';

my @errormessages = ();
my (%cgiparams,%selected,%checked);
my $filename = "${swroot}/ddns/config";
my $DYNACCESS_BIN = "/usr/local/bin/dynaccessposter";

&showhttpheaders();

$cgiparams{'ENABLED'} = 'off';
$cgiparams{'PROXY'} = 'off';
$cgiparams{'WILDCARDS'} = 'off';
&getcgihash(\%cgiparams);

if (!(-e $filename)) {
    open(FILEHANDLE, ">$filename") || die('Cannot create config file.');
    close(FILEHANDLE);
}

my @service = ();
open(FILE, "$filename") or die 'Unable to open config file.';
my @current = <FILE>;
close(FILE);

if ($cgiparams{'ACTION'} eq 'add')
{
    toggle_file("${swroot}/ddns/behindnat","$cgiparams{'BEHINDNAT'}");
    unless ($cgiparams{'SERVICE'} =~ /^(dhs\.org|DynAccess|dyndns\.org|dyndns-custom|dyndns-static|dyns\.cx|easydns\.com|freedns-afraid\.org|no-ip\.com|nsupdate|ovh\.com|regfish\.com|selfhost\.de|tzo\.com|zoneedit\.com)$/) {
        push(@errormessages, _('Invalid input'));
    }
    unless ($cgiparams{'LOGIN'} ne '') {
        push(@errormessages, _('Username not set.'));
    }
    # for free-dns.afraid.org, only 'connect string' is mandatory
    if ($cgiparams{'SERVICE'} ne 'freedns-afraid.org') {
      unless ($cgiparams{'SERVICE'} eq 'regfish.com' || $cgiparams{'PASSWORD'} ne '') {
          push(@errormessages, _('Password not set.'));
      }
      # Permit an empty HOSTNAME for the nsupdate, regfish, dyndns, ovh, zoneedit
      unless ($cgiparams{'SERVICE'} eq 'zoneedit.com' || $cgiparams{'SERVICE'} eq 'nsupdate' || $cgiparams{'SERVICE'} eq 'dyndns-custom'|| $cgiparams{'SERVICE'} eq 'regfish.com' || $cgiparams{'SERVICE'} eq 'ovh.com' || $cgiparams{'HOSTNAME'} ne '') {
          push(@errormessages, _('Hostname not set.'));
      }
      unless ($cgiparams{'HOSTNAME'} eq '' || $cgiparams{'HOSTNAME'} =~ /^[a-zA-Z_0-9-]+$/) {
          push(@errormessages, _('Invalid hostname.'));
      }
      if ($cgiparams{'DOMAIN'} eq '') {
          push(@errormessages, _('Domain not set.'));
      }
      else {
          unless ($cgiparams{'DOMAIN'} =~ /^[a-zA-Z_0-9.-]+$/ || $cgiparams{'DOMAIN'} =~ /[.]/) {
              push(@errormessages, _('Invalid domain name.'));
          }
      }
    }
    my $id = 0;
    foreach my $line (@current)
    {
        $id++;
        my @temp = split(/\,/,$line);
        if($cgiparams{'HOSTNAME'} eq $temp[1] &&
           $cgiparams{'DOMAIN'} eq $temp[2] &&
           $cgiparams{'EDITING'} ne $id)
        {
             push(@errormessages, _('Hostname and domain already in use.'));
        }
    }
    if (scalar(@errormessages) eq 0)
    {
        if ($cgiparams{'EDITING'} eq 'no')
        {
            open(FILE,">>$filename") or die 'Unable to open config file.';
            flock FILE, 2;
            print FILE "$cgiparams{'SERVICE'},$cgiparams{'HOSTNAME'},$cgiparams{'DOMAIN'},$cgiparams{'PROXY'},$cgiparams{'WILDCARDS'},$cgiparams{'LOGIN'},$cgiparams{'PASSWORD'},$cgiparams{'ENABLED'}\n";
            &log(_('Dynamic DNS hostname added'));
        } else {
            open(FILE,">$filename") or die 'Unable to open config file.';
            flock FILE, 2;
            my $id = 0;
            foreach my $line (@current)
            {
                $id++;
                chomp($line);
                my @temp = split(/\,/,$line);
                if ($cgiparams{'EDITING'} eq $id) {
                    print FILE "$cgiparams{'SERVICE'},$cgiparams{'HOSTNAME'},$cgiparams{'DOMAIN'},$cgiparams{'PROXY'},$cgiparams{'WILDCARDS'},$cgiparams{'LOGIN'},$cgiparams{'PASSWORD'},$cgiparams{'ENABLED'}\n";
                } else {
                    print FILE "$line\n";
                }
            }
        }
        close(FILE);
        undef %cgiparams;
    }
    
    system('/usr/bin/sudo /usr/local/bin/setddns.pl -f 2&>/dev/null');
}

if ($cgiparams{'ACTION'} eq 'edit' )
{
    my $id = 0;
    foreach my $line (@current)
    {
        $id++;
        chomp($line);
        my @temp = split(/\,/,$line);
        if ($cgiparams{'ID'} eq $id)
        {
            $cgiparams{'SERVICE'} = $temp[0];
            $cgiparams{'HOSTNAME'} = $temp[1];
            $cgiparams{'DOMAIN'} = $temp[2];
            $cgiparams{'PROXY'} = $temp[3];
            $cgiparams{'WILDCARDS'} = $temp[4];
            $cgiparams{'LOGIN'} = $temp[5];
            $cgiparams{'PASSWORD'} = $temp[6];
            $cgiparams{'ENABLED'} = $temp[7];
        }
    }
}

if ($cgiparams{'ACTION'} eq 'remove')
{
    open(FILE, ">$filename") or die 'Unable to open config file.';
    flock FILE, 2;
    my $id = 0;
    foreach my $line (@current)
    {
        $id++;
        unless ($cgiparams{"ID"} eq $id) { print FILE "$line"; }
    }
    close(FILE);
    &log(_('Dynamic DNS hostname removed'));

    system('/usr/bin/sudo /usr/local/bin/setddns.pl -f 2&>/dev/null');
}

if ($cgiparams{'ACTION'} eq 'toggle')
{
    open(FILE, ">$filename") or die 'Unable to open config file.';
    flock FILE, 2;
    my $id = 0;
    foreach my $line (@current)
    {
        $id++;
        unless ($cgiparams{'ID'} eq $id) { print FILE "$line"; }
        else
        {
            my $pos = 7;
            if ($cgiparams{'KEY1'} eq 'wildcard') { $pos = 4; }
            elsif ($cgiparams{'KEY1'} eq 'proxy') { $pos = 3; }
            chomp($line);
            my @temp = split(/\,/,$line);
            if ($temp[$pos] eq "on") {
                $temp[$pos] = "off";
            } else {
                $temp[$pos] = "on";
            }
            print FILE join(',',@temp) . "\n";
        }
    }
    close(FILE);

    system('/usr/bin/sudo /usr/local/bin/setddns.pl -f 2&>/dev/null');
}

if ($cgiparams{'ACTION'} eq 'forceupdate')
{
    system('/usr/bin/sudo /usr/local/bin/setddns.pl -f 2&>/dev/null');
}

if ($cgiparams{'ACTION'} eq '')
{
    $cgiparams{'ENABLED'} = 'on';
}

$selected{'SERVICE'}{'dhs.org'} = '';
$selected{'SERVICE'}{'DynAccess'} = '';
$selected{'SERVICE'}{'dyndns.org'} = '';
$selected{'SERVICE'}{'dyndns-custom'} = '';
$selected{'SERVICE'}{'dyndns-static'} = '';
$selected{'SERVICE'}{'dyns.cx'} = '';
$selected{'SERVICE'}{'easydns.com'} = '';
$selected{'SERVICE'}{'freedns-afraid.org'} = '';
$selected{'SERVICE'}{'no-ip.com'} = '';
$selected{'SERVICE'}{'nsupdate'} = '';
$selected{'SERVICE'}{'ovh.com'} = '';
$selected{'SERVICE'}{'regfish.com'} = '';
$selected{'SERVICE'}{'selfhost.de'} = '';
$selected{'SERVICE'}{'tzo.com'} = '';
$selected{'SERVICE'}{'zoneedit.com'} = '';
$selected{'SERVICE'}{$cgiparams{'SERVICE'}} = "selected='selected'";

$checked{'PROXY'}{'off'} = '';
$checked{'PROXY'}{'on'} = '';
$checked{'PROXY'}{$cgiparams{'PROXY'}} = "checked='checked'";

$checked{'WILDCARDS'}{'off'} = '';
$checked{'WILDCARDS'}{'on'} = '';
$checked{'WILDCARDS'}{$cgiparams{'WILDCARDS'}} = "checked='checked'";

$checked{'ENABLED'}{'off'} = '';
$checked{'ENABLED'}{'on'} = '';  
$checked{'ENABLED'}{$cgiparams{'ENABLED'}} = "checked='checked'";

if( -e  "${swroot}/ddns/behindnat" )
{ 
    $checked{'BEHINDNAT'}{'on'} = "checked='checked'";
}

&openpage(_('Dynamic DNS'), 1, '');
&openbigbox($errormessage, $warnmessage, $notemessage);

if (scalar(@errormessages) > 0) {
    #Stay in edit mode if we are in it
    if ($cgiparams{'EDITING'} ne 'no') {
        $cgiparams{'ACTION'} = 'edit';
        $cgiparams{'ID'} = $cgiparams{'EDITING'};
    }    
}

&openbox('100%', 'left', _('Current hosts'));

# if ($cgiparams{'ACTION'} eq "edit") {
#     $action = "edit";
# }
# else {
#     $action = "add";
# }

openeditorbox(_("Add a host"), _("Add a host"), ($cgiparams{'ACTION'} eq 'edit' || scalar(@errormessages) > 0 ? "showeditor" : ""), "hosts", @errormessages);

my $dynaccess_option = "";
if(-e $DYNACCESS_BIN){
  $dynaccess_option =   "<option $selected{'SERVICE'}{'DynAccess'}>DynAccess</option>";
}
printf <<END
<table width='100%'>
<tr>
    <td width='25%' class='base'>%s *</td>
    <td width='25%'><select size='1' name='SERVICE'>
            <option $selected{'SERVICE'}{'dhs.org'}>dhs.org</option>
            $dynaccess_option
            <option $selected{'SERVICE'}{'dyndns.org'}>dyndns.org</option>
            <option $selected{'SERVICE'}{'dyndns-custom'}>dyndns-custom</option>
            <option $selected{'SERVICE'}{'dyndns-static'}>dyndns-static</option>
            <option $selected{'SERVICE'}{'dyns.cx'}>dyns.cx</option>
            <option $selected{'SERVICE'}{'easydns.com'}>easydns.com</option>
            <option $selected{'SERVICE'}{'freedns-afraid.org'}>freedns-afraid.org</option>
            <option $selected{'SERVICE'}{'no-ip.com'}>no-ip.com</option>
            <option $selected{'SERVICE'}{'nsupdate'}>nsupdate</option>
            <option $selected{'SERVICE'}{'ovh.com'}>ovh.com</option>
            <option $selected{'SERVICE'}{'regfish.com'}>regfish.com</option>
            <option $selected{'SERVICE'}{'selfhost.de'}>selfhost.de</option>
<!--            <option $selected{'SERVICE'}{'tzo.com'}>tzo.com</option>    comment this service out until a working fix is developed -->
            <option $selected{'SERVICE'}{'zoneedit.com'}>zoneedit.com</option>
        </select></td>
    <td width='25%' class='base'>%s <input type='checkbox' name='PROXY' value='on' $checked{'PROXY'}{'on'} /></td>
    <td width='25%' class='base'>%s <input type='checkbox' name='WILDCARDS' value='on' $checked{'WILDCARDS'}{'on'} /></td>
</tr>
<tr>
    <td class='base'>%s *</td>
    <td><input type='text' name='HOSTNAME' value='$cgiparams{'HOSTNAME'}' /></td>
    <td class='base'>%s *</td>
    <td><input type='text' name='DOMAIN' value='$cgiparams{'DOMAIN'}' /></td>
</tr>
<tr>
    <td class='base'>%s *</td>
    <td><input type='text' name='LOGIN' value='$cgiparams{'LOGIN'}' /></td>
    <td class='base'>%s *</td>
    <td><input type='password' name='PASSWORD' value='$cgiparams{'PASSWORD'}' /></td>
</tr>
<tr>
    <td class='base'>%s<input type='checkbox' name='BEHINDNAT' value='on' $checked{'BEHINDNAT'}{'on'} /></td>
    <td>
        %s<input type='checkbox' name='ENABLED' value='on' $checked{'ENABLED'}{'on'} />
        <input type="hidden" name="ACTION" value="add"/>
    </td>
</tr>
</table>
END
,
_('Service'),
_('Behind a proxy'),
_('Enable wildcards'),
_('Hostname'),
_('Domain'),
_('Username'),
_('Password'),
_('behind Router(NAT)'),
_('Enabled'),
;

if ($cgiparams{'ACTION'} eq 'edit') {
    print "<input type='hidden' name='EDITING' value='$cgiparams{'ID'}' />\n";
} else {
    print "<input type='hidden' name='EDITING' value='no' />\n";
}
 
&closeeditorbox(($cgiparams{'ACTION'} eq 'add' || $cgiparams{'ACTION'} eq 'edit' || scalar(@errormessages) > 0 ? _("Update Host") : _("Add Host")), _("Cancel"), "hostsbutton", "hosts", $ENV{'SCRIPT_NAME'});

printf <<END
<table class="ruleslist" width='100%' cellpadding="0" cellspacing="0" border="0">
<tr>
    <th width='15%' class='boldbase'><b>%s</b></td>
    <th width='20%' class='boldbase'><b>%s</b></td>
    <th width='25%' class='boldbase'><b>%s</b></td>
    <th width='8%' nowrap="nowrap" align='center' class='boldbase'><b>%s</b></td>
    <th width='8%' class='boldbase'><b>%s</b></td>
    <th width='8%' class='boldbase'><b>%s</b></td>
    <th width='16%' class='boldbase' colspan='2'><b>%s</b></td>
</tr>
END
,
_('Service'),
_('Hostname'),
_('Domain'),
_('Anonymous web proxies'),
_('Wildcards'),
_('Enabled'),
_('Actions')
;

my $id = 0;
open(SETTINGS, "$filename") or die 'Unable to open config file.';
while (<SETTINGS>)
{
    my ($gifproxy,$descproxy,$gifwildcards,$descwildcard,$gifenabled,$descenabled);
    $id++;
    chomp($_);
    my @temp = split(/\,/,$_);
    if ($cgiparams{'ACTION'} eq 'edit' && $cgiparams{'ID'} eq $id) {
        print "<tr class='selected'>\n"; }
    elsif ($id % 2) { print "<tr class='odd'>\n"; }
    else { print "<tr class='even'>\n"; }
    if ($temp[3] eq 'on') {
        $gifproxy = 'on.png';
        $descproxy = _('Enabled (click to disable)');
    } else {
        $gifproxy = 'off.png';
        $descproxy = _('Disabled (click to enable)');
    }
    if ($temp[4] eq 'on') {
        $gifwildcards = 'on.png';
        $descwildcard = _('Enabled (click to disable)');
    } else {
        $gifwildcards = 'off.png';
        $descwildcard = _('Disabled (click to enable)');
    }
    if ($temp[7] eq 'on') {
        $gifenabled = 'on.png';
        $descenabled = _('Enabled (click to disable)');
    } else {
        $gifenabled = 'off.png';
        $descenabled = _('Disabled (click to enable)');
    }

printf <<END
<td>$temp[0]</td>
<td>$temp[1]</td>
<td>$temp[2]</td>

<form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}' name='frma$id'>
<td class='center'>
    <input class='imagebutton' type='image' src='/images/$gifproxy' alt='$descproxy' title='$descproxy' border='0'/>
    <input type='hidden' name='ACTION' value='toggle' />
    <input type='hidden' name='ID' value='$id' />
    <input type='hidden' name='KEY1' value='proxy' />
</td>
</form>

<form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}' name='frmb$id'>
<td class='center'>
    <input class='imagebutton' type='image' src='/images/$gifwildcards' alt='$descwildcard' title='$descwildcard'/>
    <input type='hidden' name='ACTION' value='toggle' />
    <input type='hidden' name='ID' value='$id' />
    <input type='hidden' name='KEY1' value='wildcard' />
</td>
</form>

<form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}' name='frmc$id'>
<td class='center'>
    <input class='imagebutton' type='image' src='/images/$gifenabled' alt='$descenabled' title='$descenabled'/>
    <input type='hidden' name='ACTION' value='toggle' />
    <input type='hidden' name='ID' value='$id' />
    <input type='hidden' name='KEY1' value='enable' />
</td>
</form>

<td class='center'>
    <form enctype='multipart/form-data' method='post' name='frmd$id' action='$ENV{'SCRIPT_NAME'}'>
    <input class='imagebutton' type='image' name='%s' src='/images/edit.png' title='%s' alt='%s' />
    <input type='hidden' name='ID' value='$id' />
    <input type='hidden' name='ACTION' value='edit' />
    </form>
</td>

<td align='center'>
    <form enctype='multipart/form-data' method='post' name='frme$id' action='$ENV{'SCRIPT_NAME'}'>
    <input class='imagebutton' type='image' name='%s' src='/images/delete.png' title='%s' alt='%s' />
    <input type='hidden' name='ID' value='$id' />
    <input type='hidden' name='ACTION' value='remove' />
    </form>
</td>


</tr>
END
,
_('Edit'), 
_('Edit'), 
_('Edit'),
_('Remove'), 
_('Remove'), 
_('Remove')
;
}
close(SETTINGS);
printf <<END
</table>
<form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}'>
<input type='hidden' name='ACTION' value='forceupdate' />
<table width='100%'>
<tr>
<td width='100%' align='center'><input class='submitbutton' type='submit' name='SUBMIT' value='%s' /></td>
</tr>
</table>
</form>
END
, _('Force update')
;

# If the file contains entries, print Key to action icons
if ( ! -z "$filename") {
printf <<END
<table class="list-legend" cellpadding="0" cellspacing="0" border="0">
<tr>
    <td class='boldbase'><b>%s:</b></td>
    <td>&nbsp; <img src='/images/on.png' alt='%s' /></td>
    <td class='base'>%s</td>
    <td>&nbsp; &nbsp; <img src='/images/off.png' alt='%s' /></td>
    <td class='base'>%s</td>
    <td>&nbsp; &nbsp; <img src='/images/edit.png' alt='%s' /></td>
    <td class='base'>%s</td>
    <td>&nbsp; &nbsp; <img src='/images/delete.png' alt='%s' /></td>
    <td class='base'>%s</td>
</tr>
</table>
END
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
}

&closebox();

&closebigbox();

&closepage();
