use Test::More tests => 6;
BEGIN { use_ok('Sub::Assert::Nothing') };


use strict;
use warnings;
use 5.006;

sub double {
    my $x = shift;
    return $x*2;
}

ok(ref(
assert(
       pre     => '$PARAM[0] > 0',
       post    => '$VOID || $RETURN > $PARAM[0]',
       sub     => 'double',
       context => 'novoid',
       action  => 'darnedtestmodule'
      )
) ne 'CODE', 'assert (nothing) returns *nothing*');

my $d = double(2);
ok(1, "assertion did not croak.");

$d = double(-1);
ok(1, "assertion carped on unmatched precondition.");

double(2);
ok(1, "assertion didn't complain now either.");

sub faultysqrt {
    my $x = shift;
    return $x**2;
}

assert
       pre    => '$PARAM[0] >= 0',
       post   => '$VOID || $RETURN <= $PARAM[0]',
       sub    => 'faultysqrt',
       action => 'darnedtestmodule';
  
$d = faultysqrt(3);
ok(1, "assertion did not complain this time.");

