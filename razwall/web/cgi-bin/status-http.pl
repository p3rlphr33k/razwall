require 'header.pl';
require '/razwall/web/cgi-bin/endianinc.pl';

my $http = ['httpd', '', ''];
register_status(_('Web server'), $http);
