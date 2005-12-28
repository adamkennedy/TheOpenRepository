#!/usr/bin/perl -w

# Unit tests for the PITA::Report::Install class

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

# Extra testing functions
sub dies {
	my $code = shift;
	eval { &$code() };
	ok( $@, $_[0] || 'Code dies as expected' );
}





#####################################################################
# Create the support objects

my $md5sum  = '0123456789ABCDEF0123456789ABCDEF';
my $request = PITA::Report::Request->new(
	scheme   => 'perl5',
	distname => 'Foo-Bar',
	filename => 'Foo-Bar-0.01.tar.gz',
	md5sum   => $md5sum,
	);
isa_ok( $request, 'PITA::Report::Request' );

my $platform = PITA::Report::Platform->current;
isa_ok( $platform, 'PITA::Report::Platform' );





#####################################################################
# Testing a sample of the functionality

# Create an empty install object
SCOPE: {
	my $install = PITA::Report::Install->new(
		request  => $request,
		platform => $platform,
		);
	isa_ok( $install,           'PITA::Report::Install'  );
	isa_ok( $install->request,  'PITA::Report::Request'  );
	isa_ok( $install->platform, 'PITA::Report::Platform' );
	is_deeply( [ $install->commands ], [], '->commands returns correct in list context' );
	is( scalar($install->commands), 0, '->commands returns correct in scalar context' );
	is_deeply( [ $install->tests ], [], '->tests returns correct in list context' );
	is( scalar($install->tests), 0, '->tests returns correct in scalar context' );
	is( $install->analysis, undef, '->analysis returns undef as expected' );
}

exit(0);
