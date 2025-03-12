#!/usr/bin/perl

require 'header.pl';

&showhttpheaders();

my $title = _("The Page you requested does not exist.");
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
                <img src='/images/notfound_splash.png' /><br /><br /><br />
            </td>
        </tr>
    </table>
    <br />
    <font size='4'>
        %s
        <br />
        <br />
    </font>
</div>
END
,
$title,
;
&closebigbox();
&closepage();
