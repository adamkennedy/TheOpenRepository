#!/usr/bin/perl

use strict;
use Test::More;
use File::Which;
BEGIN {
	if ( $^O eq 'MSWin32' and not $INC{'Math/BigInt/GMP.pm'} ) {
		plan( skip_all => 'Test is excessively slow without GMP' );
	} else {
		plan( tests => 18 );
	}
}

use Crypt::DSA;
use Crypt::DSA::Util qw( mod_exp );
use Math::BigInt;

my $dsa = Crypt::DSA->new;
my $two = Math::BigInt->new(2);
for my $bits (qw( 512 768 1024 )) {
	my $key = $dsa->keygen( Size => $bits );
	ok($key);
	ok($key->size, $bits);
	ok(($key->p < ($two ** $bits)) && ($key->p > ($two ** ($bits-1))));
	ok(($key->q < ($two ** 160)) && ($key->q > ($two ** 159)));
	ok(0, ($key->p - 1) % $key->q);
	ok($key->pub_key, mod_exp($key->g, $key->priv_key, $key->p));
}
