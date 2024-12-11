#!/usr/bin/perl
#
# SmoothWall CGIs
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
#
# $Id: shutdown.cgi,v 1.5 2003/12/11 11:06:40 riddles Exp $
#

require 'header.pl';

my %cgiparams;
my $death = 0;
my $rebirth = 0;

&showhttpheaders();

$cgiparams{'ACTION'} = '';
&getcgihash(\%cgiparams);

if ($cgiparams{'ACTION'} eq 'shutdown')
{
	$death = 1;
	&log(_('Shutting down %s %s',$brand,$product));
	system '/usr/local/bin/ipcopdeath';
}
elsif ($cgiparams{'ACTION'} eq 'reboot')
{
	$rebirth = 1;
	&log(_('Rebooting %s %s',$brand,$product));
	system '/usr/local/bin/ipcoprebirth';
}
if ($death == 0 && $rebirth == 0) {
	&openpage(_('Shutdown control'), 1, '');

        &openbigbox($errormessage, $warnmessage, $notemessage);

	&openbox('100%', 'left', _('Shutdown'));
	printf <<END
<table width='100%'>
<tr>
	<td align='center'>
            <form method='post' action='$ENV{'SCRIPT_NAME'}'>
              <input type='hidden' name='ACTION' value='reboot' />
              <input class='submitbutton' type='submit' name='submit' value='%s' />
            </form>
        </td>

	<td align='center'>
            <form method='post' action='$ENV{'SCRIPT_NAME'}'>
              <input type='hidden' name='ACTION' value='shutdown' />
              <input class='submitbutton' type='submit' name='submit' value='%s' />
            </form>
        </td>
</tr>
</table>
END
, _('Reboot'), _('Shutdown')
	;
	&closebox();

}
else
{
	&openpage(_('Shutdown control'), 1, '');
	my ($message,$title);
	if ($death)
	{
		$title = _('Shutting down');
		$message = $brand . " " . $product . " " . _('has been shut down') . ".";
	}
	else
	{
		$title = _('Rebooting');
		$message = $brand . " " . $product . " " . _('is being rebooted') . ".";
	}

        &openbigbox($errormessage, $warnmessage, $notemessage);
	printf <<END
<div align='center'>
<table width='100%' bgcolor='#ffffff'>
<tr><td align='center'>
<br /><br /><img src='/images/reboot_splash.png' /><br /><br /><br />
</td></tr>
</table>
<br />
<font size='6'>$message</font>
</div>
END
	;
}

&closebigbox();

&closepage();
