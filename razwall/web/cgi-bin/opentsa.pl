
sub opentsa_check_file($) {
    my $file = shift;

    system("/usr/local/bin/control_log_archives_timestamp -F '$file' &>/dev/null");

    return $?;
}


sub opentsa_timestamp_file($) {
    my $file = shift;

    system("/usr/local/bin/timestamp_log_archives -f -F '$file' &>/dev/null");

    return $?;
}

1;
