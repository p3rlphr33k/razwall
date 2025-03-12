#!/usr/bin/perl
#

my $item = {
    'caption' => _('Web Console'),
    'uri' => '/manage/webshell',
    'title' => _('Web Console'),
    'helpuri' => 'system.html#web-console',
    'enabled' => 1,
};

register_menuitem('00.haslave', '04.console', $item);

1;
