#!perl

use Scalar::Util qw(reftype weaken isweak);
use Data::Dumper;

# $Data::Dumper::Purity = 1;

sub constructor {
    my $object = 42;
    my ($o1, $o2, $o3);
    $o3 = 711;
    $o2 = \$o3;
    $o1 = \$o2;
    my $hash = { weak => \$o1, strong => \$object, stronger => \$o1 };
    my $array = [ $hash, $hash, \$hash ];
    weaken($array->[0]);
    weaken($hash->{weak});
    return [ $hash, $array ];
}


sub follow {
    # my $class = shift;
    my $base_ref = shift;

    # Initialize the results with a reference to the dereferenced
    # base reference.
    my $result = [ \( ${$base_ref} ) ];
    my %reverse = ();
 
    my $to_here = -1;
    REF: while ($to_here < $#{$result}) {
        $to_here++;
        my $refref = $result->[$to_here];
        my $type = reftype $refref;

        my @old_refrefs =
            $type eq 'REF' ? ($refref) :
            $type eq 'ARRAY' ?  (map { \$_ } grep { ref $_ } @{$refref}) :
            $type eq 'HASH' ?  (map { \$_ } grep { ref $_ } values %{$refref}) :
            ();

        for my $old_refref (@old_refrefs) {
            my $rr_type = reftype ${$old_refref};
            my $new_refref = 
                $rr_type eq 'HASH' ? \%{${$old_refref}} :
                $rr_type eq 'ARRAY' ? \@{${$old_refref}} :
                $rr_type eq 'REF' ? \${${$old_refref}} :
                $rr_type eq 'SCALAR' ? \${${$old_refref}} :
                $rr_type eq 'CODE' ? \&{${$old_refref}} :
                $rr_type eq 'VSTRING' ? \${${$old_refref}} :
                undef;
            if (defined $new_refref && not $reverse{$new_refref+0}) {
                push @{$result}, $new_refref;
                $reverse{$new_refref+0}++;
            }
            
        }

    } # REF

    return $result;

} # sub follow

my $base_ref = constructor();
my $result = follow( \( $base_ref ) );
for my $rr (@{$result}) {
     print +(ref $rr), "\n";
}
print Data::Dumper->Dump([$result], [qw(base)]);

my $test_hash = $base_ref->[0];
for my $key (keys %{$test_hash}) {
     printf "hash element '%s' is %s\n", $key, (isweak($test_hash->{$key}) ? "weak" : "strong");
}

my $test_array = $base_ref->[1];
for my $element (@{$test_array}) {
     printf "array element is %s\n", (isweak($element) ? "weak" : "strong");
}
