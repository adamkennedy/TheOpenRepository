#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Scalar::Util qw(isweak weaken reftype);

BEGIN {
	use_ok( 'Test::Weaken' );
}


my (
    $weak_count,
    $strong_count,
    $weak_unfreed_array,
    $strong_unfreed_array
) = Test::Weaken::poof(sub {
	my $x;
	my $y = [ \$x, 42];
	$x = [ \$y, 711];
	weaken($x->[2] = \$y);
	weaken($y->[2] = \$x);
	$x;
    }
);

my $text = "Starting counts: w=$weak_count  s=$strong_count\n"
  . 'Unfreed counts: w=' . scalar @{$weak_unfreed_array} . '  s=' . scalar @{$strong_unfreed_array} . "\n";

# names for the references, so checking the dump does not depend
# on the specific hex value of locations
my %name;

sub name {
    my $r = shift;
    my $name = $name{$r};
    return $name if defined $name;
    return "$r";
}

sub give_name {
    my $r = shift;
    return if defined $name{$r};
    my $type = reftype $r;
    my $prefix = 'r';
    if ($type eq 'REF') {
	my $number = ${$r}->[1];
        $name{$r} = $prefix . $number;
	give_name(${$r});
	return;
    }
    if ($type eq 'ARRAY') {
	$prefix = 'a';
        $name{$r} = $prefix . $r->[1];
	return;
    }
}

STRONG: for my $ix ( 0 .. $#{$strong_unfreed_array} ) {
    give_name($strong_unfreed_array->[$ix]);
}

my @unfreed_text;

for my $ix ( 0 ..  $#{$strong_unfreed_array} ) {
    my $unfreed = $strong_unfreed_array->[$ix];
    my $unfreed_line .= 'Unfreed strong ref: ' .
	name($unfreed) . ' => ';
    my $type = reftype $unfreed;
    if ($type eq 'REF') {
        my @named_refs;
        for my $ref_ref (@{${$unfreed}}) {
            my $t = reftype $ref_ref;
            push @named_refs, ((defined $t and $t eq 'REF') ? name($ref_ref) : $ref_ref);
        }
 	$unfreed_line .=
            q{}
            . name( ${$unfreed} )
            . ' == ' .
	    '[ ' .  (join q{, }, @named_refs) .  ' ]';
    } elsif ($type eq 'ARRAY') {
        my @named_refs;
        for my $array_ref (@{$unfreed}) {
            my $t = reftype $array_ref;
            push @named_refs, ((defined $t and $t eq 'REF') ? name($array_ref) : $array_ref);
        }
 	$unfreed_line .= '[ '.  (join ', ', @named_refs) .  ' ]';
    } else {
 	$unfreed_line .= $type;
    }
    push @unfreed_text, $unfreed_line;
}

for my $ix ( 0 .. $#{$weak_unfreed_array} ) {
    my $unfreed = $weak_unfreed_array->[$ix];
    my @named_refs;
    for my $ref_ref (@{${$unfreed}}) {
        my $t = reftype $ref_ref;
        push @named_refs, ((defined $t and $t eq 'REF') ? name($ref_ref) : $ref_ref);
    }
    my $unfreed_line .=
        'Unfreed weak   ref:'
	. q{ } . name($unfreed) . ' => '
	. name(${$unfreed}) . ' == '
	. '[ ' . (join ', ', @named_refs) . ' ]';
    push @unfreed_text, $unfreed_line;
}

$text .= (join "\n", sort @unfreed_text) . "\n";

is($text, <<'EOS', 'Dump of unfreed arrays');
Starting counts: w=2  s=5
Unfreed counts: w=2  s=5
Unfreed strong ref: a42 => [ r711, 42, r711 ]
Unfreed strong ref: a711 => [ r42, 711, r42 ]
Unfreed strong ref: a711 => [ r42, 711, r42 ]
Unfreed strong ref: r42 => a42 == [ r711, 42, r711 ]
Unfreed strong ref: r711 => a711 == [ r42, 711, r42 ]
Unfreed weak   ref: r42 => a42 == [ r711, 42, r711 ]
Unfreed weak   ref: r711 => a711 == [ r42, 711, r42 ]
EOS
