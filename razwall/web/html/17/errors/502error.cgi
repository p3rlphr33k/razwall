#!/usr/bin/perl

require 'header.pl';

&showhttpheaders();

my $title = _("The %s Management Interface is currently restarting...", $brand);
my $refresh = "<meta http-equiv='refresh' content='10;'/>";
&openpage($title, 0, $refresh);
&openbigbox($errormessage, $warnmessage, $notemessage);
printf <<END
<div align='center'>
    <table width='100%' bgcolor='#ffffff'>
        <tr>
            <td align='center'>
                <br />
                <br />
                <img src='/images/restart_splash.png' /><br /><br /><br />
            </td>
        </tr>
    </table>
    <br />
    <font size='4'>
        %s
        <br />
        %s
        <br />
        <br />
    </font>
</div>
END
,
$title,
_("Please wait a few moments.");
;
&closebigbox();
&closepage();
