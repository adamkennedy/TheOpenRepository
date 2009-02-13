#!/usr/bin/perl

use strict;
use Test::More;
use File::Which;
BEGIN {
	if ( $^O eq 'MSWin32' and not $INC{'Math/BigInt/GMP.pm'} ) {
		plan( skip_all => 'Test is excessively slow without GMP' );
	} else {
		plan( tests => 4 );
	}
}
use Crypt::DSA;

my $message = "Je suis l'homme a tete de chou.";

my $dsa = Crypt::DSA->new;
my $key = $dsa->keygen( Size => 512 );
my $sig = $dsa->sign(
	Message => $message,
	Key => $key,
);
my $verified = $dsa->verify(
	Key       => $key,
	Message   => $message,
	Signature => $sig,
);
ok($verified);
