#!/usr/bin/perl
#
# Register CGI for Endian Firewall
#
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

my $efw_url = "http://www.endian.com/it/community/register/";

my $wizardconffile = '/var/efw/wizard/settings';
my $mainconffile = '/var/efw/main/settings';

my %wizardhash;
readhash($wizardconffile, \%wizardhash);

my $versionconffile = '/var/efw/version/settings';
my %versionhash;
readhash($versionconffile, \%versionhash);

my %par;

my $EN_CLIENT='/usr/bin/en-client';

my %mainsettings=();
&readhash($mainconffile, \%mainsettings);

my %errhash;

if ($0 =~ /step3\/efw-register.cgi/) {
    $pagename =  "firstregister";
    $nomenu = 1;
    setFlavour('setup');
    $nostatus = 1;
} else {
    undef $pagename;
    undef $nomenu;
    undef $nostatus;
}


# already done this step ?
my $state = uc($wizardhash{'WIZARD_STATE'});
# is this step the current step ?
if (
    ($pagename eq "firstregister") and
    ($state ne 'REGISTER')
    ) {
    redirect("/");
}

sub clean_dot($) {
    my $data = shift;
    chomp($data);

    $data =~ s/\n\././m;
    return $data;
}

sub redirect($) {
    $page=shift;
    print "Status: 302 Moved\n";
    print "Location: https://$ENV{'SERVER_ADDR'}:10443${page}\n\n";
    exit;
}



sub save() {

    my $email = cleanhtml(clean_dot($par{'email'}));
    
    if(($email eq '')) {
         return (1, _('Email must not be empty'));
    }

    use strict;
    use warnings;
    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->credentials('updates.endian.org:80', 'Endian Community Repository', $email, 'community');

    my $resp = $ua->get('http://updates.endian.org/'.$versionhash{'MAJOR_VERSION'}.'/');
    my $error_message = "";
    if ($resp->is_error) {
        if ($resp->code == 401) {
            $errhash{'email'} = _('The email address you provided has not been registered yet. Please <a href="%s" target="_blank">create a new account here</a>', $efw_url);
        }
        elsif ($resp->code == 500) {
            $error_message = _('Can\'t connect to remote server! Check your connection');
        }
        else {
            $error_message = _("Registration failure! %s", $resp->status_line);
        }
        return (1, $error_message);
    }

    # if no error occured
    $mainsettings{'COMMUNITY_USERNAME'} = $email;
    writehash($mainconffile, \%mainsettings);
    return 0;
}

sub display_data($) {
    use POSIX qw(ceil floor);

    my $cfg = shift;

    &openbox('100%', 'left', _('Endian Firewall Community Updates'));

    print <<EOF
    <table>
EOF
;
    if($mainsettings{'COMMUNITY_USERNAME'} ne '') {
        printf <<EOF
        <tr>
            <td valign="top"><p>%s</p></td>
        </tr>
        <tr>
            <td>%s: <b>$mainsettings{'COMMUNITY_USERNAME'}</b></td>
        </tr>
        <tr>
            <td>&nbsp;</td>
        </tr>
        <tr>
            <td>%s:<br><b>efw-upgrade</b></td>
        </tr>
EOF
,
_("Updates on this system have been activated successfully."),
_("This system has been registered by"),
_("In order to update your system connect over SSH and run the following command"),
;
    }
    print <<EOF
        </table>
<br><br><br>
EOF
;

   if (($0 =~ /step3\/efw-register.cgi/)) {
        printf <<EOF
<form method='post' action='/'>
<center>
    <input type="submit" name="finish" value="%s" />
</center>
</form>
EOF
,
_('Finish')
;
    }

    &closebox();
}


sub in_array {
    my $needle = shift;
    my $array = shift;
    my @haystack = @$array;
    
    foreach(@haystack) {
        if($_ eq $needle) { return 1 };
    }
    return 0;
}

sub error_msg {
    my $text = shift;
    
    return "<label class=\"error-msg\">$text</label>";
    #return "error"
}

sub display_register {
    &openbox('100%', 'left', _('Endian Firewall Community Registration'));

    printf <<EOF
    <style type="text/css">
        .form-field, .multi-form-field { float:left; padding-right: 4px; }
        .form-field input, .form-field select, .multi-form-field input, .multi-form-field select { display: block; margin: 0px; margin-top: 4px; }
        .form-field input, .form-field select { width: 300px; }
        .multi-form-field input, .multi-form-field select { width: 180px; }
        input.checkbox { margin: 0px; margin-top: 4px; padding: 0px; }
        label { font-weight: bold; }
        .form-section-title { font-size: 12px; font-weight: normal; padding: 0px; margin: 0px; padding-top: 8px; padding-bottom: 4px; }
        .form-section-title.first { padding-top: 0px; }
        label.error-msg { font-weight: normal; padding-top: 3px; color: red; font-size: 10px; display: block; clear: both; }
        .form-field.error, .multi-form-field.error, b.error { color: red; }
        p.error-msg { color: red; }
    </style>
    
<form action="" method="post">
    <table id="efw-register" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td valign="top" class="title" colspan="2"><p class="form-section-title first">%s</p></td>
        </tr>
        <tr>
            <td class="divider"><img src="/images/clear.gif" width="1" height="1" alt="" border="0" /></td>
        </tr>
        <tr>
            <td valign="top" colspan="2"><p>%s</p></td>
        </tr>
        <tr>
            <td valign="top" colspan="2"><p %s>%s</p></td>
        </tr>
        <tr>
            <td valign="bottom" width="300px">
                <span class="form-field">
                <input type="text" value="$par{'email'}" name="email"/></span>
            </td>
            <td valign="bottom">
                <input type='submit' name='action' value='%s' />
            </td>
        </tr>
EOF
,_('Register your Endian Firewall Community to get Free Updates'),
,_('By registering to Endian Firewall Community updates you get access to the latest features and bug fixes for free.'),
exists $errhash{'email'} ? 'class="error-msg"' : '',
exists $errhash{'email'} ? error_msg($errhash{'email'}) : _('Please enter the email address you used to subscribe or <a href="%s" target="_blank">create a new account here</a>', $efw_url),
_('Register'),
;


print <<EOF
    <tr>
        <td align="left">
EOF
;

  if ($pagename eq "firstregister") {
      printf "<p>%s</p>"
      ,
      _('<a href=%s>I don’t want any updates</a>', '/cgi-bin/main.cgi')
      ;
  }

  printf <<EOF
     </tr>
  </table>
</form>
EOF
;
    &closebox();

    for (keys %errhash)
    {
        delete $errhash{$_};
    }
}

sub get_data() {
    use IPC::Open3;
    my %confighash;
    my $conf = \%confighash;
    readhash($mainconffile, $conf);
    # Check if the system is registered.
    if ($conf->{'COMMUNITY_USERNAME'} ne "") {
        return (1, $conf)
    }
    return (0,0) if (! $conf);
    return (0, $conf);
}

sub display {
    my $have_data = shift;
    my $data = shift;
    if (! $have_data) {
            display_register();
        return;
    }
    if ($state eq 'REGISTER') {
        my $next = uc($wizardhash{"WIZARD_NEXT_$state"});
        $wizardhash{'WIZARD_STATE'} = $next;
        writehash($wizardconffile, \%wizardhash);
    }
    display_data($data);
}

sub action($) {
    my $have_data = shift;
    if ($have_data) {
        return 0;
    }

    if (defined($par{'action'})) {
        return save();
    }
    #return 0;
}

&getcgihash(\%par);

# cancel pressed
if (defined($par{'cancel'})) {
    redirect("/cgi-bin/main.cgi");
} elsif (defined($par{'back'})) {
    redirect("/");
} elsif (defined($par{'finish'}) && lc($state) eq 'register') {
    my $next = uc($wizardhash{"WIZARD_NEXT_$state"});
    $wizardhash{'WIZARD_STATE'} = $next;
    writehash($wizardconffile, \%wizardhash);
    redirect("/");
} 

&showhttpheaders();
&openpage(_('Register your Endian Firewall Community'), 1, '',$nomenu=$nomenu);

my ($have_data, $data) = get_data();
my ($error, $errormessage) = action($have_data);
if(! $error) {
   ($have_data, $data) = get_data();
}
&openbigbox($errormessage, $warnmessage, $notemessage);
display($have_data, $data);
&closebigbox();
&closepage($nostatus=$nostatus);



