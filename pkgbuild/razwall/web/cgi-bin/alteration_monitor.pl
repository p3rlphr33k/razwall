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
use strict;
use warnings;
# MonitorThread package
package MonitorThread;
sub new {
    my ($class, %args) = @_;
    my $self = {
        callback_func => $args{callback_func},
        frequency => $args{frequency} // 1,
        match => $args{match},
        ignore_files => $args{ignore_files} || [],
        debug => $args{debug} // 0,
        changed_modules_arg => $args{changed_modules_arg} // 0,
        stop => 0, # flag to stop the monitor
    };
    return bless $self, $class;
}

sub run {
    my ($self) = @_;
    my %mtimes;
    my $first_time = 1;
    while (!$self->{stop}) {
        my @changed_files;
        my $run_func = 0;
        # Get the list of files to monitor
        my @files = grep { /\.pm$|\.pl$/ } keys %INC;
        foreach my $filename (@files) {
            next if grep { $_ eq $filename } @{$self->{ignore_files}};
            # Convert module names in %INC to file paths
            if ($filename =~ /\.pm$/) {
                $filename =~ s/::/\//g;
                $filename .= ".pm";
            }
            # Get the modification time using pure Perl `stat`
            my @stats = stat($filename);
            my $mtime = $stats[9] || 0;
            if (defined $mtime) {
                if (!exists $mtimes{$filename}) {
                    $mtimes{$filename} = $mtime;
                }
                elsif ($mtime > $mtimes{$filename}) {
                    unless ($first_time) {
                        push @changed_files, $filename;
                        $run_func = 1;
                        print "File changed: $filename\n" if $self->{debug};
                    }
                    $mtimes{$filename} = $mtime;
                }
            }
        }
        if ($run_func && !$first_time) {
            if ($self->{changed_modules_arg}) {
                $self->{callback_func}->(\@changed_files);
            } else {
                $self->{callback_func}->();
            }
        }
        $first_time = 0;
        sleep($self->{frequency});
    }
}

sub stop {
    my ($self) = @_;
    $self->{stop} = 1;
}

# Install alteration monitor
sub install_alteration_monitor {
    my (%args) = @_;
    my $monitor = MonitorThread->new(%args);
    # Start the monitor in a separate thread
    my $pid = fork();
    if (!defined $pid) {
        die "Failed to fork process!";
    }
    elsif ($pid == 0) {
        # Child process runs the monitor
        $monitor->run();
        exit;
    }
    return ($monitor, $pid);
}
# Main script
if (!caller()) {
    my $callback = sub {
        my ($changed_files) = @_;
        print "Time: " . time() . "\n";
        print "Changed files: " . join(", ", @$changed_files) . "\n";
    };
    my ($monitor, $pid) = install_alteration_monitor(
        callback_func => $callback,
        frequency => 2,
        match => undef,
        ignore_files => [],
        debug => 1,
        changed_modules_arg => 1
    );
    print "Press Ctrl+C to stop.\n";
    # Handle Ctrl+C to stop the monitor
    $SIG{INT} = sub {
        $monitor->stop();
        waitpid($pid, 0); # Wait for child process to terminate
        exit;
    };
    # Keep the main process running
    while (1) {
        sleep(1);
    }
}
