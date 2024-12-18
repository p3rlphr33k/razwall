#!/usr/bin/perl

my %subsubbackuphash = ();
my $subsubbackup = \%subsubbackuphash;

$subsubbackup->{'01.backup'} = {
    'caption' => _('Backup'),
    'uri' => '/cgi-bin/backup.cgi',
    'title' => _('Backup'),
    'enabled' => 1,
    'helpuri' => 'system.html#backup',
};
$subsubbackup->{'02.scheduled'} = {
    'caption' => _('Scheduled backups'),
    'title' => _('Scheduled backups'),
    'uri' => '/cgi-bin/backupschedule.cgi',
    'enabled' => 1,
    'helpuri' => 'system.html#scheduled-backups',
};


my %subsystemhash = ();
my $subsystem = \%subsystemhash;

$subsystem->{'01.home'} = {
    'caption' => _('Dashboard'),
    'uri' => '/manage/dashboard',
    'title' => _('Dashboard'),
    'enabled' => 1,
    'helpuri' => 'system.html#dashboard',
};
$subsystem->{'02.netwizard'} = {
    'caption' => _('Network configuration'),
    'uri' => '/cgi-bin/netwizard.cgi',
    'title' => _('Network configuration'),
    'enabled' => 1,
    'helpuri' => 'system.html#network-configuration',
};
$subsystem->{'05.passwords'} = {
    'caption' => _('Passwords'),
    'uri' => '/cgi-bin/changepw.cgi',
    'title' => _('Passwords'),
    'enabled' => 1,
    'helpuri' => 'system.html#passwords',
};
$subsystem->{'06.ssh'} = {
    'caption' => _('SSH access'),
    'uri' => '/manage/openssh',
    'title' => _('SSH access'),
    'enabled' => 1,
    'helpuri' => 'system.html#ssh-access',
};
$subsystem->{'07.gui'} = {
    'caption' => _('GUI settings'),
    'uri' => '/cgi-bin/gui.cgi',
    'title' => _('GUI settings'),
    'enabled' => 1,
    'helpuri' => 'system.html#gui-settings',
};
$subsystem->{'08.backup'} = {'caption' => _('Backup'),
			     'enabled' => 1,
			     'subMenu' => $subsubbackup
};
$subsystem->{'09.shutdown'} = {
    'caption' => _('Shutdown'),
    'uri' => '/cgi-bin/shutdown.cgi',
    'title' => _('Shutdown/reboot'),
    'enabled' => 1,
    'helpuri' => 'system.html#shutdown',
};

my %substatushash = ();
my $substatus = \%substatushash;
$substatus->{'01.systemstatus'} = {
    'caption' => _('System status'),
    'uri' => '/cgi-bin/status.cgi',
    'title' => _('System status information'),
    'enabled' => 1,
    'helpuri' => 'status.html#system-status',
};
$substatus->{'02.networkstatus'} = {
    'caption' => _('Network status'),
    'uri' => '/cgi-bin/netstatus.cgi',
    'title' => _('Network status information'),
    'enabled' => 1,
    'helpuri' => 'status.html#network-status',
};
$substatus->{'03.systemgraphs'} = {
    'caption' => _('System graphs'),
    'uri' => '/cgi-bin/graphs.cgi',
    'novars' => 1,
    'title' => _('System graphs'),
    'enabled' => 1,
    'helpuri' => 'status.html#system-graphs',
};
$substatus->{'03.systemgraphs1'} = {
    'caption' => _('System graphs'),
    'uri' => '/cgi-bin/graphs.cgi',
    'vars' => 'graph=cpu',
    'title' => _('System graphs'),
    'enabled' => 0,
    'helpuri' => 'status.html#system-graphs',
};
$substatus->{'03.systemgraphs2'} = {
    'caption' => _('System graphs'),
    'uri' => '/cgi-bin/graphs.cgi',
    'vars' => 'graph=memory',
    'title' => _('System graphs'),
    'enabled' => 0,
    'helpuri' => 'status.html#system-graphs',
};
$substatus->{'03.systemgraphs3'} = {
    'caption' => _('System graphs'),
    'uri' => '/cgi-bin/graphs.cgi',
    'vars' => 'graph=swap',
    'title' => _('System graphs'),
    'enabled' => 0,
    'helpuri' => 'status.html#system-graphs',
};
$substatus->{'03.systemgraphs4'} = {
    'caption' => _('System graphs'),
    'uri' => '/cgi-bin/graphs.cgi',
    'vars' => 'graph=df',
    'title' => _('System graphs'),
    'enabled' => 0,
    'helpuri' => 'status.html#system-graphs',
};
$substatus->{'04.trafficgraphs'} = {
    'caption' => _('Traffic Graphs'),
    'uri' => '/cgi-bin/graphs.cgi',
    'vars' => 'graph=network',
    'title' => _('Network traffic graphs'),
    'enabled' => 1,
    'helpuri' => 'status.html#traffic-graphs',
};
$substatus->{'04.trafficgraphs1'} = {
    'caption' => _('Traffic Graphs'),
    'uri' => '/cgi-bin/graphs.cgi',
    'vars' => 'graph=GREEN',
    'title' => _('Network traffic graphs'),
    'enabled' => 0,
    'helpuri' => 'status.html#traffic-graphs',
};
$substatus->{'04.trafficgraphs2'} = {
    'caption' => _('Traffic Graphs'),
    'uri' => '/cgi-bin/graphs.cgi',
    'vars' => 'graph=BLUE',
    'title' => _('Network traffic graphs'),
    'enabled' => 0,
    'helpuri' => 'status.html#traffic-graphs',
};
$substatus->{'04.trafficgraphs3'} = {
    'caption' => _('Traffic Graphs'),
    'uri' => '/cgi-bin/graphs.cgi',
    'vars' => 'graph=ORANGE',
    'title' => _('Network traffic graphs'),
    'enabled' => 0,
    'helpuri' => 'status.html#traffic-graphs',
};
$substatus->{'04.trafficgraphs4'} = {
    'caption' => _('Traffic Graphs'),
    'uri' => '/cgi-bin/graphs.cgi',
    'vars' => 'graph=RED_',
    'title' => _('Network traffic graphs'),
    'enabled' => 0,
    'helpuri' => 'status.html#traffic-graphs',
};
$substatus->{'06.connections'} = {
    'caption' => _('Connections'),
    'uri' => '/cgi-bin/connections.cgi',
    'title' => _('Connections'),
    'enabled' => 1,
    'helpuri' => 'status.html#connections',
};
$substatus->{'06.connections1'} = {
    'caption' => _('Connections'),
    'uri' => '/cgi-bin/ipinfo.cgi',
    'title' => _('Connections'),
    'enabled' => 0,
    'helpuri' => 'status.html#connections',
};
$substatus->{'07.mailgraph'} = {
    'caption' => _('SMTP mail statistics'),
    'uri' => '/cgi-bin/mailgraph.cgi',
    'title' => _('SMTP mail statistics'),
    'enabled' => 1,
    'helpuri' => 'status.html#smtp-mail-statistics',
};
$substatus->{'08.mailqueue'} = {
    'caption' => _('Mail queue'),
    'uri' => '/cgi-bin/mailqueue.cgi',
    'title' => _('Mail queue'),
    'enabled' => 1,
    'helpuri' => 'status.html#mail-queue',
};
$substatus->{'09.monit'} = {
    'caption' => _('Monit'),
    'uri' => '/cgi-bin/monit.cgi',
    'title' => _('Monit'),
    'enabled' => 0,
};





my %subnetworkhash = ();
my $subnetwork = \%subnetworkhash;


my %subserviceshash = ();
my $subservices = \%subserviceshash;

$subservices->{'01.dhcp'} = {
    'caption' => _('DHCP server'),
    'uri' => '/cgi-bin/dhcp.cgi',
    'title' => _('DHCP configuration'),
    'enabled' => 1,
    'helpuri' => 'services.html#dhcp-server',
};
$subservices->{'02.dyndns'} = {
    'caption' => _('Dynamic DNS'),
    'uri' => '/cgi-bin/ddns.cgi',
    'title' => _('Dynamic DNS client'),
    'enabled' => 1,
    'helpuri' => 'services.html#dynamic-dns',
};
$subservices->{'03.time'} = {
    'caption' => _('Time server'),
    'uri' => '/cgi-bin/time.cgi',
    'title' => _('Time server'),
    'enabled' => 1,
    'helpuri' => 'services.html#time-server',
};
$subservices->{'05.ids'} = {
    'caption' => _('Intrusion detection'),
    'enabled' => 1,
    'uri' => '/cgi-bin/ids.cgi',
    'title' => _('Intrusion Detection System (Snort)'),
    'helpuri' => 'services.html#intrusion-prevention',
};
$subservices->{'06.ha'} = {
    'caption' => _('High availability'),
    'enabled' => 1,
    'uri' => '/cgi-bin/ha.cgi',
    'title' => _('High availability'),
    'helpuri' => 'services.html#high-availability',
};


my %subhttphash = ();
my $subhttp = \%subhttphash;
$subhttp->{'01.proxy'} = {
    'caption' => _('Configuration'),
    'uri' => '/cgi-bin/advproxy.cgi',
    'title' => _('HTTP: proxy configuration'),
    'enabled' => 1,
    'helpuri' => 'http.html#configuration',
};
$subhttp->{'02.authentication'} = {
    'caption' => _('Authentication'),
    'uri' => '/cgi-bin/proxyauth.cgi',
    'title' => _('HTTP: authentication'),
    'enabled' => 1,
    'helpuri' => 'http.html#authentication',
};
$subhttp->{'03.defaultsettings'} = {
    'caption' => _('Default policy'),
    'uri' => '/cgi-bin/proxydefault.cgi',
    'title' => _('HTTP: default policy'),
    'enabled' => 1,
    'helpuri' => 'http.html#http',
};
$subhttp->{'04.contentfilter'} = {
    'caption' => _('Web filter'),
    'uri' => '/cgi-bin/dansguardian.cgi',
    'title' => _('HTTP: Web filter'),
    'enabled' => 1,
    'helpuri' => 'http.html#web-filter',
};
$subhttp->{'05.antivirus'} = {
    'caption' => _('Antivirus'),
    'uri' => '/cgi-bin/httpantivirus.cgi',
    'title' => _('HTTP: antivirus'),
    'enabled' => 1,
    'helpuri' => 'http.html#antivirus',
};
$subhttp->{'06.groupmanagment'} = {
    'caption' => _('Group policies'),
    'uri' => '/cgi-bin/proxygroups.cgi',
    'title' => _('HTTP: group policies'),
    'enabled' => 1,
    'helpuri' => 'http.html#http',
};
$subhttp->{'07.policyprofiles'} = {
    'caption' => _('Policy profiles'),
    'uri' => '/cgi-bin/proxyprofiles.cgi',
    'title' => _('HTTP: policy profiles'),
    'enabled' => 1,
    'helpuri' => 'http.html#http',
};




my %subpophash = ();
my $subpop = \%subpophash;

$subpop->{'01.config'} = {
    'caption' => _('Global settings'),
    'uri' => '/cgi-bin/p3scan.cgi',
    'title' => _('POP3: global settings'),
    'enabled' => 1,
    'helpuri' => 'proxy/pop.html#pop3',
};
$subpop->{'02.spamfilter'} = {
    'caption' => _('Spam filter'),
    'uri' => '/cgi-bin/spamassassin.cgi',
    'title' => _('POP3: spam filter'),
    'enabled' => 1,
    'helpuri' => 'proxy/pop.html#spam-filter',
};

my %subftphash = ();
my $subftp = \%subftphash;

$subftp->{'01.proxy'} = {
    'caption' => _('Proxies'),
    'uri' => '/cgi-bin/frox.cgi',
    'title' => _('FTP: virus scanner'),
    'enabled' => 1,
    'helpuri' => 'proxy/ftp.html#ftp',
};

$subsmtp->{'01.proxy'} = {
    'caption' => _('Main'),
    'uri' => '/cgi-bin/smtproxd.cgi',
    'title' => _('SMTP: SMTP scanner'),
    'enabled' => 1,
    'helpuri' => 'smtp.html#smtp',
};

$subsmtp->{'02.antivirus'} = {
    'caption' => _('Antivirus'),
    'uri' => '/cgi-bin/smtpav.cgi',
    'title' => _('SMTP: antivirus'),
    'enabled' => 1,
    'helpuri' => 'smtp.html#antivirus',
};

$subsmtp->{'03.spam'} = {
    'caption' => _('Spam'),
    'uri' => '/cgi-bin/smtpsa.cgi',
    'title' => _('SMTP: spam'),
    'enabled' => 1,
    'helpuri' => 'smtp.html#spam-filter',
};

$subsmtp->{'04.extensions'} = {
    'caption' => _('File extensions'),
    'uri' => '/cgi-bin/smtpext.cgi',
    'title' => _('SMTP: blocked file extensions'),
    'enabled' => 1,
    'helpuri' => 'smtp.html#smtp',
};

$subsmtp->{'05.blacklists'} = {
    'caption' => _('blacklist/whitelist'),
    'uri' => '/cgi-bin/smtpbl.cgi',
    'title' => _('SMTP: blacklist/whitelist'),
    'enabled' => 1,
    'helpuri' => 'smtp.html#black-whitelists',
};

$subsmtp->{'06.domains'} = {
    'caption' => _('Domains'),
    'uri' => '/cgi-bin/smtpdomains.cgi',
    'title' => _('SMTP: local domains'),
    'enabled' => 1,
    'helpuri' => 'smtp.html#incoming-domains',
};

$subsmtp->{'07.bcc'} = {
    'caption' => _('Mail Routing'),
    'uri' => '/cgi-bin/smtpbcc.cgi',
    'title' => _('SMTP: BCC'),
    'enabled' => 1,
    'helpuri' => 'smtp.html#mail-routing',
};
$subsmtp->{'09.advanced'} = {
    'caption' => _('Advanced'),
    'uri' => '/cgi-bin/smtpadv.cgi',
    'title' => _('SMTP: advanced'),
    'enabled' => 1,
    'helpuri' => 'smtp.html#advanced',
};



my %subproxyhash = ();
my $subproxy = \%subproxyhash;

$subproxy->{'01.http'} = {
    'caption' => _('HTTP'),
    'enabled' => 1,
    'subMenu' => $subhttp
};
$subproxy->{'02.pop'} = {
    'caption' => _('POP3'),
    'enabled' => 1,
    'subMenu' => $subpop
};

my %subservicelogshash = ();
my $subservicelogs = \%subservicelogshash;

$subservicelogs->{'01.ids'} = {
    'caption' => _('IDS'),
    'uri' => '/cgi-bin/logs_ids.cgi',
    'title' => _('Intrusion Detection System log viewer'),
    'enabled' => 1,
    'helpuri' => 'logs.html#service',
};
$subservicelogs->{'02.openvpn'} = {
    'caption' => _('OpenVPN'),
    'uri' => '/cgi-bin/logs_openvpn.cgi',
    'title' => _('OpenVPN log'),
    'enabled' => 1,
    'helpuri' => 'logs.html#service',
};
$subservicelogs->{'03.clamavlog'} = {
    'caption' => _('ClamAV'),
    'uri' => '/cgi-bin/logs_clamav.cgi',
    'title' => _('ClamAV log'),
    'enabled' => 1,
    'helpuri' => 'logs.html#service',
};

if (-e '/home/httpd/menus/main/menu-avengine02-panda.pl') {
$subservicelogs->{'04.pandalog'} = {
    'caption' => _('Panda Antivirus'),
    'uri' => '/cgi-bin/logs_panda.cgi',
    'title' => _('Panda log'),
    'enabled' => 1,
    'helpuri' => 'logs.html#service',
};
}


my %sublogshash = ();
my $sublogs = \%sublogshash;

$sublogs->{'00.livelogs'} = {
    'caption' => _('Live Logs'),
    'uri' => '/cgi-bin/logs_live_list.cgi',
    'title' => _('Live Logs'),
    'enabled' => 1,
    'helpuri' => 'logs.html#live',
};
$sublogs->{'01.summary'} = {
    'caption' => _('Summary'),
    'uri' => '/cgi-bin/logs_summary.cgi',
    'title' => _('Log summary'),
    'enabled' => 1,
    'helpuri' => 'logs.html#summary',
};
$sublogs->{'01.system'} = {
    'caption' => _('System'),
    'uri' => '/cgi-bin/logs_log.cgi',
    'title' => _('System log viewer'),
    'enabled' => 1,
    'helpuri' => 'logs.html#logs-system',
};
$sublogs->{'02.service'} = {
    'caption' => _('Service'),
    'enabled' => 1 ,
    'subMenu' => $subservicelogs
};
$sublogs->{'03.firewall'} = {
    'caption' => _('Firewall'),
    'uri' => '/cgi-bin/logs_firewall.cgi',
    'title' => _('Firewall log viewer'),
    'enabled' => 1,
    'helpuri' => 'logs.html#firewall',
};
$sublogs->{'05.settings'} = {
    'caption' => _('Settings'),
    'uri' => '/cgi-bin/logs_config.cgi',
    'title' => _('Log settings'),
    'enabled' => 1,
    'helpuri' => 'logs.html#settings',
};


#
#
# registering
#
#


register_menuitem('01.system', 0, 
		  {
		      'caption' => _('System'),
		      'enabled' => 'on',
		      'subMenu' => $subsystem
		  }
    );
register_menuitem('02.status', 0,
		  {
		      'caption' => _('Status'),
		      'enabled' => 'on',
		      'subMenu' => $substatus
		  }
    );
register_menuitem('03.network', 0,
		  {
		      'caption' => _('Network'),
		      'enabled' => 'on',
		      'subMenu' => $subnetwork
		  }
    );
register_menuitem('04.services', 0,
		  {
		      'caption' => _('Services'),
		      'enabled' => 'on',
		      'subMenu' => $subservices
		  }
    );
register_menuitem('05.firewall', 0,
		  {
		      'caption' => _('Firewall'),
		      'enabled' => 'on'
		  }
    );
register_menuitem('06.proxy', 0,
		  {
		      'caption' => _('Proxy'),
		      'enabled' => 'on',
		      'subMenu' => $subproxy
		  }
    );
register_menuitem('07.vpn', 0,
		  {
		      'caption' => _('VPN'),
		      'enabled' => 'on',
		      'subMenu' => $subvpn
		  }
    );
register_menuitem('99.logs', 0,
		  {
		      'caption' => _('Logs and Reports'),
		      'enabled' => 1,
		      'subMenu' => $sublogs
		  }
    );

1;

