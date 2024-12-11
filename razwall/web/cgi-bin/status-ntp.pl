require 'header.pl';
require '/razwall/web/cgi-bin/endianinc.pl';

my $ntp = ['ntpd', '', ''];
register_status(_('NTP server'), $ntp);
