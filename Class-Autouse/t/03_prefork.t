#!/usr/bin/perl -w

# Formal testing for Class::Autouse.
# While this isn't a particularly exhaustive unit test like script, 
# it does test every known bug and corner case discovered. As new bugs
# are found, tests are added to this test script.
# So if everything works for all the nasty corner cases, it should all work
# as advertised... we hope ;)

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	if ( $ENV{HARNESS_ACTIVE} ) {
		lib->import( catdir( curdir(), 't', 'modules' ) );
	} else {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( 'modules' );
	}
}

# We don't need to run this if prefork is not installed
my @test_plan;
BEGIN {
	eval { require prefork; };
	@test_plan = $@
		? ('skip_all', 'prefork.pm is not installed')
		: (tests => 5);
}
use Test::More @test_plan;
use Class::Autouse 'C';



ok( ! $Class::Autouse::DEVEL, '$Class::Autouse::DEVEL is false' );
is( $INC{"C.pm"}, 'Class::Autouse', 'C.pm is autoused' );

ok( prefork::enable(), 'prefork::enable returns true' );
is( $Class::Autouse::DEVEL, 1, '$Class::Autouse::DEVEL is true' );
isnt( $INC{"C.pm"}, 'Class::Autouse', 'C.pm has been loaded' );

1;
