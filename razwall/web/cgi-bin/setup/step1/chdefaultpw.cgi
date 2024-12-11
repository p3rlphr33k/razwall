#!/usr/bin/perl
#
#        +-----------------------------------------------------------------------------+
#        | Endian Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2005-2006 Endian                                              |
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

require 'header.pl';
require '/razwall/web/cgi-bin/backup-lib.cgi';
require '/razwall/web/cgi-bin/passwd-lib.pl';

# use LWP::UserAgent;

if ( -f '/usr/share/endian/COPYING' ) {
    $eulafile = '/usr/share/endian/COPYING';
} else {
    $eulafile = '/usr/share/endian/GPL';
}

my $timeconffile = '/var/efw/time/settings';
my $mainsettings = '/var/efw/main/settings';
my $i18n = '/usr/lib/efw/i18n/';
my $productconffile = '/var/efw/product/settings';
my $wizardconffile = '/var/efw/wizard/settings';

my %wizardhash;
readhash($wizardconffile, \%wizardhash);

my $enterprise = is_enterprise();
my $product = get_product();

my %par;
my %timeconf_hash = ();
my $timeconf = \%timeconf_hash;

$par{'step'} = 0;
$par{'accept'} = '';

sub is_enterprise() {
    my %product_hash = ();
    my $productconf = \%product_hash;
    readhash($productconffile, $productconf);

    if ($productconf->{'ENTERPRISE'} eq 'yes') {
	return 1;
    }
    return 0;
}

sub load_languages() {
    my %ret_hash = ();
    my $ret = \%ret_hash;

    my %ret_hash_sorted = ();
    my $ret_sorted = \%ret_hash_sorted;

    opendir(my $fd, $i18n) || return ();
    foreach my $line(readdir($fd)) {
	my %hash = ();
        my $item = \%hash;
	readhash($i18n.'/'.$line, $item);
	next if ($item->{'ISO'} =~ /^$/);
        $ret_sorted->{$item->{'PRIORITY'}.$item->{'GENERIC'}} = $item;
        $ret->{$item->{'ISO'}} = $item;
    }
    close($fd);
    return ($ret, $ret_sorted);
}


sub redirect($) {
    $page=shift;	
    print "Status: 302 Moved\n";
    print "Location: https://$ENV{'SERVER_ADDR'}:10443${page}\n\n";
    exit;
}

sub get_eula() {
    return '' if (! -e $eulafile);
    open F, "$eulafile";
    my @ret = <F>;
    close F;
    return join("", @ret);
}

sub loadconfig() {
    readhash($timeconffile, $timeconf);
    if ($timeconf->{'TIMEZONE'} =~ /^$/) {
        my %mainhash = ();
        my $mainconf = \%mainhash;
        readhash($mainsettings, $mainconf);
        $timeconf->{'TIMEZONE'} = $mainconf->{'TIMEZONE'};
        $timeconf->{'TIMEZONE'} =~ s+/usr/share/zoneinfo/(posix/)?++;
    }
    if (-e $enabled_file) {
        $enabled = 1;
    }
}

sub restore_local($) {
    my $basename = shift;

    # remove EN Registration ?
    if ($par{'DELETE_REGISTRATION'} eq 'on') {
        $backupcmd="$restore --delete-sysid $backupsets/$basename"; 
    } else {  
        $backupcmd="$restore $backupsets/$basename";  
    }

    if (! -e "$backupsets/$basename") {
        $errormessage = _('Backup set "%s" not found!', $basename);
        return 0;
    }
    if ($basename =~ /.gpg$/) {
        $errormessage = _('Cannot restore encrypted backups!');
        return 0;
    }

    system($backupcmd);

    # restoring a backup skips netwizard and jumps directly to registering
    $wizardhash{'WIZARD_STATE'} = "register";
    writehash($wizardconffile, \%wizardhash);

    return 1;    
}

sub import_archive_local() {
    if (ref ($par{'IMPORT_FILE'}) ne 'Fh')  {
        $errormessage = "No data was uploaded: importfile $par{'IMPORT_FILE'}";
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

    my $file = "backup-${now}-${hostname}${content}.tar.gz";
    my $newfilename = "$backupsets/$file";
    if (! move($tmpfile, $newfilename)) {
        unlink($tmpfile);
        $errormessage = _('Could not bring imported backup archive in place! (%s)', $!);
        return 0;
    }
    
    $par{'REMARK'} = $file;
    save_meta($newfilename, $par{'REMARK'});
    restore_local($file);
    $notemessage = _('Backup archive successfully restored. The %s is going down for reboot NOW!', $brand.' '.$product);
    system '/usr/local/bin/ipcoprebirth';
    return 1;
}

# already done this step ?
my $state = uc($wizardhash{'WIZARD_STATE'});
if ($state ne 'INIT') {
    redirect("/");
}

getcgihash(\%par, {'wantfile' => 1, 'filevar' => 'IMPORT_FILE'});

import_archive_local() if ($par{'ACTION'} eq 'import');

sub printout_agb {
    setFlavour('setup');
    &showhttpheaders();
    &openpage(_('Change passwords'), 1, '',$nomenu=1);
    &openbigbox($errormessage, $warnmessage, $notemessage);
    &openbox('100%', 'center',_('Welcome to %s', $brand.' '.$product));

    my $license = get_eula();

printf <<EOF
<h2>%s</h2>
<br>
<form enctype='multipart/form-data'  method='post' action='$ENV{'SCRIPT_NAME'}'>
  <p>
    <textarea name="License" cols="75" rows="20" readonly>$license</textarea><br><br><br>
    <input type="checkbox" name="accept" value="accept">%s<br>
  </p>
<br><br><br>
  <input class='submitbutton' type="submit" name="next" value=">>>">
  <input type="hidden" name="step" value="3">
</form>
EOF
, _('Welcome to %s', $brand.' '.$product)
, _('ACCEPT License')
;

    &closebigbox();
    &closebox();
}

#####

sub printout_language_selection {
    setFlavour('setup');
    &showhttpheaders();
    &openpage(_('Please select your language'), 1, '',$nomenu=1);
    &openbigbox($errormessage, $warnmessage, $notemessage);
    &openbox('100%', 'center',_('Welcome to %s', $brand.' '.$product));

    my ($languages, $languages_sorted) = load_languages();

printf <<EOF
<h2>%s</h2>
<br><br>
<form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}'>
<table width='55%' columns="2" >
  <tr>
      <td width='40%' valign="middle" >%s:</td>
      <td valign="middle">
        <select name="language" size="1">
EOF
, _('Welcome to %s', $brand.' '.$product)
, _('Please select your language')
;

    my $id=0;
    foreach my $lang (sort keys %$languages_sorted)
    {
        $id++;
	my $item = $languages_sorted->{$lang};
	my $engname = $item->{'GENERIC'};
	my $natname = $item->{'ORIGINAL'};

	print "<option value='$item->{'ISO'}' ";
	if ($item->{'ISO'} =~ /$settings{'LANGUAGE'}/)
	{
	    print " selected='selected'";
	}
	printf <<END
>$engname ($natname)</option>
END
;
    }


printf <<EOF
        </select>
      </td>
  </tr>
  <tr>
      <td width='25%' valign="middle">%s:</td>
      <td valign="middle">
        <select name='TIMEZONE'>
EOF
, _('Timezone')
;

    use DateTime::TimeZone;
    foreach my $zone (DateTime::TimeZone::all_names) {
        my $checked = '';
        if ($timeconf->{'TIMEZONE'} eq $zone) {
            $checked = 'selected';
        }
        print "<option value='$zone' $checked>$zone</option>";
    }

printf <<EOF
          </select>
        </td>
  </tr>
  <tr><td></td></tr>
  <tr><td></td></tr>
  <tr>
    <td width='25%'></td>
    <td>
      <input class='submitbutton' type="submit" name="next" value=">>>">
      <input type="hidden" name="step" value="2">
    </td>
  </tr>
</table>
</form>

EOF
;

    &closebigbox();
    &closebox();
}
##

if ($par{'step'} eq '5' && !defined($par{'CANCEL'})) {
	foreach my $regfile (glob("/razwall/web/cgi-bin/passwordDialogue-*.pl")) {
	    require $regfile;
	}
	callPasswordSaves();
	
    if ($errormessage) {
        $par{'step'} = 4;
    }
}


if ($par{'step'} == 0) {
    setFlavour('setup');
    &showhttpheaders();
    &openpage(_('Initial wizard'), 1, '',$nomenu=1);
    &openbigbox($errormessage, $warnmessage, $notemessage);
    &openbox('100%', 'center',_('Welcome to %s', $brand.' '.$product));

printf <<EOF
<h2>%s</h2>
<br><br>
%s
<br><br>
%s
<br><br><br>
<form enctype='multipart/form-data' action="" method="post">
  <input class='submitbutton' type="submit" name="next" value=">>>">
  <input type="hidden" name="step" value="1">
</form>
EOF
, _('Welcome to %s', $brand.' '.$product)
, _('Thank you for choosing %s', $brand.' '.$product)
, _('Please follow the next step to complete the installation.')
;

   &closebigbox();
   &closebox();
} elsif ($par{'step'} == 1) {
    loadconfig();	
    printout_language_selection();
} elsif ($par{'step'} == 2) {
    # read/write language
    &readhash("${swroot}/main/settings", \%settings);
    $redirect = 0;
    if(!($settings{'LANGUAGE'} eq $par{'language'})){
       $redirect = 1;
    }
    $settings{'LANGUAGE'}=$par{'language'};
    $settings{'TIMEZONE'}=$par{'TIMEZONE'};
    &writehash("${swroot}/main/settings", \%settings);
    
    if($redirect != 0){
	expireMenuCache();
	system("sudo /etc/init.d/emi reload &>/dev/null");	
    }

    gettext_init($par{'language'}, "efw");
    gettext_init($par{'language'}, "efw.enterprise");
    gettext_init($par{'language'}, "efw.vendor");
    
    loadconfig();	
    $timeconf{'TIMEZONE'}=$par{'TIMEZONE'};
    &writehash("${swroot}/time/settings", \%timeconf);

    printout_agb();

} elsif ($par{'step'} == 3) {
    if (!($par{'accept'})) {	# EULA not accepted
        $errormessage=_('EULA not accepted');
        printout_agb();
        exit;
    }
    
    # my $agent = LWP::UserAgent->new();
    # my $reqest = HTTP::Request->new(GET => 'http://localhost:3131/manage/commands/commands.license.acceptlicense');
    # $reqest->header('Accept' => 'text/html');
    # # send request
    # my $response = $agent->request($reqest);
    
    system("sudo /usr/local/bin/accept_license &>/dev/null");

setFlavour('setup');
&showhttpheaders();
&openpage(_('Restore a backup'),1,'',$nomenu=1);
&openbigbox($errormessage,$warnmessage,$notemessage);
&openbox('100%', 'center',_('Import backup'));

         printf <<EOF   

        <form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}'>
        <br><br>
          <p>
            %s&nbsp;&nbsp;&nbsp;&nbsp;
            <select name="restorebackup" size="1">
              <option value=no>%s</option>
              <option value=yes>%s</option>
            </select>

          </p>
        <br><br><br>
          <input type="submit" name="cancel" value="%s">&nbsp;&nbsp;&nbsp;&nbsp;
          <input type="submit" name="next" value="%s">
          <input type="hidden" name="step" value="4">
        </form>
EOF
                                                                                            
            ,_('Do you want to restore a backup?'),
            _('No'),
            _('Yes'),
            _('Cancel'),
            _('>>>')
;            
&closebox();            
&closebigbox();

} elsif ($par{'step'} == 4) {
   if($par{'restorebackup'} eq 'no' or (! $par{'restorebackup'} and ! $par{'IMPORT_FILE'})) 
   {
        setFlavour('setup');
        &showhttpheaders();
        &openpage(_('Change passwords'), 1, '',$nomenu=1);
        &openbigbox($errormessage, $warnmessage, $notemessage);

        &openbox('100%', 'center', _('change default password'));


printf <<EOF
    <form enctype='multipart/form-data' method='post' action='$ENV{'SCRIPT_NAME'}'>
    <br class="cb" />
    <table>
    <tr><td align="center">
    <div class="efw-form">
EOF
;
	foreach my $regfile (glob("/razwall/web/cgi-bin/passwordDialogue-*.pl")) {
	    require $regfile;
	}

       displayUserPasswordDialogue("admin", 1);
       displayUserPasswordDialogue("root", 1);

printf <<EOF

            <br class="cb" />
            <br class="cb" />
            <input type='submit' name='CANCEL' value='%s' />&nbsp;&nbsp;&nbsp;&nbsp;
            <input class='submitbutton' type='submit' name='ACTION' value='>>>' />
        </div>
    </td></tr>
    </table>
            <input type='hidden' name='step' value='5'>
        </form>
EOF
, _('Cancel')
;

        &closebox();
        &closebigbox();
        } else {
        setFlavour('setup');
        &showhttpheaders();
        &openpage(_('Restore a backup'),1,'',$nomenu=1);
        &openbigbox($errormessage,$warnmessage,$notemessage);

        # import
        openbox('100%', 'left', _('Import backup archive'));

printf <<END
          <form method='post' action='$ENV{'SCRIPT_NAME'}' enctype='multipart/form-data'>
          <input type='hidden' name='ACTION' value='import' />
          <table cols="3">
            <tr>
              <td>%s:</td>
              <td><input type='file' name='IMPORT_FILE' size='40' /></td>
              <td><input class='submitbutton' type='submit' name='submit' value='%s' /></td>
            </tr>
END
, _('File')
, _('Import and restore')
;

if ( $enterprise ) {
printf <<END
            <tr>
              <td>%s %s:</td>
              <td><input type='checkbox' name='DELETE_REGISTRATION' checked='checked' /></td>
              <td></td>
            </tr>
END
, _('Exclude')
, _('%s registration', $network_name),
;
}

printf <<END    
          </table>
          <input type='hidden' name='REMARK' value='imported_backup' />
          <input type='hidden' name='step' value='4'>
          </form>
END
; 
        &closebox();
        &closebigbox();
}


} else {
    my $next = uc($wizardhash{"WIZARD_NEXT_$state"});
    $wizardhash{'WIZARD_STATE'} = $next;
    writehash($wizardconffile, \%wizardhash);
    system('rm /etc/httpd/conf.d/setup-step1.conf >/dev/null 2>&1');
    redirect("/");
}


&closepage($nostatus=1);
