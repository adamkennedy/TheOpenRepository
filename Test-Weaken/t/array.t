#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Scalar::Util qw(isweak weaken reftype);

BEGIN {
	use_ok( 'Test::Weaken' );
}


my ($wc, $sc, $wa, $sa) = Test::Weaken::poof(sub {
	my $a;
	my $b = [ \$a, 42];
	$a = [ \$b, 711];
	weaken($a->[2] = \$b);
	weaken($b->[2] = \$a);
	$a;
    }
);

my $text = "Starting counts: w=$wc  s=$sc\nUnfreed counts: w=" . scalar @$wa . "  s=" . scalar @$sa . "\n";

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
    my $prefix = "r";
    if ($type eq "REF") {
	my $number = $$r->[1];
        $name{$r} = $prefix . $number;
	give_name($$r);
	return;
    }
    if ($type eq "ARRAY") {
	$prefix = "a";
        $name{$r} = $prefix . $r->[1];
	return;
    }
}

STRONG: for (my $ix = 0; $ix <= $#$sa; $ix++) {
    give_name($sa->[$ix]);
}

my @unfreed_text;

for (my $ix = 0; $ix <= $#$sa; $ix++) {
    my $r = $sa->[$ix];
    my $unfreed_line .= "Unfreed strong ref: " .
	name($r) . " => ";
    my $type = reftype $r;
    if ($type eq "REF") {
 	$unfreed_line .=
	    "". name($$r) . " == " .
	    "[ ".
	    join(", ",
		map { my $t = reftype $_; (defined $t && $t eq "REF") ? name($_) : $_ }
		@$$r
	    ) .
	    " ]";
    } elsif ($type eq "ARRAY") {
 	$unfreed_line .=
	    "[ ".
	    join(", ",
		map { my $t = reftype $_; (defined $t and $t eq "REF") ? name($_) : $_ }
		@$r
	    ) .
	    " ]";
    } else {
 	$unfreed_line .= $type;
    }
    push(@unfreed_text, $unfreed_line);
}

for (my $ix = 0; $ix <= $#$wa; $ix++) {
    my $r = $wa->[$ix];
    my $unfreed_line .= "Unfreed weak   ref:" .
	" ". name($r) . " => " .
	name($$r) . " == " .
	"[ ".
	join(", ",
	    map { my $t = reftype $_; (defined $t and $t eq "REF") ? name($_) : $_ }
	    @$$r)
	. " ]";
    push(@unfreed_text, $unfreed_line);
}

$text .= join("\n", sort @unfreed_text) . "\n";

is($text, <<'EOS', "Dump of unfreed arrays");
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
