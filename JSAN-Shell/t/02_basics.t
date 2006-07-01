#!/usr/bin/perl -w

# Compile testing for jsan2

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), 'lib') );
	}
}

use JSAN::Shell2 ();
use Test::More tests => 1;





#####################################################################
# Object creation

my $shell = JSAN::Shell2->new;
isa_ok( $shell, 'JSAN::Shell2' );





#####################################################################
# Config manipulation

my @config_true  = qw{t true y yes 1 on};
my @config_false = qw{f false n no 0 off};
foreach ( @config_true ) {
	# ...
}
	
exit(0);
