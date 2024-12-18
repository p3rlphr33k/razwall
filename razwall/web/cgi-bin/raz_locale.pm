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

use Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(_ gettext_init);
1;

#
#
#

use Locale::gettext;
use POSIX;     # Needed for setlocale()

my %catalogs = ();
sub gettext_init($$) {
    my $lang = shift;
    my $domain = shift;

    $ENV{'LANGUAGE'} = $lang;
    $ENV{'LANG'} = "en_US.utf-8";
    setlocale(LC_MESSAGES, "");
    $obj = Locale::gettext->domain_raw($domain);
    $obj->codeset('UTF-8');
    $catalogs{$domain} = $obj;
}

sub _ {
    my $msgid = shift;
    my @list = @_;

    my $text = "";
    foreach my $domain (keys(%catalogs)) {
        $catalog = $catalogs{$domain};
        $text = $catalog->get($msgid);
        last if ($text ne $msgid);
    }
    return sprintf($text, @list);
}

1;
