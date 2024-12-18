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

require 'smtpscan.pl';

my (%cgiparams);
my $filename = "${swroot}/smtpscan/domains";

$cgiparams{'ACTION'} = '';

&getcgihash(\%cgiparams);

&showhttpheaders();

(my $default_conf_ref, my $conf_ref) = reload_par();
my %default_conf = %$default_conf_ref;
my %conf = %$conf_ref;

open(FILE, $filename) or die 'Unable to open config file.';
my @current = <FILE>;
close(FILE);

&readhash("${swroot}/main/settings", \%settings);


if ($ENV{'QUERY_STRING'} =~ /DOMAIN|SERVER/ ) {
  my $newsort=$ENV{'QUERY_STRING'};
  $act=$settings{'SORT_HOSTSLIST'};
  #Reverse actual ?
  if ($act =~ $newsort) {
    if ($act !~ 'Rev') {$Rev='Rev'};
    $newsort.=$Rev
  };
  
  $settings{'SORT_HOSTSLIST'}=$newsort;
  &writehash("${swroot}/main/settings", \%settings);
  
  #Need to sort the file...
  &sortcurrent;
}

if ($cgiparams{'ACTION'} eq 'add')
{
  if ( (! $errormessage) && ($cgiparams{'DOMAIN'}) && ($cgiparams{'SERVER'}))
  {
    if ($cgiparams{'KEY1'} eq '') #Add or Edit ?
    {
      unshift (@current, "$cgiparams{'DOMAIN'},$cgiparams{'SERVER'}\n");
      &log(_('Domain was successfully added.'));
      undef (%cgiparams); # End add mode and clear fields.
      system("touch $proxyrestart");
    } else {
      @current[$cgiparams{'KEY1'}] = "$cgiparams{'DOMAIN'},$cgiparams{'SERVER'}\n";
      &log(_('Domain was successfully changed.'));
      undef (%cgiparams); # End edit mode and clear fields.
      system("touch $proxyrestart");
    }
		
    #Sort here the file. So that resorting is much less time consuming next time.
    &sortcurrent;
  } 
}
elsif ($cgiparams{'ACTION'} eq 'edit')
{
  my @temp = split(/\,/,@current[$cgiparams{'KEY1'}]);
  $cgiparams{'DOMAIN'} = $temp[0];
  $cgiparams{'SERVER'} = $temp[1];
}
elsif ($cgiparams{'ACTION'} eq 'remove')
{
  open(FILE, ">$filename") or die 'Unable to open config file.';
  splice (@current,$cgiparams{'KEY1'},1);
  print FILE @current;
  close(FILE);
  undef ($cgiparams{'KEY1'});  # End remove mode
  &log(_('Domain was successfully changed.'));
  system("touch $proxyrestart");
}
elsif ($cgiparams{'ACTION'} eq 'apply') {
    &log(_('Apply proxy settings'));
    applyaction();
}


&openpage(_('SMTP Proxy'), 1, $notification_script);

showapplybox(\%conf);

openbigbox($errormessage, $warnmessage, $notemessage);

my $buttontext = _('Add');
if ($cgiparams{'KEY1'} ne '') {
  $buttontext = _('Update');
}

my $show = "";
if($cgiparams{'ACTION'} eq 'add' || $cgiparams{'ACTION'} eq 'edit') {
    $show = "showeditor";
}

my $button = ($cgiparams{'ACTION'} eq 'edit') ? _("Update domain") : _("Add domain");
openeditorbox(_("Add a domain"), $title, $show, "createrule", @errormessages);

printf <<END
<input type='hidden' name='ACTION' value='add' >
<table width='100%'>
<tr>
<td width='25%' class='base'>%s:&nbsp;</td>
<td width='25%' ><input type='text' name='DOMAIN' value='$cgiparams{'DOMAIN'}' size='25' tabindex='1' ></td>
</tr>
<tr>
<td width='25%' class='base'>%s:&nbsp;</td>
<td width='25%'><input type='text' name='SERVER' value='$cgiparams{'SERVER'}' size='25' tabindex='2' ></td>
</tr>
<input type='hidden' name='KEY1' value='$cgiparams{'KEY1'}' >
</table>
END
,
_('Domain'),
_('Mailserver IP'),
;

&closeeditorbox($buttontext, _("Cancel"), "routebutton", "createrule", $ENV{'SCRIPT_NAME'});

printf <<END
<div align='center'>
<table class="ruleslist" width='100%' cellpadding="0" cellspacing="0">
<tr>
<th align='center'><a href='$ENV{'SCRIPT_NAME'}?DOMAIN'><b>%s</b></a></td>
<th align='center'><a href='$ENV{'SCRIPT_NAME'}?SERVER'><b>%s</b></a></td>
<th colspan="2" width='10%'>%s</th>
</tr>
END
,
_('Domain'),
_('Mailserver'),
_("Actions")
;

my $key = 0;
foreach my $line (@current)
{
  chomp($line);
  my @temp = split(/\,/,$line);

  if ($cgiparams{'KEY1'} eq $key) 
  {
    print "<tr class='selected'>\n";
  } elsif ($key % 2) 
  {
    print "<tr class='even'>\n";
  } else 
  {
    print "<tr class='odd'>\n";
  }
  print "<td align='center'>$temp[0]</td>\n";
  print "<td align='center'>$temp[1]</td>\n";
  printf <<END
<td align='center'>
<form method='post' action='$ENV{'SCRIPT_NAME'}'>
<input type='hidden' name='ACTION' value='edit' >
<input class='imagebutton' type='image' name='submit' src='/images/edit.png' alt='%s' title='%s' >
<input type='hidden' name='KEY1' value='$key' >
</form>
</td>

<td align='center'>
<form method='post' action='$ENV{'SCRIPT_NAME'}'>
<input type='hidden' name='ACTION' value='remove' >
<input class='imagebutton' type='image' name='submit' src='/images/delete.png' alt='%s' title='%s' >
<input type='hidden' name='KEY1' value='$key' >
</form>
</td>


END
,
_('Edit'),
_('Edit'),
_('Remove'),
_('Remove')
;
  print "</tr>\n";
  $key++;
}
print "</table>";
print "</div>\n";

# If the file contains entries, print Key to action icons
if ( $key > 0) 
{
  printf <<END
<table>
<tr>
<td class='boldbase'>&nbsp; <b>%s:</b></td>
<td>&nbsp; &nbsp; <img src='/images/edit.png' alt='%s' ></td>
<td class='base'>%s</td>
<td>&nbsp; &nbsp; <img src='/images/delete.png' alt='%s' ></td>
<td class='base'>%s</td>
</tr>
</table>
END
,
_('Legend'),
_('Edit'),
_('Edit'),
_('Remove'),
_('Remove')
;
}

&closebigbox();
&closepage();

# Sort function
sub bymysort {
  if (rindex ($settings{'SORT_HOSTSLIST'},'Rev') != -1)
  {
    $qs=substr ($settings{'SORT_HOSTSLIST'},0,length($settings{'SORT_HOSTSLIST'})-3);
    if ($qs eq 'DOMAIN') {  
      @a = split(/\./,$entries{$a}->{DOMAIN});
      @b = split(/\./,$entries{$b}->{DOMAIN});
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
    $qs=$settings{'SORT_HOSTSLIST'};
    if ($qs eq 'SERVER') {
      @a = split(/\./,$entries{$a}->{SERVER});
      @b = split(/\./,$entries{$b}->{SERVER});
      ($a[0]<=>$b[0]) ||
      ($a[1]<=>$b[1]) ||
      ($a[2]<=>$b[2]) ||
      ($a[3]<=>$b[3]);
    }else {
      $entries{$a}->{$qs} cmp $entries{$b}->{$qs};
    }
  }
}

# Sort the "current" array according to choices
sub sortcurrent
{
  #Use an associative array (%entries)
  my $key = 0;
  foreach my $line (@current)
  {
    $line =~ /(.*),(.*)/;
    @record = ('name',$key++,'DOMAIN',$1,'SERVER',$2);
    $record = {};                        # create a reference to empty hash
    %{$record} = @record;                # populate that hash with @record
    $entries{$record->{name}} = $record; # add this to a hash of hashes
  }
  open(FILE, ">$filename") or die 'Unable to open config file.';
  foreach my $entry (sort bymysort keys %entries) 
  {
    print FILE "$entries{$entry}->{DOMAIN},$entries{$entry}->{SERVER}\n";
  }
  close(FILE);

  # Reload sorted  @current
  open (FILE, "$filename");
  @current = <FILE>;
  close (FILE);
}
