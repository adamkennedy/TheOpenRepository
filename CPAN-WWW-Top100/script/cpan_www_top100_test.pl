#!C:\strawberry\perl\bin\perl.exe -w

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catalyst::Test 'CPAN::WWW::Top100';

my $help = 0;

GetOptions( 'help|?' => \$help );

pod2usage(1) if ( $help || !$ARGV[0] );

print request($ARGV[0])->content . "\n";

1;

=head1 NAME

cpan_www_top100_test.pl - Catalyst Test

=head1 SYNOPSIS

cpan_www_top100_test.pl [options] uri

 Options:
   -help    display this help and exits

 Examples:
   cpan_www_top100_test.pl http://localhost/some_action
   cpan_www_top100_test.pl /some_action

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst action from the command line.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
