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

use lib '/razwall/web/cgi-bin/';
require 'header.pl';

$thisPath = $ENV{'REQUEST_URI'};
$thisAddress = $ENV{'SERVER_NAME'};

getcgihash(\%par);
%template = ();

undef $pagename;
undef $nomenu;
undef $nostatus;

readhash($productfile, \%producthash);
readhash($wizardfile, \%wizardhash);

# build system paths
$cgi_path = $1 if (($ENV{'SCRIPT_FILENAME'}||$0) =~ m/^(.*)(\\|\/)(.+?)$/);
$templates = $cgi_path . '/templates.pl';

# Check that templates file can be loaded..
&loadTemplates;

showhttpheaders();

openpage('Dashboard');

&getTemplate('dashboard');
&doSub('TITLE', 'RazWall Dashboard');
&printTemplate;

&closepage();

1;
