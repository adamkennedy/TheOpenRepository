#!/usr/bin/perl -w

# Unit testing for Data::Vitals::Util

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}

use Test::More tests => 373;





#####################################################################
# Importing

# Load it three different ways
eval "use Data::Vitals::Util ();";
ok( ! $@, 'Eval succeeded' );
ok( ! defined &cm2inch, 'Loading with () does not import' );
ok( ! defined &inch2cm, 'Loading with () does not import' );

eval "use Data::Vitals::Util;";
ok( ! $@, 'Eval succeeded' );
ok( ! defined &cm2inch, 'Loading plain does not import' );
ok( ! defined &inch2cm, 'Loading plain does not import' );

eval "use Data::Vitals::Util 'cm2inch', 'inch2cm';";
ok( ! $@, 'Eval succeeded' );
ok( defined *cm2inch{CODE}, 'Loading with explicit import does import' );
ok( defined *inch2cm{CODE}, 'Loading with explicit import does import' );





#####################################################################
# Inches and Centimetres

# Basic round-trip testing
foreach my $inch ( 20 .. 200 ) {
	$inch = $inch / 2;
	my $cm = inch2cm($inch);
	ok( $cm > $inch, 'Got a different cm value' );
	my $inch2 = cm2inch($cm);
	ok( $inch2 == $inch, "cm2inch(inch2cm($inch)) == $inch" );
}

# Test half a dozen known conversions
is( cm2inch(100), 39,   'cm2inch(100) == 39'   );
is( cm2inch(101), 39.5, 'cm2inch(101) == 39.5' );

exit(0);
