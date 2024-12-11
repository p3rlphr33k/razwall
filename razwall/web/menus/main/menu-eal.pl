#!/usr/bin/env perl
# +--------------------------------------------------------------------------+
# | Endian Firewall                                                          |
# +--------------------------------------------------------------------------+
# | Copyright (c) 2004-2016 S.p.A. <info@endian.com>                         |
# |         Endian S.p.A.                                                    |
# |         via Pillhof 47                                                   |
# |         39057 Appiano (BZ)                                               |
# |         Italy                                                            |
# |                                                                          |
# | This program is free software; you can redistribute it and/or modify     |
# | it under the terms of the GNU General Public License as published by     |
# | the Free Software Foundation; either version 2 of the License, or        |
# | (at your option) any later version.                                      |
# |                                                                          |
# | This program is distributed in the hope that it will be useful,          |
# | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            |
# | GNU General Public License for more details.                             |
# |                                                                          |
# | You should have received a copy of the GNU General Public License along  |
# | with this program; if not, write to the Free Software Foundation, Inc.,  |
# | 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.              |
# +--------------------------------------------------------------------------+

my $main_menu_item = '95.authentication';

my %testSubMenuHash = ();
my $testSubMenu = \%testSubMenuHash;

$testSubMenu->{'01.scopetest'} = {
   'caption' => _('Scope authentication'),
   'enabled' => 1,
   'uri' => '/manage/authentication/scopetest',
   'title' => _('Test authentication with scope')
};

$testSubMenu->{'02.providertest'} = {
   'caption' => _('Provider authentication'),
   'enabled' => 1,
   'uri' => '/manage/authentication/providertest',
   'title' => _('Test authentication with provider')
};

my %authenticationSubMenuHash = ();
my $authenticationSubMenu = \%authenticationSubMenuHash;

$authenticationSubMenu->{'01.user'} = {
   'caption' => _('Users'),
   'enabled' => 1,
   'uri' => '/manage/authentication/user',
   'title' => _('Authentication users')
};

$authenticationSubMenu->{'02.usergroup'} = {
   'caption' => _('Groups'),
   'enabled' => 1,
   'uri' => '/manage/authentication/usergroup',
   'title' => _('Authentication groups')
};

# $authenticationSubMenu->{'03.authserver'} = {
#    'caption' => _('Authentication server'),
#    'enabled' => 1,
#    'uri' => '/manage/authentication/settings/authserver',
#    'title' => _('Authentication server')
# };
#
# $authenticationSubMenu->{'04.service'} = {
#    'caption' => _('Authentication server mappings'),
#    'enabled' => 1,
#    'uri' => '/manage/authentication/settings/service',
#    'title' => _('Authentication server mappings')
# };

$authenticationSubMenu->{'05.settings'} = {
   'caption' => _('Settings'),
   'enabled' => 1,
   'uri' => '/manage/authentication/settings',
   'title' => _('Settings')
};

$authenticationSubMenu->{'99.test'} = {
   'caption' => _('Test'),
   'enabled' => 1,
   'uri' => '/manage/authentication/test',
   'title' => _('Test')
};

my $authenticationMenu = {
   'caption' => _('Authentication'),
   'enabled' => 1,
   'subMenu' => $authenticationSubMenu,
};

# uncomment to see the menu for debugging or other stuff
# register_menuitem($main_menu_item, 0, $authenticationMenu);
