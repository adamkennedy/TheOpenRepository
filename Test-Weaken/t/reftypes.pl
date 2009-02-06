#
#        my @old_refrefs = ();
#        if ( $type eq 'REF' ) { @old_refrefs = ($refref) }
#        elsif ( $type eq 'ARRAY' ) {
#            @old_refrefs = map { \$_ } grep { ref $_ } @{$refref};
#        }
#        elsif ( $type eq 'HASH' ) {
#            @old_refrefs = map { \$_ } grep { ref $_ } values %{$refref};
#        }
#
#        for my $old_refref (@old_refrefs) {
#            my $rr_type = reftype ${$old_refref};
#            my $new_refref =
#                  $rr_type eq 'HASH'    ? \%{ ${$old_refref} }
#                : $rr_type eq 'ARRAY'   ? \@{ ${$old_refref} }
#                : $rr_type eq 'REF'     ? \${ ${$old_refref} }
#                : $rr_type eq 'SCALAR'  ? \${ ${$old_refref} }
#                : $rr_type eq 'CODE'    ? \&{ ${$old_refref} }
#                : $rr_type eq 'VSTRING' ? \${ ${$old_refref} }
#                :                         undef;

#                   SCALAR
#                   ARRAY
#                   HASH
#                   CODE
#                   REF
#                   GLOB
#                   LVALUE
#                   FORMAT
#                   IO
#                   VSTRING
#                   Regexp

use strict;
use warnings;

use Scalar::Util qw(reftype);

my $array_ref = \@{[qw(42)]};

my $scalar_ref = \42;

my $regexp_ref = qr/./;

format fmt =
@<<<<<<<<<<<<<<<
.
my $format_ref = *fmt{FORMAT};

my $glob_ref = *fmt{GLOB};

my $IO_ref = *STDOUT{IO};

my $string = "abc" x 40;
my $lv_ref = \pos($string);

REF: for my $ref ($array_ref, $scalar_ref, $regexp_ref, $format_ref, $glob_ref, $IO_ref, $lv_ref) {
    print +(ref $ref), " ", (reftype $ref), "\n";
}

REF: for my $ref ($scalar_ref, $regexp_ref, $format_ref, $glob_ref, $IO_ref, $lv_ref) {
    last REF;
}
