package Marpa::Test::Util;

# The original of this code was copied from Andy Lester's Ack
# package

use 5.010;
use strict;
use warnings;

use Test::More;
use English qw( -no_match_vars );
use File::Spec;

# capture stderr output into this file
my $catcherr_file = 'stderr.log';

sub is_win32 {
    return $^O =~ /Win32/;
}

# capture-stderr is executing ack and storing the stderr output in
# $catcherr_file in a portable way.
#
# The quoting of command line arguments depends on the OS
sub build_command_line {
    my (@args) = @_;

    if ( is_win32() ) {
        for ( @args ) {
            s/(\\+)$/$1$1/;     # Double all trailing backslashes
            s/"/\\"/g;          # Backslash all quotes
            $_ = qq{"$_"};
        }
    }
    else {
        @args = map { quotemeta $_ } @args;
    }

    return "$^X -Ilib ./lib/Marpa/Test/capture-stderr $catcherr_file @args";
}

sub run_command {
    my ($command, @args) = @_;

    my ($stdout, $stderr) = run_with_stderr( $command, @args );

    Test::More::is( $stderr, q{}, "Should have no output to stderr: $command @args" )
            or diag( "STDERR:\n$stderr" );

    return $stdout;
}

sub run_with_stderr {
    my @args = @_;

    my $cmd = build_command_line( @args );

    my $stdout = `$cmd`;
    my ($sig,$core,$rc) = (($? & 127),  ($? & 128) , ($? >> 8));

    open( my $fh, '<', $catcherr_file ) or die $!;
    my $stderr = do { local $RS = undef; <$fh> };
    close $fh or die $!;
    unlink $catcherr_file;

    return ( $stdout, $stderr, $rc );
}

1;
