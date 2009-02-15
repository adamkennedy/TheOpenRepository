#!perl

# This is a sandbox for experiments with referencing and dereferencing.
# It is not part of a test suite, not even an "author" test suite.

use strict;
use warnings;

use Scalar::Util qw(reftype weaken);
use Data::Dumper;
use Carp;
use English qw( -no_match_vars );

our $STRING = 'abc' x 40;

## no critic (Miscellanea::ProhibitFormats,References::ProhibitDoubleSigils)
format fmt =
@<<<<<<<<<<<<<<<
$_
.
## use critic
my $format_ref = *fmt{FORMAT};

my $glob_ref = *STRING{GLOB};

my $io_ref1 = *STDOUT{IO};

# This form not valid
# my $io_ref2 = *STDOUT{IO::Handle};

my $io_ref3 = *STDOUT{FILEHANDLE};

open my $auto_viv_fh, q{>}, '/dev/null';

my $lv_ref = \( pos $STRING );
${$lv_ref} = 7;

REF:
for my $ref (
    $glob_ref,  $io_ref1, $io_ref3, $auto_viv_fh, $lv_ref, $format_ref,
    )
{
    print +( ref $ref ), q{ }, ( reftype $ref), "\n"
        or croak("Cannot print to STDOUT: $ERRNO");
}

$| = 1;
for my $dumper_ref ( $glob_ref, $io_ref1, $io_ref3, $auto_viv_fh, $lv_ref, $format_ref, ) {
    printf STDERR "Dumper: %s\n", Dumper( $dumper_ref);
}
