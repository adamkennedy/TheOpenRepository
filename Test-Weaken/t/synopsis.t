#!perl

use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 2;
use Fatal qw(close);
use Carp;
use Scalar::Util qw(weaken isweak);

use lib 't/lib';
use Test::Weaken::Test;

BEGIN { use_ok('Test::Weaken') }

package main;

# slurp in the code
my $filename = $INC{'Test/Weaken.pm'};
open my $code_fh, '<', $filename or croak("Cannot open $filename: $!");
my $code = do { local ($RS) = undef; <$code_fh> };
close $code_fh;

# remove stuff before and after the SYNOPSIS
$code =~ s/.*^=head1\s*SYNOPSIS\s*$//xms;
$code =~ s/^=head1.*\z//xms;

# remove POD text
$code =~ s/^\S[^\n]*$//xmsg;

my $code_output = q{};
## no critic (InputOutput::ProhibitTwoArgOpen)
my $pid = open my $read, q{-|};
## use critic
if ( not defined $pid ) {
    croak("Could not fork: $!");
}
elsif ($pid) {
    local $RS = undef;
    $code_output .= <$read>;
    close $read;
    if ( my $child_error = ${^CHILD_ERROR_NATIVE} ) {
        $code_output .= "synopsis code returned $child_error\n";
    }
}
else {
    open STDERR, '>&STDOUT'
        or croak("Cannot dup to STDOUT: $ERRNO");
    $code .= "\n1;\n";
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    my $eval_ok = eval $code;
    ## use critic
    if ( not $eval_ok ) {
        print "eval failed: $@\n"
            or croak("Cannot print to STDOUT: $ERRNO");
    }
    exit;
}

Test::Weaken::Test::is( $code_output, <<'EOS', 'synopsis output' );
No leaks in test 1
Test 2: 1 of 2 original references were not freed
These are the probe references to the unfreed objects:
$unfreed = [
             42,
             711,
             $unfreed
           ];
EOS
