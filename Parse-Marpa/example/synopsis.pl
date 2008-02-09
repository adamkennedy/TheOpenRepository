use 5.010_000;
use strict;
use warnings;
use English;
use Parse::Marpa;

# remember to use refs to strings
my $value = Parse::Marpa::marpa(
    (do { local($RS) = undef; my $source = <DATA>; \$source; }),
    \("2+2*3")
);
say $$value;

__DATA__
semantics are perl5.  version is 0.205.0.  start symbol is Expression.

Expression: Expression, /[*]/, Expression.  priority 200.  q{
    $Parse::Marpa::Read_Only::v->[0] * $Parse::Marpa::Read_Only::v->[2]
}.

Expression: Expression, /[+]/, Expression.  priority 100.  q{
    $Parse::Marpa::Read_Only::v->[0] + $Parse::Marpa::Read_Only::v->[2]
}.

Expression: /\d+/.  q{ $Parse::Marpa::Read_Only::v->[0] }.
