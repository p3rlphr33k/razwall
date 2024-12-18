#!/usr/bin/perl
#

my $item = {
    'caption' => _('AD join'),
    'title' => _('AD join'),
    'enabled' => 1,
    'uri' => '/manage/proxy/adjoin',
    'helpuri' => 'proxy.html#ad-join',
};
register_menuitem('00.haslave', '05.adjoin', $item);

1;