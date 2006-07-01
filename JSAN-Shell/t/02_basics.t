#!/usr/bin/perl -w

# Compile testing for jsan2

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			'lib',
			);
	}
}

use JSAN::Shell ();
use Test::More tests => 1;





#####################################################################
# Object creation

my $shell = JSAN::Shell->new;
isa_ok( $shell, 'JSAN::Shell' );





#####################################################################
# Config manipulation

my @config_true  = qw{t true y yes 1 on};
my @config_false = qw{f false n no 0 off};
foreach ( @config_true ) {
	# ...
}

exit(0);
