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

getcgihash( \%par );

sub print_html()
{
	showhttpheaders();
	openpage(_('Mail queue'), 1, '');
	openbox('100%','left', _('Mail queue'));

	open(QUEUE, '/usr/sbin/postqueue -p |');
        @lines = <QUEUE>;
        close(QUEUE);

	if(@lines)
	{
		print "<pre style=\"overflow: auto; width: 750px;\">";
		foreach $line (@lines) {
			print &cleanhtml($line,"y");
		}
		print "</pre>";
		printf <<EOF
		<br><br>
		<form method='post' action='$ENV{SCRIPT_NAME}'>
		<input type='hidden' name='ACTION' value="flush" />
		<input class='submitbutton' type='submit' name='submit' value="%s" />
		</form>
EOF
,_('Flush mail queue')
;
	} else {
		print "<br>";
		print _('The SMTP proxy is currently disabled. Therefore no information is available.');
		print "<br><br>";
	}
	closebox();
	closepage();
}

print_html;

if ( $par{ACTION} eq 'flush' ) {
        system('sudo /usr/sbin/postqueue -f');
}

