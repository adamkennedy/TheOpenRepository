#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Marpa;

# remember to use refs to strings
my $value = Marpa::mdl(
    (   do { local ($RS) = undef; my $source = <DATA>; \$source; }
    ),
    \('2+2*3')
);
say ${$value};

## no critic (Subroutines::RequireArgUnpacking)

sub add_ops   { return $_[0] * $_[2] }
sub first_arg { return $_[0] }

## use critic

__DATA__
semantics are perl5.  version is 0.001_019.  start symbol is Expression.

Expression: Expression, /[*]/, Expression.  priority 200.
'main::add_ops'.

Expression: Expression, /[+]/, Expression.  priority 100.
'main::add_ops'.

Expression: /\d+/.  'main::first_arg'.
