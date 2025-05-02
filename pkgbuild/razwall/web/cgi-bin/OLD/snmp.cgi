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

my (%settings, %checked);
my $conffile         = "${swroot}/snmp/settings";
my $name             = _('SNMP');

&showhttpheaders();
$errormessage = '';
&getcgihash(\%settings);

if ($settings{'ACTION'} eq 'save')
{
    &writehash($conffile, \%settings);
	if ($settings{'ENABLED'} eq 'on') {
		&log(_('SNMP server is enabled.  Restarting.'));
    } else {
		&log(_('SNMP server is disabled.  Stopping.'));
	}

	# delete $settings{'__CGI__'};
	if ($settings{'SNMP_OVERRIDE'} eq 'on' && !validemail($settings{'SNMP_CONTACT_EMAIL'})) {
		$errormessage = _('Invalid email address.');
	}
    
	if ($errormessage eq '') {
    	system('/usr/local/bin/restartsnmp --force >/dev/null 2>&1') == 0
    		or $errormessage = _('Helper program returned error code')." " . $?/256;
    }
}


&readhash( "$conffile", \%settings );

&openpage(_('SNMP'), 1, '<script type="text/javascript" src="/include/serviceswitch.js"></script>');
&openbigbox($errormessage, $warnmessage, $notemessage);
if($errormessage or $warnmessage or $notemessage) {
    &closebigbox();
    &closepage();
    exit (0);
} 
&openbox('100%', 'left', _("Settings"));

$service_status = $settings{'ENABLED'};
printf <<END
<script type="text/javascript">
    \$(document).ready(function() {
        var SERVICE_STAT_DESCRIPTION = {'on' : '%s', 'off' : '%s', 'restart' : '%s'};
        var sswitch = new ServiceSwitch('/cgi-bin/snmp.cgi', SERVICE_STAT_DESCRIPTION);
    });
    function emailActivation () {
    	if (\$('#emailC').get()[0].checked)
    		\$('#emailF').get()[0].disabled = false;
    	else
    		\$('#emailF').get()[0].disabled = 'disabled';
    }
</script>

<div id="validation-error" class="error-fancy" style="width: 504px; display:none">
        <div class="content">
            <table cellpadding="0" cellspacing="0" border="0">
                <tr>
                    <td class="sign" valign="middle"><img src="/images/bubble_red_sign.png" alt="" border="0" /></td>
                    <td id="validation-error-text" class="text" valign="middle"></td>
                </tr>
            </table>
        </div>
        <div class="bottom"><img src="/images/clear.gif" width="1" height="1" alt="" border="0" /></div>
</div>

<form enctype='multipart/form-data' class="service-switch-form" id="snmp-form" method='post' action='$ENV{'SCRIPT_NAME'}'>
<input type="hidden" class="service-status" name="ENABLED" value="$service_status" />

<table cellpadding="0" cellspacing="0" border="0">
    <tr>
        <td valign="top">
            <div id="access-policy" class="service-switch">
                <div><span class="title">%s</span>
                    <span class="image"><img class="$service_status" align="absbottom" src="/images/switch-%s.png" alt="" border="0"/></span>
                </div>
                <div class="content">
                    <div id="access-description" class="description" %s>%s</div>
                    <div id="access-policy-hold" class="spinner working">%s</div>
                    <div id="access-options" class="options-container" %s>
                        <div class="options">
                            <table border='0' cellspacing="0" cellpadding="4">
                            <tr>
                                <td>%s:</td>
                                <td><input type='text' class="text" name='SNMP_COMMUNITY_STRING' value='$settings{'SNMP_COMMUNITY_STRING'}' /></td>
                            </tr>
                            <tr>
                                <td>%s:</td>
                                <td><input type='text' class="text" name='SNMP_LOCATION' value='$settings{'SNMP_LOCATION'}' /></td>
                            </tr>    
                            <tr>
                                <td>%s:</td>
                                <td><input id='emailC' type='checkbox' class="text" name='SNMP_OVERRIDE' %s onclick='emailActivation();' /></td>
                            </tr>    
                            <tr>
                                <td>%s:</td>
                                <td><input id='emailF' type='text' class="text" name='SNMP_CONTACT_EMAIL' value='$settings{'SNMP_CONTACT_EMAIL'}' %s /></td>
                            </tr>    
                            </table>
                        </div>
                        <div class="save-button">
                            <input class='submitbutton save-button' type='submit' name='submit' value='%s' /></div>
                        </div>
                    </div>
                </div>
            </div>
        </td>
    </tr>
</table>
    <input type='hidden' name='ACTION' value='save' />
</form>
END
, escape_quotes(_("The SNMP server configuration is being applied. Please hold...")),
escape_quotes(_("The SNMP server is being shutdown. Please hold...")),
escape_quotes(_("Settings are saved and the SNMP server is being restarted. Please hold...")),
_('Enable SNMP Server'),
$settings{'ENABLED'} eq 'on' ? 'on' : 'off',
$settings{'ENABLED'} eq 'on' ? 'style="display:none"' : '',
 _("Use the switch above to enable the SNMP server."),
'',
 $settings{'ENABLED'} eq 'off' ? 'style="display:none"' : '',
_('Community String'),
_('Location'),
_('Override global notification email address'),
$settings{'SNMP_OVERRIDE'} eq 'on' ? "checked='checked'" : '',
_('System contact email address'),
$settings{'SNMP_OVERRIDE'} eq 'on' ? '' : "disabled='disabled'",
_('Save'),
;

&closebox();
print "</form>\n";
&closebigbox();
&closepage();

