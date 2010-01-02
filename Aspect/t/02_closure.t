#!/usr/bin/perl

# Validates that the type of closures used in Aspect.pm work properly on every
# Perl version we care about.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 28;
# use Test::NoWarnings;

# Create the subroutine we plan to replace
my $foo = 0;
sub foo () {
	++$foo;
}
is( foo(), 1, 'foo() ok' );
is( $foo,  1, '$foo ok'  );

# Replace the function
eval <<'END_PERL';
sub main::foo () {
	++$foo;
}
END_PERL
is( $@, '', 'Built new function without error' );
is( foo(), 2, 'foo() ok' );
is( $foo,  2, '$foo ok'  );
is( foo(), 3, 'foo() ok' );
is( $foo,  3, '$foo ok'  );
