#!/usr/bin/perl
#use strict;
#use warnings;
use lib './';
use SimpleCurses;

=pod
Color	Foreground	Background
Black	\e[30m	\e[40m
Red	\e[31m	\e[41m
Green	\e[32m	\e[42m
Yellow	\e[33m	\e[43m
Blue	\e[34m	\e[44m
Magenta	\e[35m	\e[45m
Cyan	\e[36m	\e[46m
White	\e[37m	\e[47m
Default Terminal	\e[39m	\e[49m
=cut

# Function to get terminal size
sub get_terminal_size {
    my ($cols, $rows) = (0, 0);
    eval {
        ($rows, $cols) = split / /, `stty size`;
    };
    return ($cols || 80, $rows || 24);
}

sub get_key(){
print "You pressed: " . @_;
}

# Initialize screen
my $screen = SimpleCurses->new();
$screen->init_screen();

# Get terminal size
my ($width, $height) = get_terminal_size();

# Calculate positions and sizes as percentages
my $left_width  = int($width * 0.5);   # 50% of terminal width
my $right_width = $width - $left_width;
my $menu_height = $height - 2;        # Leave space for borders

# Draw main window border
$screen->draw_box(1, 1, $width, $height);

# Draw left column (Menu)
$screen->draw_box(1, 1, $left_width, $height);

# Draw right column (System Info)
$screen->draw_box($left_width + 1, 1, $right_width, $height);

# Set up colors (ANSI escape codes)
my $menu_color = "\e[40m"; # Black background
my $info_color = "\e[42m"; # Green background
my $text_color = "\e[97m"; # White text
my $reset_color = "\e[0m";

# Fill the left column (Menu)
for my $line (2 .. $menu_height) {
    print "\e[${line};2H$menu_color" . (' ' x ($left_width - 2)) . "$reset_color";
}

# Fill the right column (System Info)
for my $line (2 .. $menu_height) {
    my $start_col = $left_width + 2;
    print "\e[${line};${start_col}H$info_color" . (' ' x ($right_width - 2)) . "$reset_color";
}

# Write text with background color
sub write_colored_text {
    my ($x, $y, $text, $bg_color, $fg_color) = @_;
    $fg_color ||= "\e[97m"; # Default white text
    $bg_color ||= "\e[40m"; # Default black background
    print "\e[${y};${x}H$bg_color$fg_color$text$reset_color";
}

sub main_screen {
# Write menu items with a blue background
write_colored_text(10, 10, 'Menu:', $menu_color, $text_color);

write_colored_text(10, 12, '0. System shell', $mnu_color, $text_color);
write_colored_text(10, 13, '1. Reboot system', $menu_color, $text_color);
write_colored_text(10, 14, '2. Change root pasword', $menu_color, $text_color);
write_colored_text(10, 15, '3. Change admin password', $menu_color, $text_color);
write_colored_text(10, 16, '4. Restore Factory Defaults', $mnu_color, $text_color);
write_colored_text(10, 17, '5. Network Wizard', $mnu_color, $text_color);
write_colored_text(10, 18, '6. Refresh Console', $mnu_color, $text_color);

$razwall_version = '1.0.0';
$lan_ipaddress = '192.168.19.1';
$lan_httpport = '10443';
$LanUD = 'UP';
$WanUD = 'DOWN';

# Write system information with a green background
write_colored_text($left_width + 5, 10, 'System Info:', $info_color, "\e[30m");
write_colored_text($left_width + 5, 11, 'RazWall '.$razwall_version, $info_color, "\e[30m");
write_colored_text($left_width + 5, 12, 'https://'.$lan_ipaddress.':'.$lan_httpport, $info_color, "\e[30m");
write_colored_text($left_width + 5, 15, 'LAN Zone', $info_color, "\e[30m");
write_colored_text($left_width + 5, 16, 'Device eth0 ['.$LanUD.']', $info_color, "\e[30m");
write_colored_text($left_width + 5, 19, 'WAN Zone', $info_color, "\e[30m");
write_colored_text($left_width + 5, 20, 'Device eth1 ['.$WanUD.']', $info_color , "\e[30m");
}

# Wait for a key press to exit
#write_colored_text(3, $height - 1, 'Press any key to exit...', $menu_color, $text_color);
&main_screen;
my $key = $screen->get_input();
if($key == 0) {
system('clear');
exit;
}
elsif($key == 1) {
$screen->end_screen();
system('clear');
print "Going down for reboot!";
`reboot`;
exit;
}

elsif($key == 2) {
#$screen->end_screen();
system('clear');
print "Change root passwrd.\n-------------------\n";
`passwd root`;
$screen->init_screen();
&main_screen;
}
elsif($key == 3) {

}

elsif($key == 4) {
}

elsif($key == 5) {
}
elsif($key == 6) {
#$screen->end_screen();
system('clear');
&main_screen;
}
#print "$key";
# End the screen session
#$screen->end_screen();

