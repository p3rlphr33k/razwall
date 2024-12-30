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
use CGI();
use CGI::Cookie;
use Socket;
use Time::Local;
use endian_locale;
use Net::IPv4Addr qw (:all);
use HTML::Entities;
use core_widgets;
use JSON::XS;
use URI::Escape;
#use Unicode::Escape qw(escape unescape);
use File::Basename;
use YAML::Syck;
use Text::Glob qw (match_glob);

my @white_list = undef;
my $has_gui_profile = 0;

sub check_user_profile() {
    my $guiuser_filename = "";
    foreach my $f (glob('/usr/lib/efw/auth/guiuser*.default')) {
        $guiuser_filename = $f;
    }
    if (-f '/razwall/config/auth/guiuser') {
        $guiuser_filename = '/razwall/config/auth/guiuser';
    }

    my $guiprofile_filename = "";
    foreach my $f (glob('/usr/lib/efw/auth/guiprofile*.default')) {
        $guiprofile_filename = $f;
    }
    if (-f '/razwall/config/auth/guiprofile') {
        $guiprofile_filename = '/razwall/config/auth/guiprofile';
    }

    $user = $ENV{'REMOTE_USER'};
    if ($guiuser_filename eq "" || $guiprofile_filename eq "") {
        return undef;
    }
    $profile = '';
    my %yaml_user = %{ LoadFile( $guiuser_filename ) };
    foreach my $key (keys %yaml_user) {
      if ($yaml_user{$key}->{'name'} eq $user) {
          $profile = $yaml_user{$key}->{'profile'};
          break;
      }
    }
    if ($profile eq '') {
        return undef;
    }
    my %yaml_profile = %{ LoadFile( $guiprofile_filename ) };
    if (! exists $yaml_profile{$profile}) {
        return undef;
    }
    $has_gui_profile = 1;
    @white_list = @{ $yaml_profile{$profile}{'white_list'} };
    @black_list = @{ $yaml_profile{$profile}{'black_list'} };
    $script_name = $ENV{'SCRIPT_NAME'};
    foreach my $glob (@black_list) {
        if ($glob =~ /\/\*$/ && match_glob(substr($glob, 0, -2), $script_name)) {
           print "Status: 403 Forbidden\r\n";
           print "\r\n";
           exit 0;
        }
        if (match_glob($glob, $script_name)) {
           print "Status: 403 Forbidden\r\n";
           print "\r\n";
           exit 0;
        }
    }
    if ((length @white_list == 0) || (@white_list == '')) {
        return 1; 
    }
    foreach my $glob (@white_list) {
        if ($glob =~ /\/\*$/ && match_glob(substr($glob, 0, -2), $script_name)) {
           return 1;
        }
        if (match_glob($glob, $script_name)) {
            return 1;
        }
    }
    print "Status: 403 Forbidden\r\n";
    print "\r\n";
    exit 0;
}
check_user_profile();

$|=1; # line buffering

sub escape_quotes($) {
    $var = shift;
    $var =~ s/(["\"", "'"])/\\$1/g;
    return $var;
}

sub get_major_version() {
    my %version_settings = ();
    &readhash("/razwall/config/version/settings", \%version_settings);
    my $major_version = $version_settings{'MAJOR_VERSION'} ne "" ? $version_settings{'MAJOR_VERSION'} : "";
    return $major_version;
}

sub get_product_minor_version() {
    my %version_settings = ();
    &readhash("/razwall/config/version/settings", \%version_settings);
    my $product_minor_version = $version_settings{'PRODUCT_MINOR_VERSION'} ne "" ? $version_settings{'PRODUCT_MINOR_VERSION'} : "";
    return $product_minor_version;
}

sub get_product_version() {
    my $product_major_version = get_product_major_version();
    my $product_minor_version = get_product_minor_version();
    if ($product_major_version ne "" && $product_minor_version ne "") {
        return $product_major_version . "." . $product_minor_version;
    } elsif ($product_major_version ne "") {
        return $product_major_version;
    } elsif ($product_minor_version ne "") {
        return $product_minor_version;
    }
    return ""
}

sub get_version_info() {
    $version_custom = </etc/release*.custom>;
    $version_vendor = </etc/release*.vendor>;

    if ( $version_custom ) {
        $release = $version_custom;
    } elsif ( $version_vendor ) {
        $release = $version_vendor;
    } else {
        $release = '/etc/release';
    }

    open(FILE, $release);
    while (<FILE>) {
        $read_ver = $_;
    }

    if ($read_ver =~ /^$/) {
        return "Endian Firewall (unknown version)";
    }
    return $read_ver;
}

sub get_documentation_type() {
    my %productsettings = ();
    &readhash("/razwall/config/product/settings", \%productsettings);
    return $productsettings{'DOCUMENTATION_TYPE'} ne "" ? $productsettings{'DOCUMENTATION_TYPE'} : "";
}

sub get_settings_product_name() {
    my %productsettings = ();
    &readhash("/razwall/config/product/settings", \%productsettings);
    return $productsettings{'PRODUCT_NAME'};
}

# Return all brand specific settings
sub get_brand_settings {
    my $hash = shift;
    
    if(-f "/etc/custom.conf") {
        &readhash("/etc/custom.conf", $hash);
        $branded = 1;
    }
}

# Is the firewall branded or not.
sub is_branded() {
    return $branded;
}

sub get_company() {
    &get_brand_settings(\%brandsettings);
    
    chomp($brandsettings{'COMPANY'});
    return (is_branded()) ? $brandsettings{'COMPANY'} : "Endian";
}

sub get_brand() {
    &get_brand_settings(\%brandsettings);
    
    chomp($brandsettings{'BRAND'});
    return (is_branded()) ? $brandsettings{'BRAND'} : "Endian";
}

sub get_product() {
    &get_brand_settings(\%brandsettings);
    
    chomp($brandsettings{'PRODUCT'});
    return $brandsettings{'PRODUCT'} || get_settings_product_name() || "Firewall";
}

sub get_network_brand() {
    &get_brand_settings(\%brandsettings);
    
    chomp($brandsettings{'EN_BRAND'});
    return (is_branded()) ? $brandsettings{'EN_BRAND'} : "Network";
}

my $webroot = '/home/httpd/cgi-bin/';
if ($ENV{'DOCUMENT_ROOT'}) {
    $webroot = $ENV{'DOCUMENT_ROOT'};
}

my $menuCache = '/var/cache/menu/';
my $menuRegistry = '/home/httpd/menus/';

$version = get_version_info();
$brand = get_brand();
$product = get_product();
$en_brand = get_network_brand();
$network_name = $brand.' '.$en_brand;

# Is the firewall branded?
$branded = 0;
$revision = 'final';
$swroot = '/var/efw';
$pagecolour = '#ffffff';
#$tablecolour = '#a0a0a0';
$tablecolour = '#FFFFFF';
$bigboxcolour = '#F6F4F4';
$boxcolour = '#EAE9EE';
$bordercolour = '#000000';
$table1colour = '#E0E0E0';
$table2colour = '#F0F0F0';
$colourred = '#993333';
$colourorange = '#FF9933';
$colouryellow = '#FFFF00';
$colourgreen = '#339933';
$colourblue = '#333399';
$colourfw = '#000000';
$colourvpn = '#990099';
$colourerr = '#FF0000';
$viewsize = 150;
$errormessage = '';
$notemessage = '';
$warnmessage = '';
my %menuhash = ();
my $menu = \%menuhash;
my %flavourmenushash = ();
my $flavourmenus = \%flavourmenushash;
my $useFlavour = 'main';
%settings = ();
%hostsettings = ();
%ethsettings = ();
@URI = ();
$supported=0;

$HOTSPOT_ENABLED = '/razwall/config/hotspot/enabled';

$DOWNLOADJOB_TIMESTAMPS = '/razwall/config/download/timestamps';

$ALLOW_PNG = '/images/stock_ok.png';
$DENY_PNG = '/images/stock_stop.png';
$ADD_PNG = '/images/add.png';
$UP_PNG = '/images/stock_up-16.png';
$DOWN_PNG = '/images/stock_down-16.png';
$ENABLED_PNG = '/images/on.png';
$DISABLED_PNG = '/images/off.png';
$EDIT_PNG = '/images/edit.png';
$DELETE_PNG = '/images/delete.png';
$OPTIONAL_PNG = '/images/blob.png';
$CLEAR_PNG = '/images/clear.gif';

$PERSISTENT_DIR = '/usr/lib/efw/';
$USER_DIR = '/razwall/config/';
$STATE_DIR = '/var/lib/efw/';
$PROVISIONING_DIR = '/var/emc/';
$VENDOR_DIR = 'vendor';
$DEFAULT_DIR = 'default';
$VENDOR_DIR = 'vendor';
@IGNORE_SUFFICES = qw'old orig rej rpmsave rpmnew';

my %cookies = fetch CGI::Cookie;

### Initialize environment
&readhash("${swroot}/host/settings", \%hostsettings);
&readhash("${swroot}/main/settings", \%settings);
&readhash("${swroot}/ethernet/settings", \%ethsettings);

# make backwards compatible
$settings{'HOSTNAME'} = $hostsettings{'HOSTNAME'};
$settings{'DOMAINNAME'} = $hostsettings{'DOMAINNAME'};

$language = $settings{'LANGUAGE'};
$hostname = $settings{'HOSTNAME'};
$hostnameintitle = 0;

### Initialize language
if ($language =~ /^(\w+)$/) {$language = $1;}
gettext_init($language, "efw");
gettext_init($language, "efw.enterprise");
gettext_init($language, "efw.vendor");

@zones = qw 'GREEN ORANGE BLUE RED';
%zonecolors = (
        RED => $colourred,
        BLUE => $colourblue,
        GREEN => $colourgreen,
        ORANGE => $colourorange,
        LOCAL => $colourfw
);
%strings_zone = (
	'GREEN' => _('GREEN'),
	'BLUE' => _('BLUE'),
	'ORANGE' => _('ORANGE'),
	'RED' => _('RED'),
        'LOCAL' => _('LOCAL'),
);

@bypassuris = qw '/welcome /hotspot /template.cgi';
generalRedirect();

sub generalRedirect() {
    ### Make sure this is an SSL request
    return if (! $ENV{'SERVER_ADDR'});
    return if ($ENV{'HTTPS'} eq 'on');
    foreach my $uri (@bypassuris) {
	return if ($ENV{'SCRIPT_NAME'} =~ $uri);
    }
    print "Status: 302 Moved\r\n";
    print "Location: https://$ENV{'SERVER_ADDR'}:10443/$ENV{'PATH_INFO'}\r\n\r\n";
    exit 0;
}

sub checkForLogout() {
    ### Check if the user clicked the logout button
    my $is_opera = 0;
    my $browser_user_agent = $ENV{'HTTP_USER_AGENT'};
    if (! $browser_user_agent) {
        $browser_user_agent = "";
    }
    if (index(lc($browser_user_agent), "opera") != -1) {
        $is_opera = 1;
    }

    if ($ENV{'SCRIPT_NAME'} eq '/cgi-bin/logout.cgi') {
	my $logout = 0;
	my $timeout = "";
	my $cookiepath = "/";
	foreach $key (keys %cookies) {
	    if ($key eq "EFWlogout") {
		$logout = 1;
	    }
	}

	if ($logout == 0) {
	    $timeout = gmtime(time()+365*24*3600)." GMT";
	    print "Set-Cookie: EFWlogout=1; expires=$timeout; path=$cookiepath\r\n";
	    print "Status: 401 Unauthorized\r\n";
	    my $realm_suffix = "";
	    if ($is_opera) {
                $realm_suffix = "." . rand(10000);
	    }
	    print "WWW-authenticate: Basic realm=\"Restricted$realm_suffix\"\r\n\r\n";
	} else {
	    $timeout = gmtime(time()-365*24*3600)." GMT";
	    print "Set-Cookie: EFWlogout=1; expires=$timeout; max-age=0; path=$cookiepath\r\n";
	    print "Location: https://$ENV{'SERVER_ADDR'}:10443/\r\n\r\n";
	}
    } else {
	my $timeout = "";
	my $cookiepath = "/";
	$timeout = gmtime(time()-365*24*3600)." GMT";
	print "Set-Cookie: EFWlogout=1; expires=$timeout; max-age=0; path=$cookiepath\r\n";
    }
}

sub expireMenuCache() {
    my $cachefile = "${menuCache}/${useFlavour}.json";
    if (-e $cachefile) {
        unlink($cachefile);
    }
}

sub cacheMenu($$) {
    my $menu = shift;
    my $flavour = shift;
    my $cachefile = "${menuCache}/${flavour}.json";
    if (! open(J, ">$cachefile")) {
	warn("Could not cache menu to '$cachefile' due to $!");
	return;
    }
    my $jsonobj = jsonifyMenu($menu);
    print J $jsonobj;
    close(J);
}

sub loadMenuFromCache($) {
    my $flavour = shift;
    my $cachefile = "${menuCache}/${flavour}.json";
    open(J, $cachefile);

    # $cachefile content *is* utf-8 encoded, don't ask why json
    # needs it to load as latin1. I don't know.
    # It's however necessary to use the latin1 encoder
    # otherwise it will be encoded as utf-8 twice.
    my $jsonobj = JSON::XS->new->latin1->decode (join('', <J>));
    close J;
    return $jsonobj;
}

sub isMenuCacheExpired($) {
    my $flavour = shift;
    my $cachefile = "${menuCache}/${flavour}.json";

    if (! -e $cachefile) {
	return 1;
    }
    my $dirtime = (stat("$menuRegistry/$flavour"))[9];
    my $filetime = (stat($cachefile))[9];
    if ($filetime < $dirtime) {
	return 1;
    }

    return 0;
}

sub registerMenus($) {
    my $flavour = shift;
    my %emptyhash;
    $menu = \%emptyhash;
    foreach my $regfile (glob("$menuRegistry/$flavour/menu-*.pl")) {
	require $regfile;
    }
    disableInexistentMenus($menu);
    cacheMenu($menu, $flavour);

    return $menu;
}

sub genFlavourMenus() {
    $flavourmenus->{$useFlavour} = $menu;
    foreach my $flavour (glob("$menuRegistry/*")) {
	$flavour =~ s#^.*/([^/]+)$#\1#;
	if (isMenuCacheExpired($flavour)) {
	    $menu = registerMenus($flavour);
	} else {
	    $menu = loadMenuFromCache($flavour);
	}
	$flavourmenus->{$flavour} = $menu;
    }
    $menu = $flavourmenus->{$useFlavour};
}

sub setFlavour($) {
    my $flavour = shift;
    $useFlavour = $flavour;
}

sub getHTTPRedirectHost() {
    my $httphost = $ENV{'HTTP_HOST'};

    if ($ENV{'HTTPS'} ne 'on') {
	my ($host, $port) = split(/:/, $httphost);
	if ($port =~ /^$/) {
	    $port = '10443';
	}
	$httphost = "$host:$port";
    }
    return $httphost;
}

### Check whether this system is a HA slave or not - if so redirect to an info-page
sub checkForHASlave() {
    return if ( ! -e "${swroot}/ha/settings");
    &readhash("${swroot}/ha/settings",\%hasettings);
    return if ($hasettings{'HA_ENABLED'} ne 'on');
    return if ($hasettings{'HA_STATE'} ne 'slave');
    
    setFlavour('haslave');
    return if ($ENV{'SCRIPT_NAME'} eq '/cgi-bin/ha_slave.cgi');
    if (! gettitle($flavourmenus->{$useFlavour})) {
	my $host = getHTTPRedirectHost();
	print "Location: https://$host/cgi-bin/ha_slave.cgi\r\n\r\n";
    }
}

sub orange_used () {
    if ($ethsettings{'CONFIG_TYPE'} =~ /^[1357]$/) {
	return 1;
    }
    return 0;
}

sub blue_used () {
    if ($ethsettings{'CONFIG_TYPE'} =~ /^[4567]$/) {
	return 1;
    }
    return 0;
}

sub is_modem {
    if ($ethsettings{'CONFIG_TYPE'} =~ /^[0145]$/) {
	return 1;
    }
    return 0;
}


### Initialize menu
#
# New dynamic menu structure:
#
# Right now there is a 'main' menu, which is backwards compatible and
# allows legacy registration in header.pl and legacy registration
# through hooks in /home/httpd/cgi-bin/menu-*.pl using the
# register_menuitem() registration function.
#
# New style menu item registration allows for more different main menus
# which allow to be selected by setting the global $useFlavour variable.
#
# Menu items can be registered by creating a hook file in 
# /home/httpd/menus/$flavour/menu-*.pl which then use the registering
# function register_menuitem()
#
# The main menu is called 'main'. Right now there is one more menu
# 'haslave'. A 'hotspot' menu may follow.
#
##
sub genmenu {
    if ($useFlavour ne 'main') {
	$menu = $flavourmenus->{$useFlavour};
    }
    return $menu;
}

sub calcURI() {
    if ($ENV{'SCRIPT_NAME'} =~ '/template.cgi') {
	my $cgi = CGI->new ();
	%vars = $cgi->Vars();
	$URI[0] = "/cgi-bin/".$vars{'SCRIPT_NAME'};
	$URI[1] = $vars{'PARAMETER'};
	return;
    }

    @URI=split ('\?',  $ENV{'REQUEST_URI'} );
}

sub showhttpheaders
{
    calcURI();
    checkForLogout();
    genFlavourMenus();

    # XXX: if there are more, maybe make them hookable
    checkForHASlave();
	print "Pragma: no-cache\n";
	print "Cache-control: no-cache\n";
	print "Connection: close\n";
	print "Content-type: text/html\n\n";
}

sub is_menu_visible($) {
    my $link = shift;
    $link =~ s#\?.*$##;
    if ( $link =~ /^http:\/\// ) {
        return 1;
    }
    if ($link !~ /\.cgi$/) {
	return 1;
    }
    return (-e $webroot."/../$link");
}


sub getlink($;$) {
    my $root = shift;
    my $disable_permission_check = shift;
    if (! $root->{'enabled'}) {
       return '';
    }
    if ($root->{'uri'} !~ /^$/) {
        if ($disable_permission_check || check_menu_permission($root, 1)) {
            my $vars = '';
            if ($root->{'vars'} !~ /^$/) {
                $vars = '?'. $root->{'vars'};
            }
            if (! is_menu_visible($root->{'uri'})) {
                return '';
            }
            return $root->{'uri'}.$vars;
        }
    }
    my $submenus = $root->{'subMenu'};
    if (! $submenus) {
        return '';
    }
    foreach my $item (sort keys %$submenus) {
	my $item = $submenus->{$item};
        if ($disable_permission_check || check_menu_permission($item, 1)) {
            my $link = getlink($item, $disable_permission_check);
            if ($link ne '') {
                return $link;
            }
        }
    }
    return '';
}


sub compare_url($) {
    my $conf = shift;

    my $uri = $conf->{'uri'};
    my $vars = $conf->{'vars'};
    my $novars = $conf->{'novars'};

    if ($uri eq '') {
	return 0;
    }
    if ($uri ne $URI[0]) {
	return 0;
    }
    if ($novars) {
	if ($URI[1] !~ /^$/) {
	    return 0;
	}
    }
    if (! $vars) {
	return 1;
    }
    return ($URI[1] =~ /$vars.*/);
}


sub gettitle($) {
    my $root = shift;

    if (! $root) {
	return '';
    }
    foreach my $item (sort keys %$root) {
	my $val = $root->{$item};
	if (compare_url($val)) {
	    $val->{'selected'} = 1;
	    if ($val->{'title'} !~ /^$/) {
		return $val->{'title'};
	    }
	    return 'EMPTY TITLE';
	}

	my $title = gettitle($val->{'subMenu'});
	if ($title ne '') {
	    $val->{'selected'} = 1;
	    return $title;
	}
    }
    return '';
}

sub disableInexistentMenus($) {
    my $root = shift;
    if (! $root) {
	return;
    }
    foreach my $item (sort keys %$root) {
	my $node = $root->{$item};
	if ($node->{'subMenu'}) {
	    disableInexistentMenus($node->{'subMenu'});
	}
	if (! $node->{'enabled'}) {
	    next;
	}
	if (! $node->{'uri'}) {
	    next;
	}
	if (! is_menu_visible($node->{'uri'})) {
	    $node->{'enabled'} = 0;
	    next;
	}
    }
}

sub showmenu() {
    printf <<EOF
<div id="menu-top-background"></div>
<div id="menu-top">
    <ul>
EOF
;
    foreach my $k1 ( sort keys %$menu ) {
        if (! $menu->{$k1}{'enabled'}) {
            next;
        }
        my $link = getlink($menu->{$k1});
        if ($link eq '') {
            next;
        }
        if (! check_menu_permission($menu->{$k1}, 0, $link)) {
            next;
        }
        if ($menu->{$k1}->{'selected'}) {
            print '<li class="selected">';
        } else {
            print '<li>';
        }
        printf <<EOF
            <a href="$link">$menu->{$k1}{'caption'}</a>
        </li>
EOF
        ;
    }
    printf <<EOF
    </ul>
</div>
<script language="javascript" type="text/javascript">
\$(document).ready(function() {
    \$("#menu-top-background").stalker();
    \$("#menu-top").stalker();
});
</script>
EOF
    ;
}

sub getselected($) {
    my $root = shift;
    if (!$root) {
	return 0;
    }

    foreach my $item (%$root) {
	if ($root->{$item}{'selected'}) {
	    return $root->{$item};
	}
    }
}

sub check_sub_menu_permission($$) {
    my $hash = shift;
    my $disable_submenu_check = shift;
    if ($hash->{'subMenu'} && !$disable_submenu_check) {
        my $submenus = $hash->{'subMenu'};
        foreach my $sub_item (sort keys %$submenus) {
            my $sub_hash = $submenus->{$sub_item};
            if (! $sub_hash->{'enabled'}) {
                next;
            }
            if (check_menu_permission($sub_hash, $disable_submenu_check)) {
                return 1;
            }
        }
    }
    return 0;
}

sub check_menu_permission($;$;$) {
    my $hash = shift;
    my $disable_submenu_check = shift;
    my $forced_link = shift;
    my $link;
    if ($forced_link) {
        $link = $forced_link;
    } else {
        $link = getlink($hash, 1);
    }

    if (! is_menu_visible($link)) {
        return 0;
    }
    if ($has_gui_profile) {
        my $b = 0;
        # black list
        foreach my $glob (@black_list) {
            if (($glob =~ /\/\*$/ && match_glob(substr($glob, 0, -2), $link)) || (match_glob($glob, $link))) {
                $b = 1;
                break;
            }
        }
        if (($b == 1) && check_sub_menu_permission($hash, $disable_submenu_check)) {
            $b = 0; # one sub menu is enabled, re-enable the item
        }
        if ($b) {
            return 0;
        }
        # white list
        if ((length @white_list != 0) && (@white_list != '')) {
            my $m = 0;
            foreach my $glob (@white_list) {
                if (($glob =~ /\/\*$/ && match_glob(substr($glob, 0, -2), $link)) || (match_glob($glob, $link))) {
                    $m = 1;
                    break;
                }
            }
            if (!$m && check_sub_menu_permission($hash, 1)) {
                $m1 = 1; # one sub menu is enabled, re-enable the item
            }
            if (! $m) {
                return 0;
            }
        }
    }
    return 1;
}

sub showsubsection($$) {
    my $root = shift;
    my $id = shift;
    if ($id eq '') {
        $id = 'menu-left';
        printf <<EOF
<script language="javascript" type="text/javascript">
\$(document).ready(function() {
    \$("#menu-left").stalker({offset: 35});
});
</script>
EOF
        ;
    }
    if (! $root) {
        print '<div style="width: 85px;"></div>';
        return;
    }
    my $selected = getselected($root);
    if (! $selected) {
        print '<div style="width: 85px;"></div>';
        return;
    }
    my $submenus = $selected->{'subMenu'};
    if (! $submenus) {
        print '<div style="width: 85px;"></div>';
        return;
    }
    printf <<EOF
    <div id="$id">
        <ul>
EOF
;
    foreach my $item (sort keys %$submenus) {
        my $hash = $submenus->{$item};
        if (! $hash->{'enabled'}) {
            next;
        }
        my $link = getlink($hash);
        if ($link eq '') {
            next;
        }
        if (! check_menu_permission($menu->{$k1}, 0, $link)) {
            next;
        }
        my $caption = $hash->{'caption'};
        if ($hash->{'selected'}) {
            print '<li class="selected">';
            print "<a href=\"$link\">$caption</a></li>";
        } else {
            print '<li>';
            print "<a href=\"$link\">$caption</a></li>";
        }
    }
    printf <<EOF
        </ul>
    </div>
EOF
    ;
}

sub showsubsubsection {
    my $root = shift;
    my $submenutitle = shift;
        
    if (!$root) {
        print "<div>";
        return;
    }
    my $selected = getselected($root);
    if (! $selected) {
        print "<div>";
        return;
    }
    
    if (! $selected->{'subMenu'}) {
        print "<div>";
        return;
    }
    
    my $subSelected = getselected($selected->{'subMenu'});
    if (! $subSelected) {
        print "<div>";
        return;
    }
    my $subsubmenus = $subSelected->{'subMenu'};
    if (! $subsubmenus) {
        print "<div>";
        return;
    }
	showsubsection($selected->{'subMenu'}, 'menu-subtop');
	print "<div id=\"page-content-box\">";
}


sub get_helpuri_recursive($) {
    my $root = shift;

    if (! $root) {
	return '';
    }
    foreach my $item (sort keys %$root) {
	my $val = $root->{$item};
	if (compare_url($val)) {
	    $val->{'selected'} = 1;
	    if ($val->{'helpuri'} !~ /^$/) {
		return $val->{'helpuri'};
	    }
	    return '';
	}

	my $helpuri = get_helpuri_recursive($val->{'subMenu'});
	if ($helpuri ne '') {
	    $val->{'selected'} = 1;
	    return $helpuri;
	}
    }
    return '';
}

sub get_helpuri($) {
    my $root = shift;
    
    # Retrieve product settings
    my %productsettings = ();
    &readhash("/razwall/config/product/settings", \%productsettings);
    
    # Retrieve brand settings
    my %brandsettings = ();
    &get_brand_settings(\%brandsettings);
    
    my $uri = get_helpuri_recursive($root);
    # Retrieve docs URL from custom.conf for custom branding
    my $rooturi = "http://docs.endian.com/%(PRODUCT_MAJOR_VERSION)s/%(LANGUAGE)s/";
    if($productsettings{'DOCUMENTATION_URL'} ne '') {
        $rooturi = $productsettings{'DOCUMENTATION_URL'} . '/';
        # replace efw. for branding
        $uri =~ s/efw.//g
    } elsif($brandsettings{'DOCS_URL'} ne '') {
        $rooturi = $brandsettings{'DOCS_URL'} . '/';
        # replace efw. for branding
        $uri =~ s/efw.//g
    }
    
    my $version = get_product_version();
    $rooturi =~ s/\%\(VERSION\)s/$version/g;
    my $product_major_version = get_product_major_version();
    $rooturi =~ s/\%\(PRODUCT_MAJOR_VERSION\)s/$product_major_version/g;
    my $doc_type = get_documentation_type();
    $rooturi =~ s/\%\(DOCUMENTATION_TYPE\)s/$doc_type/g;
    $rooturi =~ s/\%\(LANGUAGE\)s/$language/g;
    
    return $uri if ($uri =~ /^http:/);
    return $uri if ($uri =~ /^https:/);
    return $uri if ($uri =~ /^\//);
    return $rooturi.$uri;
}

sub jsonifyMenu($) {
    my $menu = shift;
    # $menu *is* utf-8 encoded, don't ask why json
    # needs it as latin1. I don't know.
    # It's however necessary to use the latin1 encoder
    # otherwise it will be encoded as utf-8 twice.
    return JSON::XS->new->latin1->encode($menu);
}

sub menu_to_json {
    print jsonifyMenu($menu);
}

sub openpage {
    my $title = shift;
    my $boh = shift;
    my $extrahead = shift;
	my $submenutitle = shift;

    &readhash("${swroot}/main/settings", \%settings);
    if(!($nomenu == 1)) {
        &genmenu();
    }
    my $h2 = gettitle($menu);
    my $helpuri = get_helpuri($menu);

    $title = $brand.' '.$product." - $title";
    if ($settings{'WINDOWWITHHOSTNAME'} eq 'on') {
        $title =  "$settings{'HOSTNAME'}.$settings{'DOMAINNAME'} - $title"; 
    }

    printf <<END
<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <title>$title</title>
        <link rel="shortcut icon" href="/favicon.ico" />
        <style type="text/css">\@import url(/include/style.css);</style>
        <style type="text/css">\@import url(/include/menu.css);</style>
        <style type="text/css">\@import url(/include/content.css);</style>
        <style type="text/css">\@import url(/include/service-notifications.css);</style>
        <style type="text/css">\@import url(/include/updates.css);</style>
END
;
if (-e "/home/httpd/html/include/branding.css" ) {
    print '<style type="text/css">@import url(/include/branding.css);</style>';
}
printf <<END
        <script language="JavaScript" type="text/javascript" src="/include/overlib_mini.js"></script>
        <script language="javascript" type="text/javascript" src="/include/jquery.min.js"></script>
        <script language="javascript" type="text/javascript" src="/include/jquery.ifixpng.js"></script>
        <script language="javascript" type="text/javascript" src="/include/jquery.selectboxes.js"></script>
        <script language="javascript" type="text/javascript" src="/include/form.js"></script>
        <!-- Include Service Notification API -->
        <script language="javascript" type="text/javascript" src="/include/servicesubscriber.js"></script>
		<!--
#raw
		-->
        <script language="javascript" type="text/javascript" src="/include/jquery.stalker.js"></script>
        <script language="javascript" type="text/javascript">
            \$(document).ready(function() {
                try {
                    \$.ifixpng('/images/clear.gif');
                    \$('img').ifixpng();
                    \$('input').ifixpng();
                }
                catch(e) {
                    
                }
            });
        </script>
      	<!--
#end raw
		-->
        $extrahead
    
        <script type="text/javascript">
            overlib_pagedefaults(WIDTH,300,FGCOLOR,'#ffffcc',BGCOLOR,'#666666');
            function swapVisibility(id) {
                el = document.getElementById(id);
                if(el.style.display != 'block') {
                    el.style.display = 'block'
                }
                else {
                    el.style.display = 'none'
                }
            }
        </script>
        <script type="text/javascript" src="/include/accordion.js"></script>
END
;
    if($ENV{'SCRIPT_NAME'} eq '/cgi-bin/main.cgi' && -e '/home/httpd/html/include/uplink.js') {
        printf <<END
            <script language="javascript" type="text/javascript" src="/include/uplink.js"></script>
            <link rel="stylesheet" type="text/css" media="screen" title="Uplinks Status" href="/include/uplinks-status.css" />
END
;
    }
    if($ENV{'SCRIPT_NAME'} eq '/cgi-bin/uplinkeditor.cgi') {
        printf <<END
            <script language="javascript" type="text/javascript" src="/include/uplinkeditor.js"></script>
END
;
    }
    if ($ENV{'SCRIPT_NAME'} eq '/cgi-bin/updates.cgi' && -e '/home/httpd/html/include/ajax.js'  && -e '/home/httpd/cgi-bin/updates-ajax.cgi'
        && -e '/home/httpd/html/include/updates.js' && -e'/home/httpd/html/include/updates.css') {
      printf <<END
        <script type="text/javascript" language="JavaScript" src="/include/ajax.js"></script>
        <script type="text/javascript" language="JavaScript" src="/include/updates.js"></script>
    </head>
    <body>
END
;
    } else {
      printf <<END
      </head>
      <body>
END
;
    }
    printf <<END
<!-- EFW HEADER -->

<div id="background">
    <div id="background-overlay"></div>
</div>
<div id="header-background"></div>
<div id="header">
END
;

$image_custom = </home/httpd/html/images/product_*.custom.png>;
$image_vendor = </home/httpd/html/images/product_*.vendor.png>;
$image_orig = </home/httpd/html/images/product_*.png>;

$logo_custom = </home/httpd/html/images/logo_*.custom.png>;
$logo_vendor = </home/httpd/html/images/logo_*.vendor.png>;
$logo_orig = </home/httpd/html/images/logo_*.png>;
    
if ( $logo_custom ) {
    $logo_path = $logo_custom;
} elsif ( $logo_vendor ) {
    $logo_path = $logo_vendor;
} else {
    $logo_path = $logo_orig;
}
if ( $logo_path ) {
    $filename=substr($logo_path,24);
    print "     <img id=\"logo\" src=\"/images/$filename\" alt=\"Logo\" />";
};

if ( $image_custom ) {
    $image_path	= $image_custom;
} elsif	( $image_vendor ) {
    $image_path	= $image_vendor;
} elsif	( $image_orig )	{
    $image_path	= $image_orig;
}

if ( $image_path ) {
    $filename=substr($image_path,24);
    print "     <img id=\"logo-product\" src=\"/images/$filename\" alt=\"Product Logo\" />";
};

printf <<END
	<div id="header-icons">
<ul>
    <li id="logout-icon" onclick="window.location.href='/cgi-bin/logout.cgi';">
        <a href="#" onclick="return false;">%s</a>
    </li>
    <li id="help-icon" onclick="javascript:window.open('$helpuri','_blank','height=700,width=1000,location=no,menubar=no,scrollbars=yes');">
        <a href="#" onclick="return false;">%s</a>
    </li>
</ul>
<script language="javascript" type="text/javascript">
\$(document).ready(function() {
	if (\$.browser.msie) {
		\$("#main_header_logout").removeAttr("href");
		\$("#main_header_logout").parent().unbind('click').click(function() {
			\$.ajax({
				url: "/cgi-bin/logout.cgi",
				username: 'username',
				password: 'wrong_password_for_username'
			});
		document.location = "/";
		});
	}
});
</script>
END
,
_("Logout"),
_("Help")
;
printf <<END
   </div><!-- header-icons -->
   </div><!-- header -->
END
;

    &showmenu();

printf <<END
<div id="content">
END
;
	
    &showsubsection($menu); # second level menu

    printf <<END
        <div id="page-content">
            <h2>$h2</h2>
END
    ;
    
    &showsubsubsection($menu,$submenutitle);
#    eval {
#	require 'endian-network.pl';
#	$supported = check_support();
#	warn_unsupported($supported);
#    };
if ( -e '/var/tmp/oldkernel' && $ENV{'SCRIPT_NAME'} eq '/cgi-bin/main.cgi') {
    printf <<END                                                                                                                                                                
    <h3 class="warning">%s</h3>                                                                                                                                                 
    <table class="list"><tr><td align="center"><img src="/images/dialog-warning.png"/></td><td align="left">%s</td></tr></table>                                                
    <br/>                                                                                                                                                                       
END
,                                                                                                                                                                           
_('Old kernel'),
_('You are not running the latest kernel version. If your Firewall has been updated this could mean that a new kernel has been installed. To activate it you will have to <a href="%s">reboot</a> the system.<br/>If this is not the case you should check your %s file and make sure that the newest kernel will be booted after a restart.',"/cgi-bin/shutdown.cgi","/boot/grub/grub.conf")
;                 
}
    # Add HTML required to display notifications posted from service(s)
    printf <<END
        <div id="notification-view" class="spinner" style="display:none"></div>
END
;

    printf <<END
        <div id="module-content">
END
;
}

sub closepage () {
    print <<END
              </div>
              </div>
              <br />
              <div id="footer">
END
;
    if (!($nostatus == 1)) {
        my $status = &connectionstatus();
        $uptime = `/usr/bin/uptime`;
        print '<div style="font-size: 9px"><b>Status:</b> '.$status.' <b>Uptime:</b>'.$uptime.'</div>';
    }
	if (!is_branded()) {
	    print "<p>".$version." (c) ".'<a href="http://www.endian.com">Endian</a><span style="font-size: 7px"></span></p>';
	} else {
	    print "<p>".$version." (c) ".get_company().'<span style="font-size: 7px"></span></p>';
	}    
print <<END
              </div>
            </div>
            <div class="cb"></div>
          </div><!-- page_content -->
        </div><!-- content -->
  </body>
</html>
END
;
&handleinput();
}

sub handleinput () {
    if ($ENV{'CONTENT_LENGTH'}) {
        while (<STDIN>){}
    };
}

sub openbigbox($$$) {
    my $error=shift;
    my $warning=shift;
    my $note=shift;

    errorbox($error);
    warnbox($warning);
    notificationbox($note);
}

sub closebigbox {
    return;
}

sub openbox
{
    # this is deprecated use get_accordion_template instead
    
    $width = $_[0];
    $align = $_[1];
    $caption = $_[2];
    $id = $_[3];
    
    my %params = (
        V_ACCORDION => [
            {
                T_TITLE => $caption,
                V_START_ONLY => 1
            },
        ]
    );
    
    print get_accordion_widget(\%params);
}

sub closebox
{
    # this is deprecated use get_accordion_template instead
    
    my %params = (
        V_ACCORDION => [
            {
                V_END_ONLY => 1
            },
        ]
    );
    
    print get_accordion_widget(\%params);
}

sub openeditorbox($$$$@)
{
    my $linktext = shift;
    my $title = shift;
    my $show = shift;
    my $linkname = shift;
    my @errormessages = @_;
    #my @errormessages = $errormessages;
    my $disp_editor = "hidden";
    my $disp_link = "";
    if ($show eq "showeditor" || $#errormessages ne -1) {
        $disp_link = "hidden";
        $disp_editor = "";
    }
    
    if ($linktext ne "") {
        printf <<EOF
    <div class="editoradd $disp_link" id="$linkname" name="$linkname">
        <div><a class="editoradd" name="$linkname" href="#$linkname">$linktext</a></div>
    </div>
EOF
        ;
    }
    printf <<EOF
    <div class="editorbox $disp_editor" name="$linkname">
EOF
;
    if($title ne '') {
        printf <<EOF
        <div class="editortitle"><b>$title</b></div>
EOF
        ;
    }
    if ($#errormessages ne -1) {
        printf <<EOF
        <div class="editorerror" name="$linkname">
            <div>
                <ul style="padding-left: 20px">
EOF
        ;
        foreach my $errormessage (@errormessages) {
            printf <<EOF
                    <li style="color: red;">
                        <font color="red">$errormessage</font>
                    </li>
EOF
            ;
        }
        printf <<EOF
                </ul>
            </div>
            <hr size="1" color="#cccccc">
        </div>
EOF
        ;
    }
    printf <<EOF
        <form enctype='multipart/form-data' method='post' action='$ENV{SCRIPT_NAME}#$linkname'>
EOF
    ;
}

sub closeeditorbox
{
    my $submitvalue = shift;
    my $cancelvalue = shift;
    my $submitname = shift;
    my $cancelname = shift;
    my $cancellink = shift;
    my $legend = shift;
    
    if ($cancellink eq "") {
        $cancellink = "#$cancelname"
    }
        
    printf <<EOF
            <div class="editorsubmit">
                <div style="float: left;"><input class='submitbutton' type='submit' name='$submitname' value='$submitvalue' />&nbsp;%s&nbsp;<a class="editorcancel" name='$cancelname' href="$cancellink">$cancelvalue</a></div>
                <div style="float: right; padding-top: 4px;">* %s $legend</div>
                <br class="cb"/>
            </div>
        </form>
        <input type="hidden" class="form" name="color" value="" />
    </div>    
EOF
    ,
    _("or"),
    _("This Field is required.")
    ;
}

sub log
{
	my $logmessage = $_[0];
	$logmessage =~ /([\w\W]*)/;
	$logmessage = $1;
	if (is_branded()){
	    system('/usr/bin/logger', '-t', "$brand", $logmessage)
	} else {
    	system('/usr/bin/logger', '-t', 'efw', $logmessage);
	}
}

sub age
{
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
	        $atime, $mtime, $ctime, $blksize, $blocks) = stat $_[0];
	my $now = time;

	my $totalsecs = $now - $mtime;
	my $days = int($totalsecs / 86400);
	my $totalhours = int($totalsecs / 3600);
	my $hours = $totalhours % 24;
	my $totalmins = int($totalsecs / 60);
	my $mins = $totalmins % 60;
	my $secs = $totalsecs % 60;

 	return "${days}d ${hours}h ${mins}m ${secs}s";
}

sub validip
{
	my $ip = $_[0];

	if (!($ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/)) {
		return 0; }
	else 
	{
		@octets = ($1, $2, $3, $4);
		foreach $_ (@octets)
		{
			if (/^0./) {
				return 0; }
			if ($_ < 0 || $_ > 255) {
				return 0; }
		}
		return 1;
	}
}

sub validmask
{
	my $mask = $_[0];
	# secord part an ip?
	if (&validip($mask)) {
		return 1; }
	# second part a number?
	if (/^0/) {
		return 0; }
	if (!($mask =~ /^\d+$/)) {
		return 0; }
	if ($mask >= 0 && $mask <= 32) {
		return 1; }
	return 0;
}

sub validipormask
{
	my $ipormask = $_[0];

	# see if it is a IP only.
	if (&validip($ipormask)) {
		return 1; }
	# split it into number and mask.
	if (!($ipormask =~ /^(.*?)\/(.*?)$/)) {
		return 0; }
	$ip = $1;
	$mask = $2;
	# first part not a ip?
	if (!(&validip($ip))) { return 0; }
	return &validmask($mask);
}

sub validipandmask
{
	my $ipandmask = $_[0];

	# split it into number and mask.
	if (!($ipandmask =~ /^(.*?)\/(.*?)$/)) {
		return 0; }
	$ip = $1;
	$mask = $2;
	# first part not a ip?
	if (!(&validip($ip))) {
		return 0; }
	return &validmask($mask);
}

sub validport
{
	$_ = $_[0];

	if (!/^\d+$/) {
		return 0; }
	if (/^0./) {
		return 0; }
	if ($_ >= 1 && $_ <= 65535) {
		return 1; }
	return 0;
}

sub is_ipaddress($) {
    my $addr = shift;
    if ($addr !~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?:\/(\d{1,2}))?$/) {
	return 0;
    }

    my @parts = {$1, $2, $3, $4};
    my $cidr = '';
    if ($5) {
	$cidr = $5;
    }
    foreach my $number (@parts) {
	$number = s/\D//;
	if (($number < 0) || ($number > 255)) {
	    return 0;
	}
    }
    if ($cidr ne '') {
	if (($cidr < 0) || ($cidr > 32)) {
	    return 0;
	}
    }

    return 1;
}

sub validmac($) {
    my $addr = shift;
    if ($addr !~ /^([\dA-F]{2}):([\dA-F]{2}):([\dA-F]{2}):([\dA-F]{2}):([\dA-F]{2}):([\dA-F]{2})$/i) {
	return 0;
    }
    return 1;
}

sub validhostname
{
	# Checks a hostname against RFC1035
        my $hostname = $_[0];

	# Each part should be at least two characters in length
	# but no more than 63 characters
	if (length ($hostname) < 2 || length ($hostname) > 63) {
		return 0;}
	# Only valid characters are a-z, A-Z, 0-9 and -
	if ($hostname !~ /^[a-zA-Z0-9-]*$/) {
		return 0;}
	# First character can only be a letter or a digit
	if (substr ($hostname, 0, 1) !~ /^[a-zA-Z0-9]*$/) {
		return 0;}
	# Last character can only be a letter or a digit
	if (substr ($hostname, -1, 1) !~ /^[a-zA-Z0-9]*$/) {
		return 0;}
	return 1;
}

sub validdomainname
{
	# Checks a domain name against RFC1035
        my $domainname = $_[0];
	my @parts = split (/\./, $domainname);	# Split hostname at the '.'

	foreach $part (@parts) {
		# Each part should be at least one characters in length
		# but no more than 63 characters
		if (length ($part) < 1 || length ($part) > 63) {
			return 0;}
		# Only valid characters are a-z, A-Z, 0-9 and -
		if ($part !~ /^[a-zA-Z0-9-]*$/) {
			return 0;}
		# First character can only be a letter or a digit
		if (substr ($part, 0, 1) !~ /^[a-zA-Z0-9]*$/) {
			return 0;}
		# Last character can only be a letter or a digit
		if (substr ($part, -1, 1) !~ /^[a-zA-Z0-9]*$/) {
			return 0;}
	}
	return 1;
}

sub validfqdn
{
	# Checks a fully qualified domain name against RFC1035
        my $fqdn = $_[0];
	my @parts = split (/\./, $fqdn);	# Split hostname at the '.'
	if (scalar(@parts) < 2) {		# At least two parts should
		return 0;}			# exist in a FQDN
						# (i.e. hostname.domain)
	foreach $part (@parts) {
		# Each part should be at least 1 characters in length
		# but no more than 63 characters
		if (length ($part) < 1 || length ($part) > 63) {
			return 0;}
		# Only valid characters are a-z, A-Z, 0-9 and -
		if ($part !~ /^[a-zA-Z0-9-]*$/) {
			return 0;}
		# First character can only be a letter or a digit
		if (substr ($part, 0, 1) !~ /^[a-zA-Z0-9]*$/) {
			return 0;}
		# Last character can only be a letter or a digit
		if (substr ($part, -1, 1) !~ /^[a-zA-Z0-9]*$/) {
			return 0;}
	}
	return 1;
}

sub validportrange # used to check a port range 
{
	my $port = $_[0]; # port values
	$port =~ tr/-/:/; # replace all - with colons just in case someone used -
	my $srcdst = $_[1]; # is it a source or destination port

	if (!($port =~ /^(\d+)\:(\d+)$/)) {
	
		if (!(&validport($port))) {	 
			if ($srcdst eq 'src'){
				return _('Source port must be a valid port number or port range.');
			} else 	{
				return _('Destination port must be a valid port number or port range.');
			} 
		}
	}
	else 
	{
		@ports = ($1, $2);
		if ($1 >= $2){
			if ($srcdst eq 'src'){
				return _('The Source port range has a first value that is greater than or equal to the second value.');
			} else 	{
				return _('The destination port range has a first value that is greater than or equal to the second value.');
			} 
		}
		foreach $_ (@ports)
		{
			if (!(&validport($_))) {
				if ($srcdst eq 'src'){
					return _('Source port must be a valid port number or port range.'); 
				} else 	{
					return _('Destination port must be a valid port number or port range.');
				} 
			}
		}
		return;
	}
}

# Test if IP is within a subnet
# Call: IpInSubnet (Addr, Subnet, Subnet Mask)
#       Subnet can be an IP of the subnet: 10.0.0.0 or 10.0.0.1
#       Everything in dottted notation
# Return: TRUE/FALSE
sub IpInSubnet
{
    $ip = unpack('N', inet_aton(shift));
    $start = unpack('N', inet_aton(shift));
    $mask  = unpack('N', inet_aton(shift));
    $start &= $mask;  # base of subnet...
    $end   = $start + ~$mask;
    return (($ip >= $start) && ($ip <= $end));
}

sub validemail {
    my $mail = shift;
    return 0 if ( $mail !~ /^[0-9a-zA-Z\.\-\_]+\@[0-9a-zA-Z\.\-]+$/ );
    return 0 if ( $mail =~ /^[^0-9a-zA-Z]|[^0-9a-zA-Z]$/);
    return 0 if ( $mail !~ /([0-9a-zA-Z]{1})\@./ );
    return 0 if ( $mail !~ /.\@([0-9a-zA-Z]{1})/ );
    return 0 if ( $mail =~ /.\.\-.|.\-\..|.\.\..|.\-\-./g );
    return 0 if ( $mail =~ /.\.\_.|.\-\_.|.\_\..|.\_\-.|.\_\_./g );
    return 0 if ( $mail !~ /\.([a-zA-Z]{2,})$/ );
    return 1;
}

sub readhasharray {
    my ($filename, $hash) = @_;

    open(FILE, $filename) or die _('Unable to read file %s', $filename);

    while (<FILE>) {
	my ($key, $rest, @temp);
	chomp;
	($key, $rest) = split (/,/, $_, 2);
	if ($key =~ /^[0-9]+$/ && $rest) {
	    @temp = split (/,/, $rest);
	    $hash->{$key} = \@temp;
        }
    }
    close FILE;
    return;
}

sub writehasharray {
    my ($filename, $hash) = @_;
    my ($key, @temp);

    open(FILE, ">$filename") or die "Unable to write to file $filename";

    foreach $key (keys %$hash) {
	if ( $hash->{$key} ) {
	    print FILE "$key";
	    foreach $i (0 .. $#{$hash->{$key}}) {
		print FILE ",$hash->{$key}[$i]";
	    }
	}
	print FILE "\n";
    }
    close FILE;
    return;
}

sub findhasharraykey {
    foreach my $i (1 .. 1000000) {
	if ( ! exists $_[0]{$i}) {
	     return $i;
	}
    }
}

sub cleanhtml
{
	my $outstring =$_[0];
	$outstring =~ tr/,/ / if not defined $_[1] or $_[1] ne 'y';
	$outstring =~ s/&/&amp;/g;
	$outstring =~ s/\'/&#039;/g;
	$outstring =~ s/\"/&quot;/g;
	$outstring =~ s/</&lt;/g;
	$outstring =~ s/>/&gt;/g;
	return $outstring;
}
sub connectionstatus
{
        my $status;
        opendir UPLINKS, "/razwall/config/uplinks" or die "Cannot read uplinks: $!";
                foreach my $uplink (sort grep !/^\./, readdir UPLINKS) {
                    if ( -f "${swroot}/uplinks/${uplink}/active") {
                        if ( ! $status ) {
                                $timestr = &age("${swroot}/uplinks/${uplink}/active");
                                $status = _('Connected').": $uplink (<span class='ipcop_StatusBigRed'>$timestr</span>) ";
                        } else {
                                $timestr = &age("${swroot}/uplinks/${uplink}/active");
                                $status = "$status , $uplink (<span class='ipcop_StatusBigRed'>$timestr</span>) ";
                        }
                    } elsif ( -f "${swroot}/uplinks/${uplink}/connecting") {
                        if ( ! $status ) {
                                $status = _('Connecting...')." $uplink";
                        } else {
                                $status = "$status , "._('Connecting...')." $uplink (<span class='ipcop_StatusBigRed'>$timestr</span>) ";
                        }
                    }
                    $lines++;
                }
                closedir(UPLINKS);
                if ( ! $status ) {
                        $status = _('Idle');
                }
                $connstate = "<span class='ipcop_StatusBig'>$status</span>";
    return $connstate;
}

sub srtarray 
# Darren Critchley - darrenc@telus.net - (c) 2003
# &srtarray(SortOrder, AlphaNumeric, SortDirection, ArrayToBeSorted)
# This subroutine will take the following parameters:
#   ColumnNumber = the column which you want to sort on, starts at 1
#   AlphaNumberic = a or n (lowercase) defines whether the sort should be alpha or numberic
#   SortDirection = asc or dsc (lowercase) Ascending or Descending sort
#   ArrayToBeSorted = the array that wants sorting
#
#   Returns an array that is sorted to your specs
#
#   If SortOrder is greater than the elements in array, then it defaults to the first element
# 
{
	my ($colno, $alpnum, $srtdir, @tobesorted) = @_;
	my @tmparray;
	my @srtedarray;
	my $line;
	my $newline;
	my $ttlitems = scalar @tobesorted; # want to know the number of rows in the passed array
	if ($ttlitems < 1){ # if no items, don't waste our time lets leave
		return (@tobesorted);
	}
	my @tmp = split(/\,/,$tobesorted[0]);
	$ttlitems = scalar @tmp; # this should be the number of elements in each row of the passed in array

	# Darren Critchley - validate parameters
	if ($colno > $ttlitems){$colno = '1';}
	$colno--; # remove one from colno to deal with arrays starting at 0
	if($colno < 0){$colno = '0';}
	if ($alpnum ne '') { $alpnum = lc($alpnum); } else { $alpnum = 'a'; }
	if ($srtdir ne '') { $srtdir = lc($srtdir); } else { $srtdir = 'src'; }

	foreach $line (@tobesorted)
	{
		chomp($line);
		if ($line ne '') {
			my @temp = split(/\,/,$line);
			# Darren Critchley - juggle the fields so that the one we want to sort on is first
			my $tmpholder = $temp[0];
			$temp[0] = $temp[$colno];
			$temp[$colno] = $tmpholder;
			$newline = "";
			for ($ctr=0; $ctr < $ttlitems ; $ctr++) {
				$newline=$newline . $temp[$ctr] . ",";
			}
			chomp($newline);
			push(@tmparray,$newline);
		}
	}
	if ($alpnum eq 'n') {
		@tmparray = sort {$a <=> $b} @tmparray;
	} else {
		@tmparray = (sort @tmparray);
	}
	foreach $line (@tmparray)
	{
		chomp($line);
		if ($line ne '') {
			my @temp = split(/\,/,$line);
			my $tmpholder = $temp[0];
			$temp[0] = $temp[$colno];
			$temp[$colno] = $tmpholder;
			$newline = "";
			for ($ctr=0; $ctr < $ttlitems ; $ctr++){
				$newline=$newline . $temp[$ctr] . ",";
			}
			chomp($newline);
			push(@srtedarray,$newline);
		}
	}

	if ($srtdir eq 'dsc') {
		@tmparray = reverse(@srtedarray);
		return (@tmparray);
	} else {
		return (@srtedarray);
	}
}

sub speedtouchversion
{
	if (-f "/proc/bus/usb/devices")
	{
		$speedtouch=`/bin/cat /proc/bus/usb/devices | /bin/grep 'Vendor=06b9 ProdID=4061' | /usr/bin/cut -d ' ' -f6`;
		if ($speedtouch eq '') {
			$speedtouch= _('Connect the modem');
		}
	} else {
		$speedtouch='USB '._('not running');
	}
	return $speedtouch
}

sub CheckSortOrder {
#Sorting of allocated leases
    if ($ENV{'QUERY_STRING'} =~ /^IPADDR|^ETHER|^HOSTNAME|^ENDTIME/ ) {
	my $newsort=$ENV{'QUERY_STRING'};
        &readhash("${swroot}/dhcp/settings", \%dhcpsettings);
        $act=$dhcpsettings{'SORT_LEASELIST'};
        #Reverse actual ?
        if ($act =~ $newsort) {
            if ($act !~ 'Rev') {$Rev='Rev'};
            $newsort.=$Rev
        };

        $dhcpsettings{'SORT_LEASELIST'}=$newsort;
	&writehash("${swroot}/dhcp/settings", \%dhcpsettings);
        $dhcpsettings{'ACTION'} = 'SORT';  # avoid the next test "First lauch"
    }

}

sub PrintActualLeases
{
    &openbox('100%', 'left', _('Current dynamic leases'));
    printf <<END
<table width='100%'>
<tr>
<td width='5%'><b>#</b></td>
<td width='25%' align='center'><a href='$ENV{'SCRIPT_NAME'}?IPADDR'><b>%s</b></a></td>
<td width='25%' align='center'><a href='$ENV{'SCRIPT_NAME'}?ETHER'><b>%s</b></a></td>
<td width='20%' align='center'><a href='$ENV{'SCRIPT_NAME'}?HOSTNAME'><b>%s</b></a></td>
<td width='25%' align='center'><a href='$ENV{'SCRIPT_NAME'}?ENDTIME'><b>%s (local time d/m/y)</b></a></td>
</tr>
END
,
_('IP address'),
_('MAC address'),
_('Hostname'),
_('Lease expires')
;

    open(LEASES,"/var/lib/dhcp/dhcpd.leases") or die "Can't open dhcpd.leases";
    while ($line = <LEASES>) {
	next if( $line =~ /^\s*#/ );
	chomp($line);
	@temp = split (' ', $line);

	if ($line =~ /^\s*lease/) {
	    $ip = $temp[1];
	    #All field are not necessarily read. Clear everything
	    $endtime = 0;
	    $ether = "";
	    $hostname = "";
	}

	if ($line =~ /^\s*ends/) {
	    $line =~ /(\d+)\/(\d+)\/(\d+) (\d+):(\d+):(\d+)/;
	    $endtime = timegm($6, $5, $4, $3, $2 - 1, $1 - 1900);
	}

	if ($line =~ /^\s*hardware ethernet/) {
	    $ether = $temp[2];
	    $ether =~ s/;//g;
	}

	if ($line =~ /^\s*client-hostname/) {
	    $hostname = "$temp[1] $temp[2] $temp[3]";
	    $hostname =~ s/;//g;
	    $hostname =~ s/\"//g;
	}

	if ($line eq "}") {
	    @record = ('IPADDR',$ip,'ENDTIME',$endtime,'ETHER',$ether,'HOSTNAME',$hostname);
    	    $record = {};                        		# create a reference to empty hash
	    %{$record} = @record;                		# populate that hash with @record
	    $entries{$record->{'IPADDR'}} = $record;   	# add this to a hash of hashes
	}
    }
    close(LEASES);

    my $id = 1;
    foreach my $key (sort leasesort keys %entries) {

	my $hostname = &cleanhtml($entries{$key}->{HOSTNAME},"y");

	if ($id % 2) {
	    print "<tr class='even'>"; 
	}
	else {
	    print "<tr class='odd'>"; 
	}

	printf <<END
<td>$id</td>
<td align='center'>$entries{$key}->{IPADDR}</td>
<td align='center'>$entries{$key}->{ETHER}</td>
<td align='center'>&nbsp;$hostname </td>
<td align='center'>
END
	;

	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst) = localtime ($entries{$key}->{ENDTIME});
	$enddate = sprintf ("%02d/%02d/%d %02d:%02d:%02d",$mday,$mon+1,$year+1900,$hour,$min,$sec);

	if ($entries{$key}->{ENDTIME} < time() ){
	    print "<strike>$enddate</strike>";
	} else {
	    print "$enddate";
	}
	print "</td></tr>";
	$id++;
    }

    print "</table>";
    &closebox();
}


# This sub is used during display of actives leases
sub leasesort {
    if (rindex ($dhcpsettings{'SORT_LEASELIST'},'Rev') != -1)
    {
        $qs=substr ($dhcpsettings{'SORT_LEASELIST'},0,length($dhcpsettings{'SORT_LEASELIST'})-3);
        if ($qs eq 'IPADDR') {
            @a = split(/\./,$entries{$a}->{$qs});
            @b = split(/\./,$entries{$b}->{$qs});
            ($b[0]<=>$a[0]) ||
            ($b[1]<=>$a[1]) ||
            ($b[2]<=>$a[2]) ||
            ($b[3]<=>$a[3]);
        }else {
            $entries{$b}->{$qs} cmp $entries{$a}->{$qs};
        }
    }
    else #not reverse
    {
        $qs=$dhcpsettings{'SORT_LEASELIST'};
        if ($qs eq 'IPADDR') {
	    @a = split(/\./,$entries{$a}->{$qs});
    	    @b = split(/\./,$entries{$b}->{$qs});
    	    ($a[0]<=>$b[0]) ||
	    ($a[1]<=>$b[1]) ||
	    ($a[2]<=>$b[2]) ||
    	    ($a[3]<=>$b[3]);
	}else {
    	    $entries{$a}->{$qs} cmp $entries{$b}->{$qs};
	}
    }
}

sub get_uplinks() {
    my @uplinks = ();
    opendir(DIR, "${swroot}/uplinks/") || return \@uplinks;
    foreach my $dir (readdir(DIR)) {
	    next if ($dir =~ /^\./);
        next if (!(-f "${swroot}/uplinks/$dir/settings"));
	    push(@uplinks, $dir);
    }
    closedir(DIR);
    return \@uplinks;
}

sub get_uplink_info($$) {
    my $name = shift;
    my $getbackup = shift;
    my %uplink = {};
    
    # uplinks settings file
    my $uplink_dir = "${swroot}/uplinks/$name";
    my $uplink_file = "$uplink_dir/settings";
    my $uplink_data_file = "$uplink_dir/data";
    
    # if the uplink doesn't exist (has no settings file), false
    # is returned, else the settings are read.
    if (! -e $uplink_file) {
        return {};
    }
    readhash($uplink_file, \%uplink);

    $uplink{'ID'} = $name;
    
    if ($uplink{'NAME'} eq "") {
        if ($name eq "main") {
            $uplink{'NAME'} = _("Main uplink");
        }
        else {
            $uplink{'NAME'} = "ID: ".$name;
        }
    }
    
    # non connected uplinks don't have an data file,
    # hence reading that file would 'cause the script
    # to fail.
    if(-e $uplink_data_file) {
        my %data = {};
        readhash($uplink_data_file, \%data);
        $uplink{'data'} = \%data;
    }
    
    if ($uplink{'BACKUPPROFILE'} eq "main") {
        $uplink{'BACKUPPROFILENAME'} = _("Main uplink");
    }
    elsif ($uplink{'BACKUPPROFILE'} ne "" && -e "${swroot}/uplinks/$uplink{'BACKUPPROFILE'}/settings") {
        readhash("${swroot}/uplinks/$uplink{'BACKUPPROFILE'}/settings", \%backuplink);
        if ($backuplink{'NAME'} eq "") {
            $backuplink{'NAME'} = "ID: " . $name;
        }
        $uplink{'BACKUPPROFILENAME'} = $backuplink{'NAME'};
    }
    else {
        $uplink{'BACKUPPROFILE'} = "";
        $uplink{'BACKUPPROFILENAME'} = _("None");
    }
    
    return %uplink;
}

sub get_iface($) {
    my $uplink = shift;
    eval {
	    &readhash("${swroot}/uplinks/$uplink/data", \%set);
    };
    $iface = $set{'interface'};
    return $iface;
}

sub get_red_ifaces_by_type($) {
    my $type=shift;
    my @gottypeiface = ();
    my @gottypeuplink = ();
    my @gottype = ();

    my $ref=get_uplinks();
    my @uplinks=@$ref;
    my %set = ();
    foreach my $link (@uplinks) {
	eval {
	    &readhash("${swroot}/uplinks/$link/data", \%set);
	};
	push(@gottype, $link);

	my $iface = $set{'interface'};
	next if (!$iface);

	if ($set{'RED_TYPE'} eq $type) {
	    push(@gottypeiface, $iface);
	    push(@gottypeuplink, $link);
	}
    }
    return (\@gottypeiface, \@gottypeuplink, \@gottype);
}

sub get_red_ifaces() {
    my @uplinks = ();
    my @gottypeiface = ();
    opendir(DIR, "${swroot}/uplinks/") || return \@uplinks;
    foreach my $dir (readdir(DIR)) {
        next if ($dir =~ /^\./);
        next if (!(-f "${swroot}/uplinks/$dir/data"));
        &readhash("${swroot}/uplinks/$dir/data", \%set);
        push(@gottypeiface, $set{'interface'});
    }
    closedir(DIR);
    return \@gottypeiface;
}

sub get_zone_devices($) {
    my $bridge = shift;
    my @ifaces = ();
    open (FILE, "${swroot}/ethernet/$bridge") || return "";
    foreach my $line (<FILE>) {
	chomp($line);
	next if (!$line);
	push(@ifaces, $line);
    }
    close(FILE);
    return \@ifaces;
}


sub register_submenuitem($$$$) {
    my $menuitem = shift;
    my $submenuitem = shift;
    my $newitem = shift;
    my $hash = shift;

    $menu->{$menuitem}->{'subMenu'}->{$submenuitem}->{'subMenu'}->{$newitem} = $hash;
    return ($menu->{$menuitem}->{'subMenu'}->{$submenuitem}->{'subMenu'}->{$newitem} == $hash);

}

sub register_menuitem($$$) {
    my $menuitem = shift;
    my $newitem = shift;
    my $hash = shift;
    
    if ( ! $newitem ) {
        $menu->{$menuitem} = $hash;
        return ($menu->{$menuitem} == $hash);
    } 
    
    $menu->{$menuitem}->{'subMenu'}->{$newitem} = $hash;
    return ($menu->{$menuitem}->{'subMenu'}->{$newitem} == $hash);

    # sample:
    #
    # my $menuitem = {
    #                 'caption' => _('Home'),
    #                 'uri' => '/cgi-bin/index.cgi',
    #                 'title' => _('Home'),
    #                 'enabled' => 1,
    #                };
    # 
    # register_menuitem('01.system', '01.home', $menuitem);
    #
    #
    #
}

sub validzones() {
    my @ret = ();

    push(@ret, 'GREEN');
    if (orange_used()) {
	push(@ret, 'ORANGE');
    }
    if (blue_used()) {
	push(@ret, 'BLUE');
    }
    if (!is_modem()) {
	push(@ret, 'RED');
    }

    return \@ret;
}


sub get_red_devices() {
    my $ref = get_uplinks();
    my @ret = ();
    foreach my $uplink (@$ref) {
	my %config = ();
	eval {
	    &readhash("${swroot}/uplinks/$uplink/settings", \%config);
	};
	my $iface = "";
	if (($config{'RED_TYPE'} eq "STATIC") || 
	        ($config{'RED_TYPE'} eq "DHCP") || 
	        ($config{'RED_TYPE'} eq "PPPOE") || 
	        ($config{'RED_TYPE'} eq "PPTP")) {
	    $iface = $config{'RED_DEV'};
	}
	next if ($iface =~ /^$/);
	push(@ret, $iface);
    }
    return \@ret;
}

sub get_uplink_by_device($) {
    my $device = shift;
    my $ref = get_uplinks();
    my @ret = ();
    foreach my $uplink (@$ref) {
	my %config = ();
	eval {
	    &readhash("${swroot}/uplinks/$uplink/settings", \%config);
	};
	my $iface = $config{'RED_DEV'};
	push(@ret, $uplink) if ($iface eq $device);
    }
    return \@ret;
}

sub disable_uplink($) {
    my $uplink = shift;
    return 0 if (! -e "${swroot}/uplinks/$uplink/settings");
    eval {
	my %confhash;
	&readhash("${swroot}/uplinks/$uplink/settings", \%confhash);
	$confhash{'ENABLED'} = 'off';
	&writehash("${swroot}/uplinks/$uplink/settings", \%confhash);
	return 1;
    };
    return 0
}

sub setbgcolor($$$) {
    my $is_editing = shift;
    my $line = shift;
    my $i = shift;

    if ($is_editing) {
	if ($line == $i) {
	    return 'selected';
	}
    }
    if ($i % 2) {
	return 'even';
    }
    return 'odd';
}

sub value_or_nbsp($) {
    my $value = shift;
    if ($value =~ /^$/) {
	return '&nbsp;';
    }
    return $value;
}

sub get_hotspot_dev() {
    if (! -e "$HOTSPOT_ENABLED") {
	return "";
    }

    open (F, "$ethernet_dir/br2") || return "";
    my @file = <F>;
    close(F);
    my $dev = $file[0];
    chomp($dev);
    return $dev;
}

sub getzonebyinterface($) {
    my $iface = shift;
    my $zones = validzones();
    foreach my $zone (@$zones) {
        my $devices = get_zone_devices($ethsettings{$zone.'_DEV'});
        return $zone if (grep(/^$iface$/, @$devices));
    }
    my $reddev = get_red_devices();
    return 'RED' if (grep(/^$iface$/, @$reddev));
    return '';
}

sub joinbridge($$) {
    my $bridge = shift;
    my $device = shift;

    my $bridge_ifaces = get_zone_devices($bridge);
    return if (grep (/^$device$/, @$bridge_ifaces));

    my $file = "/razwall/config/ethernet/$bridge";
    if (!open(F, ">>$file")) {
        warn("Could not open '$file' because $!");
        return;
    }
    print F "$device\n";
    close(F);
}

sub removefrombridge($$) {
    my $bridge = shift;
    my $device = shift;
    my $bridge_ifaces = get_zone_devices($bridge);

    my $file = "/razwall/config/ethernet/$bridge";
    if (!open(F, ">$file")) {
        warn("Could not open '$file' because $!");
        return;
    }
    foreach my $iface (@$bridge_ifaces) {
        next if ($iface eq $device);
        print F "$iface\n";
    }
    close(F);
}

sub toggle_file($$) {
    my $file = shift;
    my $set = shift;

    if ($set) {
        `touch $file`;
        return 1;
    }
    if (-e $file) {
        unlink($file);
    }
    return 0;
}

sub applybox($) {
    my $text = shift;
    
    printf <<EOF
    <form action="$ENV{'SCRIPT_NAME'}" METHOD="post">
    <div $id class="important-fancy" style="width: 504px; $style">
        <div class="content">
            <table cellpadding="0" cellspacing="0" border="0">
                <tr>
                    <td class="sign" valign="middle"><img src="/images/bubble_green_sign.png" alt="" border="0" /></td>
                    <td class="text" valign="middle">
                        %s
                        <p style="margin-top: 5px;"> </p>
                        <input type="submit" name="save" value="%s" />
                        <input type="hidden" name="ACTION" value="apply" />
                    </td>
                </tr>
            </table>
        </div>
        <div class="bottom"><img src="/images/clear.gif" width="1" height="1" alt="" border="0" /></div>
    </div>
    </form>
EOF
, $text
, _("Apply");
}

sub errorbox($) {
    my $text = shift;
    my $id = shift;
    my $style = shift;
    if ($text =~ /^\s*$/) {
        return;
    }
    $id = ($id ne "") ? "id=\"$id\"" : "";
    
    printf <<EOF
    <div $id class="error-fancy" style="width: 504px; $style">
        <div class="content">
            <table cellpadding="0" cellspacing="0" border="0">
                <tr>
                    <td class="sign" valign="middle"><img src="/images/bubble_red_sign.png" alt="" border="0" /></td>
                    <td class="text" valign="middle">%s</td>
                </tr>
            </table>
        </div>
        <div class="bottom"><img src="/images/clear.gif" width="1" height="1" alt="" border="0" /></div>
    </div>
EOF
, $text;
}

sub warnbox($) {
    my $caption = shift;
    if ($caption =~ /^\s*$/) {
        return;
    }
    printf <<EOF, _('Warning');
<h3 class="warning">%s</h3>
<div class="warning"><img class="warning" src='/images/dialog-warning.png' alt='_("Warning")'>$caption</div>
EOF
;
}

sub notificationbox($) {
    my $text = shift;
    my $id = shift;
    my $style = shift;
    if ($text =~ /^\s*$/) {
        return;
    }
    $id = ($id ne "") ? "id=\"$id\"" : "";
    printf <<EOF
    <div $id class="notification-fancy" style="width: 504px; $style">
        <div class="content">
            <table cellpadding="0" cellspacing="0" border="0">
                <tr>
                    <td class="sign" valign="middle"><img src="/images/bubble_yellow_sign.png" alt="" border="0" /></td>
                    <td class="text" valign="middle">%s</td>
                </tr>
            </table>
        </div>
        <div class="bottom"><img src="/images/clear.gif" width="1" height="1" alt="" border="0" /></div>
    </div>
EOF
    , $text;
    ;
}

sub get_category {
    # this is deprecated use get_category_template instead
    
    my $name = shift;      # name of the marker
    my $text = shift;      # text to display
    my $checked = shift; # are all subcategories checked? (all/some/none)
    my($subcategories) = shift;
    my($status) = shift;
    
    my @subcategories = ();
    
    for my $item (keys %$subcategories) {
        my $subname = $subcategories->{$item};
        my $allowed = 0;
        if ($status->{$item} ne "") {
            $allowed = 1;
        }
        push(@subcategories, {T_TITLE => $subname, V_NAME => $item, V_ALLOWED => $allowed});
    }

    my %params = (T_TITLE => $text, V_NAME => $name, V_SUBCATEGORIES => \@subcategories, V_HIDDEN => 1);
    print get_category_widget(\%params);
}

sub get_folding {
    my $name = shift;      # name of the marker
    my $status = shift;    # start/EOF
    my $text = shift;      # text to display
    my $open = shift;      # "open" if value should be shown per default
    my $add = shift;
    
    my %params = ();
    
    if ( $status eq "start" ) {
        my $hidden = 0;
        if ($open ne "open") {
            $hidden = 1;
        }
        $params{'V_ACCORDION'} = [
                {T_TITLE => $text,
                V_NAME => $name,
                V_ADD => $add,
                V_HIDDEN => $hidden,
                V_START_ONLY => 1}
            ];

    }
    else {
        $params{'V_ACCORDION'} = [{V_END_ONLY => 1}];
    }

    return get_accordion_widget(\%params);
}

sub ipmask_to_cidr($) {
   my $addr = shift;
   if ($addr =~ /\//) {
       my ($ip,$msklen) = ipv4_parse($addr);
       return "$ip/$msklen";
   }
   return $addr;
}

sub get_taps() {
    my @ret = ();

    if (open (F, "${swroot}/openvpn/clientconfig")) {
	foreach my $line (<F>) {
	    chomp($line);
	    my @arr = split(/:/, $line);
	    next if ($arr[0] ne 'on');
	    next if ($arr[6] eq 'bridged');
	    
	    my $iface = $arr[1];
	    my $name = $arr[2];
	    chomp($iface);
	    chomp($name);
	    next if ($iface =~ /^$/);
	    next if ($name =~ /^$/);
	    my %hash = ();
	    my $ref = \%hash;
	    $ref->{'name'} = $name;
	    $ref->{'tap'} = $iface;
	    push(@ret, $ref);
	}
	close(F);
    }

    if (opendir(DIR, "${swroot}/openvpnclients")) {
	foreach my $dir (readdir(DIR)) {
	    next if ($dir =~ /^\./);
	    next if ($dir =~ /^default$/);
	    next if (! -f "${swroot}/openvpnclients/$dir/settings");
	    my %conf;
	    readhash("${swroot}/openvpnclients/$dir/settings", \%conf);
	    my $dev = $conf{'DEVICE'};
	    chomp($dev);
	    next if ($dev =~ /^$/);

	    my %hash = ();
	    my $ref = \%hash;
	    $ref->{'name'} = $dir;
	    $ref->{'tap'} = $dev;
	    $ref->{'bridged'} = 0;
	    if ($conf{'ROUTETYPE'} eq 'bridged') {
		$ref->{'bridged'} = 1;
		$ref->{'zone'} = uc($conf{'BRIDGE'});
	    }
	    if ($ref->{'zone'} eq '') {
		$ref->{'zone'} = 'GREEN';
	    }
	    push(@ret, $ref);
	}
    }
    return \@ret;
}

sub get_uplink_label($) {
    my $uplink = shift;
    my %set = ();
    eval {
	&readhash("${swroot}/uplinks/$uplink/settings", \%set);
    };
    my %hash = ();
    my $ref = \%hash;
    $ref->{'name'} = $uplink;
    $ref->{'dev'} = "UPLINK:$uplink";
    $ref->{'title'} = $set{'NAME'};
    if ($ref->{'title'}) {
	$ref->{'description'} = $uplink ." ($ref->{'title'})";
    } else {
	$ref->{'description'} = $uplink;
    }
    return $ref;
}

sub get_uplinks_list() {
    my $uplinks=get_uplinks();
    my @arr = ();
    my $ret = \@arr;
    foreach my $link (@$uplinks) {
	push(@arr, get_uplink_label($link));
    }
    return $ret;
}

sub get_aliases() {
    my $uplinks=get_uplinks();
    my @arr = ();
    my $ret = \@arr;
    foreach my $link (@$uplinks) {
	my %set = ();
	eval {
	    &readhash("${swroot}/uplinks/$link/settings", \%set);
	};
	my %hash = ();
	my $ref = \%hash;
	$ref->{'name'} = $link;
	$ref->{'value'} = "UPLINK:$link,0.0.0.0";
	$ref->{'dev'} = "UPLINK:$link";
	$ref->{'title'} = $set{'NAME'};
	push(@arr, $ref);
	my $ips = $set{'RED_IPS'};
	next if ($ips =~ /^$/);
	foreach my $addr (split(/,/, $ips)) {
	    next if ($addr =~ /^$/);
	    my ($ip,$cidr) = ipv4_parse($addr);	    
	    next if ($ip =~ /^$/);
	    my %hash = ();
	    my $ref = \%hash;
	    $ref->{'name'} = "$link - $ip";
	    $ref->{'value'} = "UPLINK:$link,$ip";
	    $ref->{'ip'} = "$ip";
	    $ref->{'dev'} = "$link";
	    push(@arr, $ref);
	}
    }
    my $taps = get_taps();
    foreach my $tap (@$taps) {
	my %hash = ();
	my $ref = \%hash;
	$ref->{'name'} = _('VPN') . ' ' . $tap->{'name'};
	$ref->{'value'} = 'VPN:'.$tap->{'name'}.',0.0.0.0';
	$ref->{'ip'} = '0.0.0.0';
	$ref->{'dev'} = $tap->{'name'};
	push(@arr, $ref);
    }
    my %hash = ();
    my $ref = \%hash;
    $ref->{'name'} = _('VPN') . ' ' . _('IPsec');
    $ref->{'value'} = 'VPN:IPSEC,0.0.0.0';
    $ref->{'ip'} = '0.0.0.0';
    $ref->{'dev'} = 'ipsec+';
    push(@arr, $ref);

    return $ret;
}


sub getSpareMemory() {
    my $swapfree = 0;
    my $used = 0;
    foreach my $line (`/usr/bin/free`) {
	if ($line =~ /cache:\s+(\d+)\s+(\d+)$/) {
	    $used = $1;
	}
	if ($line =~ /Swap:\s+(\d+)\s+(\d+)\s+(\d+)$/) {
	    $swapfree = $3;
	}
    }
    return ($swapfree-$used)*1024;
}

sub fileStayInMemory($) {
    my $filename = shift;
    return 0 if (! -e $filename);

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	$atime,$mtime,$ctime,$blksize,$blocks)
	= stat($filename);
    return 0 if ($size > getSpareMemory());
    return 1;
}

sub writehash
{
	my $filename = $_[0];
	my $hash = $_[1];
	
        if (-e $filename) {
            system("cp -f $filename ${filename}.old &>/dev/null");
        }

    my %plain_conf = ();
    &readplainhash( "$filename", \%plain_conf );

	# write cgi vars to the file.
	open(FILE, ">${filename}") or die "Unable to write file $filename";
	flock FILE, 2;
	foreach $var (keys %$hash) 
	{
	    $val = $hash->{$var};
		#$val = decode_entities($hash->{$var});
		# Darren Critchley Jan 17, 2003 added the following because when submitting with a graphic, the x and y
		# location of the mouse are submitted as well, this was being written to the settings file causing
		# some serious grief! This skips the variable.x and variable.y
		if (!($var =~ /(.x|.y)$/) && ($plain_conf{$var} ne $val)) {
		    $val = decode_entities($val);
			if ($val =~ / /) {
				$val = "\'$val\'"; }
			if (!($var =~ /^(ACTION|__CGI__|submit)/)) {
				print FILE "${var}=${val}\n"; }
		}
	}
	close FILE;
}

sub readhashfile
{
	my $filename = $_[0];
	my $hash = $_[1];
	my ($var, $val);

	open(FILE, $filename) or die "Unable to read file $filename";
	
	while (<FILE>)
	{
		chomp;
		($var, $val) = split /=/, $_, 2;
		if ($var)
		{
			$val =~ s/^\'//g;
			$val =~ s/\'$//g;

			# Untaint variables read from hash
			$var =~ /([A-Za-z0-9_-]*)/;        $var = $1;
			$val =~ /([\w\W]*)/; $val = $1;
			$hash->{$var} = encode_entities($val,"'\"");
		}
	}
	close FILE;
}

sub filteredGlob($) {
    my @ret = ();
    foreach my $item (glob($_[0])) {
	my $ignore = 0;
	foreach my $suffix (@IGNORE_SUFFICES) {
	    if ($item =~ /\.$suffix$/) {
		$ignore = 1;
		break;
	    }
	}
	if ($ignore == 0) {
	    push(@ret, $item);
	}
    }
    return @ret;
}

sub readplainhash($) {
    my $filename = shift;
    my $hash = shift;

    # basic cases:
    #
    # 1) /usr/lib/efw/XXX/default/settings
    # 2) /razwall/config/XXX/default/settings
    # 3) /usr/lib/efw/XXX/vendor/settings
    # 4) /razwall/config/XXX/vendor/settings
    # 5) /var/lib/efw/XXX/default/settings
    #
    # - every default and vendor case searches also for ../ and ../../
    #
    # extension for the future:
    #
    # - case 1 default case searches also for file.* (ignoring some .*
    #   like .old, .rpmsave, etc) allowing vendor and local overrides


    if ($filename =~ /\/var\/efw\/(.*)/) {
        my $modulefile = $1;
        chomp $modulefile;

        my $basename = basename($filename);
        my $module = dirname($modulefile);

        my @search = ();

        # case 1
        push(@search, "$PERSISTENT_DIR/$module/../../$DEFAULT_DIR/$basename");
        push(@search, "$PERSISTENT_DIR/$module/../$DEFAULT_DIR/$basename");
        push(@search, "$PERSISTENT_DIR/$module/$DEFAULT_DIR/$basename");

        push(@search, filteredGlob("$PERSISTENT_DIR/$module/../../$DEFAULT_DIR/$basename.*"));
        push(@search, filteredGlob("$PERSISTENT_DIR/$module/../$DEFAULT_DIR/$basename.*"));
        push(@search, filteredGlob("$PERSISTENT_DIR/$module/$DEFAULT_DIR/$basename.*"));

        # case 2
        push(@search, "$USER_DIR/$module/../../$DEFAULT_DIR/$basename");
        push(@search, "$USER_DIR/$module/../$DEFAULT_DIR/$basename");
        push(@search, "$USER_DIR/$module/$DEFAULT_DIR/$basename");

        # case 3
        push(@search, "$PERSISTENT_DIR/$module/../../$VENDOR_DIR/$basename");
        push(@search, "$PERSISTENT_DIR/$module/../$VENDOR_DIR/$basename");
        push(@search, "$PERSISTENT_DIR/$module/$VENDOR_DIR/$basename");

        # case 4
        push(@search, "$PROVISIONING_DIR/$module/../../$VENDOR_DIR/$basename");
        push(@search, "$PROVISIONING_DIR/$module/../$VENDOR_DIR/$basename");
        push(@search, "$PROVISIONING_DIR/$module/$VENDOR_DIR/$basename");

        # case 5
        push(@search, "$USER_DIR/$module/../../$VENDOR_DIR/$basename");
        push(@search, "$USER_DIR/$module/../$VENDOR_DIR/$basename");
        push(@search, "$USER_DIR/$module/$VENDOR_DIR/$basename");

        # case 6
        push(@search, "$STATE_DIR/$module/../../$DEFAULT_DIR/$basename");
        push(@search, "$STATE_DIR/$module/../$DEFAULT_DIR/$basename");
        push(@search, "$STATE_DIR/$module/$DEFAULT_DIR/$basename");

        foreach my $ff (@search) {
            if (! -e $ff) {
                next;
            }
            readhashfile($ff, $hash);
        }
        return;
    }
    return;
}

sub readhash($$) {
    my $filename = shift;
    my $hash = shift;


    # basic cases:
    #
    # 1) /usr/lib/efw/XXX/default/settings
    # 2) /razwall/config/XXX/default/settings
    # 3) /usr/lib/efw/XXX/vendor/settings
    # 4) /razwall/config/XXX/vendor/settings
    # 5) /var/lib/efw/XXX/default/settings
    # 6) /razwall/config/XXX/settings
    # 7) /var/lib/efw/XXX/settings
    #
    # - every default and vendor case searches also for ../ and ../../
    #
    # extension for the future:
    #
    # - case 1 default case searches also for file.* (ignoring some .*
    #   like .old, .rpmsave, etc) allowing vendor and local overrides


    if ($filename =~ /\/var\/efw\/(.*)/) {
	my $modulefile = $1;
	chomp $modulefile;

	my $basename = basename($filename);
	my $module = dirname($modulefile);

	my @search = ();

	# case 1
	push(@search, "$PERSISTENT_DIR/$module/../../$DEFAULT_DIR/$basename");
	push(@search, "$PERSISTENT_DIR/$module/../$DEFAULT_DIR/$basename");
	push(@search, "$PERSISTENT_DIR/$module/$DEFAULT_DIR/$basename");

	push(@search, filteredGlob("$PERSISTENT_DIR/$module/../../$DEFAULT_DIR/$basename.*"));
	push(@search, filteredGlob("$PERSISTENT_DIR/$module/../$DEFAULT_DIR/$basename.*"));
	push(@search, filteredGlob("$PERSISTENT_DIR/$module/$DEFAULT_DIR/$basename.*"));

	# case 2
	push(@search, "$USER_DIR/$module/../../$DEFAULT_DIR/$basename");
	push(@search, "$USER_DIR/$module/../$DEFAULT_DIR/$basename");
	push(@search, "$USER_DIR/$module/$DEFAULT_DIR/$basename");

	# case 3
	push(@search, "$PERSISTENT_DIR/$module/../../$VENDOR_DIR/$basename");
	push(@search, "$PERSISTENT_DIR/$module/../$VENDOR_DIR/$basename");
	push(@search, "$PERSISTENT_DIR/$module/$VENDOR_DIR/$basename");

	# case 4
	push(@search, "$USER_DIR/$module/../../$VENDOR_DIR/$basename");
	push(@search, "$USER_DIR/$module/../$VENDOR_DIR/$basename");
	push(@search, "$USER_DIR/$module/$VENDOR_DIR/$basename");

	# case 5
	push(@search, "$STATE_DIR/$module/../../$DEFAULT_DIR/$basename");
	push(@search, "$STATE_DIR/$module/../$DEFAULT_DIR/$basename");
	push(@search, "$STATE_DIR/$module/$DEFAULT_DIR/$basename");

	# case 6
	push(@search, "$PROVISIONING_DIR/$module/$basename");

	# case 7
	push(@search, "$USER_DIR/$module/$basename");

	# case 8
	push(@search, "$STATE_DIR/$module/$basename");
	push(@search, filteredGlob("$STATE_DIR/$module/$basename.*"));


	foreach my $ff (@search) {
	    if (! -e $ff) {
		next;
	    }
	    readhashfile($ff, $hash);
	}
	return;
    }

    # if it is not a file beginning with /var/efw
    # fall back to old mode
    if (! -e $filename) {
	return;
    }
    readhashfile($filename, $hash);
}

sub getcgihash {
	my ($hash, $params) = @_;
	my $cgi = CGI->new ();
	$hash->{'__CGI__'} = $cgi;
	return if ($ENV{'REQUEST_METHOD'} ne 'POST');
	if (!$params->{'wantfile'}) {
		$CGI::DISABLE_UPLOADS = 1;
		$CGI::POST_MAX = 512 * 1024;
	}
	else {
		$CGI::POST_MAX = 10 * 1024 * 1024;
	}

	$cgi->referer() =~ m/^https?\:\/\/([^\/]+)/;
	my $referer = $1;
	$cgi->url() =~ m/^https?\:\/\/([^\/]+)/;
	my $servername = $1;
	return if ($referer ne $servername);

	### Modified for getting multi-vars, split by |
	%temp = $cgi->Vars();
    foreach my $key (keys %temp) {
		$hash->{$key} = $temp{$key};
		$hash->{$key} =~ s/\0/|/g;
		$hash->{$key} =~ s/^\s*(.*?)\s*$/$1/;
		$hash->{$key} = encode_entities(uri_unescape($hash->{$key}),"'\"");
    }

	if (($params->{'wantfile'})&&($params->{'filevar'})) {
		$hash->{$params->{'filevar'}} = $cgi->upload($params->{'filevar'});
	}
	return;
}

# Converts an array to JSON format
sub arrayToJSON {
    my $refarray = shift;
    my @array = @$refarray;
    my $json = '[';
    my @value_pairs = ();
    
    foreach (@array) {
        push(@value_pairs, sprintf("\"%s\"", $_));
    }
    
    $json .= join(',', @value_pairs);
    $json .= ']';
    
    return $json;
}

# Convert hash to JSON format
sub hashToJSON {
    my $hashref = shift;
    my %hash = %$hashref;
    my $json = '{';
    my @key_value_pairs = ();
    foreach $key (keys %hash) {
        push(@key_value_pairs, sprintf("\"%s\": \"%s\"", $key, $hash{$key}));
    }
    $json .= join(',', @key_value_pairs);
    $json .= '}';
    
    return $json;
}

# Helper to display notifications on the web interface
sub service_notifications {
    my $servicesref = shift;
    my $optionsref = shift;
    
    printf <<END
        <script type="text/javascript">
            \$(document).ready(function() {
                /* Enable visualization of service notifications */
                display_notifications(%s, %s);
            })
        </script>
END
, arrayToJSON($servicesref)
, hashToJSON($optionsref);
}

# Convert a time stamp to readable string,
# prepending an optional label.
sub timestamp2str($$) {
    my $ts = shift;
    my $label = shift;
    my $str_ts = "";
    if ($ts) {
        $str_ts = scalar localtime($ts);
    }
    if ($label) {
        $str_ts = $label . $str_ts;
    }
    return $str_ts;
}

# Return the timestamp stored by the DownloadJob for
# the provided key.
sub last_download_timestamp($) {
    my $key = shift;
    my %timestampshash = ();
    my $timestamps = \%timestampshash;
    readhash($DOWNLOADJOB_TIMESTAMPS, $timestamps);
    return $timestampshash{$key};
}

1;
