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
