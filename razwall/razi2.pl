#!/usr/bin/perl
use strict;
use warnings;
use SimpleCurses;

# Use ANSI escape codes for colors
my $menu_color  = "\e[40m";  # Black background
my $info_color  = "\e[42m";  # Green background
my $text_color  = "\e[97m";  # White text
my $reset_color = "\e[0m";

# Function to get terminal size
sub get_terminal_size {
    my ($cols, $rows) = (0, 0);
    eval {
        ($rows, $cols) = split / /, `stty size`;
    };
    return ($cols || 80, $rows || 24);
}

# Get IP address for a given interface (uses ifconfig as available on Slackware)
sub get_ip_address {
    my $iface = shift;
    my $ip    = 'N/A';
    my $output = `ifconfig $iface 2>/dev/null`;
    # Try to match common ifconfig patterns
    if ($output =~ /inet (?:addr:)?(\d+\.\d+\.\d+\.\d+)/) {
        $ip = $1;
    }
    return $ip;
}

# Update dynamic network info
sub update_network_info {
    # For example, using eth0 for LAN and eth1 for WAN
    my $lan_ip = get_ip_address('eth0');
    my $wan_ip = get_ip_address('eth1');
    return ($lan_ip, $wan_ip);
}

# Redraw the entire screen
sub redraw_screen {
    my ($screen, $width, $height, $lan_ip, $wan_ip) = @_;

    # Clear the screen (you may want to use curses clear method if available)
    print "\e[H\e[2J";

    # Calculate positions and sizes as percentages
    my $left_width  = int($width * 0.5);   # 50% of terminal width
    my $right_width = $width - $left_width;
    my $menu_height = $height - 2;          # Leave space for borders

    # Draw main window border and inner boxes using SimpleCurses
    $screen->draw_box(1, 1, $width, $height);
    $screen->draw_box(1, 1, $left_width, $height);
    $screen->draw_box($left_width + 1, 1, $right_width, $height);

    # Fill the left column (Menu) using ANSI escapes
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

    # Display Menu Title and Items
    write_colored_text(10, 10, 'Menu:', $menu_color, $text_color);
    my @menu_items = (
        '0. System shell',
        '1. Reboot system',
        '2. Change root password',
        '3. Change admin password',
        '4. Restore Factory Defaults',
        '5. Network Wizard'
    );
    my $menu_start_row = 12;
    for my $i (0 .. $#menu_items) {
        write_colored_text(10, $menu_start_row + $i, $menu_items[$i], $menu_color, $text_color);
    }

    # Display System Info with dynamic network info
    write_colored_text($left_width + 5, 10, 'System Info:', $info_color, "\e[30m");
    write_colored_text($left_width + 5, 11, 'RazWall 1.0.0', $info_color, "\e[30m");
    write_colored_text($left_width + 5, 12, 'https://192.168.19.17:10443', $info_color, "\e[30m");

    # LAN Zone info
    write_colored_text($left_width + 5, 15, "LAN Zone: IP $lan_ip", $info_color, "\e[30m");
    # For demonstration, we simply show status; you could add extra checks for cable connectivity
    write_colored_text($left_width + 5, 16, 'Device eth0 [' . ( ($lan_ip ne 'N/A') ? 'UP' : 'DOWN' ) . ']', $info_color, "\e[30m");

    # WAN Zone info
    write_colored_text($left_width + 5, 19, "WAN Zone: IP $wan_ip", $info_color, "\e[30m");
    write_colored_text($left_width + 5, 20, 'Device eth1 [' . ( ($wan_ip ne 'N/A') ? 'UP' : 'DOWN' ) . ']', $info_color , "\e[30m");

    # Prompt for key press (if desired)
    write_colored_text(3, $height - 1, 'Press a menu key (0-5) or q to quit...', $menu_color, $text_color);
}

# Example stub functions for menu actions
sub run_system_shell        { system("/bin/sh"); }
sub reboot_system           { system("reboot"); }
sub change_root_password    { system("passwd root"); }
sub change_admin_password   { system("passwd admin"); }
sub restore_factory_defaults { print "Restoring factory defaults...\n"; sleep 2; }
sub network_wizard          {
    # This function could launch an interactive network configuration script
    print "Launching network wizard...\n";
    sleep 2;
    # For example, after configuration, the IP address may have changed
}

# Initialize screen
my $screen = SimpleCurses->new();
$screen->init_screen();

# Main program loop
my ($width, $height) = get_terminal_size();
while (1) {
    # Update dynamic info (LAN & WAN)
    my ($lan_ip, $wan_ip) = update_network_info();

    # Redraw the screen with the latest info
    redraw_screen($screen, $width, $height, $lan_ip, $wan_ip);

    # Wait for a key press
    my $key = $screen->get_input();

    # Process menu selection
    if ($key eq '0') {
        run_system_shell();
    }
    elsif ($key eq '1') {
        reboot_system();
    }
    elsif ($key eq '2') {
        change_root_password();
    }
    elsif ($key eq '3') {
        change_admin_password();
    }
    elsif ($key eq '4') {
        restore_factory_defaults();
    }
    elsif ($key eq '5') {
        network_wizard();
    }
    elsif ($key eq 'q') {
        last;  # Exit loop on 'q'
    }

    # After executing the selected function, the loop will iterate again,
    # re-reading network info and updating the display.
}

# End the screen session properly
$screen->end_screen();
