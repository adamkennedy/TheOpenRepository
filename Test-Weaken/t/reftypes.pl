#!perl

# This is a sandbox for experiments with referencing and dereferencing.
# It is not part of a test suite, not even an "author" test suite.

use strict;
use warnings;

use Scalar::Util qw(reftype weaken);
use Data::Dumper;
use Carp;
use English qw( -no_match_vars );

sub try_dumper {
    my $probe_ref = shift;

    my @warnings = ();
    $SIG{__WARN__} = sub { push @warnings, $_[0]; };
    printf STDERR "Dumper: %s", Dumper( ${$probe_ref} );
    for my $warning (@warnings) {
        print STDERR "Dumper warning: $warning";
    }
}

my $array_ref = \@{ [qw(42)] };
my $hash_ref    = { a => 1, b => 2 };
my $scalar_ref  = \42;
my $ref_ref     = \$scalar_ref;
my $regexp_ref  = qr/./xms;
my $vstring_ref = \(v1.2.3.4);
my $code_ref    = \&try_dumper;

## no critic (Miscellanea::ProhibitFormats,References::ProhibitDoubleSigils)
format fmt =
@<<<<<<<<<<<<<<<
$_
.
## use critic
my $format_ref = *fmt{FORMAT};

my $glob_ref = *STDOUT{GLOB};

my $io_ref = *STDOUT{IO};

my $string     = 'abc' x 40;
my $lvalue_ref = \( pos $string );
${$lvalue_ref} = 7;

my %data = (
    'scalar'  => $scalar_ref,
    'array'   => $array_ref,
    'hash'    => $hash_ref,
    'ref'     => $ref_ref,
    'code'    => $code_ref,
    'regexp'  => $regexp_ref,
    'vstring' => $vstring_ref,
    'format'  => $format_ref,
    'glob'    => $glob_ref,
    'io'      => $io_ref,
    'lvalue'  => $io_ref,
);

REF:
while ( my ( $name, $ref ) = each %data ) {
    printf STDERR "==== $name, %s, %s ====\n", ( ref $ref ), ( reftype $ref)
        or croak("Cannot print to STDOUT: $ERRNO");
    try_dumper( \$ref );
}

REF:
for my $data_name (qw(scalar vstring regexp ref )) {
    my $ref = $data{$data_name};
    printf STDERR "=== Deref test $data_name, %s, %s ===\n", ( ref $ref ),
        ( ref $ref )
        or croak("Cannot print to STDOUT: $ERRNO");
    my $old_probe = \$ref;
    try_dumper($old_probe);
    my $new_probe = \${ ${$old_probe} };
    try_dumper($new_probe);
}

REF: for my $ref ($format_ref) {
    my $probe = \$ref;
    print 'Trying to deref ', ( ref $probe ), q{ }, ( ref $ref ), "\n"
        or croak("Cannot print to STDOUT: $ERRNO");
    try_dumper($probe);

    # How to dereference ?
}

REF: for my $ref ($lvalue_ref) {
    my $probe = \$ref;
    print 'Trying to deref ', ( ref $probe ), q{ }, ( ref $ref ), "\n"
        or croak("Cannot print to STDOUT: $ERRNO");
    try_dumper($probe);
    my $new_probe = \${ ${$probe} };
    printf {*STDOUT} "pos is %d\n", ${$lvalue_ref};
    ${$lvalue_ref} = 11;
    printf {*STDOUT} "pos is %d\n", ${$lvalue_ref};
}

REF: for my $ref ($io_ref) {
    my $probe = \$ref;
    print 'Trying to deref ', ( ref $probe ), q{ }, ( ref $ref ), "\n"
        or croak("Cannot print to STDOUT: $ERRNO");
    try_dumper($probe);
    my $new_probe = \*{ ${$probe} };
    print { ${$new_probe} } "Printing via IO ref\n";
}

REF: for my $ref ($glob_ref) {
    my $probe = \$ref;
    print 'Trying to deref ', ( ref $probe ), q{ }, ( ref $ref ), "\n"
        or croak("Cannot print to STDOUT: $ERRNO");
    try_dumper($probe);
    my $new_probe = \*{ ${$probe} };
    print { ${$new_probe} } "Printing via GLOB ref\n";
}
