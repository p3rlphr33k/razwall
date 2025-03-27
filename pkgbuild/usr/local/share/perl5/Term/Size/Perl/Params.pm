
package Term::Size::Perl::Params; 

# created Thu Mar 27 19:16:27 2025

use vars qw($VERSION);
$VERSION = '0.031';

sub params {
    return (
        winsize => {
            sizeof => 8,
            mask => 'S!S!S!S!'
        },
        TIOCGWINSZ => {
            value => 21523,
            definition => qq{0x5413}
        }
    );
}

1;

=pod

=head1 NAME

Term::Size::Perl::Params - Configuration for Term::Size::Perl

=head1 SYNOPSIS

    use Term::Size::Perl::Params ();

    %params = Term::Size::Perl::Params::params();

=head1 DESCRIPTION

The configuration parameters C<Term::Size::Perl> needs to
know for retrieving the terminal size with C<ioctl>.

=head1 FUNCTIONS

=head2 params

The configuration parameters C<Term::Size::Perl> needs to
know for retrieving the terminal size with C<ioctl>.

=cut
