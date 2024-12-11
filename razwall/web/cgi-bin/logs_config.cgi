#!/usr/bin/perl
#
# IPCop CGIs
#
# This code is distributed under the terms of the GPL
#
# (c) The IPCop Team
#
# $Id: config.dat,v 1.2.2.3 2004/03/13 12:53:58 eoberlander Exp $
#

require 'header.pl';

my (%logsettings, %checked, %selected, $errormessage, %outgoingsettings, %par);

&showhttpheaders();

$logsettings{'LOGVIEW_REVERSE'} = 'off';
$logsettings{'LOGVIEW_SIZE'} = $viewsize;
$logsettings{'LOGWATCH_LEVEL'} = 'Low';
$logsettings{'LOGWATCH_KEEP'} = '56';
$logsettings{'ENABLE_REMOTELOG'} = 'off';
$logsettings{'REMOTELOG_ADDR'} = '';
$logsettings{'REMOTELOG_PROTO'} = 'UDP';
$logsettings{'ACTION'} = '';

$logsettings{'LOG_BADTCP'} = 'off';
$logsettings{'LOG_NEWNOTSYN'} = 'off';
$logsettings{'LOG_DROPS'} = 'off';

$outgoingfw{'LOG_ACCEPTS'} = 'off';

&getcgihash(\%par);

if (-f "${swroot}/logging/settings") {
    &readhash("${swroot}/logging/settings", \%logsettings);
}
if (-f "${swroot}/outgoing/settings") {
    &readhash("${swroot}/outgoing/settings", \%outgoingsettings);
}

if ($par{'ACTION'} eq 'save')
{

  if ($par{'ENABLE_REMOTELOG'} eq 'on')
  {
    unless ( &validfqdn($par{'REMOTELOG_ADDR'}) ||
             &validip  ($par{'REMOTELOG_ADDR'}))
    {
      $errormessage = _('Invalid syslogd server address');
    }
  }
  unless ($par{'LOGWATCH_KEEP'} =~ /^\d+$/)
  {
    $errormessage = _('Keep time must be a valid number');
  }
  unless ($par{'LOGWATCH_LEVEL'} =~ /^Low|Med|High$/)
  {
    $errormessage = _('Invalid input');
  }
  unless ($errormessage) {

    $logsettings{'LOGVIEW_REVERSE'} = $par{'LOGVIEW_REVERSE'};
    $logsettings{'LOGVIEW_SIZE'} = $par{'LOGVIEW_SIZE'};
    $logsettings{'LOGWATCH_LEVEL'} = $par{'LOGWATCH_LEVEL'};
    $logsettings{'LOGWATCH_KEEP'} = $par{'LOGWATCH_KEEP'};
    $logsettings{'ENABLE_REMOTELOG'} = $par{'ENABLE_REMOTELOG'};
    $logsettings{'REMOTELOG_ADDR'} = $par{'REMOTELOG_ADDR'};
    $logsettings{'REMOTELOG_PROTO'} = $par{'REMOTELOG_PROTO'};

    $logsettings{'LOG_BADTCP'} = $par{'LOG_BADTCP'};
    $logsettings{'LOG_NEWNOTSYN'} = $par{'LOG_NEWNOTSYN'};
    $logsettings{'LOG_DROPS'} = $par{'LOG_DROPS'};

    $outgoingsettings{'LOG_ACCEPTS'} = $par{'LOG_ACCEPTS'};

    &writehash("${swroot}/logging/settings", \%logsettings);
    &writehash("${swroot}/outgoing/settings", \%outgoingsettings);
    system('/usr/local/bin/restartsyslog 2>&1 >/dev/null ') == 0
      or $errormessage = _('Helper program returned error code')." " . $?/256;
    system('/etc/rc.d/rc.firewall reload  2>&1 >/dev/null') == 0
      or $errormessage = _('Helper program returned error code')." " . $?/256;
    system('/usr/local/bin/setoutgoing  2>&1 >/dev/null') == 0
      or $errormessage = _('Helper program returned error code')." " . $?/256;
  }

}

if (-f "${swroot}/logging/settings") {
    &readhash("${swroot}/logging/settings", \%logsettings);
}
if (-f "${swroot}/outgoing/settings") {
    &readhash("${swroot}/outgoing/settings", \%outgoingsettings);
}

$checked{'LOG_ACCEPTS'}{'off'} = '';
$checked{'LOG_ACCEPTS'}{'on'} = '';
$checked{'LOG_ACCEPTS'}{$outgoingsettings{'LOG_ACCEPTS'}} = "checked='checked'";

$checked{'LOG_BADTCP'}{'off'} = '';
$checked{'LOG_BADTCP'}{'on'} = '';
$checked{'LOG_BADTCP'}{$logsettings{'LOG_BADTCP'}} = "checked='checked'";

$checked{'LOG_NEWNOTSYN'}{'off'} = '';
$checked{'LOG_NEWNOTSYN'}{'on'} = '';
$checked{'LOG_NEWNOTSYN'}{$logsettings{'LOG_NEWNOTSYN'}} = "checked='checked'";

$checked{'LOG_DROPS'}{'off'} = '';
$checked{'LOG_DROPS'}{'on'} = '';
$checked{'LOG_DROPS'}{$logsettings{'LOG_DROPS'}} = "checked='checked'";

$checked{'ENABLE_REMOTELOG'}{'off'} = '';
$checked{'ENABLE_REMOTELOG'}{'on'} = '';
$checked{'ENABLE_REMOTELOG'}{$logsettings{'ENABLE_REMOTELOG'}} = "checked='checked'";

$checked{'LOGVIEW_REVERSE'}{'off'} = '';
$checked{'LOGVIEW_REVERSE'}{'on'} = '';
$checked{'LOGVIEW_REVERSE'}{$logsettings{'LOGVIEW_REVERSE'}} = "checked='checked'";

$selected{'LOGWATCH_LEVEL'}{'Low'} = '';
$selected{'LOGWATCH_LEVEL'}{'Med'} = '';
$selected{'LOGWATCH_LEVEL'}{'High'} = '';
$selected{'LOGWATCH_LEVEL'}{$logsettings{'LOGWATCH_LEVEL'}} = "selected='selected'";

$selected{'REMOTELOG_PROTO'}{'TCP'} = '';
$selected{'REMOTELOG_PROTO'}{'UDP'} = '';
$selected{'REMOTELOG_PROTO'}{$logsettings{'REMOTELOG_PROTO'}} = "selected='selected'";

&openpage(_('Log settings'), 1, '');

&openbigbox($errormessage, $warnmessage, $notemessage);

&openbox('100%', 'left', _('Log viewing options'));
printf <<END
<form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}'>
<input type='hidden' name='ACTION' value='save' />

<table width='100%'>
<tr>
   <td class='base' width='30%'>%s:</td><td width='10%'><input type='text' name='LOGVIEW_SIZE' size="5" value="$logsettings{'LOGVIEW_SIZE'}" /></td>
   <td class='base' width='20%'>&nbsp;</td>
   <td class='base' width='30%'>%s:</td><td width='10%'><input type='checkbox' name='LOGVIEW_REVERSE' $checked{'LOGVIEW_REVERSE'}{'on'} /></td>
</tr>
</table>
END
,
_('Number of lines to display'),
_('Sort in reverse chronological order')
;
&closebox();

&openbox('100%', 'left', _('Log summaries'));
printf <<END
<table width='100%'>
<tr>
  <td class='base' width='50%'>%s</td>
  <td>%s:</td><td>
  <select name='LOGWATCH_LEVEL'>
  <option value='Low' $selected{'LOGWATCH_LEVEL'}{'Low'}>%s</option>
  <option value='Med' $selected{'LOGWATCH_LEVEL'}{'Med'}>%s</option>
  <option value='High' $selected{'LOGWATCH_LEVEL'}{'High'}>%s</option>
  </select></td>
</tr>
</table>
END
,
_('Keep summaries for %s days', "<input type='text' name='LOGWATCH_KEEP' value='$logsettings{'LOGWATCH_KEEP'}' size='4' />"),
_('Detail level'),
_('Low'),
_('Medium'),
_('High')
;
&closebox();

&openbox('100%', 'left', _('Remote logging'));
printf <<END
<table width='100%'>
<tr>
  <td class='base'>%s:</td><td><input type='checkbox' name='ENABLE_REMOTELOG' $checked{'ENABLE_REMOTELOG'}{'on'} /></td>
  <td>%s:</td>
  <td><input type='text' name='REMOTELOG_ADDR' value='$logsettings{'REMOTELOG_ADDR'}' /></td>
  <td>%s:
    <select name="REMOTELOG_PROTO">
      <option value="TCP" $selected{'REMOTELOG_PROTO'}{'TCP'}>%s</option>
      <option value="UDP" $selected{'REMOTELOG_PROTO'}{'UDP'}>%s</option>
    </select>
  </td>
</tr>
</table>
END
,
_('Enabled'),
_('Syslog server'),
_('Protocol'),
_('TCP'),
_('UDP')
;
&closebox();


&openbox('100%', 'left', _('Firewall logging'));
printf <<END
<table width='100%'>
<tr>
  <td width="10%">%s:</td>
  <td width="5%"><input type='checkbox' name='LOG_BADTCP' value='on' $checked{'LOG_BADTCP'}{'on'} /></td>

  <td width="10%">%s:</td>
  <td width="5%"><input type='checkbox' name='LOG_NEWNOTSYN' value='on' $checked{'LOG_NEWNOTSYN'}{'on'} /></td>
</tr>

<tr>
  <td class='base'>%s:</td>
  <td><input type='checkbox' name='LOG_ACCEPTS' value='on' $checked{'LOG_ACCEPTS'}{'on'} /></td>

  <td class='base'>%s:</td>
  <td><input type='checkbox' name='LOG_DROPS' value='on' $checked{'LOG_DROPS'}{'on'} /></td>
</tr>
</table>
END
,
_('Log packets with BAD constellation of TCP flags'),
_('Log NEW connections without SYN flag'),
_('Log accepted outgoing connections'),
_('Log refused packets')

;
&closebox();


printf <<END
<div align='center'>
<table width='60%'>
<tr>
  <td align='center'><input class='submitbutton' type='submit' name='submit' value='%s' /></td>
</tr>
</table>
</div>
</form>
END
,_('Save')
;

&closebigbox();

&closepage();
