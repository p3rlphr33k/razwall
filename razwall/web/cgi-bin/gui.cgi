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

my $demo = $demo_settings->{'DEMO_ENABLED'} eq 'on';

# -------------------------------------------------------------------

my %languages_hash = ();
my $languages = \%languages_hash;
my $i18n = '/usr/lib/efw/i18n/';
my $productconffile = '/var/efw/product/settings';

my $enterprise = is_enterprise();

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

my $restarthotspot = '/usr/local/bin/restarthotspot';

my (%cgiparams, %mainsettings, %checked);
$cgiparams{'WINDOWWITHHOSTNAME'} = 'off';

&getcgihash(\%cgiparams);

&readhash("${swroot}/main/settings",\%mainsettings);

my ($languages, $languages_sorted) = load_languages();

if ($cgiparams{'ACTION'} eq 'save')
{
        if ( $languages->{$cgiparams{'lang'}} )
        {
            if (!$demo) {
                $mainsettings{'LANGUAGE'} = $cgiparams{'lang'};
            }
        }

        # write cgi vars to the file.
        $mainsettings{'WINDOWWITHHOSTNAME'} = $cgiparams{'WINDOWWITHHOSTNAME'};
        &writehash("${swroot}/main/settings", \%mainsettings);
        system("jobcontrol call emi.expire_menu_cache &>/dev/null");
        system("jobcontrol call emi.reload &>/dev/null");

        print "Status: 302 Moved\nLocation: /cgi-bin/gui.cgi\n\n";

} else {

        if ($mainsettings{'WINDOWWITHHOSTNAME'}) {
                $cgiparams{'WINDOWWITHHOSTNAME'} = $mainsettings{'WINDOWWITHHOSTNAME'};
        } else {
                $cgiparams{'WINDOWWITHHOSTNAME'} = 'off';
        }
}

$checked{'WINDOWWITHHOSTNAME'}{'off'} = '';
$checked{'WINDOWWITHHOSTNAME'}{'on'} = '';
$checked{'WINDOWWITHHOSTNAME'}{$cgiparams{'WINDOWWITHHOSTNAME'}} = "checked='checked'";


gettext_init($mainsettings{'LANGUAGE'}, "efw");

&showhttpheaders();

&openpage(_('GUI settings'), 1, '');

&openbigbox($errormessage, $warnmessage, $notemessage);

&openbox('100%','left',_('Settings'));
printf <<END
<form method='post' action='$ENV{'SCRIPT_NAME'}'>
    <input type='hidden' name='ACTION' value='save' />
    <table cellpadding="0" cellspacing="0"><tr><td>
    <div class="efw-form">
        <div class="section">
            <div class="title"><h2 class="title">%s</h2></div>
            <div class="fields-row">
                <span class="multi-field">
                    <label id="username_field" for="username">%s *</label>
                    <select name='lang' %s>
END
, _("Settings"),
_("Select your language"),
$demo ? "disabled='disabled'" : ""
;

my $id=0;
foreach my $lang (sort keys %$languages_sorted)
{
        $id++;
        my $item = $languages_sorted->{$lang};
        my $engname = $item->{'GENERIC'};
        my $natname = $item->{'ORIGINAL'};

        print "<option value='$item->{'ISO'}' ";
        if ($item->{'ISO'} =~ /$mainsettings{'LANGUAGE'}/)
        {
                print " selected='selected'";
        }
        printf <<END
>$engname ($natname)</option>
END
        ;
}

printf <<END
                    </select></span>
                <br class="cb" />
            </div>
            <div class="fields-row">
                <span class="multi-field checkbox">
                    <input type="checkbox" name="WINDOWWITHHOSTNAME" $checked{'WINDOWWITHHOSTNAME'}{'on'} />
                    <label id="username_field" for="username">%s *</label></span>
                <br class="cb" />
            </div>
        </div>
        <div class="save-button">
            <input class='submitbutton save-button' type='submit' name='submit' value='%s' /></div>
END
, _('Display hostname in window title')
, _("Save Changes")
;

if (! $enterprise and ! is_branded()) {
    printf <<END
        <div class="fields-row">
          <br class="cb" />
          <br class="cb" />
          <a href="https://launchpad.net/products/efw/trunk/+translations" target="_new">%s</a>
        </div>
END
, _('Help translating this project')
;
}

printf <<END
    </div>
    </td></tr></table>
</form>
END
;

&closebox();
&closebigbox();
&closepage();
exit;
