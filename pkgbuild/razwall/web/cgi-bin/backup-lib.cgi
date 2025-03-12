#!/usr/bin/perl
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


require 'header.pl';
use File::Copy;
use File::Temp qw/ tempdir tempfile/;
use Sys::Hostname;

# -------------------------------------------------------------------
# Check if the demo mode is enabled

my $demo_conffile = "${swroot}/demo/settings";
my $demo_conffile_default = "/usr/lib/efw/demo/default/settings";
my %demo_settings_hash = ();
my $demo_settings = \%demo_settings_hash;

if (-e $demo_conffile_default) {
    readhash($demo_conffile_default, $demo_settings);
}

if (-e $demo_conffile) {
    readhash($demo_conffile, $demo_settings);
}

$demo = $demo_settings->{'DEMO_ENABLED'} eq 'on';
# -------------------------------------------------------------------

$backupsets='/var/backups/';
$backup='/usr/local/bin/backup-create';
$restore='/usr/local/bin/backup-restore';
$factoryfile='/var/efw/factory/factory.tar.gz';

$conffile    = "${swroot}/backup/settings";
$conffile_default = "${swroot}/backup/default/settings";

$errormessage = '';
%par;
%conf_hash;
$conf = \%conf_hash;

$gpgkey = '';
$gpgwrap = 'sudo /usr/local/bin/gpgwrap.sh';
%checked = ( 0 => '', 'on' => "checked='checked'" );

$removebackupusb = 'sudo /usr/local/bin/efw-backupusb --removebackup';
$createbackupusb = 'sudo /usr/local/bin/efw-backupusb --runbackup';

sub save_meta($$) {
    my $fname = shift;
    my $msg = shift;

    open(F, ">${fname}.meta") || return 1;
    print F "$msg";
    close(F);
}

sub get_meta($) {
    my $fname = shift;
    open(F, "${fname}") || return "";
    my @msg = <F>;
    return join(" ",@msg);
}

sub format_date($) {
    my $number = shift;
    if ($number =~ /^(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(.*)$/) {
        my $year=$1;
        my $month=$2;
        my $day=$3;
        my $hour=$4;
        my $minute=$5;
        my $second=$6;
        my $timezone=$7;
        if ($timezone eq "") {
            $timezone = DateTime::TimeZone->new( name => 'local' )->name();
        }

        use DateTime;
        my $dt = DateTime->new(
           year   => $year,
           month  => $month,
           day    => $day,
           hour   => $hour,
           minute => $minute,
           second => $second,
           time_zone => $timezone
        );
        $dt->set_time_zone(DateTime::TimeZone->new( name => 'local' )->name());
        return $dt->strftime("%a, %d %b %Y %H:%M:%S %Z");
    }
    return $number;
}

sub get_now() {
    use DateTime;
    my $dt = DateTime->now;
    return $dt->strftime("%Y%m%d%H%M%S%Z");
}

sub check_archive($) {
    my $arch = shift;
    use File::Path;

    my $content='';
    if (! -e $arch) {
        return (1,'');
    }
    my $tmp = tempdir('importXXXXXX', DIR=> '/var/tmp/');
    return '' if ($tmp !~ /^\/var\/tmp/);

    if (system("tar -C $tmp -xzf $arch &>/dev/null") != 0) {
        rmtree($tmp);
        return '';
    }
    if (-e "$tmp/var/efw/dhcp/") {
        $content.='-settings';
    }
    if (-e "$tmp/var/pgsql_backup/psql-latest.dump.bz2" || -e "$tmp/var/efw/mongodb/mongodb-latest.dump.tar.xz") {
        $content.='-db';
    }
    if (-d "$tmp/var/log") {
        $content.='-logs';
    }
    if (-e "$tmp/etc/businfotab") {
        $content.='-hwdata';
    }
    if (-d "$tmp/var/log/archives") {
        $content.='-logarchive';
    }
    rmtree($tmp);
    return $content;
}

sub import_archive() {
    if ($demo) {
        return 0;
    }
    if (ref ($par{'IMPORT_FILE'}) ne 'Fh')  {
        $errormessage = _('No data was uploaded');
        return 0;
    }
    my ($fh, $tmpfile) = tempfile("import.XXXXXX", DIR=>'/var/tmp/', SUFFIX=>'.tar.gz');
    if (!copy ($par{'IMPORT_FILE'}, $fh)) {
        $errormessage = _('Unable to save configuration archive file %s: \'%s\'', $par{'IMPORT_FILE'}, $!);
        return 0;
    }
    close($fh);

    my $now=get_now();
    my $hostname=hostname();

    my $content = check_archive($tmpfile);
    if ($content =~ /^$/) {
        unlink($tmpfile);
        $errormessage = _('Invalid backup archive!');
        return 0;
    }

    my $newfilename = "$backupsets/backup-${now}-${hostname}${content}.tar.gz";
    if (! move($tmpfile, $newfilename)) {
        unlink($tmpfile);
        $errormessage = _('Could not bring imported backup archive in place! (%s)', $!);
        return 0;
    }

    save_meta($newfilename, $par{'REMARK'});
    $notemessage = _('Backup archive successfully imported.');
    system("jobcontrol call base.noop &>/dev/null");
    return 1;
}

sub factory() {
    if ($demo) {
        return 0;
    }
    if (! -x "/usr/local/bin/factory-default") {
        $errormessage = _('Could not bring the machine to factory defaults!');
        return 0;
    }
    system("/usr/local/bin/factory-default &");
    return 1;
}

sub remove_archive($) {
    my $basename = shift;
    if ($demo) {
        return 0;
    }
    if ($basename =~ /^$/) {
        return 0;
    }

    my $followed_link = readlink("$backupsets/$basename");
    if (!"$followed_link") {
        $followed_link = readlink("$backupsets/$basename.gpg");
    }
    if ("$followed_link") {
        my $unlinkcmd = "$removebackupusb \"" . "$followed_link" . '"';
        call($unlinkcmd);
    }

    if ( -e "$backupsets/$basename" || -l "$backupsets/$basename") {
        unlink("$backupsets/$basename");
    }
    if ( -e "$backupsets/$basename.meta" || -l "$backupsets/$basename.meta") {
        unlink("$backupsets/$basename.meta");
    }
    if ( -e "$backupsets/$basename.gpg" || -l "$backupsets/$basename.gpg") {
        unlink("$backupsets/$basename.gpg");
    }
    if ( -e "$backupsets/$basename.mailerror" || -l "$backupsets/$basename.mailerror") {
        unlink("$backupsets/$basename.mailerror");
    }
    if ( -e "$backupsets/$basename.gpg.mailerror" || -l "$backupsets/$basename.gpg.mailerror") {
        unlink("$backupsets/$basename.gpg.mailerror");
    }
    if (-e "$backupsets/$basename") {
        $errormessage = _('Backup archive "%s" not removed!', $basename);
        return 0;
    }
    $notemessage = _('Backup archive "%s" successfully removed!', $basename);
    system("jobcontrol call base.noop &>/dev/null");
    return 1;
}

sub remove_vmarchive($) {
    my $path = shift;
    if ($demo) {
        return 0;
    }
    if ($path =~ /^$/) {
        return 0;
    }
    if ( -e "$path" || -l "$path") {
        my $unlinkcmd = "$removebackupusb \"" . "$path" . '"';
        call($unlinkcmd);
    }
    if (-e "$path") {
        $errormessage = _('Virtual machine backup archive "%s" not removed!', $path);
        return 0;
    }
    $notemessage = _('Virtual machine backup archive "%s" successfully removed!', $path);
    return 1;
}

sub call($) {
    my $cmd = shift;
    use IPC::Open3;

    $pid = open3(\*WRITE, \*READ, \*ERROR, $cmd);
    if (! $pid) {
        return (0, _('Could  not call "%s"', $cmd));
    }
    close WRITE;
    my @err = <ERROR>;
    my @out = <READ>;
    close READ;
    close WRITE;

    my $reterr = join(" ", @err);
    my $retout = join(" ", @out);

    my $ret = 0;
    waitpid($pid, 0);
    if ($? == 0) {
        $ret = 1;
    }
    return ($ret, $reterr, $retout);
}

sub create($$$$$$$$) {
    my $settings=shift;
    my $dbdumps=shift;
    my $logs=shift;
    my $logarchives=shift;
    my $hwdata=shift;
    my $remark=shift;
    my $vm=shift;
    my $usb=shift;
    my $args = "";

    if ($demo) {
        return 0;
    }

    if ($usb) {
        $args .= " --usb";
        if ($vm) {
            $args .= " --virtualmachines";
        }
    }
    if ($settings) {
        $args .= " --settings";
    }
    if ($dbdumps) {
        $args .= " --dbdumps";
    }
    if ($logs) {
        $args .= " --logs";
    }
    if ($logarchives) {
        $args .= " --logarchives";
    }
    if ($hwdata) {
        $args .= " --hwdata";
    }
    if ($remark !~ /^$/) {
        $args .= " --message=\"$remark\"";
    }
    if (($conf->{'BACKUP_ENCRYPT'} eq 'on') && ($conf->{'BACKUP_GPGKEY'} !~ /^$/)) {
        $args .= " --gpgkey=$conf->{'BACKUP_GPGKEY'}";
    }
    if (! $settings && ! $logs && ! $dbdumps && ! $logarchives && ! $hwdata && ! $vm) {
        $errormessage = _('Include at least something to backup!');
        return 0;
    }
    system("jobcontrol call backup.do_backup $args &>/dev/null");
    return 1;
}

sub restore($) {
    my $basename = shift;
    if ($demo) {
        return 0;
    }

    my $backupcmd="$restore --reboot $backupsets/$basename &";

    if (! -e "$backupsets/$basename") {
        $errormessage = _('Backup set "%s" not found!', $basename);
        return 0;
    }
    if ($basename =~ /.gpg$/) {
        $errormessage = _('Cannot restore encrypted backups!');
        return 0;
    }

    system($backupcmd);
    system("jobcontrol call base.noop &>/dev/null");

    return 1;
}

sub display_reboot() {
    my $title='';
    if ($par{'ACTION'} eq 'restore') {
        $title = _('Restore is in progress! Please wait until reboot!');
    }
    if ($par{'ACTION'} eq 'factory') {
        $title = _('Reset to factory default is in progress! Please wait until reboot!');
    }
    openbox('100%', 'left', $title);
    printf <<END
<br />
<br />
<div align='center'>
  <img src='/images/reboot_splash.png' />
<br /><br />
<font size='6'>$title</font>
</div>
END
;

    closebox();
}

sub save() {
    if ($demo) {
        return 0;
    }
    if ($gpgkey !~ /^$/) {
        chomp($gpgkey);
        $conf->{'BACKUP_GPGKEY'} = $gpgkey;
    }
    $conf->{'BACKUP_ENCRYPT'} = $par{'BACKUP_ENCRYPT'};
    &writehash("${swroot}/backup/settings", $conf);
    system("jobcontrol call base.noop &>/dev/null");
}

sub configure_gpgkey() {
    if ($demo) {
        return 0;
    }
    save();

    if (ref ($par{'IMPORT_FILE'}) ne 'Fh')  {
        return 1;
    }

    my ($fh, $tmpfile) = tempfile("gpgkey.XXXXXX", DIR=>'/var/tmp/', SUFFIX=>'.tar.gz');
    if (!copy ($par{'IMPORT_FILE'}, $fh)) {
        $errormessage = _('Unable to store GPG public key: \'%s\'', $par{'IMPORT_FILE'}, $!);
        return 0;
    }
    close($fh);
    my ($r, $e, $o) = call("$gpgwrap --import ".$tmpfile);
    system("jobcontrol call base.noop &>/dev/null");

    if (! $r) {
        $errormessage = _('Could not import GPG public key because "%s".', $e);
        return 0;
    }

    if ($o =~ /^$/) {
        my $err = _('No GPG user ID found');
        $errormessage = _('Could not import GPG public key because "%s".', $err);
        return 0;
    }
    unlink($tmpfile);
    $gpgkey = $o;
    $notemessage = _('GPG public key "%s" imported successfully', $gpgkey);
    save();
    return 1;
}

sub doaction() {
    return factory() if ($par{'ACTION'} eq 'factory');
    return restore($par{'ARCHIVE'}) if ($par{'ACTION'} eq 'restore');
    if ($par{'ACTION'} eq 'create') {
        create($par{'SETTINGS'},
               $par{'DBDUMPS'},
               $par{'LOGS'},
               $par{'LOGARCHIVES'},
               $par{'HWDATA'},
               $par{'REMARK'},
               $par{'VIRTUALMACHINES'},
               $par{'CREATEBACKUPUSB'});
    }
    remove_archive($par{'ARCHIVE'}) if ($par{'ACTION'} eq 'remove');
    remove_vmarchive($par{'ARCHIVE'}) if ($par{'ACTION'} eq 'removevm');
    import_archive() if ($par{'ACTION'} eq 'import');
    configure_gpgkey() if ($par{'ACTION'} eq 'gpgkey');
    return 0;
}


