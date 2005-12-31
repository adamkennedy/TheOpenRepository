#!/usr/bin/perl -w

# Compile-testing for PITA-Scheme

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

use File::Remove;
use PITA::Scheme;
use Test::More tests => 9;

# Locate the injector directory
my $injector = catdir( 't', '02_empiric', 'injector' );
ok( -d $injector, 'Test injector exists' );

# Create the workarea directory
my $workarea = catdir( 't', '02_empiric', 'workarea' );
        remove( \1, $workarea ) if -d $workarea;
BEGIN { remove( \1, $workarea ) if -d $workarea; }
ok( mkdir( $workarea ), 'Created workarea' );
ok( -d $workarea, 'Test workarea exists' );





#####################################################################
# Main Testing

my $scheme = PITA::Scheme->new(
	injector => $injector,
	workarea => $workarea,
	);
isa_ok( $scheme, 'PITA::Scheme' );
isa_ok( $scheme, 'PITA::Scheme::Perl5::Make' );



exit(0);
