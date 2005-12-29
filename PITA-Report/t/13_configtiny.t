#!/usr/bin/perl -w

# Coerce from and to Config::Tiny objects if installed

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
			);
	}
}

use Test::More tests => 10;
use PITA::Report ();
eval "use Config::Tiny ();";





#####################################################################
# Create the Report components

sub test_request {
	my $it = shift;
	isa_ok( $it, 'PITA::Report::Request' );

	# Convert to a config object
	my $config = $it->__as_Config_Tiny;
	isa_ok( $config, 'Config::Tiny' );
	is( ref($config->{_}), 'HASH', 'Has a root section' );

	# Convert back
	my $that = PITA::Report::Request->__from_Config_Tiny( $config );
	isa_ok( $that, 'PITA::Report::Request' );

	# Does it round-trip?
	is_deeply( $it, $that, 'Round-trips ok' );
}

SKIP: {
	skip("Config::Tiny is not installed", 5) if $@;

	# Test the basic request object
	my $request1 = PITA::Report::Request->new(
		scheme    => 'perl5',
		distname  => 'Foo-Bar',
		filename  => 'Foo-Bar-0.01.tar.gz',
		md5sum    => '5cf0529234bac9935fc74f9579cc5be8',
		);
	test_request( $request1 );

	# Test the authority object
	my $request2 = PITA::Report::Request->new(
		scheme    => 'perl5',
		distname  => 'Foo-Bar',
		filename  => 'Foo-Bar-0.01.tar.gz',
		md5sum    => '5cf0529234bac9935fc74f9579cc5be8',
		authority => 'cpan',
		authpath  => '/id/authors/A/AD/ADAMK/Foo-Bar-0.01.tar.gz',
		);
	test_request( $request2 );
}

exit(0);
