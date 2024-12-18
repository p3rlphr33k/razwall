#!/usr/bin/perl

require 'header.pl';

&showhttpheaders();

my $title = _("The %s Management Interface encountered an error.", $brand);
my $refresh = "";
&openpage($title, 0, $refresh);
&openbigbox($errormessage, $warnmessage, $notemessage);
printf <<END
<div align='center'>
    <table width='100%' bgcolor='#ffffff'>
        <tr>
            <td align='center'>
                <br />
                <br />
                <img src='/images/error_splash.png' /><br /><br /><br />
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
_("Please contact an administrator.");
;
&closebigbox();
&closepage();
