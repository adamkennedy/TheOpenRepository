use 5.010_000;
use strict;
use warnings;
use lib "../lib";
use English;

use Test::More tests => 1;

BEGIN {
	use_ok( 'Parse::Marpa' );
}

# remember to use refs to strings
my $value = Parse::Marpa::marpa(
    (do { local($RS) = undef; my $source = <DATA>; \$source; }),
    \("2+2*3")
);
say $$value;

__DATA__
semantics are perl5.  version is 0.204.0.  start symbol is Expression.

Expression: Factor, /[*]/, Factor.  q{
    $Parse::Marpa::Read_Only::v->[0] * $Parse::Marpa::Read_Only::v->[2]
}.

Factor: Term.  q{ $Parse::Marpa::Read_Only::v->[0] }.

Factor: Term, /[+]/, Term.  q{
    $Parse::Marpa::Read_Only::v->[0] + $Parse::Marpa::Read_Only::v->[2]
}.

Term: /\d+/.  q{ $Parse::Marpa::Read_Only::v->[0] }.
