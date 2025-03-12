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
my %pppsettings;
my %netsettings;
my @graphs;

&showhttpheaders();

my $dir = "/razwall/web/html/sgraph";
$cgiparams{'ACTION'} = '';
&getcgihash(\%cgiparams);
my $sgraphdir = "/razwall/web/html/sgraph";

&openpage(_('Proxy access graphs'), 1, '');

&openbigbox($errormessage, $warnmessage, $notemessage);

&openbox('100%', 'left', _('Proxy access graphs'));

if (open(IPACHTML, "$sgraphdir/index.html"))
{
$skip = 1;
	while (<IPACHTML>)
	{
		$skip = 1 if /^<HR>$/;
		if ($skip)
		{
			$skip = 0 if /<H1>/;
			next;
		}
		s/<IMG SRC=([^"'>]+)>/<img src='\/sgraph\/$1' alt='Graph' \/>/;
		s/<HR>/<hr \/>/g;
		s/<BR>/<br \/>/g;
		s/<([^>]*)>/\L<$1>\E/g;
		s/(size|align|border|color)=([^'"> ]+)/$1='$2'/g;
		print;
	}
	close(IPACHTML);
}
else {
	print _('No information available.'); }

&closebox();

&closebigbox();

&closepage();
