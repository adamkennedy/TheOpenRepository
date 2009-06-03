#!/usr/bin/perl

# Tests for the ADAMK::Role::Make role

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $ENV{ADAMK_CHECKOUT} and -d $ENV{ADAMK_CHECKOUT} ) {
		plan( tests => 17 );
	} else {
		plan( skip_all => '$ENV{ADAMK_CHECKOUT} is not defined or does not exist' );
	}
}
use File::Spec::Functions ':ALL';
use ADAMK::Repository ();

my $repository = ADAMK::Repository->new(
	path => $ENV{ADAMK_CHECKOUT},
);
isa_ok( $repository, 'ADAMK::Repository' );





#####################################################################
# Module::Install Detection

my @versions = (
	'Config-Tiny'      => undef,
	'Class-Default'    => 0,
	'ADAMK-Repository' => '0.91',
);
while ( @versions ) {
	my $name     = shift @versions;
	my $expected = shift @versions;
	my $distribution = $repository->distribution($name);
	isa_ok( $distribution, 'ADAMK::Distribution' );
	my $version = $distribution->module_install;
	is( $version, $expected, "Version for $name matches expected value" );
}





#####################################################################
# Makefile.PL Support

SCOPE: {
	my $distribution = $repository->distribution('Devel-Dumpvar');
	isa_ok( $distribution, 'ADAMK::Distribution' );

	# Configure a module
	my $meta = $distribution->run_makefile_pl;
	ok( -f catfile($distribution->path, 'Makefile'),    'Created Makefile'    );
	ok( -f catfile($distribution->path, 'MYMETA.json'), 'Created MYMETA.json' );
	is( ref($meta), 'HASH', '->run_makefile_pl returns a MYMETA hash' );
	is( $meta->{version}, '1.05', '->{version} ok' );
	is( $meta->{license}, 'perl', '->{license} ok' );
	is( $meta->{name}, 'Devel-Dumpvar', '->{name} ok' );

	# Build the module
	ok( $distribution->run_make, '->run_make' );
	ok( -d 'blib', 'make ok' );

	# Test the module
	ok( $distribution->run_make_test, '->run_make_test' );
}
