#!/usr/bin/perl

#
#
# registering
#
#
register_menuitem('01.dashboard', 0, 
		  {
			'caption' => '/images/2025/home_light.png',
			'uri' => "window.location.href='/cgi-bin/dashboard.cgi';",
			'title' => 'Monitor',
			'id' => 'home',
			'enabled' => 1,
			'helpuri' => '/forum/index.php?board=8.0',
		  }
    );

register_menuitem('02.system', 0, 
		  {
			'caption' => '/images/2025/system_light.png',
			'uri' => "window.location.href='/cgi-bin/razwall-type.cgi';",
			'title' => 'System',
			'id' => 'system',
			'enabled' => 1,
			'helpuri' => 'https://razwall.com/forum/index.php?board=20.0',
		  }
    );

register_menuitem('03.snat', 0,
		  {
			'caption' => '/images/2025/snat_light.png',
			'uri' => "window.location.href='';",
			'title' => 'SNAT',
			'id' => 'snat',
			'enabled' => 1,
			'helpuri' => 'https://razwall.com/forum/index.php?board=15.0',
		  }
    );

register_menuitem('04.dnat', 0,
		  {
			'caption' => '/images/2025/dnat_light.png',
			'uri' => "window.location.href='/cgi-bin/razwall-dnat.cgi';",
			'title' => 'DNAT',
			'id' => 'dnat',
			'enabled' => 1,
			'helpuri' => 'https://razwall.com/forum/index.php?board=14.0',
		  }
    );

register_menuitem('05.zonefw', 0,
		  {
			'caption' => '/images/2025/zonefw_light.png',
			'uri' => "window.location.href='';",
			'title' => 'Zone FW',
			'id' => 'zonefw',
			'enabled' => 1,
			'helpuri' => 'https://razwall.com/forum/index.php?board=18.0',
		  }
    );
	
register_menuitem('06.outbound', 0,
		  {
			'caption' => '/images/2025/outfw_light.png',
			'uri' => "window.location.href='';",
			'title' => 'Outboud',
			'id' => 'outfw',
			'enabled' => 1,
			'helpuri' => 'https://razwall.com/forum/index.php?board=17.0',
		  }
    );
	
register_menuitem('07.vpnfw', 0,
		  {
			'caption' => '/images/2025/vpnfw_light.png',
			'uri' => "window.location.href='';",
			'title' => 'VPN FW',
			'id' => 'vpnfw',
			'enabled' => 1,
			'helpuri' => 'https://razwall.com/forum/index.php?board=19.0',
		  }
    );
	
register_menuitem('08.access', 0,
		  {
			'caption' => '/images/2025/sysfw_light.png',
			'uri' => "window.location.href='';",
			'title' => 'Access',
			'id' => 'sysfw',
			'enabled' => 1,
			'helpuri' => 'https://razwall.com/forum/index.php?board=20.0',
		  }
    );

register_menuitem('09.routing', 0,
		  {
			'caption' => '/images/2025/routing_light.png',
			'uri' => "window.location.href='';",
			'title' => 'Routing',
			'id' => 'routing',
			'enabled' => 1,
			'helpuri' => 'https://razwall.com/forum/index.php?board=16.0',
		  }
    );
	
register_menuitem('10.hosts', 0,
		  {
			'caption' => '/images/2025/hosts_light.png',
			'uri' => "window.location.href='';",
			'title' => 'Hosts',
			'id' => 'hosts',
			'enabled' => 1,
			'helpuri' => 'https://razwall.com/forum/index.php?board=12.0',
		  }
    );
	
register_menuitem('11.users', 0,
		  {
			'caption' => '/images/2025/users_light.png',
			'uri' => "window.location.href='';",
			'title' => 'Users',
			'id' => 'users',
			'enabled' => 1,
			'helpuri' => '',
		  }
    );
	
register_menuitem('12.network', 0,
		  {
			'caption' => '/images/2025/network_light.png',
			'uri' => "window.location.href='/cgi-bin/razwall-netwizard.cgi';",
			'title' => 'Network',
			'id' => 'network',
			'enabled' => 1,
			'helpuri' => 'https://razwall.com/forum/index.php?board=9.0',
		  }
    );

register_menuitem('13.zones', 0,
		  {
			'caption' => '/images/2025/zones_light.png',
			'uri' => "window.location.href='';",
			'title' => 'Zones',
			'id' => 'zones',
			'enabled' => 1,
			'helpuri' => '',
		  }
    );

register_menuitem('13.dhcp', 0,
		  {
			'caption' => '/images/2025/dhcp_light.png',
			'uri' => "window.location.href='';",
			'title' => 'DHCP',
			'id' => 'dhcp',
			'enabled' => 1,
			'helpuri' => 'https://razwall.com/forum/index.php?board=21.0',
		  }
    );

register_menuitem('14.vpn', 0,
		  {
			'caption' => '/images/2025/vpn_light.png',
			'uri' => "window.location.href='';",
			'title' => 'OpenVPN',
			'id' => 'vpn',
			'enabled' => 1,
			'helpuri' => '',
		  }
    );

register_menuitem('15.theme', 0,
		  {
			'caption' => '/images/2025/theme_light.png',
			'uri' => "javascript:toggleTheme()",
			'title' => 'Theme',
			'id' => 'theme',
			'enabled' => 1,
			'helpuri' => '',
		  }
    );
	
register_menuitem('09.help', 0,
		  {
			'caption' => '/images/2025/help_light.png',
			'uri' => "javascript:window.open('https://razwall.com/forum','_blank','height=700,width=1000,location=no,menubar=no,scrollbars=yes');",
			'title' => 'Help',
			'id' => 'help',
			'enabled' => 1,
			'helpuri' => '',
		  }
    );
	
register_menuitem('99.logout', 0,
		  {
			'caption' => '/images/2025/logout_light.png',
			'uri' => "window.location.href='/cgi-bin/logout.cgi';",
			'title' => 'Logout',
			'id' => 'logout',
			'enabled' => 1,
			'helpuri' => '',
		  }
    );
	
1;

