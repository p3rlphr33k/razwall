require 'header.pl';
require '/razwall/web/cgi-bin/endianinc.pl';

my $dhcp = ['dhcpd', '', ''];
register_status(_('DHCP server'), $dhcp);
