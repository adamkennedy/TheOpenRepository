#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
	use_ok( 'POE' ); # 1
	use_ok( 'PITA::POE::SupportServer' ); # 2
    use_ok( 'PITA::Test::Image::Qemu' ); # 3
};

ok( $] > 5.005, 'Perl version is 5.005 or newer' ); # 4

exit(0);
