#!/usr/bin/perl
#
# Backup CGI for Endian Firewall
#
#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2005-2008 Endian                                              |
#        |         Endian GmbH/Srl                                                     |
#        |         Bergweg 41 Via Monte                                                |
#        |         39057 Eppan/Appiano                                                 |
#        |         ITALIEN/ITALIA                                                      |
#        |         info@endian.it                                                      |
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


require '/razwall/web/cgi-bin/backup-lib.cgi';

$usbstickdetected=`mount | grep '/mnt/usbstick' 2>/dev/null`;
$virtualization=`/usr/bin/rpm -q efw-virtualization | grep endian`;

sub display() { 

#print "<div id=\"newbackup\" style=\"display: none\">";

# backup sets
openbox('100%', 'left', _('Backup sets'));

&openeditorbox(_('Create new Backup'), _("Create new Backup"), "", "createrule", @errormessages);
#openbox('100%', 'left', _('Create new Backup'));
printf <<END
  <input type='hidden' name='ACTION' value='create' />
  <table>
    <tr>
      <td>%s:</td>
      <td><input type='checkbox' name='SETTINGS' checked="checked" /></td>
    </tr>
END
, _('Include configuration')
;

printf <<END
    <tr>
        <td>%s</td>
        <td><input type='checkbox' name='DBDUMPS' checked /></td>
    </tr>
    <tr>
        <td>%s</td>
        <td><input type='checkbox' name='LOGS' checked /></td>
    </tr>
    <tr>
        <td>%s</td>
        <td><input type='checkbox' name='LOGARCHIVES' checked /></td>
    </tr>
    <tr>
        <td>%s</td>
        <td><input type='checkbox' name='HWDATA' unchecked /></td>
    </tr>
    <tr>
        <td>%s</td>
        <td><input type='text' name='REMARK' size='30' /></td>
    </tr>
END
, _('Include database dumps')
, _('Include log files')
, _('Include log archives')
, _('Include hardware data')
, _('Remark')
;

if ( $usbstickdetected ) {
printf <<END
    <tr>
        <td><b>%s</b> (%s)</td>
        <td><input type='checkbox' name='CREATEBACKUPUSB' checked="checked" onClick="\$('#virtualmachines').toggle();" /></td>
    </tr>
END
, _('Create backup on USB Stick')
, _('USB Stick detected')
;
    if ($virtualization ne "") {
printf <<END
    <tr id="virtualmachines">
        <td>%s</td>
        <td><input type='checkbox' name='VIRTUALMACHINES' checked /></td>
    </tr>
END
, _('Backup virtual machine snapshots on USB disk')
;
    }
    else {
printf <<END
    <input type='hidden' name='VIRTUALMACHINES' value='0' />
END
;
    }
}
else {
printf <<END
    <input type='hidden' name='VIRTUALMACHINES' value='0' />
END
;
}

print <<END
    </tr>
  </table>
END
;
closeeditorbox(_("Create Backup"), _("Cancel"), "routebutton", "createrule");
#    closebox();

#print "</div>";

printf <<END
<table class="ruleslist" id="backuplist" width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td class='boldbase' style="width: 240px;">%s</td>
    <td class='boldbase' style="width: 90px;">%s</td>
    <td class='boldbase'>%s</td>
    <td class='boldbase' style="width: 90px;">%s</td>
  </tr>
END
, _('Creation date')
, _('Content')
, _('Remark')
, _('Actions')
;

my $i = 0;

foreach my $archive (reverse glob("${backupsets}/backup-*.tar.gz*meta")) {
    my $bgcolor = setbgcolor(0, 0, $i);
    $archive =~ s/\.meta$//;
    $archive =~ /\/(backup[^\/]+)$/;
    my $basename = $1;

    $archive =~ /\/backup-([^-]+)-([^\s\.]+\.[^\s]+?)-([^\.]+)\.tar\.gz/;
    my $date = format_date($1);
    my $dns = $2;
    my $content_part = $3;

    my $content = '';
    if ($content_part =~ /settings/) {
       $content = 'S';
    }
    if ($content_part =~ /db/) {
       $content .= '&nbsp;D';
    }
    if ($content_part =~ /logs/) {
       $content .= '&nbsp;L';
    }
    if ($content_part =~ /logarchive/) {
       $content .= '&nbsp;A';
    }
    if ($content_part =~ /hwdata/) {
       $content .= '&nbsp;H';
    }
    if ($content_part =~ /cron/) {
       $content .= '&nbsp;C';
    }
    if ($content_part =~ /virtualmachines/) {
       $content .= '&nbsp;V';
    }
    if (-e "${archive}.gpg") {
       $content .= '&nbsp;E';
    }
    if (-e "${archive}.mailerror") {
       $content .= '&nbsp;!';
    }
    if (-e "${archive}.gpg.mailerror") {
       $content .= '&nbsp;!';
    }
    if (-l "${archive}.meta") {
       $content .= '&nbsp;U';
    }

    $content =~ s/^(&nbsp;)*//;

    my $meta = get_meta("${archive}.meta");
    $meta =~ s/-/ - /g;
    my $remark = value_or_nbsp($meta);
printf <<END
  <tr class="$bgcolor">
    <td>$date</td>
    <td>$content</td>
    <td>$remark</td>
END
;

    if (-e "${archive}.gpg") {
        printf <<END
    <td class="actions">
      <a href="/backup/${basename}.gpg"><img class="imagebutton" border="0"  src='/images/download_encrypted.png' alt='%s' title='%s' /></a>
      <a href="/backup/${basename}"><img class="imagebutton" border="0"  src='/images/download.png' alt='%s' title='%s' /></a>
END
, _('Export encrypted archive')
, _('Export encrypted archive')
, _('Export plain archive')
, _('Export plain')
;
    } else {
        printf <<END
    <td class="actions">
      <a href="/backup/${basename}"><img class="imagebutton" border="0" src='/images/download.png' alt='%s' title='%s' /></a>
END
, _('Export')
, _('Export')
;
}

printf <<END
      <form method='post' action='$ENV{'SCRIPT_NAME'}' onSubmit="return confirm('%s');">
        <input type='hidden' name='ACTION' value='remove' />
        <input type='hidden' name='ARCHIVE' value='${basename}' />
        <input class='imagebutton' type='image' name='submit' src='/images/delete.png' alt='%s' title='%s' />
      </form>
      <form method='post' action='$ENV{'SCRIPT_NAME'}' onSubmit="return confirm('%s');">
        <input type='hidden' name='ACTION' value='restore' />
        <input type='hidden' name='ARCHIVE' value='${basename}' />
        <input class='imagebutton' type='image' name='submit' src='/images/reload.png' alt='%s' title='%s' />
      </form>
    </td>
  </tr>

END
, _('Do you really want to remove the backup archive %s?', $basename)
, _('Delete')
, _('Delete')
, _('Do you really want to restore the backup archive %s? All existing data will be overwritten and then %s %s will reboot!', $basename,$brand,$product )
, _('Restore')
, _('Restore')
;

    $i++;
}

printf <<END
</table>

<br>
<table>
  <tr>
    <td width="5%">
      <b>%s:</b>
    </td>
    <td width="32%">S: %s</td>
    <td width="32%">D: %s</td>
    <td width="31%">E: %s</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td>L: %s</td>
    <td>A: %s</td>
    <td>!: %s</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td>C: %s</td>
    <td>H: %s</td>
    <td>U: %s</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td>%s</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td><img src='/images/download.png' />: %s</td>
    <td><img src='/images/delete.png' />: %s</td>
    <td><img src='/images/reload.png' />: %s</td>
  </tr>
</table>
END
, _('Legend')
, _('Settings')
, _('Database dumps')
, _('Archive is encrypted')
, _('Log files')
, _('Log archives')
, _('Error sending backup')
, _('Created automatically with a Schedule')
, _('Hardware data')
, _('Backup is on USB Stick')
, $virtualization eq "" ? "&nbsp;" : "V: "._("Virtual machines")
, _('Export archive')
, _('Delete archive')
, _('Restore archive')
;
closebox();

if ($virtualization ne "") {
openbox('100%', 'left', _('Virtual machine backups'));
printf <<END
<table class="ruleslist" id="vmbackuplist" width="100%" cellpadding="0" cellspacing="0">
	<tr>
    	<td class='boldbase' style="width: 240px;">%s</td>
    	<td class='boldbase' style="width: 90px;">%s</td>
    	<td class='boldbase'>%s</td>
    	<td class='boldbase' style="width: 90px;">%s</td>
 	</tr>
END
, _('Creation date')
, _('Virtual machine')
, _('Remark')
, _('Actions')
;

my $i = 0;

foreach my $archive (reverse glob("/mnt/usbstick*/vm-backups/vm-backup-*.gz")) {
    $archive =~ /\/(vm-backup[^\/]+)$/;
    my $basename = $1;
	
	my $date = "";
	my $vmname = "";
	my $remark = $basename;
	
    my $bgcolor = setbgcolor(0, 0, $i);
	my %metahash = ();
	my $meta = \%metahash;
	if (-e "$archive.meta") {
		&readhash("$archive.meta", $meta);
		$date = format_date($meta->{'timestamp'});
		$vmname = $meta->{'name'};
		$remark = $meta->{'remark'}
	}
	printf <<END
	<tr class="$bgcolor">
  		<td>$date</td>
    	<td>$vmname</td>
    	<td>$remark</td>

		<td>
			<form method='post' action='$ENV{'SCRIPT_NAME'}' onSubmit="return confirm('%s');">
        		<input type='hidden' name='ACTION' value='removevm' />
        		<input type='hidden' name='ARCHIVE' value='${archive}' />
        		<input class='imagebutton' type='image' name='submit' src='/images/delete.png' alt='%s' title='%s' />
      		</form>
    	</td>
	</tr>
END
, _('Do you really want to remove the virtual machine backup archive %s?', $basename)
, _('Delete')
, _('Delete')
;
    $i++;
}

printf <<END
</table>
END
;

closebox();
}

    # import gpgkey
    openbox('100%', 'left', _('Encrypt backup archives with a GPG public key'));
    if ($conf->{'BACKUP_ENCRYPT'} !~ /^$/) {
        my ($r, $e, $keyinfo) = call("$gpgwrap --show-key ".$conf->{'BACKUP_GPGKEY'});

        my $keyinfo_sanitized = cleanhtml($keyinfo, 'y');
        printf <<END
%s:
<br>
<pre>
 $keyinfo_sanitized
</pre>
END
, _('The following GPG public key will be used to encrypt the backup archives')
;
    }
printf <<END
  <form method='post' action='$ENV{'SCRIPT_NAME'}' enctype='multipart/form-data'>
  <input type='hidden' name='ACTION' value='gpgkey' />
  <table cols="3">
    <tr>
      <td>%s:</td>
      <td><input type='checkbox' name='BACKUP_ENCRYPT' $checked{$conf->{'BACKUP_ENCRYPT'}} value='on' /></td>
      <td></td>
    </tr>
    <tr>
      <td>%s:</td>
      <td><input type='file' name='IMPORT_FILE' size='40' %s /></td>
      <td></td>
    </tr>
    <tr><td></td></tr>
    <tr>
      <td><input class='submitbutton' type='submit' name='submit' value='%s' /></td>
    </tr>
  </table>
  </form>
END
, _('Encrypt backup archives')
, _('Import GPG public key')
, $demo ? "disabled='disabled'" : ""
, _('Save')
;
    closebox();

    # import
    openbox('100%', 'left', _('Import backup archive'));
printf <<END
  <form method='post' action='$ENV{'SCRIPT_NAME'}' enctype='multipart/form-data'>
  <input type='hidden' name='ACTION' value='import' />
  <table>
    <tr>
      <td>%s:</td>
      <td><input type='file' name='IMPORT_FILE' size='40' %s /></td>
      <td></td>
    </tr>
    <tr>
      <td>%s:</td>
      <td><input type='text' name='REMARK' size='40' /></td>
      <td>&nbsp;</td>
    </tr>
    <tr><td></td></tr>  
    <tr>
      <td><input class='submitbutton' type='submit' name='submit' value='%s' /></td>
    </tr>
  </table>
  </form>
END
, _('File')
, $demo ? "disabled='disabled'" : ""
, _('Remark')
, _('Import')
;
    closebox();


    # factory default
    if (-e $factoryfile) {
        openbox('100%', 'left', _('Reset configuration to factory defaults and reboot'));
        printf <<END
  <form method='post' action='$ENV{'SCRIPT_NAME'}' onSubmit="return confirm('%s');">
    <input type='hidden' name='ACTION' value='factory' />
    <div align='center'>
      <input class='submitbutton' type='submit' name='submit' value='%s' />
    </div>
  </form>
END
, _('Do you really want to reset to factory defaults?')
, _('Factory defaults')
;
        closebox();
    }
}


&getcgihash(\%par, {'wantfile' => 1, 'filevar' => 'IMPORT_FILE'});

&showhttpheaders();
&openpage(_('Backup configuration'), 1, '');

&readhash("${swroot}/backup/settings", $conf);

my $reboot = doaction();
if(!($notemessage ne '' && $par{'ACTION'} eq 'create')) {
    &openbigbox($errormessage, $warnmessage, $notemessage);
}

# Display service notifications if no error occured.
$service_restarted = $par{'ACTION'} eq 'create' ? 1 : 0;
if($validation_error != 1) {
    &service_notifications(['backup'], 
                          {'type' => $service_restarted == 1 ? "commit" : 
                                                               "observe",
                           'interval' => 1000, 
                           'startMessage' => _("Backing up your data. ". 
                                               "Please hold..."),
                           'endMessage' => _("Backup completed successfully"),
                           'updateContent' => '#backuplist',
                           'delay' => 4
                          });
}

if ($reboot == 0) {
  display();
} else {
  display_reboot();
}
closebigbox();
closepage();

exit 0;

