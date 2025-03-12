#!/usr/bin/perl -X
binmode STDOUT, ":utf8"; # BINARY MODE FOR IMPORT/EXPORT DATA
use utf8; # LETS ASSUME/FORCE ALL UTF8 CHAR SETS
use JSON; # WRITE OUR OWN JSON PARSER IN THE FUTURE TO REMOVE DEPENDENCIES
use Socket; # NEEDED FOR SMTP
use IO::Socket::SSL; # FOR INTERNAL WEBSOCKET
use IO::Select; # USED?
use Protocol::WebSocket::Client; # FOR INTERNAL WEBSOCKET
use Net::LDAP; # FOR AS USER AUTH ON RAZDC LOGIN SCREEN

# Determine if we are secure:
$is_secure = $ENV{'HTTPS'};
$thisPath = $ENV{'REQUEST_URI'};
$thisAddress = $ENV{'SERVER_NAME'};

# Redirect if we are unsecure:
if($is_secure ne 'on') {
	print "Location: https://$thisAddress$thisPath\n\n";	
}

# Establish core variables
$proto = 'ws';
$host = 'localhost';
$port = 4000;
$wsConnected = 0;

%firewall = ();
%perms = ();
%razdc = ();
%services = ();
%settings = ();
%smtp = ();
%svn = ();
%tasks = ();
%users = ();
%netInfo = ();
%template = ();

# build system paths
$cgi_path = $1 if (($ENV{'SCRIPT_FILENAME'}||$0) =~ m/^(.*)(\\|\/)(.+?)$/);
$templates = $cgi_path . '/templates.pl';

$auth = 0; # must always be set to 0 - DO NOT CHANGE THIS!
# Enable debug to see lots of info spit out everywhere in the web console
# Enabled will bypass cookie creating!
# 0 = disabled
# 1 = enabled
$debug = 0; # ALL DEBUG ROUTINES RAN GET REMOVED OR REWORKED, USING DEBUG BREAKS AUTHENTICATION AND CREATES A LOGIN LOOP
$debugws = 0; # DEBUG INTERNAL WEBSOCKET CLIENT

if($debug || $debugws) { print "Content-Type: Text/HTML\n\nDebug Flag Enabled<br>\n"; }

$url = "$proto://$host:$port";

my $tcp_socket = IO::Socket::SSL->new( # DO WE NEED THIS FOR INTERNAL NON-SSL WEBSOCKET CONNECTION?
	PeerAddr => $host,
	PeerPort => "$proto($port)",
	Proto => 'tcp',
	SSL_startHandshake => ($proto eq 'wss' ? 1 : 0),
	Blocking => 1
);# or die "Failed to connect to socket: $@";

my $client = Protocol::WebSocket::Client->new(url => $url);

$client->on(
	write => sub {
		my $client = shift;
		my ($buf) = @_;
		syswrite $tcp_socket, $buf;
	}
);

$client->on(
	connect => sub {
		my $client = shift;
		# You may wish to set a global variable here (our $isConnected), or
		#  just put your logic as I did here.  Or nothing at all :)
		$wsConnected = 1;
	}
);

$client->on(
	error => sub {
		my $client = shift;
		my ($buf) = @_;
		#print "ERROR ON WEBSOCKET: $buf";
		$tcp_socket->close;
		$wsConnected = 0;
		#exit;
	}
);

$client->on(
	read => sub {
		my $client = shift;
		my ($buf) = @_;
		#print "Received from socket: '$buf'";
	}
);

$client->connect;

# read until handshake is complete.
while (! $client->{hs}->is_done) {
	my $recv_data;
	my $bytes_read = sysread $tcp_socket, $recv_data, 16384;
	if (!defined $bytes_read) { die "sysread on tcp_socket failed: $!" }
	elsif ($bytes_read == 0) { die "Connection terminated." }
	$client->read($recv_data);
}

sub runCmd {
	($cmd) = "@_";	
	@result = `sudo $cmd`;
	`echo $cmd >> /razdc/log/cmd.log`;
	if($wsConnected == 1) {
		$client->write("::TRM::Command: $cmd");
		#if(@result) {
		$client->write("::TRM::Result:\n@result");
		#}
	}
	return @result;
}
 
##### END CLIENT WS ###############
# Process POST and GET page requests
&parseform;
# Gather System Configuration
# Used to fetch password based on username
&getConfig;
# Fetch system parameters
&getSystem;
$authvalid = 'true';
# Gather Network Information from system
&netInfo;
# Check that templates file can be loaded..
&loadTemplates;
# check for sessions stored in cookies
$cookies = $ENV{'HTTP_COOKIE'};
$samba_tool = $settings->{'system'}->{'samba'}->{'exe'};
# check cookie login first

if( $cookies ) {
	@allCookies = split(/\;/, $cookies);
	foreach (@allCookies) {
		($singleCookie, $cookieValue) = split(/=/);
		$cookieValues{$singleCookie} = $cookieValue;
		if($debug) {
			print "COOKIE: $singleCookie, $cookieValue";
		}
	}
	
	if( $cookieValues{$cookieName} ) {
		$raw1 = &decode($cookieValues{$cookieName});
		($session_user,$session_hash) = split(/:/, $raw1);
		$username = $session_user;
		$md5hash = $session_hash;
	}
}

########################################################
## AUTHENTICATED WORK STARTS HERE
# Check cookies first

	if($cookies) {
		if( $authvalid eq 'true' ) {
			if($cookies && $session_user && $session_user eq $users->{'admins'}{"$session_user"}->{'name'} && $session_hash eq $users->{'admins'}{"$session_user"}->{'password'}) {
				$auth = 1;
				$username = $session_user;
				$md5hash = $session_hash;
			}
			else {
				$auth = 0;
				$loginError = "Session Expired";
			}
		}
		else {
			$auth = 0;
			$loginError = "Not Activated";
		}
	}
	# Check credentials second, only if cookies fail
	if($auth == 0) {
		if( $authvalid eq 'true' ) {
			if($username && $username eq $users->{'admins'}{"$username"}->{'name'} && $users->{'admins'}{"$username"}->{'enable'} eq 'true' && $md5hash eq $users->{'admins'}{"$username"}->{'password'}) {
				$auth = 1;
				#$username = $session_user;
				#$md5hash = $session_hash;
			}
			else {
				$auth = 0;
				$loginError = "Invalid Login";
			}
		}
		else {
			$auth = 0;
			$loginError = "Not Activated";
		}
	}


# Credentials and Cookies both failed. Last resort, check CGI for session string in request
if($auth == 0) {
	# see if session was passed via CGI
	if($session) {
		$raw1 = &decode($session);
		($session_user,$session_hash) = split(/:/, $raw1);
		$username = $session_user;
		$md5hash = $session_hash;
	}
	if( $authvalid eq 'true') {

			if($session_user && $session_user eq $users->{'admins'}{"$session_user"}->{'name'} && $users->{'admins'}{"$session_user"}->{'enable'} eq 'true' && $session_hash eq $users->{'admins'}{"$session_user"}->{'password'}) {
				$auth = 1;
				$username = $session_user;
				$md5hash = $session_hash;
			}
			else {
				$auth = 0;
				$loginError = "Session Ended";
				&expired;
			}
		
	}
	else {
		$auth = 0;
		$loginError = "Not Activated";
		&expired;
	}
}
if(	$auth == 1) {
	# authentication is good, lets continue. Build session string if it does not exist
	if(!$session) {
		$part4="$username:$md5hash";
		if($debug) {
			print "SESSION: $part4<br>\n";
		}
		$session=&encode($part4);
	}
	$expireCalc = $timeout * 60;
			
	# Determine if we need to set cookie or not and perform action requested.
	# Only set cookie on home until it times out.
	if($do eq 'home') { # requested Home
		print "Set-Cookie:$cookieName=$session;Expires='" . &gmtTimeFormat($expireCalc) . "';Path=/cgi-bin/;SameSite=Strict;Secure;\n";
		print "Content-Type: text/html\n\n";
		if($debug){
			print "Set Cookie 1.<br>\n";
		}
		&home;
		exit;
	}
	elsif($do eq 'JSON') { # requested JSON Config
		print "Content-Type: application/json\n\n";
		 &JSON;
		exit;
	}
	elsif($do eq 'SEARCH') { # requested SEARCH Config
		print "Content-Type: application/json\n\n";
		&SEARCH;
		exit;
	}
	elsif($do eq 'USERS') { # requested USER Config
		print "Content-Type: application/json\n\n";
		&USERS;
		exit;
	}
	elsif($do eq 'sub') { # requested sub-menu function
		print "Set-Cookie:$cookieName=$session;Expires='" . &gmtTimeFormat($expireCalc) . "';Path=/cgi-bin/;SameSite=Strict;Secure;\n";
		print "Content-Type: text/html\n\n";
		if($debug){
			print "Set Cookie 2.<br>\n";
		}
		&{$task}; # call submenu request routine
	}
	elsif($do eq 'save') {
		if ($filename) {
		$dir = "/razdc/tmp";
		print "Content-Type:application/x-download\n";
		print "Content-Disposition: attachment; filename=$filename\n\n";
		open(FILE, "< $dir/$filename") or die "can't open : $!";
		binmode FILE;
		while (<FILE>){
		print $_;
		}
		close FILE;   
		}
		&{$ref}; # call submenu request routine
	}
	elsif($do eq 'savebackup') {
		if ($filename) {
		$dir = "/razdc/backups";
		print "Content-Type:application/x-download\n";
		print "Content-Disposition: attachment; filename=$filename\n\n";
		open(FILE, "< $dir/$filename") or die "can't open : $!";
		binmode FILE;
		while (<FILE>){
		print $_;
		}
		close FILE;   
		}
		&{$ref}; # call submenu request routine
	}
	else {
		$loginError = "Session Ended - 2";
		&expired;
	}
}
else {
	&expired;
}

sub expired {
	# Authentication is bad. Clear any cookies and log off.
	# Login was invalid
	# no cookie, or just a bad login
	print "Set-Cookie:$cookieName=empty;Expires='" . &gmtTimeFormat(-86400) . "';Path=/cgi-bin/;SameSite=Strict;Secure;\n";
	print "Content-Type: text/html\n\n";
	&login($loginError);
	exit;
}
sub administrator { 
		&getTemplate('administrator');
		&doSub("SESSION", $session);
		&printTemplate;
	}
sub loading {
		&getTemplate('loading');
		&printTemplate;
	}
sub versionInfo { 
		$svnuser = $svn->{$settings->{'svn'}}->{'svnuser'};
		$svnpass = $svn->{$settings->{'svn'}}->{'svnpass'};
		($sambav) = &runCmd("$settings->{'system'}->{'samba'}->{'path'}/sbin/samba -V");
		($myVersion) = &runCmd("-u root svn info -r BASE --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache | grep 'Revision: '");
	
		$myVersion =~ s/Revision: //ig;			
		
		$razName = $settings->{'name'};
		$razVersion = $settings->{'version'};
		$razBuild = $myVersion;
		
		$osName = $settings->{'os'}->{'name'};
		$osVersion = $settings->{'os'}->{'version'};
		
		&getTemplate('dash_sysinfo');
		&doSub("OSVERSION", "$osName $osVersion");
		&doSub("SAMBAV", $sambav);
		&doSub("RAZDCV", "$razName $razVersion - $razBuild");
		&doSub("HOST", $netInfo{'HOST'});
		&doSub("FQDN", $netInfo{'FQDN'});
		&doSub("DOMAIN", $netInfo{'DOMAIN'});
		&doSub("REALM", $netInfo{'REALM'});
		&doSub("IPADDR", $netInfo{'IPADDR'});
		&doSub("NETMASK", $netInfo{'NETMASK'});
		&doSub("GATEWAY", $netInfo{'GATEWAY'});
		&printTemplate;
	}
sub razdc {
	$serial = $razdc->{'serial'};
	&getTemplate('razdcWebsite');
	doSub('SERIAL',$serial);
	&printTemplate;
}
sub dash_services { # LINK TO SERVICES WINDOW IN THE FUTURE - LOW PRIORITY
		$q=0;
		$services = &loadJSON('services');
		$name="";
		$daemon="";
		foreach(@{$services->{'services'}}) {
			if ($q%2==1) { $class = "oddRow"; }
			else {$class = "evenRow";}
			$name = $services->{'services'}[$q]->{'name'};
			$daemon = $services->{'services'}[$q]->{'daemon'};

			&getTemplate('dash_services_start');
			&doSub("CLASS", $class);
			&printTemplate;

			@statData = &runCmd("sudo systemctl show $daemon");
			$statData = "@statData";
			$statData =~ s/\\n//ge;

			&getTemplate('dash_services_inner');
			
			if($statData =~ /ActiveState=active/ && $statData !~ /ActiveState=inactive/) {
				$color = 'green';
				$status = 'Running';
			}
			else {
				$color = 'red';
				$status = 'Stopped';
			}
			
			&doSub("SVCNAME", $name);
			&doSub("COLOR", $color);
			&doSub("SVCSTATUS", $status);
			$q++;
			&printTemplate;
			
			&getTemplate('dash_services_end');
			&printTemplate;
		}
	}
sub dash_volumes { 
		use lib '/razdc/www/cgi-bin/';
		use BAR_GRAPH;
		$diskCmd = "df -h";
		@disk = &runCmd($diskCmd);
		
		@disk = @disk[ 1 .. $#disk ];
		@exclude = ('tmpfs','devpts','sunrpc');
		$test = join("|", @exclude);
		foreach $diskData (@disk) {
			$diskData =~ s/^\s+//;
			($PART,$SIZE,$USED,$AVAIL,$USEDP,$MNT) = split(/ +/,$diskData);
			if($PART !~ /$test/g) {
				#if($PART =~ /sda1/g){$PART="Boot";}
				#if($PART =~ /sda2/g){$PART="Recovery";}
				#if($PART =~ /sda3/g){$PART="RazDC";}
				#if($PART =~ /sdb/g){$PART="Backup";}

				$PART =~ tr/\015//d;
				$SIZE =~ tr/\015//d;
				$USED =~ tr/\015//d;
				$AVAIL =~ tr/\015//d;
				$USEDP =~ tr/\015//d;

				$USED = $USED/1000 if ($USED =~ /m/i);
				$USED = $USED/2000 if ($USED =~ /k/i);
		
				$SIZE = $SIZE/1000 if ($SIZE =~ /m/i);
				$SIZE = $SIZE/2000 if ($USED =~ /k/i);

				$graph = BAR_GRAPH->new();
				$graph->{type} = "pBar";		
				$graph->{values} = "$USED;$SIZE";
				$graph->{labels} = "$PART";
				$graph->{barBGColor} = "white";
				$graph->{barBorder} = "1px solid #808080";
				$graph->{labelColor} = "#000";
				$graph->{labelBGColor} = "";
				$graph->{labelBorder} = "";
				$graph->{labelFont} = "Arial Black, Arial, Helvetica";
				$graph->{labelSize} = 14;
				$graph->{absValuesColor} = "#000";
				$graph->{absValuesBGColor} = "white";
				$graph->{absValuesBorder} = "1px solid silver";
				$graph->{absValuesFont} = "Verdana, Arial, Helvetica";
				$graph->{absValuesSize} = 12;
				$graph->{absValuesPrefix} = "";
				$graph->{absValuesSuffix} = " GB";
				$graph->{percValuesColor} = "#000";
				$graph->{percValuesFont} = "Verdana";
				$graph->{percValuesSize} = 14;
				$graph->{showValues} = 1;
				$graph->{barLevelColors} = [0, "lightgreen", 80, "yellow", 120, "red"];
		
				print "<tr onClick=\"window.open('../storage/list.html','tabFrame');\">\n";
				print "<td>" . $graph->create() . "</td>\n";
				print "</tr>\n";	
			}
		}
	}
sub services { 
		$q=0;
		@SRVC;
		$services = &loadJSON('services');
		$name="";
		$daemon="";
		$description="";
		foreach(@{ $services->{'services'} }) {
			if ($q%2==1) { $class = "oddRow"; }
			else {$class = "evenRow";}
			$name = $services->{'services'}[$q]->{'name'};
			$daemon = $services->{'services'}[$q]->{'daemon'};
			$description = $services->{'services'}[$q]->{'description'};
			@statData = &runCmd("systemctl status $daemon");
			$statData = "@statData";
			
			$statData =~ s/\\n//ge;
			if($daemon eq 'httpd.service') {
				&getTemplate('servicesDisabled');
			}
			else {
				&getTemplate('services');
			}
			if($statData =~ /Active: active/g) {
				$color = 'green';
				$status = 'Running';
				$enabledisable = "Disable";
				$startstop = "Stop";
			}
			elsif($statData =~ /Active: failed/g) {
				$color = 'red';
				$status = 'Failed';
				$enabledisable = "Enable";
				$startstop = "Start";
			}
			elsif($statData =~ /Active: inactive/g) {
				$color = 'red';
				$status = 'Stopped';
				$enabledisable = "Enable";
				$startstop = "Start";
			}
			if($session) {
				&doSub("SESSION", $session);	
			}
			else {
				&doSub("SESSION", $cookieValue);	
			}
			&doSub("CLASS", $class);
			&doSub("SVCNAME", $name);
			&doSub("DAEMON", $daemon);
			&doSub("COLOR", $color);
			&doSub("SVCSTATUS", $status);
			&doSub("SVCSTARTSTOP", $startstop);
			&doSub("SVCENABLEDISABLE", $enabledisable);
			
			$q++;
			push(@SRVC, $_);
		}
		
		&getTemplate('services_main');
		doSub('SVCITEMS', "@SRVC");
		&printTemplate;
	}
sub controlService { 
		
		if($control eq 'Stop') {
			$stopData = &runCmd("systemctl stop $daemon");
			$disableData = &runCmd("systemctl disable $daemon");
		}
		if($control eq 'Start') {
			$startData = &runCmd("systemctl start $daemon");
			$enableData = &runCmd("systemctl enable $daemon");
		}
		if($control eq 'restart') {
			$restartData = &runCmd("systemctl restart $daemon");
		}
		@statData = &runCmd("systemctl status $daemon");
		$statData = "@statData";
			
		$statData =~ s/\\n//ge;
		&getTemplate('service_control');
		
		if($statData =~ /Active: active/g) {
			$color = 'green';
			$status = 'Running';
			$enabledisable = "Disable";
			$startstop = "Stop";
		}
		elsif($statData =~ /Active: failed/g) {
			$color = 'red';
			$status = 'Failed';
			$enabledisable = "Enable";
			$startstop = "Start";
		}
		elsif($statData =~ /Active: inactive/g) {
			$color = 'red';
			$status = 'Stopped';
			$enabledisable = "Enable";
			$startstop = "Start";
		}
		if($session) {
			&doSub("SESSION", $session);	
		}
		else {
			&doSub("SESSION", $cookieValue);	
		}
		&doSub("SVCNAME", $svcname);
		&doSub("DAEMON", $daemon);
		&doSub("COLOR", $color);
		&doSub("SVCSTATUS", $status);
		&doSub("SVCSTARTSTOP", $startstop);
		&doSub("SVCENABLEDISABLE", $enabledisable);
		&printTemplate;
	} 
sub saveAdmin { # MOVE HTML TO TEMPLATE
		$auth2 = 0;
		if( $session_user && $session_user eq $users->{'admins'}{"$session_user"}->{'name'} && $session_hash eq $users->{'admins'}{"$session_user"}->{'password'}) {
			$auth2 = 1;
		}
		if( $auth2 && $omd5hash eq $users->{'admins'}{"$session_user"}->{'password'} ) {
			# push new password to perl JSON config in memory hash:
			$users->{'admins'}{"$session_user"}->{'password'} = $nmd5hash;
			&saveConfig('users');
			$message = "<br>Local admin account was updated.<br>You need to login again to continue.<br><button onclick=\"eraseCookie('RazDC-Session-Key'); window.open('/index.html','_Top'); return false;\">Logoff</button>";
		}
		else {
			$message = "<br>Authentication failed.<br>No changes were saved.";
		}
		print "$message";
	}
sub volumes {
		&getTemplate('storage');
		&printTemplate;
	}
sub usb { # FUTURE ? MAYBE NOT WITH WEB BACKUPS - OR MAYBE FOR COMMUNITY EDITION?
		&getTemplate('usb');
		&printTemplate;
	}
sub backup { # ADD PATH TO JSON CONFIG
		$backup_dir = '/razdc/backups';
		if($backup_dir) {
			$dir = "$backup_dir";
			opendir(DIR, $dir) or print "Can't open directory $dir: $!\n";
			$i=0;
			while ($file = readdir(DIR)) {
				next if $file=~/^\./;
				if($file =~ /\.raz$/) {
					$formid = "backupForm$i";
					&getTemplate('backupItem');
					&doSub('FILENAME', $file);
					&doSub('SESSION', $session);
					&doSub('FORMID', $formid);
					push(@BACKUPFILES , $_);
					$i++;
				}
			}
		}
		if(!@BACKUPFILES) { push(@BACKUPFILES, "No backup files found."); }
		
		&getTemplate('backup');
		&doSub('SESSION', $session);
		&doSub('BACKUPFILES', "@BACKUPFILES");
		&printTemplate;
	}
sub delbackup { # NEED TO FIX NUMERICAL ORDERING
	if($filename && $callback) {
		$backup_dir="/razdc/backups";
		unlink("$backup_dir/$filename") or print "Unable to delete backup \"$backup_dir/$filename\" $!<br>\n";
	}
	else {
		print "File: $filename<br>";
		print "Callback: $callback<br>";
	}
	if($callback) {
		&{$callback};
	}
	else {
		print "No callback found!";
		#&login;
	}
}
sub restore { # ADD PATH TO JSON CONFIG
	$backup_dir = '/razdc/backups';
	$temp_dir = '/razdc/tmp';
	$stamp = &getStamp;
	$ImportFile = "RazDC_Restore.$stamp.raz";
	if(-e "$temp_dir/temp.file") {
		print "Generating upload, please check back in a moment.<br>\n";
	}
	if(-e "$temp_dir/temp.file") {
		chmod(0755," $temp_dir/temp.file");
		rename("$temp_dir/temp.file", "$temp_dir/$ImportFile") or print "Error renaming: $!<br>\n";
	}
	else {
		$dir = "$backup_dir";
		opendir(DIR, $dir) or print "Can't open directory $dir: $!\n";
		$i=0;
		while ($file = readdir(DIR)) {
			next if $file=~/^\./;
			if($file =~ /\.raz$/) {
				$formid = "backupForm$i";
				&getTemplate('restoreItem');
				&doSub('FILENAME', $file);
				&doSub('SESSION', $session);
				&doSub('FORMID', $formid);
				push(@BACKUPFILES , $_);
				$i++;
			}
		}
		if(!@BACKUPFILES) { push(@BACKUPFILES, "No backup files found."); }
		&getTemplate('restore');
		&doSub('SESSION', $session);
		&doSub('IMPORTFILES', "@BACKUPFILES");
		&printTemplate;
	}
}
sub completeRestore { # WIP - NEED TO WRITE RESTORE METHODS!
	# Original Method:
	# sudo samba-tool domain backup restore --backup-file=<tar-file> --newservername=<DC-name> --targetdir=<new-samba-dir>
	# $restoreCmd = "sudo samba-tool domain backup restore --backup-file=<tar-file> --newservername=$newhostname --targetdir=<new-samba-dir>";
	
	
	# Manual Method:
=pod
	# RESTORE SSL, JSON, DHCP, DNS, CRON, WHAT ELSE? - LOOK AT SAMBA_BACKUP SCRIPT in /razdc/scripts folder..
	Remove the folders, that we will restore (samba must not be running!):

	# rm -rf /usr/local/samba/etc
	# rm -rf /usr/local/samba/private
	# rm -rf /usr/local/samba/var/locks/sysvol

	Now unpack your latest working backup files to their old location:

	# cd /usr/local/backups
	# tar -jxf etc.{Timestamp}.tar.bz2 -C /usr/local/samba/
	# tar -jxf samba4_private.{Timestamp}.tar.bz2 -C /usr/local/samba/
	# tar -jxf sysvol.{Timestamp}.tar.bz2 -C /usr/local/samba/

	Rename *.ldb.bak files in the 'private' directory back to *.ldb. This can be done with GNU find and Bash:

	# find /usr/local/samba/private/ -type f -name '*.ldb.bak' -print0 | while read -d $'\0' f ; do mv "$f" "${f%.bak}" ; done
	
	If your backup doesn't contain extended ACLs (see section About the samba_backup script, you have to run:

	# samba-tool ntacl sysvolreset

	If you use Bind as DNS backend, you have to fix the hardlinks for the DNS databases:

	# samba_upgradedns --dns-backend=BIND9_DLZ

	See DNS Backend BIND - New added DNS entries are not resolvable.

	Now you can start samba and test if your restore was successful.
------------------------------------------------------------------------
SAMBA 4.13

Restore

The following restore guide assumes that you backed-up your databases with the 'samba_backup' script. If you have your own script, adjust the steps.

Very important notes:

    Never do a restore and a version change at the same time! Always restore on a system using the same Samba version as the one you created the backup on!
    Always Restore on a system with the same IP and Hostname. Otherwise you will run into Kerberos and DNS issues.
    Recommended: Restore on the same OS as you created the backup on.

The most important thing in a restore situation is to bring your system back to a running state. Once everything is up and tested, you can then do any required changes. Never try to make changes together with a restore!

If your whole system is broken, you will first have to setup the whole machine as described in the HowTo (Active Directory Controller).

Remove the folders, that we will restore (samba must not be running!):

# rm -rf /usr/local/samba/etc
# rm -rf /usr/local/samba/private
# rm -rf /usr/local/samba/var/locks/sysvol

Now unpack your latest working backup files to their old location:

# cd /usr/local/backups
# tar -jxf etc.{Timestamp}.tar.bz2 -C /usr/local/samba/
# tar -jxf samba4_private.{Timestamp}.tar.bz2 -C /usr/local/samba/
# tar -jxf sysvol.{Timestamp}.tar.bz2 -C /usr/local/samba/

Rename *.ldb.bak files in the 'private' directory back to *.ldb. This can be done with GNU find and Bash:

# find /usr/local/samba/private/ -type f -name '*.ldb.bak' -print0 | while read -d $'\0' f ; do mv "$f" "${f%.bak}" ; done

If your backup doesn't contain extended ACLs (see section About the samba_backup script, you have to run:

# samba-tool ntacl sysvolreset

If you use Bind as DNS backend, you have to fix the hardlinks for the DNS databases:

# samba_upgradedns --dns-backend=BIND9_DLZ

See DNS Backend BIND - New added DNS entries are not resolvable.

Now you can start samba and test if your restore was successful. 
=cut	
}
sub updateCheck {
	$svnuser = $svn->{$settings->{'svn'}}->{'svnuser'};
	$svnpass = $svn->{$settings->{'svn'}}->{'svnpass'};
	
	($myVersion) = `sudo -u root svn info $svnpath -r BASE --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache | grep 'Revision: '`;
	($serverVersion) = `sudo -u root svn info $svnpath -r HEAD --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache | grep 'Revision: '`;
	@serverVersionLog = `sudo -u root svn log $svnpath -r HEAD --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache`;
	
	$serverVersionLog = "@serverVersionLog";
	$serverVersionLog =~ s/(-)(?=.*?\1)//gis;
	$serverVersionLog =~ s/\|/<br>/g;
		
	$myVersion =~ s/Revision: //ig;			
	$serverVersion =~ s/Revision: //gi;
	
	if($myVersion < $serverVersion) {
		if($wsConnected == 1) {
			$client->write("::NOTIFY::A RazDC update is available: $serverVersion.<br><button onclick=\"win('','RazDC Update','/cgi-bin/core.pl?do=sub&task=update&session=$session','600','500','');\">View Update</button>");
		}
	}
}
sub update { 
	$svnuser = $svn->{$settings->{'svn'}}->{'svnuser'};
	$svnpass = $svn->{$settings->{'svn'}}->{'svnpass'};
	$svnpath = $svn->{$settings->{'svn'}}->{'svnpath'};
	
	($myVersion) = `sudo -u root svn info $svnpath -r BASE --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache | grep 'Revision: '`;
	($serverVersion) = `sudo -u root svn info $svnpath -r HEAD --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache | grep 'Revision: '`;
	@serverVersionLog = `sudo -u root svn log $svnpath -r HEAD --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache`;
	
	$serverVersionLog = "@serverVersionLog";
	$serverVersionLog =~ s/(-)(?=.*?\1)//gis;
	$serverVersionLog =~ s/\|/<br>/g;
	$myVersion =~ s/Revision: //ig;			
	$serverVersion =~ s/Revision: //gi;
	&getTemplate('update');
	&doSub("MYVERSION", $myVersion);
	&doSub("SESSION", $session);
	&doSub("SERVERVERSION", $serverVersion);
	&doSub("UPDATEDESC", $serverVersionLog);
	chomp($myVersion);
	chomp($serverVersion);
	if($myVersion < $serverVersion) {
		$disable = '';
	}
	else {
		$disable = 'disabled';
	}
	&doSub("DISABLED", $disable);
	&printTemplate;
}
sub completeUpdate {
	$svnrepo = $svn->{$settings->{'svn'}}->{'url'};
	$svnuser = $svn->{$settings->{'svn'}}->{'svnuser'};
	$svnpass = $svn->{$settings->{'svn'}}->{'svnpass'};
	$svnpath = $svn->{$settings->{'svn'}}->{'svnpath'};
	$svnrepo =~ s/=>/:/g;
	
	# Run the update:
	`sudo -u root svn checkout $svnrepo $svnpath  --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache --force`;
	
	# Reset permissions on all CGI files after the update
	$q=0;
	foreach (@{ $perms->{'chmod777'} }) {
		&runCmd("chmod 0777 $perms->{'chmod777'}[$q]");
		$q++;
	}
	
	$q=0;
	foreach (@{ $perms->{'chmod777R'} }) {
		&runCmd("chmod -R 0777 $perms->{'chmod777R'}[$q]"); # 'R' is case sensitive!
		$q++;
	}
	
	$q=0;
	foreach (@{ $perms->{'chmod775'} }) {
		&runCmd("chmod 0775 $perms->{'chmod775'}[$q]");
		$q++;
	}
	
	$q=0;
	foreach (@{ $perms->{'chmodx'} }) {
		&runCmd("chmod +x $perms->{'chmodx'}[$q]");
		$q++;
	}
	
	# Spit out the messages from these commands:
	
	# NEEDS UPDATING TO USE LATEST JSON METHODS!
	# update crontab:
	# `sudo crontab < $scriptpath/cron.txt`;

	($myVersion) = `sudo -u root svn info $svnpath -r BASE --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache | grep 'Revision: '`;
	($serverVersion) = `sudo -u root svn info $svnpath -r HEAD --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache | grep 'Revision: '`;
	@serverVersionLog = `sudo -u root svn log $svnpath -r HEAD --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache`;

	$serverVersionLog = "@serverVersionLog";
	$serverVersionLog =~ s/(-)(?=.*?\1)//gis;
	$serverVersionLog =~ s/\|/<br>/g;
		
	
	$myVersion =~ s/Revision: //ig;			
	$serverVersion =~ s/Revision: //gi;
	&getTemplate('update');
	&doSub("MYVERSION", $myVersion);
	&doSub("SERVERVERSION", $serverVersion);
	&doSub("UPDATEDESC", $serverVersionLog);
	chomp($myVersion);
	chomp($serverVersion);
	if($myVersion < $serverVersion) {
		$disable = '';
	}
	else {
		$disable = 'disabled';
	}
	&doSub("DISABLED", $disable);
	&printTemplate;	
	if($wsConnected == 1) {
		$client->write("::NOTIFY::Update Complete: $serverVersion.");
	}
}
sub sdiag { 
		$ipaddr = $netInfo{'IPADDR'};
		$samba_path = $settings->{'system'}->{'samba'}->{'path'};
		@smbclient = &runCmd("sudo $samba_path/bin/smbclient -L $ipaddr -U%");
		
		&getTemplate('genericwin');
		&doSub("GENERICDATA", "@smbclient");
		&printTemplate;
	}
sub dcdiag { 		
		@dbcheck = &runCmd("sudo $samba_tool dbcheck");
		@drskcc = &runCmd("sudo $samba_tool drs kcc");
		@drsopt = &runCmd("sudo $samba_tool drs options");

		$line1 = "Database check:<br>@dbcheck<br>";
		$line2 = "Replication KCC Check:<br>@drskcc<br>";
		$line3 = "Replication Options:<br>@drsopt<br>";
		$line4 = "Finished.";
		$lines = "$line1 $line2 $line3 $line4";

		&getTemplate('genericwin');
		&doSub("GENERICDATA", $lines);
		&printTemplate;
	}
sub intdiag {  # MOVE ALL HTML TO TEMPLATE!
		($results1) = &runCmd("host -t SRV _ldap._tcp.$netInfo{'REALM'}.");
		($results2) = &runCmd("host -t SRV _kerberos._udp.$netInfo{'REALM'}.");
		($results3) = &runCmd("host -t A $netInfo{'FQDN'}.");
		
		$line1 = "&emsp;Checking Service Records for LDAP:<br><br>\n";
		$line2 = "<b style=\"border:0px #696969 solid;margin:8px;\">$results1</b><br><br>\n";
		$line3 = "&emsp;Checking Service Records for Kerberos:<br><br>\n";
		$line4 = "<b style=\"border:0px #696969 solid;margin:8px;\">$results2</b><br><br>\n";
		$line5 = "&emsp;Checking Host Records:<br><br>\n";
		$line6 = "<b style=\"border: 0px #696969 solid;margin:8px;\">$results3</b><br><br>\n";
		
		$lines = "$line1 $line2 $line3 $line4 $line5 $line6";
		
		&getTemplate('genericwin');
		&doSub("GENERICDATA", $lines);
		&printTemplate;
	}
sub exdiag {  
		&getTemplate('exdiag');
		&doSub("SESSION", $session);
		&printTemplate;
	}
sub exrun {
		if($exdomain) {
			@lookup = &runCmd("nslookup $exdomain");
			$lookup = "@lookup";
			&getTemplate('genericwin');
			&doSub("GENERICDATA", $lookup);
			&printTemplate;
		}
		else {
			&getTemplate('genericwin');
			&doSub("GENERICDATA", 'Enter a valid domain to test.');
			&printTemplate;
		}
	}
sub krb5diag { 
		&getTemplate('krb5diag');
		&doSub("SESSION", $session);
		&doSub("DOMAIN", $netInfo{'DOMAIN'});
		&printTemplate;
	}
sub krb5test { 
		$MYREALM = uc($netInfo{'REALM'});
		$kadd = "sudo /razdc/scripts/krb5.sh administrator $MYREALM $krb5hash";
		$ktest = "sudo echo $krb5hash | sudo kinit administrator\@$MYREALM";
		
		@output1 = &runCmd("$kadd 2>&1");
		$output1 = "@output1";
		&getTemplate('genericwin');
		&doSub("GENERICDATA", "$output1");
		&printTemplate;
		
		@output2 = &runCmd("$ktest 2>&1");
		$output2 = "@output2";
		&getTemplate('genericwin');
		&doSub("GENERICDATA", "$output2");
		&printTemplate;
	}
sub domaininfo {
		&getTemplate('domaininfo');
		
		@domain_info = &runCmd("sudo $samba_tool domain info $netInfo{'IPADDR'}");
		
		foreach(@domain_info) {
			($K,$V) = split(/ : /, $_);
			push(@domainInfo, "$V");
		}
		&doSub("FOREST", $domainInfo[0]);
		&doSub("DOMAIN", $domainInfo[1]);
		&doSub("NBDOMAIN", $domainInfo[2]);
		&doSub("DCNAME", $domainInfo[3]);
		&doSub("DCNBNAME", $domainInfo[4]);
		&doSub("SERVERSITE", $domainInfo[5]);
		&doSub("CLIENTSITE", $V);
		&printTemplate;
	}
sub funclvl { # N/A UNTIL SUPPORTED
		
		@domain_level = &runCmd("sudo $samba_tool domain level show");
		
		foreach(@domain_level) {
			if($_ =~ m/: /) {
			($K,$V) = split(/: /,$_);
			# Override value to test
			#$V = "2012 R2";
			$CONTAINERID = $K;
			$CONTAINERID =~ s/ /_/g;
				if($V){
					if($K =~ m/Forest/gi){$func = "--forest-level";}
					if($K =~ m/Domain/gi){$func = "--domain-level";}
				
					if($K =~ m/^Domain|Forest/) {
						if($V !~ m/2012 R2/) {
							if($V =~ /2003/) {
								$newfunc = '2008';
								$newtext = '2008';
							}
							if($V =~ /2008/) {
								$newfunc = '2008_R2';
								$newtext = '2008 R2';
							}
							if($V =~ /2008 R2/) {
								$newfunc = '2012';
								$newtext = '2012';
							}
							if($V =~ /2012/) {
								$newfunc = '2012_R2';
								$newtext = '2012 R2';
							}
							&getTemplate('levels');
							&doSub("CONTAINERID", $CONTAINERID);
							&doSub("SESSION", $session);
							&doSub("LVLNAME", $K);
							&doSub("VALUE", $V);
							&doSub("FORESTDOMAIN", $func);
							&doSub("NEWFUNC", $newfunc);
							&doSub("NEWTEXT", $newtext);
							&doSub("DISABLED", 'disabled');
							&printTemplate;
						}
						else {
							$newfunc = 'DISABLED';
							$newtext = 'DISABLED';
							$disabled='disabled';
					
							&getTemplate('nolvl');
							&doSub("CONTAINERID", $CONTAINERID);
							&doSub("SESSION", $session);
							&doSub("LVLNAME", $K);
							&doSub("VALUE", $V);
							&doSub("FORESTDOMAIN", $func);
							&doSub("NEWFUNC", $newfunc);
							&doSub("NEWTEXT", $newtext);
							&doSub("DISABLED", 'disabled');
							&printTemplate;
						}
					}
				}
			}
		}
	}
sub raiselvl { # N/A UNTIL SUPPORTED
		if($func && $level) {
			
			$mesg = &runCmd("sudo $samba_tool domain level raise $func=$level");
			if($func =~ m/forest/gi){$func = "Forest";}
			if($func =~ m/domain/gi){$func = "Domain";}
		}
		else {
			$mesg = "ERROR: No data for function level change!";
		}
		
#		&getTemplate('raiselvl');
#		&doSub("FUNC", $func);
#		&doSub("LEVEL", $level);
#		&doSub("MESG", $mesg);
#		&printTemplate;
		
		@domain_level = &runCmd("sudo $samba_tool domain level show");
		
		foreach(@domain_level) {
			if($_ =~ m/: /) {
			($K,$V) = split(/: /,$_);
			# Override value to test
			#$V = "2012 R2";
			$CONTAINERID = $K;
			$CONTAINERID =~ s/ /_/g;
				if($V){
					if($K =~ m/Forest/gi){$func = "--forest-level";}
					if($K =~ m/Domain/gi){$func = "--domain-level";}
				
					if($K =~ m/^Domain|Forest/) {
						if($V !~ m/2012 R2/) {
							if($V =~ /2003/) {
								$newfunc = '2008';
								$newtext = '2008';
							}
							if($V =~ /2008/) {
								$newfunc = '2008_R2';
								$newtext = '2008 R2';
							}
							if($V =~ /2008 R2/) {
								$newfunc = '2012';
								$newtext = '2012';
							}
							if($V =~ /2012/) {
								$newfunc = '2012_R2';
								$newtext = '2012 R2';
							}
							&getTemplate('raiselvl2');
							&doSub("CONTAINERID", $CONTAINERID);
							&doSub("SESSION", $session);
							&doSub("LVLNAME", $K);
							&doSub("VALUE", $V);
							&doSub("FORESTDOMAIN", $func);
							&doSub("NEWFUNC", $newfunc);
							&doSub("NEWTEXT", $newtext);
							&printTemplate;
						}
						else {
							$newfunc = 'DISABLED';
							$newtext = 'DISABLED';
							$disabled='disabled';
					
							&getTemplate('nolvl');
							&doSub("CONTAINERID", $CONTAINERID);
							&doSub("SESSION", $session);
							&doSub("LVLNAME", $K);
							&doSub("VALUE", $V);
							&doSub("FORESTDOMAIN", $func);
							&doSub("NEWFUNC", $newfunc);
							&doSub("NEWTEXT", $newtext);
							&printTemplate;
						}
					}
				}
			}
		}
	}
sub passpol { 
		
		@domain_passpol = &runCmd("sudo $samba_tool domain passwordsettings show");
		&getTemplate('pass_policy_begin');
		&printTemplate;
		foreach(@domain_passpol) {
		($K,$V) = split(/: /,$_);
		
		if($V){
			if($K =~ /\bPassword complexity\b/ || $K =~ /Store plaintext passwords/) {
				$sname = "complex";
				if($K =~ /\bPassword complexity\b/) {
					$sname = "complex";
					$comment = "(Default is 'on')";
				}
				if($K =~ /Store plaintext passwords/) {
					$sname = "plain";
					$comment = "(Default is 'off')";
				}
				$options = "";
				@modes = ('on','off');
				foreach $mode (@modes) {
					$options .= " <option value=\"$mode\"". ($V =~ m/$mode/ ? ' selected="selected"' : ''). ">$mode</option>\n";
				}
				&getTemplate('pass_policy_drop');
				&doSub("KEY", $K);
				&doSub("SNAME", $sname);
				&doSub("OPTIONS", $options);
				&doSub("COMMENT", $comment);
				&printTemplate;
			}
			else {
				$iname = $K;
				$iname =~ s/ /_/g;
				if($K =~ /\bPassword history length\b/) {
					$iname = "history"; 
					$comment = "(Default is 24)";
					}
				if($K =~ /\bMinimum password length\b/) {
					$iname = "minLen";
					$comment = "(Default is 7)";
				}
				if($K =~ /\bMinimum password age\b/) {
					$iname = "minAge";
					$comment = "(Default is 1)";
				}
				if($K =~ /\bMaximum password age\b/) {
					$iname = "maxAge";
					$comment = "(Default is 42)";
				}
				if($K =~ /\bAccount lockout duration\b/) {
					$iname = "lockDur";
					$comment = "(Default is 30)";
				}
				if($K =~ /\bAccount lockout threshold\b/) {
					$iname = "lockTH";
					$comment = "(Default is 0)";
				}
				if($K =~ /\bReset account lockout after\b/) {
					$iname = "resetLock";
					$comment = "(Default is 30)";
				}
				&getTemplate('pass_policy_input');
				&doSub("KEY", $K);
				&doSub("INAME", $iname);
				&doSub("VALUE", $V);
				&doSub("COMMENT", $comment);
				&printTemplate;
			}
		}
	}
	&getTemplate('pass_policy_end');
	&doSub("SESSION", $session);
	&printTemplate;
	}
sub passpol_update {		
		@passpolresults = &runCmd("sudo $samba_tool domain passwordsettings set --complexity=$complex --store-plaintext=$plain --history-length=$history --min-pwd-length=$minLen --min-pwd-age=$minAge --max-pwd-age=$maxAge --account-lockout-duration=$lockDur --account-lockout-threshold=$lockTH --reset-account-lockout-after=$resetLock");
		&getTemplate('genericwin');
		&doSub('GENERICDATA', "<br>&emsp;Password Policy Updated.<br>@passpolresults");
		&printTemplate;
	}
sub seizeRole { 
	$fsmomesg = '';
	
	if($role) {
		if($force) { $cmd = "sudo $samba_tool fsmo seize --role=$role"; } 
		else { $cmd = "sudo $samba_tool fsmo seize --role=$role --force"; }
		@fsmomesg = &runCmd("$cmd");
		&fsmo;
	}
	else {
		&getTemplate('genericwin');
		&doSub("GENERICDATA", "Seize failed: Missing Server Role: $role");
		&printTemplate;
	}
}
sub transferRole { 
	$fsmomesg = '';
	
	if($role){
		@fsmomesg = &runCmd("sudo $samba_tool fsmo transfer --role=$role");
		&fsmo;
	}
	else {
		&getTemplate('genericwin');
		&doSub("GENERICDATA", "Transfer failed: Missing Server Role: $role");
		&printTemplate;
	}
}
sub fsmo { 
		$ROLEFQDN = uc($netInfo{'FQDN'});
		&getTemplate('currentRolesHead');
		&doSub('FSMOMSG', "<p>@fsmomesg</p>THIS SERVER: $ROLEFQDN");
		&printTemplate;

		
		@fsmo = &runCmd("sudo $samba_tool fsmo show");
		
		# FSMO CHANGES:
		$roleid=1;
		foreach $row (@fsmo) {
			@CNS = ();
			@DCS = ();
			($role, $value) = split(/ owner:/, $row);
			(@ele) = split(/,/, $value);
			foreach (@ele) {
                ($k,$v) = split(/=/, $_);
                if($k =~ /DC/) { push(@DCS, $v); }
                if($k =~ /CN/) { push(@CNS, $v); }
			}

			$newValue = join(',', @CNS);
			($ntds,$host,$grp,$site,$sitegrp,$config) = split(/,/, $newValue);

			($hostkey,$hostval) = split(/=/,$host);
			$ServerD = join('.', @DCS);
			$roleHost = uc("$host.$ServerD");
			
			if($role eq "InfrastructureMasterRole" ) {
				$roleName = "Infrastructure Master";
				$fsmoRole = "infrastructure";
			}
			if($role eq "RidAllocationMasterRole") {
				$roleName = "RID Master";
				$fsmoRole = "rid";
			}
			if($role eq "PdcEmulationMasterRole") {
				$roleName = "PDC Emulator";
				$fsmoRole = "pdc";
			}
			if($role eq "DomainNamingMasterRole") {
				$roleName = "Domain Naming Master";
				$fsmoRole = "naming";
			}
			if($role eq "SchemaMasterRole") {
				$roleName ="Schema Master";
				$fsmoRole = "schema";
			}
			if($role eq "DomainDnsZonesMasterRole") {
				$roleName = "Domain DNS Master";
				$fsmoRole = "domaindns";
			}
			if($role eq "ForestDnsZonesMasterRole") {
				$roleName = "Forest DNS Master";
				$fsmoRole = "forestdns";
			}
			if( $roleHost =~ /$ROLEFQDN/) {
				$roleHost = "<b style=\"color:green;\">$roleHost</b>";
				$disabled = 'disabled="disabled"';
			}
			else {
				$roleHost = "<b style=\"color:orange;\">$roleHost</b>";
				$disabled = '';
			}
			&getTemplate('rolesTemp');
			&doSub('ROLENAME', "&emsp;$roleName");
			&doSub('ROLEHOST', "&emsp;$roleHost");
			&doSub('DISABLED', "$disabled");
			&doSub('ROLE', "$fsmoRole");
			&doSub('ROLEID', "$roleid");
			&doSub('SESSION', "$session");
			&printTemplate;
			$roleid++;
		}
		&getTemplate('rolesFoot');
		&doSub('SESSION', "$session");
		&printTemplate;
	}
sub gpo { # WIP - ADD PER MIKE S.
	
@gpo = &runCmd("sudo $samba_tool gpo listall");

#GPO
#displayname
#path
#dn
#version
#flags

$q=0;

@policyTabs;
@policyTabContent;

foreach $line (@gpo) {
	($k,$v) = split(/:/, $line);
	$k =~ s/ //gi;
	$v =~ s/\R//g;
	
	${$k} = $v;
	if($k =~ /displayname/) {
		$policyid = $displayname;
		$policyid =~ s/ //g;
		&getTemplate('policyEntry');
		&doSub("POLICYID", $policyid);
		&doSub("POLICYNAME", $displayname);
		push(@policyTabs, "$_");
		}
	$q++;
}

foreach $line (@gpo) {
	($k,$v) = split(/:/, $line);
	$k =~ s/ //gi;
	$v =~ s/\R//g;
	
	${$k} = $v;
	
	$policyid = $displayname;
	$policyid =~ s/ //g;
	&getTemplate('policyTabContent');
	&doSub("POLICYID", $policyid);
	&doSub("PDN", $displayname);
	&doSub("GPO", $GPO);
	&doSub("GPPATH",$path);
	&doSub("GPDN",$dn);
	&doSub("GPV",$version);
	&doSub("GPF",$flags);
	push(@policyTabContent, "$_");
}
		
&getTemplate('policyTemplate');
&doSub("POLICYTABS","@policyTabs");
&doSub("POLICYTABCONTENT","@policyTabContent");
&printTemplate;
}
sub shares { # SHARES - WIP! ADDED PER NOAH C.
# NEW SHARE
#########################################
# mkdir /nas
# chmod -R 775 /nas
# chown -R root:"domain users" /nas
# ls -alh | grep nas
#
# SMB.CONF
# [nas]
#	path = /nas
#	read only = no
# SECURED]
#
# path = /samba/shares
# valid users = @smbgrp
# browsable = yes
# writable = yes
# read only = no

		&getTemplate('shares');
		&printTemplate;
	}
sub int { 
		&getTemplate('interface');
		&doSub("HOST", $netInfo{'HOST'});
		&doSub("FQDN", $netInfo{'FQDN'});
		&doSub("DOMAIN", $netInfo{'DOMAIN'});
		&doSub("REALM", $netInfo{'REALM'});
		&doSub("IPADDR", $netInfo{'IPADDR'});
		&doSub("NETMASK", $netInfo{'NETMASK'});
		&doSub("GATEWAY", $netInfo{'GATEWAY'});
		&printTemplate;
	}
sub dhsettings { 
		$dhcpOptions = $settings->{'system'}->{'dhcp'}->{'options'};
		$dhcpHosts = $settings->{'system'}->{'dhcp'}->{'hostdir'};
		$dhcpScopes = $settings->{'system'}->{'dhcp'}->{'scopedir'};
		$authoritative = "false";
		open(dhcpOptions, "< $dhcpOptions") or print "Error: $!.\n";
		@dhcpOptions =  <dhcpOptions>;
		close(dhcpOptions);
		# Define globals
		@DomainNameServers;
		@NetbiosNameServers;
		foreach $line (@dhcpOptions) {
			#print "$line<br>\n";
			$line =~ s/^option\s//gi;
			$line =~ s/;//gi;
			$line =~ s/\"//gi;
			if($line =~ /\s/g && $line !~ /authoritative/ && $line !~ /^\s+?$/) {
				($k,$v) = split(/\s/, $line);
				$k =~ s/-//gi;

				if($k =~ /domainnameservers/) {
					#print "DNS: $k,$v<br>\n";
					if($v =~ /,/) {
						#print "Multiple DNS Found!<br>\n";
						(@DNSServer) = split(/,/, $v);
						foreach $dhcpGlobalDNS (@DNSServer) {
							push(@DomainNameServers, $dhcpGlobalDNS);
						}
					}
					else { #print "Single DNS Found!<br>\n"; 
						push(@DomainNameServers, $v); 
					}
				}

				if($k =~ /netbiosnameservers/) {
					#print "NNS: $k,$v<br>\n";
					if($v =~ /,/) {
						#print "Single NNS Found!<br>\n";
						(@NNSServer) = split(/,/, $v);
						foreach $dhcpGlobalNNS (@NNSServer) {
							push(@NetbiosNameServers, $dhcpGlobalNNS);
						}
					}
					else { #print "Single NNS Found!<br>\n"; 
						push(@NetbiosNameServers, $v);
					}
                }
				else {
					${$k} = $v;
				}
			}
	
			if($line =~ /authoritative/gi) {
				$authoritative = "true";
			}
		}

		$nscount=0;
		@NSNameServers;
		foreach $dnsip (@DomainNameServers) {
			&getTemplate('dhcp_dns_server');
			&doSub("DHDNSCOUNT", "domainnameservers$nscount");
			&doSub("DHDNSENTRY", $dnsip);
			push(@NSNameServers, $_);
			$nscount++;
		}

		$winscount=0;
		@NBNameServers;
		foreach $nnsip (@NetbiosNameServers) {
			&getTemplate('dhcp_wins_server');
			&doSub("DHWINSCOUNT", "netbiosnameservers$winscount");
			&doSub("DHWINSENTRY", $nnsip);
			push(@NBNameServers, $_);
			$winscount++;
		}
		
		&getTemplate('dhcp_global');
		&doSub("DHDOMAINNAME", $domainname);
		&doSub("DHDNSSERVERS", "@NSNameServers");
		&doSub("DHDNSCOUNT", "domainnameservers$nscount");
		&doSub("DHWINSSERVERS", "@NBNameServers");
		&doSub("DHWINSCOUNT", "netbiosnameservers$winscount");
		&doSub("DEFAULTLEASETIME", $defaultleasetime);
		&doSub("MAXLEASETIME", $maxleasetime);
		&doSub("AUTHORITATIVE", $authoritative);
		&doSub('SESSION',$session);
		&printTemplate;
		
		# SCOPES
		###############
		opendir(SCOPES, $dhcpScopes) or print "Oh Crap! Somthing went wrong: $!<br>\n";

		while ($file = readdir SCOPES) {
			next if $file=~/^\./;
			push(@S,$file);
		}
		@ScopeRows;
		$scopeCount = @S;
		$q=0;
		foreach $s (@S) {
			$scopeName = $s;
			$scopeName =~ s/\.scope$//g;
			$q++;
			if ($q%2==1) { $class = "oddRow"; }
			else {$class = "evenRow";}

			open(SCOPE, "< $dhcpScopes/$s") or print "Oh Crap! Somthing went wrong: $!<br>\n";
			@ThisScope = <SCOPE>;
			close(SCOPE);
	
			foreach(@ThisScope) {
				next if $_ =~ /\{/;
				next if $_ =~ /\}/;

				# subnet 192.168.0.0 netmask 255.255.255.0 
				if($_ =~ /^subnet/) {
					($subnetK,$subnetV,$netmaskK,$netmaskV) = split(/\s/, $_);
				}	

				# range dynamic-bootp 192.168.0.200 192.168.0.250; 
				if($_ =~ /^range/) {
					($range1,$range2,$scopeStart,$scopeEnd) = split(/\s/, $_);
					$scopeStart =~ s/;//gi;
					$scopeStart =~ s/\"//gi;
					$scopeEnd =~ s/;//gi;
					$scopeEnd =~ s/\"//gi;
				}
				# option broadcast-address 192.168.0.255; 
				# option routers 192.168.0.1;
				# option domain-name "razdc.local";
				# option domain-name-servers 192.168.0.238;
				# option netbios-name-servers 192.168.0.238;
				# option time-offset -21600; 
				if($_ =~ /^option/) {
					if($_ =~ /broadcast-address/) { ($option,$key,$broadcast) = split(/\s/, $_);  }
					if($_ =~ /routers/) { ($option,$key,$gateway) = split(/\s/, $_);  }
					if($_ =~ /domain-name /) { ($option,$key,$domain) = split(/\s/, $_);  }
					if($_ =~ /domain-name-servers/) { ($option,$key,$DNS) = split(/\s/, $_); }
					if($_ =~ /netbios-name-servers/) { ($option,$key,$netbios) = split(/\s/, $_); }
					if($_ =~ /time-offset/)	{ ($option,$key,$offset) = split(/\s/, $_); }
					$broadcast =~ s/;//gi;
					$broadcast =~ s/\"//gi;
					$gateway =~ s/;//gi;
					$gateway =~ s/\"//gi;
					$domain =~ s/;//gi;
					$domain =~ s/\"//gi;
					$DNS =~ s/;//gi;
					$DNS =~ s/\"//gi;
					$netbios =~ s/;//gi;
					$netbios =~ s/\"//gi;
					$offset =~ s/;//gi;
					$offset =~ s/\"//gi;
				}
			}

			&getTemplate('scope_row');
			&doSub("SCOPENAME", $scopeName);
			&doSub("SCOPESTART", $scopeStart);
			&doSub("SCOPEEND", $scopeEnd);
			&doSub("SCOPECOUNT", $q);
			&doSub("THISSCOPE", $s);
			&doSub("CLASSNAME", $class);
			&doSub("SUBNETV", $subnetV);
			&doSub("NETMASKV", $netmaskV);
			&doSub("BROADCAST", $broadcast);
			&doSub("GATEWAY", $gateway);
			&doSub("DOMAIN", $domain);
			&doSub("DNS", $DNS);
			&doSub("NETBIOS", $netbios);
			&doSub("OFFSET", $offset);
			push(@ScopeRows, "$_");
			}
		
		&getTemplate('scope_table');
		&doSub("SCOPECOUNT", $scopeCount);
		&doSub("SCOPEROWS", "@ScopeRows");
		&printTemplate;
		
		# HOSTS
		###############
		opendir(HOSTS, $dhcpHosts) or print "Somthing went wrong: $!<br>\n";

		while ($file = readdir HOSTS) {
			next if $file=~/^\./;
			push(@H,$file);
        }
		@StaticRows;
		$hostCount = @H;
		$q=0;
		foreach $h (@H) {
			#	print "$h<br>\n";
			$hostName = $h;
			$hostName =~ s/\.host$//g;
			$q++;
			if ($q%2==1) { $class = "oddRow"; }
			else {$class = "evenRow";}
			open(HOST, "< $dhcpHosts/$h") or print "Oh Crap! Somthing went wrong: $!<br>\n";
			@ThisHost = <HOST>;
			close(HOST);

			foreach(@ThisHost) {
				next if $_ =~ /\{/;
				next if $_ =~ /\}/;
				# host dc2.razdc.co.us
				if($_ =~ /^host/) {
					($key,$StaticHost) = split(/\s/, $_);
                }
				# hardware ethernet 00:50:56:B1:1B:84;
				if($_ =~ /^hardware/) {
					($hardware,$ethernet,$MacAddress) = split(/\s/, $_);
				}
				# fixed-address 192.168.0.238;
				if($_ =~ /^fixed-address/) {
					($fa,$StaticIP) = split(/\s/, $_);
				}
			}

			$StaticHost =~ s/;//gi;
			$StaticHost =~ s/\"//gi;
			$MacAddress =~ s/;//gi;
			$MacAddress =~ s/\"//gi;
			$StaticIP =~ s/;//gi;
			$StaticIP =~ s/\"//gi;

			&getTemplate('static_row');
			&doSub("CLASSNAME", $class);
			&doSub("STATICHOST", $StaticHost);
			&doSub("STATICMAC", $MacAddress);
			&doSub("STATICIP", $StaticIP);
			&doSub("HOSTID", $h);
			push(@StaticRows, "$_");
		}
		
		&getTemplate('static_table');
		&doSub("HOSTCOUNT", $hostCount);
		&doSub("STATICROWS", "@StaticRows");
		&printTemplate;
	}
sub dhsave { 

	&runCmd("sudo echo '' > $settings->{'system'}->{'dhcp'}->{'options'}"); #CLEAR options.conf /razdc/DHCP/conf/options.conf;
	&runCmd("sudo echo 'option domain-name $domain;' >> $settings->{'system'}->{'dhcp'}->{'options'}"); #/razdc/DHCP/conf/options.conf;

	$allDNS = join(',', @DomainNameServers);
	$allNNS = join(',', @NetbiosNameServers);

	&runCmd("sudo echo 'option domain-name-servers $allDNS;' >> $settings->{'system'}->{'dhcp'}->{'options'}"); #/razdc/DHCP/conf/options.conf;
	&runCmd("sudo echo 'option netbios-name-servers $allNNS;' >> $settings->{'system'}->{'dhcp'}->{'options'}"); #/razdc/DHCP/conf/options.conf;
	&runCmd("sudo echo 'default-lease-time $defaultleasetime;' >> $settings->{'system'}->{'dhcp'}->{'options'}"); #/razdc/DHCP/conf/options.conf;
	&runCmd("sudo echo 'max-lease-time $maxleasetime;' >> $settings->{'system'}->{'dhcp'}->{'options'}"); #/razdc/DHCP/conf/options.conf;

	if($authoritative == 'authoritative') { 
		&runCmd("sudo echo 'authoritative;' >> $settings->{'system'}->{'dhcp'}->{'options'}"); #/razdc/DHCP/conf/options.conf`;
	}

		$dhcpOptions = $settings->{'system'}->{'dhcp'}->{'options'};
		$dhcpHosts = $settings->{'system'}->{'dhcp'}->{'hostdir'};
		$dhcpScopes = $settings->{'system'}->{'dhcp'}->{'scopedir'};
		$authoritative = "false";
		open(dhcpOptions, "< $dhcpOptions") or print "Error: $!.\n";
		@dhcpOptions =  <dhcpOptions>;
		close(dhcpOptions);
		# Define globals
		@DomainNameServers=();
		@NetbiosNameServers=();
		foreach $line (@dhcpOptions) {
			#print "$line<br>\n";
			$line =~ s/^option\s//gi;
			$line =~ s/;//gi;
			$line =~ s/\"//gi;
			if($line =~ /\s/g && $line !~ /authoritative/ && $line !~ /^\s+?$/) {
				($k,$v) = split(/\s/, $line);
				$k =~ s/-//gi;

				if($k =~ /domainnameservers/) {
					#print "DNS: $k,$v<br>\n";
					if($v =~ /,/) {
						#print "Multiple DNS Found!<br>\n";
						(@DNSServer) = split(/,/, $v);
						foreach $dhcpGlobalDNS (@DNSServer) {
							push(@DomainNameServers, $dhcpGlobalDNS);
						}
					}
					else { #print "Single DNS Found!<br>\n"; 
						push(@DomainNameServers, $v); 
					}
				}

				if($k =~ /netbiosnameservers/) {
					#print "NNS: $k,$v<br>\n";
					if($v =~ /,/) {
						#print "Single NNS Found!<br>\n";
						(@NNSServer) = split(/,/, $v);
						foreach $dhcpGlobalNNS (@NNSServer) {
							push(@NetbiosNameServers, $dhcpGlobalNNS);
						}
					}
					else { #print "Single NNS Found!<br>\n"; 
						push(@NetbiosNameServers, $v);
					}
                }
				else {
					${$k} = $v;
				}
			}
	
			if($line =~ /authoritative/gi) {
				$authoritative = "true";
			}
		}

		$nscount=0;
		@NSNameServers;
		foreach $dnsip (@DomainNameServers) {
			&getTemplate('dhcp_dns_server');
			&doSub("DHDNSCOUNT", "domainnameservers$nscount");
			&doSub("DHDNSENTRY", $dnsip);
			push(@NSNameServers, $_);
			$nscount++;
		}

		$winscount=0;
		@NBNameServers;
		foreach $nnsip (@NetbiosNameServers) {
			&getTemplate('dhcp_wins_server');
			&doSub("DHWINSCOUNT", "netbiosnameservers$winscount");
			&doSub("DHWINSENTRY", $nnsip);
			push(@NBNameServers, $_);
			$winscount++;
		}
		
		&getTemplate('dhcp_global');
		&doSub("DHDOMAINNAME", $domainname);
		&doSub("DHDNSSERVERS", "@NSNameServers");
		&doSub("DHDNSCOUNT", "domainnameservers$nscount");
		&doSub("DHWINSSERVERS", "@NBNameServers");
		&doSub("DHWINSCOUNT", "netbiosnameservers$winscount");
		&doSub("DEFAULTLEASETIME", $defaultleasetime);
		&doSub("MAXLEASETIME", $maxleasetime);
		&doSub("AUTHORITATIVE", $authoritative);
		&doSub('SESSION',$session);
		&printTemplate;

	}
sub findip { # FUTURE OPTION TO OPEN AND DELETE INDIVIDUAL LEASES INCOMPLETE - ALSO NEED HTML TEMPLATE!
	&ParseDHCPLeases();
	($sortref, $dataref) = @_; 		# have to pass as a referece

		@sorted = @$sortref;			# dereference for sanity
		if ($dataref) {
			our %data = %$dataref;		# "                       "
		}
		
	$ip = $findip;
	chomp($ip);
	print "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"padding-left:5px;width:400px;\">\n";
	print "<tr><td><b>IP:</b></td><td>$ip</td></tr>\n";
	print "<tr><td><b>MAC:</b></td><td>".$lease{$ip}{"hardware"}."</td></tr>\n";
	$lease{$ip}{"client-hostname"} =~ s/"//ge;
	print "<tr><td><b>Name:</b></td><td> &nbsp; ".$lease{$ip}{"client-hostname"}."</td></tr>";
	print "<tr><td><b>Starts:</b></td><td>"; 	
	&parsedate($lease{$ip}{"starts"});
	print "</td></tr>\n";
	print "<tr><td><b>Ends:</b></td><td>"; 
	&parsedate($lease{$ip}{"ends"});
	print "</td></tr>\n";
	print "</table>";	
	print "FIND IP: $findip<br>\n";
		&getTemplate('dhfindip');
		&doSub("DHDOMAINNAME", $domainname);
		&doSub("DHDNSSERVERS", "@NSNameServers");
		&doSub("DHDNSCOUNT", "domainnameservers$nscount");
		&doSub("DHWINSSERVERS", "@NBNameServers");
		&doSub("DHWINSCOUNT", "netbiosnameservers$winscount");
		&doSub("DEFAULTLEASETIME", $defaultleasetime);
		&doSub("MAXLEASETIME", $maxleasetime);
		&doSub("AUTHORITATIVE", $authoritative);
		&doSub('SESSION',$session);
		&printTemplate;
	}
sub dhclient { 
		&ParseDHCPLeases();
		&PrintEntries(\@ips);
	}
sub savescope { 
		$dhcpScopes = $settings->{'system'}->{'dhcp'}->{'scopedir'};
		$scopesConf = $settings->{'system'}->{'dhcp'}->{'scopeconf'};
										
		#print"$scopename, $scopenetwork, $scopemask, $scoperange, $scopebroadcast, $scoperouter, $scopedomain, $scopedns, $scopewins, $scopetime<br>\n";
		if($scopename && $scopenetwork && $scopemask && $scoperange && $scopebroadcast) {
			$scopename =~ s/\s//g;
			open(SCOPES, "> $dhcpScopes/$scopename.scope") or print "Failed to open $scopename.scope: $!<br>\n";

			$scoperange =~ s/\R/ /g;

			print SCOPES qq|subnet $scopenetwork netmask $scopemask\n|;
			print SCOPES qq|{\n|;
			print SCOPES qq|range dynamic-bootp $scoperange;\n|;
			print SCOPES qq|option broadcast-address $scopebroadcast;\n|;

			if($scoperouter) 	{ print SCOPES qq|option routers $scoperouter;\n|; }
			if($scopedomain) 	{ print SCOPES qq|option domain-name "$scopedomain";\n|; }
			if($scopedns) 	{ print SCOPES qq|option domain-name-servers $scopedns;\n|; }
			if($scopewins) 	{ print SCOPES qq|option netbios-name-servers $scopewins;\n|; }
			if($scopetime) 	{ print SCOPES qq|option time-offset $scopetime;\n|; }
			print SCOPES qq|}|;
			close(SCOPES);

			opendir(HOSTS, $dhcpScopes) or print "Oh Crap! Somthing went wrong: $!<br>\n";

			while ($file = readdir HOSTS) {
				next if $file=~/^\./;
				push(@H,$file);
			}

			open(CONF, "> $scopesConf") or print "Oh Crap! Somthing went wrong: $!<br>\n";
				foreach(@H) {
					print CONF "include \"/razdc/DHCP/scopes/$_\";\n";
				}
			close(CONF);
			$msg = "Scope Saved.";
		}

		else {
			$msg = "No blank fields!";
		}
		
		&getTemplate('genericwin');
		&doSub("GENERICDATA", $msg);
		&printTemplate;
	}
sub newscope { 
		&getTemplate('new_scope');
		&doSub('SESSION',$session);
		&printTemplate;
	}
sub delscope { 
		$dhcpScopes = $settings->{'system'}->{'dhcp'}->{'scopedir'};
		$scopesConf = $settings->{'system'}->{'dhcp'}->{'scopeconf'};

		if($scope) { 
			unlink("$dhcpScopes/$scope") or print "Error: $!<br>"; 
			$msg = "Scope deleted!";
			opendir(HOSTS, $dhcpScopes) or print "Somthing went wrong: $!<br>\n";

			while ($file = readdir HOSTS) {
				next if $file=~/^\./;
				push(@H,$file);
			}

			open(CONF, "> $scopesConf") or print "Somthing went wrong: $!<br>\n";
			foreach(@H) {
				print CONF "include \"$dhcpScopes/$_\";\n";
			}
			close(CONF);
			}

		else {
			$msg = "Scope was empty.. what happened? this shouldn't be possible!";
		}


		&getTemplate('genericwin');
		&doSub(GENERICDATA, $msg);
		&printTemplate;

	}
sub savestatic {
		$dhcpHosts = $settings->{'system'}->{'dhcp'}->{'hostdir'}; 
		$hostsConf = $settings->{'system'}->{'dhcp'}->{'hostconf'}; 

		#Host, StaticIP, MACAddress

		if($Host && $StaticIP && $MACAddress) {
			open(HOSTS, "> $dhcpHosts/$Host.host") or print "Failed to open $Host.scope: $!<br>\n";
print HOSTS qq|
host $Host
{
hardware ethernet $MACAddress;
fixed-address $StaticIP;
}
|;
			$msg = "Host Saved.";
			opendir(HOSTS, $dhcpHosts) or print "Oh Crap! Somthing went wrong: $!<br>\n";
			while ($file = readdir HOSTS) {
				next if $file=~/^\./;
				push(@H,$file);
				}

			open(CONF, "> $hostsConf") or print "Oh Crap! Somthing went wrong: $!<br>\n";
			foreach(@H) {
				print CONF "include \"$dhcpHosts/$_\";\n";
			}
			close(CONF);
		}

		else {
			$msg = "No blank fields!";
		}

		&getTemplate('genericwin');
		&doSub(GENERICDATA, $msg);
		&printTemplate;
	}
sub newstatic { 
		&getTemplate('new_static');
		&doSub('SESSION',$session);
		&printTemplate;
	}
sub delstatic {
		$dhcpHosts = $settings->{'system'}->{'dhcp'}->{'hostdir'};
		$hostConf = $settings->{'system'}->{'dhcp'}->{'hostconf'};

		if($host) {
			unlink("$dhcpHosts/$host") or print "Error: $!<br>"; 
			$msg = "Host deleted!";
			opendir(HOSTS, $dhcpHosts) or print "Oh Crap! Somthing went wrong: $!<br>\n";

			while ($file = readdir HOSTS) {
				next if $file=~/^\./;
				push(@H,$file);
	        }

			open(CONF, "> $hostConf") or print "Oh Crap! Somthing went wrong: $!<br>\n";
			foreach(@H) {
				print CONF "include \"$dhcpHosts/$_\";\n";
			}
			close(CONF);
		}
		else {
			$msg = "Host was empty.. This shouldn't be possible..";
		}
		&getTemplate('genericwin');
		&doSub(GENERICDATA, $msg);
		&printTemplate;
	}
sub nsoptions { 
		%nsOptions;
		@NSROWS;
		$optionfile = $settings->{'system'}->{'dns'}->{'options'};
		
		open(OPTIONS, "< $optionfile") or print "Failed to open file: $!\n";
		@OPTIONS = <OPTIONS>;
		close(OPTIONS);

		$count = 0;
		foreach $line (@OPTIONS) {
			if($line !~ /^\/\//) {
				#($key,$val) = split(/ /, $line);
				$nsOptions{$count} = "$line";
				$count++;
			}
		}

		for $key ( sort {$a<=>$b} keys %nsOptions) {
			# This staggers line color if bassing [!CLASS!] in template
			#if ($key%2==1) { $class = "background:#FFF;"; }
			#else {$class = "background:#C6C6C6;";}

			($k,$v) = split(/ /,$nsOptions{$key});
			$v =~ s/"//g;
			$v =~ s/;//g;
			$formatk = $k;
			$kname = $k;
			$kname =~ s/-//g;
			$formatk =~ s/-/ /g;
			$formatk =~ s/(\w+)/\u\L$1/g;

			&getTemplate('dnsoption_row');
			&doSub("NSKFORMAT", $formatk);
			&doSub("KEY", $k);
			&doSub("KNAME", $kname);
			&doSub("VALUE", $v);
			push(@NSROWS, "$_");
		}

		&getTemplate('dns_options');
		&doSub("NSDATA", "@NSROWS");
		&doSub("SESSION", $session);
		&printTemplate;
	}
sub save_ns { 
	$optionfile = $settings->{'system'}->{'dns'}->{'options'};
	open(OPTIONS, "> $optionfile") or print "Failed to open file: $!\n";
	print OPTIONS qq~directory "$directory";\n~;
	print OPTIONS qq~dump-file "$dumpfile";\n~;
	print OPTIONS qq~statistics-file "$statisticsfile";\n~;
	print OPTIONS qq~memstatistics-file "$memstatisticsfile";\n~;
	print OPTIONS qq~recursion $recursion;\n~;
	print OPTIONS qq~notify $notify;\n~;
	print OPTIONS qq~dnssec-enable $dnssecenable;\n~;
	print OPTIONS qq~dnssec-validation $dnssecvalidation;\n~;
	print OPTIONS qq~dnssec-lookaside $dnsseclookaside;\n~;
	print OPTIONS qq~bindkeys-file "$bindkeysfile";\n~;
	print OPTIONS qq~managed-keys-directory "$managedkeysdirectory";\n~;
	close(OPTIONS);

	$msg = "Settings Saved!<br>\n";
	# print message
	# reload nsoptions form by calling the nsoptions submenu function:
	#&submenu('nsoptions');
	&getTemplate('genericwin');
	&doSub("GENERICDATA", $msg);
	&printTemplate;
}
sub intns {
		$resolvFile = $settings->{'system'}->{'dns'}->{'resolv'};
		@GLOBALNS;
		@DNS_DATA = &runCmd("cat $resolvFile");

		#(@DNS_DATA) = split(/\\r\\n/, $DNS_DATA);
		foreach $line (@DNS_DATA) {
			#print "Line: $line<br>\n";
			if($line =~ m/search/) { 
				$search = $line;
				$search =~ s/search //gi;
				$search =~ tr/\015//d;
			}
			if($line =~ m/nameserver/) { 
				$dns = $line;
				$dns =~ s/nameserver //gi;
				$dns =~ tr/\015//d;
				$dns =~ s/\\s//g;
				$dns =~ s/;//g;
				chomp($dns);
				push(@GLOBALNS, $dns);
			}
		}
		
		chomp($search);
		
		$GLOBALNS = join('&#13;&#10;',@GLOBALNS);
		
		if(@_) {
			$mesg = "@_";
		}
		else {
			$mesg = "";
		}
		&getTemplate('internal_dns');
		&doSub('MESG', $mesg);
		&doSub('DOMAIN', $search);
		&doSub('NAMESERVERS', $GLOBALNS);
		&doSub('SESSION', $session);
		&printTemplate;
	}
sub save_intns {
	$resolvFile = $settings->{'system'}->{'dns'}->{'resolv'};
	(@NS) = split(/\s/, $nameservers);
	foreach(@NS) {
		$verified = &verifyIP($_);
    }
	&runCmd("chmod 0777 $resolvFile");

	open(INTNS, "> $resolvFile" ) or print "Unable to edit resolv: $!<br>\n";
	if($search) {
		print INTNS "search $search\n";
	}
	foreach(@NS) {
		print INTNS "nameserver $_;\n";
	}
	close(INTNS);
	
	$mesg = "Settings Saved. Restarting DNS service for changes to take effect.<br>";
	&runCmd("systemctl restart named.service");
	&intns($mesg);
}	
sub forward { 
	$forwardFile = $settings->{'system'}->{'dns'}->{'forwarders'};
	@GLOBALFORWARD;
	@DNS_FWD = &runCmd("sudo cat $forwardFile");

	foreach $line (@DNS_FWD) {
		next if $line =~ m/forwarders/;
		next if $line =~ m/\{/;
		next if $line =~ m/}/;
		$line =~ s/;//g;
		$line =~ tr/\015//d;
		$line =~ s/\\s//g;
		chomp($line);
		push(@GLOBALFORWARD, $line);
	}
	$GLOBALFORWARD = join('&#13;&#10;',@GLOBALFORWARD);
	
	if(@_) {
		$mesg = "@_";
	}
	else {
		$mesg = "";
	}
	&getTemplate('dns_forwarders');
	&doSub('MESG', $mesg);
	&doSub('DOMAIN', $search);
	&doSub('NAMESERVERS', $GLOBALFORWARD);
	&doSub('SESSION', $session);
	&printTemplate;
}
sub save_forward {
	$forwardFile = $settings->{'system'}->{'dns'}->{'forwarders'};
	(@NS) = split(/\s/, $nameservers);
	foreach(@NS) {
		$verified = &verifyIP($_);
    }
	&runCmd("sudo echo 'forwarders {' > $forwardFile");
	foreach(@NS) { &runCmd("sudo echo '$_;' >> $forwardFile"); }
	&runCmd("sudo echo '};' >> $forwardFile");
	$mesg = "Settings Saved.<br>";
	&forward($mesg);
}
sub recurse {
	$recursionFile = $settings->{'system'}->{'dns'}->{'recursion'};
	@GLOBALCLIENTS;
	@RECURSION = &runCmd("sudo cat $recursionFile");
	foreach $line (@RECURSION) {
		next if $line =~ m/allow-recursion/;
		next if $line =~ m/\{/;
		next if $line =~ m/}/;
		$line =~ s/;//g;
		$line =~ tr/\015//d;
		$line =~ s/\\s//g;
		chomp($line);
		push(@GLOBALCLIENTS, $line);
	}
	$GLOBALCLIENTS = join('&#13;&#10;',@GLOBALCLIENTS);
	
	if(@_) {
		$mesg = "@_";
	}
	else {
		$mesg = "";
	}
	&getTemplate('dns_recursion');
	&doSub('MESG', $mesg);
	&doSub('NAMESERVERS', $GLOBALCLIENTS);
	&doSub('SESSION', $session);
	&printTemplate;
}
sub save_recurse {
	$recurseFile = $settings->{'system'}->{'dns'}->{'recursion'};
	(@NS) = split(/\s/, $nameservers);
	foreach(@NS) {
		next if $_ =~ m/any/;
		$verified = &verifyIP($_);
    }
	&runCmd("sudo echo 'allow-recursion {' > $recurseFile");
	foreach(@NS) { &runCmd("sudo echo '$_;' >> $recurseFile"); }
	&runCmd("sudo echo '};' >> $recurseFile");
	$mesg = "Settings Saved.";
	&recurse($mesg);
}
sub trans {
	$axfrFile = $settings->{'system'}->{'dns'}->{'axfr'};
	@GLOBALAXFR;
	@AXFR = &runCmd("sudo cat $axfrFile");
	foreach $line (@AXFR) {
		next if $line =~ m/allow-transfer/;
		next if $line =~ m/\{/;
		next if $line =~ m/}/;
		$line =~ s/;//g;
		$line =~ tr/\015//d;
		$line =~ s/\\s//g;
		chomp($line);
		push(@GLOBALAXFR, $line);
	}
	$GLOBALAXFR = join('&#13;&#10;',@GLOBALAXFR);
	
	if(@_) {
		$mesg = "@_";
	}
	else {
		$mesg = "";
	}	
	&getTemplate('dns_transfers');
	&doSub('MESG', $mesg);
	&doSub('NAMESERVERS', $GLOBALAXFR);
	&doSub('SESSION', $session);
	&printTemplate;
}
sub save_trans {
	$axfrFile = $settings->{'system'}->{'dns'}->{'axfr'};
	(@NS) = split(/\s/, $nameservers);
	foreach(@NS) {
		next if $_ =~ m/any/;
		$verified = &verifyIP($_);
    }
	&runCmd("sudo echo 'allow-transfer {' > $axfrFile");
	foreach(@NS) { &runCmd("sudo echo '$_;' >> $axfrFile"); }
	&runCmd("sudo echo '};' >> $axfrFile");
	$mesg = "Settings Saved.";
	&trans($mesg);
}
sub flush { # NEED FLUSH COMMAND IN CONFIG.JSON IN FUTURE!
	@flush = &runCmd("sudo rndc flush");
	$flush = "@flush";
	&getTemplate('genericwin');
	&doSub("GENERICDATA",'DNS Cache Has been cleared.');
	&printTemplate;
}
sub email { # FUTURE - SMTP FOR BACKUPS AND REPORTS
		&getTemplate('log_settings');
		&printTemplate;
	}
sub seclog { 
		$log_path = $settings->{'system'}->{'logs'}->{'secure'}->{'path'};
		$log_cmd = $settings->{'system'}->{'logs'}->{'secure'}->{'cmd'};
		@log_data = &runCmd("$log_cmd $log_path");
		foreach $line (@log_data) {
			$line =~ s/\\n/<br>/g;
		}
		&getTemplate('view_logs');
		&doSub("VIEW_LOG", "@log_data");
		&printTemplate;
	}
sub errlog { 
		$log_path = $settings->{'system'}->{'logs'}->{'error'}->{'path'};
		$log_cmd = $settings->{'system'}->{'logs'}->{'error'}->{'cmd'};
		@log_data = &runCmd("$log_cmd $log_path");
		foreach $line (@log_data) {
			$line =~ s/\\n/<br>/g;
		}
		&getTemplate('view_logs');
		&doSub("VIEW_LOG", "@log_data");
		&printTemplate;
	}
sub cmdlog { # ADD CMD LOG AND PATH TO CONFIG
		$log_path = '/razdc/log/cmd.log';
		@log_data = &runCmd("sudo tail -100 $log_path");
		foreach $line (@log_data) {
			$line =~ s/\\n/<br>/g;
		}
		&getTemplate('view_logs');
		&doSub("VIEW_LOG", "@log_data");
		&printTemplate;
}
sub acclog { 
		$log_path = $settings->{'system'}->{'logs'}->{'access'}->{'path'};
		$log_cmd = $settings->{'system'}->{'logs'}->{'access'}->{'cmd'};
		@log_data = &runCmd("$log_cmd $log_path");
		foreach $line (@log_data) {
			$line =~ s/\\n/<br>/g;
		}
		&getTemplate('view_logs');
		&doSub("VIEW_LOG", "@log_data");
		&printTemplate;
	}
sub smblog { 
		#SAMBA LOGS
		$log_path = $settings->{'system'}->{'logs'}->{'samba'}->{'path'};
		$log_cmd = $settings->{'system'}->{'logs'}->{'samba'}->{'cmd'};
		@log_data = &runCmd("$log_cmd $log_path");

		$log_path2 = $settings->{'system'}->{'logs'}->{'smbd'}->{'path'};
		$log_cmd2 = $settings->{'system'}->{'logs'}->{'smbd'}->{'cmd'};
		@log_data2 = &runCmd("$log_cmd2 $log_path2");

		&getTemplate('view_logs');
		&doSub("VIEW_LOG", "Samba Logs:\n\n @log_data\n\n SMBD Logs:\n\n  @log_data2");
		&printTemplate;
	}
sub replog { 
		$log_cmd = $settings->{'system'}->{'logs'}->{'replication'}->{'cmd'};
		@log_data = &runCmd("$log_cmd");
		foreach $line (@log_data) {
			$line =~ s/\\n/<br>/g;
		}
		&getTemplate('view_logs');
		&doSub("VIEW_LOG", "@log_data");
		&printTemplate;
	}
sub bootlog { 
		$log_path = $settings->{'system'}->{'logs'}->{'boot'}->{'path'};
		$log_cmd = $settings->{'system'}->{'logs'}->{'boot'}->{'cmd'};
		@log_data = &runCmd("$log_cmd $log_path");
		foreach $line (@log_data) {
			$line =~ s/\\n/<br>/g;
		}
		&getTemplate('view_logs');
		&doSub("VIEW_LOG", "@log_data");
		&printTemplate;
	}
sub dmesg { 
		$log_path = $settings->{'system'}->{'logs'}->{'dmesg'}->{'path'};
		$log_cmd = $settings->{'system'}->{'logs'}->{'dmesg'}->{'cmd'};
		@log_data = &runCmd("$log_cmd $log_path");
		foreach $line (@log_data) {
			$line =~ s/\\n/<br>/g;
		}
		&getTemplate('view_logs');
		&doSub("VIEW_LOG", "@log_data");
		&printTemplate;
	}
sub mesglog { 
		$log_path = $settings->{'system'}->{'logs'}->{'message'}->{'path'};
		$log_cmd = $settings->{'system'}->{'logs'}->{'message'}->{'cmd'};
		@log_data = &runCmd("$log_cmd $log_path");
		foreach $line (@log_data) {
			$line =~ s/\\n/<br>/g;
		}
		&getTemplate('view_logs');
		&doSub("VIEW_LOG", "@log_data");
		&printTemplate;
	}
sub updatelog { # Need to sort by revision # Need to use runCmd fix output
	$max = 100;
	$linecount = 0;
	$newrecord = 0;

	$svnrepo = $svn->{$settings->{'svn'}}->{'url'};
	$svnuser = $svn->{$settings->{'svn'}}->{'svnuser'};
	$svnpass = $svn->{$settings->{'svn'}}->{'svnpass'};
	$svnpath = $svn->{$settings->{'svn'}}->{'svnpath'};
	$svnrepo =~ s/=>/:/g;
	
	$log_data_xml = `svn log $svnpath --xml --username $svnuser --password $svnpass --non-interactive --trust-server-cert --no-auth-cache`;
	
	@lines = split(/\n/,$log_data_xml);
	

	foreach $line (@lines)  {
		chomp $line;
		#print "$LINE: $line<br>";
		# break down the file into seperate records using the <logentry> tag
		if ($line =~ /\<logentry/i){
			$linecount++;
			$newrecord = 1;
		}
		if ($line =~ /\<\/logentry\>/i){$newrecord = 0;}

		# Add to record:
		if ($newrecord == 1){$LINE{$linecount} = "$LINE{$linecount} $line";}
	}
		# Parse the record and display:
	foreach $linecount (sort keys %LINE) {
		if($linecount < $max+1) {

		$revision = "";
		$author = "";
		$date = "";
		$msg = "";

		# get each field
		if ($LINE{$linecount} =~ /revision="(.*)">/i){$revision = $1;}
		if ($LINE{$linecount} =~ /<author>(.*)<\/author>/i){$author = $1;}
		if ($LINE{$linecount} =~ /<date>(.*)<\/date>/i){$date = $1;}
		if ($LINE{$linecount} =~ /<msg>(.*)<\/msg>/i){$msg = $1;}
	
		#print "<span align=\"left\" class=\"barColor\">$revision - $date</span><div>Comment:<br>$msg</div><br>\n";
		&getTemplate('update_log');
		&doSub("LOGVERSION", "$revision");
		&doSub("LOGSTAMP", "$date");
		&doSub("LOGCOMMENT", "$msg");
		&printTemplate;
		}
	}
}
sub shutdown { 
		&getTemplate('shutdown');
		&doSub("SESSION", $session);
		&printTemplate;
	}
sub power_shutdown { 
		$mesg = "Performing powering down.";
		&getTemplate('genericwin');
		&doSub("GENERICDATA", $mesg);
		&printTemplate;
		&runCmd("$settings->{'system'}->{'power'}->{'shutdown'}");
	}
sub restart { 
		&getTemplate('restart');
		&doSub("SESSION", $session);
		&printTemplate;
	}
sub power_restart { 
		$mesg = "Performing reboot.";
		&getTemplate('genericwin');
		&doSub("GENERICDATA", $mesg);
		&printTemplate;
		&runCmd("$settings->{'system'}->{'power'}->{'restart'}");
	}
sub newdc { 
		&getTemplate('preview');
		doSub("HOST", "$netInfo{'HOST'}");
		doSub("FQDN", "$netInfo{'FQDN'}");
		doSub("DOMAIN", "$netInfo{'DOMAIN'}");
		doSub("REALM", "$netInfo{'REALM'}");
		doSub("IPADDR", "$netInfo{'IPADDR'}");
		doSub("NETMASK", "$netInfo{'NETMASK'}");
		doSub("GATEWAY", "$netInfo{'GATEWAY'}");
		doSub("NAMESERVERS", "$netInfo{'NAMESERVERS'}");
		doSub("SESSION", $session);
		&printTemplate;

		&getTemplate('newdc');
		doSub("DOMAIN", "$netInfo{'DOMAIN'}");
		doSub("REALM", "$netInfo{'REALM'}");
		doSub("IPADDR", "$netInfo{'IPADDR'}");
		doSub("SESSION", $session);
		&printTemplate;
	}
sub olddc { 
		&getTemplate('preview');
		doSub("HOST", "$netInfo{'HOST'}");
		doSub("FQDN", "$netInfo{'FQDN'}");
		doSub("DOMAIN", "$netInfo{'DOMAIN'}");
		doSub("REALM", "$netInfo{'REALM'}");
		doSub("IPADDR", "$netInfo{'IPADDR'}");
		doSub("NETMASK", "$netInfo{'NETMASK'}");
		doSub("GATEWAY", "$netInfo{'GATEWAY'}");
		doSub("NAMESERVERS", "$netInfo{'NAMESERVERS'}");
		doSub("SESSION", $session);
		&printTemplate;

		&getTemplate('olddc');
		doSub("DOMAIN", "$netInfo{'DOMAIN'}");
		doSub("REALM", "$netInfo{'REALM'}");
		doSub("IPADDR", "$netInfo{'IPADDR'}");
		doSub("SESSION", $session);
		&printTemplate;	
	}
sub setup_back {
		&getTemplate('setup_data');
		doSub("SESSION", $session);
		&printTemplate;
	}
sub userPasswd {
		&getTemplate('userPassword');
		&doSub('UNIXUSERNAME',$Unixusername);
		&doSub('SESSION',$session);
		&printTemplate;
	}
sub setUserPass {	
	$pdbedit = $settings->{'system'}->{'samba'}->{'pdbedit'};
	if($userpassword eq $userpassword2) {
        @update = `echo '$userpassword\n$userpassword\n' | sudo $pdbedit -a $Unixusername`;
		if($wsConnected == 1) {
			$client->write("::TRM::Command: Setting password for $Unixusername (Command hidden for security)");
		}
		$update = "@update";
		if($update =~ m/SID/) {
			$message = "$Unixusername password has been updated.";	
		}
		else {
			$message = "Error occured updating password.";
		}
	}
	else {
		$message = "Passwords do not match";
	}

	&getTemplate('genericwin');
	&doSub('GENERICDATA', $message);
	&printTemplate;
}
sub newUser {
		&getTemplate('newUser');
		&doSub('SESSION',$session);
		&printTemplate;
	}
sub deleteUser {
		&getTemplate('deleteUser');
		&doSub('UNIXUSERNAME',$Unixusername);
		&doSub('SESSION',$session);
		&printTemplate;
	}
sub deleteUserConfirm {
		if($userConfirmDelete eq 'DELETE') {
			$pdbedit = $settings->{'system'}->{'samba'}->{'pdbedit'};
			$delOutput = &runCmd("sudo $pdbedit -u $Unixusername -x 2>&1 1>/dev/null");
			&getTemplate('createUser');
			&doSub('MESSAGE', "User has been deleted.");
			&printTemplate;
		}
		else {
			$message = "Confirmation failed - Confirmation code is case sensitive.";
			&getTemplate('genericwin');
			&doSub('GENERICDATA', $message);
			&printTemplate;
		}
	}
sub delfile {
	if($filename && $callback) {
		$temp_dir="/razdc/tmp";
		unlink("$temp_dir/$filename");
	}
	else {
		print "File: $filename<br>";
		print "Callback: $callback<br>";
	}
	if($callback) {
		&{$callback};
	}
	else {
		print "No callback found!";
		#&login;
	}
}
sub importUsers { 
		$temp_dir = '/razdc/tmp';
		if($temp_dir) {
			$dir = "$temp_dir";
			opendir(DIR, $dir) or print "Can't open directory $dir: $!\n";
			$i=0;
			$formid = "importForm$i";
			while ($file = readdir(DIR)) {
				next if $file=~/^\./;
				if($file =~ /^ImportUsersFile/) {
					&getTemplate('importItem');
					&doSub('FILENAME', $file);
					&doSub('SESSION', $session);
					&doSub('FORMID', $formid);
					push(@IMPORTFILES , $_);
					$i++;
				}
			}
		}
		if(!@IMPORTFILES) { push(@IMPORTFILES, "No user files found."); }
		&getTemplate('importUsers');
		&doSub('IMPORTFILES', "@IMPORTFILES");
		&doSub('SESSION',$session);
		&printTemplate;	
}
sub completeImport {
	$temp_dir = '/razdc/tmp';
	$stamp = &getStamp;
	$ImportFile = "ImportUsersFile-$stamp.csv";
	if(-e "$temp_dir/temp.file") {
		chmod(0755," $temp_dir/temp.file");
		rename("$temp_dir/temp.file", "$temp_dir/$ImportFile") or print "Error renaming: $!<br>\n";
	}
	&importUsers;	
}
sub import {
	print "Running import..<br>\n";
	
	$temp_dir = "/razdc/tmp";
	if(-e "$temp_dir/$filename") {
		open(FH, '<', "$temp_dir/$filename") or print "Error accessing file for import: $!<br>\n";
		while(<FH>){
			#print $_;
			(@cols) = split(/,/, $_);
			 &runCmd("sudo $samba_tool user create $cols[0] --random-password");
		}
		close(FH);
	}
	else {
		print "Error locating file for import: $!<br>\n";
	}
	print "Import complete.<br>\n";
	&importUsers;
}
sub export { 
		# Need to update JSON to have TEMP path:
		#$settings->{'system'}->{'temp'};
		$temp_dir = '/razdc/tmp';
		if($temp_dir) {
			$i=0;
			$formid = "exportForm$i";
			$dir = "$temp_dir";
			opendir(DIR, $dir) or print "Can't open directory $dir: $!\n";
			while ($file = readdir(DIR)) {
				next if $file=~/^\./;
				if($file =~ /^UserFile/) {
					&getTemplate('fileItem');
					&doSub('FILENAME', $file);
					&doSub('SESSION', $session);
					&doSub('FORMID', $formid);
					push(@USERFILES , $_);
					$i++;
				}
				if($file =~ /^ComputerFile/) {
					&getTemplate('fileItem');
					&doSub('FILENAME', $file);
					&doSub('SESSION', $session);
					&doSub('FORMID', $formid);
					push(@MACHINEFILES , $_);
					$i++;
				}
			}
		}
		if(!@USERFILES) { push(@USERFILES, "No user files found."); }
		if(!@MACHINEFILES) { push(@MACHINEFILES, "No computer files found."); }
		
		&getTemplate('export');
		&doSub('USERLIST', "@USERFILES");
		&doSub('PCLIST', "@MACHINEFILES");
		&doSub('SESSION',$session);
		&printTemplate;	
}
sub exportUsers { # move temp path to JSON config in future
		
		# Need to update JSON to have TEMP path:
		#$settings->{'system'}->{'temp'};
		$temp_dir = '/razdc/tmp';
		$stamp = &getStamp;
		$UserFile = "$temp_dir/UserFile-$stamp.csv";
		$UserOutput = &runCmd("sudo $samba_tool user list > $UserFile");
		&export;
}
sub exportPCs { # move temp path to JSON config in future
		
		# Need to update JSON to have TEMP path:
		#$settings->{'system'}->{'temp'};
		$temp_dir = '/razdc/tmp';
		$stamp = &getStamp;
		$MachineFile = "$temp_dir/ComputerFile-$stamp.csv";
		$MachineOutput = &runCmd("sudo $samba_tool computer list > $MachineFile");
		&export;
}
sub editGroup { 
	@groups = &runCmd("sudo $samba_tool group list");
	@userGroups = &runCmd("sudo $samba_tool user getgroups $Unixusername");
	foreach $item (@groups) {
		$item = "<option value='$item'>$item</option>";
	}
	foreach $uitem (@userGroups) {
		$uitem = "<option value='$uitem'>$uitem</option>";
	}
	&getTemplate('userGroups');
	&doSub('UNIXUSERNAME', $Unixusername);
	&doSub('ALLGROUPS', "@groups");
	&doSub('USERGROUPS', "@userGroups");
	&doSub('SESSION', $session);
	&printTemplate;
}
sub manageGroups { 
	@groups = &runCmd("sudo $samba_tool group list");

	foreach $item (@groups) {
		$item = "<option value='$item'>$item</option>";
	}
	&getTemplate('groups');
	&doSub('ALLGROUPS', "@groups");
	&doSub('SESSION', $session);
	&printTemplate;
}
sub addGroup { 
		&getTemplate('addGroup');
		&doSub('SESSION',$session);
		&printTemplate;
}
sub saveGroup {
	@groups = &runCmd("sudo $samba_tool group list");
	chomp($newGroup);
	foreach $grpitem (@groups) {
		chomp($grpitem);
		if($grpitem eq $newGroup) {
			print "Group '$newGroup' already exists.";
			exit;
		}
	}
	$createGroup = &runCmd("sudo $samba_tool group add '$newGroup'");
	print "$createGroup";
	exit;
}
sub delGroup {
	if($delConfirm eq 'DELETE') {

		@members = &runCmd("sudo $samba_tool group listmembers '$delGroup'");

		if(@members) {
			print "Group is not empty.";
			exit;
		}
		else {
			$delMessage = &runCmd("sudo $samba_tool group delete '$delGroup'");
			print "$delMessage";
			exit;
		}
	}
	else {
		print "Confirmation did not match.";
		exit;
	}
}
sub delGroupConfirm {
	&getTemplate('deleteGroup');
	&doSub('SESSION',$session);
	&doSub('DELGROUP',$delGroup);
	&printTemplate;
}
sub getMembers {
	@members = &runCmd("sudo $samba_tool group listmembers '$groupName'");
	if(@members) {
		foreach $item (@members) {
			$item =~ s/\\n//gi;
			$item = "<option>$item</option>";
		}
	}
	else {
		@members = ("<option>Empty</option>");
	}
	print "@members";
}
sub saveUserGroups { 
	if($GroupType eq 'add') {
		chomp($allGroups);
		$command = "sudo $samba_tool group addmembers '$allGroups' '$Unixusername'";
	}
	if($GroupType eq 'remove') {
		chomp($usersGroup);
		$command = "sudo $samba_tool group removemembers '$usersGroup' '$Unixusername'";
	}
	$GroupChange = &runCmd("$command");
	&editGroup;
}
sub editUser {
		$pdbedit = $settings->{'system'}->{'samba'}->{'pdbedit'};
		@getUser = &runCmd("sudo $pdbedit -u $Unixusername -v");

		foreach (@getUser) {
			if ($_ =~ m/^Unix username:\s*(.*?)$/) { $acctUnixusername = $1; }
			if ($_ =~ m/^Account Flags:\s*(.*?)$/) { $acctFlags = $1; }
			if ($_ =~ m/^Full Name:\s*(.*?)$/) { $acctFullName = $1; }
			if ($_ =~ m/^Home Directory:\s*(.*?)$/) { $acctHomeDirectory = $1; }
			if ($_ =~ m/^HomeDir Drive:\s*(.*?)$/) { $acctHomeDirDrive = $1; }
			if ($_ =~ m/^Logon Script:\s*(.*?)$/) { $acctLogonScript = $1; }
			if ($_ =~ m/^Profile Path:\s*(.*?)$/) { $acctProfilePath = $1; }
			if ($_ =~ m/^Account desc:\s*(.*?)$/) { $acctAccountDesc = $1; }
			
			#if ($_ =~ m/^NT username:\s*(.*?)$/) { $acctNTusername = $1; } # FUTURE
			#if ($_ =~ m/^User SID:\s*(.*?)$/) { $acctUserSID = $1; } # FUTURE
			#if ($_ =~ m/^Primary Group SID:\s*(.*?)$/) { $acctGroupSID = $1; } # FUTURE
			#if ($_ =~ m/^Domain:\s*(.*?)$/) { $acctDomain = $1; } # FUTURE
			#if ($_ =~ m/^Workstations:\s*(.*?)$/) { $acctWorkstations = $1; } # FUTURE
			#if ($_ =~ m/^Munged Dial:\s*(.*?)$/) { $acctMungedDial = $1; } # FUTURE
			#if ($_ =~ m/^Logon time:\s*(.*?)$/) { $acctLogonTime = $1; } # FUTURE
			#if ($_ =~ m/^Logoff time:\s*(.*?)$/) { $acctLogoffTime = $1; } # FUTURE
			#if ($_ =~ m/^Kickoff time:\s*(.*?)$/) { $acctKickoffTime = $1; } # FUTURE
			#if ($_ =~ m/^Password lst set:\s*(.*?)$/) { $acctPassLastSet = $1; } # FUTURE
			#if ($_ =~ m/^Password can change:\s*(.*?)$/) { $acctPassCanChange = $1; } # FUTURE
			#if ($_ =~ m/^Password must change:\s*(.*?)$/) { $acctPassMustChange = $1; } # FUTURE
			#if ($_ =~ m/^Last bad password:\s*(.*?)$/) { $acctLastBadPass = $1; } # FUTURE
			#if ($_ =~ m/^Bad password count:\s*(.*?)$/) { $acctBadPassCount = $1; } # FUTURE
			#if ($_ =~ m/^Logon hours:\s*(.*?)$/) { $acctLogonHours = $1; } # FUTURE
		}
		
		if($acctHomeDirDrive eq '(null)') { $acctHomeDirDrive = ''; }
		$acctHomeDirDrive =~ s/\\/\\\\/gi;
		#$acctProfilePath =~ s/\\/\\\\/gi;
		
		$NoExpire = "";
		$AcctDisabled = "";
		
		# N: No password required
		# D: Account disabled
		# H: Home directory required
		# T: Temporary duplicate of other account
		# U: Regular user account
		# M: MNS logon user account
		# W: Workstation Trust Account
		# S: Server Trust Account
		# L: Automatic Locking
		# X: Password does not expire
		# I: Domain Trust Account

		if($acctFlags =~ m/X/) { $NoExpire = "checked"; }
		if($acctFlags =~ m/D/) { $AcctDisabled = "checked"; }
		#if($acctFlags =~ m/U/gi) { $AcctUserType = "checked"; } # FUTURE
		#if($acctFlags =~ m/N/gi) { $AcctNoPasswd = "checked"; } # FUTURE
		#if($acctFlags =~ m/H/gi) { $AcctHomeRequired = "checked"; } # FUTURE
		#if($acctFlags =~ m/T/gi) { $AcctTemp = "checked"; } # FUTURE
		#if($acctFlags =~ m/M/gi) { $AcctMNS = "checked"; } # FUTURE
		#if($acctFlags =~ m/W/gi) { $AcctStationTrust = "checked"; } # FUTURE
		#if($acctFlags =~ m/S/gi) { $AcctServerTrust = "checked"; } # FUTURE
		#if($acctFlags =~ m/L/gi) { $AcctAutoLock = "checked"; } # FUTURE
		#if($acctFlags =~ m/I/gi) { $AcctDomainTrust = "checked"; } # FUTURE	

		&getTemplate('editUser');
		&doSub('UNIXUSERNAME',$acctUnixusername);
		&doSub('FULLNAME',$acctFullName);
		&doSub('HOMEDIRDRIVE',$acctHomeDirDrive);
		&doSub('HOMEDIRECTORY',$acctHomeDirectory);
		&doSub('LOGINSCRIPT',$acctLogonScript);
		&doSub('PROFILEPATH',$acctProfilePath);
		&doSub('ACCOUNTDESC',$acctAccountDesc);
		&doSub('NOEXPIRE',$NoExpire); 
		&doSub('ACCTDISABLED',$AcctDisabled);
		&doSub('SESSION',$session);
		&printTemplate;
	}
sub saveUser {
		$pdbedit = $settings->{'system'}->{'samba'}->{'pdbedit'};
		$Flags = "";


#pdbedit [-a] [-b passdb-backend] [-c account-control] [-C value] [-d debuglevel] [-D drive] [-e passdb-backend] [-f fullname] [--force-initialized-passwords] [-g] [-h homedir] [-i passdb-backend] [-I domain] [-K] [-L ] [-m] [-M SID|RID] [-N description] [-P account-policy] [-p profile] [--policies-reset] [-r] [-s configfile] [-S script] [--set-nt-hash] [-t] [--time-format] [-u username] [-U SID|RID] [-v] [-V] [-w] [-x] [-y] [-z] [-Z]

#-u|--user username
#-f|--fullname fullname
#-h|--homedir homedir
#-D|--drive drive
#-S|--script script
#-p|--profile profile
#-c|--account-control account-control
#-a|--create
#-r|--modify
#-m|--machine create machine trust rather than 
#-g|--group
#-N|--account-desc description
#-z|--bad-password-count-reset
#-x|--delete
#-t|--password-from-stdin This option causes pdbedit to read the password from standard input, rather than from /dev/tty


		&getTemplate('genericwin');
		&doSub('GENERICDATA', "User $Unixusername has been updated.");
		&printTemplate;
		
		print "$Flags<br>";
		
		$HomeDirDrive =~ s/\\/\\\\/g;
		#$ProfilePath =~ s/\\/\\\\/g;
		
        if($FullName eq '') { $FullName = " "; }
        if($HomeDirectory eq '') { $HomeDirectory = " "; }
        if($HomeDirDrive eq '') { $HomeDirDrive = " "; }
        if($LogonScript eq '') { $LogonScript = " "; }
        if($ProfilePath eq ''){ $ProfilePath = " "; }
        if($Accountdesc eq ''){ $Accountdesc = " "; }
		
		$addfullname = &runCmd("sudo $pdbedit -r -u $Unixusername -f '$FullName'");
		$addhomedir = &runCmd("sudo $pdbedit -r -u $Unixusername -h '$HomeDirectory'");
		$addHomedrive = &runCmd("sudo $pdbedit -r -u $Unixusername -D '$HomeDirDrive'");
		$addlogonscript = &runCmd("sudo $pdbedit -r -u $Unixusername -S '$LogonScript'");
		$addprofilePath = &runCmd("sudo $pdbedit -r -u $Unixusername -p '$ProfilePath'");
		$addDescription = &runCmd("sudo $pdbedit -r -u $Unixusername -N '$Accountdesc'");
		
        if($userDisabled eq 'on') { $Flags .= 'D'; }
        if($noExpire eq 'on') { $Flags .= 'X'; }
        $setFlags = &runCmd("sudo $pdbedit -r -u $Unixusername -c '[$Flags]'");
	}
sub createUser { 
		$pdbedit = $settings->{'system'}->{'samba'}->{'pdbedit'};
		
		if($Unixuserame =~ /[^\w\s]/) {  
			$message = "Username cannot contain spaces or non alphanumeric characters.<br>\n";
			&getTemplate('genericwin');
			&doSub('GENERICDATA', $message);
			&printTemplate;
			exit;
		} 
		else { 
			if($password eq $password2) { 
                $create = &runCmd("echo '$password\n$password\n' | sudo $pdbedit -a $Unixusername");
				if($create =~ /Constraint violation/) { 
                    ($dump, $msg) = split(/Constraint violation/, $create);
					$message = "<b>Password Contraint Violation</b><hr>$msg\n";
					&getTemplate('genericwin');
					&doSub('GENERICDATA', $message);
					&printTemplate;
					exit;
				} 
				else { 
					&getTemplate('createUser');
					&doSub("MESSAGE", "User $Unixusername has been created.");
					&printTemplate;
                    if($create =~ /SID/) { 
                        if($FullName ne "") { $addfullname = &runCmd("sudo $pdbedit -u $Unixusername -f '$FullName'"); }
                        if($HomeDirectory ne "") { $addhomedir = &runCmd("sudo $pdbedit -u $Unixusername -h '$HomeDirectory'"); }
                        if($HomeDirDrive ne "") { $addHomedrive = &runCmd("sudo $pdbedit -u $Unixusername -D '$HomeDirDrive'"); }
                        if($LogonScript ne "") { $addlogonscript = &runCmd("sudo $pdbedit -u $Unixusername -S '$LogonScript'"); }
                        if($ProfilePath ne ""){ $addprofilePath = &runCmd("sudo $pdbedit -u $Unixusername -p '$ProfilePath'"); }
                        if($Accountdesc ne ""){ $addDescription = &runCmd("sudo $pdbedit -u $Unixusername -N '$Accountdesc'"); }
                        if($Disabled eq "on") { $Flags = $Flags.'D'; }
                        if($noExpire eq "on") { $Flags = $Flags.'X'; }
                        if($Flags ne "") { $setFlags = &runCmd("sudo $pdbedit -u $Unixusername -c '[$Flags]'"); }
						
						#$task = "editUser";
						#&submenu($task);
                    }
				}
			}
			else {
				$message = "Passwords do not match: $password, $password2<br>\n";
				&getTemplate('genericwin');
				&doSub('GENERICDATA', $message);
				&printTemplate;
                exit;
			}
		}
	}
sub editPC {
	$pdbedit = $settings->{'system'}->{'samba'}->{'pdbedit'};
	
	@getUser = &runCmd("sudo $pdbedit -m $pcname -r");

#EXAMPLE DATA OUTPUT FROM A MACHINE THAT HAS BEEN REMOVED FROM DOMAIN:
#Unix username:        DESKTOP-4RABP6T$
#NT username:
#Account Flags:        [DW         ]
#User SID:             S-1-5-21-2614576399-308812565-1163205234-1107
#Primary Group SID:    S-1-5-21-2614576399-308812565-1163205234-515
#Full Name:
#Home Directory:
#HomeDir Drive:        (null)
#Logon Script:
#Profile Path:
#Domain:
#Account desc:
#Workstations:
#Munged dial:
#Logon time:           Thu, 24 Dec 2020 20:32:17 UTC
#Logoff time:          0
#Kickoff time:         never
#Password last set:    Thu, 24 Dec 2020 20:22:34 UTC
#Password can change:  Thu, 24 Dec 2020 20:22:34 UTC
#Password must change: never
#Last bad password   : 0
#Bad password count  : 0
#Logon hours         : FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

#PDBEDIT COMMAND CHAIN AND PARAMTERES:
#pdbedit [-a] [-b passdb-backend] [-c account-control] [-C value] [-d debuglevel] [-D drive] [-e passdb-backend] [-f fullname] [--force-initialized-passwords] [-g] [-h homedir] [-i passdb-backend] [-I domain] [-K] [-L ] [-m] [-M SID|RID] [-N description] [-P account-policy] [-p profile] [--policies-reset] [-r] [-s configfile] [-S script] [--set-nt-hash] [-t] [--time-format] [-u username] [-U SID|RID] [-v] [-V] [-w] [-x] [-y] [-z] [-Z]

#-u|--user username
#-f|--fullname fullname
#-h|--homedir homedir
#-D|--drive drive
#-S|--script script
#-p|--profile profile
#-c|--account-control account-control
#-a|--create
#-r|--modify
#-m|--machine create machine trust rather than 
#-g|--group
#-N|--account-desc description
#-z|--bad-password-count-reset
#-x|--delete
#-t|--password-from-stdin This option causes pdbedit to read the password from standard input, rather than from /dev/tty


		foreach (@getUser) {
			if ($_ =~ m/^Unix username:\s*(.*?)\$$/) { $acctUnixusername = $1; }
			if ($_ =~ m/^Account Flags:\s*(.*?)$/) { $acctFlags = $1; }
			if ($_ =~ m/^Full Name:\s*(.*?)$/) { $acctFullName = $1; }
			if ($_ =~ m/^Home Directory:\s*(.*?)$/) { $acctHomeDirectory = $1; }
			if ($_ =~ m/^HomeDir Drive:\s*(.*?)$/) { $acctHomeDirDrive = $1; }
			if ($_ =~ m/^Logon Script:\s*(.*?)$/) { $acctLogonScript = $1; }
			if ($_ =~ m/^Profile Path:\s*(.*?)$/) { $acctProfilePath = $1; }
			if ($_ =~ m/^Account desc:\s*(.*?)$/) { $acctAccountDesc = $1; }
			
			if ($_ =~ m/^NT username:\s*(.*?)$/) { $acctNTusername = $1; } # FUTURE
			if ($_ =~ m/^User SID:\s*(.*?)$/) { $acctUserSID = $1; } # FUTURE
			if ($_ =~ m/^Primary Group SID:\s*(.*?)$/) { $acctGroupSID = $1; } # FUTURE
			if ($_ =~ m/^Domain:\s*(.*?)$/) { $acctDomain = $1; } # FUTURE
			if ($_ =~ m/^Workstations:\s*(.*?)$/) { $acctWorkstations = $1; } # FUTURE
			if ($_ =~ m/^Munged Dial:\s*(.*?)$/) { $acctMungedDial = $1; } # FUTURE
			if ($_ =~ m/^Logon time:\s*(.*?)$/) { $acctLogonTime = $1; } # FUTURE
			if ($_ =~ m/^Logoff time:\s*(.*?)$/) { $acctLogoffTime = $1; } # FUTURE
			if ($_ =~ m/^Kickoff time:\s*(.*?)$/) { $acctKickoffTime = $1; } # FUTURE
			if ($_ =~ m/^Password last set:\s*(.*?)$/) { $acctPassLastSet = $1; } # FUTURE
			if ($_ =~ m/^Password can change:\s*(.*?)$/) { $acctPassCanChange = $1; } # FUTURE
			if ($_ =~ m/^Password must change:\s*(.*?)$/) { $acctPassMustChange = $1; } # FUTURE
			if ($_ =~ m/^Last bad password:\s*(.*?)$/) { $acctLastBadPass = $1; } # FUTURE
			if ($_ =~ m/^Bad password count:\s*(.*?)$/) { $acctBadPassCount = $1; } # FUTURE
			if ($_ =~ m/^Logon hours\s*:\s*(.*?)$/) { $acctLogonHours = $1; } # FUTURE
		}
		
		if($acctHomeDirDrive eq '(null)') { $acctHomeDirDrive = ''; }
		$acctHomeDirDrive =~ s/\\/\\\\/gi;
		$acctProfilePath =~ s/\\/\\\\/gi;
		
		$AcctDomainTrust = "";
		$AcctDisabled = "";
		
		# ACCOUNT FLAG MEANINGS:
		# N: No password required
		# D: Account disabled
		# H: Home directory required
		# T: Temporary duplicate of other account
		# U: Regular user account
		# M: MNS logon user account
		# W: Workstation Trust Account
		# S: Server Trust Account
		# L: Automatic Locking
		# X: Password does not expire
		# I: Domain Trust Account

		if($acctFlags =~ m/X/) { $NoExpire = "checked"; }
		if($acctFlags =~ m/D/) { $AcctDisabled = "checked"; }
		if($acctFlags =~ m/U/gi) { $AcctUserType = "checked"; } # FUTURE
		if($acctFlags =~ m/N/gi) { $AcctNoPasswd = "checked"; } # FUTURE
		if($acctFlags =~ m/H/gi) { $AcctHomeRequired = "checked"; } # FUTURE
		if($acctFlags =~ m/T/gi) { $AcctTemp = "checked"; } # FUTURE
		if($acctFlags =~ m/M/gi) { $AcctMNS = "checked"; } # FUTURE
		if($acctFlags =~ m/W/gi) { $AcctStationTrust = "checked"; } # FUTURE
		if($acctFlags =~ m/S/gi) { $AcctServerTrust = "checked"; } # FUTURE
		if($acctFlags =~ m/L/gi) { $AcctAutoLock = "checked"; } # FUTURE
		if($acctFlags =~ m/I/gi) { $AcctDomainTrust = "checked"; } # FUTURE	

		@status = &runCmd("sudo ping $acctUnixusername -c 1");
		$status = "@status";
		
		if($status =~ /1 received/) {
			$icon = "PC-ON.png";
			$disabled = "";
			$wake = "disabled";
		}
		else {
			$icon = "PC-OFF.png";
			$disabled = "disabled";
			$wake = "";
		}
		
		# Start NoVNC 
		# ./launch.sh --vnc w7-01:5900 --cert /razdc/www/ssl/razdc.pem /var/log/no_vnc.log
		
		&getTemplate('editPC');
		&doSub('PCIMG',$icon);
		&doSub('TOKEN',$token);
		&doSub('DISABLED',$disabled);
		&doSub('WAKE',$wake);
		&doSub('UNIXUSERNAME',$acctUnixusername);
		&doSub('ACCOUNTDESC',$acctAccountDesc);
		&doSub('ACCTUSERSID',$acctUserSID);
		&doSub('ACCTGROUPSID',$acctGroupSID);
		&doSub('ACCTLOGONTIME',$acctLogonTime);
		&doSub('ACCTLOGONHOURS',$acctLogonHours);
		&doSub('ACCTDISABLED',$AcctDisabled);
		&doSub('ACCTTRUST',$AcctStationTrust);
		&doSub('SESSION',$session);
		&printTemplate;
	}
sub deletePC {
		&getTemplate('deletePC');
		&doSub('UNIXUSERNAME',$Unixusername);
		&doSub('SESSION',$session);
		&printTemplate;
	}
sub deletePCConfirm {
		if($pcConfirmDelete eq 'DELETE') {
			$pdbedit = $settings->{'system'}->{'samba'}->{'pdbedit'};
			$delOutput = &runCmd("sudo $pdbedit -m $Unixusername -x 2>&1 1>/dev/null");
			&getTemplate('createUser');
			&doSub('MESSAGE', "Computer has been deleted.");
			&printTemplate;
		}
		else {
			$message = "Confirmation failed - Confirmation code is case sensitive.";
			&getTemplate('genericwin');
			&doSub('GENERICDATA', $message);
			&printTemplate;
		}
	}
sub remote { 	
	&getTemplate('novnc');
	&doSub('UNIXUSERNAME',$pcname);
	&doSub('TOKEN',$token);
	&doSub('IPADDR',$netInfo{'IPADDR'});
	&printTemplate;
	#`sudo /razdc/www/html/novnc/utils/launch.sh --vnc $pcname:5900 --run-once --cert /razdc/www/ssl/razdc.pem /var/log/no_vnc.log`;
}
sub wol { # NEED WOL SCRIPT TESTED AND ADDED AS FUNCTION
	# CALL WOL SCRIPT WITH PC INFO: MAC:IP/HOSTNAME
	&getTemplate('genericwin');
	&doSub('GENERICDATA', "Sent Wake-On-Lan packets to PC.");
	&printTemplate;
=pod
SCRIPT I WILL USE TO MAKE WOL WORK:

use strict;
use Socket;
use Getopt::Std;
use vars qw($VERSION $opt_v $opt_h $opt_i $opt_p $opt_f);
$VERSION = '0.40';

my $DEFAULT_IP      = '255.255.255.255';
my $DEFAULT_PORT    = getservbyname('discard', 'udp');

#
# Process the command line
#

getopts("hvp:i:f:");

if ($opt_h) { usage(); exit(0); }
if ($opt_v) { print "wakeonlan version $VERSION\n"; exit(0); }
if (!$opt_f and !@ARGV) { usage(); exit(0); }
if ($opt_i) { $DEFAULT_IP = $opt_i; }           # override default
if ($opt_p) { $DEFAULT_PORT = $opt_p; }         # override default
if ($opt_f) { process_file($opt_f); }

# The rest of the command line are a list of hardware addresses 

foreach (@ARGV) {
        wake($_, $opt_i, $opt_p);
} 

#
# wake
#
# The 'magic packet' consists of 6 times 0xFF followed by 16 times
# the hardware address of the NIC. This sequence can be encapsulated
# in any kind of packet, in this case UDP to the discard port (9).
#                                                                               
sub wake {
        my $hwaddr  = shift;
        my $ipaddr  = shift || $DEFAULT_IP;
        my $port    = shift || $DEFAULT_PORT;
        my ($raddr, $them, $proto);
        my ($hwaddr_re, $pkt);

        # Validate hardware address (ethernet address)

        $hwaddr_re = join(':', ('[0-9A-Fa-f]{1,2}') x 6);
        if ($hwaddr !~ m/^$hwaddr_re$/) {
                warn "Invalid hardware address: $hwaddr\n";
                return undef;
        }

        # Generate magic sequence

        foreach (split /:/, $hwaddr) {
                $pkt .= chr(hex($_));
        }

        $pkt = chr(0xFF) x 6 . $pkt x 16;

        # Alocate socket and send packet

        $raddr = gethostbyname($ipaddr);
        $them = pack_sockaddr_in($port, $raddr);
        $proto = getprotobyname('udp');

        socket(S, AF_INET, SOCK_DGRAM, $proto) or die "socket : $!";
        setsockopt(S, SOL_SOCKET, SO_BROADCAST, 1) or die "setsockopt : $!";
        print "Sending magic packet to $ipaddr:$port with $hwaddr\n";
        send(S, $pkt, 0, $them) or die "send : $!";
        close S;
}

#
# process_file
#

sub process_file {
        my $filename = shift;
        my ($hwaddr, $ipaddr, $port);

        open (F, "<$filename") or die "open : $!";
        while(<F>) {
                next if /^\s*#/;                # ignore comments
                next if /^\s*$/;                # ignore empty lines
                chomp;
                ($hwaddr, $ipaddr, $port) = split;
                wake($hwaddr, $ipaddr, $port);
        }
        close F;
}

#
# Usage
#

sub usage {
print <<__USAGE__;
Usage
    wakeonlan [-h] [-v] [-i IP_address] [-p port] [-f file] [[hardware_address] 
...]

Options
    -h
        this information
    -v
        dislpays the script version
    -i ip_address
        set the destination IP address
        default: 255.255.255.255 (the limited broadcast address)
    -p port
        set the destination port
        default: 9 (discard port)
    -f file 
        uses file as a source of hardware addresses

See also
    wakelan(1)    

__USAGE__
}

__END__


wakeonlan - Perl script to wake up computers

wakeonlan [-h] [-v] [-i IP_address] [-p port] [-f file] [[hardware_address] ...]

This script sends 'magic packets' to wake-on-lan enabled ethernet adapters and motherboards, in order to switch on the called PC. Be sure to connect the NIC with the motherboard if neccesary, and enable the WOL function in the BIOS.
The 'magic packet' consists of 6 times 0xFF followed by 16 times the hardware address of the NIC. This sequence can be encapsulated in any kind of packet. This script uses UDP packets.

-i ip_address
-p port - Destination port. Default: 9 (discard port).
-f file 

Using the limited broadcast address (255.255.255.255):

    $ wakeonlan 01:02:03:04:05:06
    $ wakeonlan 01:02:03:04:05:06 01:02:03:04:05:07

Using a subnet broadcast address:

    $ wakeonlan -i 192.168.1.255 01:02:03:04:05:06

Using another destination port:

    $ wakeonlan -i 192.168.1.255 -p 1234 01:02:03:04:05:06

Using a file as a source of hardware addresses and IP addresses:

    $ wakeonlan -f examples/lab001.wol
    $ wakeonlan -f examples/lab001.wol 01:02:03:04:05:06

=cut
}
sub editDC {
	$pdbedit = $settings->{'system'}->{'samba'}->{'pdbedit'};
	
	@getUser = &runCmd("sudo $pdbedit -m $dcname -r");

#EXAMPLE DATA OUTPUT FROM A MACHINE THAT HAS BEEN REMOVED FROM DOMAIN:
#Unix username:        RAZ$
#NT username:
#Account Flags:        [S          ]
#User SID:             S-1-5-21-2614576399-308812565-1163205234-1000
#Primary Group SID:    S-1-5-21-2614576399-308812565-1163205234-516
#Full Name:
#Home Directory:
#HomeDir Drive:        (null)
#Logon Script:
#Profile Path:
#Domain:
#Account desc:
#Workstations:
#Munged dial:
#Logon time:           Tue, 15 Dec 2020 06:12:10 UTC
#Logoff time:          0
#Kickoff time:         never
#Password last set:    Wed, 14 Oct 2020 00:06:13 UTC
#Password can change:  Wed, 14 Oct 2020 00:06:13 UTC
#Password must change: never
#Last bad password   : 0
#Bad password count  : 0
#Logon hours         : FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

#PDBEDIT COMMAND CHAIN AND PARAMTERES:
#pdbedit [-a] [-b passdb-backend] [-c account-control] [-C value] [-d debuglevel] [-D drive] [-e passdb-backend] [-f fullname] [--force-initialized-passwords] [-g] [-h homedir] [-i passdb-backend] [-I domain] [-K] [-L ] [-m] [-M SID|RID] [-N description] [-P account-policy] [-p profile] [--policies-reset] [-r] [-s configfile] [-S script] [--set-nt-hash] [-t] [--time-format] [-u username] [-U SID|RID] [-v] [-V] [-w] [-x] [-y] [-z] [-Z]

#-u|--user username
#-f|--fullname fullname
#-h|--homedir homedir
#-D|--drive drive
#-S|--script script
#-p|--profile profile
#-c|--account-control account-control
#-a|--create
#-r|--modify
#-m|--machine create machine trust rather than 
#-g|--group
#-N|--account-desc description
#-z|--bad-password-count-reset
#-x|--delete
#-t|--password-from-stdin This option causes pdbedit to read the password from standard input, rather than from /dev/tty


		foreach (@getUser) {
			if ($_ =~ m/^Unix username:\s*(.*?)\$$/) { $acctUnixusername = $1; }
			if ($_ =~ m/^Account Flags:\s*(.*?)$/) { $acctFlags = $1; }
			if ($_ =~ m/^Full Name:\s*(.*?)$/) { $acctFullName = $1; }
			if ($_ =~ m/^Home Directory:\s*(.*?)$/) { $acctHomeDirectory = $1; }
			if ($_ =~ m/^HomeDir Drive:\s*(.*?)$/) { $acctHomeDirDrive = $1; }
			if ($_ =~ m/^Logon Script:\s*(.*?)$/) { $acctLogonScript = $1; }
			if ($_ =~ m/^Profile Path:\s*(.*?)$/) { $acctProfilePath = $1; }
			if ($_ =~ m/^Account desc:\s*(.*?)$/) { $acctAccountDesc = $1; }
			
			if ($_ =~ m/^NT username:\s*(.*?)$/) { $acctNTusername = $1; } # FUTURE
			if ($_ =~ m/^User SID:\s*(.*?)$/) { $acctUserSID = $1; } # FUTURE
			if ($_ =~ m/^Primary Group SID:\s*(.*?)$/) { $acctGroupSID = $1; } # FUTURE
			if ($_ =~ m/^Domain:\s*(.*?)$/) { $acctDomain = $1; } # FUTURE
			if ($_ =~ m/^Workstations:\s*(.*?)$/) { $acctWorkstations = $1; } # FUTURE
			if ($_ =~ m/^Munged Dial:\s*(.*?)$/) { $acctMungedDial = $1; } # FUTURE
			if ($_ =~ m/^Logon time:\s*(.*?)$/) { $acctLogonTime = $1; } # FUTURE
			if ($_ =~ m/^Logoff time:\s*(.*?)$/) { $acctLogoffTime = $1; } # FUTURE
			if ($_ =~ m/^Kickoff time:\s*(.*?)$/) { $acctKickoffTime = $1; } # FUTURE
			if ($_ =~ m/^Password last set:\s*(.*?)$/) { $acctPassLastSet = $1; } # FUTURE
			if ($_ =~ m/^Password can change:\s*(.*?)$/) { $acctPassCanChange = $1; } # FUTURE
			if ($_ =~ m/^Password must change:\s*(.*?)$/) { $acctPassMustChange = $1; } # FUTURE
			if ($_ =~ m/^Last bad password:\s*(.*?)$/) { $acctLastBadPass = $1; } # FUTURE
			if ($_ =~ m/^Bad password count:\s*(.*?)$/) { $acctBadPassCount = $1; } # FUTURE
			if ($_ =~ m/^Logon hours\s*:\s*(.*?)$/) { $acctLogonHours = $1; } # FUTURE
		}
		
		if($acctHomeDirDrive eq '(null)') { $acctHomeDirDrive = ''; }
		$acctHomeDirDrive =~ s/\\/\\\\/gi;
		$acctProfilePath =~ s/\\/\\\\/gi;
		
		$AcctDomainTrust = "";
		$AcctDisabled = "";
		
		# ACCOUNT FLAG MEANINGS:
		# N: No password required
		# D: Account disabled
		# H: Home directory required
		# T: Temporary duplicate of other account
		# U: Regular user account
		# M: MNS logon user account
		# W: Workstation Trust Account
		# S: Server Trust Account
		# L: Automatic Locking
		# X: Password does not expire
		# I: Domain Trust Account

		if($acctFlags =~ m/X/) { $NoExpire = "checked"; }
		if($acctFlags =~ m/D/) { $AcctDisabled = "checked"; }
		if($acctFlags =~ m/U/gi) { $AcctUserType = "checked"; } # FUTURE
		if($acctFlags =~ m/N/gi) { $AcctNoPasswd = "checked"; } # FUTURE
		if($acctFlags =~ m/H/gi) { $AcctHomeRequired = "checked"; } # FUTURE
		if($acctFlags =~ m/T/gi) { $AcctTemp = "checked"; } # FUTURE
		if($acctFlags =~ m/M/gi) { $AcctMNS = "checked"; } # FUTURE
		if($acctFlags =~ m/W/gi) { $AcctStationTrust = "checked"; } # FUTURE
		if($acctFlags =~ m/S/gi) { $AcctServerTrust = "checked"; } # FUTURE
		if($acctFlags =~ m/L/gi) { $AcctAutoLock = "checked"; } # FUTURE
		if($acctFlags =~ m/I/gi) { $AcctDomainTrust = "checked"; } # FUTURE	

		&getTemplate('editDC');
		&doSub('UNIXUSERNAME',$acctUnixusername);
		&doSub('ACCOUNTDESC',$acctAccountDesc);
		&doSub('ACCTUSERSID',$acctUserSID);
		&doSub('ACCTGROUPSID',$acctGroupSID);
		&doSub('ACCTLOGONTIME',$acctLogonTime);
		&doSub('ACCTLOGONHOURS',$acctLogonHours);
		&doSub('ACCTDISABLED',$AcctDisabled);
		&doSub('ACCTTRUST',$AcctStationTrust);
		&doSub('SESSION',$session);
		&printTemplate;

	}
sub deleteDC {
		&getTemplate('deleteDC');
		&doSub('UNIXUSERNAME',$Unixusername);
		&doSub('SESSION',$session);
		&printTemplate;
	}
sub deleteDCConfirm {
		if($dcConfirmDelete eq 'DELETE') {
			#$pdbedit = $settings->{'system'}->{'samba'}->{'pdbedit'};
			#$delOutput = `sudo $pdbedit -m $Unixusername -x 2>&1 1>/dev/null`;
			
			$delOutput = &runCmd("sudo $samba_tool domain demote --remove-other-dead-server=$Unixusername");
			&getTemplate('createUser');
			&doSub('MESSAGE', "Domain controller has been deleted.");
			&printTemplate;
		}
		else {
			$message = "Confirmation failed - Confirmation code is case sensitive.";
			&getTemplate('genericwin');
			&doSub('GENERICDATA', $message);
			&printTemplate;
		}
	}
sub sslnew {
	&getTemplate('sslnew');
	&doSub('SESSION', $session);
	&printTemplate;
}
sub getActiveSSL { 
	$vhost='/etc/httpd/conf.d/ssl.conf';
	open(FH, "< $vhost") or die "Failed to open ssl.conf: $!";
	@VCONF = <FH>;
	close(FH);
	
	foreach $line (@VCONF) {
		if( $line =~ m/SSLCertificateFile/ ) {
		($key, $value) = split(/ /, $line);
		${$key} = $value;
		}
	}
	return $SSLCertificateFile;
}
sub ssldel { # FIX SSL DELETE!
	$dir = '/razdc/www/ssl';
	&runCmd("sudo chmod 0777 $dir");

	if($file =~ /$delfile/) {
		unlink("$dir/$delfile") if -e "$dir/$delfile";
	}
	if($file =~ /$delkey/) {
		unlink("$dir/$delkey") if -e "$dir/$delkey";
	}
	if($file =~ /$delcsr/) {
		unlink("$dir/$delkey") if -e "$dir/$delcsr";
	}
}
sub csrdel {
	$dir = '/razdc/www/ssl';
	&runCmd("sudo chmod 0777 $dir");
	opendir(DIR, $dir) or print "Can't open directory $dir: $!\n";
	while ($file = readdir(DIR)) {
		next if $file=~/^\./;
		if($file =~ /$delfile/) {
			unlink("$dir/$delfile.csr") if -e "$dir/$delfile.csr";
			unlink("$dir/$delfile.key") if -e "$dir/$delfile.key";
		}
	}
	
}
sub ssllist { # NEED SSL COMMANDS AND PATHS IN JSON CONFIG!
	$dir = '/razdc/www/ssl';
	$sslcmd = 'openssl';
	$activeCert = &getActiveSSL; # get active SSL from config file (See sslcfg routine)

	if($dir) {
		opendir(DIR, $dir) or print "Can't open directory $dir: $!\n";
		while ($file = readdir(DIR)) {
			next if $file=~/^\./;
			next if $file=~/\.chain\.crt$/;
			next if $file=~/\.chained\.crt$/;
			if($file =~ /\.crt$/) {
				push(@CRTS , $file);
			}
			if($file =~ /\.csr$/) {
				push(@CSRS , $file);
			}
		}
		close(DIR);
		
		$i=0;
		foreach $file (@CRTS) {
			$sslid = "sslid$i";
			@subject = &runCmd("$sslcmd x509 -in $dir/$file -noout -subject");
			@edate = &runCmd("$sslcmd x509 -in $dir/$file -noout -enddate");
			@S = &runCmd("$sslcmd x509 -in $dir/$file -noout -serial");
			
			$subject = "@subject";
			$edate = "@edate";
			$S = "@S";
			
			($s1,$serial) = split(/=/, $S);
			($startFlag,$startdate) = split(/=/, $sdate);
			($endFlag,$enddate) = split(/=/, $edate);
				
			(@SUBJECT) = split(/\//,$subject);
			foreach $item (@SUBJECT) {
				($sslk,$sslv) = split(/=/, $item);
				${$sslk} = $sslv;
			}
				
			# IS THIS THE ACTIVE SSL CERT?
			if($activeCert =~ /$dir\/$file/) {
				$active = 'active';
				$disableDelete = 'disabled';
			} else {
				$active = 'inactive';
				$disableDelete = '';
			}
								
			# EVEN OR ODD?
			if ($i%2==1) {
				$evenodd = 'evenRow';
			} else {
				$evenodd = 'oddRow';
			}
			# CLEAN UP NAME TO USE AS root for PEM and key:
			#($cleanName,$CRTEXT) = split(/\./, $file);
			$rootFile = $file;
			$rootFile =~ s/\.crt//gi;
			
			&getTemplate('sslitem');
			&doSub('EVENODD', $evenodd);
			&doSub('SSLID', $sslid);
			&doSub('SSLSTATUS', $active);
			&doSub('SSLNAME', uc($file));
			&doSub('SSLFILE', $file);
			&doSub('SSLKEY', "$rootFile.key");
			&doSub('SERIAL', $serial);
			&doSub('SSLEND', $enddate);
			&doSub('SSLCERT', $file);
			&doSub('SESSION', $session);
			&doSub('SSLDEL', $disableDelete);
			push(@CERTFILES , $_);
			$i++;
		}
		$i=0;
		foreach $file (@CSRS) {
		$csrid = "csrid$i";
		# EVEN OR ODD?
			if ($i%2==1) {
				$evenodd = 'evenRow';
			} else {
				$evenodd = 'oddRow';
			}
			# CLEAN UP NAME TO USE AS DISPLAY:
			($cleanName,$CRTEXT) = split(/\./, $file);
				
			&getTemplate('csritem');
			&doSub('EVENODD', $evenodd);
			&doSub('CSRID', $csrid);
			&doSub('SSLNAME', uc($cleanName));
			&doSub('SSLFILE', $cleanName);
			&doSub('SSLCERT', $file);
			&doSub('SESSION', $session);
			&doSub('SSLDEL', $disableDelete);
			push(@CSRFILES , $_);
		$i++;
		}
	}
	if(!@CERTFILES) { push(@CERTFILES, "No certificates found."); }
	if(!@CSRFILES) { push(@CSRFILES, "No certificate requests found."); }
	
	&getTemplate('ssllist');
	&doSub('MESSAGE', $message);
	&doSub('SSLLIST', "@CERTFILES");
	&doSub('SSLCSR', "@CSRFILES");
	&printTemplate;
}
sub ssldetails { 
	# NEED SSL COMMANDS AND PATHS IN JSON CONFIG!
	$sslpath = '/razdc/www/ssl';
	$sslcmd = 'openssl';
	$certfile = $cert;
	
	#@ssldata = &runCmd("$sslcmd x509 -in $sslpath/$certfile -text -noout");
	@subject = &runCmd("$sslcmd x509 -in $sslpath/$certfile -noout -subject");
	@sdate = &runCmd("$sslcmd x509 -in $sslpath/$certfile -noout -startdate");
	@edate = &runCmd("$sslcmd x509 -in $sslpath/$certfile -noout -enddate");
	@pubkey = &runCmd("$sslcmd x509 -in $sslpath/$certfile -noout -pubkey");
	@S = &runCmd("$sslcmd x509 -in $sslpath/$certfile -noout -serial");
	
	$subject = "@subject";
	$sdate = "@sdate";
	$edate = "@edate";
	$pubkey = "@pubkey";
	$S = "@S";
			
	($s1,$serial) = split(/=/, $S);
	($startFlag,$startdate) = split(/=/, $sdate);
	($endFlag,$enddate) = split(/=/, $edate);
	# /C=US/ST=ND/L=GF/O=IT/CN=localhost 
	(@SUBJECT) = split(/\//,$subject);
	foreach $item (@SUBJECT) {
			($sslk,$sslv) = split(/=/, $item);
			${$sslk} = $sslv;
	}
	# CLEAN UP NAME TO USE AS DISPLAY:
	($cleanName,$CRTEXT) = split(/\./, $certfile);
				
	&getTemplate('ssldetails');
	doSub('SSLNAME', uc($cleanName));
	doSub('SSLSTART', $startdate);
	doSub('SSLEND', $enddate);
	doSub('SSLC', $C);
	doSub('SSLST', $ST);
	doSub('SSLL', $L);
	doSub('SSLO', $O);
	doSub('SSLCN', $CN);
	doSub('SERIAL', $serial);
	doSub('SSLKEY', $pubkey);
	&printTemplate;
}	
sub selfsigned { 
	&getTemplate('sslselfsigned');
	doSub('SESSION',$session);
	&printTemplate;	
}
sub sscertcreate { 
	$sslpath = '/razdc/www/ssl';
	$sslcmd = 'openssl';
	$newssCert = &runCmd("sudo $sslcmd req -x509 -nodes -days 356 -newkey rsa:4096 -keyout $sslpath/$SSLNAME.key -out $sslpath/$SSLNAME.crt -subj '/C=$SSLC/ST=$SSLST/L=$SSLL/O=$SSLO/CN=$SSLCN';");
	# CLEAN UP NAME TO USE AS DISPLAY:
	($cleanName,$CRTEXT) = split(/\./, $SSLNAME);
	&getTemplate('sscertcomplete');
	doSub('SSLNAME', uc($cleanName));
	doSub('SSLCERT', "$SSLNAME.crt");
	doSub('SESSION',$session);
	&printTemplate;
}
sub signedrequest { 
	&getTemplate('sslsr');
	doSub('SESSION',$session);
	&printTemplate;		
}
sub csrrequest {
	$sslpath = '/razdc/www/ssl';
	$sslcmd = 'openssl';
	$csrrequest = &runCmd("$sslcmd req -nodes -newkey rsa:4096 -keyout $sslpath/$SSLNAME.key -out $sslpath/$SSLNAME.csr -subj '/C=$SSLC/ST=$SSLST/L=$SSLL/O=$SSLO/OU=$SSLOU/CN=$SSLCN'");
	($cleanName,$CRTEXT) = split(/\./, $SSLNAME);
	&getTemplate('sscertcomplete');
	&getTemplate('srcertcomplete');
	doSub('SESSION', $session);
	doSub('SSLNAME', uc($cleanName));
	&printTemplate;		
}
sub sslhelp {
	&getTemplate('sslhelp');
	&printTemplate;	
}
sub usecert { # PATHS TO JSON CONFIG
	$dir = "/razdc/www/ssl";
	$root = $file;
	$root =~ s/\.crt//gi;
	
	# Does the crt and key exist?
	if(-e "$dir/$file" && -e "$dir/$filekey") {
		# We have a valid cert and key, but does it have a valid chain?
		if(-e "$dir/$root.chained.crt") {
			# Looks like its valid!
			&sslSaveConfig($file,'true');
		}
		else {
			# No chain, must be self-signed
			&sslSaveConfig($file,'false');
		}
		$message = "Features may not work properly until you reload.<br><a href=\"#\" onclick=\"javascript:history.go();\">Click here to reload.</a><br>";
		&ssllist;
		&runCmd("sudo apachectl graceful"); # SOFT RESET OF HTTPD TO ALLOW CERTIFICATE TO UPDATE.
	}
	else {
		$message = "Error using certificate. Missing certificate, key file.";
		&ssllist;
	}
}
sub sslSaveConfig { 
	$sslconf_dir = "/etc/httpd/conf.d";
	$sslconf = "ssl.conf";
	($file, $chained) = @_;
	# Set Folder permissions
	&runCmd("sudo chmod 0777 $sslconf_dir");
	# Set Config File permissions
	&runCmd("sudo chmod 0777 $sslconf_dir/$sslconf");
	# Remove Backup config
	&runCmd("sudo rm -f $sslconf_dir/$sslconf.bak");
	# Create new backup Config
	&runCmd("sudo cp $sslconf_dir/$sslconf $sslconf_dir/$sslconf.bak");
	# Write new SSL config
	open(SSLCONF, "> $sslconf_dir/$sslconf") or die "Error opening SSL Config: $!\n";
	
print SSLCONF qq~
Listen 443 https
SSLPassPhraseDialog exec:/usr/libexec/httpd-ssl-pass-dialog
SSLSessionCache         shmcb:/run/httpd/sslcache(512000)
SSLSessionCacheTimeout  300
SSLRandomSeed startup file:/dev/urandom  256
SSLRandomSeed connect builtin
SSLCryptoDevice builtin

<VirtualHost _default_:443>
DocumentRoot "/razdc/www/html"
#ServerName www.example.com:443
ErrorLog logs/ssl_error_log
TransferLog logs/ssl_access_log
LogLevel warn

SSLEngine on
SSLProtocol all -SSLv2 -SSLv3
SSLCipherSuite HIGH:3DES:!aNULL:!MD5:!SEED:!IDEA
SSLCertificateFile /razdc/www/ssl/$file
SSLCertificateKeyFile /razdc/www/ssl/$filekey
~;

# write chain file if chained is true
if($chained eq 'true'){
print SSLCONF qq~
SSLCertificateChainFile /razdc/www/ssl/$root.chain.crt
~;
}

# Comment chain out if chain is false
if($chained eq 'false'){
print SSLCONF qq~
#SSLCertificateChainFile /razdc/www/ssl/$root.chain.crt
~;
}

print SSLCONF qq~
ProxyPass "/ws" "ws://127.0.0.1:4000/"
ProxyPassReverse "/ws" "ws://127.0.0.1:4000/"

ProxyPass "/vnc" "ws://127.0.0.1:6080/"
ProxyPassReverse "/vnc" "ws://127.0.0.1:6080/"

<Files \~ "\\.(pl|cgi|shtml|phtml|php3?)\$">
    SSLOptions +StdEnvVars
</Files>
<Directory "/razdc/www/cgi-bin">
    SSLOptions +StdEnvVars
</Directory>

BrowserMatch "MSIE [2-5]" \\
         nokeepalive ssl-unclean-shutdown \\
         downgrade-1.0 force-response-1.0

CustomLog logs/ssl_request_log \\
          "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \\"%r\\" %b"

</VirtualHost>
~;
close(SSLCONF);
}
sub updateCron { # WIP!
	$cron = &loadJSON('tasks');
}
sub scheduling {
	@TASKS;
	$q=0;
	$cron = &loadJSON('tasks');
	
	@selectedTask;
	$TDESC;
	$TSCRIPT;
	$TASKDEL = '';
	foreach (@{ $cron->{'tasks'} }) {
		$tname = $cron->{'tasks'}[$q]->{'name'};
		$tcommand = $cron->{'tasks'}[$q]->{'script'};
		$tmin = $cron->{'tasks'}[$q]->{'minute'};
		$thour = $cron->{'tasks'}[$q]->{'hour'};
		$tday = $cron->{'tasks'}[$q]->{'dom'};
		$tmon = $cron->{'tasks'}[$q]->{'month'};
		$twday = $cron->{'tasks'}[$q]->{'dow'};
		$tdesc = $cron->{'tasks'}[$q]->{'description'};

		&getTemplate('option');
		&doSub('VALUE',$tcommand);
		&doSub('TEXT',$tname);
		
		if($cron_name eq $tcommand) {
			@selectedTask = ($tmin,$thour,$tday,$tmon,$twday);
			&doSub('SELECTED','selected');
			$TNAME = $tname;
			$TASKDEL = '<input type="button" value="Delete Task">';
			$TDESC = "$tdesc";
			$TSCRIPT = "$tcommand";
			push(@TASKS, $_);
		}
		else {
			&doSub('SELECTED','');
			push(@TASKS, $_);
		}
		$q++;
	}
	(@RETURNED) = &makeSelections(@selectedTask);
	@CMIN = $RETURNED[0];
	@CHOUR = $RETURNED[1];
	@CDAY = $RETURNED[2];
	@CMON = $RETURNED[3];
	@CWEEK = $RETURNED[4];
	
	#print "RETURNED ARRAYS: MIN:@CMIN,HOUR:@CHOUR,DAY:@CDAY,MONTH:@CMON,WEEK:@CWEEK";

	&getTemplate('newtask');
	&doSub('TNAME', "$TNAME");
	&doSub('TDESC', "$TDESC");
	&doSub('CRONMIN', "@CMIN");
	&doSub('CRONHOUR', "@CHOUR");
	&doSub('CRONDAY', "@CDAY");
	&doSub('CRONMON', "@CMON");
	&doSub('CRONWEEK', "@CWEEK");
	&doSub('TSCRIPT', "$TSCRIPT");
	&doSub('SESSION', $session);
	&doSub('TASKS', "@TASKS");
	&doSub('TASKDEL', "$TASKDEL");
	&printTemplate;
}
sub makeSelections {
	$cron_minute->{'*'} = 'Every Minute';
    $cron_minute->{'*/2'} = 'Every Other Minute';
    $cron_minute->{'*/5'} = 'Every Five Minutes';
    $cron_minute->{'*/10'} = 'Every Ten Minutes';
    $cron_minute->{'*/15'} = 'Every Fifteen Minutes';
    $cron_minute->{'0'} = '00';
    $cron_minute->{'1'} = '01';
    $cron_minute->{'2'} = '02';
    $cron_minute->{'3'} = '03';
    $cron_minute->{'4'} = '04';
    $cron_minute->{'5'} = '05';
    $cron_minute->{'6'} = '06';
    $cron_minute->{'7'} = '07';
    $cron_minute->{'8'} = '08';
    $cron_minute->{'9'} = '09';
    $cron_minute->{'10'} = '10';
    $cron_minute->{'11'} = '11';
    $cron_minute->{'12'} = '12';
    $cron_minute->{'13'} = '13';
    $cron_minute->{'14'} = '14';
    $cron_minute->{'15'} = '15';
    $cron_minute->{'16'} = '16';
    $cron_minute->{'17'} = '17';
    $cron_minute->{'18'} = '18';
    $cron_minute->{'19'} = '19';
    $cron_minute->{'20'} = '20';
    $cron_minute->{'21'} = '21';
    $cron_minute->{'22'} = '22';
    $cron_minute->{'23'} = '23';
	$cron_minute->{'24'} = '24';
    $cron_minute->{'25'} = '25';
    $cron_minute->{'26'} = '26';
    $cron_minute->{'27'} = '27';
    $cron_minute->{'28'} = '28';
    $cron_minute->{'29'} = '29';
    $cron_minute->{'30'} = '30';
    $cron_minute->{'31'} = '31';
    $cron_minute->{'32'} = '32';
    $cron_minute->{'33'} = '33';
    $cron_minute->{'34'} = '34';
    $cron_minute->{'35'} = '35';
    $cron_minute->{'36'} = '36';
    $cron_minute->{'37'} = '37';
    $cron_minute->{'38'} = '38';
    $cron_minute->{'39'} = '39';
    $cron_minute->{'40'} = '40';
    $cron_minute->{'41'} = '41';
    $cron_minute->{'42'} = '42';
    $cron_minute->{'43'} = '43';
    $cron_minute->{'44'} = '44';
    $cron_minute->{'45'} = '45';
    $cron_minute->{'46'} = '46';
    $cron_minute->{'47'} = '47';
	$cron_minute->{'48'} = '48';
    $cron_minute->{'49'} = '49';
    $cron_minute->{'50'} = '50';
    $cron_minute->{'51'} = '51';
    $cron_minute->{'52'} = '52';
    $cron_minute->{'53'} = '53';
    $cron_minute->{'54'} = '54';
    $cron_minute->{'55'} = '55';
    $cron_minute->{'56'} = '56';
    $cron_minute->{'57'} = '57';
    $cron_minute->{'58'} = '58';
    $cron_minute->{'59'} = '59';
    $cron_minute->{'60'} = '60';

	$cron_hour->{'*'} = 'Every Hour';
    $cron_hour->{'*/2'} = 'Every Other Hour';
    $cron_hour->{'*/4'} = 'Every Four Hours';
    $cron_hour->{'*/6'} = 'Every Six Hours';
    $cron_hour->{'0'} = '12 AM (Midnight)';
    $cron_hour->{'1'} = '1 AM';
    $cron_hour->{'2'} = '2 AM';
    $cron_hour->{'3'} = '3 AM';
    $cron_hour->{'4'} = '4 AM';
    $cron_hour->{'5'} = '5 AM';
    $cron_hour->{'6'} = '6 AM';
    $cron_hour->{'7'} = '7 AM';
    $cron_hour->{'8'} = '8 AM';
    $cron_hour->{'9'} = '9 AM';
    $cron_hour->{'10'} = '10 AM';
    $cron_hour->{'11'} = '11 AM';
    $cron_hour->{'12'} = '12 PM (Noon)';
    $cron_hour->{'13'} = '1 PM (13)';
    $cron_hour->{'14'} = '2 PM (14)';
    $cron_hour->{'15'} = '3 PM (15)';
    $cron_hour->{'16'} = '4 PM (16)';
    $cron_hour->{'17'} = '5 PM (17)';
    $cron_hour->{'18'} = '6 PM (18)';
    $cron_hour->{'19'} = '7 PM (19)';
    $cron_hour->{'20'} = '8 PM (20)';
    $cron_hour->{'21'} = '9 PM (21)';
    $cron_hour->{'22'} = '10 PM (22)';
    $cron_hour->{'23'} = '11 PM (23)';

	$cron_day->{'*'} = 'Every Day';
    $cron_day->{'1'} = '01';
    $cron_day->{'2'} = '02';
    $cron_day->{'3'} = '03';
    $cron_day->{'4'} = '04';
    $cron_day->{'5'} = '05';
    $cron_day->{'6'} = '06';
    $cron_day->{'7'} = '07';
    $cron_day->{'8'} = '08';
    $cron_day->{'9'} = '09';
    $cron_day->{'10'} = '10';
    $cron_day->{'11'} = '11';
    $cron_day->{'12'} = '12';
    $cron_day->{'13'} = '13';
    $cron_day->{'14'} = '14';
    $cron_day->{'15'} = '15';
    $cron_day->{'16'} = '16';
    $cron_day->{'17'} = '17';
    $cron_day->{'18'} = '18';
    $cron_day->{'19'} = '19';
    $cron_day->{'20'} = '20';
    $cron_day->{'21'} = '21';
    $cron_day->{'22'} = '22';
    $cron_day->{'23'} = '23';
	$cron_day->{'24'} = '24';
    $cron_day->{'25'} = '25';
    $cron_day->{'26'} = '26';
    $cron_day->{'27'} = '27';
    $cron_day->{'28'} = '28';
    $cron_day->{'29'} = '29';
    $cron_day->{'30'} = '30';
    $cron_day->{'31'} = '31';

	$cron_month->{'*'} = 'Every Month';
    $cron_month->{'1'} = 'January';
    $cron_month->{'2'} = 'February';
    $cron_month->{'3'} = 'March';
    $cron_month->{'4'} = 'April';
    $cron_month->{'5'} = 'May';
    $cron_month->{'6'} = 'June';
    $cron_month->{'7'} = 'July';
    $cron_month->{'8'} = 'August';
    $cron_month->{'9'} = 'September';
    $cron_month->{'10'} = 'October';
    $cron_month->{'11'} = 'November';
    $cron_month->{'12'} = 'December';

	$cron_week->{'*'} = 'Every Weekday';
    $cron_week->{'0'} = 'Sunday';
    $cron_week->{'1'} = 'Monday';
    $cron_week->{'2'} = 'Tuesday';
    $cron_week->{'3'} = 'Wednesday';
    $cron_week->{'4'} = 'Thursday';
    $cron_week->{'5'} = 'Friday';
    $cron_week->{'6'} = 'Saturday';
	
	($mtmin,$mthour,$mtday,$mtmon,$mtwday) = @_;

	# MINUTE
	foreach $key (sort keys %{ $cron_minute }) {
		#print "MIN KEY: $key<br>\n";
		$selectValue = $key;
		$selectText = $cron_minute->{$key};
		&getTemplate('option');
		if($selectValue eq $mtmin) {
			&doSub('SELECTED','selected');
		}
		else {
			&doSub('SELECTED','');
		}
		&doSub('VALUE', $selectedValue);
		&doSub('TEXT', $selectText);
		push(@CMIN, $_);
	}

	# HOUR
	foreach $key (sort keys %{ $cron_hour }) {
		#print "HOUR KEY: $key<br>\n";
		$selectValue = $key;
		$selectText = $cron_hour->{$key};
		&getTemplate('option');
		if($selectValue eq $mthour) {
			&doSub('SELECTED','selected');
		}
		else {
			&doSub('SELECTED','');
		}
		&doSub('VALUE', $selectedValue);
		&doSub('TEXT', $selectText);
		push(@CHOUR, $_);
	}

	# DAY
	foreach $key (sort keys %{ $cron_day }) {
		#print "DAY KEY: $key<br>\n";
		$selectValue = $key;
		$selectText = $cron_day->{$key};
		&getTemplate('option');
		if($selectValue eq $mtday) {
			&doSub('SELECTED','selected');
		}
		else {
			&doSub('SELECTED','');
		}
		&doSub('VALUE', $selectedValue);
		&doSub('TEXT', $selectText);
		push(@CDAY, $_);
	}
	&getTemplate('option');
	# MONTH
	foreach $key (sort keys %{ $cron_month }) {
		#print "MONTH KEY: $key<br>\n";
		$selectValue = $key;
		$selectText = $cron_month->{$key};
		&getTemplate('option');
		if($selectValue eq $mtmon) {
			&doSub('SELECTED','selected');
		}
		else {
			&doSub('SELECTED','');
		}
		&doSub('VALUE', $selectedValue);
		&doSub('TEXT', $selectText);
		push(@CMON, $_);
	}
	&getTemplate('option');
	# Week Day
	foreach $key (sort keys %{ $cron_week }) {
		#print "WEEK KEY: $key<br>\n";
		$selectValue = $key;
		$selectText = $cron_week->{$key};
		&getTemplate('option');
		if($selectValue eq $mtwday) {
			&doSub('SELECTED','selected');
		}
		else {
			&doSub('SELECTED','');
		}
		&doSub('VALUE', $selectedValue);
		&doSub('TEXT', $selectText);
		push(@CWEEK, $_);
	}
	return("@CMIN","@CHOUR","@CDAY","@CMON","@CWEEK");
}
sub provision { # ADD DATABASE TYPE SELECTION, INTERNAL, FLATFILE, BIND9 DLZ cleanup - NEEDS EXEC ENGINE OUTPUT CLEANUP!
		$err = '';
		$samba_path = $settings->{'system'}->{'samba'}->{'path'};
		$resolvFile = $settings->{'system'}->{'dns'}->{'resolv'};
		$samba_client = $settings->{'system'}->{'samba'}->{'SMBCLIENT'};
		$samba_service = 'smb.service';
		$named_service = 'named.service';
		$samba_krb5 = $settings->{'system'}->{'samba'}->{'krb5'};
		$krb5 = $settings->{'system'}->{'krb5'}->{'path'};
		
		&getTemplate('provision_head');
		&printTemplate;
		
		if($type eq 'newdc') {
			$message = "Setting up your new domain...";
		}
		elsif($type eq 'olddc') {
			$message = "Joining an existing domain.";
		}
		
		&getTemplate('provision');
		&doSub("MESSAGE", $message);
		&printTemplate;
		
		$out_str = "";
		`chmod 0777 $resolvFile`;
		`echo "search $netInfo{'DOMAIN'}" > $resolvFile`;
		
		if($type eq "newdc"){ #PROVISION NEW DC IF SELECTED
			$Admp = &rand(8); # Random string generator
			if(!$backend) { #(SAMBA_INTERNAL, BIND9_FLATFILE, BIND9_DLZ, OR NONE)
				$backend="BIND9_DLZ";
			}
			$smb_provision = "$samba_tool domain provision --realm=$netInfo{'REALM'} --domain=$netInfo{'DOMAIN'} --adminpass='$Admp' --server-role=dc --dns-backend=$backend";
			
			$message = "Initializing random password generator.";
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
	
			$message = "<b>" . $netInfo{'DOMAIN'} ." Administrator Password: " . $Admp . "</b><br>(<u>You will need this for the domain administrator login!</u>)";
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
		
			$message = "Provison domain: $netInfo{'REALM'}<br>";
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
			
			
			@message = `sudo $smb_provision`;
			$message = "@message";
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
			
			$message = "Use $netInfo{'IPADDR'} for DNS.";
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
			
			`echo 'nameserver $netInfo{'IPADDR'}' >> $resolvFile`;
		}
	
		if($type eq "olddc"){ #PROVISION SECONDARY DC IF SELECTED	
			if(!$backend) { #(SAMBA_INTERNAL, BIND9_FLATFILE, BIND9_DLZ, OR NONE)
				$backend="BIND9_DLZ";
			}
			$smb_provision = "$samba_tool domain join $netInfo{'REALM'} DC -Uadministrator\@$netInfo{'REALM'} --password=$PASS1 --ipaddress=$PDCIP --realm=$netInfo{'REALM'} --dns-backend=$backend";
			$smb_adddns = "echo '$PASS1' |sudo $samba_tool dns add $PDCIP $netInfo{'REALM'} $netInfo{'HOST'} A $netInfo{'IPADDR'} -U administrator\@$netInfo{'REALM'}";
			
			$resolvFile = $settings->{'system'}->{'dns'}->{'resolv'};
			
			$message = "Checking domain passwords.";
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
			
			if($PASS1 eq $PASS2) {
				$message = "Passwords matches.";
			}
			else {
				$message = "Passwords do not match.";
			}
			
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
			
			$message = "Using $PDCIP as DNS server..<br>";
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;	
			
			if($PDCIP){
				$message = "Update DNS Service.<br>";
				`echo 'search $netInfo{'REALM'}' > $resolvFile`;
				`echo 'nameserver $PDCIP' >> $resolvFile`;
				$message .= "Start DNS Service..<br>";
				`systemctl stop $named_service`;
				`systemctl start $named_service`;
				&getTemplate('provision');
				&doSub("MESSAGE", $message);
				&printTemplate;
			}
			else {
				$message = "Missing primary DC address..<br>";
				&getTemplate('provision');
				&doSub("MESSAGE", $message);
				&printTemplate;
				exit 0;
			}
	
			####### ADD DNS RECORD
			$message = "Run command to create DNS record for new DC: <br>";
			$message .= "$smb_adddns<br>";
			$message .= `$smb_adddns`;
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
					
			$message = "Provision secondary domain controller for: $netInfo{'REALM'}<br>";
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
			
			####### PROVISION!
			$formatted = '';
			
			@message = `sudo $smb_provision`;
			$message = "@message";
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
		
			##DNS TEST: 
			$Rtest = 0;
			@R1 = `host -t A $netInfo{'FQDN'}.`;
			$message = "Testing for DNS records in the domain.";
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
			
			$message = "<ul>\n";
			foreach (@R1) {
				if($_ =~ /not found/) { $Rtest++; }
				$message .= "<li><small>$_<small></li>";
			}
			$message .= "</ul>\n";
			$message .= "Done.<br>\n";
			
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
			
			$message = "Also use $PDCIP for DNS.";
			&getTemplate('provision');
			&doSub("MESSAGE", $message);
			&printTemplate;
			
			`echo 'nameserver $PDCIP' >> $resolvFile`;
		}
	
		#sleep(7);
	
		#auto start domain service
		$message = "Enable samba on boot...";
		`sudo systemctl enable $samba_service`;
		$message .= "Done<br>\n";
		
		&getTemplate('provision');
		&doSub("MESSAGE", $message);
		&printTemplate;

		$message = "Start Samba service...";
		`sudo systemctl start $samba_service`;
		$message .= "Done<br>\n";
		
		&getTemplate('provision');
		&doSub("MESSAGE", $message);
		&printTemplate;
		
		@output = `systemctl status $samba_service`;
		
		$testpass=0;
		foreach(@output) {
			if($_ =~ /Active: active \(running\)/gi) {
				$testpass++;
			}
		}
		
		if($testpass > 0) {
			$message = "Starting samba was successful.<br>\n";
		}
		else {
			$message = "<b style=\"color:red;\">Failed to start.</b><br>\n";
			$err++;
		}
		
		&getTemplate('provision');
		&doSub("MESSAGE", $message);
		&printTemplate;
	
		#PROVISION KERBEROS
		$message = "Set permissions on '$krb5'.<br>";
		`sudo chmod 0777 $krb5`;
		
		$message .= "Copy '$samba_krb5' to '$krb5'.<br>";
		`echo yes | sudo cp -rf $samba_krb5 $krb5`;
		
		&getTemplate('provision');
		&doSub("MESSAGE", $message);
		&printTemplate;
		
		#PROVISION DNS IF DC ONLY
		#auto start domain service
		$message = "Enable DNS on boot...";
		`sudo systemctl enable $named_service`;
		`sudo systemctl start $named_service`;
		$message .= "Done<br>\n";
		
		&getTemplate('provision');
		&doSub("MESSAGE", $message);
		&printTemplate;
		
		#PROVISION NTP IF NEWDC ONLY
		if($type eq "newdc") {
			$message = "Start NTP service on boot...";
			`sudo systemctl enable $settings->{'system'}->{'services'}->{'time_service'}`;
			$message .= "Done.<br>\n";
			$message .= "Start time service...";
			`sudo systemctl start $settings->{'system'}->{'services'}->{'time_service'}`;
			$message .= "NTP Done.<br><br>\n";		
		}
		
		&getTemplate('provision');
		&doSub("MESSAGE", "$out_str");
		&printTemplate;
	
		# NEED TO SET JOINPASSBSED ON OLD DC OR NEW DC SELECTION:
		# `echo '$JOINPASS' | realm join -U administrator@RAZDC.LAN DC01.RAZDC.LAN`
		
		if($err) {
			$message = "<b>Errors were detected! You can <a href=\"#\" onclick=\"plax.update('/cgi-bin/core.pl?do=sub&task=reset&session=$session','setupContent'); return false;\">click here to reset</a> and try again, or ignore this and continue with the link below. </b>\n<br>\n";
		}
		else {
			$message = qq~<input type="button" onclick="window.open('/cgi-bin/core.pl?do=login','_top');" value="Open RazDC!"><br>~;
		}
		&getTemplate('provision');
		&doSub("MESSAGE", $message);
		&printTemplate;
		
		&getTemplate('provision_foot');
		&printTemplate;
}
sub reset {
		&getTemplate('reset');
		&doSub("SESSION", $session);
		&printTemplate;
	}
sub reset_confirm { # 12/1/2022
	$samba_service = $settings->{'system'}->{'services'}->{'samba_service'};
	$named_service = $settings->{'system'}->{'services'}->{'named_service'};
	$srcFile = $settings->{'system'}->{'network'}->{'ip_data'};
	$NIC=`ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}'`;
	$WSNIC=`$(echo -e "${NIC}" | tr -d '[:space:]')`;
	
	# Capture output for future debugging if we need it. use generic vars because we dont care rn.
	&runCmd("systemctl stop $samba_service");
	&runCmd("systemctl disable $samba_service");
	&runCmd("systemctl stop $named_service");
	&runCmd("systemctl disable $named_service");
	&runCmd("rm -rf /usr/local/samba/private/*");
	&runCmd("rm -rf /usr/local/samba/etc/smb.conf");
	&runCmd("rm -rf /usr/local/samba/var/locks/sysvol/*");
	`sudo echo '' > $srcFile`;
	`sudo nmcli dev mod $WSNIC ipv4.method auto`;
	`sudo nmcli dev reapply $WSNIC`;
	`sudo nmcli con up $WSNIC`;
		
	&getTemplate('reset_confirm');
	&doSub("MESSAGE","RazDC has been reset.");
	&printTemplate;
}
sub unlock { # FUTURE UNLOCK ADMIN
	&getTemplate('nothing');
	&printTemplate;
	}
sub unlocked { # FUTURE UNLOCK ADMIN CONFIRM
	&getTemplate('nothing');
	&printTemplate;
	}
sub getRazUsers { # WIP! - Need save routines & create routines!
# test:
#for (sort keys %{ $users->{'admins'} }) {
# print "$_ => ${ $users->{'admins'} }{$_}\n";}
	@RazDCUserTabs;
	@RazDCUserTabContent;
	
	foreach $key (keys %{ $users->{'admins'} }) {
		$username = $key;
		#push(@LINEENTRY, $username);
		&getTemplate('RazUserEntry');
		&doSub("LUSER",$username);
		push(@RazDCUserTabs, "$_");
	}
	
	foreach $key (keys %{ $users->{'admins'} }) {
		$username = $key;
		$enable = ${ $users->{'admins'} }{$key}{'enable'}; # T/F
		$dash = ${ $users->{'admins'} }{$key}{'dash'}; # T/F
		$refresh = ${ $users->{'admins'} }{$key}{'refresh'}; # T/F
		$language = ${ $users->{'admins'} }{$key}{'language'}; # T/F
		$system = ${ $users->{'admins'} }{$key}{'system'}; # T/F
		$server = ${ $users->{'admins'} }{$key}{'server'}; # T/F
		$network = ${ $users->{'admins'} }{$key}{'network'}; # T/F
		$users = ${ $users->{'admins'} }{$key}{'users'}; # T/F
		$unlock = ${ $users->{'admins'} }{$key}->{'unlock'}; # T/F
        $logs = ${ $users->{'admins'} }{$key}{'logs'}; # T/F
        $reset = ${ $users->{'admins'} }{$key}{'reset'}; # T/F
		$power = ${ $users->{'admins'} }{$key}{'power'}; # T/F
        $password = ${ $users->{'admins'} }{$key}{'password'}; # Pasword Hash
        $name = ${ $users->{'admins'} }{$key}{'name'}; # username
		
		if($enable eq 'true') { $enable = 'checked'; } else { $enable = ''; }
		if($dash eq 'true') { $dash = 'checked'; } else { $dash = ''; }
		if($refresh eq 'true') { $refresh = 'checked'; } else { $refresh = ''; }
		if($language eq 'true') { $language = 'checked'; } else { $language = ''; }
		if($system eq 'true') { $system = 'checked'; } else { $system = ''; }
		if($server eq 'true') { $server = 'checked'; } else { $server = ''; }
		if($network eq 'true') { $network = 'checked'; } else { $network = ''; }
		if($users eq 'true') { $users = 'checked'; } else { $users = ''; }
		if($unlock eq 'true') { $unlock = 'checked'; } else { $unlock = ''; }
		if($logs eq 'true') { $logs = 'checked'; } else { $logs = ''; }
		if($reset eq 'true') { $reset = 'checked'; } else { $reset = ''; }
		if($power eq 'true') { $power = 'checked'; } else { $power = ''; }
		
		&getTemplate('razUserTabContent');
		&doSub("LUSER",$username);
		&doSub("LENABLE",$enable);
		&doSub("LDASH",$dash);
		&doSub("LREFRESH",$refresh);
		&doSub("LLANG",$language);
		&doSub("LSYS",$system);
		&doSub("LSERV",$server);
		&doSub("LNET",$network);
		&doSub("LADU",$users);
		&doSub("LUADM",$unlock);
		&doSub("LLOG",$logs);
		&doSub("LRESET",$reset);
		&doSub("LPOWER",$power);
		&doSub("LPASS",$password);
		&doSub("LDELETE",$username);
		push(@RazDCUserTabContent, "$_");
		}
		
	&getTemplate('razUsers');
	&doSub("USERTABS","@RazDCUserTabs");
	&doSub("TABCONTENT","@RazDCUserTabContent");
	&printTemplate;
	}
sub network { # WIP - GUI NETWORK CONFIG CHANGES - DANGEROUS BUT HELPFUL!
	&getTemplate('ipaddr');
	&doSub("MESSAGE", $ipmessage);
	&doSub("HOST", $netInfo{'HOST'});
	&doSub("FQDN", $netInfo{'FQDN'});
	&doSub("DOMAIN", $netInfo{'DOMAIN'});
	&doSub("REALM", $netInfo{'REALM'});
	&doSub("IPADDR", $netInfo{'IPADDR'});
	&doSub("NETMASK", $netInfo{'NETMASK'});
	&doSub("GWADDR", $netInfo{'GATEWAY'});
	&doSub('SESSION', $session);
	&doSub('MESG', $mesg);
	&printTemplate;
}
sub fullnet { 
	$resolvFile = $settings->{'system'}->{'dns'}->{'resolv'};
		@GLOBALNS;
		@DNS_DATA = &runCmd("cat $resolvFile");

		#(@DNS_DATA) = split(/\\r\\n/, $DNS_DATA);
		foreach $line (@DNS_DATA) {
			#print "Line: $line<br>\n";
			if($line =~ m/search/) { 
				$search = $line;
				$search =~ s/search //gi;
				$search =~ tr/\015//d;
			}
			if($line =~ m/nameserver/) { 
				$dns = $line;
				$dns =~ s/nameserver //gi;
				$dns =~ tr/\015//d;
				$dns =~ s/\\s//g;
				chomp($dns);
				push(@GLOBALNS, $dns);
			}
		}
		
		chomp($search);
		
		$GLOBALNS = join('&#13;&#10;',@GLOBALNS);
	
	&getTemplate('fullnet');
	&doSub("MESSAGE", $ipmessage);
	&doSub("HOST", $netInfo{'HOST'});
	&doSub("FQDN", $netInfo{'FQDN'});
	&doSub("DOMAIN", $netInfo{'REALM'});
	&doSub("REALM", $netInfo{'REALM'});
	&doSub("IPADDR", $netInfo{'IPADDR'});
	&doSub("NETMASK", $netInfo{'NETMASK'});
	&doSub("GWADDR", $netInfo{'GATEWAY'});
	&doSub("GLOBALNS", $GLOBALNS);
	&doSub('SESSION', $session);
	&doSub('MESG', $mesg);
	&printTemplate;
}
sub save_ipaddr { # 12/1/2022
	$srcFile = $settings->{'system'}->{'network'}->{'ip_data'};
	$netFile = $settings->{'system'}->{'network'}->{'net_data'};
	$resolvFile = $settings->{'system'}->{'dns'}->{'resolv'};
	$NIC=`ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}'`;
	$UUID=`nmcli con | awk -F' ' '$0 !~ "NAME|^[^0-9azA-Z]"{print $4;getline}'`;
	$WSNIC=`$(echo -e "${NIC}" | tr -d '[:space:]')`;
	$update_hwaddr=`cat /sys/class/net/$WSNIC/address`;
	$numbits=&get_bits($update_netmask);
	
	($a, $b, $c, $d) = split(/\./, $update_ipaddr);
	
	$netRange =  "$a.$b.$c.0/".$numbits;
	$firewall = &loadJSON('firewall');
	#$firewall->{'allow'}[1]->{'host'} = "$netRange";
	
	$q=0;
	$FWsaved = 'false';
	foreach(@{ $firewall->{'allow'} }) {
		if($firewall->{'allow'}[$q]->{'comment'} eq 'LAN') {
			$firewall->{'allow'}[$q]->{'host'} = "$netRange";
			$FWsaved = 'true';
		}
		$q++;	
	}
	
	if($FWsaved == 'false') {
		$q++;
		$firewall->{'allow'}[$q]->{'host'} = "$netRange";
		$firewall->{'allow'}[$q]->{'comment'} = 'LAN';
	}
	
	&saveConfig('firewall');
	#&reload_fw;
	
print qq~
	Reconnect usign the new hostname or address to continue:
	<br><br>
	<a href="https://$update_ipaddr/">https://$update_ipaddr</a> or <a href="https://$update_host/">https://$update_host</a>
~;


	open(STORE, "> $srcFile") or print "Failed to open storeFile: $!<br>";
print STORE qq~
TYPE=Ethernet
DEVICE=$WSNIC
BOOTPROTO=static
ONBOOT=yes
NM_CONTROLLED=no
IPADDR=$update_ipaddr
NETMASK=$update_netmask
USERCTL=no
PEERDNS=no
HWADDR=$update_hwaddr
UUID=$UUID
PREFIX=$numbits
IPV6INIT=no
~;
	close(STORE);


	(@NS) = split(/\s/, $update_dns);
	foreach(@NS) {
		$verified = &verifyIP($_);
    }
	&runCmd("chmod 0777 $resolvFile");

	if($update_domain) { &runCmd("echo 'search $update_domain' > $resolvFile"); }
	foreach(@NS) { &runCmd("echo 'nameserver $_' >> $resolvFile"); }

	$mesg = "Settings Saved. Restarting DNS service for changes to take effect.<br>";

	&runCmd("systemctl restart named.service");

	`sudo echo "$update_ipaddr $update_host $update_host.$update_domain" > /etc/hosts`;
	`sudo hostnamectl set-hostname $update_host;`;

	open(NET, "> $netFile") or print "Failed to open $netFile: $!<br>";

print NET qq~
NETWORKING=yes
HOSTNAME=$update_host.$update_domain
GATEWAY=$update_gwaddr
~;
close(NET);
	

`sudo nmcli con mod $WSNIC ipv4.addresses $update_ipaddr/$numbits`;
`sudo nmcli con mod $WSNIC ipv4.gateway $update_gwaddr`;
`sudo nmcli con mod $WSNIC ipv4.method manual`;
`sudo nmcli con up $WSNIC`;

	close(SRC);

	`sudo nmcli device reapply $WSNIC`;
	`sudo nmcli con up $WSNIC`;
	#&reload_fw;
	#`sudo systemctl restart httpd`;
}
sub localhosts { # WIP - EDIT LOCAL /etc/hosts file
	@localhosts = &runCmd("sudo cat /etc/hosts");
	&getTemplate('localhosts');
	&doSub("LOCALHOSTS", @localhosts);
	&doSub('SESSION', $session);
	&doSub('MESG', $mesg);
	&printTemplate;
}
sub smtpoptions { # FUTURE SMTP OPTIONS
	&getTemplate('nothing');
	&printTemplate;	
}
sub login { 
	# Load Login
	##############
	&printHeader('RazDC - Login');
	&getTemplate('login');
	doSub("ERRMESSAGE", "$_[0]");
	&printTemplate;
}
sub home { 
	# Load Home
	##############
	if(-e $settings->{'system'}->{'samba'}->{'CONFIGFILE'}) {
		&index;
	}
	else {
		if( $netInfo{'HOST'} && $netInfo{'DOMAIN'} && $netInfo{'IPADDR'} && $netInfo{'REALM'} ) {
			&setup;
		}
		else {
			&notready;
		}
	}
}
sub index { 
	# Index
	##############
	&printHeader('RazDC ' . $razdc->{'version'});
	&getTemplate('loggedIn');
	&doSub("RAZCOOKIE", $settings->{'cookieName'});
	&doSub("RAZIP", $netInfo{'IPADDR'});
	&printTemplate;
}
sub setup { 
	# Setup
	##############
	&printHeader('RazDC - Setup');	
	&getTemplate('setup');
	doSub("SESSION", $session);
	&printTemplate;
}
#########################################################################################
sub notready { 
	# Not Ready - Begin
	##############
	
	&printHeader('RazDC - Not Ready');
	&getTemplate('not_ready');
	&doSub("SETUPDATA", $setup_win);
	&doSub("SESSION", $session);
	&printTemplate;
}
#########################################################################################
# ALSO NEED TO ELIMINATE JSON MODULE.
sub saveConfig { 
	# Save JSON Config to file
	#############################
	# create JSON object
	$json = new JSON;
	($jconfig) = @_; # JSON Config
	$jpath = "/razdc/www/json/$jconfig.json";
	#Encode PERL to JSON
	$json_text =$json->pretty->encode( ${$jconfig} );

	chmod(0777," $jpath");
	open(H, ">$jpath");
	print H $json_text or print "Failed to save JSON $jconfig: $!";
	close(H); 
}
sub loadJSON {
	# JSON Config
	############################################
	# $rjfh means "Requested JSON File Handle"

	($jconfig) = @_; # JSON Config
	$jpath = "/razdc/www/json/$jconfig.json";
	{
		local $/; #Enable 'slurp' mode
		open (RJFH, "<", "$jpath" ) or print "Unable to access system config file (" . $jconfig . "): " . $! . "\n";
		$rjson = <RJFH>;
		close(RJFH);
	}
	$rjson =~ s/:/=>/g;
	$rjson =~ s/\@/\\@/g;
	$return=eval($rjson);
	return($return);
}
sub getConfig { 
	$razdc = &loadJSON('razdc');
	$settings = &loadJSON('settings');
	$users = &loadJSON('users');
	$svn = &loadJSON('svn');
	$perms = &loadJSON('perms');
	#$smb = &loadJSON('smb'); # future loader for synamic SMB config generator to manage shares
	
	$razdcName = $razdc->{'name'};
	$version = $razdc->{'version'};
	$language =  $settings->{'language'};
	
	#$email = $data->{'email'}; # Enable for future notifications	
	$cookieName = $settings->{'cookieName'};
	$timeout = $settings->{'timeout'};
	#$config_user = $users->{'admins'}{"$username"}->{'name'};
	#$config_pass = $users->{'admins'}{"$username"}->{'password'};
}
sub JSON {
	#
	# The quick and dirty way is to change the JSON syntax to Perl syntax and then Eval it back into Perl, like this:
	# I might expand on this to remove module dependancy in the future. Until then i will use JSON module.
	#
	#############################
	#
	# $JSON='json string here';
	# $JSON=~s/":/"=>/g;
	# $PERL=eval $JSON;
	#############################
	
	# Build Client JSON
	#####################		
	if($task eq 'CONFIG'){
print qq~
	{
    "_comment":"$razdc->{'_comment'}",
	"name": "$razdc->{'name'}",
	"version": "$razdc->{'version'}",
	"language": "$settings->{'language'}",
~;

# EXCLUDE FOR NOW
#	"email" : "$smtp->{'email'}",

print qq~
	"cookieName" : "$settings->{'cookieName'}",
	
	"os" : {
		"name" : "$settings->{'os'}->{'name'}",
		"version" : "$settings->{'os'}->{'version'}",
		"arch" : "$settings->{'os'}->{'arch'}"
	}
~;		
	}
	if($task eq 'MENU'){

print qq~
		{
		"menu":[
~;

	if( $users->{'admins'}->{$session_user}->{'dash'} eq 'true' ) {
print qq~
		{
         "id":"dash",
		 "order":"0",
         "img":"/images/dashboard.png",
         "alt":"Dashboard",
         "onclick":"tab('dash');setTimeout('setupBlocks(window.innerWidth)', 1000);"
        },
~;
	}
#	if( $users->{'admins'}->{$session_user}->{'language'} eq 'true' ) {
#print qq~
#		{
#         "id":"language",
#		 "order":"2",
#         "img":"/images/language2.png",
#         "alt":"Language",
#         "onclick":"tab('language');subMenu('Language');"
#        },
#~;
#	}
	if( $users->{'admins'}->{$session_user}->{'system'} eq 'true' ) {
print qq~
		{
         "id":"system",
		 "order":"3",
         "img":"/images/system.png",
         "alt":"System",
         "onclick":"tab('system');subMenu('System');"
        },
~;
	}
	if( $users->{'admins'}->{$session_user}->{'server'} eq 'true' ) {
print qq~
		{
         "id":"server",
		 "order":"4",
         "img":"/images/server.png",
         "alt":"Server",
         "onclick":"tab('server');subMenu('Server');"
        },
~;
	}
	if( $users->{'admins'}->{$session_user}->{'network'} eq 'true' ) {
print qq~
		{
         "id":"network",
		 "order":"5",
         "img":"/images/network.png",
         "alt":"Network",
         "onclick":"tab('network');subMenu('Network');"
        },
~;
	}	
	if( $users->{'admins'}->{$session_user}->{'users'} eq 'true' ) {
print qq~
		{
         "id":"users",
		 "order":"6",
         "img":"/images/users.png",
         "alt":"Users",
         "onclick":"tab('users');subMenu('Users');"
        },
~;
	}
	
	if( $users->{'admins'}->{$session_user}->{'logs'} eq 'true' ) {
print qq~
		{
         "id":"logs",
		 "order":"7",
         "img":"/images/logs.png",
         "alt":"Logs",
         "onclick":"tab('logs');subMenu('Logs');"
        },
~;
	}
	# ALWAYS PRINT EXIT BUTTON AND LIGHT/DARK MODE
print qq~
		{
         "id":"theme",
		 "order":"11",
         "img":"/images/theme.png",
         "alt":"Theme",
         "onclick":"toggleTheme(); return false;"
        },
	  {
         "id":"exit",
		 "order":"12",
         "img":"/images/exit.png",
         "alt":"Logoff",
         "onclick":"window.open('/cgi-bin/core.pl?do=login','_top');"
      }
~;

print qq~
		]
	}
~;

	}
	if($task eq 'DASH'){ # ADD REFRESH TO DASH
			if( $users->{'admins'}->{$session_user}->{'dash'} eq 'true' ) {
print qq~
{
	"widgets":[
      {
         "title":"System Information",
         "container":"verinfo",
         "content":"/cgi-bin/core.pl?do=sub&task=versionInfo&session=$session"
      },
      {
         "title":"Disk Space",
         "container":"diskusage",
         "content":"/cgi-bin/core.pl?do=sub&task=dash_volumes&session=$session"
      },
      {
         "title":"Services",
         "container":"servicestat",
         "content":"/cgi-bin/core.pl?do=sub&task=dash_services&session=$session"
      },
	  {
		 "title":"Realtime CPU",
		 "container":"rtcpu",
		 "html":"<canvas id=cpu-chart width=454 height=215></canvas>"
	  },
	  {
		 "title":"Realtime Memory",
		 "container":"rtmem",
		 "html":"<canvas id=mem-chart width=454 height=215></canvas>"
	  }
   ]
}
~;
	}
	}
	if($TASK eq 'Language'){
	if( $users->{'admins'}->{$session_user}->{'language'} eq 'true' ) {
print qq~
      {
		"text":"Language",
         "options":[
            {
               "text":"Language",
               "id":"LanguageMenu0",
			   "style":"background-image: url('/images/open.gif');",
               "options":[
~;


	$lang_path = $settings->{'system'}->{'languages'}->{'path'};
	
	opendir(LANG_FILES, $lang_path) or die "could not open $lang_path: $!";
	@lang_files = readdir(LANG_FILES) or die "could not readdir $lang_path: $!";
	for $entry (@lang_files) {
		next if $entry =~ /^[\.]/;
		next if -d "$lang_path/$entry";
		push(@LJSON, $entry);
	}
	$lang_count = @LJSON;
	$lc = 1;
	sort @LJSON;
	for $lang_file (@LJSON) {
		#next if $lang_file =~ /^[.]/;
		#next if -d "$lang_path/$lang_file";
		local $/; #Enable 'slurp' mode
		open (FH, "<", "$lang_path/$lang_file" ) or die "Unable to access system config file: " . $! . "\n";
		$lang = <FH>;
		close(FH);
				
		$this_lang = decode_json("$lang");
		$lang_name = $this_lang->{'name'};
		$lang_abbr = $this_lang->{'abbreviation'};
	
print qq~
					{
						"text" : "$lang_name ($lang_abbr)",
						"onclick":"win('','Set Language','/cgi-bin/core.pl?do=sub&task=language&lang=$lang_abbr&session=$session','600','300','language');"
~;
		if($lc < $lang_count) {
			print "					},\n";
		}
		else {
			print "					}\n";
		}
		$lc++;
	}
	closedir(LANG_FILES);


print qq~
               ]
            }
         ]
	}
~;
	}		
	}
	if($task eq 'SEARCH'){
print qq~
{
	"name" : "RazDC4 Search Index",
	"dictionary" : [
~;

if( $users->{'admins'}->{$session_user}->{'system'} eq 'true' ) {
print qq~
			{
				"parent" : "System",
				"menu" : "Settings",
				"text" : "My RazDC Password",
				"link" : "win('','Change Password','/cgi-bin/core.pl?do=sub&task=administrator&session=$session','600','300','system');"
			},
			{
				"parent" : "System",
				"menu" : "Settings",
				"text" : "System Services",
				"link" : "win('','Services','/cgi-bin/core.pl?do=sub&task=services&session=$session','700','400','system');"
			},
			{
				"parent" : "System",
				"menu" : "Settings",
				"text" : "Network Information",
				"link" : "win('','Network Interface','/cgi-bin/core.pl?do=sub&task=int&session=$session','500','300','system');"
			},
			{
				"parent" : "System",
				"menu" : "Settings",
				"text" : "Time & Region",
				"link" : "win('','Region & Location','/cgi-bin/core.pl?do=sub&task=region&session=$session','500','300','system');"
			},
			{
				"parent" : "System",
				"menu" : "Settings",
				"text" : "Tasks & Schedules",
				"link" : "win('','Region & Location','/cgi-bin/core.pl?do=sub&task=region&session=$session','500','300','system');"
			},
			{
				"parent" : "System",
				"menu" : "Settings",
				"text" : "RazDC Users",
				"link" : "win('','Region & Location','/cgi-bin/core.pl?do=sub&task=region&session=$session','500','300','system');"
			},
			{
				"parent" : "System",
				"menu" : "SSL Certificates",
				"text" : "New Certificate",
				"link" : "win('','New SSL Certificate','/cgi-bin/core.pl?do=sub&task=sslnew&session=$session','500',500,'system');"
			},
			{
				"parent" : "System",
				"menu" : "SSL Certificates",
				"text" : "Manage SSL",
				"link" : "win('','Edit SSL Certificate','/cgi-bin/core.pl?do=sub&task=sslold&session=$session','500','500','system'); return false;"
			},
			{
				"parent" : "System",
				"menu" : "Firmware",
				"text" : "Backup",
				"link" : "win('','RazDC Backup','/cgi-bin/core.pl?do=sub&task=backup&session=$session','600','250','system');"
			},
			{
				"parent" : "System",
				"menu" : "Firmware",
				"text" : "Restore",
				"link" : "win('','RazDC Restore','/cgi-bin/core.pl?do=sub&task=restore&session=$session','600','250','system');"
			},
			{
				"parent" : "System",
				"menu" : "Firmware",
				"text" : "Update",
				"link" : "win('','RazDC Update','/cgi-bin/core.pl?do=sub&task=update&session=$session','600','280','system');"
			},
			{
				"parent" : "System",
				"menu" : "Diagnostics",
				"text" : "Domain Shares",
				"link" : "win('','Domain Share Diagnostics','/cgi-bin/core.pl?do=sub&task=sdiag&session=$session','500','500','system');"
			},
			{
				"parent" : "System",
				"menu" : "Diagnostics",
				"text" : "Domain Controller",
				"link" : "win('','DC Diagnostics','/cgi-bin/core.pl?do=sub&task=dcdiag&session=$session','500','500','system');"
			},
			{
				"parent" : "System",
				"menu" : "Diagnostics",
				"text" : "DNS Internal",
				"link" : "win('','Internal DNS Diagnostics','/cgi-bin/core.pl?do=sub&task=intdiag&session=$session','500','500','system');"
			},
			{
				"parent" : "System",
				"menu" : "Diagnostics",
				"text" : "DNS External",
				"link" : "win('','External DNS Diagnostics','/cgi-bin/core.pl?do=sub&task=exdiag&session=$session','500','500','system');"
			},
			{
				"parent" : "System",
				"menu" : "Diagnostics",
				"text" : "Kerberos Test",
				"link" : "win('','Kerberos Diagnostics','/cgi-bin/core.pl?do=sub&task=krb5diag&session=$session','500','500','system');"
			},
~;
}
	
if( $users->{'admins'}->{$session_user}->{'server'} eq 'true' ) {
print qq~
			{
				"parent" : "Server",
				"menu" : "Domain",
				"text" : "Information",
				"link" : "win('','Domain Information','/cgi-bin/core.pl?do=sub&task=domaininfo&session=$session','600','300','server');"
			},
			{
				"parent" : "Server",
				"menu" : "Domain",
				"text" : "Password Policy",
				"link" : "win('','Password Policy','/cgi-bin/core.pl?do=sub&task=passpol&session=$session','600','500','server');"
			},
			{
				"parent" : "Server",
				"menu" : "Domain",
				"text" : "Role Management",
				"link" : "win('','FSMO Roles','/cgi-bin/core.pl?do=sub&task=fsmo&session=$session','600','500','server');"
			},
			{
				"parent" : "Server",
				"menu" : "Domain",
				"text" : "Function Levels",
				"link" : "win('','Function Levels','/cgi-bin/core.pl?do=sub&task=funclvl&session=$session','800','250','server');"
			},
			{
				"parent" : "Server",
				"menu" : "Domain",
				"text" : "Domain Trust",
				"link" : "win('','Domain Trust','/cgi-bin/core.pl?do=sub&task=fsmo&session=$session','600','500','server');"
			},
			{
				"parent" : "Server",
				"menu" : "Domain",
                "text" : "Group Policies",
                "link" : "win('','Group Policies','/cgi-bin/core.pl?do=sub&task=gpo&session=$session','800','250','server');"
            },
			{
				"parent" : "Server",
				"menu" : "DHCP",
				"text" : "Settings",
				"link" : "win('','DHCP Settings','/cgi-bin/core.pl?do=sub&task=dhsettings&session=$session','600','600','server');"
			},
			{
				"parent" : "Server",
				"menu" : "DHCP",
				"text" : "Client Leases",
				"link" : "win('','Network Clients','/cgi-bin/core.pl?do=sub&task=dhclient&session=$session','600','600','server');"
			},
			{
				"parent" : "Server",
				"menu" : "DHCP",
				"text" : "New Scope",
				"link" : "win('','New DHCP Scope','/cgi-bin/core.pl?do=sub&task=newscope&session=$session','700','600','server');"
			},
			{
				"parent" : "Server",
				"menu" : "DHCP",
				"text" : "New Static",
				"link" : "win('','New Static Host','/cgi-bin/core.pl?do=sub&task=newstatic&session=$session','700','300','server');"
			},
			{
				"parent" : "Server",
				"menu" : "DNS",
				"text" : "Options",
				"link" : "win('','Nameserver Options','/cgi-bin/core.pl?do=sub&task=nsoptions&session=$session','600','700','server');"
			},
			{
				"parent" : "Server",
				"menu" : "DNS",
				"text" : "Internal Resolution",
				"link" : "win('','Internal Resolution','/cgi-bin/core.pl?do=sub&task=intns&session=$session','600','300','server');"
			},
			{
				"parent" : "Server",
				"menu" : "DNS",
				"text" : "Forwarding Servers",
				"link" : "win('','Forward Lookups','/cgi-bin/core.pl?do=sub&task=forward&session=$session','600','300','server');"
			},
			{
				"parent" : "Server",
				"menu" : "DNS",
				"text" : "Recursive Lookups",
				"link" : "win('','Recursive Lookups','/cgi-bin/core.pl?do=sub&task=recurse&session=$session','600','300','server');"
			},
			{
				"parent" : "Server",
				"menu" : "DNS",
				"text" : "Allow Transfers",
				"link" : "win('','Zone Transfers','/cgi-bin/core.pl?do=sub&task=trans&session=$session','600','300','server');"
			},
			{
				"parent" : "Server",
				"menu" : "DNS",
				"text" : "Flush Cache",
				"link" : "win('','Flush Cache','/cgi-bin/core.pl?do=sub&task=flush&session=$session','600','300','server');"
			},
~;
}

if( $users->{'admins'}->{$session_user}->{'network'} eq 'true' ) {
print qq~
		{
			"parent" : "Network",
			"text" : "Configure IP",
			"link" : ""
		},
		{
			"parent" : "Network",
			"text" : "Local Hosts",
			"link" : "win('','Local Hosts','/cgi-bin/core.pl?do=sub&task=localhosts&session=$session','600','300','network');"
		},
		{
			"parent" : "Network",
			"text" : "Configure SMTP",
			"link" : ""
		},
~;
}

if( $users->{'admins'}->{$session_user}->{'users'} eq 'true' ) {
print qq~
		{
			"parent" : "Users",
			"text" : "Create User",
			"link" : "win('','Create User','/cgi-bin/core.pl?do=sub&task=newUser&session=$session','700','500','users');"
		},
		{
			"parent" : "Users",
			"text" : "Import Users",
			"link" : "win('','Import Users','/cgi-bin/core.pl?do=sub&task=importUsers&session=$session','700','500','users');"
		},
		{
			"parent" : "Users",
			"text" : "Export",
			"link" : "win('','Export','/cgi-bin/core.pl?do=sub&task=export&session=$session','700','500','users');"
		},
~;
}
	
if( $users->{'admins'}->{$session_user}->{'logs'} eq 'true' ) {
print qq~
			{
				"parent" : "Logs",
				"menu" : "Web Logs",
				"text" : "Security Log",
				"link" : "win('','Security Log','/cgi-bin/core.pl?do=sub&task=seclog&session=$session','900','550','logs');"
			},
			{
				"parent" : "Logs",
				"menu" : "Web Logs",
				"text" : "Error Log",
				"link" : "win('','Error Log','/cgi-bin/core.pl?do=sub&task=errlog&session=$session','900','550','logs');"
			},
			{
				"parent" : "Logs",
				"menu" : "Web Logs",
				"text" : "Access Log",
				"link" : "win('','Access Log','/cgi-bin/core.pl?do=sub&task=acclog&session=$session','900','550','logs');"
			},
			{
				"parent" : "Logs",
				"menu" : "Samba Logs",
				"text" : "Samba Log",
				"link" : "win('','Samba Logs','/cgi-bin/core.pl?do=sub&task=smblog&session=$session','900','800','logs');"
			},
			{
				"parent" : "Logs",
				"menu" : "Samba Logs",
				"text" : "Replication Log",
				"link" : "win('','Replication Logs','/cgi-bin/core.pl?do=sub&task=replog&session=$session','900','550','logs');"
			},
			{
				"parent" : "Logs",
				"menu" : "system logs",
				"text" : "Boot Log",
				"link" : "win('','Boot Log','/cgi-bin/core.pl?do=sub&task=bootlog&session=$session','900','550','logs');"
			},
			{
				"parent" : "Logs",
				"menu" : "system logs",
				"text" : "System Diag Log",
				"link" : "win('','Diagnostic Log','/cgi-bin/core.pl?do=sub&task=dmesg&session=$session','900','550','logs');"
			},
			{
				"parent" : "Logs",
				"menu" : "system logs",
				"text" : "Message Log",
				"link" : "win('','Message Log','/cgi-bin/core.pl?do=sub&task=mesglog&session=$session','900','550','logs');"
			},
			{
				"parent" : "Logs",
				"menu" : "system logs",
				"text" : "Update Log",
				"link" : "win('','Update Log','/cgi-bin/core.pl?do=sub&task=updatelog&session=$session','900','550','logs');"
			},
~;
}

if( $users->{'admins'}->{$session_user}->{'reset'} eq 'true' ) {
print qq~
		{
			"parent" : "Reset",
			"text" : "Reset",
			"link" : "win('','Factory Reset','/cgi-bin/core.pl?do=sub&task=reset&session=$session','500','300','reset');"
		},
~;
}
	
if( $users->{'admins'}->{$session_user}->{'power'} eq 'true' ) {
print qq~
		{
			"parent" : "Power",
			"text" : "Shutdown",
			"link" : "win('','Power Down RazDC','/cgi-bin/core.pl?do=sub&task=shutdown&session=$session','400','200','power');"
		},
		{
			"parent" : "Power",
			"text" : "Restart",
			"link" : "win('','Restart RazDC','/cgi-bin/core.pl?do=sub&task=restart&session=$session','400','200','power');"
		}
~;
}

print qq~
]
}
~;		
	}
	if($task eq 'System'){
	if( $users->{'admins'}->{$session_user}->{'system'} eq 'true' ) {
print qq~
	  {
		"text":"System",
         "options":[
			{
				"text":"Options",
				"id":"SystemMenu0",
				"style":"background-image: url('/images/open.gif');",
				"options":[
					{
						"text":"Refresh",
						"icon":"/images/refresh_16.png",
						"onclick":"rebuildMenu('System');return false;"
					}
				]
			},
            {
               "text":"Settings",
               "id":"SystemMenu1",
			   "style":"background-image: url('/images/open.gif');",
               "options":[
                  {
                     "text":"My RazDC Password",
                     "onclick":"win('','Change Password','/cgi-bin/core.pl?do=sub&task=administrator&session=$session','600','300','system');"
                  },
                  {
                     "text":"System Services",
                     "onclick":"win('','Services','/cgi-bin/core.pl?do=sub&task=services&session=$session','700','400','system');"
                  },
				  {
                     "text":"Network Information",
                     "onclick":"win('','Network Interface','/cgi-bin/core.pl?do=sub&task=int&session=$session','500','300','system');"
                  },
				  {
					"text":"Time & Region",
					"onclick":"win('','Time & Region','/cgi-bin/core.pl?do=sub&task=getRegions&session=$session','500','350','system');"
				  },
				  {
					"text":"Tasks & Schedules",
					"onclick":"win('','Tasks & Schedule','/cgi-bin/core.pl?do=sub&task=scheduling&session=$session','850','400','system');"
				  }
               ]
            },
            {
               "text":"Firmware",
               "id":"SystemMenu2",
               "style":"background-image:url('/images/open.gif');",
               "options":[
                  {
                     "text":"Backups",
                     "onclick":"win('','RazDC Backups','/cgi-bin/core.pl?do=sub&task=backup&session=$session','660','250','system');"
                  },
                  {
                     "text":"Restore",
                     "onclick":"win('','RazDC Restore','/cgi-bin/core.pl?do=sub&task=restore&session=$session','705','400','system');"
                  },
                  {
                     "text":"Update",
                     "onclick":"win('','RazDC Update','/cgi-bin/core.pl?do=sub&task=update&session=$session','600','500','system');"
                  },
				  {
					 "text":"Reset",
					 "onclick":"win('','Factory Reset','/cgi-bin/core.pl?do=sub&task=reset&session=$session','500','300','system');"
				  }
               ]
            },
            {
               "text":"Diagnostics",
               "id":"SystemMenu3",
               "style":"background-image:url('/images/open.gif');",
               "options":[
				  {
                     "text":"Terminal",
                     "onclick":"win('','Terminal','/cgi-bin/core.pl?do=sub&task=webterm&session=$session','800','500','system');"
                  },
                  {
                     "text":"Domain Shares",
                     "onclick":"win('','Domain Share Diagnostics','/cgi-bin/core.pl?do=sub&task=sdiag&session=$session','500','500','system');"
                  },
                  {
                     "text":"Domain Controller",
                     "onclick":"win('','DC Diagnostics','/cgi-bin/core.pl?do=sub&task=dcdiag&session=$session','500','500','system');"
                  },
                  {
                     "text":"DNS Internal",
                     "onclick":"win('','Internal DNS Diagnostics','/cgi-bin/core.pl?do=sub&task=intdiag&session=$session','500','500','system');"
                  },
                  {
                     "text":"DNS External",
                     "onclick":"win('','External DNS Diagnostics','/cgi-bin/core.pl?do=sub&task=exdiag&session=$session','500','500','system');"
                  },
				  {
                     "text":"Kerberos Test",
                     "onclick":"win('','Kerberos Diagnostics','/cgi-bin/core.pl?do=sub&task=krb5diag&session=$session','500','500','system');"
                  }
               ]
            },
			{
				"text":"Power",
				"id":"SystemMenu4",
				"style":"background-image:url('/images/open.gif');",
				"options":[
				  {
					 "text":"Shutdown",
					 "onclick":"win('','Power Down RazDC','/cgi-bin/core.pl?do=sub&task=shutdown&session=$session','400','200','system');"
				  },
				  {
					 "text":"Restart",
					 "onclick":"win('','Restart RazDC','/cgi-bin/core.pl?do=sub&task=restart&session=$session','400','200','system');"
				  }
				]
			}
         ]
      }
~;
	}		
	}
	if($task eq 'Server'){
	if( $users->{'admins'}->{$session_user}->{'server'} eq 'true' ) {

print qq~
		{
         "text":"Server",
         "options":[
			{
				"text":"Options",
				"id":"ServerMenu0",
				"style":"background-image: url('/images/open.gif');",
				"options":[
					{
						"text":"Refresh",
						"icon":"/images/refresh_16.png",
						"onclick":"rebuildMenu('Server');return false;"
					}
				]
			},
            {
               "text":"Domain",
               "id":"ServerMenu1",
			   "style":"background-image: url('/images/open.gif');",
               "options":[
                  {
                     "text":"Information",
                     "onclick":"win('','Domain Information','/cgi-bin/core.pl?do=sub&task=domaininfo&session=$session','600','300','server');"
                  },
                  {
                     "text":"Password Policy",
                     "onclick":"win('','Password Policy','/cgi-bin/core.pl?do=sub&task=passpol&session=$session','600','500','server');"
                  },
                  {
                     "text":"Role Management",
                     "onclick":"win('','FSMO Roles','/cgi-bin/core.pl?do=sub&task=fsmo&session=$session','600','500','server');"
                  },
                  {
                     "text":"Function Levels",
                     "onclick":"win('','Function Levels','/cgi-bin/core.pl?do=sub&task=funclvl&session=$session','800','250','server');"
                  },
				  {
                     "text":"Group Policies",
                     "onclick":"win('','Group Policies','/cgi-bin/core.pl?do=sub&task=gpo&session=$session','800','250','server');"
                  }
               ]
            },
            {
               "text":"DHCP",
               "id":"ServerMenu2",
			   "style":"background-image: url('/images/open.gif');",
               "options":[
				  {
                     "text":"Settings",
                     "onclick":"win('','DHCP Settings','/cgi-bin/core.pl?do=sub&task=dhsettings&session=$session','600','600','server');"
                  },
                  {
                     "text":"Client Leases",
                     "onclick":"win('','Network Clients','/cgi-bin/core.pl?do=sub&task=dhclient&session=$session','600','600','server');"
                  },
~;
# CONSOLIDATED INTO DHCP SETINGS SCREEN, MAYBE WE WILL SEPARATE IT LATER?
#                  {
#                     "text":"Manage Scopes",
#                     "onclick":"win('','Scopes','/cgi-bin/core.pl?do=sub&task=dhscopes&session=$session','600','300','server');"
#                  },
print qq~
                  {
                     "text":"New Scope",
                     "onclick":"win('','New DHCP Scope','/cgi-bin/core.pl?do=sub&task=newscope&session=$session','700','600','server');"
                  },
                  {
                     "text":"New Static",
                     "onclick":"win('','New Static Host','/cgi-bin/core.pl?do=sub&task=newstatic&session=$session','700','300','server');"
                  }
               ]
            },
            {
               "text":"DNS",
               "id":"ServerMenu3",
			   "style":"background-image: url('/images/open.gif');",
               "options":[
                  {
                     "text":"Options",
                     "onclick":"win('','Nameserver Options','/cgi-bin/core.pl?do=sub&task=nsoptions&session=$session','600','700','server');"
                  },
                  {
                     "text":"Internal Resolution",
                     "onclick":"win('','Internal Resolution','/cgi-bin/core.pl?do=sub&task=intns&session=$session','600','300','server');"
                  },
                  {
                     "text":"Forwarding Servers",
                     "onclick":"win('','Forward Lookups','/cgi-bin/core.pl?do=sub&task=forward&session=$session','600','300','server');"
                  },
                  {
                     "text":"Recursive Lookups",
                     "onclick":"win('','Recursive Lookups','/cgi-bin/core.pl?do=sub&task=recurse&session=$session','600','300','server');"
                  },
                  {
                     "text":"Allow Transfers",
                     "onclick":"win('','Zone Transfers','/cgi-bin/core.pl?do=sub&task=trans&session=$session','600','300','server');"
                  },
				                    {
                     "text":"Flush Cache",
                     "onclick":"win('','Flush Cache','/cgi-bin/core.pl?do=sub&task=flush&session=$session','600','300','server');"
                  },
				  {
					 "text":"Zone Manager",
					 "onclick":"win('','DNS Zones','/cgi-bin/core.pl?do=sub&task=dnszones&session=$session','600','300','server');"
				  }
               ]
            },
			{
               "text":"SSL Certificates",
               "id":"ServerMenu4",
               "style":"background-image:url('/images/open.gif');",
               "options":[
                  {
                     "text":"New Certificate",
                     "onclick":"win('','New SSL Certificate','/cgi-bin/core.pl?do=sub&task=sslnew&session=$session','500',200,'server'); return false;"
                  },
                  {
                     "text":"Manage SSL",
                     "onclick":"win('','Manage Certificates','/cgi-bin/core.pl?do=sub&task=ssllist&session=$session','600','400','server'); return false;"
                  }
               ]
            }
         ]
      }
~;
	}		
	}
	if($task eq 'Network'){
	if( $users->{'admins'}->{$session_user}->{'network'} eq 'true' ) {
print qq~
	{
         "text":"Network",
         "options":[
			{
				"text":"Options",
				"id":"NetworkMenu0",
				"style":"background-image: url('/images/open.gif');",
				"options":[
					{
						"text":"Refresh",
						"icon":"/images/refresh_16.png",
						"onclick":"rebuildMenu('Network');return false;"
					}
				]
			},
            {
               "text":"Network Settings",
               "id":"NetworkMenu1",
			   "style":"background-image: url('/images/open.gif');",
               "options":[
                  {
                     "text":"Network Address",
                     "onclick":"win('','Configure IP','/cgi-bin/core.pl?do=sub&task=network&session=$session','600','300','network');"
                  },
                  {
                     "text":"Local Hosts",
                     "onclick":"win('','Local Hosts','/cgi-bin/core.pl?do=sub&task=localhosts&session=$session','600','300','network');"
                  }
               ]
            },
			{
               "text":"Firewall",
               "id":"NetworkMenu2",
               "style":"background-image:url('/images/open.gif');",
               "options":[
                  {
                     "text":"Good Hosts",
                     "onclick":"win('','Good Hosts','/cgi-bin/core.pl?do=sub&task=goodhosts&session=$session','650','500','network');"
                  },
                  {
                     "text":"Bad Hosts",
                     "onclick":"win('','Bad Hosts','/cgi-bin/core.pl?do=sub&task=badhosts&session=$session','650','500','network');"
                  },
                  {
                     "text":"Firewall Ports",
                     "onclick":"win('','Firewall Ports','/cgi-bin/core.pl?do=sub&task=ports&session=$session','680','655','network');"
                  },
				  {
                     "text":"Current Rules",
                     "onclick":"win('','Firewall Rules','/cgi-bin/core.pl?do=sub&task=rules&session=$session','655','655','network');"
                  }
               ]
            }
         ]
      }
~;
	}		
	}
	if($task eq 'Users'){
			if( $users->{'admins'}->{$session_user}->{'users'} eq 'true' ) {
print qq~
{
         "text":"USERS",
		 "options":[
			{
				"text":"Options",
				"id":"UserMenu0",
				"style":"background-image: url('/images/open.gif');",
				"options":[
					{
						"text":"Refresh",
						"icon":"/images/refresh_16.png",
						"onclick":"rebuildMenu('Users');return false;"
					},
					{
						"text":"Create User",
						"icon":"/images/user_add_16.png",
						"onclick":"win('','Create User','/cgi-bin/core.pl?do=sub&task=newUser&session=$session','700','500','users');"
					},
					{
						"text":"Manage Groups",
						"icon":"/images/group_16.png",
						"onclick":"win('','Manage Groups','/cgi-bin/core.pl?do=sub&task=manageGroups&session=$session','700','500','users');"
					},
					{
						"text":"Import Users",
						"icon":"/images/import_16.png",
						"onclick":"win('','Import Users','/cgi-bin/core.pl?do=sub&task=importUsers&session=$session','700','500','users');"
					},
					{
						"text":"Export",
						"icon":"/images/export_16.png",
						"onclick":"win('','Export','/cgi-bin/core.pl?do=sub&task=export&session=$session','700','500','users');"
					}
				]
			},
			{
				"text":"Domain Controllers",
				"id":"UserMenu1",
				"style":"background-image: url('/images/open.gif');",
				"options":[
~;

&getDCS;

print qq~
				]
			},
			{
				"text":"Domain Computers",
				"id":"UserMenu2",
				"style":"background-image: url('/images/open.gif');",
				"options":[
~;

&getComputers;

print qq~
				]
			},
			{
				"text":"Domain Admins",
				"id":"UserMenu3",
				"style":"background-image: url('/images/open.gif');",
				"options":[
~;

&getAdmins;  

print qq~
				]
			},
			{
				"text":"Domain Users",
				"id":"UserMenu4",
				"style":"background-image: url('/images/open.gif');",
				"options":[
~;

&getUsers;

print qq~
				]
			}
		]
}
~;
		} # end permission check
	}
	if($task eq 'Logs'){
	if( $users->{'admins'}->{$session_user}->{'logs'} eq 'true' ) {
print qq~
{
         "text":"Logs",
         "options":[
			{
				"text":"Options",
				"id":"LogMenu0",
				"style":"background-image: url('/images/open.gif');",
				"options":[
					{
						"text":"Refresh",
						"icon":"/images/refresh_16.png",
						"onclick":"rebuildMenu('Logs');return false;"
					}
				]
			},		
			{
               "text":"Web Logs",
               "id":"LogMenu1",
			   "style":"background-image: url('/images/open.gif');",
               "options":[
                  {
                     "text":"Security Log",
                     "onclick":"win('','Security Log','/cgi-bin/core.pl?do=sub&task=seclog&session=$session','900','550','logs');"
                  },
                  {
                     "text":"Error Log",
                     "onclick":"win('','Error Log','/cgi-bin/core.pl?do=sub&task=errlog&session=$session','900','550','logs');"
                  },
                  {
                     "text":"Access Log",
                     "onclick":"win('','Access Log','/cgi-bin/core.pl?do=sub&task=acclog&session=$session','900','550','logs');"
                  }
               ]
            },
            {
               "text":"Active Directory Logs",
               "id":"LogMenu2",
			   "style":"background-image: url('/images/open.gif');",
               "options":[
                  {
                     "text":"Samba Logs",
                     "onclick":"win('','Samba Logs','/cgi-bin/core.pl?do=sub&task=smblog&session=$session','900','800','logs');"
                  },
                  {
                     "text":"Replication Log",
                     "onclick":"win('','Replication Logs','/cgi-bin/core.pl?do=sub&task=replog&session=$session','900','550','logs');"
                  }
               ]
            },
            {
               "text":"System Logs",
               "id":"LogMenu3",
			   "style":"background-image: url('/images/open.gif');",
               "options":[
                  {
                     "text":"Command Log",
                     "onclick":"win('','Command Log','/cgi-bin/core.pl?do=sub&task=cmdlog&session=$session','900','550','logs');"
                  },			   
                  {
                     "text":"Boot Log",
                     "onclick":"win('','Boot Log','/cgi-bin/core.pl?do=sub&task=bootlog&session=$session','900','550','logs');"
                  },
                  {
                     "text":"DMesg",
                     "onclick":"win('','Display Log','/cgi-bin/core.pl?do=sub&task=dmesg&session=$session','900','550','logs');"
                  },
                  {
                     "text":"Message Log",
                     "onclick":"win('','Message Log','/cgi-bin/core.pl?do=sub&task=mesglog&session=$session','900','550','logs');"
                  },
				  {
					 "text":"Update Log",  
					 "onclick":"win('','Update Log','/cgi-bin/core.pl?do=sub&task=updatelog&session=$session','900','550','logs');"
				  }
               ]
            }
         ]
      }
~;
	}		
  }
}
sub webterm {
	&getTemplate(webterm);
	&doSub('SESSION',$session);
	&printTemplate;
}
sub webtermExec { # FUTURE - process web terminal commands.
	
}
sub getSystem {
	$serial = $razdc->{'serial'};
	$macaddr = $razdc->{'macaddr'};
	
	$NIC=`ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}'`;
	$WSNIC=`$(echo -e "${NIC}" | tr -d '[:space:]')`;
	$sysmac=`cat /sys/class/net/$WSNIC/address`;
	
	@sysserial = `cat $razdc->{'CPU'} | grep 'Serial		: '`;
	#@sysmac = `cat $razdc->{'MAC'}`;
	
	$sysserial = "@sysserial";
	#$sysmac = "@sysmac";
	
	$sysserial =~ s/Serial		: //gi;
	chomp($sysserial);
	chomp($sysmac);
	$sysserial = &encode($sysserial);
	$sysmac = &encode($sysmac);
	if($serial eq $sysserial && $macaddr eq $sysmac) {
		$authvalid = 'true';
	}
	else {
		$authvalid = 'false';
	}
}
sub getDCS {
	# Get DCS
	###################
	$i=0;
	@grpdcs = &runCmd("sudo $settings->{'system'}->{'samba'}->{'exe'} group listmembers 'Domain Controllers'");
	foreach $member (@grpdcs) {
		chomp($member);
		$member =~ s/\$//g;
		
		@status = &runCmd("sudo ping $member -c 1");
		$status = "@status";
		
		if($status =~ /1 received/) {
			$icon = "screen_on_16.png";
		}
		else {
			$icon = "screen_off_16.png";
		}
		$i++;
		
print qq~
					{
						"text":"$member",
						"icon":"/images/$icon",
						"onclick":"win('','$member Properties','/cgi-bin/core.pl?do=sub&task=editDC&dcname=$member&session=$session','700','600','users');"
~;
		if($i < @grpdcs) {
			print "					},\n";
		}
		else {
			print "					}\n";
		}
	}
}
sub getComputers {  # NEED MULTI-THREADED MACHINE CHECKS FOR PINGS. LOTS OF PCS MEANS LOTS OF WAITING.
	# Get Machines
	###################
	$i=0;
	
	@grppcs = &runCmd("sudo $settings->{'system'}->{'samba'}->{'exe'} group listmembers 'Domain Computers'");
	if(@grppcs > 0) {
		open(TOKENFILE, '>', '/razdc/www/cgi-bin/TokenFile');
		foreach $member (@grppcs) {
			chomp($member);
			$member =~ s/\$//g;

#ADD FORK FOR PING#############################
##
#if( my $pid = fork) {
#        push(@childs, $pid);
#    }
#    elsif( !defined $pid)
#    {
#        die "Cannot fork $!\n"
#    }
#    else {
        # In child, do whatever
#		$status = `sudo ping $member -c 1`;
		###
#    }
##

## END FORK!


##############################
			
			@status = &runCmd("sudo ping $member -c 1");
			$status = "@status";
			
			# DEFAULT IS SCREEN OFF!
			$icon = "screen_off_16.png";
			
			if($status =~ /1 received/) {
				$icon = "screen_on_16.png";
			}
			else {
				$icon = "screen_off_16.png";
			}
			$i++;
			# ADD TOKEN AFTER INCREMENT!
			print TOKENFILE "token$i: $member:5900\n";

print qq~
					{
						"text":"$member",
						"icon":"/images/$icon",
						"onclick":"win('','$member Properties','/cgi-bin/core.pl?do=sub&task=editPC&token=token$i&pcname=$member&session=$session','700','600','users');"
~;
			if($i < @grppcs) {
				print "					},\n";
			}
			else {
				print "					}\n";
			}
		}
	close(TOKENFILE);
	}
	else {
print qq~
					{
						"text":"Empty",
						"onclick":"return false;"
					}
~;
	}
}
sub getConnect {  # NEED MULTI-THREADED MACHINE CHECKS FOR PINGS. LOTS OF PCS MEANS LOTS OF WAITING.
	# Get Machines
	###################
	$i=0;

	@grppcs = &runCmd("sudo $settings->{'system'}->{'samba'}->{'exe'} group listmembers 'Domain Computers'");
	if(@grppcs > 0) {
		foreach $member (@grppcs) {
			chomp($member);
			$member =~ s/\$//g;
			
			@status = &runCmd("sudo ping $member -c 1");
			$status = "@status";
			
			# DEFAULT IS SCREEN OFF!
			#$icon = "connect_16.png";
			
			if($status =~ /1 received/) {
				$icon = "screen_on_16.png";
			}
			else {
				$icon = "screen_off_16.png";
			}
			$i++;

print qq~
					{
						"text":"$member",
						"icon":"/images/$icon",
						"onclick":"win('','Connect to $member','/cgi-bin/core.pl?do=sub&task=remote&token=token$i&pcname=$member&session=$session','800','800','connect');return false;"
~;
			if($i < @grppcs) {
				print "					},\n";
			}
			else {
				print "					}\n";
			}
		}
	}
	else {
print qq~
					{
						"text":"Empty",
						"onclick":"return false;"
					}
~;
	}
}
sub getAdmins { 
	# Get Admins
	###################
	$i=0;
	@grpadmins = &runCmd("sudo $settings->{'system'}->{'samba'}->{'exe'} group listmembers 'Domain Admins'");
	foreach $member (@grpadmins) {
		chomp($member);
		$i++;
print qq~
					{
						"text":"$member",
						"icon":"/images/user_16.png",
						"onclick":"win('','$member Properties','/cgi-bin/core.pl?do=sub&task=editUser&Unixusername=$member&session=$session','640','450','users');"
~;
		if($i < @grpadmins) {
			print "					},\n";
		}
		else {
			print "					}\n";
		}
	}
}
sub getUsers { 
	# Get Users
	###################
	$i=0;
	@users = &runCmd("sudo $settings->{'system'}->{'samba'}->{'exe'} user list");
	foreach $member (@users) {
		chomp($member);
		$i++;
print qq~
					{
						"text":"$member",
						"icon":"/images/user_16.png",
						"onclick":"win('','$member Properties','/cgi-bin/core.pl?do=sub&task=editUser&Unixusername=$member&session=$session','640','450','users');"
~;
		if($i < @users) {
			print "					},\n";
		}
		else {
			print "					}\n";
		}
	}
}
sub getGroups { # WIP - ADVANCED USER/MACHINE LIST FEATURE BRING BACK FROM OLD VERSION
	# Get Groups
	###################
	$g=0;
	@groups = &runCmd("sudo $settings->{'system'}->{'samba'}->{'exe'} group list");
	foreach $group (@groups) {
		chomp($group);
		$g++;
print qq~
			{
				"text":"$group",
				"id":"UserMenu$g",
				"style":"background-image: url('/images/open.gif');",
				"options":[
~;

		$i=0;
		@users = &runCmd("sudo $settings->{'system'}->{'samba'}->{'exe'} group listmemebers $group");
		foreach $member (@users) {
			chomp($member);
			$i++;
print qq~
					{
						"text":"$member",
						"icon":"/images/user_16.png",
						"onclick":"win('','$member Properties','/cgi-bin/core.pl?do=sub&task=editUser&Unixusername=$member&session=$session','640','450','users');"
~;
			if($i < @users) {
				print "					},\n";
			}
			else {
				print "					}\n";
			}
		}
	}
}
sub doSub { 
	# Generic "safe" substitution routine that watches for user-inserted substitution markers.
	# It changes all occurances of [!, [?, !] or ?] to [~~! etc., to be changed back later.
	# Otherwise users can include substitution markers in their posts, and cause havoc.
	($subName, $newStr) = @_;
	$newStr = '' unless ($newStr);
	$newStr =~ s/\[(!|\?)/\[~~$1/g;
	$newStr =~ s/(!|\?)\]/$1~~\]/g;
	$newStr =~ s/\^/~~CARET/g;
	s/\[!\Q$subName\E!\]/$newStr/g;
}
sub printHeader { 
	# Create the common page header - pass a title parameter.
	# Compose the regular header template.
	&getTemplate('header');
	&doSub("PAGETITLE", $_[0]);
	&printTemplate;
}
sub getTemplate { 
	# This retrieves a template and does some substitutions common to most templates
	# The result is returned as $_ to the calling function.
	# Pass it a template name and hash reference to an @forum_data entry (like $forum_ref).
	($template_name) = @_;
	$_ = $template{$template_name};
	# Make usergroups available everywhere...
	# s/\[\?ISLOGGEDIN(.)(.*?)\1(.*?)\?\]/$username ? $2 : $3/seg;
}
sub fail { 
	# Auth failed or no data submitted, return to login, need to add templlate processing to handle error meessages
	
	print "Content-Type: text/html\n\n";
	$err = "@_";
	print "$err";
	&getTemplate('login');
	#&doSub("","");
	print $template{'login'};
}
sub encode { 
	# Encode data to for cookie
    @table = (('A' .. 'Z'), ('a' .. 'z'), ('0' .. '9'), '+', '/', '|');
    local $_ = unpack('B*', $_[0]);
    $_ .= '0' x (6 - (length($_) % 6)) if (length($_) % 6) != 0;
    s/.{6}/$table[ord(pack('B6', $&)) >> 2]/eg; $_;
}
sub decode { 
	# Decode cookie for login (passwords are still encrypted)
	@table = (('A' .. 'Z'), ('a' .. 'z'), ('0' .. '9'), '+', '/', '|');
    for ($_ = 0; $_ <= $#table; $_++) {
         $decode_table[ord($table[$_])] = $_;
    }
    local $_ = $_[0];
    s/./unpack('B6', chr($decode_table[ord($&)] << 2))/eg;
    pack('B' . (int(length($_) / 8) * 8), $_);
}
sub loadTemplates { 
	# Load Templates
	if(-e $templates) {
		if(!(do "$templates")) {
			# Display an error if the template file can't be evaluated successfully.
print qq~
Content-type: text/html
<html>
<body>
<h2>RazDC: Error</h2>
<div>An error occured while loading the RazDC template file:</div>
<div>$@</div>
</body></html>
~;
		}
	}
	else {
print qq~
Content-type: text/html
<html>
<body>
<h2>RazDC: Error</h2>
<div>An error occured while loading the RazDC template file:</div>
<div>$@</div>
</body></html>
~;
	}
}
sub read_bounded_line {
   $fh = shift;  # get file handle: reference to hash
   $rbuf, $nread, $res;
   $toread = ($fh->{LENGTH} > 8000)? 8000 : $fh->{LENGTH};

   # if more to read and buffer below size, add some more to the buffer
   if ($toread && length($fh->{BUFFER}) < 8000) {
      $nread = read(STDIN, $rbuf, $toread);
      if ($nread > 0) {
         $fh->{LENGTH} -= $nread;
         $fh->{BUFFER} .= $rbuf;
      } else {
         # either EOF or error case!
         $fh->{LENGTH} = 0;
      }
   }
   # extract first line terminated by CRLF pair
   # note use of non-greedy *? quantifier on .
   if ($fh->{BUFFER} =~ s/^(.*?\r\n)//s) {
      $res = $1;
   } else {
      # no CRLF to be seen, but possible last CR could start a CRLF,
      # so push that back for later
      if ($fh->{LENGTH} > 0) {
         $res = substr($fh->{BUFFER}, 0, -1);
         $fh->{BUFFER} = substr($fh->{BUFFER}, -1, 1);
      } else {
         $res = $fh->{BUFFER};
         $fh->{BUFFER} = '';
      }
   }
   return $res;
}
sub more_input {
   $fh = shift;
   return $fh->{LENGTH} || length($fh->{BUFFER});
}
sub split_urlencoding {
	$in = shift;
	@in = split(/&/, $in);
	foreach(@in) {
		($k,$v) = split(/=/,$_);
		$k =~ tr/+/ /;
		$k =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$k =~ s/\+/ /g;
		$v =~ tr/+/ /;
		$v =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$v =~ s/\+/ /g;
		#$v =~ s///g;
		${$k} = $v;
		
		if($debug){ print "$k = $v<br>\n"; }
		if($k =~ m/domainnameservers\d/gi) {
			if($v) {
				push(@DomainNameServers, $v);
			}
		}
		if($k =~ m/netbiosnameservers\d/gi) {
			if($v) {
				push(@NetbiosNameServers, $v);
			}
		}
	}
}
sub parseform {
   $maxform = 30000;
   $filedir = '/razdc/tmp/';
   $inform, $infile, $boundary, $lastline, $name, $value;
   $fh = { LENGTH => ($ENV{'CONTENT_LENGTH'} > $maxform) ? $maxform : $ENV{'CONTENT_LENGTH'}, BUFFER => '' };
   if ($ENV{'REQUEST_METHOD'} eq 'GET') {
      split_urlencoding($ENV{'QUERY_STRING'});
   }
   if ($ENV{'REQUEST_METHOD'} eq 'POST') {
	  if($ENV{'QUERY_STRING'}) {
		split_urlencoding($ENV{'QUERY_STRING'});
	  }
      binmode STDIN;
      if ($ENV{'CONTENT_TYPE'} =~ /application\/x-www-form-urlencoded/i) {
         read(STDIN, $value, $ENV{'CONTENT_LENGTH'});
         split_urlencoding($value);
      } elsif ($ENV{'CONTENT_TYPE'} =~ /multipart\/form-data;\s*boundary=(\S+)/i) {
         $boundary = $1;
         $inform = 0;
         while (more_input($fh)) {
            $_ = read_bounded_line($fh);
            if (!$inform) {
               $inform = /^--$boundary/;
            } else {
               if (/content-disposition:\s*form-data;\s*name=\"([^\"]*)\"/i) {
                  # found start of header: extract form data name
                  $name = $1;
                  $value = '';
                  $infile = 0;
                  # is this header a file name?
                  if (/filename=\"([^\"]*)\"/i) {
                     # only process file name if one was given
                     if (length($1) > 0) {
                        $value = $1;
                        $value =~ s/://g;       # remove colons
                        $value =~ s/\\/\//g;    # turn backslashes to slashes
                        $value =~ s/^(.*\/)*//; # delete all leading path elements
                        $value =~ s/\s/_/g;     # replace whitespace with underscores
                        $value = $filedir . "temp.file";   # add upload path
                     }
                     $infile = 1;
                  }
               } elsif (/^\r\n$/) {
                  # an empty line marks end of header, so process content that follows
                  if ($infile) {
                     # does our upload directory exist?
                     mkdir($filedir, 0700) unless (-d $filedir);
                     # only process file content if required and we can write it
                     if (length($value) > 0 && open(SAVEFILE, ">$value") or print "FAILED: $!<br>\n") {
                        binmode SAVEFILE;
                        $lastline = '';
                        COPYLINE: while (more_input($fh)) {
                           $_ = read_bounded_line($fh);
                           if (/^--$boundary/) {
                              $lastline =~ s/\r\n$//;
                              last COPYLINE;
                           } else {
                              print SAVEFILE $lastline;
                           }
                           $lastline = $_;
                        }
                        print SAVEFILE $lastline;
                        close SAVEFILE;
                        # form name gets the file path
                        $FORM{$name} = $value;
                     } else {
                        # skip over unused file content to next boundary
                        SKIPLINE: while (more_input($fh)) {
                           $_ = read_bounded_line($fh);
                           last SKIPLINE if (/^--$boundary/);
                        }
                     }
                  } else {
                     # we have normal content: pack it until we see a boundary
                     $lastline = '';
                     COPYVALUE: while (more_input($fh)) {
                        $_ = read_bounded_line($fh);
                        if (/^--$boundary/) {
                           $lastline =~ s/\r\n$//;
                           last COPYVALUE;
                        } else {
                           $value .= $lastline;
                        }
                        $lastline = $_;
                     }
                     $value .= $lastline;
                     # form name gets the content
                     $FORM{$name} = $value;
                  }
                  # check for -- suffix to mark end of form
                  $inform = (/^--$boundary--/)? 0 : 1;
               }
            }
         }
      }
   }
   $auth = 0;
}
sub rand { 
	# Generate random passwords
	#############################
    $length_of_randomstring=shift;# the length of the random string to generate

    @chars=('a'..'z','A'..'Z','0'..'9','_');
    $random_string = 'RDC_';
    foreach (1..8)
        {
            # rand @chars will generate a random
            # number between 0 and scalar @chars
            $random_string.=$chars[rand @chars];
        }
	return $random_string;
}
sub netInfo { 
	# Gather all network info from system
	######################################
	# THE VARIABLES GENERATED BY THIS FUNCTION IN netInfo HASH:
	# BOOTPROTO : static<br>
	# DEVICE : eth0<br>
	# DOMAIN : DC<br>
	# EXDNS : 104.167.2.167<br>
	# FQDN : raz.dc.local<br>
	# GATEWAY : 192.168.19.1<br>
	# HOST : raz<br>
	# HOSTNAME : raz.dc.local<br>
	# HWADDR : <br>
	# IPADDR : 192.168.19.65<br>
	# NAMESERVERS : 192.168.19.27 192.168.19.26<br>
	# NETMASK : 255.255.255.0<br>
	# NETWORKING : yes<br>
	# NM_CONTROLLED : no<br>
	# ONBOOT : yes<br>
	# PEERDNS : no<br>
	# REALM : dc.local<br>
	# RECURSION : any<br>
	# TLD : local<br>
	# TRANSFERS : <br>
	# TYPE : <br>
	# USERCTL : no<br>
	# search : grand-forks.lib.nd.us<br>
	
	# $netInfo{'TRANSFERS'}
	# $netInfo{'RECURSION'}
	# $netInfo{'EXDNS'}
	# $netInfo{'TYPE'}
	# $netInfo{'FQDN'}
	# $netInfo{'DOMAIN'}
	# $netInfo{'REALM'}
	# $netInfo{'HOST'}
	# $netInfo{'TLD'}
	
	$net_data_path = $settings->{'system'}->{'network'}->{'net_data'};
	$ip_data_path = $settings->{'system'}->{'network'}->{'ip_data'};
	$ns_data_path = $settings->{'system'}->{'network'}->{'ns_data'};
	$forward_dns_path = $settings->{'system'}->{'network'}->{'ns_data'}; 
	$recursion_data_path = $settings->{'system'}->{'network'}->{'recursion'};
	$transfer_data_path = $settings->{'system'}->{'network'}->{'transfer'};
	
	$NAME_DATA = `sudo cat /etc/hostname`;
	@NET_DATA = `sudo cat $net_data_path`;
	@IP_DATA = `sudo cat $ip_data_path`;
	@NS_DATA = `sudo cat $ns_data_path`;
	@FORWARD_DNS_DATA = `sudo cat $forward_dns_path`;
	@RECURSION_DATA = `sudo cat $recursion_data_path`;
	@TRANFER_DATA = `sudo cat $transfer_data_path`;
	#@DHCP_DATA = `sudo cat $settings->{'system'}->{'network'}->{'dhcp_data'}`;

	$netInfo{'HOSTNAME'} = $NAME_DATA;

	foreach(@NET_DATA) {
		($k,$v) = split(/=/, $_);
        chomp($v);
        $v =~ tr/\015//d;
        $v =~ s/"//ge;
        $netInfo{$k}=$v;
    }

	foreach(@IP_DATA) {
		($k,$v) = split(/=/, $_);
        chomp($v);
        $v =~ tr/\015//d;
        $v =~ s/"//ge;
        $netInfo{$k}=$v;
    }

	foreach(@NS_DATA) {
		($k,$v) = split(/ /, $_);
        chomp($v);
        $v =~ tr/\015//d;
        $v =~ s/"//ge;
        if($k =~ /^domain/){ $netInfo{$k}=$v; }
        if($k =~ /^search/){ $netInfo{$k}=$v; }
        if($k =~ /^nameserver/){ push(@NAMESERVERS, "$v"); }
    }

	foreach $nsentry (@FORWARD_DNS_DATA) {
		#chomp($nsentry);
		$nsentry =~ s/;//g;

		if( $nsentry !~ /[\{|\}]/  )
			{
			$nsentry =~ s/\s+//g;
			chomp($nsentry);
			push(@EXTERNAL, "$nsentry");
		}
	}

	foreach $recuentry (@RECURSION_DATA) {
	#chomp($recuentry);
    $recuentry =~ s/;//g;

		if( $recuentry !~ /[\{|\}]/  ) {
			$recuentry =~ s/\s+//g;
			chomp($recuentry);
			push(@RECURSION, "$recuentry");
		}
    }

	foreach $axfrline (@TRANSFER_DATA) {
		chomp($axfrline);
		$axfrline =~ s/;//g;
	
		if( $axfrline !~ /[\{|\}]/ ) {
			$axfrline =~ s/\s+//g;
			chomp($axfrline);
			push(@TRANSFERS, "$axfrline");
		}
	}

	#print "NS Array: @NAMESERVERS<br>\n";
	$netInfo{'NAMESERVERS'} = "@NAMESERVERS";

	#($HOST,$DOMAIN,$ROOT) = split(/\./, $netInfo{'HOSTNAME'});

	$FQDN = "$netInfo{'HOSTNAME'}";
	(@FQDNParts) = split(/\./, $netInfo{'HOSTNAME'});

	$HOST = $FQDNParts[0];
	$DOMAIN = $FQDNParts[1];
	$TLD = $FQDNParts[2];

	$REALM = $DOMAIN.".".$TLD;
	$DOMAIN = uc($DOMAIN);
	$REALM = lc($REALM);
	$netInfo{'TRANSFERS'} = "@TRANSFERS";
	$netInfo{'RECURSION'} = "@RECURSION";
	$netInfo{'EXDNS'} = "@EXTERNAL";
	$netInfo{'TYPE'} = "$TYPE";
	$netInfo{'FQDN'} = "$FQDN";
	$netInfo{'DOMAIN'} = "$DOMAIN";
	$netInfo{'REALM'} = "$REALM";
	$netInfo{'HOST'} = "$HOST";
	$netInfo{'TLD'} = "$TLD";

	#foreach(@DHCP_DATA)
	#        {
	#	if($_ =~ /^subnet/i){ $netInfo{$subnet} = $_; }
	#        if($_ =~ /^option routers/i){ $netInfo{$router} = $_; }
	#        if($_ =~ /^option subnet-mask/i){ $netInfo{$mask} = $_; }
	#        if($_ =~ /^option domain-name-servers/i){ $localdns = $_; }
	#        if($_ =~ /^option netbios-name-servers/i){$localwins = $_; }
	#        if($_ =~ /^range dynamic-bootp/i){ $range = $_; }
	#        if($_ =~ /^default-lease-time/i){$leasetime = $_; }
	#        if($_ =~ /^max-lease-time/i){$maxlease = $_; }
	#        }

	#$subnet =~ s/;//ge;
	#$router =~ s/;//ge;
	#$mask =~ s/;//ge;
	#$localdns =~ s/;//ge;
	#$localwins =~ s/;//ge;
	#$leasetime =~ s/;//ge;
	#$maxlease =~ s/;//ge;
	#$range =~ s/;//ge;

	#@range = split(/ /,$range);
	#@subnet = split(/ /,$subnet);
	#@router = split(/ /,$router);
	#@mask = split(/ /,$mask);
	#@localdns = split(/ /,$localdns);
	
	#foreach(@localdns)
	#        {
	#        $_ =~ s/,//ge;
	#        }
	#@localwins = split(/ /,$localwins);
	#@leasetime = split(/ /,$leasetime);
	#@maxlease = split(/ /,$maxlease);

	#return %netInfo;
}
sub nsOptions { 
	# write NS Options config file
	##################################
	open(OPTIONS, "< $nspath/options.conf");
	@OPTIONS = <OPTIONS>;
	close(OPTIONS);

	$count = 0;
	foreach $line (@OPTIONS) {
		if($line !~ /^\/\//) {
	#		($key,$val) = split(/ /, $line);
			$nsOptions{$count} = "$line";
			$count++;
			}
		}
	return %nsOptions;
}
sub dnszones { # 11/2022 - ADDED - TESTING DNS ZONE MANAGER
	@AXFR = &runCmd("dig $netInfo{'REALM'} AXFR");
	@ALLAXFR;
	foreach $line (@AXFR) {
		@RSOA=();
		@RNS=();
		@RA=();
		@RSRV=();
		@RCNAME=();
		@RMX=();
		@RTXT=();
		@PTR=();
		next if($line =~ m/^;+?.*?$/m);
		
		if($line =~ /NS/) {
			(@parts) = split(/\s+/, $line);
		
			@zoneRecords = `dig $parts[0] AXFR`;

			push(@ALLAXFR, qq|<div style="border:1px #000 solid;"><div class="barColor"><img src="../images/database_add_32.png" height="16px" width="16px">&nbsp;Zone: $parts[0]</div><br>|);
			#push(@RSOA, qq|<h3>SOA</h3><ul>|);
push(@RSOA, qw(<div class="tr">
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -108.5px -63.1px;">Record</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -108.5px -63.1px;">TTL</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -108.5px -63.1px;">IN/Stop</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -108.5px -63.1px;">TYPE</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -108.5px -63.1px;">Target</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -108.5px -63.1px;">Email</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -108.5px -63.1px;">S/N</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -108.5px -63.1px;">REF</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -108.5px -63.1px;">RET</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -108.5px -63.1px;">EXP</div>
	<div class="barColor td" style="padding: 5px; height: 30px; background-position: -108.5px -63.1px;">MIN</div>
</div>));


			push(@RNS, qq|<h3>NS</h3><ul>|);
			push(@RA, qq|<h3>A</h3><ul>|);
			push(@RSRV, qq|<h3>SRV</h3><ul>|);
			push(@RCNAME, qq|<h3>CNAME</h3><ul>|);
			push(@RMX, qq|<h3>MX</h3><ul>|);
			push(@RTXT, qq|<h3>TXT</h3><ul>|);
			push(@RPTR, qq|<h3>PTR</h3><ul>|);
			
			#2003080800 sn, 12h refresh, 15m update retry, 3w expiry, 2h minimum
			#2007091701 sn, 30800 refresh, 7200 retry, 604800 expire, 300 minimum
			
			#VALUE			   TTL IN RT  TARGET			   EMAIL					   SN RF  RT  EXP	MIN
			#supervene.local. 3600 IN SOA dc2.supervene.local. hostmaster.supervene.local. 38 900 600 86400 3600
 
			#VALUE			  TTL IN RT TARGET
			#supervene.local. 900 IN NS dc1.supervene.local.
			
			#VALUE 			  TTL IN RT TARGET
			#supervene.local. 900 IN A 192.168.19.113
			
			#SERVICE									TTL IN RT  PRIORITY WEIGHT 	PORT TARGET
			#_ldap._tcp.DomainDnsZones.supervene.local. 900 IN SRV 0 		100 	389	 dc1.supervene.local.

			# 
			#MX TYPE
			
			# VALUE														  TTL IN TYPE  TARGET
			#0fd39933-9b13-46eb-bfb4-f6859c6e3602._msdcs.supervene.local. 900 IN CNAME DC2.supervene.local.
			
			foreach $record (@zoneRecords) {
				
				# SOA - DONE
				if($record =~ m/\hSOA\h/) {
					($VALUE,$TTL,$IN,$TYPE,$TARGET,$EMAIL,$SN,$REFRESH,$RETRY,$EXPIRE,$MINIMUM) = split(/\s+?/, $record);
					#push(@RSOA, "<li>$VALUE,$TTL,$IN,$TYPE,$TARGET,$EMAIL,$SN,$REFRESH,$RETRY,$EXPIRE,$MINIMUM</li>");
					push(@RSOA, qw(<div class="tr evenRow" id="service_container_smb.service">
					<li>$VALUE,$TTL,$IN,$TYPE,$TARGET,$EMAIL,$SN,$REFRESH,$RETRY,$EXPIRE,$MINIMUM</li>
					</div>));
				}
				
				# NS - DONE
				if($record =~ m/\hNS\h/) {
					($VALUE,$TTL,$IN,$TYPE,$TARGET) = split(/\s+?/, $record);
					push(@RNS, "<li>$VALUE,$TTL,$IN,$TYPE,$TARGET</li>");
				}
				
				# A - DONE
				if($record =~ m/\hA\h/) {
					($VALUE,$TTL,$IN,$TYPE,$TARGET) = split(/\s+?/, $record);
					push(@RA, "<li>$VALUE,$TTL,$IN,$TYPE,$TARGET</li>");
				}
				
				# SRV - DONE
				if($record =~ m/\hSRV\h/) {
					($SERVICE,$TTL,$IN,$TYPE,$PRIORITY,$WEIGHT,$PORT,$TARGET) = split(/\s+?/, $record);
					push(@RSRV, "<li>$SERVICE,$TTL,$IN,$TYPE,$PRIORITY,$WEIGHT,$PORT,$TARGET</li>");
				}
				
				# CNAME - DONE
				if($record =~ m/\hCNAME\h/) {
					($VALUE,$TTL,$IN,$TYPE,$TARGET) = split(/\s+?/, $record);
					push(@RCNAME, "<li>$VALUE,$TTL,$IN,$TYPE,$TARGET</li>");
				}
				
				# MX - ?
				if($record =~ m/\hMX\h/) {
					($NAME,$TTL,$IN,$TYPE,$VALUE) = split(/\s+?/, $record);
				push(@RMX, "<li>$VALUE&nbsp;$TYPE</li>");
				}
				
				# TXT - ?
				if($record =~ m/\hTXT\h/) {
					($NAME,$TTL,$IN,$TYPE,$VALUE) = split(/\s+?/, $record);
				push(@RTXT, "<li>$VALUE&nbsp;$TYPE</li>");
				}
				
				# PTR - ?
				if($record =~ m/\hPTR\h/) {
					($NAME,$TTL,$IN,$TYPE,$VALUE) = split(/\s+?/, $record);
				push(@RPTR, "<li>$VALUE&nbsp;$TYPE</li>");
				}
				
				#@zParts = split(/\s+?/, $record);
				#if($zParts[0] !~ /^;/) {
				#	push(@ALLAXFR, "<li>@zParts</li>");
					#push(@ALLAXFR, "<li>$zParts[0]</li>");
				#}
			}
			
			push(@RSOA, qq|</ul><br>|);
			push(@RNS, qq|</ul><br>|);
			push(@RA, qq|</ul><br>|);
			push(@RSRV, qq|</ul><br>|);
			push(@RCNAME, qq|</ul><br>|);
			push(@RMX, qq|</ul><br>|);
			push(@RTXT, qq|</ul><br>|);
			push(@RPTR, qq|</ul><br>|);
			
			push(@ALLAXFR,"@RSOA@RNS@RA@RSRV@RCNAME@RMX@RTXT@RPTR");
			push(@ALLAXFR, "</div>");
			
			#print qq|</li>
			#	<!--li><a href="../cgi-bin/addrecord.cgi?zone=$V" target="tabFrame"><img src="../images/folder_add_32.png" height="16px" width="16px">&nbsp;Add Record</a></li-->
			#               </ul>
			#</li>|;
		}
	}
	
	&getTemplate('genericwin');
	&doSub(GENERICDATA, "@ALLAXFR");
	&printTemplate;
}
sub getStamp { # USED for temp file names
	# get Datetime
	###############
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	$mon+1;
	$year += 1900;
	if ($hour > 12) { $hour=$hour-12; }
    if (length($mon)  == 1) {$mon = "0$mon";}
    if (length($mday) == 1) {$mday = "0$mday";}
    if (length($hour) == 1) {$hour = "0$hour";}
    if (length($min)  == 1) {$min = "0$min";}
    if (length($sec)  == 1) {$sec = "0$sec";}
	return "$mon$mday$year$hour$min$sec";
}
sub getDatetime { # NEED TO MOVE HTML TO TEMPALTES!
	# get Datetime
	###############
	@months = ("January","February","March","April","May","June","July","August","September","October","November","December");
	@days = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	$day = $days[$wday];
    $month = $months[$mon];
	$year += 1900;
	if ($hour >= 12) { $mil="PM"; } else { $mil = "AM"; }
	if ($hour > 12) { $hour=$hour-12; }
    if (length($mon)  == 1) {$mon = "0$mon";}
    if (length($mday) == 1) {$mday = "0$mday";}
    if (length($hour) == 1) {$hour = "0$hour";}
    if (length($min)  == 1) {$min = "0$min";}
    if (length($sec)  == 1) {$sec = "0$sec";}

####PRINT DAY DROP DOWN##
	print "<select name=\"uday\">\n";
    foreach $D (@days){
		&getTemplate('option');
		&doSub('VALUE', $D);
		&doSub('TEXT', $D);
		if($D eq $day){
			&doSub('SELECTED', "selected");
        }
		else {
			&doSub('SELECTED', "");
		}
		&printTemplate;
	}
    print "</select>\n";

####PRINT MONTH DROP DOWN##
	print "<select name=\"umonth\">\n";
    foreach $M (@months){
		&getTemplate('option');
		&doSub('VALUE', $M);
		&doSub('TEXT', $M);
		if($M eq $month){
			&doSub('SELECTED', "selected");
        }
        else {
			&doSub('SELECTED', "");
        }
		&printTemplate;
    }
    print "</select>\n";

####PRINT MONTHDAY DROP DOWN##
	@mdays = (1..31);
	print "<select name=\"umday\">\n";
    foreach $AMDAY (@mdays){
		&getTemplate('option');
		&doSub('VALUE', $AMDAY);
		&doSub('TEXT', $AMDAY);
		if($AMDAY eq $mday){
			&doSub('SELECTED', "selected");
        }
        else {
			&doSub('SELECTED', "");
        }
		&printTemplate;
	}
    print "</select>,\n";

####PRINT YEAR DROP DOWN##
	@years = (1900..2100);
	print "<select name=\"uyear\">\n";
    foreach $AYEAR (@years){
		&getTemplate('option');
		&doSub('VALUE', $AYEAR);
		&doSub('TEXT', $AYEAR);
        if($AYEAR eq $year){
			&doSub('SELECTED', "selected");
        }
        else {
			&doSub('SELECTED', "");
        }
		&printTemplate;
    }
    print "</select><br>\n";

####PRINT HOUR DROP DOWN##
	@HOURS = (1..12);
	print "<select name=\"uhour\">\n";
    foreach $ahour (@HOURS){
		&getTemplate('option');
		$ahour = '0' . $ahour if $ahour < 10;
		if($ahour == $hour){
			&doSub('SELECTED', "selected");
		}
		else {
			&doSub('SELECTED', "");
		}
		&doSub('VALUE', $ahour);
		&doSub('TEXT', $ahour);
		&printTemplate;
    }
	print "</select>:\n";

####PRINT MINUTE DROP DOWN##
	@MINS = (0..59); 
	print "<select name=\"umin\">\n";
    foreach $amin (@MINS){
		&getTemplate('option');
        $amin = '0' . $amin if $amin < 10;
        if($amin == $min) {
			&doSub('SELECTED', "selected");
		}
		else {
			&doSub('SELECTED', "");
		}
		&doSub('VALUE', $amin);
		&doSub('TEXT', $amin);
		&printTemplate;
    }
        print "</select>:\n";

####PRINT SECONDS DROP DOWN##
	@SECS = (0..59);
	print "<select name=\"usec\">\n";
	foreach $asec (@SECS){
		&getTemplate('option');
		
        $asec = '0' . $asec if $asec < 10;
        if($asec == $sec){
			&doSub('SELECTED', "selected");
		}
		else {
			&doSub('SELECTED', "");
		}
		&doSub('VALUE', $asec);
		&doSub('TEXT', $asec);
		&printTemplate;
	}
    print "</select>\n";

####PRINT AMPM DROP DOWN##
	@MILS = ('AM','PM');
	print "<select name=\"umil\">\n";
    foreach $amil (@MILS){
		&getTemplate('option');
		&doSub('VALUE', $amil);
		&doSub('TEXT', $amil);
        if($amil eq $mil){
			&doSub('SELECTED', "selected");
		}
		else {
			&doSub('SELECTED', "");
		}
		&printTemplate;
    }
	print "</select>\n";
}
sub getLocaltime { 
	# get localtime
	################
	@mytimezone = &runCmd("ls -l /etc/localtime");
	$mytimezone = "@mytimezone";
	@items = split(/\//, $mytimezone);
	$mylocal = $items[$#items];
	return $mylocal;
}
sub setTZ { 
	if($tz) {
		&runCmd("sudo timedatectl set-timezone $tz");
	}
	&getRegions;
}
sub setTD { # WIP - ADD FUNTIONS FOR NTP SERVER IN FUTURE!
	if($uday && $umonth && $umday && $uyear && $uhour && $umin && $usec && $umil) {
		# IGNORE $day THIS IS THE DAY OF THE WEEK.
		
		#Set Hour (0-24)
        #Set Minutes (0-60)
        #Set Seconds (0-60)
        #Set Month (1-12)
        #Set Day (1-31)
        #Set Year (2020)
		
		$uhour = 0 if $uhour == 12;
		$uhour += 12 if $umil eq 'PM';

		%months = (
			january => 1,
			february => 2,
			march => 3,
			april => 4,
			may => 5,
			june => 6,
			july => 7,
			august => 8,
			september => 9,
			october => 10,
			november => 11,
			december => 12
		);
		
		$dtc1 = "sudo timedatectl set-ntp no";
		$dtc2 = "sudo timedatectl set-time $uyear-$months{lc($umonth)}-$umday";
		$dtc3 = "sudo timedatectl set-time $uhour:$umin:$usec";
		$dtc4 = "sudo timedatectl set-local-rtc yes"; # ONLY ON RPI4 WITH REALTIME CLOCK! (YES/NO)
		$dtc5 = "sudo timedatectl set-ntp yes";
				
		&runCmd($dtc1);
		&runCmd($dtc2);
		&runCmd($dtc3);
		
	}
	&getRegions;
}
sub getRegions { 
	# Get Time zones
	#################
	@current_time = &runCmd("sudo date");
	@current_zone = &runCmd("sudo timedatectl | grep 'Time zone'");	
	
	$current_time = "@current_time";
	$current_zone = "@current_zone";
	
	$current_zone =~ s/Time zone: //;
	
	&getTemplate('datetime');
	&doSub('CURRENTTIME',$current_time);
	&doSub('CURRENTZONE',$current_zone);
	&printTemplate;
	
	&getTemplate('timezonestart');
	&doSub('SESSION',$session);
	&printTemplate;

	$zonefile = '/razdc/vsh/timezones.txt';
	
	open(TZS, "< $zonefile") or print "Unable to open timezone file: $!<br>\n";
	@zones = <TZS>;
	close(TZS);
	
	foreach $zone (@zones) {
		&getTemplate('option');
		&doSub('VALUE', "$zone");
		&doSub('TEXT', "$zone");
		&doSub('SELECTED', "");
		&printTemplate;
	}
		
	&getTemplate('timezoneend');
	&printTemplate;
	&getDatetime;
	&getTemplate('timeend');
	&doSub('SESSION',$session);
	&printTemplate;
}
sub getNTP { # OLD TIME SETTINGS NEEDS UPDATING FOR CHRONY!
	# Get NTP
	##############
	$i=0;
	$ntp = $settings->{'system'}->{'datetime'}->{'ntp'};
	@lines = &runCmd("sudo cat $ntp");
	&getTemplate('ntpstart');
	&printTemplate;
	foreach $line (@lines){
		$i++;
		if($line =~ m/^server\s(.*)/i){
			chomp($line);
			&getTemplate('ntpbox');
			&doSub("NUMBER", $i);
			&doSub("NTPSERVER", $line);
			&printTemplate;
		}
	}
	&getTemplate('ntpend');
	&printTemplate;
}
sub gmtTimeFormat { # USED?
	# Get GM Time
	##############
 $expires = $_[0];
 ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time+$expires);
 #$ampm = ($hour < 12 ? 'AM' : 'PM');
 $min = sprintf("%02d", $min);
 #$hour = $hour ? ($hour > 12 ? $hour-12 : $hour) : 12;
 $wday = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat')[$wday]; 
 $mon = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[$mon];
 $year += 1900;
# $mygmt = "$wday, $mon $mday $hour:$min:$sec $year";
 $mygmt = "$wday, $mday-$mon-$year $hour:$min:$sec GMT";
 # Tue Sep, 4 13:47:48 2018<br>
 # Tue 04-Sep-2018 14:02:48 GMT<br>
  return ($mygmt);
}
sub printTemplate {
	# ADD STANDARD REPLACEMENTS HERE:
	# FUNCTION CALL?
	# LIST EACH REPLACMENT?
	# NEED TO PASS VARIBLES?
	
	# Print Template
	################
 s/\[~~(!|\?)/\[$1/g;
 s/(!|\?)~~\]/$1\]/g;
 s/~~CARET/\^/g;
 print "$_";
}
sub ParseDHCPConfig {
	$dhcpScopes = $settings->{'system'}->{'dhcp'}->{'scopedir'};
	
	opendir(SCOPES, $dhcpScopes) or print "Oh Crap! Somthing went wrong: $!<br>\n";

	while ($file = readdir SCOPES) {
		next if $file=~/^\./;
		push(@S,$file);
	}

	foreach $s (@S) {
		
		open(IN, "< $dhcpScopes/$s") or print "Their was an error reading DHCP configuration: $!\n";
		@info = <IN>;
		close(IN) or print "Their was an error after reading the DHCP configuration: $!\n";
		print "@info<br>\n";
		$line;
		@parts;
		$i = 0;
		$dlt;	#not doing anything with dlt yet!	
		%range;
	
		while ($line=$info[$i]) { # parse the dhcpd.conf file
			if ($line =~ m/^#/) { # ignore commented lines
				$i++;
				next;
			}
			if ($line =~ m/default-lease-time/) {	#found default lease time
				@parts= split(/\s/, $line);
				$dlt = $parts[1];
			}
	        if ($line =~ m/subnet/) {
	            @parts = split (/\s/, $line);
	            $j = 0;
	            foreach $part(@parts) {
					if ($part eq "subnet") {
						$netwk =  $parts[$j+1];
	                    $mask = $parts[$j+3];
	                    $nets{$netwk} = $mask;            #save net and mask pairs in a hash
	                }
	            $j++;
	            }
	        }
			if ($line =~ m/range/) {				# get address range
				@parts = split (/\s/, $line);
	            $j = 0;
				foreach $part(@parts) {
					if ($part eq "range") {		# Potential list of ranges... 
						chop ($parts[$j+2]);
						$range{$netwk} .= $parts[$j+1] . "-" . $parts[$j+2] . ":";
					}
					$j++;
				}
			}
	        $i++;
		}
		@networks = sort(keys(%nets));
	}
}
sub ParseDHCPLeases {
	$dhcpfile = $settings->{'system'}->{'dhcp'}->{'leases'};
	
	our %lease;
	unless(open (IN, $dhcpfile)) {
		print "\nError: unable to open file $dhcpfile: $! \n";
		exit -1;
	}	
	@leases = <IN>;
	$data = "";
	foreach $line (@leases) {
		unless ($line =~ m/^#/) { # ignore commented lines
			$data .= $line;
		}
	}
	@data = split (/lease /, $data); 	#Split each lease into an array entry
	foreach (@data) {	                #create hash of hashes keyed on ip from the array
		@temp = split(/{/, $_);
		chop($temp[0]);			# 0 is IP 
		chop($temp[1]);			# 1 is the rest...
		$temp[1] =~ tr/\t//d;
		@t = split(/;\n/, $temp[1]);	#Split each lease on newline 
		$i=0;
		while ($t[$i]) {
			$string = $t[$i];
			$string =~ tr/\n//d;
	 		$string =~ s/^\s*//; # remove any leading spaces 
			@words = split(/\s+/, $string); #hashes keyed on first word
	
			if ($words[0]) {
				$key = shift(@words);
				$lease{$temp[0]}{$key}="@words";
				$lease{$temp[0]}{"hardware"}=~ s/ethernet//;		
				$lease{$temp[0]}{"binding"}=~ s/state //;		
			}
			$i++;
		}
	}
	@temp = sort(keys(%lease));
	$prev = "";					# checks for duplicates
	@ips=grep($_ ne $prev && (($prev) = $_), @temp);
	$entries = @ips;
}
sub PrintEntries {
	@DHCP_ROWS;
	($sortref, $dataref) = @_; 		# have to pass as a referece

		@sorted = @$sortref;			# dereference for sanity
		if ($dataref) {
			our %data = %$dataref;		# "                       "
		}

		## Calculate current GMT 
		($sec, $min, $hr, $mond, $mon, $year, $weekd, $yeard, $dls) = gmtime(time);
		$year += 1900;
		$mon++;
		if ($mon < 10) {
			$mon = "0" . $mon;
		}
		$curgmt = "$weekd $year/$mon/$mond $hr:$min:$sec";

		foreach $entry (@sorted) {
			if ($dataref) {
				$ip = $data{$entry};
			}
			else {
				$ip = $entry;
			}
			unless ($values{"filteractive"} && $lease{$ip}{"binding"} eq "free") {
				
	
				&getTemplate('dhcp_rows');
				&doSub("DHCP_IP", $ip );
				&doSub("DHCPHARDWARE", $lease{$ip}{"hardware"} );
				# REMOVE QUOTATIONS
				$lease{$ip}{"client-hostname"} =~ s/"//ge;
				@STARTDATE = &parsedate($lease{$ip}{"starts"});
				@ENDDATE = &parsedate($lease{$ip}{"ends"});
				$DHCPSTARTS = "@STARTDATE";
				$DHCPENDS = "@ENDDATE";
				&doSub("DHCLIENTHOSTNAME", $lease{$ip}{"client-hostname"} );
				&doSub("DHCPBINDING", $lease{$ip}{"binding"}	);
				&doSub("DHCPSTARTS", $STARTDATE );
				&doSub("DHCPENDS", $ENDDATE );
				&doSub("SESSION", $session );
				s/\[~~(!|\?)/\[$1/g;
				s/(!|\?)~~\]/$1\]/g;
				s/~~CARET/\^/g;
				push(@DHCP_ROWS, "$_");
			}
		}
		&getTemplate('dhcp_clients');
		&doSub("DHCPCLIENTS", "@DHCP_ROWS" );
		&printTemplate;
}
sub parsedate {
	#print "SENT: $_[0]<br>\n";
	@date = split(/ /, $_[0]);

	%months =	("01", "Jan",
			"02", "Feb",
			"03", "March",
			"04", "April",
			"05", "May",
			"06", "June",
			"07", "July",
			"08", "Aug",
			"09", "Sept",
			"10", "Oct",
			"11", "Nov",
			"12", "Dec");
	
	%days =	("0", "Sun",
		 	"1", "Mon",
			"2", "Tues",
			"3", "Wed",
			"4", "Thur",
			"5", "Fri",
			"6", "Sat");

	$date[0] = $days{$date[0]}. ", ";
	@day = split (/\//, $date[1]);
	$date[1] = $months{$day[1]} . " $day[2], $day[0] ";
	#print "DATE: @date<br>\n";
	return(@date, " GMT");
}
sub delDHCPleases { # WIP!
	$dhcpScopes = $settings->{'system'}->{'dhcp'}->{'scopedir'};
	$scopesConf = $settings->{'system'}->{'dhcp'}->{'scopeconf'};
	
	@perms = &runCmd("sudo chown apache:apache /var/lib/dhcpd/dhcpd.leases");
	@temp = &runCmd("sudo echo '' > /var/lib/dhcpd/dhcpd.leases");
	@cache = &runCmd("sudo rm /var/lib/dhcpd/dhcpd.leases~");
	
	$perms = "@perms";
	$temp = "@temp";
	$cache = "@cache";
	
print<<EOF

<!DOCTYPE html>
<html>
<head>
<title>DHCP Leases Cleared</title>
<script language="javascript">
alert('DHCP Leases Cleared.');
</script>
</head>
<body>
</body>
</html>

EOF
}
sub verifyIP { 
	$_ =~ s/\s//gi;
    $octets = "$_";
	$octets =~ s/\s//g;
	if( $octets =~ m/^(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)$/ ) {
		if($1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255) { 
			$err = 0;
		}
		else { $err = 1; }
    }
	else {
		$err = 1;
	}
	if($err == 1) {
		$msg = "Invalid IP format!";
		&getTemplate('genericwin');
		&doSub(GENERICDATA, $msg);
		&printTemplate;
		exit 0;
	}
}

#### FIREWALL ROUTINES - NEED TO ADD LOCAL IP ONLY IF STATIC CONFIGURED FOR AUTO-CONFIG!
#############################################################################################
## ADDED FOR RAZDC GUI:
sub rules {
	@iptablelist = &runCmd("sudo iptables --list");
	print "<pre>@iptablelist</pre>";
}
sub goodhosts { 
	$firewall = &loadJSON('firewall');
	$q=0;
	$frtype='allow';
	
	foreach $all (@{ $firewall->{$frtype} }) {
		$host = $firewall->{$frtype}[$q]->{'host'};
		$comment = $firewall->{$frtype}[$q]->{'comment'};
		$host =~ s/\s//gi;
		&getTemplate('fwHostLine');
		&doSub("TYPE", "$frtype");
		&doSub("ID", "$q");
		&doSub("HOST", "$host");
		&doSub("COMMENT", $comment);
		push(@lines, "$_");
		$q++;
	}
	
	&getTemplate('fwHosts');
	&doSub("MESSAGE", $message);
	&doSub("HOSTS", "@lines");
	&doSub("TYPE", "$frtype");
	&doSub("SESSION", $session);
	&printTemplate;	
}
sub save_goodhosts { # WIP
	$message = "Allow list has been updated.";
}
sub badhosts { 
	$firewall = &loadJSON('firewall');
	$q=0;
	$frtype='block';
	
	foreach $all (@{ $firewall->{$frtype} }) {
		$host = $firewall->{$frtype}[$q]->{'host'};
		$comment = $firewall->{$frtype}[$q]->{'comment'};
		$host =~ s/\s//gi;
		&getTemplate('fwHostLine');
		&doSub("TYPE", "$frtype");
		&doSub("ID", "$q");
		&doSub("HOST", "$host");
		&doSub("COMMENT", $comment);
		push(@lines, "$_");
		$q++;
	}

	&getTemplate('fwHosts');
	&doSub("MESSAGE", $message);
	&doSub("HOSTS", "@lines");
	&doSub("TYPE", "$frtype");
	&doSub("SESSION", $session);
	&printTemplate;
}
sub save_badhosts { # WIP
	$message = "Block list has been updated.";
}
sub ports { # WIP - PATHS TO CONFIG - NEED TEMPLATES CREATED - USER GENERIC OPTION IN SELECTS
	$firewall = &loadJSON('firewall');
	@protos = ('all','tcp','udp');
	$q=0;
	$frtype = 'interfaces';
	
	foreach $all (@{ $firewall->{$frtype} }) {
		$name = $firewall->{$frtype}[$q]->{'name'};
		$interface = $firewall->{$frtype}[$q]->{'interface'};
		push(@ints, "<option value='$interface'>$name</option>");
		$q++;
	}
	
	foreach(@protos) {
		$_ = "<option value='$_'>$_</option>";
	}
	
	$q=0;
	$frtype = 'ports';
	foreach $all (@{ $firewall->{$frtype} }) {
		$int = $firewall->{$frtype}[$q]->{'interface'};
		$proto = $firewall->{$frtype}[$q]->{'protocol'};
		$port = $firewall->{$frtype}[$q]->{'port'};
		$comment = $firewall->{$frtype}[$q]->{'comment'};		
		&getTemplate('fwPortLine');
		&doSub("ID", $q);
		&doSub("TYPE", "$frtype");
		&doSub("INT", $int);
		&doSub("INTS", "@ints");
		&doSub("PROTO", $proto);
		&doSub("PROTOS", "@protos");
		&doSub("PORT", $port);
		&doSub("COMMENT", $comment);
		push(@lines, "$_");
		$q++;
	}
	
 
	&getTemplate('fwPorts');
	&doSub("MESSAGE", $message);
	&doSub("INTS", "@ints");
	&doSub("PROTOS", "@protos");
	&doSub("PORTS", "@lines");
	&doSub("SESSION", $session);
	&printTemplate;
}
sub save_ports { # WIP
	$message = "Firewall ports have been updated.";
}
#### Get subnet bits
sub get_bits {  # 12/1/2022
  local($ip) = @_;
  
  # break up the bytes of the incoming IP address
  $_ = $ip;
  @ip_bytes = split(/\./);
   
  if ($ip_bytes[0] > 255 || $ip_bytes[1] > 255 || $ip_bytes[2] > 255 
       || $ip_bytes[3] > 255 || /[^0-9.]/ || $#ip_bytes != 3) {
     print "invalid input mask or wildcard\n";
     exit(  );
  }
   
  $bits = 0;
  for ($i=0; $i < 4 ; $i++) {
     if ($ip_bytes[$i] > 0 && $bits < 8*$i) {
        print "invalid mask for bit count format\n";
        exit(  );
     }
     if ($ip_bytes[$i] == 255 ) { $bits += 8;
     } elsif ($ip_bytes[$i] == 254 ) { $bits += 7; 
     } elsif ($ip_bytes[$i] == 252 ) { $bits += 6; 
     } elsif ($ip_bytes[$i] == 248 ) { $bits += 5; 
     } elsif ($ip_bytes[$i] == 240 ) { $bits += 4; 
     } elsif ($ip_bytes[$i] == 224 ) { $bits += 3; 
     } elsif ($ip_bytes[$i] == 192 ) { $bits += 2; 
     } elsif ($ip_bytes[$i] == 128 ) { $bits += 1; 
     } elsif ($ip_bytes[$i] != 0 ) {
        print "invalid mask for bit count format\n";
        exit(  );
     }
   }
   return($bits);
}
## ORIGINAL FW ROUTINES:
# ORIGINAL FW ROUTINES:
sub reload_fw { # WIP - ADD FW PATHS TO JSON
	$default_policy = "DROP";
	$iptables = "/sbin/iptables";
	$firewall = &loadJSON('firewall');

	set_ip_forwarding(0);
	load_interfaces();

	$protocols{tcp}++;
	$protocols{udp}++;
	$protocols{icmp}++;

	init();
	set_default_policy();
	add_good_hosts();
	add_bad_hosts();
	build_chains();
	add_rules();
	set_default_action();
	set_ip_forwarding(1);
}
sub load_interfaces {
	$q=0;
	$frtype='interfaces';
	foreach $all (@{ $firewall->{$frtype} }) {
		$name = $firewall->{$frtype}[$q]->{'name'};
		$int = $firewall->{$frtype}[$q]->{'interface'};
		$interface{$name} = $int;
		$q++;
	}
}
sub init {
    iptables("-F");  # flush rules
    iptables("-t nat -F");
    iptables("-X");  # delete chains
    iptables("-Z");  # zero counters
    iptables("-t nat -A POSTROUTING -j MASQUERADE");
    iptables("-A INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT");
}
sub set_default_policy {
    iptables("-P INPUT $default_policy");
    iptables("-P OUTPUT ACCEPT");
    iptables("-P FORWARD ACCEPT");
    return;
}
sub build_chains {
    my($interface, $protocol, $chain);

    foreach $interface (keys %interface) {
        foreach $protocol (keys %protocols) {
            $chain = "$interface-$protocol";

            iptables("-N $chain");
            iptables("-A INPUT -i $interface{$interface} -p $protocol -j $chain");
        }
    }
}
sub add_rules {
	$q=0;
	$frtype='ports';
	foreach $all (@{ $firewall->{$frtype} }) {
		$int = $firewall->{$frtype}[$q]->{'interface'};
		$proto = $firewall->{$frtype}[$q]->{'protocol'};
		$port = $firewall->{$frtype}[$q]->{'port'};
		$port_comment = $firewall->{$frtype}[$q]->{'comment'};
		$i = $interface{$int};
		$chain = "$int-$proto";
		if ($proto eq "all") {
            foreach $proto (keys %protocols) {
                $chain = "$int-$proto";
				#print "ALL: -A $chain -i $i -p $proto -j ACCEPT\n";
                iptables("-A $chain -i $i -p $proto -j ACCEPT");
            }
        }
        if ($proto eq "udp") {
			 #print "UDP: -A $chain -i $i -p udp --dport $port -j ACCEPT\n";
            iptables("-A $chain -i $i -p udp --dport $port -j ACCEPT");
			 #print "UDP: -A $chain -i $i -p udp --sport $port -j ACCEPT\n";
            iptables("-A $chain -i $i -p udp --sport $port -j ACCEPT");
        }
        if ($proto eq "tcp") {
			#print "TCP: -A $chain -i $i -p tcp --dport $port --syn -j ACCEPT\n";
            iptables("-A $chain -i $i -p tcp --dport $port --syn -j ACCEPT");
			#print "TCP: -A $chain -i $i -p tcp --dport $port -j ACCEPT\n";
            iptables("-A $chain -i $i -p tcp --dport $port -j ACCEPT");
        }
		$q++;
	}
}
sub set_default_action {
    my($interface, $protocol, $chain);
    foreach $interface (keys %interface) {
        foreach $protocol (keys %protocols) {
            $chain = "$interface-$protocol";
            iptables("-A $chain -j LOG --log-prefix DEFAULT_$default_policy-$chain-");
            iptables("-A $chain -j $default_policy");
        }
    }
	$result = system("service iptables save");
}
sub iptables {
    my($line) = @_;
	$iptables = "/sbin/iptables";
    @result = &runCmd("$iptables $line");
    $result = "@result";
	
	if ($result != 0) {
        print "X: ($result) iptables $line\n";
    }
}
sub set_ip_forwarding {
    ($value) = @_;
    local(*FILE);
    open FILE, ">/proc/sys/net/ipv4/ip_forward";
    print FILE $value;
    close FILE;
}
sub add_good_hosts {
	$q=0;
	$frtype='allow';
	foreach $all (@{ $firewall->{$frtype} }) {
		$host = $firewall->{$frtype}[$q]->{'host'};
		$comment = $firewall->{$frtype}[$q]->{'comment'};
		iptables("-A INPUT -s $host -j ACCEPT");
        iptables("-A OUTPUT -d $host -j ACCEPT");
		$q++;
	}
}
sub add_bad_hosts {
    $q=0;
	$frtype='block';
	foreach $all (@{ $firewall->{$frtype} }) {
		$host = $firewall->{$frtype}[$q]->{'host'};
		$comment = $firewall->{$frtype}[$q]->{'comment'};
		iptables("-A INPUT -s $host -j LOG --log-prefix $comment");
        iptables("-A OUTPUT -d $host -j LOG --log-prefix $comment");
        iptables("-A INPUT -s $host -j DROP");
        iptables("-A OUTPUT -d $host -j DROP");
		$q++;
	}
}
$client->disconnect;