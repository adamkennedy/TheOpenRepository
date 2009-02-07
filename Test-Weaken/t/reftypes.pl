#!perl

use strict;
use warnings;

use Scalar::Util qw(reftype weaken);
use Data::Dumper;
use Carp;
use English qw( -no_match_vars );

my $array_ref = \@{ [qw(42)] };

my $scalar_ref = \42;

my $regexp_ref = qr/./xms;

## no critic (Miscellanea::ProhibitFormats,References::ProhibitDoubleSigils)
format fmt =
@<<<<<<<<<<<<<<<
.
## use critic
my $format_ref = *fmt{FORMAT};

my $glob_ref = *fmt{GLOB};

my $IO_ref = *STDOUT{IO};

my $string = 'abc' x 40;
my $lv_ref = \( pos $string );

REF:
for my $ref (
    $array_ref, $scalar_ref, $regexp_ref, $format_ref,
    $glob_ref,  $IO_ref,     $lv_ref
    )
{
    print +( ref $ref ), q{ }, ( reftype $ref), "\n"
        or croak("Cannot print to STDOUT: $ERRNO");
}

REF: for my $ref ( $scalar_ref, $regexp_ref, $glob_ref, $lv_ref ) {
    my $probe = \$ref;
    print 'Trying to deref ', ( ref $probe ), q{ }, ( ref $ref ), "\n"
        or croak("Cannot print to STDOUT: $ERRNO");
    my $new_probe = \${ ${$probe} };
}

REF: for my $ref ($IO_ref) {
    my $probe = \$ref;
    print 'Trying to deref ', ( ref $probe ), q{ }, ( ref $ref ), "\n"
        or croak("Cannot print to STDOUT: $ERRNO");
    my $new_probe = \*{ ${$probe} };
}

